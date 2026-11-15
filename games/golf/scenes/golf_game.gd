extends Node3D
## Fairway Flick - one playable hole (step 6 of docs/plans/2026-11-14-fairway-flick-courses.md),
## still behind enabled = false. The hole is baked from games/golf/data/holes/meadow_03.json.
## Controls (portrait, one thumb): tap or drag on the course to move the landing marker (the club is
## picked for that distance; tap a club to change it); then press below the ball, pull DOWN and let
## go - pull length = power (the gold tick shows the power for the marker), sideways drift = hook /
## slice, and past 100% (overpower) the drift counts double. On the green the putter rolls the ball.
## The ball is a GolfBall (4 x 1/240 s substeps per tick); nodes move in _process from interpolated
## states, so root physics interpolation is OFF (CLAUDE.md).

enum Mode { AIM, PULL, MOVING, RESULT }

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
const BALL_DRAW := 4.0
const PULL_PX := 560.0  # canvas px of pull for 100% power
const SIDE_PX := 260.0  # sideways drift for a full hook / slice
const MAX_TILT := 12.0  # curve (spin-axis tilt, deg) at full drift
const MAX_PUSH := 2.5  # start-direction error (deg) at full drift
const PAD_TOP := 1240.0  # swing pad: presses below this canvas y start a pull
const NAMES := {-3: "Albatross", -2: "Eagle", -1: "Birdie", 0: "Par", 1: "Bogey", 2: "Double bogey"}
const LIES := ["", "Tee", "Fairway", "Rough", "Fringe", "Green", "Bunker", "", "Path"]

var mode: int = Mode.AIM

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
var _strokes := 0
var _pin_index := 0
var _ball_at := Vector3.ZERO  # where the ball lies between shots
var _wind := Vector3.ZERO
var _pull_from := Vector2.ZERO
var _pull := 0.0
var _side := 0.0
var _result_t := 0.0
var _hole_over := false
var _prev := Vector3.ZERO
var _cur := Vector3.ZERO
var _events_seen := 0
var _bot_t := 0.0

var _terrain: GolfTerrain
var _ball_mesh: MeshInstance3D
var _marker: MeshInstance3D
var _flag: Node3D
var _aim_line: ImmediateMesh
var _trail: ImmediateMesh
var _trail_pts := PackedVector3Array()
var _cam: Camera3D
var _cam_ready := false
var _hud_top: Label
var _hud_info: Label
var _banner: Label
var _hint: Label
var _meter: Control
var _club_buttons: Array[Button] = []


## Schema history: 1 = first version. Bump SAVE_SCHEMA and handle `from` here on any change.
static func migrate_save(old: Dictionary, _from: int, _to: int) -> Dictionary:
	return old


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see CLAUDE.md
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
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.8, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.9, 0.95)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.85, 0.95)
	env.fog_density = 0.0012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 0.9
	add_child(sun)
	_terrain = GolfTerrain.new()
	add_child(_terrain)
	_terrain.build(_hole, 3)
	_ball_mesh = _mesh(_sphere(_ball_r()), Color(0.98, 0.98, 0.98), true)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.6
	disc.bottom_radius = 1.6
	disc.height = 0.04
	disc.radial_segments = 32
	_marker = _mesh(disc, Color(1.0, 0.85, 0.25, 0.75), true)
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
	var cup := CylinderMesh.new()
	cup.top_radius = GolfBall.CUP_R * 2.0
	cup.bottom_radius = GolfBall.CUP_R * 2.0
	cup.height = 0.02
	_mesh(cup, Color(0.05, 0.05, 0.05), true, _flag)
	_aim_line = _immediate()
	_trail = _immediate()
	_cam = Camera3D.new()
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 60.0
	_cam.far = 1500.0
	add_child(_cam)
	_cam.make_current()


func _ball_r() -> float:
	return _ball.p.radius * BALL_DRAW


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


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
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0, 0, 0, 0.45), 26))
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
	_banner.position = Vector2(0, 640)
	_banner.size = Vector2(1080, 240)
	layer.add_child(_banner)
	var h := get_viewport().get_visible_rect().size.y
	_hint = _outlined("", 30, Color.WHITE, 700, 10)
	_hint.position = Vector2(40, h - 330)
	_hint.size = Vector2(1000, 80)
	layer.add_child(_hint)
	for i in GolfClubs.count() + 1:
		var c := i
		var b := UiKit.button(GolfClubs.name_of(c), Color(0, 0, 0, 0.5), Color.WHITE, 30, 96)
		b.position = Vector2(24 + i * 172, h - 140)
		b.size = Vector2(160, 96)
		b.pressed.connect(func() -> void: _choose_club(c))
		layer.add_child(b)
		_club_buttons.append(b)
	_meter = Control.new()
	_meter.position = Vector2(1080 - 90, 520)
	_meter.size = Vector2(56, 640)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter.draw.connect(_draw_meter)
	layer.add_child(_meter)


func _choose_club(c: int) -> void:
	if mode != Mode.AIM:
		return
	_club = c
	_club_manual = true
	AudioService.play("tap")
	_refresh()


## Power meter: fill = pull, gold tick = power for the marker, red band = overpower.
func _draw_meter() -> void:
	var r := Rect2(Vector2.ZERO, _meter.size)
	_meter.draw_rect(r, Color(0, 0, 0, 0.45))
	var over := r.size.y * (1.0 - 1.0 / GolfClubs.MAX_POWER)
	_meter.draw_rect(Rect2(0, 0, r.size.x, over), Color(0.9, 0.25, 0.2, 0.35))
	var f := clampf(_pull / GolfClubs.MAX_POWER, 0.0, 1.0)
	var col := Color(0.95, 0.4, 0.3) if _pull > 1.0 else Color(0.35, 0.9, 0.55)
	_meter.draw_rect(Rect2(0, r.size.y * (1.0 - f), r.size.x, r.size.y * f), col)
	var want := clampf(_wanted_power() / GolfClubs.MAX_POWER, 0.0, 1.0)
	_meter.draw_rect(Rect2(-12, r.size.y * (1.0 - want) - 4, r.size.x + 24, 8), UiKit.GOLD)


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
	_banner.text = ""
	_new_shot()


func _new_shot() -> void:
	mode = Mode.AIM
	_banner.text = ""
	_pull = 0.0
	_side = 0.0
	_club_manual = false
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
		# Aim at the pin if a full driver reaches it, else down the hole's centre line.
		var reach := _clubs.carry_at(0, 1.0) * 0.92
		if to_pin <= reach:
			_set_target(_hole.pin)
		else:
			_set_target(_along_path(reach))


## The point on the hole's centre line `ahead` metres (straight-line) from the ball.
func _along_path(ahead: float) -> Vector3:
	var pts: Array = _spec.path
	var best := _flat(_hole.pin)
	for k in range(pts.size() - 1):
		var a := Vector3(pts[k][0], 0.0, pts[k][1])
		var b := Vector3(pts[k + 1][0], 0.0, pts[k + 1][1])
		for t in 41:
			var q := a.lerp(b, t / 40.0)
			var d := _flat(q - _ball_at).length()
			if (
				d <= ahead
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
		# Club up from a bad lie (rough / sand take speed off).
		var lie := GolfClubs.lie(_hole.surface_at(_ball_at.x, _ball_at.z))
		_club = _clubs.pick(_flat(_target - _ball_at).length() / lie.x)
	_refresh()


func _wanted_power() -> float:
	var d := _flat(_target - _ball_at).length()
	if _club == GolfClubs.PUTTER:
		return GolfClubs.putt_speed(d, _ball.surf.roll[HoleData.Surface.GREEN]) / GolfClubs.MAX_PUTT
	var lie := GolfClubs.lie(_hole.surface_at(_ball_at.x, _ball_at.z))
	return _clubs.power_for(_club, d / lie.x)


func _refresh() -> void:
	_hud_top.text = (
		"%s · PAR %d · %s"
		% [
			str(_spec.get("name", "")).to_upper(),
			int(_spec.get("par", 4)),
			GolfClubs.name_of(_club)
		]
	)
	var to_pin := _flat(_hole.pin - _ball_at).length()
	_hud_info.text = (
		"Stroke %d · %d m to pin · aim %d m · wind %.1f m/s %s"
		% [
			_strokes + 1,
			roundi(to_pin),
			roundi(_flat(_target - _ball_at).length()),
			_wind.length(),
			_wind_arrow()
		]
	)
	for i in _club_buttons.size():
		_club_buttons[i].modulate = UiKit.GOLD if i == _club else Color.WHITE
	_hint.text = (
		"Drag on the course to aim · press below, pull DOWN and let go" if mode == Mode.AIM else ""
	)
	_meter.queue_redraw()
	_draw_aim()


## Wind relative to the line of play.
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


func _hit() -> void:
	var drift := clampf(_side, -1.0, 1.0)
	if _pull > 1.0:
		drift *= 2.0  # overpower: errors grow
	var to := _flat(_target - _ball_at)
	var heading := rad_to_deg(atan2(to.x, -to.z)) + drift * MAX_PUSH
	_strokes += 1
	_events_seen = 0
	_ball = GolfBall.new(_hole, _preset)
	if _club == GolfClubs.PUTTER:
		var sp := _pull * GolfClubs.MAX_PUTT
		var h := deg_to_rad(heading)
		_ball.putt(_ball_at.x, _ball_at.z, sin(h) * sp, -cos(h) * sp)
		AudioService.play("clack", 0.7, -8.0)
	else:
		var l := GolfClubs.launch(_club, _pull)
		var lie := GolfClubs.lie(_hole.surface_at(_ball_at.x, _ball_at.z))
		_ball.strike(_ball_at, l[0] * lie.x, l[1], l[2] * lie.y, drift * MAX_TILT, heading)
		_ball.flight.set_wind(_wind)
		AudioService.play("cue", 0.6 + 0.2 * minf(_pull, 1.0), -2.0)
		AudioService.buzz(int(10 + 10 * minf(_pull, 1.0)))
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
			_banner.text = "Water · +1"
			_ball_at = _drop_point(_ball.last_safe)
			AudioService.play("foul", 1.0, -4.0)
		GolfBall.Phase.OUT:
			_strokes += 1  # stroke and distance: replay from the same spot
			_banner.text = "Out of bounds · +1"
			AudioService.play("foul", 1.0, -4.0)
		_:
			_ball_at = _ball.pos()
			_banner.text = LIES[_hole.surface_at(_ball_at.x, _ball_at.z)]
	if not _hole_over and _strokes >= par + 3:
		_banner.text = "Picked up · %d" % (_strokes + 1)
		_hole_over = true
	_banner.modulate.a = 1.0


## A drop on playable ground near where the ball went in (stepping back towards the tee).
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
	if mode == Mode.MOVING:
		_prev = _cur
		for i in 4:
			_ball.substep()
			if _ball.done():
				break
		_cur = _ball.pos()
		if _ball.phase == GolfBall.Phase.FLY and _ball.bounces == 0:
			_trail_pts.append(_cur)  # the trail traces the flight only
		_sounds()
		if _ball.done():
			_shot_over()
	elif mode == Mode.RESULT:
		_result_t += delta
		_banner.modulate.a = clampf(2.4 - _result_t, 0.0, 1.0)
		if _result_t > 2.2:
			if _hole_over:
				_pin_index += 1
				_start_hole()
			else:
				_new_shot()
	elif mode == Mode.AIM and Boot.bot:
		_bot_t += delta
		if _bot_t > 1.2:  # smoke runs / screenshots: hit the marked power, dead straight
			_bot_t = 0.0
			_pull = _wanted_power()
			_side = 0.0
			_hit()


func _sounds() -> void:
	while _events_seen < _ball.events.size():
		var kind := _ball.events[_events_seen]
		var v := _ball.event_speed[_events_seen]
		_events_seen += 1
		if kind == GolfBall.Ev.BOUNCE:
			AudioService.play(
				"cushion", 0.7, clampf(linear_to_db(clampf(v / 25.0, 0.1, 1.0)), -20.0, -2.0)
			)
		elif kind == GolfBall.Ev.LIP:
			AudioService.play("clack", 1.1, -6.0)


func _process(delta: float) -> void:
	var f := Engine.get_physics_interpolation_fraction() if mode == Mode.MOVING else 1.0
	var p := _prev.lerp(_cur, f)
	_ball_mesh.position = p + Vector3(0, _ball_r() - _ball.p.radius, 0)
	_ball_mesh.visible = not (_ball.phase == GolfBall.Phase.HOLED and mode == Mode.RESULT)
	if mode == Mode.MOVING and _trail_pts.size() > 1 and _club != GolfClubs.PUTTER:
		_draw_trail(p)
	_marker.visible = mode == Mode.AIM or mode == Mode.PULL
	_marker.position = _target + Vector3(0, 0.05, 0)
	# About 1.5% of the shot length: a 1.6 m disc on a drive, a coin-sized mark on a putt.
	var ms := clampf(_flat(_target - _ball_at).length() * 0.015, 0.12, 1.6) / 1.6
	_marker.scale = Vector3(ms, 1.0, ms)
	_place_camera(delta, p)


func _draw_trail(p: Vector3) -> void:
	_trail.clear_surfaces()
	var n := _trail_pts.size()
	var flying := _ball.phase == GolfBall.Phase.FLY and _ball.bounces == 0
	var last := n + (1 if flying else 0)
	# Skip points right at the lens (the ribbon would fan out across the screen).
	var first := maxi(0, n - 150)  # last ~2.5 s of flight
	while first < last - 1 and _pt(first, p).distance_squared_to(_cam.position) < 64.0:
		first += 1
	if last - first < 2:
		return
	_trail.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for k in range(first, last):
		var q := _pt(k, p)
		var nxt := _pt(mini(k + 1, last - 1), p)
		# Thinner near the lens so the ribbon never fans out across the screen.
		var cd := q.distance_to(_cam.position)
		var side := (
			(nxt - q).cross(_cam.position - q).normalized() * 0.08 * clampf(cd / 25.0, 0.15, 1.0)
		)
		var a := 0.15 + 0.65 * float(k - first) / (last - first)
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
	if mode != Mode.AIM and mode != Mode.PULL:
		return
	var a := _ball_at
	var b := _target
	var d := _flat(b - a).length()
	if d < 1.0:
		return
	var n := maxi(2, int(d / 3.0))
	var side := Vector3(-(b - a).z, 0.0, (b - a).x).normalized() * 0.25
	_aim_line.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(0, n, 2):
		var p0 := a.lerp(b, float(k) / n)
		var p1 := a.lerp(b, float(k + 1) / n)
		p0.y = _hole.height(p0.x, p0.z) + 0.08
		p1.y = _hole.height(p1.x, p1.z) + 0.08
		for v in [p0 - side, p1 - side, p1 + side, p0 - side, p1 + side, p0 + side]:
			_aim_line.surface_set_color(Color(1, 1, 1, 0.7))
			_aim_line.surface_add_vertex(v)
	_aim_line.surface_end()


## Aim: behind the ball looking down the line. Moving: chase. Putting: lower and closer.
func _place_camera(delta: float, ball: Vector3) -> void:
	var fwd := _flat(_target - _ball_at)
	fwd = fwd.normalized() if fwd.length() > 0.5 else Vector3(0, 0, -1)
	var want: Vector3
	var look: Vector3
	var d := _flat(_target - _ball_at).length()
	if mode == Mode.MOVING and _club != GolfClubs.PUTTER:
		var vel := _flat(_cur - _prev)
		var dir := vel.normalized() if vel.length() > 0.001 else fwd
		want = ball - dir * 12.0 + Vector3(0, 4.0 + maxf(0.0, ball.y - _ball_at.y) * 0.3, 0)
		look = ball + dir * 20.0
	elif _club == GolfClubs.PUTTER:
		want = _ball_at - fwd * (3.0 + d * 0.25) + Vector3(0, 1.6 + d * 0.12, 0)
		look = _ball_at.lerp(_target, 0.6)
	else:
		want = _ball_at - fwd * 7.0 + Vector3(0, 3.0, 0)
		look = _ball_at + fwd * minf(d * 0.55, 90.0)
		look.y = _hole.height(look.x, look.z)
	var rate := 4.0 if mode == Mode.MOVING else 8.0
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
		else:
			_release()
		return
	var mm := event as InputEventMouseMotion
	if mm == null:
		return
	if mode == Mode.PULL:
		_pull = clampf((mm.position.y - _pull_from.y) / PULL_PX, 0.0, GolfClubs.MAX_POWER)
		_side = clampf((mm.position.x - _pull_from.x) / SIDE_PX, -1.0, 1.0)
		_meter.queue_redraw()
	elif mode == Mode.AIM and mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_aim_at(mm.position)


func _press(at: Vector2) -> void:
	if mode != Mode.AIM:
		return
	if at.y > PAD_TOP:
		mode = Mode.PULL
		_pull_from = at
		_pull = 0.0
		_side = 0.0
		_hint.text = "Pull down for power · let go to hit · slide back up to cancel"
	else:
		_aim_at(at)


func _release() -> void:
	if mode != Mode.PULL:
		return
	if _pull < 0.04:
		mode = Mode.AIM  # pulled back up: cancelled
		_pull = 0.0
		_refresh()
		return
	_hit()


## Moves the landing marker to the course point under the finger (ray-marched on the terrain).
func _aim_at(screen: Vector2) -> void:
	var o := _cam.project_ray_origin(screen)
	var dir := _cam.project_ray_normal(screen)
	var t := 2.0
	while t < 600.0:
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
				_set_target(hit)
			return
		t += 2.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneRouter.back_to_hub()
