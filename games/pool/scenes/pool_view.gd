class_name PoolView
extends Node3D
## Cue Club 3D table (renders only; never owns game state). docs/research/Cue Club pool game
## design.md "About twelve draw calls render the whole table":
## - Long perspective lens (22 deg, KEEP_WIDTH), pitched 12 deg towards the player; table long axis
##   vertical on screen; fixed while aiming.
## - One MultiMesh + one unshaded shader for all 16 balls: stripes and the cue marker in object
##   space (they roll), numbers as an upright camera-facing disc (readable at ~20 dp), painted
##   lamp: wrap diffuse, tight highlight, Fresnel rim. Ball spin is visual only (quaternions).
## - Painted table (cloth, cushions, wood, pockets, sights) with no real lights or shadow maps;
##   soft blob shadows in one MultiMesh.
## - Aim line, ghost ball, object / cue rays and the cue from preallocated meshes.
## World: sim (x, y) -> (x, height, -y); y up the table = into the screen.

const FOV := 22.0
const PITCH_DEG := 5.0
const RAIL := 0.03  # cushion depth beyond the nose (drawn thin: more screen for the balls)
const WOOD := 0.04
const TABLE_FILL := 0.985  # outer table width / screen width (side controls overlay the wood)
const MAX_SPIN_STEP := 1.2  # rad of visual rotation per tick (fast balls strobe otherwise)
const PHYS_DT := 1.0 / 60.0
const DROP_TIME := 0.32  # seconds a potted ball takes to roll into the hole and sink

## Ball colours (sRGB): cue, 1-7 solids, 8, 9-15 stripes of the same colours. Original palette.
const BALL_COLORS := [
	Color("#F4F1E6"),
	Color("#F2C230"),
	Color("#2456C8"),
	Color("#D9312B"),
	Color("#6B3FA0"),
	Color("#F07A1E"),
	Color("#1E8C4E"),
	Color("#8B1E2E"),
	Color("#16161B"),
]

const BALL_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;
uniform sampler2D digits : filter_linear_mipmap;
uniform vec4 colors[16];
uniform vec3 light_dir = vec3(-0.35, 1.0, 0.45);
uniform float radius = 0.028575;
uniform float show_numbers = 1.0;
varying vec3 obj_n;
varying float bid;
varying float fade;
varying float rest;
varying vec3 vctr;
varying vec3 vpos;

void vertex() {
	obj_n = normalize(VERTEX);
	bid = INSTANCE_CUSTOM.r * 255.0;
	fade = INSTANCE_CUSTOM.g;
	rest = INSTANCE_CUSTOM.b;
	vctr = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vpos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	int b = int(bid + 0.5);
	vec3 base = colors[b].rgb;
	vec3 white = vec3(0.86, 0.84, 0.78);
	vec3 col = base;
	if (b == 0) {
		// Cue ball: small red markers so its spin is visible.
		float m = smoothstep(0.22, 0.18, length(obj_n.xz - vec2(0.0, 0.0)) ) * step(0.0, obj_n.y);
		m += smoothstep(0.22, 0.18, length(obj_n.xy)) * step(0.0, obj_n.z);
		col = mix(white, vec3(0.75, 0.08, 0.06), clamp(m, 0.0, 1.0) * fade);
	} else if (b >= 9) {
		float band = smoothstep(0.62, 0.55, abs(obj_n.y));
		col = mix(white, base, mix(0.75, band, fade));
	}
	if (b > 0 && show_numbers > 0.5) {
		vec2 cell = vec2(float(b % 4), float(b / 4));
		// Printed numbers on two opposite sides: they roll with the ball like the real thing.
		float side = obj_n.z >= 0.0 ? 1.0 : -1.0;
		vec2 q = vec2(obj_n.x * side, -obj_n.y) / 0.42;
		float pd = smoothstep(1.0, 0.9, length(q)) * (1.0 - rest) * fade;
		float pink = texture(digits, (cell + clamp(q * 0.5 * 0.9 + 0.5, 0.0, 1.0)) / 4.0).a * pd;
		col = mix(col, white, pd);
		col = mix(col, vec3(0.03, 0.03, 0.04), pink);
		// At rest an upright label fades in on top, so numbers stay readable from above.
		vec2 off = (vpos.xy - vctr.xy) / radius;
		float disc = smoothstep(0.52, 0.47, length(off)) * rest;
		vec2 cuv = vec2(off.x, -off.y) / 0.5 * 0.5 * 0.9 + 0.5;
		float ink = texture(digits, (cell + clamp(cuv, 0.0, 1.0)) / 4.0).a * disc;
		col = mix(col, white, disc);
		col = mix(col, vec3(0.03, 0.03, 0.04), ink);
	}
	vec3 n = normalize(NORMAL);
	vec3 l = normalize((VIEW_MATRIX * vec4(light_dir, 0.0)).xyz);
	vec3 v = normalize(-VERTEX);
	float diff = clamp(dot(n, l) * 0.5 + 0.5, 0.0, 1.0);
	float lit = 0.32 + 0.8 * diff * diff;
	vec3 h = normalize(l + v);
	float spec = pow(max(dot(n, h), 0.0), 90.0);
	float fres = 0.04 + 0.96 * pow(1.0 - max(dot(n, v), 0.0), 5.0);
	ALBEDO = col * lit + vec3(spec * 0.85) + vec3(0.6, 0.65, 0.7) * fres * 0.12;
}
"""

const CLOTH_SHADER := """
shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform vec4 cloth : source_color = vec4(0.07, 0.52, 0.49, 1.0);
uniform vec2 half_size = vec2(0.5, 1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * half_size;
	float pool = 1.12 - 0.36 * length(p / (half_size * vec2(1.25, 1.1)));
	vec2 edge = half_size - abs(p);
	float vig = smoothstep(0.0, 0.06, min(edge.x, edge.y));
	float fibre = (hash(floor(UV * vec2(700.0, 1400.0))) - 0.5) * 0.05;
	ALBEDO = cloth.rgb * (pool * (0.82 + 0.18 * vig) + fibre);
}
"""

const FLAT_SHADER := """
shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0);
uniform float grain = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float g = grain * (sin(UV.x * 90.0 + hash(floor(UV * 40.0)) * 3.0) * 0.5 + 0.5);
	float top = 0.85 + 0.15 * clamp(NORMAL.y, 0.0, 1.0);
	ALBEDO = color.rgb * (1.0 - g * 0.12) * top;
}
"""

const SHADOW_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	ALBEDO = vec3(0.0);
	ALPHA = (smoothstep(1.0, 0.2, r) * 0.42 + smoothstep(0.45, 0.25, r) * 0.25) * COLOR.a;
}
"""

const LINE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.85);
uniform float length_m = 1.0;
uniform float dash = 0.0;
void fragment() {
	float f = fract(UV.x * length_m / max(dash, 1e-4));
	float on = dash > 0.0 ? smoothstep(0.35, 0.45, f) * smoothstep(1.0, 0.92, f) : 1.0;
	float edge = smoothstep(0.0, 0.35, UV.y) * smoothstep(1.0, 0.65, UV.y);
	ALBEDO = color.rgb;
	ALPHA = color.a * on * edge;
}
"""

const RING_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 0.9);
uniform float width = 0.12;
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float ring = smoothstep(1.0, 1.0 - 0.06, r) * smoothstep(1.0 - width - 0.06, 1.0 - width, r);
	ALBEDO = color.rgb;
	ALPHA = color.a * ring;
}
"""

var camera: Camera3D
var sim: CueSim
var radius := 0.028575
var hw := 0.4955
var hl := 0.9905

var _balls: MultiMeshInstance3D
var _shadows: MultiMeshInstance3D
var _ball_mat: ShaderMaterial
var _quat: Array[Quaternion] = []
var _prev := PackedVector3Array()
var _cur := PackedVector3Array()
var _fade := PackedFloat32Array()
var _rest := PackedFloat32Array()
## Pocket drop animation per ball: time since capture (-1 = none), start and hole positions.
var _drop := PackedFloat32Array()
var _drop_from := PackedVector3Array()
var _drop_to := PackedVector3Array()
var _digits: SubViewport
var _cue: MeshInstance3D
var _aim_line: MeshInstance3D
var _obj_ray: MeshInstance3D
var _cue_ray: MeshInstance3D
var _ghost: MeshInstance3D
var _kitchen: MeshInstance3D
var _pocket_rings: Array[MeshInstance3D] = []
var _layout_top := 300.0
var _layout_bottom := 220.0


func setup(cue_sim: CueSim) -> void:
	sim = cue_sim
	radius = sim.p.radius
	hw = sim.table.hw
	hl = sim.table.hl
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_make_environment()
	_make_camera()
	_make_table()
	_make_digits()
	_make_balls()
	_make_aim()
	# Start with a printed number facing up (object +z -> world up), each turned a little.
	for i in CueSim.N:
		var yaw := Quaternion(Vector3.UP, (i * 0.618034) * TAU)
		_quat.append(yaw * Quaternion(Vector3.RIGHT, -PI * 0.5))
	_prev.resize(CueSim.N)
	_cur.resize(CueSim.N)
	_fade.resize(CueSim.N)
	_rest.resize(CueSim.N)
	_drop.resize(CueSim.N)
	_drop.fill(-1.0)
	_drop_from.resize(CueSim.N)
	_drop_to.resize(CueSim.N)
	snap()


## Free canvas space above and below the table (HUD bands), then re-frame the camera.
func set_margins(top: float, bottom: float) -> void:
	_layout_top = top
	_layout_bottom = bottom
	_frame_camera()


# --- per frame ---------------------------------------------------------------------------------


## Copy the solver state as both previous and current (after a placement / re-rack).
## Balls already dropping into a pocket keep animating.
func snap() -> void:
	for i in CueSim.N:
		if not sim.on_table(i) and _drop[i] >= 0.0:
			continue
		_cur[i] = _world(i) if sim.on_table(i) else Vector3(0, -1, 0)
		_prev[i] = _cur[i]
		if sim.on_table(i):
			_drop[i] = -1.0
	render(1.0)


## Centre of a pocket hole as drawn (balls sink towards it).
func _hole(k: int) -> Vector2:
	var m := _pocket_mouth(k)
	if k < 4:
		return m + Vector2(sign(m.x), sign(m.y)) * 0.008
	return m + Vector2(sign(m.x) * 0.016, 0.0)


## Call after each fixed step: integrates the visual spin and shifts current -> previous.
func physics_tick(dt: float) -> void:
	for i in CueSim.N:
		var was := _cur[i]
		_prev[i] = _cur[i]
		_cur[i] = _world(i)
		if not sim.on_table(i):
			if _drop[i] < 0.0 and was.y > 0.0:
				# Just captured: roll on into the hole and sink instead of vanishing.
				_drop[i] = 0.0
				_drop_from[i] = was
				var k := sim.pocket_of[i]
				var hole := _hole(k) if k >= 0 else Vector2(sim.px[i], sim.py[i])
				_drop_to[i] = to_world(hole, radius)
			elif _drop[i] >= 0.0:
				_drop[i] += dt
			_cur[i] = Vector3(0, -1, 0)  # marks "off the table" for the next capture check
			_prev[i] = _cur[i]
			continue
		_drop[i] = -1.0
		var w := Vector3(sim.wx[i], sim.wz[i], -sim.wy[i])  # table (x, y, z-up) -> world
		var mag := w.length()
		var moving := _cur[i].distance_squared_to(_prev[i]) > 1e-10
		_rest[i] = 0.0 if moving else minf(1.0, _rest[i] + dt * 3.5)
		if mag > 1e-6:
			var step := mag * dt
			_fade[i] = clampf(1.0 - (step - 1.5), 0.35, 1.0)
			_quat[i] = (Quaternion(w / mag, minf(step, MAX_SPIN_STEP)) * _quat[i]).normalized()
		else:
			_fade[i] = 1.0


func render(frac: float) -> void:
	var mm := _balls.multimesh
	var sm := _shadows.multimesh
	for i in CueSim.N:
		if not sim.on_table(i):
			var k := (_drop[i] + frac * PHYS_DT) / DROP_TIME if _drop[i] >= 0.0 else 2.0
			if k >= 1.0:
				mm.set_instance_transform(
					i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
				)
				sm.set_instance_color(i, Color(1, 1, 1, 0))
				continue
			var e := GestureTimeline.decel(k)
			var p := _drop_from[i].lerp(_drop_to[i], e)
			p.y = radius - 0.06 * k * k
			mm.set_instance_transform(
				i, Transform3D(Basis(_quat[i]).scaled(Vector3.ONE * (1.0 - 0.15 * k)), p)
			)
			mm.set_instance_custom_data(i, Color(i / 255.0, _fade[i], 0.0, 0))
			sm.set_instance_transform(
				i,
				Transform3D(
					Basis.from_scale(Vector3(3.2, 1, 3.2) * radius), Vector3(p.x, 0.0006, p.z)
				)
			)
			sm.set_instance_color(i, Color(1, 1, 1, 1.0 - k))
			continue
		var p := _prev[i].lerp(_cur[i], frac)
		mm.set_instance_transform(i, Transform3D(Basis(_quat[i]), p))
		mm.set_instance_custom_data(i, Color(i / 255.0, _fade[i], _rest[i], 0))
		sm.set_instance_transform(
			i,
			Transform3D(
				Basis.from_scale(Vector3(3.2, 1, 3.2) * radius),
				Vector3(p.x + 0.006, 0.0006, p.z + 0.004)
			)
		)
		sm.set_instance_color(i, Color(1, 1, 1, 1))


func _world(i: int) -> Vector3:
	return Vector3(sim.px[i], radius, -sim.py[i])


func to_world(p: Vector2, h := 0.0) -> Vector3:
	return Vector3(p.x, h, -p.y)


## Table point under a canvas position (on the plane through the ball centres).
func table_point(screen: Vector2) -> Vector2:
	var o := camera.project_ray_origin(screen)
	var d := camera.project_ray_normal(screen)
	if absf(d.y) < 1e-6:
		return Vector2.ZERO
	var t := (radius - o.y) / d.y
	var w := o + d * t
	return Vector2(w.x, -w.z)


func screen_point(p: Vector2) -> Vector2:
	return camera.unproject_position(to_world(p, radius))


## Canvas-space size of one metre at the table (for converting dp to table distances).
func pixels_per_metre() -> float:
	return screen_point(Vector2(0.5, 0.0)).distance_to(screen_point(Vector2(-0.5, 0.0)))


# --- aim overlays --------------------------------------------------------------------------------


func hide_aim() -> void:
	for n in [_aim_line, _obj_ray, _cue_ray, _ghost, _cue]:
		n.visible = false


## cue_pos: cue ball; aim: PoolAim after predict(); pull: power 0..1 (cue draws back);
## obj_len / cue_len: guideline lengths (difficulty assist).
func show_aim(cue_pos: Vector2, aim: PoolAim, pull: float, obj_len: float, cue_len: float) -> void:
	var d := aim.dir()
	var end := aim.contact if aim.hit_kind == 1 else _ray_to_cushion(cue_pos, d)
	_place_line(_aim_line, cue_pos, end, 0.008)
	_ghost.visible = aim.hit_kind == 1
	if aim.hit_kind == 1:
		_ghost.position = to_world(aim.contact, 0.002)
		var obj := Vector2(sim.px[aim.hit_ball], sim.py[aim.hit_ball])
		_place_line(_obj_ray, obj, obj + aim.obj_dir * obj_len, 0.010)
		_cue_ray.visible = aim.cue_dir != Vector2.ZERO and cue_len > 0.0
		if _cue_ray.visible:
			_place_line(_cue_ray, aim.contact, aim.contact + aim.cue_dir * cue_len, 0.007)
	else:
		_obj_ray.visible = false
		_cue_ray.visible = false
	# Cue stick behind the cue ball, drawn back with the power pull.
	_cue.visible = true
	var back := radius + 0.012 + pull * 0.22
	var mid := cue_pos - d * (back + 0.5)
	_cue.position = to_world(mid, radius + 0.035)
	# Cylinder axis (local +Y, thin tip end) along the aim, butt slightly raised.
	var y_axis := Vector3(d.x, -0.05, -d.y).normalized()
	var x_axis := y_axis.cross(Vector3.UP).normalized()
	_cue.basis = Basis(x_axis, y_axis, x_axis.cross(y_axis))


func show_kitchen(on: bool) -> void:
	_kitchen.visible = on


## Pocket call markers; selected = the called pocket (-1 none).
func show_pockets(on: bool, selected := -1) -> void:
	for k in _pocket_rings.size():
		var ring := _pocket_rings[k]
		ring.visible = on
		var mat := ring.material_override as ShaderMaterial
		mat.set_shader_parameter(
			"color", Color(1.0, 0.85, 0.3, 1.0) if k == selected else Color(1, 1, 1, 0.55)
		)


func pocket_screen(k: int) -> Vector2:
	return screen_point(_pocket_mouth(k))


func _ray_to_cushion(from: Vector2, d: Vector2) -> Vector2:
	var t := 10.0
	var lim := Vector2(hw - radius, hl - radius)
	if absf(d.x) > 1e-6:
		t = minf(t, ((lim.x if d.x > 0.0 else -lim.x) - from.x) / d.x)
	if absf(d.y) > 1e-6:
		t = minf(t, ((lim.y if d.y > 0.0 else -lim.y) - from.y) / d.y)
	return from + d * maxf(t, 0.0)


func _place_line(n: MeshInstance3D, a: Vector2, b: Vector2, width: float) -> void:
	var length := a.distance_to(b)
	n.visible = length > 0.005
	if not n.visible:
		return
	var mid := (a + b) * 0.5
	var d := (b - a) / length
	n.position = to_world(mid, radius * 0.05 + 0.001)
	n.basis = Basis(Vector3(d.x, 0, -d.y) * length, Vector3.UP, Vector3(d.y, 0, d.x) * width)
	(n.material_override as ShaderMaterial).set_shader_parameter("length_m", length)


# --- construction ------------------------------------------------------------------------------


func _make_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.045, 0.06)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _make_camera() -> void:
	camera = Camera3D.new()
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = FOV
	camera.near = 0.5
	camera.far = 20.0
	add_child(camera)
	camera.make_current()
	get_viewport().size_changed.connect(_frame_camera)
	_frame_camera()


## Distance so the outer table spans TABLE_FILL of the width; v_offset centres it between bands.
func _frame_camera() -> void:
	if camera == null:
		return
	var canvas := get_viewport().get_visible_rect().size
	# Fit the outer table by width AND by the height left between the HUD bands.
	var outer_w := 2.0 * (hw + RAIL + WOOD)
	var outer_l := 2.0 * (hl + RAIL + WOOD)
	var avail_h := maxf(canvas.y - _layout_top - _layout_bottom, canvas.y * 0.5)
	var visible_w := maxf(outer_w / TABLE_FILL, outer_l * canvas.x / avail_h)
	var dist := visible_w * 0.5 / tan(deg_to_rad(FOV * 0.5))
	var pitch := deg_to_rad(PITCH_DEG)
	camera.position = Vector3(0.0, cos(pitch), sin(pitch)) * dist
	camera.look_at(Vector3.ZERO, Vector3(0, 0, -1))
	var visible_h := visible_w * canvas.y / canvas.x
	var want := (_layout_top + (canvas.y - _layout_bottom)) * 0.5
	camera.v_offset = (want - canvas.y * 0.5) / canvas.y * visible_h


func _make_table() -> void:
	var cloth := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	# Cloth runs under the cushions to the wood, so the pocket cut-outs show cloth, not a void.
	plane.size = Vector2(hw + RAIL, hl + RAIL) * 2.0
	cloth.mesh = plane
	var cm := _material(CLOTH_SHADER)
	cm.set_shader_parameter("half_size", Vector2(hw + RAIL, hl + RAIL))
	cloth.material_override = cm
	add_child(cloth)
	var cushion_col := Color(0.05, 0.42, 0.40)
	var wood_col := Color(0.42, 0.22, 0.12)
	var cushion := _flat(cushion_col, 0.0)
	var wood := _flat(wood_col, 1.0)
	var t := sim.table
	for k in 6:  # the six rail noses
		var a := Vector2(t.seg_x[k], t.seg_y[k])
		var d := Vector2(t.seg_dx[k], t.seg_dy[k])
		var n := Vector2(t.seg_nx[k], t.seg_ny[k])
		var c := a + d * t.seg_len[k] * 0.5 - n * RAIL * 0.5
		_box(Vector3(t.seg_len[k], 0.04, RAIL), c, d, 0.02, cushion)
	# Wood frame.
	var ow := hw + RAIL + WOOD
	var ol := hl + RAIL + WOOD
	_box(
		Vector3(ow * 2.0, 0.05, WOOD),
		Vector2(0, hl + RAIL + WOOD * 0.5),
		Vector2.RIGHT,
		0.025,
		wood
	)
	_box(
		Vector3(ow * 2.0, 0.05, WOOD),
		Vector2(0, -hl - RAIL - WOOD * 0.5),
		Vector2.RIGHT,
		0.025,
		wood
	)
	_box(Vector3(ol * 2.0, 0.05, WOOD), Vector2(hw + RAIL + WOOD * 0.5, 0), Vector2.UP, 0.025, wood)
	_box(
		Vector3(ol * 2.0, 0.05, WOOD), Vector2(-hw - RAIL - WOOD * 0.5, 0), Vector2.UP, 0.025, wood
	)
	# Cushion strips in the corners' wood gaps are covered by the pocket discs.
	_box(
		Vector3(RAIL, 0.04, RAIL),
		Vector2(hw + RAIL * 0.5, hl + RAIL * 0.5),
		Vector2.RIGHT,
		0.02,
		wood
	)
	_box(
		Vector3(RAIL, 0.04, RAIL),
		Vector2(-hw - RAIL * 0.5, hl + RAIL * 0.5),
		Vector2.RIGHT,
		0.02,
		wood
	)
	_box(
		Vector3(RAIL, 0.04, RAIL),
		Vector2(hw + RAIL * 0.5, -hl - RAIL * 0.5),
		Vector2.RIGHT,
		0.02,
		wood
	)
	_box(
		Vector3(RAIL, 0.04, RAIL),
		Vector2(-hw - RAIL * 0.5, -hl - RAIL * 0.5),
		Vector2.RIGHT,
		0.02,
		wood
	)
	# Pockets: dark discs over the corners / sides, plus call rings.
	var hole := _flat(Color(0.02, 0.02, 0.025), 0.0)
	for k in 6:
		var m := _pocket_mouth(k)
		var corner := k < 4
		var disc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.062 if corner else 0.05
		cyl.bottom_radius = cyl.top_radius
		cyl.height = 0.002
		cyl.radial_segments = 32
		disc.mesh = cyl
		disc.material_override = hole
		# Holes sit in the jaws: corners just past the corner point, sides just past the rail.
		var out := (
			m
			+ (Vector2(sign(m.x), sign(m.y)) * 0.008 if corner else Vector2(sign(m.x) * 0.016, 0.0))
		)
		disc.position = to_world(out, 0.052)
		if not corner:
			disc.scale = Vector3(1.0, 1.0, 1.45)  # side holes are long along the rail (14 cm mouth)
		add_child(disc)
		var ring := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.16, 0.16)
		q.orientation = PlaneMesh.FACE_Y
		ring.mesh = q
		ring.material_override = _material(RING_SHADER)
		ring.position = to_world(out, 0.06)
		ring.visible = false
		add_child(ring)
		_pocket_rings.append(ring)
	# Sights (diamonds): 3 per short rail, 3 per long-rail half.
	var dots := MultiMeshInstance3D.new()
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := CylinderMesh.new()
	dot.top_radius = 0.007
	dot.bottom_radius = 0.007
	dot.height = 0.002
	dot.radial_segments = 12
	dm.mesh = dot
	var spots: Array[Vector2] = []
	var wy := hl + RAIL + WOOD * 0.5
	var wx := hw + RAIL + WOOD * 0.5
	for f in [-0.5, 0.0, 0.5]:
		spots.append(Vector2(f * hw, wy))
		spots.append(Vector2(f * hw, -wy))
	for f in [0.25, 0.5, 0.75]:
		for sgn in [-1.0, 1.0]:
			spots.append(Vector2(wx, sgn * f * hl))
			spots.append(Vector2(-wx, sgn * f * hl))
	dm.instance_count = spots.size()
	for i in spots.size():
		dm.set_instance_transform(i, Transform3D(Basis(), to_world(spots[i], 0.0505)))
	dots.multimesh = dm
	dots.material_override = _flat(Color(0.93, 0.9, 0.82), 0.0)
	add_child(dots)
	# Head string (kitchen line) for ball in hand on the break.
	_kitchen = MeshInstance3D.new()
	var kq := QuadMesh.new()
	kq.orientation = PlaneMesh.FACE_Y
	kq.size = Vector2(hw * 2.0, 0.004)
	_kitchen.mesh = kq
	var km := _material(LINE_SHADER)
	km.set_shader_parameter("color", Color(1, 1, 1, 0.35))
	_kitchen.material_override = km
	_kitchen.position = to_world(Vector2(0.0, -hl * 0.5), 0.0008)
	_kitchen.visible = false
	add_child(_kitchen)


func _pocket_mouth(k: int) -> Vector2:
	if k < 4:
		var sx := -1.0 if k % 2 == 0 else 1.0
		var sy := -1.0 if k < 2 else 1.0
		return Vector2(sx * hw, sy * hl)
	return Vector2(-hw if k == 4 else hw, 0.0)


func _make_digits() -> void:
	_digits = SubViewport.new()
	_digits.size = Vector2i(512, 512)
	_digits.transparent_bg = true
	_digits.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_digits)
	for b in range(1, 16):
		var l := Label.new()
		l.text = str(b)
		l.add_theme_font_override("font", UiKit.font(900))
		l.add_theme_font_size_override("font_size", 86 if b < 10 else 74)
		l.add_theme_color_override("font_color", Color.BLACK)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2((b % 4) * 128, (b / 4) * 128)
		l.size = Vector2(128, 128)
		_digits.add_child(l)


func _make_balls() -> void:
	_ball_mat = _material(BALL_SHADER)
	var cols := PackedColorArray()
	for b in 16:
		var c: Color = BALL_COLORS[b if b <= 8 else b - 8]
		cols.append(c.srgb_to_linear())
	_ball_mat.set_shader_parameter("colors", cols)
	_ball_mat.set_shader_parameter("digits", _digits.get_texture())
	_ball_mat.set_shader_parameter("radius", radius)
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = sphere
	mm.instance_count = CueSim.N
	_balls = MultiMeshInstance3D.new()
	_balls.multimesh = mm
	_balls.material_override = _ball_mat
	var sq := QuadMesh.new()
	sq.size = Vector2(1, 1)
	sq.orientation = PlaneMesh.FACE_Y
	var smm := MultiMesh.new()
	smm.transform_format = MultiMesh.TRANSFORM_3D
	smm.use_colors = true
	smm.mesh = sq
	smm.instance_count = CueSim.N
	_shadows = MultiMeshInstance3D.new()
	_shadows.multimesh = smm
	_shadows.material_override = _material(SHADOW_SHADER)
	add_child(_shadows)
	add_child(_balls)


func _make_aim() -> void:
	_aim_line = _line_node(Color(1, 1, 1, 0.8), 0.03)
	_obj_ray = _line_node(Color(1, 1, 1, 0.9), 0.0)
	_cue_ray = _line_node(Color(0.75, 0.88, 1.0, 0.75), 0.02)
	_ghost = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(radius * 2.0, radius * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	_ghost.mesh = q
	_ghost.material_override = _material(RING_SHADER)
	add_child(_ghost)
	_cue = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0065
	cyl.bottom_radius = 0.014
	cyl.height = 1.0
	cyl.radial_segments = 12
	cyl.rings = 1
	_cue.mesh = cyl
	_cue.material_override = _flat(Color(0.86, 0.72, 0.5), 1.0)
	add_child(_cue)
	hide_aim()


func _line_node(col: Color, dash: float) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.orientation = PlaneMesh.FACE_Y
	n.mesh = q
	var m := _material(LINE_SHADER)
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("dash", dash)
	n.material_override = m
	add_child(n)
	return n


func _box(size: Vector3, centre: Vector2, along: Vector2, h: float, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	m.position = to_world(centre, h)
	m.rotation.y = atan2(along.y, along.x)
	add_child(m)


func _material(code: String) -> ShaderMaterial:
	var s := Shader.new()
	s.code = code
	var m := ShaderMaterial.new()
	m.shader = s
	return m


func _flat(col: Color, grain: float) -> ShaderMaterial:
	var m := _material(FLAT_SHADER)
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("grain", grain)
	return m
