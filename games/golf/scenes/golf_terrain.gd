class_name GolfTerrain
extends Node3D
## Draws a baked HoleData (render only). Chunked ArrayMeshes from the height grid at every
## `STEP`-th vertex (1 m) with the same triangle split as the physics grid; one terrain shader
## colours each cell from an R8 surface texture (what you see is what the ball feels), with mowing
## stripes on fairway and green. Decorative trees (MultiMesh) stand only out of bounds.
## Research: docs/research/Fairway Flick courses and maps.md (themes and Mobile-renderer budget).

const STEP := 2  # render every 2nd physics vertex (0.5 m grid -> 1 m mesh)
const CHUNK := 48  # render cells per chunk side

const SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D surf : filter_nearest;
uniform vec2 origin;
uniform vec2 extent;
uniform vec4 cols[9];
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 uv = (wpos.xz - origin) / extent;
	int s = int(texture(surf, uv).r * 255.0 + 0.5);
	vec3 c = cols[clamp(s, 0, 8)].rgb;
	if (s == 1 || s == 2) {
		c *= 0.93 + 0.1 * step(0.5, fract(wpos.z / 9.0));
	} else if (s == 5) {
		c *= 0.95 + 0.07 * step(0.5, fract((wpos.x + wpos.z) / 2.4));
	} else if (s == 3 || s == 0) {
		c *= 0.92 + 0.08 * fract(sin(dot(floor(wpos.xz * 1.5), vec2(12.9898, 78.233))) * 43758.5453);
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"""

## Surface colours (OUT, TEE, FAIRWAY, ROUGH, FRINGE, GREEN, SAND, WATER, PATH): a brightness ladder
## water < rough < fairway < green < sand, so surfaces read without relying on hue.
const COLS := [
	Color(0.2, 0.36, 0.16),
	Color(0.38, 0.64, 0.32),
	Color(0.32, 0.6, 0.26),
	Color(0.24, 0.47, 0.2),
	Color(0.34, 0.64, 0.3),
	Color(0.42, 0.74, 0.36),
	Color(0.9, 0.82, 0.6),
	Color(0.14, 0.38, 0.62),
	Color(0.62, 0.6, 0.55),
]

var hole: HoleData


func build(h: HoleData, seed_value := 1) -> void:
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
	var cols := PackedColorArray()
	for c in COLS:
		cols.append(c.srgb_to_linear())
	mat.set_shader_parameter("cols", cols)
	var rx := h.nx / STEP
	var rz := h.nz / STEP
	for cj in range(0, rz, CHUNK):
		for ci in range(0, rx, CHUNK):
			var mi := MeshInstance3D.new()
			mi.mesh = _chunk(ci, cj, mini(CHUNK, rx - ci), mini(CHUNK, rz - cj))
			mi.material_override = mat
			add_child(mi)
	_trees(seed_value)


func _vertex(i: int, j: int) -> Vector3:
	var pi := i * STEP
	var pj := j * STEP
	return Vector3(hole.x0 + pi * hole.cell, hole._h(pi, pj), hole.z0 + pj * hole.cell)


func _chunk(ci: int, cj: int, w: int, d: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	var step_m := hole.cell * STEP
	for j in d + 1:
		for i in w + 1:
			var gi := ci + i
			var gj := cj + j
			verts.append(_vertex(gi, gj))
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
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## Low-poly trees scattered (seeded) on out-of-bounds ground near the playing corridor.
func _trees(seed_value: int) -> void:
	var rng := Rng.make(seed_value)
	var spots: Array[Transform3D] = []
	var step_m := 7.0
	var z := hole.z0 + 4.0
	while z < hole.z0 + hole.nz * hole.cell - 4.0:
		var x := hole.x0 + 4.0
		while x < hole.x0 + hole.nx * hole.cell - 4.0:
			var px := x + rng.randf_range(-2.5, 2.5)
			var pz := z + rng.randf_range(-2.5, 2.5)
			if hole.surface_at(px, pz) == HoleData.Surface.OUT and _near_play(px, pz):
				var s := rng.randf_range(0.8, 1.35)
				var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(s, s, s))
				spots.append(Transform3D(b, Vector3(px, hole.height(px, pz), pz)))
			x += step_m
		z += step_m
	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 2.6
	crown.height = 7.0
	crown.radial_segments = 7
	crown.rings = 1
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.25
	trunk.bottom_radius = 0.35
	trunk.height = 2.0
	trunk.radial_segments = 5
	trunk.rings = 1
	_multi(crown, Color(0.1, 0.3, 0.13), spots, Vector3(0, 5.2, 0))
	_multi(trunk, Color(0.35, 0.24, 0.14), spots, Vector3(0, 1.0, 0))


func _near_play(x: float, z: float) -> bool:
	for k in 8:
		var a := TAU * k / 8.0
		if hole.surface_at(x + cos(a) * 14.0, z + sin(a) * 14.0) != HoleData.Surface.OUT:
			return true
	return false


func _multi(mesh: Mesh, col: Color, spots: Array[Transform3D], offset: Vector3) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = spots.size()
	for i in spots.size():
		var t := spots[i]
		mm.set_instance_transform(i, Transform3D(t.basis, t.origin + t.basis * offset))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 1.0
	mmi.material_override = m
	add_child(mmi)
