class_name BlocksView
extends Node3D
## 3D crystal tower for Stack Drop. Reads a StackState every frame and draws it; never owns
## game state. Locked cells, the active shard and its ghost are three MultiMeshes.

const GEM_COLORS: Array[Color] = [
	Color(0.27, 0.52, 1.0),  # A long  - sapphire
	Color(1.0, 0.73, 0.26),  # B square - topaz
	Color(0.68, 0.42, 1.0),  # C tee   - amethyst
	Color(0.22, 0.86, 0.56),  # D skew  - emerald
	Color(0.96, 0.3, 0.42),  # E skew  - ruby
	Color(0.32, 0.86, 0.96),  # F hook  - aquamarine
	Color(1.0, 0.56, 0.76),  # G hook  - rose quartz
]
const GARBAGE_COLOR := Color(0.46, 0.43, 0.57)
const CUBE := 0.94
const PITCH_DEG := 7.0
const FOV_DEG := 30.0
## Screen bands left for the HUD (fractions of height) and the side panels (fraction of width).
const TOP_BAND := 0.085
const BOTTOM_BAND := 0.012
const SIDE_BAND := 0.012

const GEM_SHADER := """
shader_type spatial;
render_mode cull_back;
varying vec3 lp;
void vertex() {
	lp = VERTEX;
}
void fragment() {
	vec3 a = abs(lp) / 0.47;
	float mid = max(min(a.x, a.y), min(max(a.x, a.y), a.z));
	float edge = smoothstep(0.82, 0.97, mid);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = COLOR.rgb * (0.7 + 0.3 * fres);
	ROUGHNESS = 0.12;
	SPECULAR = 0.8;
	EMISSION = COLOR.rgb * (0.1 + 0.4 * fres) + COLOR.rgb * edge * (0.25 + 0.6 * COLOR.a);
}
"""

const GHOST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
varying vec3 lp;
void vertex() {
	lp = VERTEX;
}
void fragment() {
	vec3 a = abs(lp) / 0.47;
	float mid = max(min(a.x, a.y), min(max(a.x, a.y), a.z));
	float edge = smoothstep(0.8, 0.95, mid);
	ALBEDO = COLOR.rgb;
	ALPHA = 0.06 + 0.55 * edge;
}
"""

const GLASS_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec2 cells = vec2(9.0, 18.0);
uniform float fill = 0.05;
uniform float lines = 0.13;
void fragment() {
	vec2 g = UV * cells;
	vec2 d = abs(fract(g + 0.5) - 0.5);
	vec2 fw = fwidth(g);
	vec2 l = 1.0 - smoothstep(fw * 0.6, fw * 1.8, d);
	float line = max(l.x, l.y);
	vec3 tint = mix(vec3(0.62, 0.55, 0.95), vec3(0.45, 0.5, 0.95), UV.y);
	ALBEDO = tint;
	ALPHA = fill * (0.6 + 0.4 * UV.y) + lines * line;
}
"""

var camera: Camera3D

var _locked: MultiMesh
var _active: MultiMesh
var _ghost: MultiMesh
var _burst_pool: Array[CPUParticles3D] = []
var _next_burst := 0
var _flash_rows: Array[MeshInstance3D] = []
var _garbage_bar: MeshInstance3D
var _cam_base := Transform3D()
var _time := 0.0
var _shake := 0.0
var _active_visual := Vector2.ZERO  # smoothed (x, y) of the active shard's box
var _active_key := ""  # kind/rot/spawn identity, to snap instead of gliding on a new shard


func setup() -> void:
	_add_environment()
	_add_tower()
	var gem := ShaderMaterial.new()
	gem.shader = _shader(GEM_SHADER)
	var ghost := ShaderMaterial.new()
	ghost.shader = _shader(GHOST_SHADER)
	_locked = _multimesh(StackState.W * StackState.H, gem)
	_active = _multimesh(4, gem)
	_ghost = _multimesh(4, ghost)
	for i in 4:
		var flash := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(StackState.W, 1.0, 1.05)
		flash.mesh = box
		flash.material_override = _flat(Color(1, 1, 1), 2.5)
		flash.visible = false
		add_child(flash)
		_flash_rows.append(flash)
	for i in 4:
		_burst_pool.append(_make_burst())
	_garbage_bar = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.22, 1.0, 0.22)
	_garbage_bar.mesh = bar
	_garbage_bar.material_override = _flat(Color(1.0, 0.25, 0.3), 2.2)
	_garbage_bar.visible = false
	add_child(_garbage_bar)
	camera = Camera3D.new()
	camera.fov = FOV_DEG
	camera.far = 300.0
	add_child(camera)
	camera.make_current()
	fit_to_viewport()
	get_viewport().size_changed.connect(fit_to_viewport)


func fit_to_viewport() -> void:
	var vis := get_viewport().get_visible_rect().size
	_cam_base = fit_camera(vis.x / maxf(1.0, vis.y))
	camera.transform = _cam_base


## World centre of board cell (x, y); row 0 is the top hidden row.
static func cell_pos(x: float, y: float) -> Vector3:
	return Vector3(x - (StackState.W - 1) * 0.5, (StackState.H - 1 - y) + 0.5, 0.0)


func render(s: StackState, delta: float) -> void:
	_time += delta
	var n := 0
	for y in StackState.H:
		for x in StackState.W:
			var v := s.board[y * StackState.W + x]
			if v == 0:
				continue
			_locked.set_instance_transform(n, _cube(cell_pos(x, y), CUBE))
			_locked.set_instance_color(n, _color_for(v, 0.0))
			n += 1
	_locked.visible_instance_count = n
	_render_active(s, delta)
	var pending := s.pending_garbage
	_garbage_bar.visible = pending > 0
	if pending > 0:
		var h := float(mini(pending, StackState.H - StackState.HIDDEN))
		_garbage_bar.scale = Vector3(1, h, 1)
		_garbage_bar.position = Vector3(-StackState.W * 0.5 - 0.45, h * 0.5, 0.3)
	var sway := sin(_time * 0.3) * deg_to_rad(2.0)
	var t := Transform3D(Basis(Vector3.UP, sway), Vector3.ZERO) * _cam_base
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 3.0)
		t = t.translated_local(Vector3(sin(_time * 61.0), cos(_time * 53.0), 0) * _shake * 0.12)
	camera.transform = t


func _render_active(s: StackState, delta: float) -> void:
	if s.kind < 0 or s.over:
		_active.visible_instance_count = 0
		_ghost.visible_instance_count = 0
		return
	var key := "%d/%d/%d" % [s.kind, s.pieces, int(s.can_hold)]
	var target := Vector2(s.px, s.py)
	if key != _active_key or _active_visual.distance_to(target) > 3.0:
		_active_visual = target
		_active_key = key
	else:
		_active_visual = _active_visual.lerp(target, 1.0 - exp(-delta * 28.0))
	var cells := ShardData.cells(s.kind, s.rot)
	var gy := StackLogic.ghost_y(s)
	for i in 4:
		var c: Vector2i = cells[i]
		var p := cell_pos(_active_visual.x + c.x, _active_visual.y + c.y)
		_active.set_instance_transform(i, _cube(p, CUBE))
		_active.set_instance_color(i, _color_for(s.kind + 1, 1.0))
		_ghost.set_instance_transform(i, _cube(cell_pos(s.px + c.x, gy + c.y), CUBE))
		_ghost.set_instance_color(i, GEM_COLORS[s.kind].lightened(0.3))
	_active.visible_instance_count = 4
	_ghost.visible_instance_count = 4 if gy > s.py else 0


func _color_for(v: int, sparkle: float) -> Color:
	var c := GARBAGE_COLOR if v == StackState.GARBAGE else GEM_COLORS[v - 1]
	c.a = 0.35 + 0.65 * sparkle  # alpha drives the facet-edge glow in the gem shader
	return c


## Rows that were just cleared: flash them, then shatter into crystal fragments.
func clear_fx(rows: PackedInt32Array) -> void:
	for i in mini(rows.size(), _flash_rows.size()):
		var f := _flash_rows[i]
		f.position = cell_pos((StackState.W - 1) * 0.5, rows[i])
		f.visible = true
		f.scale = Vector3.ONE
		var tw := f.create_tween()
		tw.tween_property(f, "scale", Vector3(1.05, 0.2, 1.05), 0.18)
		tw.tween_callback(func() -> void: f.visible = false)
		var b := _burst_pool[_next_burst]
		_next_burst = (_next_burst + 1) % _burst_pool.size()
		b.position = f.position
		b.restart()
		b.emitting = true
	_shake = 0.35 + 0.15 * rows.size()


func hard_drop_fx() -> void:
	_shake = maxf(_shake, 0.25)


func _cube(p: Vector3, size: float) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3.ONE * size), p)


func _multimesh(count: int, mat: Material) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = count
	mm.visible_instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = mat
	add_child(node)
	return mm


func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.09, 0.06, 0.2)
	sky_mat.sky_horizon_color = Color(0.32, 0.2, 0.45)
	sky_mat.ground_horizon_color = Color(0.22, 0.15, 0.3)
	sky_mat.ground_bottom_color = Color(0.06, 0.05, 0.1)
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -32, 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.95, 1.0)
	add_child(sun)


func _add_tower() -> void:
	var w := float(StackState.W)
	var h := float(StackState.H - StackState.HIDDEN)
	var glass := ShaderMaterial.new()
	glass.shader = _shader(GLASS_SHADER)
	glass.set_shader_parameter("cells", Vector2(w, h))
	var back := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	back.mesh = quad
	back.material_override = glass
	back.position = Vector3(0, h * 0.5, -0.52)
	add_child(back)
	var side_mat := ShaderMaterial.new()
	side_mat.shader = _shader(GLASS_SHADER)
	side_mat.set_shader_parameter("cells", Vector2(1.0, h))
	side_mat.set_shader_parameter("fill", 0.04)
	side_mat.set_shader_parameter("lines", 0.0)
	for sx in [-1.0, 1.0]:
		var side := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(1.04, h)
		side.mesh = sq
		side.material_override = side_mat
		side.position = Vector3(sx * (w * 0.5 + 0.02), h * 0.5, 0)
		side.rotation.y = PI * 0.5
		add_child(side)
	var post_mat := _flat(Color(0.82, 0.8, 1.0), 1.25)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(
				Vector3(0.09, h + 0.5, 0.09),
				Vector3(sx * (w * 0.5 + 0.05), (h + 0.5) * 0.5, sz * 0.54),
				post_mat
			)
	for sz in [-1.0, 1.0]:
		_box(Vector3(w + 0.2, 0.07, 0.07), Vector3(0, h + 0.5, sz * 0.54), post_mat)
	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 7.2
	cyl.bottom_radius = 7.6
	cyl.height = 0.7
	cyl.radial_segments = 6
	cyl.rings = 1
	base.mesh = cyl
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.17, 0.14, 0.26)
	base_mat.roughness = 0.55
	base.material_override = base_mat
	base.position = Vector3(0, -0.36, 0)
	base.rotation.y = PI / 6.0
	add_child(base)
	var plate := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(w + 0.6, 0.12, 1.6)
	plate.mesh = pbox
	plate.material_override = _flat(Color(0.42, 0.38, 0.7), 0.55)
	plate.position = Vector3(0, -0.04, 0)
	add_child(plate)


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	m.position = pos
	add_child(m)


func _make_burst() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 46
	p.lifetime = 1.1
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(StackState.W * 0.5, 0.4, 0.4)
	var shard := PrismMesh.new()
	shard.size = Vector3(0.22, 0.3, 0.12)
	p.mesh = shard
	p.direction = Vector3(0, 1, 1)
	p.spread = 70.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 7.5
	p.gravity = Vector3(0, -14.0, 0)
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	ramp.colors = PackedColorArray(
		[GEM_COLORS[0], GEM_COLORS[2], GEM_COLORS[3], GEM_COLORS[1], GEM_COLORS[4], GEM_COLORS[5]]
	)
	p.color_initial_ramp = ramp
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.4, 0.5)
	mat.roughness = 0.2
	p.material_override = mat
	add_child(p)
	return p


static func _shader(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


static func _flat(color: Color, energy: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(
		(
			"shader_type spatial;\nrender_mode unshaded;\nuniform vec3 c : source_color;\n"
			+ "uniform float e = 1.0;\nvoid fragment() { ALBEDO = c * e; }\n"
		)
	)
	m.set_shader_parameter("c", color)
	m.set_shader_parameter("e", energy)
	return m


## Camera with a slight downward pitch, as close as possible while the whole tower (and its
## base) stays inside the screen area left free by the HUD bands.
static func fit_camera(aspect: float) -> Transform3D:
	var tan_v := tan(deg_to_rad(FOV_DEG) * 0.5)
	var tan_h := tan_v * aspect
	var w := StackState.W * 0.5 + 0.35
	var h := float(StackState.H - StackState.HIDDEN) + 0.6
	var pts: Array[Vector3] = []
	for x in [-w, w]:
		for y in [-0.15, h]:  # the hex base may run off the bottom edge
			for z in [-0.6, 0.6]:
				pts.append(Vector3(x, y, z))
	var pitch := deg_to_rad(PITCH_DEG)
	var dir := Vector3(0, sin(pitch), cos(pitch))
	var y_top := 1.0 - 2.0 * TOP_BAND
	var y_bot := -1.0 + 2.0 * BOTTOM_BAND
	var x_lim := 1.0 - 2.0 * SIDE_BAND
	var best := Transform3D()
	var d := 10.0
	while d < 200.0:
		var ty := h * 0.45
		for i in 10:
			var t := Transform3D(Basis(), Vector3(0, ty, 0) + dir * d).looking_at(
				Vector3(0, ty, 0), Vector3.UP
			)
			var r := _bounds(t, pts, tan_h, tan_v)
			ty -= ((y_top + y_bot) * 0.5 - (r.z + r.w) * 0.5) * d * tan_v * 0.5
			best = t
		var b := _bounds(best, pts, tan_h, tan_v)
		if b.x >= -x_lim and b.y <= x_lim and b.z >= y_bot and b.w <= y_top:
			return best
		d += 0.25
	return best


static func _bounds(t: Transform3D, pts: Array[Vector3], tan_h: float, tan_v: float) -> Vector4:
	var inv := t.affine_inverse()
	var r := Vector4(INF, -INF, INF, -INF)
	for p in pts:
		var q := inv * p
		var z := maxf(-q.z, 0.001)
		var x := q.x / (z * tan_h)
		var y := q.y / (z * tan_v)
		r = Vector4(minf(r.x, x), maxf(r.y, x), minf(r.z, y), maxf(r.w, y))
	return r
