extends Node3D
## Cue Club controller: Casual 8 vs the CPU. Owns the PoolMatch (solver + rules), feeds the
## view and HUD, turns touch into aim / ball in hand / pocket calls, steps the solver at a fixed
## 60 Hz (4 substeps of 1/240 s) and renders with interpolation (root interpolation OFF).

enum State { READY, AIM, CPU_THINK, CPU_AIM, ROLLING, PAUSED, OVER }

const STEP := 1.0 / 60.0
const SAVE_SCHEMA := 1
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"difficulty": "medium",
	"tutorial_seen": false,
	"learned": {},
}
const WIN_BONUS := {"easy": 20, "medium": 40, "hard": 80}
const GUIDE := {"easy": [2.0, 0.6], "medium": [0.45, 0.25], "hard": [0.12, 0.0]}
const PREVIEW_SPEED := 2.0

var state: int = State.READY
var difficulty := "medium"

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
var _paused_from: int = State.AIM
var _log_seen := 0
var _bot := false
var _potted_by := PackedInt32Array([0, 0])


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see CLAUDE.md
	get_viewport().msaa_3d = Viewport.MSAA_2X  # thin aim lines and ball edges (research default)
	tree_exiting.connect(func() -> void: get_viewport().msaa_3d = Viewport.MSAA_DISABLED)
	_save = SaveService.game("pool", SAVE_SCHEMA, SAVE_DEFAULTS)
	difficulty = str(SceneRouter.params.get("difficulty", _save["difficulty"]))
	if not GUIDE.has(difficulty):
		difficulty = "medium"
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
	_hud.set_mode("vs")
	_hud.set_players(_match.state)
	AudioService.play_music("game")
	if SceneRouter.params.get("autostart", false):
		_start_turns()
	elif not bool(_save["tutorial_seen"]):
		_hud.show_howto()
	else:
		_hud.show_start(_stats_text())


func _new_match() -> void:
	var seed_value := Rng.next_seed()
	_rng = Rng.make(seed_value ^ 0x3c6ef372)
	_match = PoolMatch.new(seed_value & 0x7FFFFFFF, 0)
	_potted_by = PackedInt32Array([0, 0])
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


func _on_play(d: String, _m: String) -> void:
	difficulty = d
	_save["difficulty"] = d
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
	_hud.set_players(_match.state)
	_next_turn()


func _next_turn() -> void:
	_view.snap()
	_hud.set_players(_match.state)
	_hud.set_breaking(_match.state.phase == PoolState.Phase.BREAK)
	if _match.over():
		_finish()
		return
	if _match.state.shooter == 0 and not _bot:
		state = State.AIM
		_hud.set_controls(true)
		_preview_dirty = true
		_update_message()
	else:
		state = State.CPU_THINK
		_timer = 0.9
		_hud.set_controls(false)
		_view.hide_aim()
		_view.show_pockets(false)
		_hud.set_message("CPU is thinking..." if not _bot else "")


func _update_message() -> void:
	var s := _match.state
	var text := "Drag to aim · pull the power bar to shoot"
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


func _shoot(d: Vector2, speed: float, side: float, top: float) -> void:
	if not _match.strike(d.x, d.y, speed, side, top):
		return
	AudioService.play("cue", 0.8 + speed * 0.04)
	AudioService.buzz(int(8 + speed * 1.5))
	_log_seen = 0
	state = State.ROLLING
	_hud.set_controls(false)
	_hud.set_message("")
	_view.hide_aim()
	_view.show_pockets(false)
	_view.show_kitchen(false)
	_hud.reset_spin()


func _settle() -> void:
	var shooter := _match.state.shooter
	var r := _match.settle()
	for p in PoolShot.from_sim(_match.sim).pocketed:
		if p[0] != 0 and p[0] != 8:
			_potted_by[shooter] += 1
	var who := "You" if shooter == 0 else "CPU"
	if r.outcome == PoolRules.Outcome.RERACK:
		_hud.banner("RE-RACK", "24 shots without a pot", Color.WHITE)
	elif r.outcome == PoolRules.Outcome.GAME_OVER:
		pass
	elif r.foul():
		var text: String = PoolRules.FOUL_TEXT.get(r.fouls[0], "Foul")
		var next := "Ball in hand for the CPU" if shooter == 0 else "Ball in hand for you"
		_hud.banner("FOUL", "%s · %s" % [text, next], Color(1.0, 0.45, 0.4))
		AudioService.play("crash", 1.4)
		AudioService.buzz(30)
	elif r.assigned:
		var g := _match.state.group[0]
		var gname := "SOLIDS 1-7" if g == PoolState.Group.SOLIDS else "STRIPES 9-15"
		_hud.banner("YOU: " + gname, "%s potted first" % who, PoolHud.ACCENT)
	elif r.outcome == PoolRules.Outcome.CONTINUE and shooter == 0:
		_hud.set_message("Nice - your turn again")
	_next_turn()


func _finish() -> void:
	state = State.OVER
	_hud.set_controls(false)
	_view.hide_aim()
	var s := _match.state
	var won := s.winner == 0
	var reason: String = (
		{
			PoolRules.Reason.WIN: "The 8 went in the called pocket",
			PoolRules.Reason.EIGHT_OFF_TABLE: "The 8 left the table",
			PoolRules.Reason.EARLY_EIGHT: "The 8 went in too early",
			PoolRules.Reason.EIGHT_WITH_FOUL: "The 8 went in on a foul",
			PoolRules.Reason.WRONG_POCKET: "The 8 went in the wrong pocket",
			PoolRules.Reason.SCRATCH_ON_EIGHT: "Scratch on the 8",
		}
		. get(s.end_reason, "")
	)
	var coins := 0
	var daily := 0
	if not _bot:
		_save["played"] = int(_save["played"]) + 1
		_save["wins" if won else "losses"] = int(_save["wins" if won else "losses"]) + 1
		coins = int(WIN_BONUS[difficulty]) if won else 5
		var stats := {"game": "pool", "difficulty": difficulty, "won": won, "score": _potted_by[0]}
		daily = DailyChallenge.report(SaveService.data["profile"], DailyChallenge.today(), stats)
		SaveService.save()
		Economy.add_coins(coins + daily)
	_hud.banner("YOU WIN!" if won else "CPU WINS", reason, UiKit.GOLD if won else Color.WHITE)
	var info := {
		"title": "YOU WIN!" if won else "YOU LOSE",
		"color": UiKit.GOLD if won else Color(1.0, 0.45, 0.4),
		"cause": reason,
		"stats":
		"Balls potted %d · CPU %d · Wins %d" % [_potted_by[0], _potted_by[1], int(_save["wins"])],
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
			if _timer <= 0.0:
				_cpu_plan = PoolCpu.plan(_match, difficulty, _rng)
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


func _cue_pos() -> Vector2:
	return Vector2(_match.sim.px[0], _match.sim.py[0])


## Click on contacts (rate-limited), drop sound on pots.
func _sounds() -> void:
	var log := _match.sim.log
	var plays := 0
	while _log_seen + 2 < log.size() and plays < 3:
		match log[_log_seen]:
			CueSim.Ev.BALL_HIT:
				AudioService.play("clack", _fx_rng.randf_range(0.9, 1.15))
			CueSim.Ev.POCKET:
				AudioService.play("pocket")
				AudioService.buzz(15)
		_log_seen += 3
		plays += 1
	if plays >= 3:
		_log_seen = log.size() - log.size() % 3


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


## The cue points from the white ball at the finger; Easy / Medium lock onto a legal ball's centre
## when the aim passes within 0.6 / 0.3 degrees of it.
func _point(at: Vector2) -> void:
	var snap := {"easy": 0.6, "medium": 0.3}.get(difficulty, 0.0) as float
	var centres := []
	if snap > 0.0:
		for b in PoolRules.legal_targets(_match.state):
			centres.append(Vector2(_match.sim.px[b], _match.sim.py[b]))
	_aim.point_at(_cue_pos(), at, Time.get_ticks_msec(), centres, deg_to_rad(snap))


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
