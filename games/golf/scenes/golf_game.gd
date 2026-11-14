extends Node3D
## Fairway Flick - FLIGHT PREVIEW (steps 2-3 of docs/plans/2026-11-14-fairway-flick.md) while the
## game is built behind enabled = false: a flat practice hole, three clubs, tap the course to hit.
## Tap left / right of centre to curve the shot. The ball flies on the real solver (GolfFlight over
## HoleData, 4 x 1/240 s substeps per tick) and stops where it first lands - no bounce or roll yet.
## Nodes are moved in _process from interpolated solver states, so root interpolation is OFF.

const SAVE_SCHEMA := 1
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"best_score": 0,
	"difficulty": "medium",
	"tutorial_seen": false,
}
## Average amateur launches (TrackMan 14.5-handicap driver; irons scaled from tour by 0.78):
## [name, ball speed mph, launch deg, spin rpm]
const CLUBS := [
	["Driver", 133.0, 12.6, 3275.0], ["7-iron", 96.0, 17.5, 6500.0], ["Wedge", 81.0, 25.0, 8500.0]
]
const BALL_DRAW := 4.0  # ball drawn 4x real size so it reads on a phone
const STEP := 1.0 / 60.0
const MAX_TILT := 14.0

var _save: Dictionary
var _hole := HoleData.new()
var _flight := GolfFlight.new()
var _rng := Rng.make(0x901f)
var _club := 1
var _flying := false
var _landed := false
var _wind := Vector3.ZERO
var _prev := Vector3.ZERO
var _cur := Vector3.ZERO
var _trail := PackedVector3Array()
var _hold := 0.0

var _ball: MeshInstance3D
var _trail_mesh: ImmediateMesh
var _cam: Camera3D
var _info: Label
var _result: Label
var _buttons: Array[Button] = []


## Schema history: 1 = first version. Bump SAVE_SCHEMA and handle `from` here on any change.
static func migrate_save(old: Dictionary, _from: int, _to: int) -> Dictionary:
	return old


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see the project rules
	_save = SaveService.game("golf", SAVE_SCHEMA, SAVE_DEFAULTS, migrate_save)
	_hole.setup(-40.0, -260.0, 1.0, 80, 262)
	_hole.fill(
		func(_x: float, _z: float) -> float: return 0.0,
		func(x: float, z: float) -> int:
			if Vector2(x, z + 150.0).length() < 12.0:
				return HoleData.Surface.GREEN
			return HoleData.Surface.FAIRWAY if absf(x) < 14.0 else HoleData.Surface.ROUGH
	)
	_build_world()
	_build_ui()
	_reset()


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.56, 0.78, 0.96)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.92)
	env.ambient_light_energy = 0.45
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.84, 0.95)
	env.fog_density = 0.0015
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 0.85
	add_child(sun)
	_plane(Vector2(400, 700), Vector3(0, -0.02, -150), Color(0.13, 0.33, 0.13))  # rough
	_plane(Vector2(28, 262), Vector3(0, 0.0, -129), Color(0.22, 0.5, 0.2))  # fairway
	for k in 13:  # mowing stripes
		_plane(Vector2(28, 10), Vector3(0, 0.002, -10 - k * 20), Color(0.26, 0.56, 0.24))
	var green := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 12.0
	disc.bottom_radius = 12.0
	disc.height = 0.01
	disc.radial_segments = 48
	green.mesh = disc
	green.material_override = _mat(Color(0.33, 0.66, 0.3))
	green.position = Vector3(0, 0.004, -150)
	add_child(green)
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 2.4
	pole.mesh = cyl
	pole.material_override = _mat(Color(0.95, 0.95, 0.95))
	pole.position = Vector3(0, 1.2, -150)
	add_child(pole)
	var flag := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.55, 0.02)
	flag.mesh = box
	flag.material_override = _mat(Color(0.95, 0.25, 0.2))
	flag.position = Vector3(0.45, 2.1, -150)
	add_child(flag)
	for d in [50, 100, 150, 200]:
		var l := Label3D.new()
		l.text = "%d m" % d
		l.font_size = 160
		l.pixel_size = 0.01
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.modulate = Color(1, 1, 1, 0.85)
		l.position = Vector3(-17, 1.0, -float(d))
		add_child(l)
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _flight.p.radius * BALL_DRAW
	sphere.height = sphere.radius * 2.0
	_ball.mesh = sphere
	_ball.material_override = _mat(Color(0.98, 0.98, 0.98))
	add_child(_ball)
	_trail_mesh = ImmediateMesh.new()
	var trail := MeshInstance3D.new()
	trail.mesh = _trail_mesh
	var tm := StandardMaterial3D.new()
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.albedo_color = Color(1, 1, 1, 0.8)
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	trail.material_override = tm
	add_child(trail)
	_cam = Camera3D.new()
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 58.0
	add_child(_cam)
	_cam.make_current()


func _plane(size: Vector2, at: Vector3, col: Color) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	m.mesh = pm
	m.material_override = _mat(col)
	m.position = at
	add_child(m)


func _mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	return m


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := UiKit.safe_top(layer)
	var title := UiKit.label("FAIRWAY FLICK · flight preview", 40, Color.WHITE, 900)
	title.position = Vector2(0, top + 24)
	title.size = Vector2(1080, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	layer.add_child(title)
	_info = UiKit.label("", 34, Color.WHITE, 700)
	_info.position = Vector2(0, top + 90)
	_info.size = Vector2(1080, 110)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_constant_override("outline_size", 14)
	_info.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	layer.add_child(_info)
	_result = UiKit.label("", 64, UiKit.GOLD, 900)
	_result.position = Vector2(0, 760)
	_result.size = Vector2(1080, 200)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result.add_theme_constant_override("outline_size", 14)
	_result.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	layer.add_child(_result)
	var h := get_viewport().get_visible_rect().size.y
	for i in CLUBS.size():
		var b := UiKit.button(CLUBS[i][0], Color(0, 0, 0, 0.45), Color.WHITE, 40, 120)
		b.position = Vector2(40 + i * 340, h - 220)
		b.size = Vector2(320, 120)
		var idx := i
		b.pressed.connect(
			func() -> void:
				_club = idx
				AudioService.play("tap")
				_reset()
		)
		layer.add_child(b)
		_buttons.append(b)


func _reset() -> void:
	_flying = false
	_landed = false
	_hold = 0.0
	var w := _rng.randf_range(0.0, 5.0)
	var dir := _rng.randf_range(0.0, TAU)
	_wind = Vector3(cos(dir), 0.0, sin(dir)) * w
	var tee := Vector3(0.0, _flight.p.radius, 0.0)
	_flight.launch(tee, 1.0, 0.0, 0.0)
	_prev = tee
	_cur = tee
	_trail.clear()
	_trail_mesh.clear_surfaces()
	_result.text = ""
	for i in _buttons.size():
		_buttons[i].modulate = Color(1, 0.85, 0.3) if i == _club else Color.WHITE
	var arrow := "←" if _wind.x < -0.5 else ("→" if _wind.x > 0.5 else "")
	var along := "into you" if _wind.z > 0.5 else ("behind you" if _wind.z < -0.5 else "")
	_info.text = (
		"%s  ·  wind %.1f m/s %s %s\nTap the course to hit · tap left / right of centre to curve"
		% [CLUBS[_club][0], w, arrow, along]
	)
	_place_camera(true)


func _hit(screen_x: float) -> void:
	var c: Array = CLUBS[_club]
	var tilt := clampf((screen_x - 540.0) / 540.0, -1.0, 1.0) * MAX_TILT
	_flight.launch(
		Vector3(0.0, _flight.p.radius, 0.0),
		float(c[1]) * GolfFlight.MPH,
		c[2],
		float(c[3]) * GolfFlight.RPM,
		tilt
	)
	_flight.set_wind(_wind)
	_flying = true
	_trail.clear()
	_trail.append(_flight.pos())
	_result.text = ""
	AudioService.play("cue", 0.7)
	AudioService.buzz(20)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _landed:
		_reset()
	elif not _flying:
		_hit(mb.position.x)


func _physics_process(_delta: float) -> void:
	if Boot.bot and not _flying:  # smoke runs / screenshots: hit, wait, go again
		_hold += STEP
		if _hold > 1.0:
			if _landed:
				_club = (_club + 1) % CLUBS.size()
				_reset()
			else:
				_hit(700.0)
	if not _flying:
		return
	_prev = _cur
	var r := GolfFlight.Over.FLYING
	for i in 4:
		r = _flight.step_over(_hole)
		if r != GolfFlight.Over.FLYING:
			break
	_cur = _flight.pos()
	_trail.append(_cur)
	if r != GolfFlight.Over.FLYING:
		_flying = false
		_landed = true
		_show_result(r == GolfFlight.Over.HIT)


func _show_result(hit: bool) -> void:
	var at := _flight.pos()
	var carry := Vector2(at.x, at.z).length()
	if not hit:
		_result.text = "Out of bounds"
		return
	var names := ["Out", "Tee", "Fairway", "Rough", "Fringe", "Green", "Sand", "Water", "Path"]
	var to_pin := Vector2(at.x, at.z + 150.0).length()
	_result.text = (
		"Carry %d m · %s\nApex %d m · %d m from the flag\nTap to go again"
		% [roundi(carry), names[_hole.surface_at(at.x, at.z)], roundi(_flight.apex), roundi(to_pin)]
	)
	AudioService.play("cushion", 0.8, -6.0)


func _process(delta: float) -> void:
	var f := Engine.get_physics_interpolation_fraction() if _flying else 1.0
	var p := _prev.lerp(_cur, f)
	_ball.position = p + Vector3(0, _flight.p.radius * (BALL_DRAW - 1.0), 0)
	if _trail.size() > 1:
		_trail_mesh.clear_surfaces()
		# Camera-facing ribbon, 6 cm wide (a 1-pixel line vanishes on a phone).
		_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		var n := _trail.size()
		for k in n + 1:
			var q: Vector3 = _trail[k] if k < n else p
			var nxt: Vector3 = _trail[mini(k + 1, n - 1)] if k < n else p
			var side := (nxt - q).cross(_cam.position - q).normalized() * 0.06
			if side == Vector3.ZERO:
				side = Vector3(0.06, 0, 0)
			_trail_mesh.surface_add_vertex(q - side)
			_trail_mesh.surface_add_vertex(q + side)
		_trail_mesh.surface_end()
	if _landed:
		_hold += delta
	_place_camera(false, delta, p)


## Behind the tee while aiming; then chases the ball from behind and above.
func _place_camera(snap: bool, delta := 0.0, ball := Vector3.ZERO) -> void:
	var want := Vector3(0.0, 2.4, 6.0)
	var look := Vector3(0.0, 0.0, -70.0)
	if _flying or _landed:
		want = ball + Vector3(0.0, 3.0 + ball.y * 0.35, 11.0)
		look = ball + Vector3(0.0, 0.0, -25.0)
	if snap:
		_cam.position = want
	else:
		_cam.position = _cam.position.lerp(want, 1.0 - exp(-3.5 * delta))
	_cam.look_at(look)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneRouter.back_to_hub()
