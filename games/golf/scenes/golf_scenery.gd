class_name GolfScenery
extends Node3D
## Course dressing (render only): gradient sky, a ring of distant hills, a landmark (Meadow Run: a
## windmill-style tower), water surfaces over the spec's water stamps, and two tree species near
## the edges of play. Original low-poly look; everything procedural and seeded (no asset files).
## Research: docs/research/Fairway Flick courses and maps.md ("Themes are physics presets plus a
## fifteen-mesh visual kit").

const WATER_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_disabled;
uniform vec3 deep : source_color = vec3(0.08, 0.27, 0.42);
uniform vec3 shallow : source_color = vec3(0.2, 0.5, 0.62);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float t = TIME * 0.6;
	float ripple = sin(wpos.x * 1.7 + t) * sin(wpos.z * 1.3 - t * 0.8) * 0.5 + 0.5;
	ALBEDO = mix(deep, shallow, smoothstep(0.55, 1.0, r)) + vec3(0.06) * ripple;
	ROUGHNESS = 0.15;
	METALLIC = 0.0;
	ALPHA = 0.92;
}
"""

var _blades: Node3D


func build(hole: HoleData, spec: Dictionary, seed_value := 1) -> void:
	_environment()
	var mid := Vector3(
		hole.x0 + hole.nx * hole.cell * 0.5, 0.0, hole.z0 + hole.nz * hole.cell * 0.5
	)
	_hills(mid, seed_value)
	_water(hole, spec)
	_trees(hole, seed_value)
	var g: Dictionary = spec.green
	var far := Vector3(float(g.x), 0.0, float(g.z))
	var away := (far - Vector3(hole.tee.x, 0.0, hole.tee.z)).normalized()
	_windmill(far + away * 70.0 + Vector3(-away.z, 0.0, away.x) * 35.0, hole)


func _process(delta: float) -> void:
	if _blades != null:
		_blades.rotate_object_local(Vector3.FORWARD, delta * 0.6)


func _environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.56, 0.86)
	sky_mat.sky_horizon_color = Color(0.74, 0.86, 0.95)
	sky_mat.ground_bottom_color = Color(0.2, 0.32, 0.18)
	sky_mat.ground_horizon_color = Color(0.62, 0.74, 0.7)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.82, 0.92)
	env.fog_density = 0.0009
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.05
	sun.light_color = Color(1.0, 0.97, 0.9)
	add_child(sun)


## A low ring of rolling hills ~700 m out, fading into the fog (gives every view a skyline).
func _hills(centre: Vector3, seed_value: int) -> void:
	var rng := Rng.make(seed_value * 31 + 7)
	var n := 96
	var r_in := 620.0
	var r_out := 760.0
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var heights := PackedFloat32Array()
	for k in n:
		heights.append(
			25.0 + 20.0 * sin(k * 0.37) + 12.0 * sin(k * 0.91 + 1.3) + rng.randf_range(0.0, 10.0)
		)
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var h0 := heights[k]
		var h1 := heights[(k + 1) % n]
		var p0 := centre + Vector3(cos(a0) * r_in, -2.0, sin(a0) * r_in)
		var p1 := centre + Vector3(cos(a1) * r_in, -2.0, sin(a1) * r_in)
		var q0 := centre + Vector3(cos(a0) * r_out, h0, sin(a0) * r_out)
		var q1 := centre + Vector3(cos(a1) * r_out, h1, sin(a1) * r_out)
		verts.append_array([p0, q0, q1, p0, q1, p1])
		var c := Color(0.27, 0.42, 0.3)
		cols.append_array([c, c.lightened(0.15), c.lightened(0.15), c, c.lightened(0.15), c])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)


## Flat water surfaces over each water stamp, at the surrounding ground level.
func _water(hole: HoleData, spec: Dictionary) -> void:
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WATER_SHADER
	mat.shader = sh
	for st in spec.get("stamps", []):
		if st.type != "water":
			continue
		var rx := float(st.rx)
		var rz := float(st.rz)
		var ax: Array = st.get("axis", [1.0, 0.0])
		var u := Vector2(ax[0], ax[1]).normalized()
		var level := INF
		for k in 16:  # rim height: lowest ground on the edge
			var a := TAU * k / 16.0
			var local := Vector2(cos(a) * rx, sin(a) * rz)
			var p := Vector2(st.x, st.z) + u * local.x + Vector2(-u.y, u.x) * local.y
			level = minf(level, hole.height(p.x, p.y))
		var disc := CylinderMesh.new()
		disc.top_radius = 1.0
		disc.bottom_radius = 1.0
		disc.height = 0.02
		disc.radial_segments = 40
		var mi := MeshInstance3D.new()
		mi.mesh = disc
		mi.material_override = mat
		mi.position = Vector3(st.x, level - 0.12, st.z)
		mi.basis = (Basis(Vector3.UP, -atan2(u.y, u.x)).scaled(Vector3(rx * 1.02, 1.0, rz * 1.02)))
		add_child(mi)


## Two species on out-of-bounds ground near play: tall conifers and round broadleaf trees.
func _trees(hole: HoleData, seed_value: int) -> void:
	var rng := Rng.make(seed_value)
	var cones: Array[Transform3D] = []
	var rounds: Array[Transform3D] = []
	var step_m := 6.5
	var z := hole.z0 + 3.0
	while z < hole.z0 + hole.nz * hole.cell - 3.0:
		var x := hole.x0 + 3.0
		while x < hole.x0 + hole.nx * hole.cell - 3.0:
			var px := x + rng.randf_range(-2.5, 2.5)
			var pz := z + rng.randf_range(-2.5, 2.5)
			if hole.surface_at(px, pz) == HoleData.Surface.OUT and _edge(hole, px, pz):
				var s := rng.randf_range(0.75, 1.3)
				var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(s, s, s))
				var t := Transform3D(b, Vector3(px, hole.height(px, pz), pz))
				if rng.randf() < 0.55:
					cones.append(t)
				else:
					rounds.append(t)
			x += step_m
		z += step_m
	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 2.4
	crown.height = 6.5
	crown.radial_segments = 7
	crown.rings = 1
	var ball := SphereMesh.new()
	ball.radius = 2.6
	ball.height = 4.6
	ball.radial_segments = 8
	ball.rings = 4
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.32
	trunk.height = 2.4
	trunk.radial_segments = 5
	trunk.rings = 1
	_multi(crown, Color(0.12, 0.33, 0.16), cones, Vector3(0, 5.4, 0))
	_multi(ball, Color(0.24, 0.45, 0.17), rounds, Vector3(0, 4.4, 0))
	var all: Array[Transform3D] = []
	all.append_array(cones)
	all.append_array(rounds)
	_multi(trunk, Color(0.36, 0.25, 0.15), all, Vector3(0, 1.2, 0))


func _edge(hole: HoleData, x: float, z: float) -> bool:
	for k in 8:
		var a := TAU * k / 8.0
		if hole.surface_at(x + cos(a) * 16.0, z + sin(a) * 16.0) != HoleData.Surface.OUT:
			return true
	return false


func _multi(mesh: Mesh, col: Color, spots: Array[Transform3D], offset: Vector3) -> void:
	if spots.is_empty():
		return
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


## Meadow Run's landmark: a white tower with a dark cap and four turning sails.
func _windmill(at: Vector3, hole: HoleData) -> void:
	var base := Node3D.new()
	base.position = Vector3(at.x, hole.height(at.x, at.z) - 0.5, at.z)
	add_child(base)
	var body := CylinderMesh.new()
	body.top_radius = 2.4
	body.bottom_radius = 3.6
	body.height = 15.0
	body.radial_segments = 10
	_part(base, body, Color(0.93, 0.9, 0.84), Vector3(0, 7.5, 0))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.0
	cap.bottom_radius = 3.0
	cap.height = 4.0
	cap.radial_segments = 10
	_part(base, cap, Color(0.35, 0.2, 0.16), Vector3(0, 17.0, 0))
	_blades = Node3D.new()
	_blades.position = Vector3(0, 14.5, 2.9)
	base.add_child(_blades)
	for k in 4:
		var arm := Node3D.new()
		arm.rotation.z = k * PI * 0.5
		_blades.add_child(arm)
		var sail := BoxMesh.new()
		sail.size = Vector3(1.6, 8.5, 0.15)
		_part(arm, sail, Color(0.88, 0.84, 0.76), Vector3(0.6, 4.6, 0))


func _part(parent: Node3D, mesh: Mesh, col: Color, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
