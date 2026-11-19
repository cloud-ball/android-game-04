class_name AmbientLife
extends Node3D
## Render-only life around the course (the solver never sees any of it): butterflies looping over
## flower spots beside play, a small flock of birds circling high around the landmark, plus the
## shared wind shaders for foliage (KitBatch) and the flag. Paths are pure functions of time and a
## seed (`butterfly_at`, `bird_at`), updated in _process with value types only (no allocations).
## Reduce motion in Settings turns all of it off. Research: docs/research/Cup Dash mini golf
## visuals.md (plan row 6); plan: docs/plans/2026-11-15-cup-dash-ambient.md.

const FOLIAGE_SHADER := """
shader_type spatial;
render_mode diffuse_lambert_wrap;
uniform vec3 albedo : source_color;
uniform float amp = 0.05;  // metres at full weight
void vertex() {
	// Weight squared keeps bases planted; the gust travels across the world.
	float w = COLOR.r * COLOR.r;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * 1.4 + wp.x * 0.15 + wp.z * 0.11;
	float s = sin(t) * 0.7 + sin(t * 2.3 + 1.7) * 0.3;
	VERTEX.xz += vec2(0.8, 0.5) * s * amp * w;
}
void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = 0.9;
}
"""

const FLAG_SHADER := """
shader_type spatial;
render_mode diffuse_lambert_wrap, cull_disabled;
uniform vec3 albedo : source_color;
uniform float motion = 1.0;
void vertex() {
	// A ripple running away from the pole (the cloth's -x edge), growing toward the free end.
	float k = clamp((VERTEX.x + 0.3) / 0.6, 0.0, 1.0);
	VERTEX.z += sin(TIME * 7.0 - VERTEX.x * 9.0) * 0.05 * k * motion;
}
void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = 0.8;
}
"""

const WING_SHADER := """
shader_type spatial;
render_mode diffuse_lambert_wrap, cull_disabled, specular_disabled;
uniform float rate = 14.0;  // wing beats in radians per second
uniform float lift = 0.9;
void vertex() {
	float ph = float(INSTANCE_ID) * 1.7;
	VERTEX.y += abs(VERTEX.x) * sin(TIME * rate + ph) * lift;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
"""

const BUTTERFLIES := 5
const BIRDS := 4

static var _foliage: Shader

var _t := 0.0
var _flies: MultiMesh
var _birds: MultiMesh
var _fly_centres := PackedVector3Array()
var _bird_centre := Vector3.ZERO


## 1.0 normally, 0.0 when the player asked for reduced motion.
static func motion() -> float:
	return 0.0 if bool(SettingsService.get_value("reduce_motion")) else 1.0


static func foliage_shader() -> Shader:
	if _foliage == null:
		_foliage = Shader.new()
		_foliage.code = FOLIAGE_SHADER
	return _foliage


## A rippling flag cloth (render only): a subdivided box with the flag shader.
static func flag_cloth(size: Vector3, col: Color) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	box.subdivide_width = 8
	var sh := Shader.new()
	sh.code = FLAG_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("albedo", col)  # Godot converts to linear
	mat.set_shader_parameter("motion", motion())
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	return mi


## Butterfly k's position at time t around `centre`: a slow figure-of-eight loop up to ~1.2 m
## across, 0.35-0.95 m above the ground there, with a quick flutter bob.
static func butterfly_at(centre: Vector3, k: int, t: float) -> Vector3:
	var s := 0.45 + 0.07 * k
	var a := t * s + k * 2.1
	var x := sin(a) * 1.2
	var z := sin(a * 2.0 + 0.6) * 0.6
	var y := 0.65 + 0.22 * sin(a * 3.1) + 0.08 * sin(t * 9.0 + k)
	return centre + Vector3(x, y, z)


## Bird k's position at time t: one wide circle around `centre`, spaced around the ring, with a
## gentle rise and fall.
static func bird_at(centre: Vector3, k: int, t: float) -> Vector3:
	var a := t * 0.16 + k * 0.5
	var r := 24.0 + 3.0 * k
	return centre + Vector3(cos(a) * r, 2.0 * sin(t * 0.4 + k), sin(a) * r)


## centres: lawn spots for the butterflies (beside the play view); sky: the landmark's top.
func build(centres: PackedVector3Array, sky: Vector3, theme: GolfTheme) -> void:
	if motion() == 0.0:
		return
	_fly_centres = centres
	_bird_centre = sky + Vector3(0, 9.0, 0)
	var palette: Array = theme.flowers
	_flies = _flock(mini(BUTTERFLIES, centres.size()), 16.0, 0.9)
	for i in _flies.instance_count:
		# Instance colours reach COLOR raw (unlike shader parameters), so convert here.
		_flies.set_instance_color(i, (palette[i % palette.size()] as Color).srgb_to_linear())
	_birds = _flock(BIRDS, 6.0, 0.6)
	for i in _birds.instance_count:
		_birds.set_instance_color(i, Color(0.08, 0.09, 0.11))
	_process(0.0)


func _process(delta: float) -> void:
	if _flies == null:
		return
	_t += delta
	for i in _flies.instance_count:
		var p := butterfly_at(_fly_centres[i], i, _t)
		var ahead := butterfly_at(_fly_centres[i], i, _t + 0.05) - p
		_flies.set_instance_transform(i, _facing(p, ahead, 0.09))
	for i in _birds.instance_count:
		var p := bird_at(_bird_centre, i, _t)
		var ahead := bird_at(_bird_centre, i, _t + 0.2) - p
		_birds.set_instance_transform(i, _facing(p, ahead, 0.55))


func _facing(p: Vector3, ahead: Vector3, size: float) -> Transform3D:
	var flat := Vector3(ahead.x, 0.0, ahead.z)
	if flat.length_squared() < 1e-8:
		flat = Vector3.FORWARD
	var b := Basis.looking_at(flat, Vector3.UP).scaled(Vector3.ONE * size)
	return Transform3D(b, p)


## One MultiMesh of two-wing critters (the wings flap in WING_SHADER).
func _flock(count: int, rate: float, lift: float) -> MultiMesh:
	var wing := PackedVector3Array(
		[
			Vector3(-1, 0, -0.5),
			Vector3(0, 0, -0.3),
			Vector3(0, 0, 0.4),
			Vector3(-1, 0, -0.5),
			Vector3(0, 0, 0.4),
			Vector3(-0.8, 0, 0.5),
			Vector3(1, 0, -0.5),
			Vector3(0, 0, 0.4),
			Vector3(0, 0, -0.3),
			Vector3(1, 0, -0.5),
			Vector3(0.8, 0, 0.5),
			Vector3(0, 0, 0.4),
		]
	)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = wing
	var up := PackedVector3Array()
	up.resize(wing.size())
	up.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = up
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var sh := Shader.new()
	sh.code = WING_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("rate", rate)
	mat.set_shader_parameter("lift", lift)
	mesh.surface_set_material(0, mat)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 60.0  # instances move far from the (empty) mesh bounds
	add_child(mmi)
	return mm
