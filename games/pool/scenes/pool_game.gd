extends Node3D
## Cue Club controller: Casual 8 vs the CPU. Owns the PoolMatch (solver + rules), feeds the
## view and HUD, turns touch into aim / ball in hand / pocket calls, steps the solver at a fixed
## 60 Hz (4 substeps of 1/240 s) and renders with interpolation (root interpolation OFF).

enum State { READY, AIM, CPU_THINK, CPU_AIM, STROKE, ROLLING, PAUSED, OVER }

const STEP := 1.0 / 60.0
const SAVE_SCHEMA := 2
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"difficulty": "medium",
	"mode": "vs",
	"tutorial_seen": false,
	"learned": {},
}
const WIN_BONUS := {"easy": 20, "medium": 40, "hard": 80}
const GUIDE := {"easy": [2.0, 0.6], "medium": [0.45, 0.25], "hard": [0.12, 0.0]}
const PREVIEW_SPEED := 2.0
const MODES := {"vs": "Single rack", "bo3": "Best of 3"}
const FRAME_GAP := 2.6  # seconds between frames of a best of 3

var state: int = State.READY
var difficulty := "medium"
var mode := "vs"

var _match: PoolMatch
var _aim := PoolAim.new()
## What the player sees: eases towards _aim so the lines glide instead of jumping.
var _shown := PoolAim.new()
var _view: PoolView
var _hud: PoolHud
var _save: Dictionary
var _rng: RandomNumberGenerator
## Cosmetic randomness (sound pitch), seeded so it never touches the global RNG (CLAUDE.md).
var _fx_rng := Rng.make(0x51ed)
var _side := 0.0
var _top := 0.0
var _power := 0.0
var _preview_dirty := true
var _drag := ""  # "", "aim", "place"
var _drag_last := Vector2.ZERO
var _finger_down := false
var _timer := 0.0
var _cpu_plan := {}
var _cpu_task := -1
var _paused_from: int = State.AIM
var _log_seen := 0
var _bot := false
var _series: PoolSeries


## Schema 1 -> 2 adds "mode" (filled from the defaults); everything else is kept.
static func migrate_save(old: Dictionary, _from: int, _to: int) -> Dictionary:
	return old


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see CLAUDE.md
	get_viewport().msaa_3d = Viewport.MSAA_2X  # thin aim lines and ball edges (research default)
	tree_exiting.connect(func() -> void: get_viewport().msaa_3d = Viewport.MSAA_DISABLED)
	_save = SaveService.game("pool", SAVE_SCHEMA, SAVE_DEFAULTS, migrate_save)
	difficulty = str(SceneRouter.params.get("difficulty", _save["difficulty"]))
	if not GUIDE.has(difficulty):
		difficulty = "medium"
	mode = str(SceneRouter.params.get("mode", _save["mode"]))
	if not MODES.has(mode):
		mode = "vs"
	_bot = Boot.bot
	_new_match()
	_view = PoolView.new()
	add_child(_view)
	_view.setup(_match.sim)
	_hud = PoolHud.new()
	add_child(_hud)
	_view.set_margins(_hud.top_band, _hud.bottom_band)
	_hud.play_requested.connect(_on_play)
	_hud.rematch_requested.connect(_on_rematch)
	_hud.exit_requested.connect(func() -> void: SceneRouter.back_to_hub())
	_hud.pause_requested.connect(_pause)
	_hud.resume_requested.connect(_resume)
	_hud.howto_closed.connect(_on_howto_closed)
	_hud.shoot.connect(_on_power_release)
	_hud.nudge.connect(
		func(dp: float) -> void:
			_aim.nudge(dp, Time.get_ticks_msec())
			_preview_dirty = true
	)
	_hud.spin_changed.connect(
		func(s: float, t: float) -> void:
			_side = s
			_top = t
			_preview_dirty = true
	)
	_hud.power_bar.changed.connect(func(p: float) -> void: _power = p)
	_hud.set_difficulty(difficulty)
	_hud.set_mode(mode)
	_hud.set_players(_match.state, _series)
	AudioService.play_music("game")
	if SceneRouter.params.get("autostart", false):
		_start_turns()
	elif not bool(_save["tutorial_seen"]):
		_hud.show_howto()
	else:
		_hud.show_start(_stats_text())


func _new_match() -> void:
	_series = PoolSeries.new(mode)
	_new_frame()


## A fresh rack; breaks alternate by frame.
func _new_frame() -> void:
	var seed_value := Rng.next_seed()
	_rng = Rng.make(seed_value ^ 0x3c6ef372)
	_match = PoolMatch.new(seed_value & 0x7FFFFFFF, _series.breaker())
	_aim = PoolAim.new()
	_aim.set_dir(Vector2(0.0, 1.0))
	_shown = PoolAim.new()
	_shown.angle = _aim.angle
	if _view != null:
		_view.sim = _match.sim
		_view.snap()


func _stats_text() -> String:
	return "Wins %d of %d" % [int(_save["wins"]), int(_save["played"])]


# --- turn flow ----------------------------------------------------------------------------------


func _on_play(d: String, m: String) -> void:
	difficulty = d
	mode = m if MODES.has(m) else "vs"
	_save["difficulty"] = d
	_save["mode"] = mode
	SaveService.save()
	_on_rematch()


func _on_rematch() -> void:
	_new_match()
	_hud.hide_panels()
	_start_turns()


func _on_howto_closed() -> void:
	_save["tutorial_seen"] = true
	SaveService.save()
	if state == State.READY:
		_hud.show_start(_stats_text())


func _start_turns() -> void:
	_hud.hide_panels()
	_hud.set_players(_match.state, _series)
	_next_turn()


func _next_turn() -> void:
	_view.snap()
	_hud.set_players(_match.state, _series)
	_hud.set_breaking(_match.state.phase == PoolState.Phase.BREAK)
	if _match.over():
		_frame_over()
		return
	if _match.state.shooter == 0 and not _bot:
		state = State.AIM
		if _match.state.phase == PoolState.Phase.BREAK:
			_hud.reset_spin(PoolAim.BREAK_TOP)
		_hud.set_controls(true)
		_preview_dirty = true
		_update_message()
	else:
		state = State.CPU_THINK
		_timer = 0.9
		_start_cpu_plan()
		_hud.set_controls(false)
		_view.hide_aim()
		_view.show_pockets(false)
		_hud.set_message("CPU is thinking..." if not _bot else "")


func _update_message() -> void:
	var s := _match.state
	var text := "Touch to aim · pull the power bar to shoot"
	_view.show_kitchen(s.ball_in_hand == PoolState.Hand.KITCHEN)
	if s.ball_in_hand == PoolState.Hand.KITCHEN:
		text = "Your break: drag the white ball behind the line, then shoot"
	elif s.ball_in_hand == PoolState.Hand.ANYWHERE:
		text = "Ball in hand: drag the white ball anywhere"
	if PoolRules.requires_call(s):
		text = "On the 8: tap a pocket to call it" if s.called_pocket < 0 else "8 called - shoot"
		_view.show_pockets(true, s.called_pocket)
	else:
		_view.show_pockets(false)
	_hud.set_message(text)


func _on_power_release(power: float) -> void:
	if state != State.AIM:
		return
	if PoolRules.requires_call(_match.state) and _match.state.called_pocket < 0:
		_hud.set_message("Call a pocket for the 8 first - tap one")
		AudioService.play("count", 0.6)
		return
	var breaking := _match.state.phase == PoolState.Phase.BREAK
	var d := _aim.dir()
	_shoot(d, PoolAim.speed_for(power, breaking), _side, _top)


## A shot: the cue strokes forward (70 ms, faster for harder shots), then the ball is struck.
func _shoot(d: Vector2, speed: float, side: float, top: float) -> void:
	if PoolRules.requires_call(_match.state) and _match.state.called_pocket < 0:
		return
	state = State.STROKE
	_hud.set_controls(false)
	_hud.set_message("")
	_view.show_pockets(false)
	_view.show_kitchen(false)
	var stroke := clampf(0.11 - speed * 0.006, 0.05, 0.1)
	var tw := _view.strike_cue(_cue_pos(), d, stroke)
	get_tree().create_timer(stroke).timeout.connect(
		func() -> void:
			if state != State.STROKE or not _match.strike(d.x, d.y, speed, side, top):
				return
			AudioService.play(
				"cue", 0.8 + speed * 0.04, clampf(linear_to_db(speed / 6.0), -14.0, 0.0)
			)
			AudioService.buzz(int(8 + speed * 1.5))
			_log_seen = 0
			state = State.ROLLING
			_hud.reset_spin()
	)
	tw.play()


func _settle() -> void:
	var shooter := _match.state.shooter
	var potted := 0
	for p in PoolShot.from_sim(_match.sim).pocketed:
		if p[0] != 0:
			potted += 1
	var r := _match.settle()
	_series.record_shot(shooter, potted, r.foul())
	var who := "You" if shooter == 0 else "CPU"
	if r.outcome == PoolRules.Outcome.RERACK:
		_hud.banner("RE-RACK", "24 shots without a pot", Color.WHITE)
	elif r.outcome == PoolRules.Outcome.GAME_OVER:
		pass
	elif r.foul():
		var text: String = PoolRules.FOUL_TEXT.get(r.fouls[0], "Foul")
		var next := "Ball in hand for the CPU" if shooter == 0 else "Ball in hand for you"
		_hud.banner("FOUL", "%s · %s" % [text, next], Color(1.0, 0.45, 0.4))
		AudioService.play("foul", 1.0, -4.0)
		AudioService.buzz(18)
	elif r.assigned:
		var g := _match.state.group[0]
		var gname := "SOLIDS 1-7" if g == PoolState.Group.SOLIDS else "STRIPES 9-15"
		_hud.banner("YOU: " + gname, "%s potted first" % who, PoolHud.ACCENT)
	elif r.outcome == PoolRules.Outcome.CONTINUE and shooter == 0:
		_hud.set_message("Nice - your turn again")
	_next_turn()


func _end_reason() -> String:
	return (
		{
			PoolRules.Reason.WIN: "The 8 went in the called pocket",
			PoolRules.Reason.EIGHT_OFF_TABLE: "The 8 left the table",
			PoolRules.Reason.EARLY_EIGHT: "The 8 went in too early",
			PoolRules.Reason.EIGHT_WITH_FOUL: "The 8 went in on a foul",
			PoolRules.Reason.WRONG_POCKET: "The 8 went in the wrong pocket",
			PoolRules.Reason.SCRATCH_ON_EIGHT: "Scratch on the 8",
		}
		. get(_match.state.end_reason, "")
	)


## A rack is over: the match ends, or the next frame of a best of 3 starts after a banner.
func _frame_over() -> void:
	state = State.OVER
	_hud.set_controls(false)
	_view.hide_aim()
	_view.show_pockets(false)
	_view.show_kitchen(false)
	var w := _match.state.winner
	if _series.record_frame(w):
		_finish()
		return
	_hud.set_players(_match.state, _series)
	var score := "%d-%d" % [_series.frames[0], _series.frames[1]]
	var next := "You break next" if _series.breaker() == 0 else "CPU breaks next"
	_hud.banner(
		"FRAME TO YOU" if w == 0 else "FRAME TO CPU",
		"%s · %s · %s" % [_end_reason(), score, next],
		UiKit.GOLD if w == 0 else Color.WHITE
	)
	AudioService.play("eat" if w == 0 else "count", 1.0, -4.0)
	var tw := create_tween()
	tw.tween_interval(FRAME_GAP)
	tw.tween_callback(
		func() -> void:
			if state != State.OVER or _series.over():
				return
			_new_frame()
			_start_turns()
	)


func _finish() -> void:
	state = State.OVER
	_hud.set_controls(false)
	_view.hide_aim()
	var won := _series.winner() == 0
	var reason := _end_reason()
	var bo3 := _series.target > 1
	var coins := 0
	var daily := 0
	if not _bot:
		_save["played"] = int(_save["played"]) + 1
		_save["wins" if won else "losses"] = int(_save["wins" if won else "losses"]) + 1
		coins = (int(WIN_BONUS[difficulty]) if won else 5) * (2 if bo3 else 1)
		var stats := {
			"game": "pool", "difficulty": difficulty, "won": won, "score": _series.balls[0]
		}
		daily = DailyChallenge.report(SaveService.data["profile"], DailyChallenge.today(), stats)
		SaveService.save()
		Economy.add_coins(coins + daily)
	_hud.banner("YOU WIN!" if won else "CPU WINS", reason, UiKit.GOLD if won else Color.WHITE)
	var score := " %d-%d" % [_series.frames[0], _series.frames[1]] if bo3 else ""
	var stats_text := (
		"Potted %d · Best run %d · Pot rate %d%%\nCPU potted %d · Wins %d"
		% [
			_series.balls[0],
			_series.best_run[0],
			roundi(100.0 * _series.pot_rate(0)),
			_series.balls[1],
			int(_save["wins"])
		]
	)
	var info := {
		"title": ("YOU WIN" if won else "YOU LOSE") + (score if bo3 else "!" if won else ""),
		"color": UiKit.GOLD if won else Color(1.0, 0.45, 0.4),
		"cause": reason,
		"stats": stats_text,
		"coins": coins + daily,
		"daily": "Daily challenge complete! +%d" % daily if daily > 0 else "",
	}
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_callback(func() -> void: AudioService.play("win" if won else "lose"))
	tw.tween_callback(_hud.show_end.bind(info))


# --- per frame ----------------------------------------------------------------------------------


func _physics_process(_delta: float) -> void:
	match state:
		State.ROLLING:
			var steps := 4 if _finger_down else 1  # hold to fast-forward
			for i in steps:
				_match.sim.step(STEP)
				_view.physics_tick(STEP)
				_sounds()
				if not _match.sim.is_moving():
					_settle()
					return
		State.CPU_THINK:
			_view.physics_tick(STEP)
			_timer -= STEP
			if _timer <= 0.0 and WorkerThreadPool.is_task_completed(_cpu_task):
				_finish_cpu_task()
				if _cpu_plan.place != null:
					var p: Vector2 = _cpu_plan.place
					_match.place_cue(p.x, p.y)
					_view.snap()
				if _cpu_plan.pocket >= 0 and PoolRules.requires_call(_match.state):
					_match.call_pocket(_cpu_plan.pocket)
				_aim.set_dir(_cpu_plan.dir)
				_aim.predict(_match.sim, PREVIEW_SPEED, _cpu_plan.side, _cpu_plan.top)
				state = State.CPU_AIM
				_timer = 0.8
		State.CPU_AIM:
			_view.physics_tick(STEP)
			_timer -= STEP
			var pull := clampf(1.0 - _timer / 0.8, 0.0, 1.0) * 0.6
			_view.show_aim(_cue_pos(), _aim, pull, 0.3, 0.0)
			if _timer <= 0.0:
				_shoot(_cpu_plan.dir, _cpu_plan.speed, _cpu_plan.side, _cpu_plan.top)
		_:
			_view.physics_tick(STEP)


func _process(_delta: float) -> void:
	if state == State.AIM:
		var diff := angle_difference(_shown.angle, _aim.angle)
		if absf(diff) > 1e-5:
			_shown.angle += diff * (1.0 - exp(-28.0 * _delta))
			_preview_dirty = true
		if _preview_dirty:
			_preview_dirty = false
			var breaking := _match.state.phase == PoolState.Phase.BREAK
			var speed := PoolAim.speed_for(_power, breaking) if _power > 0.0 else PREVIEW_SPEED
			_shown.predict(_match.sim, speed, _side, _top)
		var guide: Array = GUIDE[difficulty]
		_view.show_aim(_cue_pos(), _shown, _power, guide[0], guide[1])
	_view.render(Engine.get_physics_interpolation_fraction())


## The CPU plans on a worker thread with its own copy of the match (simulated rollouts take
## tens to hundreds of ms on a phone); the main thread keeps rendering.
func _start_cpu_plan() -> void:
	_finish_cpu_task()
	var snap := _match.snapshot()
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng.randi()
	var diff := difficulty
	_cpu_plan = {}
	_cpu_task = WorkerThreadPool.add_task(func() -> void: _cpu_plan = PoolCpu.plan(snap, diff, rng))


func _finish_cpu_task() -> void:
	if _cpu_task != -1:
		WorkerThreadPool.wait_for_task_completion(_cpu_task)
		_cpu_task = -1


func _exit_tree() -> void:
	_finish_cpu_task()


func _cue_pos() -> Vector2:
	return Vector2(_match.sim.px[0], _match.sim.py[0])


## Contact sounds scaled by impact speed (rate-limited per tick; quiet touches skipped):
## ball clicks, cushion thuds, pocket drops; a light buzz only on pots.
func _sounds() -> void:
	var log := _match.sim.log
	var speeds := _match.sim.log_speed
	var plays := 0
	while _log_seen + 2 < log.size():
		var v: float = speeds[_log_seen / 3]
		var kind := log[_log_seen]
		var ball := log[_log_seen + 1]
		var pocket := log[_log_seen + 2]
		_log_seen += 3
		if kind == CueSim.Ev.POCKET and ball != 0:
			_hud.fly_ball(ball, _view.pocket_screen(pocket), _match.state)
		if plays >= 4 or (v < 0.05 and kind != CueSim.Ev.POCKET):
			continue
		var vol := clampf(linear_to_db(clampf(v / 3.0, 0.08, 1.0)), -22.0, 0.0)
		match kind:
			CueSim.Ev.BALL_HIT:
				AudioService.play("clack", _fx_rng.randf_range(0.94, 1.08), vol)
			CueSim.Ev.CUSHION:
				AudioService.play("cushion", _fx_rng.randf_range(0.92, 1.06), vol - 2.0)
			CueSim.Ev.POCKET:
				AudioService.play("pocket", _fx_rng.randf_range(0.95, 1.05), maxf(vol, -10.0))
				AudioService.buzz(14)
		plays += 1


# --- input --------------------------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		_finger_down = mb.pressed
		if mb.pressed:
			_press(mb.position)
		else:
			if _drag == "aim":
				_aim.release(Time.get_ticks_msec())
				_preview_dirty = true
			_drag = ""
	var mm := event as InputEventMouseMotion
	if mm != null and _drag != "" and state == State.AIM:
		var now := _view.table_point(mm.position)
		if _drag == "aim":
			_point(now)
		elif _drag == "place":
			var target := _cue_pos() + (now - _drag_last)
			if _match.place_cue(target.x, target.y):
				_view.snap()
		_drag_last = now
		_preview_dirty = true


func _press(screen: Vector2) -> void:
	if state != State.AIM:
		return
	var s := _match.state
	if PoolRules.requires_call(s):
		for k in 6:
			if screen.distance_to(_view.pocket_screen(k)) < 110.0:
				_match.call_pocket(k)
				AudioService.play("tap")
				_update_message()
				return
	var at := _view.table_point(screen)
	_drag_last = at
	if (
		s.ball_in_hand != PoolState.Hand.NONE
		and screen.distance_to(_view.screen_point(_cue_pos())) < 120.0
	):
		_drag = "place"
	else:
		_drag = "aim"
		_point(at)
		_preview_dirty = true


## The cue points from the white ball at the finger. Easy / Medium lock onto a pocket line - the
## ghost-ball aim that sends a legal ball at a pocket - when within 0.6 / 0.3 degrees of it.
## (Snapping to ball centres blocked thin cuts.)
func _point(at: Vector2) -> void:
	var snap := {"easy": 0.6, "medium": 0.3}.get(difficulty, 0.0) as float
	var ghosts := []
	if snap > 0.0:
		var sim := _match.sim
		for b in PoolRules.legal_targets(_match.state):
			var obj := Vector2(sim.px[b], sim.py[b])
			for k in sim.table.pocket_count():
				var to_pocket := Vector2(sim.table.pocket_x[k], sim.table.pocket_y[k]) - obj
				ghosts.append(obj - to_pocket.normalized() * 2.0 * sim.p.radius)
	_aim.point_at(_cue_pos(), at, Time.get_ticks_msec(), ghosts, deg_to_rad(snap))


func _pause() -> void:
	if state == State.PAUSED or state == State.OVER or state == State.READY:
		return
	_paused_from = state
	state = State.PAUSED
	_hud.show_pause(true)
	_hud.set_controls(false)


func _resume() -> void:
	if state == State.PAUSED:
		state = _paused_from
		_hud.show_pause(false)
		_hud.set_controls(state == State.AIM)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_pause()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if _hud.settings_open():
				_hud.close_settings()
			elif _hud.howto_open():
				_hud.close_howto()
			elif _hud.spin_panel.visible:
				_hud.spin_panel.close()
			elif state == State.PAUSED:
				_resume()
			elif state != State.READY and state != State.OVER:
				_pause()
			else:
				SceneRouter.back_to_hub()
