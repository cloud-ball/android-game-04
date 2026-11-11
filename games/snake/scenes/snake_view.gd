class_name SnakeView
extends Node3D
## Draws a SnakeLogic on a floating neon grid. Never owns game state: it reads the logic each
## frame and interpolates segment positions between ticks (alpha 0..1). Everything is unshaded
## + glow, so there are no lights or shadows to pay for on low-end phones.

const PITCH_DEG := 78.0
const FOV_DEG := 26.0
const SNAKE_COLORS: Array[Color] = [Color(0.35, 1.0, 0.55), Color(1.0, 0.32, 0.86)]
const ORB_COLOR := Color(1.0, 0.8, 0.3)
const ORB_POOL := 4
## Screen bands kept free for the HUD (fractions of the screen height).
const TOP_BAND := 0.15
const BOTTOM_BAND := 0.035

const SEGMENT_SHADER := """
shader_type spatial;
render_mode unshaded;
uniform float energy = 1.0;
void fragment() {
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float lit = 0.5 + 0.4 * clamp(n.y, 0.0, 1.0) + 0.25 * clamp(n.z, 0.0, 1.0);
	ALBEDO = COLOR.rgb * lit * energy;
}
"""

const BOARD_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;
uniform vec2 cells = vec2(12.0, 18.0);
uniform vec3 base_color : source_color = vec3(0.02, 0.03, 0.09);
uniform vec3 line_color : source_color = vec3(0.22, 0.38, 1.0);
uniform float base_alpha = 0.72;
uniform float now = 0.0;
// Up to 4 ripples: (x, z, start_time, strength) and their tint.
uniform vec4 ripples[4];
uniform vec4 ripple_tint[4];
varying vec2 local_xz;
void vertex() {
	local_xz = VERTEX.xz;
}
void fragment() {
	vec2 g = local_xz + cells * 0.5;
	vec2 dist = abs(fract(g + 0.5) - 0.5);
	vec2 fw = fwidth(g);
	vec2 a = 1.0 - smoothstep(fw * 0.6, fw * 1.8, dist);
	float line = max(a.x, a.y);
	float vignette = 1.0 - 0.7 * length(local_xz / cells);
	vec3 col = mix(base_color * vignette, line_color * 1.25, line);
	float glow = 0.0;
	for (int i = 0; i < 4; i++) {
		vec4 r = ripples[i];
		float age = now - r.z;
		if (age < 0.0 || age > 1.6 || r.w <= 0.0) {
			continue;
		}
		float d = length(local_xz - r.xy);
		float ring = exp(-pow((d - age * 9.0) / 0.45, 2.0)) * (1.0 - age / 1.6) * r.w;
		col += ripple_tint[i].rgb * ring * (0.1 + 2.2 * line);
		glow += ring;
	}
	ALBEDO = col;
	ALPHA = clamp(mix(base_alpha, 1.0, line) + glow * 0.15, 0.0, 1.0);
}
"""

## Double chevron (») drawn in a flat quad; +X of the quad is "forward".
const ARROW_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled;
uniform vec3 color : source_color = vec3(0.4, 1.0, 0.6);
uniform float fade = 0.0;
float chevron(vec2 uv, float x0) {
	float d = (uv.x - x0) + abs(uv.y - 0.5) * 0.9;
	return smoothstep(0.0, 0.03, d) * (1.0 - smoothstep(0.2, 0.24, d)) * step(abs(uv.y - 0.5), 0.44);
}
void fragment() {
	float a = chevron(UV, 0.08) * 0.55 + chevron(UV, 0.42);
	ALBEDO = color * 3.2;
	ALPHA = clamp(a * fade, 0.0, 1.0);
}
"""

const FLAT_SHADER := """
shader_type spatial;
render_mode unshaded;
uniform vec3 color : source_color = vec3(1.0);
uniform float energy = 1.0;
void fragment() {
	ALBEDO = color * energy;
}
"""

var camera: Camera3D

var _w := 12
var _h := 18
var _snake_mm: Array[MultiMesh] = []
var _orbs: Array[MeshInstance3D] = []
var _bursts: Array[CPUParticles3D] = []
var _time := 0.0
var _shake := 0.0
var _cam_base := Transform3D()
var _dead_time: Array[float] = [-1.0, -1.0]
## Per snake: [eye_l, eye_r, pupil_l, pupil_r].
var _eyes: Array = []
var _sparkles: Array[CPUParticles3D] = []
var _next_sparkle := 0
var _backdrop: SnakeBackdrop
var _board_mat: ShaderMaterial
var _frame_mat: ShaderMaterial
var _ripples := PackedVector4Array([Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO])
var _ripple_tint := PackedVector4Array([Vector4.ONE, Vector4.ONE, Vector4.ONE, Vector4.ONE])
var _next_ripple := 0
var _arrows: Array[MeshInstance3D] = []
var _next_arrow := 0


func setup(width: int, height: int) -> void:
	_w = width
	_h = height
	_add_environment()
	_add_board()
	_backdrop = SnakeBackdrop.new()
	add_child(_backdrop)
	_backdrop.setup(float(_w), float(_h), 8)
	var seg_mat := ShaderMaterial.new()
	seg_mat.shader = _shader(SEGMENT_SHADER)
	seg_mat.set_shader_parameter("energy", 1.0)
	for i in SNAKE_COLORS.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = BoxMesh.new()
		# Instances 0..n-1 are segments; n.. are the connectors that join them into one body.
		mm.instance_count = 2 * _w * _h
		mm.visible_instance_count = 0
		var node := MultiMeshInstance3D.new()
		node.multimesh = mm
		node.material_override = seg_mat
		add_child(node)
		_snake_mm.append(mm)
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.27
	orb_mesh.height = 0.54
	orb_mesh.radial_segments = 14
	orb_mesh.rings = 7
	var orb_mat := _flat(ORB_COLOR, 1.9)
	for i in ORB_POOL:
		var o := MeshInstance3D.new()
		o.mesh = orb_mesh
		o.material_override = orb_mat
		o.visible = false
		add_child(o)
		_orbs.append(o)
	for i in SNAKE_COLORS.size():
		_bursts.append(_make_burst(SNAKE_COLORS[i]))
		_eyes.append(_make_eyes())
	for i in 3:
		_sparkles.append(_make_sparkle())
	camera = Camera3D.new()
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = FOV_DEG
	camera.far = 200.0
	add_child(camera)
	camera.make_current()
	fit_to_viewport()
	get_viewport().size_changed.connect(fit_to_viewport)


func fit_to_viewport() -> void:
	var vis := get_viewport().get_visible_rect().size
	var aspect := vis.x / maxf(1.0, vis.y)
	_cam_base = fit_camera(float(_w), float(_h), aspect, TOP_BAND, BOTTOM_BAND)
	camera.transform = _cam_base


func reset() -> void:
	_dead_time = [-1.0, -1.0]
	_shake = 0.0


## World position of a grid cell's centre on the board plane.
func cell_pos(c: Vector2i) -> Vector3:
	return Vector3(c.x - (_w - 1) * 0.5, 0.0, c.y - (_h - 1) * 0.5)


func render(logic: SnakeLogic, alpha: float, delta: float) -> void:
	_time += delta
	_backdrop.update(delta)
	_board_mat.set_shader_parameter("now", _time)
	_frame_mat.set_shader_parameter("energy", 1.45 + 0.3 * sin(_time * 1.9))
	for i in _snake_mm.size():
		if i < logic.snakes.size():
			_render_snake(i, logic.snakes[i], alpha)
		else:
			_snake_mm[i].visible_instance_count = 0
			for e in _eyes[i]:
				e.visible = false
	for j in _orbs.size():
		var o := _orbs[j]
		o.visible = j < logic.orbs.size()
		if o.visible:
			var bob := 0.36 + 0.08 * sin(_time * 3.2 + j * 1.7)
			o.position = cell_pos(logic.orbs[j]) + Vector3(0, bob, 0)
			o.scale = Vector3.ONE * (1.0 + 0.1 * sin(_time * 6.0 + j))
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.5)
		var off := Vector3(sin(_time * 53.0), cos(_time * 47.0), 0.0) * _shake * 0.25
		camera.transform = _cam_base.translated_local(off)
	else:
		camera.transform = _cam_base


func _render_snake(i: int, s: SnakeLogic.Serpent, alpha: float) -> void:
	var mm := _snake_mm[i]
	var n := s.body.size()
	var base := SNAKE_COLORS[i]
	var flash := 1.0
	if not s.alive:
		if _dead_time[i] < 0.0:
			_dead_time[i] = _time
		var t := _time - _dead_time[i]
		flash = 0.35 + (0.65 * absf(cos(t * 18.0)) if t < 0.8 else 0.0)
	var prev_p := Vector3.ZERO
	var head_p := Vector3.ZERO
	var neck_p := Vector3.ZERO
	for k in n:
		var to := s.body[k]
		var from: Vector2i = s.prev_body[k] if k < s.prev_body.size() else s.prev_body.back()
		from = _unwrap(from, to)
		var p := cell_pos(from).lerp(cell_pos(to), alpha)
		var f := float(k) / maxf(1.0, float(n - 1))
		var side := (0.9 if k == 0 else 0.78) * (1.0 - 0.3 * f)
		var tall := 0.6 if k == 0 else 0.46 * (1.0 - 0.25 * f)
		p.y = tall * 0.5
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(side, tall, side)), p))
		var bright := 1.45 if k == 0 else lerpf(1.1, 0.55, f)
		mm.set_instance_color(k, base * bright * flash)
		if k == 0:
			head_p = p
		elif k == 1:
			neck_p = p
		if k > 0:
			_connect(mm, n + k - 1, prev_p, p, side * 0.8, tall * 0.85, base * bright * 0.9 * flash)
		prev_p = p
	mm.visible_instance_count = n * 2 - 1
	var fwd := Vector3(SnakeLogic.STEP[s.dir].x, 0, SnakeLogic.STEP[s.dir].y)
	var neck_gap := head_p.distance_to(neck_p)
	if n > 1 and neck_gap > 0.05 and neck_gap < 1.5:
		fwd = Vector3(head_p.x - neck_p.x, 0, head_p.z - neck_p.z).normalized()
	_place_eyes(_eyes[i], head_p, fwd, s.alive)


## A move that crossed an edge (wrap mode) is drawn sliding in from just outside the
## opposite edge, instead of streaking across the whole board.
func _unwrap(from: Vector2i, to: Vector2i) -> Vector2i:
	var dx := to.x - from.x
	var dy := to.y - from.y
	if dx > 1:
		dx -= _w
	elif dx < -1:
		dx += _w
	if dy > 1:
		dy -= _h
	elif dy < -1:
		dy += _h
	return to - Vector2i(dx, dy)


## Box joining two neighbouring segments so the body reads as one solid snake.
func _connect(
	mm: MultiMesh, idx: int, a: Vector3, b: Vector3, width: float, tall: float, color: Color
) -> void:
	var d := b - a
	var length := Vector2(d.x, d.z).length()
	if length < 0.01 or length > 1.5:
		mm.set_instance_transform(idx, Transform3D(Basis.from_scale(Vector3.ZERO), a))
		return
	var along_x := absf(d.x) > absf(d.z)
	var size := Vector3(length, tall, width) if along_x else Vector3(width, tall, length)
	var mid := (a + b) * 0.5
	mid.y = tall * 0.5
	mm.set_instance_transform(idx, Transform3D(Basis.from_scale(size), mid))
	mm.set_instance_color(idx, color)


func _place_eyes(eyes: Array, head: Vector3, fwd: Vector3, alive: bool) -> void:
	var right := Vector3(-fwd.z, 0, fwd.x)
	for side in 2:
		var sgn := -1.0 if side == 0 else 1.0
		var eye: MeshInstance3D = eyes[side]
		var pupil: MeshInstance3D = eyes[side + 2]
		eye.visible = true
		eye.position = head + fwd * 0.18 + right * (0.2 * sgn) + Vector3(0, 0.3, 0)
		pupil.visible = alive
		pupil.position = eye.position + fwd * 0.07 + Vector3(0, 0.05, 0)


## Ring of light spreading across the grid from cell c.
func ripple(c: Vector2i, color: Color, strength: float) -> void:
	var p := cell_pos(c)
	_ripples[_next_ripple] = Vector4(p.x, p.z, _time, strength)
	_ripple_tint[_next_ripple] = Vector4(color.r, color.g, color.b, 1.0)
	_next_ripple = (_next_ripple + 1) % _ripples.size()
	_board_mat.set_shader_parameter("ripples", _ripples)
	_board_mat.set_shader_parameter("ripple_tint", _ripple_tint)


## Shows a glowing » on cell c pointing in direction d: where the player's snake is about to
## turn. It pops in, slides half a cell forward and fades (about 0.45 s).
func turn_hint(c: Vector2i, d: int) -> void:
	if _arrows.is_empty():
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		for i in 3:
			var m := MeshInstance3D.new()
			m.mesh = quad
			var mat := ShaderMaterial.new()
			mat.shader = _shader(ARROW_SHADER)
			mat.set_shader_parameter("color", SNAKE_COLORS[0].lightened(0.55))
			m.material_override = mat
			m.visible = false
			add_child(m)
			_arrows.append(m)
	var m := _arrows[_next_arrow]
	_next_arrow = (_next_arrow + 1) % _arrows.size()
	var step := SnakeLogic.STEP[d]
	var fwd := Vector3(step.x, 0, step.y)
	var heading := atan2(fwd.z, fwd.x)
	var lay_flat := Basis(Vector3.RIGHT, -PI / 2.0)
	var start := cell_pos(c) + Vector3(0, 0.06, 0) - fwd * 0.15
	m.transform = Transform3D(
		Basis(Vector3.UP, -heading) * lay_flat * Basis.from_scale(Vector3(1.3, 1.3, 1)), start
	)
	m.visible = true
	var mat := m.material_override as ShaderMaterial
	var tw := m.create_tween()
	tw.tween_method(func(f: float) -> void: mat.set_shader_parameter("fade", f), 0.0, 1.0, 0.07)
	tw.parallel().tween_property(m, "position", start + fwd * 0.5, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(f: float) -> void: mat.set_shader_parameter("fade", f), 1.0, 0.0, 0.3)
	tw.tween_callback(func() -> void: m.visible = false)


func eat_fx(c: Vector2i, who: int, text: String) -> void:
	ripple(c, SNAKE_COLORS[who].lerp(ORB_COLOR, 0.5), 0.9)
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font = UiKit.font(900)
	l.font_size = 80
	l.outline_size = 24
	l.pixel_size = 0.006
	l.modulate = SNAKE_COLORS[who].lightened(0.3)
	l.outline_modulate = Color(0, 0, 0, 0.6)
	l.position = cell_pos(c) + Vector3(0, 0.9, 0)
	add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 1.6, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func sparkle_fx(c: Vector2i) -> void:
	var p := _sparkles[_next_sparkle]
	_next_sparkle = (_next_sparkle + 1) % _sparkles.size()
	p.position = cell_pos(c) + Vector3(0, 0.4, 0)
	p.restart()
	p.emitting = true


func crash_fx(c: Vector2i, who: int) -> void:
	var clamped := Vector2i(clampi(c.x, 0, _w - 1), clampi(c.y, 0, _h - 1))
	var b := _bursts[who]
	b.position = cell_pos(clamped) + Vector3(0, 0.3, 0)
	b.restart()
	b.emitting = true
	_shake = 1.0
	ripple(clamped, SNAKE_COLORS[who], 1.8)


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.02, 0.05)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _add_board() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(_w, _h)
	var mat := ShaderMaterial.new()
	mat.shader = _shader(BOARD_SHADER)
	mat.set_shader_parameter("ripples", _ripples)
	mat.set_shader_parameter("ripple_tint", _ripple_tint)
	_board_mat = mat
	mat.set_shader_parameter("cells", Vector2(_w, _h))
	var board := MeshInstance3D.new()
	board.mesh = plane
	board.material_override = mat
	add_child(board)
	var frame_mat := _flat(Color(0.5, 0.65, 1.0), 1.6)
	_frame_mat = frame_mat
	var hw := _w * 0.5
	var hh := _h * 0.5
	var bars := [
		[Vector3(0, 0, -hh), Vector3(_w + 0.12, 0.1, 0.1)],
		[Vector3(0, 0, hh), Vector3(_w + 0.12, 0.1, 0.1)],
		[Vector3(-hw, 0, 0), Vector3(0.1, 0.1, _h + 0.12)],
		[Vector3(hw, 0, 0), Vector3(0.1, 0.1, _h + 0.12)],
	]
	for bar in bars:
		var box := BoxMesh.new()
		box.size = bar[1]
		var m := MeshInstance3D.new()
		m.mesh = box
		m.material_override = frame_mat
		m.position = bar[0]
		add_child(m)


func _make_burst(color: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 1.0
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = false
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.16
	p.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 6.5
	p.gravity = Vector3(0, -9.0, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	p.color = color * 1.5
	add_child(p)
	return p


func _make_eyes() -> Array:
	var white := SphereMesh.new()
	white.radius = 0.12
	white.height = 0.24
	white.radial_segments = 10
	white.rings = 5
	var dark := SphereMesh.new()
	dark.radius = 0.065
	dark.height = 0.13
	dark.radial_segments = 8
	dark.rings = 4
	var out: Array = []
	for k in 4:
		var m := MeshInstance3D.new()
		m.mesh = white if k < 2 else dark
		m.material_override = (
			_flat(Color.WHITE, 1.15) if k < 2 else _flat(Color(0.05, 0.05, 0.1), 1.0)
		)
		m.visible = false
		add_child(m)
		out.append(m)
	return out


func _make_sparkle() -> CPUParticles3D:
	var p := _make_burst(ORB_COLOR)
	p.amount = 18
	p.lifetime = 0.6
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	dot.radial_segments = 6
	dot.rings = 3
	p.mesh = dot
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, -3.0, 0)
	p.color = ORB_COLOR * 1.8
	return p


static func _shader(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


static func _flat(color: Color, energy: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(FLAT_SHADER)
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("energy", energy)
	return m


## Smallest camera distance (at a fixed pitch) that shows the whole board inside the band
## between the HUD at the top and the bottom margin, with the board centred in that band.
static func fit_camera(w: float, h: float, aspect: float, top: float, bottom: float) -> Transform3D:
	var tan_h := tan(deg_to_rad(FOV_DEG) * 0.5)
	var tan_v := tan_h / maxf(aspect, 0.01)
	var pitch := deg_to_rad(PITCH_DEG)
	var back := Vector3(0, sin(pitch), cos(pitch))
	var hw := w * 0.5 + 0.4
	var hh := h * 0.5 + 0.4
	var corners: Array[Vector3] = [
		Vector3(-hw, 0, -hh), Vector3(hw, 0, -hh), Vector3(-hw, 0, hh), Vector3(hw, 0, hh)
	]
	var y_top := 1.0 - 2.0 * top
	var y_bot := -1.0 + 2.0 * bottom
	var want := (y_top + y_bot) * 0.5
	var d := 6.0
	var t := Transform3D()
	while d < 120.0:
		var tz := 0.0
		for i in 12:
			t = Transform3D(Basis(), Vector3(0, 0, tz) + back * d)
			t = t.looking_at(Vector3(0, 0, tz), Vector3.UP)
			var r := _ndc_bounds(t, corners, tan_h, tan_v)
			tz += (want - (r.z + r.w) * 0.5) * d * 0.25
		var b := _ndc_bounds(t, corners, tan_h, tan_v)
		if b.x >= -0.985 and b.y <= 0.985 and b.z >= y_bot and b.w <= y_top:
			return t
		d += 0.25
	return t


## Vector4(min_x, max_x, min_y, max_y) of the corners in normalized device coordinates.
static func _ndc_bounds(t: Transform3D, pts: Array[Vector3], tan_h: float, tan_v: float) -> Vector4:
	var inv := t.affine_inverse()
	var r := Vector4(INF, -INF, INF, -INF)
	for p in pts:
		var q := inv * p
		var z := maxf(-q.z, 0.001)
		var x := q.x / (z * tan_h)
		var y := q.y / (z * tan_v)
		r = Vector4(minf(r.x, x), maxf(r.y, x), minf(r.z, y), maxf(r.w, y))
	return r
