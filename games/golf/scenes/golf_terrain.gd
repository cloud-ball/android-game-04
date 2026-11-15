class_name GolfTerrain
extends Node3D
## Draws a baked HoleData (render only). Chunked ArrayMeshes from the height grid at every
## `STEP`-th vertex (1 m) with the same triangle split as the physics grid; one terrain shader
## colours each cell from an R8 surface texture (what you see is what the ball feels), with mowing
## stripes on fairway and green. Trees and the rest of the dressing live in GolfScenery.
## Research: docs/research/Fairway Flick courses and maps.md (themes and Mobile-renderer budget).

const STEP := 2  # render every 2nd physics vertex (0.5 m grid -> 1 m mesh)
const CHUNK := 48  # render cells per chunk side

const SHADER := """
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;
uniform sampler2D surf : filter_nearest;
uniform vec2 origin;
uniform vec2 extent;
uniform vec4 cols[9];
varying vec3 wpos;
varying float ao;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash(i), hash(i + vec2(1, 0)), f.x);
	float b = mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x);
	return mix(a, b, f.y);
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ao = COLOR.r;
}
void fragment() {
	vec2 uv = (wpos.xz - origin) / extent;
	int s = int(texture(surf, uv).r * 255.0 + 0.5);
	vec3 c = cols[clamp(s, 0, 8)].rgb;
	float rough = 1.0;
	float rim = 0.0;
	if (s == 5) {
		rim = 0.25;  // fibre sheen at grazing angles
		// Carpet: fine fibre noise, soft brushed bands.
		c *= 0.9 + 0.12 * vnoise(wpos.xz * 22.0) + 0.05 * step(0.5, fract((wpos.x + wpos.z) / 1.6));
		rough = 0.85;
	} else if (s == 1 || s == 2) {
		c *= 0.93 + 0.1 * step(0.5, fract(wpos.z / 9.0));
	} else if (s == 6) {
		c *= 0.88 + 0.16 * hash(floor(wpos.xz * 40.0)) + 0.06 * vnoise(wpos.xz * 3.0);
	} else if (s == 3 || s == 0) {
		// Grass: patchy tones at two scales.
		c *= 0.8 + 0.2 * vnoise(wpos.xz * 0.35) + 0.12 * vnoise(wpos.xz * 4.0);
	}
	ALBEDO = c * ao;
	ROUGHNESS = rough;
	RIM = rim;
	RIM_TINT = 0.5;
}
"""

## Surface colours (OUT, TEE, FAIRWAY, ROUGH, FRINGE, GREEN, SAND, WATER, PATH): a brightness ladder
## water < rough < fairway < green < sand, so surfaces read without relying on hue.
const COLS := [
	Color(0.3, 0.5, 0.2),
	Color(0.38, 0.64, 0.32),
	Color(0.32, 0.6, 0.26),
	Color(0.24, 0.47, 0.2),
	Color(0.34, 0.64, 0.3),
	Color(0.24, 0.66, 0.3),
	Color(0.93, 0.84, 0.62),
	Color(0.14, 0.38, 0.62),
	Color(0.62, 0.6, 0.55),
]

var hole: HoleData


## theme: optional GolfTheme; its lawn / carpet / sand / water replace the default colours.
func build(h: HoleData, theme: GolfTheme = null) -> void:
	hole = h
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	var img := Image.create(h.nx, h.nz, false, Image.FORMAT_R8)
	for j in h.nz:
		for i in h.nx:
			img.set_pixel(i, j, Color8(h.surface[j * h.nx + i], 0, 0))
	mat.set_shader_parameter("surf", ImageTexture.create_from_image(img))
	mat.set_shader_parameter("origin", Vector2(h.x0, h.z0))
	mat.set_shader_parameter("extent", Vector2(h.nx * h.cell, h.nz * h.cell))
	var palette: Array = COLS.duplicate()
	if theme != null:
		palette[HoleData.Surface.OUT] = theme.lawn
		palette[HoleData.Surface.ROUGH] = theme.lawn
		palette[HoleData.Surface.GREEN] = theme.carpet
		palette[HoleData.Surface.SAND] = theme.sand
		palette[HoleData.Surface.WATER] = theme.water
	var cols := PackedColorArray()
	for c in palette:
		cols.append((c as Color).srgb_to_linear())
	mat.set_shader_parameter("cols", cols)
	var rx := h.nx / STEP
	var rz := h.nz / STEP
	for cj in range(0, rz, CHUNK):
		for ci in range(0, rx, CHUNK):
			var mi := MeshInstance3D.new()
			mi.mesh = _chunk(ci, cj, mini(CHUNK, rx - ci), mini(CHUNK, rz - cj))
			mi.material_override = mat
			add_child(mi)


func _vertex(i: int, j: int) -> Vector3:
	var pi := i * STEP
	var pj := j * STEP
	return Vector3(hole.x0 + pi * hole.cell, hole._h(pi, pj), hole.z0 + pj * hole.cell)


## Soft shading where the ground meets a wall rail (0.6 at the rail, 1.0 from 0.45 m out).
func _ao(p: Vector3) -> float:
	var w := hole.walls
	if w.is_empty():
		return 1.0
	var best := 1e9
	for o in range(0, w.size(), 4):
		var ax := w[o]
		var az := w[o + 1]
		var dx := w[o + 2] - ax
		var dz := w[o + 3] - az
		var t := clampf(((p.x - ax) * dx + (p.z - az) * dz) / (dx * dx + dz * dz), 0.0, 1.0)
		var qx := ax + dx * t - p.x
		var qz := az + dz * t - p.z
		best = minf(best, qx * qx + qz * qz)
	var d := sqrt(best) - hole.wall_half
	return 0.6 + 0.4 * clampf(d / 0.45, 0.0, 1.0)


func _chunk(ci: int, cj: int, w: int, d: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var step_m := hole.cell * STEP
	for j in d + 1:
		for i in w + 1:
			var gi := ci + i
			var gj := cj + j
			var v := _vertex(gi, gj)
			verts.append(v)
			var a := _ao(v)
			cols.append(Color(a, a, a))
			var hx := _vertex(gi + 1, gj).y - _vertex(gi - 1, gj).y
			var hz := _vertex(gi, gj + 1).y - _vertex(gi, gj - 1).y
			norms.append(Vector3(-hx, 2.0 * step_m, -hz).normalized())
	for j in d:
		for i in w:
			var a := j * (w + 1) + i
			var b := a + 1
			var c := a + (w + 1)
			var e := c + 1
			# Same split as the physics grid: (i, j) -> (i+1, j+1); wound to face up (Godot fronts
			# are clockwise seen from the front).
			idx.append_array([a, b, e, a, e, c])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m
