extends Node3D
## Fairway Flick - one playable hole (step 6/7 of docs/plans/2026-11-14-fairway-flick-courses.md),
## still behind enabled = false. The hole is baked from games/golf/data/holes/meadow_03.json.
## Controls (chosen after phone feedback - pull-down swinging was uncomfortable):
##   aim  - drag on the course to place the landing marker; the club is picked for the distance
##          (tap a club to change it). Power is automatic: solved on the real solver with the wind,
##          lie and slopes so a perfect shot lands on the marker; a small dot shows where.
##   swing - a needle sweeps the accuracy bar; tap the lower screen when it is in the centre.
##           Centre = PERFECT (lands on the marker); off-centre hooks / slices and comes up short.
##   putt - the same: marker at your aim point, tap on the needle.
## The camera flies over the hole first, chases the ball up, then watches it land from the side.
## Nodes move in _process from interpolated solver states, so root interpolation is OFF.

enum Mode { INTRO, AIM, MOVING, RESULT }

const SAVE_SCHEMA := 1
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"best_score": 0,
	"difficulty": "medium",
	"tutorial_seen": false,
}
const HOLE_SPEC := "res://games/golf/data/holes/meadow_03.json"
const HOLE_NUMBER := 3
const NEEDLE_PERIOD := 1.6  # seconds for a full left-right-left sweep
const PERFECT := 0.1  # needle offset that still counts as centre
const MAX_TILT := 10.0  # curve (deg of spin-axis tilt) at the bar's end
const MAX_PUSH := 1.5  # start-direction error (deg) at the bar's end
const SHORT := 0.08  # power lost at the bar's end
const PUTT_ERR := 0.12  # putt speed error at the bar's end
const INTRO_TIME := 4.0
const NAMES := {-3: "Albatross", -2: "Eagle", -1: "Birdie", 0: "Par", 1: "Bogey", 2: "Double bogey"}
const LIES := ["", "Tee", "Fairway", "Rough", "Fringe", "Green", "Bunker", "", "Path"]
const PUFF_COLS := {
	HoleData.Surface.SAND: Color(0.93, 0.85, 0.62),
	HoleData.Surface.ROUGH: Color(0.3, 0.5, 0.22),
}

var mode: int = Mode.INTRO

var _save: Dictionary
var _spec: Dictionary
var _hole: HoleData
var _preset := CoursePreset.new()
var _clubs: GolfClubs
var _ball: GolfBall
var _rng := Rng.make(0x60f1)
var _club := 0
var _club_manual := false
var _target := Vector3.ZERO
var _ghost := Vector3.ZERO  # where a perfect shot lands (after wind)
var _power := 1.0  # solved power (putter: ground speed)
var _strokes := 0
var _pin_index := 0
var _ball_at := Vector3.ZERO
var _wind := Vector3.ZERO
var _needle := 0.0
var _needle_t := 0.0
var _dragging := false
var _result_t := 0.0
var _intro_t := 0.0
var _hole_over := false
var _prev := Vector3.ZERO
var _cur := Vector3.ZERO
var _land := Vector3.ZERO  # predicted first landing point of the current shot
var _shot_dir := Vector3.FORWARD
var _events_seen := 0
var _bot_wait := 0.0

var _ball_mesh: MeshInstance3D
var _shadow: MeshInstance3D
var _marker: MeshInstance3D
var _ghost_mesh: MeshInstance3D
var _flag: Node3D
var _aim_line: ImmediateMesh
var _trail: ImmediateMesh
var _trail_pts := PackedVector3Array()
var _puff: CPUParticles3D
var _splash: CPUParticles3D
var _cam: Camera3D
var _cam_ready := false
var _hud_top: Label
var _hud_info: Label
var _banner: Label
var _perfect: Label
var _hint: Label
var _card: Label
var _bar: Control
var _club_buttons: Array[Button] = []


## Schema history: 1 = first version. Bump SAVE_SCHEMA and handle `from` here on any change.
static func migrate_save(old: Dictionary, _from: int, _to: int) -> Dictionary:
	return old


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see the project rules
	_save = SaveService.game("golf", SAVE_SCHEMA, SAVE_DEFAULTS, migrate_save)
	_preset.stimp = 9.0
	_preset.wind_max = 3.0
	_spec = HoleBaker.load_spec(HOLE_SPEC)
	_hole = HoleBaker.bake(_spec)
	_clubs = GolfClubs.new()
	_ball = GolfBall.new(_hole, _preset)
	_build_world()
	_build_ui()
	_start_hole()


# --- world ---------------------------------------------------------------------------------------


func _build_world() -> void:
	var scenery := GolfScenery.new()
	add_child(scenery)
	scenery.build(_hole, _spec, 3)
	var terrain := GolfTerrain.new()
	add_child(terrain)
	terrain.build(_hole)
	_ball_mesh = _mesh(_sphere(_ball.p.radius), Color(0.99, 0.99, 0.99), true)
	_shadow = _mesh(_disc(0.6), Color(0, 0, 0, 0.35), true)
	_marker = _mesh(_disc(1.6), Color(1.0, 0.85, 0.25, 0.75), true)
	_ghost_mesh = _mesh(_sphere(0.35), Color(1, 1, 1, 0.55), true)
	_flag = Node3D.new()
	add_child(_flag)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.035
	pole.bottom_radius = 0.035
	pole.height = 2.4
	_mesh(pole, Color(0.96, 0.96, 0.96), false, _flag).position.y = 1.2
	var cloth := BoxMesh.new()
	cloth.size = Vector3(0.9, 0.55, 0.02)
	_mesh(cloth, Color(0.95, 0.25, 0.2), true, _flag).position = Vector3(0.45, 2.1, 0)
	_mesh(_disc(GolfBall.CUP_R * 2.0), Color(0.04, 0.04, 0.04), true, _flag)
	_aim_line = _immediate()
	_trail = _immediate()
	_puff = _particles(16, 0.7, Vector2(1.5, 3.5), 0.12)
	_splash = _particles(36, 1.0, Vector2(3.5, 7.0), 0.16)
	_splash.color = Color(0.85, 0.93, 1.0)
	_cam = Camera3D.new()
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 60.0
	_cam.far = 2000.0
	add_child(_cam)
	_cam.make_current()


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
	(parent if parent != null else self).add_child(mi)
	return mi


func _immediate() -> ImmediateMesh:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mi.material_override = mat
	add_child(mi)
	return im


## One-shot burst (grass / sand puffs, water splash), re-fired with restart().
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
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var m := _sphere(size)
	m.radial_segments = 6
	m.rings = 3
	p.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	add_child(p)
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
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.02, 0.1, 0.06, 0.62), 26))
	panel.position = Vector2(24, top + 10)
	panel.size = Vector2(1032, 150)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	_hud_top = UiKit.label("", 40, Color.WHITE, 900)
	_hud_top.position = Vector2(26, 10)
	panel.add_child(_hud_top)
	_hud_info = UiKit.label("", 30, Color(1, 1, 1, 0.85), 700)
	_hud_info.position = Vector2(26, 80)
	panel.add_child(_hud_info)
	_banner = _outlined("", 84, UiKit.GOLD, 900, 18)
	_banner.position = Vector2(0, 560)
	_banner.size = Vector2(1080, 260)
	layer.add_child(_banner)
	_perfect = _outlined("", 64, Color(0.6, 1.0, 0.7), 900, 16)
	_perfect.position = Vector2(0, 860)
	_perfect.size = Vector2(1080, 100)
	layer.add_child(_perfect)
	_card = _outlined("", 72, Color.WHITE, 900, 18)
	_card.position = Vector2(0, 480)
	_card.size = Vector2(1080, 420)
	layer.add_child(_card)
	var h := get_viewport().get_visible_rect().size.y
	_hint = _outlined("", 30, Color.WHITE, 700, 10)
	_hint.position = Vector2(40, h - 400)
	_hint.size = Vector2(1000, 80)
	layer.add_child(_hint)
	_bar = Control.new()
	_bar.position = Vector2(140, h - 300)
	_bar.size = Vector2(800, 110)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	layer.add_child(_bar)
	for i in GolfClubs.count() + 1:
		var c := i
		var b := UiKit.button(GolfClubs.name_of(c), Color(0, 0, 0, 0.5), Color.WHITE, 30, 96)
		b.position = Vector2(24 + i * 172, h - 150)
		b.size = Vector2(160, 96)
		b.pressed.connect(func() -> void: _choose_club(c))
		layer.add_child(b)
		_club_buttons.append(b)


func _choose_club(c: int) -> void:
	if mode != Mode.AIM:
		return
	_club = c
	_club_manual = true
	AudioService.play("tap")
	_solve()


## Accuracy bar: green centre = PERFECT, the needle sweeps; tap the lower screen to swing.
func _draw_bar() -> void:
	var w := _bar.size.x
	var h := 64.0
	var y := 30.0
	_bar.draw_rect(Rect2(0, y, w, h), Color(0, 0, 0, 0.55))
	for k in 5:
		var f := float(k) / 4.0
		_bar.draw_rect(Rect2(w * f - 1.5, y, 3, h), Color(1, 1, 1, 0.18))
	var good := w * 0.5 * 0.35
	_bar.draw_rect(Rect2(w * 0.5 - good, y, good * 2.0, h), Color(0.95, 0.8, 0.25, 0.35))
	var perfect := w * 0.5 * PERFECT
	_bar.draw_rect(Rect2(w * 0.5 - perfect, y, perfect * 2.0, h), Color(0.4, 0.95, 0.55, 0.8))
	if mode == Mode.AIM:
		var x := w * 0.5 * (1.0 + _needle)
		_bar.draw_rect(Rect2(x - 5, y - 16, 10, h + 32), Color.WHITE)
	var font := UiKit.font(900)
	var t := "TAP TO SWING" if mode == Mode.AIM else ""
	var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	_bar.draw_string(font, Vector2((w - tw) * 0.5, y + h + 34), t, 0, -1, 30, Color(1, 1, 1, 0.9))


# --- flow ----------------------------------------------------------------------------------------


func _start_hole() -> void:
	_strokes = 0
	_hole_over = false
	var pins: Array = _spec.get("pins", [[_hole.pin.x, _hole.pin.z]])
	var p: Array = pins[_pin_index % pins.size()]
	_hole.pin = Vector3(p[0], 0.0, p[1])
	_hole.pin.y = _hole.height(_hole.pin.x, _hole.pin.z)
	_flag.position = _hole.pin
	var w := _rng.randf_range(_preset.wind_min, _preset.wind_max)
	var dir := _rng.randf_range(0.0, TAU)
	_wind = Vector3(cos(dir), 0.0, sin(dir)) * w
	_ball = GolfBall.new(_hole, _preset)
	_ball_at = _hole.tee + Vector3(0, _ball.p.radius, 0)
	_cur = _ball_at
	_prev = _ball_at
	_banner.text = ""
	mode = Mode.INTRO
	_intro_t = 0.0
	_card.text = (
		"HOLE %d\n%s\nPar %d · %d m"
		% [HOLE_NUMBER, str(_spec.get("name", "")).to_upper(), _hole.par, roundi(_hole_length())]
	)
	_card.modulate.a = 1.0
	_hint.text = "Tap to skip"
	_bar.queue_redraw()


func _hole_length() -> float:
	var pts: Array = _spec.path
	var total := 0.0
	for k in range(pts.size() - 1):
		total += Vector2(pts[k][0], pts[k][1]).distance_to(Vector2(pts[k + 1][0], pts[k + 1][1]))
	return total


func _end_intro() -> void:
	_card.text = ""
	_new_shot()


func _new_shot() -> void:
	mode = Mode.AIM
	_banner.text = ""
	_perfect.text = ""
	_club_manual = false
	_needle_t = 0.0
	_cur = _ball_at
	_prev = _ball_at
	_trail_pts.clear()
	_trail.clear_surfaces()
	var lie := _hole.surface_at(_ball_at.x, _ball_at.z)
	var to_pin := _flat(_hole.pin - _ball_at).length()
	if lie == HoleData.Surface.GREEN or (lie == HoleData.Surface.FRINGE and to_pin < 25.0):
		_club = GolfClubs.PUTTER
		_set_target(_hole.pin)
	else:
		if _club == GolfClubs.PUTTER:
			_club = 0
		# Default aim: the pin if reachable, else down the centre line short enough that the
		# roll-out stays on the fairway (a full carry ran through the dogleg into the rough).
		var reach := _clubs.carry_at(0, 1.0) * 0.85
		_set_target(_hole.pin if to_pin <= reach else _along_path(reach))


## The point on the hole's centre line `ahead` metres (straight-line) from the ball.
func _along_path(ahead: float) -> Vector3:
	var pts: Array = _spec.path
	var best := _flat(_hole.pin)
	for k in range(pts.size() - 1):
		var a := Vector3(pts[k][0], 0.0, pts[k][1])
		var b := Vector3(pts[k + 1][0], 0.0, pts[k + 1][1])
		for t in 41:
			var q := a.lerp(b, t / 40.0)
			if (
				_flat(q - _ball_at).length() <= ahead
				and _flat(_hole.pin - q).length() < _flat(_hole.pin - best).length() + 1e-6
			):
				best = q
	if _flat(best - _ball_at).length() > ahead:
		best = _ball_at + _flat(_hole.pin - _ball_at).normalized() * ahead
	return best


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _set_target(p: Vector3) -> void:
	_target = Vector3(p.x, _hole.height(p.x, p.z), p.z)
	if not _club_manual and _club != GolfClubs.PUTTER:
		var lie := GolfClubs.lie(_hole.surface_at(_ball_at.x, _ball_at.z))
		_club = _clubs.pick(_flat(_target - _ball_at).length() / lie.x)
	_solve()


func _heading_to(p: Vector3) -> float:
	var to := _flat(p - _ball_at)
	return rad_to_deg(atan2(to.x, -to.z))


## Automatic power: binary search on the real solver (wind, lie, slopes) so a perfect shot lands on
## the marker; a putt stops ~0.3 m past it. Also sets the landing preview dot.
func _solve() -> void:
	var dist := _flat(_target - _ball_at).length()
	var heading := _heading_to(_target)
	var lo := 0.05
	var hi := GolfClubs.MAX_POWER
	if _club == GolfClubs.PUTTER:
		lo = 0.1
		hi = GolfClubs.MAX_PUTT
	for k in 10:
		var mid := (lo + hi) * 0.5
		var r := _simulate(mid, heading, 0.0)
		if _along(r, heading) < (dist + (0.3 if _club == GolfClubs.PUTTER else 0.0)):
			lo = mid
		else:
			hi = mid
	_power = (lo + hi) * 0.5
	_ghost = _simulate(_power, heading, 0.0)
	_refresh()


## Where a shot comes down (full swing: first landing; putt: where it stops), on a scratch copy.
func _simulate(power: float, heading: float, tilt: float) -> Vector3:
	var b := GolfBall.new(_hole, _preset, _ball.p)
	if _club == GolfClubs.PUTTER:
		var pin := _hole.pin
		_hole.pin = Vector3(1e6, 0.0, 1e6)  # judge pace without the cup catching the ball
		var h := deg_to_rad(heading)
		b.putt(_ball_at.x, _ball_at.z, sin(h) * power, -cos(h) * power)
		b.run_to_rest(1.0 / 120.0)
		_hole.pin = pin
		return b.pos()
	var l := GolfClubs.launch(_club, power)
	var lie := GolfClubs.lie(_hole.surface_at(_ball_at.x, _ball_at.z))
	b.flight.launch(_ball_at, l[0] * lie.x, l[1], l[2] * lie.y, tilt, heading)
	b.flight.set_wind(_wind)
	var o := b.flight.fly_over(_hole, 1.0 / 60.0)
	return o.pos


func _along(p: Vector3, heading: float) -> float:
	var h := deg_to_rad(heading)
	return (p.x - _ball_at.x) * sin(h) - (p.z - _ball_at.z) * cos(h)


func _refresh() -> void:
	_hud_top.text = (
		"HOLE %d · %s · PAR %d"
		% [HOLE_NUMBER, str(_spec.get("name", "")).to_upper(), int(_spec.get("par", 4))]
	)
	var to_pin := _flat(_hole.pin - _ball_at).length()
	_hud_info.text = (
		"Shot %d · %s · %d m to pin · wind %.1f m/s %s"
		% [_strokes + 1, GolfClubs.name_of(_club), roundi(to_pin), _wind.length(), _wind_arrow()]
	)
	for i in _club_buttons.size():
		_club_buttons[i].modulate = UiKit.GOLD if i == _club else Color.WHITE
	if mode == Mode.AIM:
		_hint.text = "Drag on the course to aim · the dot shows where it lands"
	elif mode != Mode.INTRO:
		_hint.text = ""
	_bar.queue_redraw()
	_draw_aim()


func _wind_arrow() -> String:
	if _wind.length() < 0.3:
		return ""
	var fwd := _flat(_target - _ball_at).normalized()
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var along := _wind.dot(fwd)
	var across := _wind.dot(right)
	var s := "helping" if along > 0.5 else ("against" if along < -0.5 else "")
	s += " →" if across > 0.5 else (" ←" if across < -0.5 else "")
	return s


func _swing() -> void:
	var e := _needle
	if absf(e) < PERFECT:
		e = 0.0
		_perfect.text = "PERFECT!"
	elif absf(e) < 0.35:
		_perfect.text = "Good"
	else:
		_perfect.text = "Hook!" if e < 0.0 else "Slice!"
	_perfect.modulate.a = 1.0
	var heading := _heading_to(_target) + e * MAX_PUSH
	_strokes += 1
	_events_seen = 0
	_ball = GolfBall.new(_hole, _preset, _ball.p)
	_shot_dir = _flat(_target - _ball_at).normalized()
	if _club == GolfClubs.PUTTER:
		var sp := _power * (1.0 + PUTT_ERR * e)
		var h := deg_to_rad(heading)
		_ball.putt(_ball_at.x, _ball_at.z, sin(h) * sp, -cos(h) * sp)
		AudioService.play("clack", 0.7, -8.0)
		_land = _ball_at
	else:
		var p := _power * (1.0 - SHORT * absf(e))
		var l := GolfClubs.launch(_club, p)
		var lie := GolfClubs.lie(_hole.surface_at(_ball_at.x, _ball_at.z))
		_ball.strike(_ball_at, l[0] * lie.x, l[1], l[2] * lie.y, e * MAX_TILT, heading)
		_ball.flight.set_wind(_wind)
		# Where it will first come down (same solver, same step: exact) - for the landing camera.
		var f := GolfFlight.new(_ball.p)
		f.launch(_ball_at, l[0] * lie.x, l[1], l[2] * lie.y, e * MAX_TILT, heading)
		f.set_wind(_wind)
		_land = f.fly_over(_hole).pos
		AudioService.play("cue", 0.55 + 0.25 * minf(p, 1.0), -2.0)
		AudioService.buzz(int(10 + 12 * minf(p, 1.0)))
	mode = Mode.MOVING
	_aim_line.clear_surfaces()
	_refresh()


func _shot_over() -> void:
	mode = Mode.RESULT
	_result_t = 0.0
	var par := int(_spec.get("par", 4))
	match _ball.phase:
		GolfBall.Phase.HOLED:
			var diff := _strokes - par
			var name: String = NAMES.get(diff, "+%d" % diff)
			if _strokes == 1:
				name = "HOLE IN ONE!"
			_banner.text = "%s\n%d strokes" % [name, _strokes]
			AudioService.play("pocket")
			AudioService.play("win" if diff <= 0 else "count")
			_hole_over = true
			_save["played"] = int(_save["played"]) + 1
			SaveService.save()
		GolfBall.Phase.WATER:
			_strokes += 1
			_banner.text = "Splash!\n+1 stroke · drop"
			_ball_at = _drop_point(_ball.last_safe)
		GolfBall.Phase.OUT:
			_strokes += 1  # stroke and distance: replay from the same spot
			_banner.text = "Out of bounds\n+1 stroke · replay"
			AudioService.play("foul", 1.0, -4.0)
		_:
			_ball_at = _ball.pos()
			_banner.text = LIES[_hole.surface_at(_ball_at.x, _ball_at.z)]
	if not _hole_over and _strokes >= par + 3:
		_banner.text = "Picked up · %d" % (_strokes + 1)
		_hole_over = true
	_banner.modulate.a = 1.0


func _drop_point(p: Vector3) -> Vector3:
	var at := Vector3(p.x, 0.0, p.z)
	var back := _flat(_hole.tee - at).normalized()
	for k in 60:
		var s := _hole.surface_at(at.x, at.z)
		if s != HoleData.Surface.WATER and s != HoleData.Surface.OUT:
			break
		at += back
	return Vector3(at.x, _hole.height(at.x, at.z) + _ball.p.radius, at.z)


# --- per frame -----------------------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	match mode:
		Mode.INTRO:
			_intro_t += delta
			if _intro_t >= INTRO_TIME or (Boot.bot and _intro_t > 1.0):
				_end_intro()
		Mode.AIM:
			_needle_t += delta
			# Triangle wave in [-1, 1], starting at the left end.
			var x := fmod(_needle_t / NEEDLE_PERIOD, 1.0)
			_needle = 1.0 - 4.0 * absf(x - 0.5)
			_needle = -_needle
			_bar.queue_redraw()
			if Boot.bot:
				_bot_wait += delta
				if _bot_wait > 1.0 and absf(_needle) < 0.04:
					_bot_wait = 0.0
					_swing()
		Mode.MOVING:
			_prev = _cur
			for i in 4:
				_ball.substep()
				if _ball.done():
					break
			_cur = _ball.pos()
			if _ball.phase == GolfBall.Phase.FLY and _ball.bounces == 0:
				_trail_pts.append(_cur)
			_effects()
			if _ball.done():
				_shot_over()
		Mode.RESULT:
			_result_t += delta
			_banner.modulate.a = clampf(2.6 - _result_t, 0.0, 1.0)
			if _result_t > 2.4:
				if _hole_over:
					_pin_index += 1
					_start_hole()
				else:
					_new_shot()
	_perfect.modulate.a = maxf(0.0, _perfect.modulate.a - delta * 0.8)


## Bounce puffs, splash and sounds from the ball's event log.
func _effects() -> void:
	while _events_seen < _ball.events.size():
		var kind := _ball.events[_events_seen]
		var v := _ball.event_speed[_events_seen]
		_events_seen += 1
		var at := _ball.pos()
		match kind:
			GolfBall.Ev.BOUNCE:
				var s := _hole.surface_at(at.x, at.z)
				_puff.color = PUFF_COLS.get(s, Color(0.42, 0.66, 0.32))
				_puff.position = at
				_puff.restart()
				AudioService.play(
					"cushion", 0.7, clampf(linear_to_db(clampf(v / 25.0, 0.1, 1.0)), -20.0, -2.0)
				)
			GolfBall.Ev.WATER:
				_splash.position = Vector3(at.x, _hole.height(at.x, at.z) + 0.3, at.z)
				_splash.restart()
				AudioService.play("crash", 1.7, -8.0)
			GolfBall.Ev.LIP:
				AudioService.play("clack", 1.1, -6.0)


func _process(delta: float) -> void:
	var f := Engine.get_physics_interpolation_fraction() if mode == Mode.MOVING else 1.0
	var p := _prev.lerp(_cur, f)
	_place_camera(delta, p)
	# The ball keeps a readable size on screen at any distance (about 6 px radius at least).
	var r := _ball.p.radius
	var s := clampf(p.distance_to(_cam.position) * 0.0075 / r, 2.5, 40.0)
	_ball_mesh.scale = Vector3(s, s, s)
	_ball_mesh.position = p + Vector3(0, r * (s - 1.0), 0)
	var gone := _ball.phase == GolfBall.Phase.HOLED or _ball.phase == GolfBall.Phase.WATER
	_ball_mesh.visible = not (gone and mode == Mode.RESULT) and mode != Mode.INTRO
	# Shadow on the ground under the ball: shows its height in the air.
	var gy := _hole.height(p.x, p.z)
	var air := p.y - gy
	var ss := s * r * 2.2 / 0.6
	_shadow.scale = Vector3(ss, 1.0, ss)
	_shadow.position = Vector3(p.x, gy + 0.03, p.z)
	_shadow.visible = _ball_mesh.visible
	(_shadow.material_override as StandardMaterial3D).albedo_color.a = clampf(
		0.45 - air * 0.012, 0.08, 0.45
	)
	if mode == Mode.MOVING and _trail_pts.size() > 1:
		_draw_trail(p)
	var aiming := mode == Mode.AIM
	_marker.visible = aiming
	_marker.position = _target + Vector3(0, 0.05, 0)
	var ms := clampf(_flat(_target - _ball_at).length() * 0.015, 0.12, 1.6) / 1.6
	_marker.scale = Vector3(ms, 1.0, ms)
	_ghost_mesh.visible = aiming and _club != GolfClubs.PUTTER
	_ghost_mesh.position = _ghost + Vector3(0, 0.3, 0)
	_ghost_mesh.scale = Vector3.ONE * clampf(_ghost.distance_to(_cam.position) * 0.004, 0.4, 3.0)


func _draw_trail(p: Vector3) -> void:
	_trail.clear_surfaces()
	var n := _trail_pts.size()
	var flying := _ball.phase == GolfBall.Phase.FLY and _ball.bounces == 0
	var last := n + (1 if flying else 0)
	var first := maxi(0, n - 150)
	while first < last - 1 and _pt(first, p).distance_squared_to(_cam.position) < 64.0:
		first += 1
	if last - first < 2:
		return
	_trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for k in range(first, last):
		var q := _pt(k, p)
		var nxt := _pt(mini(k + 1, last - 1), p)
		var cd := q.distance_to(_cam.position)
		var side := (
			(nxt - q).cross(_cam.position - q).normalized() * 0.09 * clampf(cd / 25.0, 0.15, 1.6)
		)
		var a := 0.1 + 0.7 * float(k - first) / (last - first)
		_trail.surface_set_color(Color(1, 1, 1, a))
		_trail.surface_add_vertex(q - side)
		_trail.surface_set_color(Color(1, 1, 1, a))
		_trail.surface_add_vertex(q + side)
	_trail.surface_end()


func _pt(k: int, live: Vector3) -> Vector3:
	return _trail_pts[k] if k < _trail_pts.size() else live


## Dashed line on the ground from the ball to the marker.
func _draw_aim() -> void:
	_aim_line.clear_surfaces()
	if mode != Mode.AIM:
		return
	var a := _ball_at
	var b := _target
	var d := _flat(b - a).length()
	if d < 1.0:
		return
	var n := maxi(2, int(d / 3.0))
	var side := Vector3(-(b - a).z, 0.0, (b - a).x).normalized() * (0.06 if d < 30.0 else 0.25)
	_aim_line.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(0, n, 2):
		var p0 := a.lerp(b, float(k) / n)
		var p1 := a.lerp(b, float(k + 1) / n)
		p0.y = _hole.height(p0.x, p0.z) + 0.05
		p1.y = _hole.height(p1.x, p1.z) + 0.05
		for v in [p0 - side, p1 - side, p1 + side, p0 - side, p1 + side, p0 + side]:
			_aim_line.surface_set_color(Color(1, 1, 1, 0.75))
			_aim_line.surface_add_vertex(v)
	_aim_line.surface_end()


## Intro: fly from above the green back to the tee. Aim: behind the ball down the line. Flight:
## chase on the way up, then hold a side view of the landing spot so the bounces read; putts low.
func _place_camera(delta: float, ball: Vector3) -> void:
	var fwd := _shot_dir if mode == Mode.MOVING else _flat(_target - _ball_at)
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3(0, 0, -1)
	var side := Vector3(-fwd.z, 0.0, fwd.x)
	var want: Vector3
	var look: Vector3
	var rate := 8.0
	if mode == Mode.INTRO:
		var t := GestureTimeline.decel(clampf(_intro_t / INTRO_TIME, 0.0, 1.0))
		var g := _hole.pin
		var tee := _hole.tee
		var dir := _flat(g - tee).normalized()
		var from := g + Vector3(0, 55, 0) + dir * 40.0
		var to := tee - dir * 9.0 + Vector3(0, 4.0, 0)
		want = from.lerp(to, t)
		look = g.lerp(tee + dir * 120.0, t)
		rate = 60.0
	elif mode == Mode.MOVING and _club != GolfClubs.PUTTER:
		var falling := _ball.phase != GolfBall.Phase.FLY or _ball.flight.vel().y < 0.0
		if not falling:
			want = ball - fwd * 12.0 + Vector3(0, 4.0 + maxf(0.0, ball.y - _ball_at.y) * 0.3, 0)
			look = ball + fwd * 25.0
			rate = 5.0
		else:
			# Side-on view of the landing spot; it follows the ball once it is on the ground.
			var focus := _land if _ball.bounces == 0 else ball
			want = focus - fwd * 15.0 + side * 9.0 + Vector3(0, 7.0, 0)
			look = focus + fwd * 4.0
			rate = 2.2
	elif _club == GolfClubs.PUTTER:
		var d := _flat(_target - _ball_at).length()
		var focus := ball if mode == Mode.MOVING else _ball_at
		want = focus - fwd * (3.0 + d * 0.3) + Vector3(0, 1.6 + d * 0.14, 0)
		look = _ball_at.lerp(_target, 0.65)
		rate = 4.0
	else:
		var d := _flat(_target - _ball_at).length()
		want = _ball_at - fwd * 7.0 + Vector3(0, 3.2, 0)
		look = _ball_at + fwd * minf(d * 0.55, 90.0)
		look.y = _hole.height(look.x, look.z)
	var k := 1.0 if not _cam_ready else 1.0 - exp(-rate * delta)
	_cam_ready = true
	_cam.position = _cam.position.lerp(want, k)
	_cam.look_at(look)


# --- input ---------------------------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_press(mb.position)
		elif _dragging:
			_dragging = false
			_set_target(_target)  # pick the club and solve the power where the finger let go
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _dragging and mode == Mode.AIM:
		_aim_at(mm.position, false)


func _press(at: Vector2) -> void:
	if mode == Mode.INTRO:
		_end_intro()
		return
	if mode != Mode.AIM:
		return
	var h := get_viewport().get_visible_rect().size.y
	if at.y > h - 440.0:
		_swing()  # the lower screen is the swing button
	else:
		_dragging = true
		_aim_at(at, false)


## Moves the landing marker to the course point under the finger. While dragging only the marker
## moves; the power is solved when the finger lifts.
func _aim_at(screen: Vector2, solve: bool) -> void:
	var o := _cam.project_ray_origin(screen)
	var dir := _cam.project_ray_normal(screen)
	var t := 2.0
	while t < 700.0:
		var p := o + dir * t
		if p.y <= _hole.height(p.x, p.z):
			var lo := t - 2.0
			var hi := t
			for k in 12:
				var mid := (lo + hi) * 0.5
				var q := o + dir * mid
				if q.y > _hole.height(q.x, q.z):
					lo = mid
				else:
					hi = mid
			var hit := o + dir * hi
			var reach := _clubs.carry_at(0, GolfClubs.MAX_POWER)
			if _club == GolfClubs.PUTTER or _flat(hit - _ball_at).length() < reach:
				_target = Vector3(hit.x, _hole.height(hit.x, hit.z), hit.z)
				if solve:
					_set_target(hit)
				else:
					_draw_aim()
			return
		t += 2.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneRouter.back_to_hub()
