class_name SnakeBackdrop
extends Node3D
## Purely decorative space scene under the board: twinkling drifting stars, nebula clouds,
## shooting stars and rising sparks. Uses its own seeded RNG (never touches gameplay state).
## Everything is unshaded and additive, about 8 draw calls in total.

const STAR_COUNT := 320
const SHOOTER_POOL := 3
const NEBULAE := [
	[Vector3(-7, -17, -10), 44.0, Color(0.45, 0.18, 0.95), 0.32, Vector2(0.010, 0.004)],
	[Vector3(9, -19, 6), 40.0, Color(0.12, 0.35, 1.0), 0.28, Vector2(-0.006, 0.008)],
	[Vector3(2, -15, 18), 34.0, Color(0.85, 0.2, 0.65), 0.2, Vector2(0.004, -0.007)],
]

const STAR_SHADER := """
shader_type spatial;
render_mode unshaded;
varying float twinkle;
void vertex() {
	float id = float(INSTANCE_ID);
	float speed = 0.8 + fract(id * 0.371) * 2.6;
	twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(TIME * speed + id * 1.7));
}
void fragment() {
	ALBEDO = COLOR.rgb * twinkle;
}
"""

const NEBULA_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec3 color : source_color = vec3(0.5, 0.2, 1.0);
uniform float strength = 0.4;
uniform vec2 drift = vec2(0.01, 0.004);
void fragment() {
	float n1 = texture(noise_tex, UV * 1.2 + TIME * drift).r;
	float n2 = texture(noise_tex, UV * 2.6 - TIME * drift * 1.7 + 0.37).r;
	float mask = smoothstep(1.0, 0.15, length(UV - 0.5) * 2.0);
	float a = mask * pow(clamp(n1 * 0.75 + n2 * 0.5, 0.0, 1.5), 2.2) * strength;
	ALBEDO = color;
	ALPHA = clamp(a, 0.0, 1.0);
}
"""

const SHOOTER_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec3 color : source_color = vec3(0.85, 0.92, 1.0);
uniform float fade = 0.0;
void fragment() {
	float across = 1.0 - abs(UV.y - 0.5) * 2.0;
	float tail = pow(UV.x, 3.0) * across * across;
	float head = smoothstep(0.88, 1.0, UV.x) * pow(across, 0.5) * 1.5;
	ALBEDO = color * 3.0;
	ALPHA = clamp((tail + head) * fade, 0.0, 1.0);
}
"""

var _rng := RandomNumberGenerator.new()
var _stars: MultiMeshInstance3D
var _shooters: Array[MeshInstance3D] = []
## Per shooter: {age, life, velocity}; age >= life means idle.
var _shooter_state: Array[Dictionary] = []
var _next_shooter := 1.5
var _w := 12.0
var _h := 18.0


func setup(board_w: float, board_h: float, seed_value: int) -> void:
	_w = board_w
	_h = board_h
	_rng.seed = seed_value
	_add_stars()
	_add_nebulae()
	_add_shooters()
	_add_sparks()


## Called every frame by SnakeView.
func update(delta: float) -> void:
	_stars.rotation.y += delta * 0.012
	_next_shooter -= delta
	if _next_shooter <= 0.0:
		_launch_shooter()
		_next_shooter = _rng.randf_range(1.4, 3.6)
	for i in _shooters.size():
		var st := _shooter_state[i]
		if st.age >= st.life:
			continue
		st.age += delta
		var m := _shooters[i]
		m.position += st.velocity * delta
		var k: float = st.age / st.life
		var fade := minf(1.0, k * 6.0) * (1.0 - k)
		(m.material_override as ShaderMaterial).set_shader_parameter("fade", fade)
		m.visible = st.age < st.life


func _add_stars() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = STAR_COUNT
	var tints := [Color(0.75, 0.82, 1.0), Color(1.0, 0.85, 0.7), Color(0.75, 1.0, 0.95)]
	for i in STAR_COUNT:
		var p := Vector3(
			_rng.randf_range(-32, 32), _rng.randf_range(-26, -4), _rng.randf_range(-44, 30)
		)
		var s := _rng.randf_range(0.05, 0.15)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * s), p))
		var tint: Color = tints[_rng.randi_range(0, tints.size() - 1)]
		mm.set_instance_color(i, tint * _rng.randf_range(0.6, 1.5))
	_stars = MultiMeshInstance3D.new()
	_stars.multimesh = mm
	_stars.material_override = _material(STAR_SHADER)
	add_child(_stars)


func _add_nebulae() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = _rng.randi()
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	for n in NEBULAE:
		var quad := QuadMesh.new()
		quad.size = Vector2(n[1], n[1])
		var m := MeshInstance3D.new()
		m.mesh = quad
		m.rotation = Vector3(-PI / 2.0, _rng.randf_range(0.0, TAU), 0.0)
		m.position = n[0]
		var mat := _material(NEBULA_SHADER)
		mat.set_shader_parameter("noise_tex", tex)
		mat.set_shader_parameter("color", n[2])
		mat.set_shader_parameter("strength", n[3])
		mat.set_shader_parameter("drift", n[4])
		m.material_override = mat
		add_child(m)


func _add_shooters() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	for i in SHOOTER_POOL:
		var m := MeshInstance3D.new()
		m.mesh = quad
		m.material_override = _material(SHOOTER_SHADER)
		m.visible = false
		add_child(m)
		_shooters.append(m)
		_shooter_state.append({"age": 1.0, "life": 1.0, "velocity": Vector3.ZERO})


func _launch_shooter() -> void:
	for i in _shooters.size():
		var st := _shooter_state[i]
		if st.age < st.life:
			continue
		var heading := _rng.randf_range(-0.5, 0.5) + (PI if _rng.randf() < 0.5 else 0.0) - 0.45
		var dir := Vector3(cos(heading), 0.0, sin(heading))
		var speed := _rng.randf_range(16.0, 26.0)
		var length := _rng.randf_range(6.0, 10.0)
		var start := Vector3(
			_rng.randf_range(-12, 12), _rng.randf_range(-6, -2.5), _rng.randf_range(-22, 8)
		)
		start -= dir * speed * 0.5
		var m := _shooters[i]
		var lay_flat := Basis(Vector3.RIGHT, -PI / 2.0)
		var turn := Basis(Vector3.UP, -heading)
		m.transform = Transform3D(
			turn * lay_flat * Basis.from_scale(Vector3(length, 0.2, 1)), start
		)
		m.visible = true
		st.age = 0.0
		st.life = _rng.randf_range(1.0, 1.6)
		st.velocity = dir * speed
		return


func _add_sparks() -> void:
	var p := CPUParticles3D.new()
	p.amount = 48
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(_w * 0.5 + 5.0, 0.5, _h * 0.5 + 5.0)
	p.position = Vector3(0, -8.5, 0)
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.35
	p.initial_velocity_max = 0.8
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	dot.radial_segments = 6
	dot.rings = 3
	p.mesh = dot
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.45, 0.8, 1.0, 0.0))
	ramp.add_point(0.3, Color(0.55, 0.85, 1.0, 1.0))
	ramp.add_point(0.7, Color(0.8, 0.5, 1.0, 0.9))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.9, 0.4, 1.0, 0.0))
	p.color_ramp = ramp
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p.material_override = mat
	add_child(p)


static func _material(code: String) -> ShaderMaterial:
	var s := Shader.new()
	s.code = code
	var m := ShaderMaterial.new()
	m.shader = s
	return m
