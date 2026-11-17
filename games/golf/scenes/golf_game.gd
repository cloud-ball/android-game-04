extends Node3D
## Fairway Flick - arcade mini-golf (step D of docs/plans/2026-11-15-fairway-flick-minigolf.md),
## still behind enabled = false. Plays World 1's holes (games/golf/data/mini/*.json) in a row, solo.
## Shot: press anywhere above the HUD, drag back like a slingshot and release - the ball goes the
## opposite way, power = drag length. A dotted guide shows the ball's real path (the same solver,
## up to the first wall bounce and a bit). Drag back under the dead zone to cancel. The camera sits
## low behind the ball and does not move while you drag (aiming stays stable).
## Nodes move in _process from interpolated solver states, so root interpolation is OFF.

enum Mode { INTRO, AIM, DRAG, MOVING, RESULT }

const SAVE_SCHEMA := 1
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"best_score": 0,
	"difficulty": "medium",
	"tutorial_seen": false,
}
const HOLES := [
	"res://games/golf/data/mini/meadow_01.json",
	"res://games/golf/data/mini/meadow_02.json",
	"res://games/golf/data/mini/meadow_03.json",
]
const MAX_SPEED := 13.0  # m/s at a full pull
const POWER_CURVE := 1.3  # speed = MAX x pull^1.3: the first third of the pull gives fine putts
const SLOWMO := 0.3  # presentation rate around a great hole-out (physics unchanged)
const PULL_FULL := 420.0  # canvas px of drag for full power
const DEAD := 30.0  # px: shorter drags cancel
const GUIDE_TIME := 1.2  # seconds of path shown by the guide (shrinks later with difficulty)
const INTRO_TIME := 3.0
const INTRO_HOLD := 0.8  # seconds on the establishing shot before the glide
## Camera (phone feedback: the low chase camera swung on every bounce and hid the ball behind
## walls): an angled view from behind and above (~50 degrees down). It turns only while aiming;
## while the ball rolls it glides along without rotating.
const CAM_BACK := 4.2
const CAM_UP := 5.0
const CAM_AHEAD := 2.2
const NAMES := {
	-3: "Albatross!", -2: "Eagle!", -1: "Birdie!", 0: "Par", 1: "Bogey", 2: "Double bogey"
}

var mode: int = Mode.INTRO

var _save: Dictionary
var _preset := CoursePreset.new()
var _index := 0
var _spec: Dictionary
var _hole: HoleData
var _ball: GolfBall
var _world: Node3D
var _strokes := 0
var _total := 0
var _ball_at := Vector3.ZERO
var _aim := Vector3(0, 0, -1)  # horizontal unit vector the camera looks along
var _shot_dir := Vector3(0, 0, -1)
var _power := 0.0
var _drag_from := Vector2.ZERO
var _cam_right := Vector3.RIGHT
var _cam_fwd := Vector3.FORWARD
var _result_t := 0.0
var _intro_t := 0.0
var _landmark := Vector3.ZERO  # the intro opens on it
var _hole_over := false
var _prev := Vector3.ZERO
var _cur := Vector3.ZERO
var _events_seen := 0
var _bot_t := 0.0

var _ball_mesh: MeshInstance3D
var _shadow: MeshInstance3D
var _flag: Node3D
var _guide: ImmediateMesh
var _puff: CPUParticles3D
var _splash: CPUParticles3D
var _cam: Camera3D
var _cam_ready := false
var _cam_dir := Vector3(0, 0, -1)  # horizontal facing, smoothed; fixed while the ball moves
var _overview := false
var _map_btn: Button
var _ring: MeshInstance3D
var _cup_glow: MeshInstance3D
var _confetti: CPUParticles3D
var _sparks: CPUParticles3D
var _theme := GolfTheme.meadow()
var _fx_rng := Rng.make(0x6f1f)
var _clock := PresentationClock.new()
var _hole_at := -1.0  # solver time the predicted cup drop happens (-1: this shot misses)
var _slowmo := false
var _slow_ok := false  # this shot would earn slow motion if it drops
var _forecast := ShotForecast.new()
var _kick := Vector3.ZERO  # camera kick on release, springs back
var _trauma := 0.0  # screen shake 0..1 (hole-in-one), decays
var _squash := 0.0  # seconds of ball squash left after a rail hit
var _last_tick := 0  # power tick haptics: last 10% band and time
var _last_tick_ms := 0
var _trail_pts := PackedVector3Array()
var _trail_speed := PackedFloat32Array()
var _trail_head := 0
var _trail_n := 0
var _trail: ImmediateMesh
var _flag_cloth: MeshInstance3D
var _stars: Label
var _hud_top: Label
var _hud_info: Label
var _banner: Label
var _hint: Label
var _card: Label
var _power_ui: Control


## Schema history: 1 = first version. Bump SAVE_SCHEMA and handle `from` here on any change.
static func migrate_save(old: Dictionary, _from: int, _to: int) -> Dictionary:
	return old


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see the project rules
	_save = SaveService.game("golf", SAVE_SCHEMA, SAVE_DEFAULTS, migrate_save)
	_preset.stimp = 9.0
	_cam = Camera3D.new()
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 62.0
	_cam.far = 1500.0
	add_child(_cam)
	_cam.make_current()
	_build_ui()
	_load_hole(int(Boot.options.get("hole", 1)) - 1)  # --hole=<n> for screenshots


# --- world ---------------------------------------------------------------------------------------


func _load_hole(i: int) -> void:
	_index = i % HOLES.size()
	if i > 0 and _index == 0:
		_total = 0
	_spec = MiniBaker.load_spec(HOLES[_index])
	_hole = MiniBaker.bake(_spec)
	_ball = GolfBall.new(_hole, _preset)
	if _world != null:
		_world.queue_free()
	_world = Node3D.new()
	add_child(_world)
	var scenery := GolfScenery.new()
	_world.add_child(scenery)
	scenery.build(_hole, _spec, 5 + _index, _theme)
	_landmark = scenery.landmark
	var terrain := GolfTerrain.new()
	_world.add_child(terrain)
	terrain.build(_hole, _theme)
	MiniDressing.rails(_world, _hole, _theme)
	MiniDressing.decor(_world, _hole, _theme, _index)
	_ball_mesh = MiniDressing.ball(_world, _ball.p.radius, _theme)
	_shadow = _mesh(_disc(0.6), Color(0, 0, 0, 0.3), true)
	_ring = _mesh(_disc(0.16), Color(1, 1, 1, 0.35), true)
	_flag = Node3D.new()
	_world.add_child(_flag)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.025
	pole.bottom_radius = 0.025
	pole.height = 1.6
	_mesh(pole, Color(0.96, 0.96, 0.96), false, _flag).position.y = 0.8
	_flag_cloth = AmbientLife.flag_cloth(Vector3(0.6, 0.38, 0.02), _theme.flag)  # ripples
	_flag.add_child(_flag_cloth)
	_flag_cloth.position = Vector3(0.3, 1.4, 0)
	_cup_glow = _mesh(_disc(_hole.cup_r * 3.0), Color(1.0, 0.85, 0.3, 0.4), true, _flag)
	var gm2 := _cup_glow.material_override as StandardMaterial3D
	gm2.emission_enabled = true
	gm2.emission = Color(1.0, 0.8, 0.3)
	gm2.emission_energy_multiplier = 1.6
	_cup_glow.position.y = 0.006
	_mesh(_disc(_hole.cup_r * 1.6), _theme.cup_rim, true, _flag).position.y = 0.008
	_mesh(_disc(_hole.cup_r * 1.05), Color(0.03, 0.03, 0.03), true, _flag).position.y = 0.012
	_flag.position = _hole.pin
	var guide := MeshInstance3D.new()
	_guide = ImmediateMesh.new()
	guide.mesh = _guide
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.vertex_color_use_as_albedo = true
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	guide.material_override = gm
	_world.add_child(guide)
	_puff = _particles(14, 0.6, Vector2(1.0, 2.5), 0.05)
	_splash = _particles(30, 0.9, Vector2(2.5, 5.0), 0.07)
	_splash.color = Color(0.85, 0.93, 1.0)
	_confetti = _particles(70, 1.6, Vector2(3.0, 6.0), 0.045)
	_confetti.spread = 35.0
	_confetti.gravity = Vector3(0, -5.0, 0)
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	ramp.colors = PackedColorArray(
		[
			Color(1.0, 0.85, 0.2),
			Color(0.3, 0.8, 1.0),
			Color(1.0, 0.35, 0.45),
			Color(0.5, 1.0, 0.5),
			Color(1.0, 1.0, 1.0)
		]
	)
	_confetti.color_initial_ramp = ramp
	_sparks = _particles(10, 0.28, Vector2(1.5, 3.0), 0.02)
	_sparks.spread = 70.0
	_sparks.color = Color(1.0, 0.92, 0.6)
	var tr := MeshInstance3D.new()
	_trail = ImmediateMesh.new()
	tr.mesh = _trail
	tr.material_override = gm
	tr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(tr)
	_trail_pts.resize(20)
	_trail_speed.resize(20)
	_trail_n = 0
	_start_hole()


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


static func _disc(r: float) -> CylinderMesh:
	var d := CylinderMesh.new()
	d.top_radius = r
	d.bottom_radius = r
	d.height = 0.02
	d.radial_segments = 32
	return d


func _mesh(m: Mesh, col: Color, unshaded: bool, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	(parent if parent != null else _world).add_child(mi)
	return mi


func _particles(n: int, life: float, speed: Vector2, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = n
	p.lifetime = life
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = Vector3(0, -9.0, 0)
	var m := _sphere(size)
	m.radial_segments = 6
	m.rings = 3
	p.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	_world.add_child(p)
	return p


# --- UI ------------------------------------------------------------------------------------------


func _outlined(text: String, size: int, col: Color, weight: int, outline: int) -> Label:
	var l := UiKit.label(text, size, col, weight)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := UiKit.safe_top(layer)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.03, 0.12, 0.08, 0.66), 26))
	panel.position = Vector2(24, top + 10)
	panel.size = Vector2(1032, 140)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	_hud_top = UiKit.label("", 42, Color.WHITE, 900)
	_hud_top.position = Vector2(28, 10)
	panel.add_child(_hud_top)
	_hud_info = UiKit.label("", 32, Color(1, 1, 1, 0.85), 700)
	_hud_info.position = Vector2(28, 76)
	panel.add_child(_hud_info)
	_banner = _outlined("", 88, UiKit.GOLD, 900, 18)
	_banner.position = Vector2(0, 560)
	_banner.size = Vector2(1080, 260)
	layer.add_child(_banner)
	_stars = _outlined("", 96, UiKit.GOLD, 900, 16)
	_stars.position = Vector2(0, 830)
	_stars.size = Vector2(1080, 140)
	layer.add_child(_stars)
	_card = _outlined("", 76, Color.WHITE, 900, 18)
	_card.position = Vector2(0, 480)
	_card.size = Vector2(1080, 420)
	layer.add_child(_card)
	var h := get_viewport().get_visible_rect().size.y
	_hint = _outlined("", 32, Color.WHITE, 700, 10)
	_hint.position = Vector2(40, h - 230)
	_hint.size = Vector2(1000, 100)
	layer.add_child(_hint)
	_map_btn = UiKit.button("MAP", Color(0, 0, 0, 0.5), Color.WHITE, 30, 90)
	_map_btn.position = Vector2(1080 - 24 - 150, top + 166)
	_map_btn.size = Vector2(150, 90)
	_map_btn.pressed.connect(
		func() -> void:
			if mode == Mode.AIM:
				_overview = not _overview
				_map_btn.text = "BACK" if _overview else "MAP"
				AudioService.play("tap")
	)
	layer.add_child(_map_btn)
	_power_ui = Control.new()
	_power_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_power_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power_ui.draw.connect(_draw_power)
	layer.add_child(_power_ui)


## The pull: a line from where the finger went down to where it is, and a power ring.
func _draw_power() -> void:
	if mode != Mode.DRAG:
		return
	var now := _power_ui.get_local_mouse_position()
	var col := Color(1, 1, 1, 0.8).lerp(Color(1.0, 0.45, 0.3, 0.9), _power)
	_power_ui.draw_line(_drag_from, now, Color(1, 1, 1, 0.35), 6.0)
	_power_ui.draw_arc(_drag_from, 70.0, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 8.0)
	_power_ui.draw_arc(_drag_from, 70.0, -PI * 0.5, -PI * 0.5 + TAU * _power, 48, col, 12.0)
	var font := UiKit.font(900)
	var t := "%d%%" % roundi(_power * 100.0)
	var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	_power_ui.draw_string(font, _drag_from + Vector2(-tw * 0.5, 12), t, 0, -1, 34, Color.WHITE)


# --- flow ----------------------------------------------------------------------------------------


func _start_hole() -> void:
	_strokes = 0
	_hole_over = false
	_ball_at = _hole.tee + Vector3(0, _ball.p.radius, 0)
	_cur = _ball_at
	_prev = _ball_at
	_aim = _flow_dir(_ball_at)
	_banner.text = ""
	mode = Mode.INTRO
	_intro_t = 0.0
	_card.text = (
		"HOLE %d\n%s\nPar %d" % [_index + 1, str(_spec.get("name", "")).to_upper(), _hole.par]
	)
	_card.modulate.a = 1.0
	_hint.text = "Tap to skip"
	_cam_ready = false
	_refresh()


func _new_shot() -> void:
	mode = Mode.AIM
	_banner.text = ""
	_banner.scale = Vector2.ONE
	_stars.text = ""
	_card.text = ""
	_cur = _ball_at
	_prev = _ball_at
	_aim = _flow_dir(_ball_at)
	_guide.clear_surfaces()
	_refresh()


## Direction towards the cup along the course (next tile on the flow field, else straight).
func _flow_dir(from: Vector3) -> Vector3:
	return MiniBaker.flow_dir(_spec, _hole.pin, from)


func _refresh() -> void:
	_hud_top.text = (
		"HOLE %d/%d · %s · PAR %d"
		% [_index + 1, HOLES.size(), str(_spec.get("name", "")).to_upper(), _hole.par]
	)
	var to_cup := Vector2(_hole.pin.x - _ball_at.x, _hole.pin.z - _ball_at.z).length()
	_hud_info.text = ("Stroke %d · %.1f m to the cup · total %+d" % [_strokes + 1, to_cup, _total])
	if mode == Mode.AIM:
		_hint.text = "Drag back from anywhere and let go"
	elif mode == Mode.DRAG:
		_hint.text = "Slide back to the start to cancel"
	elif mode != Mode.INTRO:
		_hint.text = ""


## Ball speed for a pull fraction: eased so short pulls give fine putts.
static func _speed(p: float) -> float:
	return MAX_SPEED * pow(clampf(p, 0.0, 1.0), POWER_CURVE)


func _reduce_motion() -> bool:
	return bool(SettingsService.get_value("reduce_motion"))


func _shoot() -> void:
	_strokes += 1
	_events_seen = 0
	_ball = GolfBall.new(_hole, _preset, _ball.p)
	var v := _shot_dir * _speed(_power)
	_ball.putt(_ball_at.x, _ball_at.z, v.x, v.z)
	# Will it drop, and when? A copy runs ahead over the next frames (no hitch at release); great
	# hole-outs get slow motion.
	var probe := GolfBall.new(_hole, _preset, _ball.p)
	probe.putt(_ball_at.x, _ball_at.z, v.x, v.z)
	_forecast.start(probe)
	_hole_at = -1.0
	_slowmo = false
	var dist := Vector2(_hole.pin.x - _ball_at.x, _hole.pin.z - _ball_at.z).length()
	_slow_ok = _strokes == 1 or _strokes < _hole.par or dist > 6.0
	_clock.reset()
	_trail_n = 0
	AudioService.play("clack", 0.65 + 0.3 * _power, -6.0 + 6.0 * _power)
	AudioService.buzz(int(8 + 10 * _power))
	if not _reduce_motion():
		_kick = -_shot_dir * (0.05 + 0.1 * _power)
	mode = Mode.MOVING
	_guide.clear_surfaces()
	_refresh()


func _shot_over() -> void:
	mode = Mode.RESULT
	_result_t = 0.0
	match _ball.phase:
		GolfBall.Phase.HOLED:
			var diff := _strokes - _hole.par
			var name: String = NAMES.get(diff, "+%d" % diff)
			if _strokes == 1:
				name = "HOLE IN ONE!"
			_total += diff
			_hole_out(name, diff)
			_hole_over = true
			_save["played"] = int(_save["played"]) + 1
			SaveService.save()
		GolfBall.Phase.WATER:
			_strokes += 1
			_banner.text = "Splash!\n+1 stroke"
			_ball_at = _safe_spot(_ball.last_safe)
		GolfBall.Phase.OUT:
			_strokes += 1
			_banner.text = "Out!\n+1 stroke · try again"
			AudioService.play("foul", 1.0, -4.0)
		_:
			_ball_at = _ball.pos()
			_banner.text = ""
	if not _hole_over and _strokes >= _hole.par + 4:
		_banner.text = "Out of strokes\n+%d" % (_strokes + 1 - _hole.par)
		_total += _strokes + 1 - _hole.par
		_hole_over = true
	_banner.modulate.a = 1.0


## Hole-out: cup sound and haptic, flag wiggle, confetti (birdie or better), the score word
## popping in, then the stars one by one. Scaled to the result: par is calm, an ace is loud.
func _hole_out(word: String, diff: int) -> void:
	AudioService.play("pocket")
	AudioService.buzz(30)
	var wig := create_tween()
	wig.tween_property(_flag_cloth, "rotation:y", 0.6, 0.12)
	wig.tween_property(_flag_cloth, "rotation:y", 0.0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(
		Tween.EASE_OUT
	)
	if diff < 0 or _strokes == 1:
		get_tree().create_timer(0.1).timeout.connect(
			func() -> void:
				_confetti.amount = 140 if _strokes == 1 else 70
				_confetti.position = _hole.pin + Vector3(0, 0.1, 0)
				_confetti.restart()
		)
	if _strokes == 1 and not _reduce_motion():
		_trauma = 0.6
	_banner.text = word
	_banner.pivot_offset = _banner.size * 0.5
	_banner.scale = Vector2(0.4, 0.4)
	var pop := create_tween()
	pop.tween_interval(0.25)
	pop.tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	pop.tween_callback(func() -> void: AudioService.play("win" if diff <= 0 else "count"))
	var stars := 3 if diff < 0 else (2 if diff == 0 else (1 if diff == 1 else 0))
	_stars.text = ""
	for k in 3:
		var star := k
		get_tree().create_timer(0.8 + 0.22 * k).timeout.connect(
			func() -> void:
				var earned := star < stars
				_stars.text += "★" if earned else "☆"
				if earned:
					AudioService.play("tap", 1.0 + 0.2 * star)
		)


func _safe_spot(p: Vector3) -> Vector3:
	return Vector3(p.x, _hole.height(p.x, p.z) + _ball.p.radius, p.z)


# --- per frame -----------------------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	match mode:
		Mode.INTRO:
			_intro_t += delta
			if _intro_t >= INTRO_TIME or (Boot.bot and _intro_t > 0.8):
				_new_shot()
		Mode.AIM:
			if Boot.bot:
				_bot_t += delta
				if _bot_t > 1.0:
					_bot_t = 0.0
					_bot_shot()
		Mode.MOVING:
			_prev = _cur
			# Slow motion only changes how many fixed substeps run per tick (PresentationClock):
			# the shot itself is bit-identical.
			if not _forecast.ready:
				_forecast.advance()
				if _forecast.ready:
					_hole_at = _forecast.hole_at
					_slowmo = _hole_at > 0.0 and _slow_ok
			var slow := _slowmo and _ball.time > _hole_at - 0.6 and _ball.time < _hole_at + 0.15
			_clock.rate = SLOWMO if slow else 1.0
			for i in _clock.take():
				_ball.substep()
				if _ball.done():
					break
			_cur = _ball.pos()
			_trail_push(_cur, _ball.roll_speed())
			_effects()
			if _ball.done():
				_shot_over()
		Mode.RESULT:
			_result_t += delta
			var hold := 2.2 if _hole_over else (1.0 if _banner.text != "" else 0.3)
			_banner.modulate.a = clampf((hold + 0.2 - _result_t) * 3.0, 0.0, 1.0)
			if _result_t > hold:
				if _hole_over:
					_load_hole(_index + 1)
				else:
					_new_shot()


## Smoke runs / screenshots: aim along the flow at a power that reaches about the next bend.
func _bot_shot() -> void:
	var best := INF
	var best_dir := _aim
	var best_p := 0.5
	for ai in 36:
		var a := TAU * ai / 36.0
		var dir := Vector3(cos(a), 0.0, sin(a))
		for pi in 10:
			var p := 0.03 + pi * 0.09 * pi / 9.0  # finer at the soft end (tap-ins)
			var b := GolfBall.new(_hole, _preset, _ball.p)
			b.putt(_ball_at.x, _ball_at.z, dir.x * _speed(p), dir.z * _speed(p))
			b.run_to_rest(1.0 / 60.0)
			var score := 1e6
			if b.phase == GolfBall.Phase.HOLED:
				score = -1.0
			elif b.phase == GolfBall.Phase.REST:
				var q := b.pos()
				score = (
					Vector2(q.x - _hole.pin.x, q.z - _hole.pin.z).length() * 0.2 + _flow_metres(q)
				)
			if score < best:
				best = score
				best_dir = dir
				best_p = p
	_shot_dir = best_dir
	_power = best_p
	_shoot()


func _flow_metres(q: Vector3) -> float:
	var f := MiniBaker.flow_field(_spec)
	var tile := float(_spec.get("tile", 3.0))
	var rows: int = _spec.map.size()
	var cols := 0
	for r in _spec.map:
		cols = maxi(cols, str(r).length())
	var c := int(floorf((q.x + cols * tile * 0.5) / tile))
	var r := int(floorf((q.z + rows * tile) / tile))
	if c < 0 or r < 0 or c >= cols or r >= rows or f[r * cols + c] < 0.0:
		return 1e5
	return f[r * cols + c]


func _effects() -> void:
	while _events_seen < _ball.events.size():
		var kind := _ball.events[_events_seen]
		var v := _ball.event_speed[_events_seen]
		_events_seen += 1
		var at := _ball.pos()
		match kind:
			GolfBall.Ev.WALL:
				if v < 0.3:
					continue  # a rolling ball nudging a rail: no machine-gun clacks
				var semis := _fx_rng.randf_range(-2.0, 2.0)
				var vol := clampf(linear_to_db(clampf(v / 8.0, 0.1, 1.0)), -18.0, -3.0)
				AudioService.play(
					"clack", pow(2.0, semis / 12.0), vol + _fx_rng.randf_range(-1.5, 1.5)
				)
				if v > 2.0:
					_sparks.amount = clampi(int(v * 1.5), 6, 12)
					_sparks.position = at
					_sparks.restart()
					_squash = 0.08
			GolfBall.Ev.BOUNCE:
				_puff.color = Color(0.45, 0.75, 0.35)
				_puff.position = at
				_puff.restart()
				AudioService.play("cushion", 0.8, -8.0)
			GolfBall.Ev.WATER:
				_splash.position = at
				_splash.restart()
				AudioService.play("crash", 1.7, -8.0)
			GolfBall.Ev.LIP:
				AudioService.play("clack", 1.2, -6.0)


func _process(delta: float) -> void:
	var f := Engine.get_physics_interpolation_fraction() if mode == Mode.MOVING else 1.0
	var p := _prev.lerp(_cur, f)
	_place_camera(delta, p)
	var r := _ball.p.radius
	var s := clampf(p.distance_to(_cam.position) * 0.006 / r, 2.0, 12.0)
	_squash = maxf(0.0, _squash - delta)
	var sq := 0.12 * _squash / 0.08
	_ball_mesh.scale = Vector3(s * (1.0 + sq), s * (1.0 - sq), s * (1.0 + sq))
	_ball_mesh.position = p + Vector3(0, r * (s - 1.0), 0)
	var gone := _ball.phase == GolfBall.Phase.HOLED or _ball.phase == GolfBall.Phase.WATER
	_ball_mesh.visible = not (gone and mode == Mode.RESULT)
	var gy := _hole.height(p.x, p.z)
	var ss := s * r * 2.0 / 0.6
	_shadow.scale = Vector3(ss, 1.0, ss)
	_shadow.position = Vector3(p.x, gy + 0.015, p.z)
	_shadow.visible = _ball_mesh.visible
	_ring.visible = mode == Mode.AIM or mode == Mode.DRAG
	_ring.position = Vector3(p.x, gy + 0.012, p.z)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
	(_cup_glow.material_override as StandardMaterial3D).albedo_color.a = 0.2 + 0.25 * pulse
	_map_btn.visible = mode == Mode.AIM
	# The HUD steps back while you aim, so only the power ring and the guide remain.
	var panel := _hud_top.get_parent() as Control
	var hud_a := 0.35 if mode == Mode.DRAG else 1.0
	panel.modulate.a = lerpf(panel.modulate.a, hud_a, 1.0 - exp(-12.0 * delta))
	_draw_trail()
	if mode == Mode.DRAG:
		_power_ui.queue_redraw()


## Speed trail: a 20-point ring buffer (preallocated), pushed while the ball moves fast.
func _trail_push(p: Vector3, speed: float) -> void:
	if speed < 1.0:
		_trail_n = maxi(0, _trail_n - 1)
		return
	_trail_head = (_trail_head + 1) % _trail_pts.size()
	_trail_pts[_trail_head] = p + Vector3(0, 0.03, 0)
	_trail_speed[_trail_head] = speed
	_trail_n = mini(_trail_n + 1, _trail_pts.size())


func _draw_trail() -> void:
	_trail.clear_surfaces()
	if _trail_n < 2 or mode != Mode.MOVING:
		return
	_trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var size := _trail_pts.size()
	for k in _trail_n:
		var idx := (_trail_head - k + size) % size
		var nxt := (_trail_head - mini(k + 1, _trail_n - 1) + size) % size
		var q := _trail_pts[idx]
		var d := q - _trail_pts[nxt]
		if d.length() < 1e-4:
			d = _shot_dir
		var side := Vector3(-d.z, 0.0, d.x).normalized()
		var w := clampf(_trail_speed[idx] * 0.006, 0.01, 0.05) * (1.0 - float(k) / _trail_n)
		var a := 0.55 * (1.0 - float(k) / _trail_n)
		_trail.surface_set_color(Color(1, 1, 1, a))
		_trail.surface_add_vertex(q - side * w)
		_trail.surface_set_color(Color(1, 1, 1, a))
		_trail.surface_add_vertex(q + side * w)
	_trail.surface_end()


## Dotted guide: the ball's real path for the first GUIDE_TIME seconds (same solver).
func _draw_guide() -> void:
	_guide.clear_surfaces()
	if mode != Mode.DRAG or _power <= 0.0:
		return
	var b := GolfBall.new(_hole, _preset, _ball.p)
	var v := _shot_dir * _speed(_power)
	b.putt(_ball_at.x, _ball_at.z, v.x, v.z)
	var pts := PackedVector3Array()
	var t := 0.0
	var walls := 0
	while t < GUIDE_TIME and not b.done():
		b.substep(1.0 / 120.0)
		t += 1.0 / 120.0
		if int(t * 120.0) % 4 == 0:
			pts.append(b.pos())
		if b.events.count(GolfBall.Ev.WALL) > walls:
			walls = b.events.count(GolfBall.Ev.WALL)
			if walls >= 2:
				break
	if pts.size() < 2:
		return
	_guide.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in pts.size():
		if k % 2 == 1:
			continue
		var q := pts[k] + Vector3(0, 0.03, 0)
		var a := 1.0 - float(k) / pts.size()
		var w := 0.035
		var side := Vector3(-_shot_dir.z, 0.0, _shot_dir.x) * w
		var fwd := _shot_dir * w
		for vtx in [
			q - side - fwd,
			q + side - fwd,
			q + side + fwd,
			q - side - fwd,
			q + side + fwd,
			q - side + fwd
		]:
			_guide.surface_set_color(Color(1, 1, 1, 0.9 * a))
			_guide.surface_add_vertex(vtx)
	_guide.surface_end()


## Intro: open on the landmark over the course, then glide down to the aiming view.
## Aim: behind and above the ball, turning smoothly to the aim. Drag: frozen. Moving: same
## facing, gliding after the ball (no rotation, so bounces never swing the view). Map: top-down
## over the whole hole.
func _place_camera(delta: float, ball: Vector3) -> void:
	if mode == Mode.DRAG:
		return
	if mode == Mode.AIM or mode == Mode.INTRO:
		_cam_dir = _cam_dir.lerp(_aim, 1.0 - exp(-5.0 * delta)).normalized()
		if not _cam_ready:
			_cam_dir = _aim
	var want := ball - _cam_dir * CAM_BACK + Vector3(0, CAM_UP, 0)
	var look := ball + _cam_dir * CAM_AHEAD
	var rate := 7.0 if mode != Mode.MOVING else 4.0
	if mode == Mode.INTRO:
		# Establishing shot: high behind the tee, the whole course below and the landmark beyond;
		# hold it a moment, then glide down to the aiming view.
		var t := GestureTimeline.decel(
			clampf((_intro_t - INTRO_HOLD) / (INTRO_TIME - INTRO_HOLD), 0.0, 1.0)
		)
		var back := Vector3(_hole.tee.x - _landmark.x, 0.0, _hole.tee.z - _landmark.z).normalized()
		var high := _hole.tee + back * 9.0 + Vector3(0, 13.0, 0)
		want = high.lerp(want, t)
		look = _landmark.lerp(look, t)
		rate = 60.0
	elif _overview and mode == Mode.AIM:
		var c := _hole_centre()
		want = c + Vector3(0, _hole_span() * 1.15, _hole_span() * 0.25)
		look = c
	var k := 1.0 if not _cam_ready else 1.0 - exp(-rate * delta)
	_cam_ready = true
	_cam.position = _cam.position.lerp(want, k)
	_cam.look_at(look)
	# Release kick (springs back over ~200 ms) and hole-in-one shake (trauma^2, smooth wobble).
	_kick = _kick.lerp(Vector3.ZERO, 1.0 - exp(-15.0 * delta))
	_trauma = maxf(0.0, _trauma - delta * 0.9)
	var tm := Time.get_ticks_msec() * 0.001
	var shake := _trauma * _trauma * 0.12
	var wob := Vector3(sin(tm * 37.0), sin(tm * 29.0 + 1.3), sin(tm * 41.0 + 2.1)) * shake
	_cam.position += _kick + wob


func _hole_centre() -> Vector3:
	var w := _hole.walls
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for o in range(0, w.size(), 2):
		lo = Vector2(minf(lo.x, w[o]), minf(lo.y, w[o + 1]))
		hi = Vector2(maxf(hi.x, w[o]), maxf(hi.y, w[o + 1]))
	var c := (lo + hi) * 0.5
	return Vector3(c.x, 0.0, c.y)


func _hole_span() -> float:
	var w := _hole.walls
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for o in range(0, w.size(), 2):
		lo = Vector2(minf(lo.x, w[o]), minf(lo.y, w[o + 1]))
		hi = Vector2(maxf(hi.x, w[o]), maxf(hi.y, w[o + 1]))
	return maxf(hi.x - lo.x, hi.y - lo.y)


# --- input ---------------------------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			if mode == Mode.INTRO:
				_new_shot()
			elif mode == Mode.AIM:
				if _overview:
					_overview = false
					_map_btn.text = "MAP"
					return
				mode = Mode.DRAG
				_drag_from = mb.position
				_power = 0.0
				# Freeze the screen-to-world mapping for this drag.
				var b := _cam.global_transform.basis
				_cam_right = Vector3(b.x.x, 0.0, b.x.z).normalized()
				_cam_fwd = Vector3(-b.z.x, 0.0, -b.z.z).normalized()
				_refresh()
		elif mode == Mode.DRAG:
			_power_ui.queue_redraw()
			if _power * PULL_FULL < DEAD:
				mode = Mode.AIM  # cancelled
				_guide.clear_surfaces()
				_refresh()
			else:
				_shoot()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and mode == Mode.DRAG:
		var d := mm.position - _drag_from
		_power = clampf(d.length() / PULL_FULL, 0.0, 1.0)
		# A light tick each 10% of power (throttled), so the pull can be felt.
		var band := int(_power * 10.0)
		var now := Time.get_ticks_msec()
		if band != _last_tick and now - _last_tick_ms > 70:
			_last_tick = band
			_last_tick_ms = now
			AudioService.buzz(5)
		if d.length() > 4.0:
			# Slingshot: the ball goes opposite to the pull (screen down = towards the camera).
			var pull := _cam_right * d.x - _cam_fwd * d.y
			_shot_dir = (-pull).normalized()
			_aim = _shot_dir
		_draw_guide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneRouter.back_to_hub()
