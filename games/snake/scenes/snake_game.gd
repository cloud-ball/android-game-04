extends Node3D
## Serpent Grid controller: match flow, swipe input, fixed-rate logic ticks, rewards and saves.
## Logic ticks at SnakeLogic.tick_interval(); frames only interpolate between ticks.
## Modes: "vs" (CPU rival, first to crash loses) and "solo" (score attack).

enum State { READY, COUNTDOWN, PLAYING, PAUSED, OVER }

const SAVE_SCHEMA := 2
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"draws": 0,
	"best_score": 0,
	"best_length": 0,
	"difficulty": "medium",
	"mode": "vs",
	"solo_played": 0,
	"solo_best": 0,
	"tutorial_seen": false,
}
const WIN_BONUS := {"easy": 10, "medium": 25, "hard": 50}
const SOLO_BEST_BONUS := 20
const MAX_TICKS_PER_FRAME := 3
const KEY_DIRS := {
	KEY_UP: SnakeLogic.Dir.UP,
	KEY_W: SnakeLogic.Dir.UP,
	KEY_RIGHT: SnakeLogic.Dir.RIGHT,
	KEY_D: SnakeLogic.Dir.RIGHT,
	KEY_DOWN: SnakeLogic.Dir.DOWN,
	KEY_S: SnakeLogic.Dir.DOWN,
	KEY_LEFT: SnakeLogic.Dir.LEFT,
	KEY_A: SnakeLogic.Dir.LEFT,
}

var logic: SnakeLogic
var state: int = State.READY
var difficulty := "medium"
var mode := "vs"

var _view: SnakeView
var _hud: SnakeHud
var _swipe := SwipeDetector.new()
var _ai_rng: RandomNumberGenerator
var _save: Dictionary
var _acc := 0.0
var _countdown := 0.0
var _paused_from: int = State.PLAYING
var _bot := false


## Schema 1 -> 2 added solo mode and the tutorial flag; defaults fill the new keys.
static func migrate_save(old: Dictionary, _from: int, _to: int) -> Dictionary:
	if int(old.get("played", 0)) > 0:
		old["tutorial_seen"] = true
	return old


func _ready() -> void:
	_save = SaveService.game("snake", SAVE_SCHEMA, SAVE_DEFAULTS, migrate_save)
	difficulty = str(SceneRouter.params.get("difficulty", _save["difficulty"]))
	if not SnakeHud.DIFFICULTIES.has(difficulty):
		difficulty = "medium"
	mode = str(SceneRouter.params.get("mode", _save["mode"]))
	if not SnakeHud.MODES.has(mode):
		mode = "vs"
	_bot = Boot.bot
	var vis := get_viewport().get_visible_rect().size
	_swipe.threshold = 0.04 * minf(vis.x, vis.y)
	_new_match()
	_view = SnakeView.new()
	add_child(_view)
	_view.setup(logic.width, logic.height)
	_hud = SnakeHud.new()
	add_child(_hud)
	_hud.play_requested.connect(_on_play)
	_hud.rematch_requested.connect(_on_rematch)
	_hud.exit_requested.connect(func() -> void: SceneRouter.back_to_hub())
	_hud.pause_requested.connect(_pause)
	_hud.resume_requested.connect(_resume)
	_hud.howto_closed.connect(_on_howto_closed)
	_hud.mode_changed.connect(
		func(m: String) -> void:
			mode = m
			_hud.set_start_stats(_stats_text())
	)
	_hud.set_difficulty(difficulty)
	_hud.set_mode(mode)
	_refresh_hud()
	_view.render(logic, 1.0, 0.0)
	AudioService.play_music("game")
	if SceneRouter.params.get("autostart", false):
		_begin_countdown()
	elif not bool(_save["tutorial_seen"]):
		_hud.show_howto()
	else:
		_hud.show_start(_stats_text())


func _new_match() -> void:
	var seed_value := Rng.next_seed()
	logic = SnakeLogic.new(SnakeConfig.for_difficulty(difficulty), seed_value, mode == "vs")
	_ai_rng = Rng.make(seed_value ^ 0x2545F491)
	_acc = 0.0
	if _view != null:
		_view.reset()


func _begin_countdown() -> void:
	_hud.hide_panels()
	state = State.COUNTDOWN
	_countdown = 3.0
	_hud.show_countdown("3")
	AudioService.play("count")


func _process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			_step_countdown(delta)
		State.PLAYING:
			_acc += delta
			var n := 0
			while state == State.PLAYING and _acc >= logic.tick_interval():
				_acc -= logic.tick_interval()
				_tick()
				n += 1
				if n >= MAX_TICKS_PER_FRAME:
					_acc = 0.0
					break
	var alpha := clampf(_acc / logic.tick_interval(), 0.0, 1.0) if state == State.PLAYING else 1.0
	_view.render(logic, alpha, delta)


func _step_countdown(delta: float) -> void:
	var before := ceili(_countdown)
	_countdown -= delta
	var now := ceili(_countdown)
	if now == before:
		return
	if now > 0:
		_hud.show_countdown(str(now))
		AudioService.play("count")
	else:
		_hud.show_countdown("GO")
		AudioService.play("go")
		state = State.PLAYING
		_acc = 0.0
		if not _bot:
			_hud.show_hint()


func _tick() -> void:
	if _bot:
		logic.queue_turn(SnakeLogic.PLAYER, SnakeAI.choose(logic, SnakeLogic.PLAYER, _ai_rng))
	if logic.vs_cpu:
		logic.queue_turn(SnakeLogic.CPU, SnakeAI.choose(logic, SnakeLogic.CPU, _ai_rng))
	logic.step()
	for e in logic.events:
		_on_event(e)
	_refresh_hud()
	if logic.is_over():
		_finish()


func _on_event(e: Dictionary) -> void:
	var who: int = e.who
	match e.type:
		"eat":
			var length := logic.snakes[who].body.size()
			_view.sparkle_fx(e.cell)
			if who == SnakeLogic.PLAYER:
				AudioService.play("eat", 1.0 + 0.015 * length)
				AudioService.buzz(12)
				_view.eat_fx(e.cell, who, "+%d LONGER" % logic.cfg.orb_score)
			else:
				AudioService.play("eat", 0.7)
				_view.eat_fx(e.cell, who, "+%d" % logic.cfg.orb_score)
		"crash":
			AudioService.play("crash")
			AudioService.buzz(70)
			_view.crash_fx(e.cell, who)


func _finish() -> void:
	state = State.OVER
	var you := logic.snakes[SnakeLogic.PLAYER]
	var won := logic.result == SnakeLogic.Result.PLAYER_WON
	var new_best := mode == "solo" and you.score > int(_save["solo_best"])
	var info := _result_text(new_best)
	_hud.banner(info.title, info.cause, info.color)
	var coins := 0
	var daily := 0
	if not _bot:  # bot runs (screenshots, smoke tests) never touch the player's save
		_record_stats(you)
		coins = you.score / 10
		coins += int(WIN_BONUS[difficulty]) if won else 0
		coins += SOLO_BEST_BONUS if new_best else 0
		var stats := {
			"game": "snake",
			"difficulty": difficulty,
			"won": won,
			"length": you.body.size(),
			"score": you.score,
			"eaten": you.eaten,
		}
		var profile: Dictionary = SaveService.data["profile"]
		daily = DailyChallenge.report(profile, DailyChallenge.today(), stats)
		SaveService.save()
		Economy.add_coins(coins + daily)
	info["score"] = you.score
	info["length"] = you.body.size()
	info["best"] = int(_save["solo_best" if mode == "solo" else "best_score"])
	info["coins"] = coins + daily
	info["daily"] = "Daily challenge complete! +%d" % daily if daily > 0 else ""
	var happy := won or new_best
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_callback(func() -> void: AudioService.play("win" if happy else "lose"))
	tw.tween_callback(_hud.show_end.bind(info))


func _record_stats(you: SnakeLogic.Serpent) -> void:
	_save["tutorial_seen"] = true
	if mode == "solo":
		_save["solo_played"] = int(_save["solo_played"]) + 1
		_save["solo_best"] = maxi(int(_save["solo_best"]), you.score)
		_save["best_length"] = maxi(int(_save["best_length"]), you.body.size())
		return
	_save["played"] = int(_save["played"]) + 1
	match logic.result:
		SnakeLogic.Result.PLAYER_WON:
			_save["wins"] = int(_save["wins"]) + 1
		SnakeLogic.Result.CPU_WON:
			_save["losses"] = int(_save["losses"]) + 1
		_:
			_save["draws"] = int(_save["draws"]) + 1
	_save["best_score"] = maxi(int(_save["best_score"]), you.score)
	_save["best_length"] = maxi(int(_save["best_length"]), you.body.size())


func _result_text(new_best: bool) -> Dictionary:
	var you := logic.snakes[SnakeLogic.PLAYER]
	var you_why := {
		"rival": "You ran into the rival",
		"self": "You ran into yourself",
		"wall": "You hit the wall",
		"head": "Head-on collision",
	}
	match logic.result:
		SnakeLogic.Result.SOLO_OVER:
			return {
				"title": "NEW BEST!" if new_best else "GAME OVER",
				"cause": str(you_why.get(you.crash_cause, "Crashed")),
				"color": UiKit.GOLD if new_best else Color.WHITE,
			}
		SnakeLogic.Result.PLAYER_WON:
			var why := {
				"rival": "It ran into you",
				"self": "It tied itself in a knot",
				"wall": "It hit the wall",
			}
			var cpu := logic.snakes[SnakeLogic.CPU]
			return {
				"title": "RIVAL CRASHED!",
				"cause":
				str(why.get(cpu.crash_cause, "It crashed")) + " · +%d" % logic.cfg.crash_bonus,
				"color": UiKit.MAGENTA,
			}
		SnakeLogic.Result.CPU_WON:
			return {
				"title": "YOU CRASHED",
				"cause": str(you_why.get(you.crash_cause, "Crashed")),
				"color": Color(1.0, 0.45, 0.4),
			}
	return {"title": "HEAD-ON!", "cause": "Both snakes crashed · draw", "color": Color.WHITE}


func _refresh_hud() -> void:
	var you := logic.snakes[SnakeLogic.PLAYER]
	var cpu_score := 0
	var cpu_len := 0
	if logic.vs_cpu:
		cpu_score = logic.snakes[SnakeLogic.CPU].score
		cpu_len = logic.snakes[SnakeLogic.CPU].body.size()
	_hud.set_scores(you.score, you.body.size(), cpu_score, cpu_len, 1.0 / logic.tick_interval())


func _stats_text() -> String:
	if mode == "solo":
		return "Solo best %d  ·  Runs %d" % [int(_save["solo_best"]), int(_save["solo_played"])]
	return (
		"Best %d  ·  Wins %d of %d"
		% [int(_save["best_score"]), int(_save["wins"]), int(_save["played"])]
	)


func _on_howto_closed() -> void:
	_save["tutorial_seen"] = true
	SaveService.save()
	if state == State.READY:
		_hud.show_start(_stats_text())


func _on_play(d: String, m: String) -> void:
	difficulty = d
	mode = m
	_save["difficulty"] = d
	_save["mode"] = m
	SaveService.save()
	_new_match()
	_refresh_hud()
	_begin_countdown()


func _on_rematch() -> void:
	_new_match()
	_refresh_hud()
	_begin_countdown()


func _pause() -> void:
	if state == State.PLAYING or state == State.COUNTDOWN:
		_paused_from = state
		state = State.PAUSED
		_hud.show_pause(true)


func _resume() -> void:
	if state == State.PAUSED:
		_hud.show_pause(false)
		state = _paused_from


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_pause()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if state == State.PLAYING or state == State.COUNTDOWN:
				_pause()
			elif state == State.PAUSED:
				_resume()
			else:
				SceneRouter.back_to_hub()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING or _bot:
		_swipe.feed(event)
		return
	var d := _swipe.feed(event)
	if event is InputEventKey and event.pressed and not event.echo:
		d = int(KEY_DIRS.get(event.keycode, -1))
	if d != -1 and logic.queue_turn(SnakeLogic.PLAYER, d):
		AudioService.play("turn")
