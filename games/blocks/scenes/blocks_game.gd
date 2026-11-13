extends Node3D
## Stack Drop controller: match flow, input (touch gestures + keys), fixed-step logic for the
## player and the CPU, garbage exchange, effects, rewards and saves.

enum State { READY, COUNTDOWN, PLAYING, PAUSED, OVER }

const STEP := 1.0 / 60.0
const SAVE_SCHEMA := 2
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"best_score": 0,
	"best_lines": 0,
	"solo_played": 0,
	"solo_best": 0,
	"difficulty": "medium",
	"mode": "vs",
	"tutorial_seen": false,
	"learned": {},  # moves the player has done ({verb: true}); retires practice hints (schema 2)
}
## First-match practice hints: [move, shards placed before its hint appears].
const PRACTICE := [["rotate", 2], ["move", 3], ["drop", 5], ["hold", 8]]
const LEVELS := StackDifficulty.LEVELS
const WIN_BONUS := {"easy": 15, "medium": 30, "hard": 60}
const CLEAR_NAMES := ["", "SINGLE", "DOUBLE!", "TRIPLE!", "QUAD CLEAR!"]
const KEY_ACTIONS := {
	KEY_LEFT: "left",
	KEY_A: "left",
	KEY_RIGHT: "right",
	KEY_D: "right",
	KEY_DOWN: "soft",
	KEY_S: "soft",
	KEY_UP: "cw",
	KEY_X: "cw",
	KEY_Z: "ccw",
	KEY_SPACE: "hard",
	KEY_C: "hold",
	KEY_SHIFT: "hold",
}
const DAS := 0.17
const ARR := 0.05

var player: StackState
var cpu: StackState
var state: int = State.READY
var difficulty := "medium"
var mode := "vs"

var _view: BlocksView
var _hud: BlocksHud
var _gestures := StackGestures.new()
var _save: Dictionary
var _ai_rng: RandomNumberGenerator
var _cpu_rng: RandomNumberGenerator
var _cpu_task := -1
var _cpu_plan: Dictionary = {}
var _acc := 0.0
var _cpu_timer := 0.0
var _countdown := 0.0
var _paused_from: int = State.PLAYING
var _bot := false
var _held_key := ""
var _held_time := 0.0
var _bot_timer := 0.0
var _layout: BoardLayout
var _practice: PracticePlan


## Schema 1 -> 2 adds "learned"; anyone who has already played knows the moves.
static func migrate_save(old: Dictionary, from: int, _to: int) -> Dictionary:
	if from < 2 and int(old.get("played", 0)) + int(old.get("solo_played", 0)) > 0:
		old["learned"] = {"rotate": true, "move": true, "drop": true, "hold": true}
	return old


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see CLAUDE.md
	_save = SaveService.game("blocks", SAVE_SCHEMA, SAVE_DEFAULTS, migrate_save)
	_practice = PracticePlan.new(PRACTICE, _save["learned"], Boot.options.has("practice"))
	difficulty = str(SceneRouter.params.get("difficulty", _save["difficulty"]))
	if not LEVELS.has(difficulty):
		difficulty = "medium"
	mode = str(SceneRouter.params.get("mode", _save["mode"]))
	if mode != "vs" and mode != "solo":
		mode = "vs"
	_bot = Boot.bot
	_layout = compute_layout()
	_gestures.cell_px = _layout.drag_step
	_gestures.reject = func(p: Vector2) -> bool: return _layout.rejects_gesture_at(p)
	_new_match()
	_view = BlocksView.new()
	add_child(_view)
	_view.setup(_layout)
	_hud = BlocksHud.new()
	_hud.layout = _layout
	add_child(_hud)
	get_viewport().size_changed.connect(_on_resize)
	_hud.play_requested.connect(_on_play)
	_hud.rematch_requested.connect(_on_rematch)
	_hud.exit_requested.connect(func() -> void: SceneRouter.back_to_hub())
	_hud.pause_requested.connect(_pause)
	_hud.resume_requested.connect(_resume)
	_hud.howto_closed.connect(_on_howto_closed)
	_hud.hold_requested.connect(func() -> void: _player_action("hold"))
	_hud.mode_changed.connect(
		func(m: String) -> void:
			mode = m
			_hud.set_start_stats(_stats_text())
			_on_resize()  # Solo has no CPU column in the top band
			_refresh_preview()
	)
	# The board behind the start panel shows the chosen difficulty's start level.
	_hud.difficulty_changed.connect(
		func(d: String) -> void:
			if state == State.READY:
				difficulty = d
				_new_match()
				_refresh_preview()
	)
	_hud.set_difficulty(difficulty)
	_hud.set_mode(mode)
	_hud.update_states(player, cpu if mode == "vs" else null)
	_view.render(player, 0.0)
	AudioService.play_music("game")
	if SceneRouter.params.get("autostart", false):
		_begin_countdown()
	elif not bool(_save["tutorial_seen"]):
		_hud.show_howto()
	else:
		_hud.show_start(_stats_text())


## Layout from the canvas size, the safe area (notch, gesture bar) and the screen density.
func compute_layout() -> BoardLayout:
	var canvas := get_viewport().get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	var k := canvas.x / maxf(1.0, win.x)  # canvas units per screen pixel
	var insets := {}
	var dp_width := 411.0
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		insets = {
			"top": safe.position.y * k,
			"bottom": (win.y - safe.end.y) * k,
			"left": safe.position.x * k,
			"right": (win.x - safe.end.x) * k,
		}
		dp_width = win.x / maxf(1.0, DisplayServer.screen_get_dpi() / 160.0)
	return BoardLayout.compute(canvas, insets, canvas.x / dp_width, mode == "vs")


func _on_resize() -> void:
	_layout = compute_layout()
	_gestures.cell_px = _layout.drag_step
	_view.apply_layout(_layout)
	_hud.apply_layout(_layout)


func _refresh_preview() -> void:
	if _hud != null and _hud.layout != null:
		_hud.update_states(player, cpu if mode == "vs" else null)
		_view.render(player, 0.0)


func _new_match() -> void:
	_finish_cpu_task()
	if _practice != null:
		_practice.new_match()
	var seed_value := Rng.next_seed()
	var lv: Dictionary = LEVELS[difficulty]
	player = StackLogic.new_game(seed_value, lv.start)
	cpu = StackLogic.new_game(seed_value ^ 0x5bd1e995, lv.start)
	_ai_rng = Rng.make(seed_value ^ 0x2545f491)
	_cpu_rng = Rng.make(seed_value ^ 0x68e31da4)
	_acc = 0.0
	_cpu_timer = 0.0


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
			_repeat_keys(delta)
			_acc = minf(_acc + delta, 0.25)
			while _acc >= STEP and state == State.PLAYING:
				_acc -= STEP
				_fixed_step()
	_view.render(player, delta)


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
		if not _bot:
			_hud.show_hint("Tap to rotate · drag to move · flick down to drop")


func _fixed_step() -> void:
	if _bot:
		_bot_turn()
	_apply_player({"type": "tick", "dt": STEP})
	if mode == "vs" and state == State.PLAYING:
		_cpu_step()
	_hud.update_states(player, cpu if mode == "vs" else null)
	_check_end()


## Applies one action to the player's board and handles its events + outgoing garbage.
func _apply_player(action: Dictionary) -> void:
	player = StackLogic.reduce(player, action)
	for e in player.events:
		_on_player_event(e)
	if player.outgoing > 0 and mode == "vs":
		cpu = StackLogic.reduce(cpu, {"type": "garbage", "rows": player.outgoing})


func _player_action(type: String) -> void:
	if state != State.PLAYING:
		return
	_apply_player({"type": type})
	_hud.update_states(player, cpu if mode == "vs" else null)
	_check_end()


## The CPU plans its next placement on a worker thread while it "thinks" (the search costs
## 40-80 ms in GDScript on a mid-range phone), then applies it when its think time is up.
func _cpu_step() -> void:
	if cpu.over:
		return
	if _cpu_task == -1:
		_start_cpu_plan()
	_cpu_timer += STEP
	var lv: Dictionary = LEVELS[difficulty]
	var think := StackDifficulty.cpu_think(difficulty, cpu.level)
	if _cpu_timer < think or not WorkerThreadPool.is_task_completed(_cpu_task):
		return
	_finish_cpu_task()
	_cpu_timer = 0.0
	if _cpu_plan.is_empty():
		cpu = StackLogic.reduce(cpu, {"type": "hard"})
	else:
		for a in StackAI.actions_for(cpu, _cpu_plan):
			cpu = StackLogic.reduce(cpu, a)
	if cpu.outgoing > 0:
		player = StackLogic.reduce(player, {"type": "garbage", "rows": cpu.outgoing})
		AudioService.play("count", 0.6)
	if not cpu.over:
		_start_cpu_plan()


## Only the CPU's own board decides its plan; incoming garbage changes the board only when
## the CPU locks, so a plan made from this snapshot stays valid until it is applied.
func _start_cpu_plan() -> void:
	var snapshot := cpu.copy()
	var lv: Dictionary = LEVELS[difficulty]
	var rng := _cpu_rng
	_cpu_plan = {}
	_cpu_task = WorkerThreadPool.add_task(
		func() -> void: _cpu_plan = StackAI.choose(snapshot, rng, lv.hold, lv.top_k, lv.noise)
	)


func _finish_cpu_task() -> void:
	if _cpu_task != -1:
		WorkerThreadPool.wait_for_task_completion(_cpu_task)
		_cpu_task = -1


func _exit_tree() -> void:
	_finish_cpu_task()


func _bot_turn() -> void:
	_bot_timer += STEP
	if _bot_timer >= 0.35:
		_bot_timer = 0.0
		var plan := StackAI.choose(player, _ai_rng)
		if not plan.is_empty():
			for a in StackAI.actions_for(player, plan):
				_apply_player(a)


func _on_player_event(e: Dictionary) -> void:
	match e.type:
		"rotate":
			AudioService.play("turn", 1.15)
			_learn("rotate")
		"move":
			AudioService.play("turn", 0.8)
			_learn("move")
		"hard_drop":
			_view.hard_drop_fx()
			AudioService.buzz(12)
			_learn("drop")
		"lock":
			AudioService.play("tap", 0.7)
			_maybe_practice.call_deferred()
		"hold":
			AudioService.play("tap", 1.3)
			_learn("hold")
		"clear":
			var n: int = e.count
			_view.clear_fx(e.rows)
			AudioService.play("eat", 0.9 + 0.1 * n)
			AudioService.buzz(20 + 15 * n)
			if n >= 2:
				var sent: int = StackLogic.GARBAGE_SENT[n]
				var sub := "+%d" % (StackLogic.LINE_SCORES[n] * player.level)
				if mode == "vs" and sent > 0:
					sub += " · %d garbage row%s sent to CPU" % [sent, "" if sent == 1 else "s"]
				_hud.banner(CLEAR_NAMES[n], sub, BlocksHud.ACCENT if n < 4 else UiKit.GOLD)
		"garbage_in":
			AudioService.play("crash", 1.4)
			AudioService.buzz(40)
			_view.hard_drop_fx()


func _check_end() -> void:
	if state != State.PLAYING:
		return
	if player.over or (mode == "vs" and cpu.over):
		_finish()


func _finish() -> void:
	state = State.OVER
	var won := mode == "vs" and cpu.over and not player.over
	var solo := mode == "solo"
	var new_best := solo and player.score > int(_save["solo_best"])
	var info := {}
	if solo:
		info = {
			"title": "NEW BEST!" if new_best else "TOWER FULL",
			"cause": "Your tower reached the top",
			"color": UiKit.GOLD if new_best else Color.WHITE,
		}
	elif won:
		info = {"title": "YOU WIN!", "cause": "The CPU's tower overflowed", "color": UiKit.GOLD}
	else:
		info = {
			"title": "TOWER FULL",
			"cause": "Your tower reached the top",
			"color": Color(1.0, 0.5, 0.55)
		}
	_hud.banner(info.title, info.cause, info.color)
	var coins := 0
	var daily := 0
	if not _bot:
		_record_stats(won, new_best)
		coins = player.score / 100 + (int(WIN_BONUS[difficulty]) if won else 0)
		coins += 20 if new_best else 0
		var stats := {
			"game": "blocks",
			"difficulty": difficulty,
			"won": won,
			"lines": player.lines,
			"score": player.score,
		}
		var profile: Dictionary = SaveService.data["profile"]
		daily = DailyChallenge.report(profile, DailyChallenge.today(), stats)
		SaveService.save()
		Economy.add_coins(coins + daily)
	var best := int(_save["solo_best" if solo else "best_score"])
	info["stats"] = (
		"Score %s  ·  Lines %d  ·  Best %s"
		% [UiKit.format_int(player.score), player.lines, UiKit.format_int(best)]
	)
	info["coins"] = coins + daily
	info["daily"] = "Daily challenge complete! +%d" % daily if daily > 0 else ""
	var tw := create_tween()
	tw.tween_interval(1.3)
	tw.tween_callback(func() -> void: AudioService.play("win" if won or new_best else "lose"))
	tw.tween_callback(_hud.show_end.bind(info))


func _record_stats(won: bool, _new_best: bool) -> void:
	_save["tutorial_seen"] = true
	_save["best_lines"] = maxi(int(_save["best_lines"]), player.lines)
	if mode == "solo":
		_save["solo_played"] = int(_save["solo_played"]) + 1
		_save["solo_best"] = maxi(int(_save["solo_best"]), player.score)
		return
	_save["played"] = int(_save["played"]) + 1
	_save["wins" if won else "losses"] = int(_save["wins" if won else "losses"]) + 1
	_save["best_score"] = maxi(int(_save["best_score"]), player.score)


func _stats_text() -> String:
	if mode == "solo":
		return (
			"Solo best %s  ·  Runs %d"
			% [UiKit.format_int(int(_save["solo_best"])), int(_save["solo_played"])]
		)
	return (
		"Best %s  ·  Wins %d of %d"
		% [UiKit.format_int(int(_save["best_score"])), int(_save["wins"]), int(_save["played"])]
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
	_on_rematch()


func _on_rematch() -> void:
	_new_match()
	_hud.update_states(player, cpu if mode == "vs" else null)
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
		_maybe_practice()


## The player did a move: remember it (saved once) and retire its hint.
func _learn(verb: String) -> void:
	if _bot:
		return
	if _practice.learn(verb):
		SaveService.save()
	_hud.hide_practice(verb)


## Shows the next due practice hint over the real board (never during bot runs or overlays).
func _maybe_practice() -> void:
	if _bot or state != State.PLAYING or _hud.practice_showing():
		return
	var verb := _practice.due(player.pieces)
	if verb == "":
		return
	var w := _layout.well
	var mid := w.get_center()
	var cap := Vector2(mid.x, w.position.y + w.size.y * 0.25)
	match verb:
		"rotate":
			var at := Vector2(mid.x + w.size.x * 0.2, mid.y)
			_hud.show_practice(verb, "tap", at, at, "Tap to rotate", cap)
		"move":
			var step := _layout.drag_step
			var from := Vector2(mid.x - 1.5 * step, mid.y)
			_hud.show_practice(
				verb, "drag", from, from + Vector2(3 * step, 0), "Drag to move", cap, 3
			)
		"drop":
			var from := Vector2(mid.x, w.position.y + w.size.y * 0.35)
			_hud.show_practice(
				verb, "flick", from, from + Vector2(0, 320), "Flick down to drop", cap
			)
		"hold":
			var at := _layout.hold.get_center()
			_hud.show_practice(verb, "tap", at, at, "Tap HOLD to save a shard", cap)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_pause()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if _hud.settings_open():
				_hud.close_settings()
			elif _hud.howto_open():
				_hud.close_howto()
			elif state == State.PLAYING or state == State.COUNTDOWN:
				_pause()
			elif state == State.PAUSED:
				_resume()
			else:
				SceneRouter.back_to_hub()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING or _bot:
		return
	for a in _gestures.feed(event, Time.get_ticks_msec()):
		_player_action(a)
	var key := event as InputEventKey
	if key != null and not key.echo:
		var action: String = KEY_ACTIONS.get(key.keycode, "")
		if action == "":
			return
		if key.pressed:
			_player_action(action)
			if action in ["left", "right", "soft"]:
				_held_key = action
				_held_time = -DAS
		elif action == _held_key:
			_held_key = ""


## Desktop keys: delayed auto-shift then auto-repeat (DAS 170 ms, ARR 50 ms).
func _repeat_keys(delta: float) -> void:
	if _held_key == "":
		return
	_held_time += delta
	while _held_time >= ARR:
		_held_time -= ARR
		_player_action(_held_key)
