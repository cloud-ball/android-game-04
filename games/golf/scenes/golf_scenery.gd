class_name GolfScenery
extends Node3D
## Course dressing (render only): gradient sky, a mid skyline of wooded
## hills, a ring of distant hills, the world's landmark (meadow: a stone windmill-tower on a knoll),
## water surfaces over the spec's water stamps, and two tree species kept clear of play. The
## landmark stands straight ahead of the tee view (MiniFraming) so the portrait camera sees it.
## Original low-poly look; everything procedural and seeded (no asset files).
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

const LANDMARK_SCALE := 0.8  # ~14 m tall: fills the top third of the play view, not more
const GROUND_Y := MiniBaker.LAWN  # the terrain's apron level outside the baked grid

## Where the landmark's top half is, for the intro's establishing shot.
var landmark := Vector3.ZERO

var _blades: Node3D
var _theme: GolfTheme
var _hole: HoleData


## Dev switches for measuring on the phone: --gfx=noshadow,noglow,scale=0.75,aa=fxaa|smaa|msaa2
static func gfx_flags() -> Dictionary:
	var out := {}
	for part in str(Boot.options.get("gfx", "")).split(",", false):
		var kv := part.split("=")
		out[kv[0]] = kv[1] if kv.size() > 1 else true
	return out


func build(hole: HoleData, spec: Dictionary, seed_value := 1, theme: GolfTheme = null) -> void:
	_theme = theme if theme != null else GolfTheme.meadow()
	_hole = hole
	_environment()
	var mid := Vector3(
		hole.x0 + hole.nx * hole.cell * 0.5, 0.0, hole.z0 + hole.nz * hole.cell * 0.5
	)
	var view := MiniFraming.tee_view(spec, hole) if spec.has("map") else Vector2(0, -1)
	var spot := MiniFraming.landmark_spot(hole, view)
	_skyline(mid, seed_value)
	_hills(mid, seed_value)
	_water(hole, spec)
	_trees(hole, seed_value, spot)
	_windmill(Vector3(spot.x, GROUND_Y, spot.y), view)
	landmark = Vector3(spot.x, GROUND_Y + 11.0 * LANDMARK_SCALE, spot.y)


## Ground height for dressing: the baked lawn inside the grid, the ground disc outside it.
func _ground_y(x: float, z: float) -> float:
	return _hole.height(x, z) if _hole.contains(x, z) else GROUND_Y


func _process(delta: float) -> void:
	if _blades != null:
		_blades.rotate_object_local(Vector3.FORWARD, delta * 0.6)


func _environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = _theme.sky_top
	sky_mat.sky_horizon_color = _theme.sky_horizon
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
	# Filmic with a little extra exposure and saturation: a bright, sunny toy-diorama look (AgX
	# came out dull and dark on the carpet in screenshots).
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.18
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.04
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.82, 0.92)
	# ~6% at the course, ~25% on the mid skyline, most of the far ring: backdrop recedes.
	env.fog_density = 0.0028
	env.fog_sky_affect = 0.0
	# Glow only for real accents (emissive, above 1.0), on two mid levels (research: level 1
	# aliases since 4.6; a wide faint bloom cost GPU time and showed little).
	var flags := gfx_flags()
	env.glow_enabled = not flags.has("noglow")
	env.glow_intensity = 0.8
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	for lv in 7:
		env.set_glow_level(lv, 1.0 if lv == 2 or lv == 3 else 0.0)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(_theme.sun_pitch, _theme.sun_yaw, 0)
	sun.light_energy = 1.05
	sun.light_color = Color(1.0, 0.97, 0.9)
	# Real shadows near the camera (walls, trees, the ball): the biggest single step in richness.
	sun.shadow_enabled = not flags.has("noshadow")
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 28.0  # the play view sees ~15-25 m
	sun.shadow_blur = 1.5
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


## Mid skyline: a ring of rolling wooded hills 90-160 m out (one hill mesh plus one MultiMesh of
## crowns), hazed toward the sky by fog. It fills the top band of the portrait play view.
func _skyline(centre: Vector3, seed_value: int) -> void:
	var rng := Rng.make(seed_value * 17 + 3)
	var n := 72
	var r0 := 92.0
	var r1 := 128.0
	var r2 := 165.0
	var tops := PackedFloat32Array()
	for k in n:
		tops.append(6.0 + 4.0 * sin(k * 0.52) + 3.0 * sin(k * 1.37 + 0.7) + rng.randf_range(0, 3))
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var low := _theme.lawn.darkened(0.08)
	var high := _theme.lawn.lerp(_theme.bush, 0.35)
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var h0 := tops[k]
		var h1 := tops[(k + 1) % n]
		var i0 := centre + d0 * r0 + Vector3(0, GROUND_Y - 0.5, 0)
		var i1 := centre + d1 * r0 + Vector3(0, GROUND_Y - 0.5, 0)
		var c0 := centre + d0 * r1 + Vector3(0, GROUND_Y + h0, 0)
		var c1 := centre + d1 * r1 + Vector3(0, GROUND_Y + h1, 0)
		var o0 := centre + d0 * r2 + Vector3(0, GROUND_Y + h0 * 0.4, 0)
		var o1 := centre + d1 * r2 + Vector3(0, GROUND_Y + h1 * 0.4, 0)
		verts.append_array([i0, c0, c1, i0, c1, i1, c0, o0, o1, c0, o1, c1])
		cols.append_array([low, high, high, low, high, low, high, high, high, high, high, high])
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
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# Tree line along the inner slope and crest, sunk a little into the hill.
	var crowns: Array[Transform3D] = []
	for k in 220:
		var a := rng.randf_range(0.0, TAU)
		var f := rng.randf_range(0.35, 1.0)  # 0 = foot of the hill, 1 = crest
		var kk := int(a / TAU * n) % n
		var top := lerpf(tops[kk], tops[(kk + 1) % n], fmod(a / TAU * n, 1.0))
		var r := lerpf(r0, r1, f)
		var y := GROUND_Y - 0.5 + (top + 0.5) * f
		var s := rng.randf_range(3.0, 5.5)
		var p := centre + Vector3(cos(a) * r, y + s * 0.5, sin(a) * r)
		crowns.append(Transform3D(Basis.from_scale(Vector3(s, s * 1.1, s)), p))
	var crown := SphereMesh.new()
	crown.radius = 0.5
	crown.height = 1.0
	crown.radial_segments = 7
	crown.rings = 3
	_multi(crown, _theme.bush.lerp(_theme.lawn, 0.2), crowns, Vector3.ZERO, false)


## Two species on open lawn around play: tall conifers and round broadleaf trees. They keep
## MiniFraming.TREE_CLEAR from the course (never between the camera and the ball), off the
## landmark's knoll and out of the tee's line of sight to it.
func _trees(hole: HoleData, seed_value: int, spot: Vector2) -> void:
	var rng := Rng.make(seed_value)
	var cones: Array[Transform3D] = []
	var rounds: Array[Transform3D] = []
	var step_m := 6.0
	var reach := 24.0
	var tee := Vector2(hole.tee.x, hole.tee.z)
	var z := hole.z0 - reach
	while z < hole.z0 + hole.nz * hole.cell + reach:
		var x := hole.x0 - reach
		while x < hole.x0 + hole.nx * hole.cell + reach:
			var px := x + rng.randf_range(-2.5, 2.5)
			var pz := z + rng.randf_range(-2.5, 2.5)
			var s := rng.randf_range(0.75, 1.3)
			var yaw := rng.randf_range(0.0, TAU)
			var cone := rng.randf() < 0.5
			var q := Vector2(px, pz)
			# Clear of play, near enough to frame it, off the knoll, out of the tee's view of the
			# landmark, and not down in a pit.
			var ok := (
				MiniFraming.clear_of_course(hole, px, pz, MiniFraming.TREE_CLEAR)
				and not MiniFraming.clear_of_course(hole, px, pz, reach)
				and q.distance_to(spot) > 13.0
				and Geometry2D.get_closest_point_to_segment(q, tee, spot).distance_to(q) > 7.0
				and _shade_clear(hole, px, pz, s)
				and _ground_y(px, pz) > MiniBaker.LAWN - 0.1
			)
			if ok:
				var b := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
				var t := Transform3D(b, Vector3(px, _ground_y(px, pz), pz))
				if cone:
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


## The tree's shadow (crown about 5 m up at scale 1) stays off the course.
func _shade_clear(hole: HoleData, x: float, z: float, s: float) -> bool:
	var sp := MiniFraming.shadow_spot(x, z, 5.0 * s, _theme.sun_pitch, _theme.sun_yaw)
	return MiniFraming.clear_of_course(hole, sp.x, sp.y, 3.2 * s)


func _multi(
	mesh: Mesh, col: Color, spots: Array[Transform3D], offset: Vector3, shadow := true
) -> void:
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
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Meadow landmark (original design): a tapered stone windmill-tower on a grassy knoll, with a
## wooden balcony, door and window, a pointed roof and four lattice sails facing the tee. Parts
## that share a colour are merged, so the whole landmark is five draw calls.
func _windmill(at: Vector3, view: Vector2) -> void:
	var base := Node3D.new()
	base.position = at
	base.rotation.y = atan2(-view.x, -view.y)  # local +z faces the tee
	base.scale = Vector3.ONE * LANDMARK_SCALE
	add_child(base)
	var knoll := SphereMesh.new()
	knoll.radial_segments = 12
	knoll.rings = 6
	var k := MeshInstance3D.new()
	k.mesh = knoll
	k.scale = Vector3(26.0, 6.0, 26.0)
	k.position.y = -1.6
	k.material_override = _mat(_theme.lawn.lightened(0.04))
	base.add_child(k)
	var foot := 1.35  # knoll height at the tower
	var tower := CylinderMesh.new()
	tower.top_radius = 2.0
	tower.bottom_radius = 3.0
	tower.height = 12.0
	tower.radial_segments = 8
	tower.rings = 1
	_part(base, tower, _theme.landmark_wall, Vector3(0, foot + 6.0, 0))
	var roof := CylinderMesh.new()
	roof.top_radius = 0.0
	roof.bottom_radius = 2.7
	roof.height = 3.8
	roof.radial_segments = 8
	roof.rings = 1
	_part(base, roof, _theme.landmark_roof, Vector3(0, foot + 13.9, 0))
	# Dark wood: balcony ring, door, window, sail hub, and the lattice spars of the sails.
	var deck := CylinderMesh.new()
	deck.top_radius = 2.9
	deck.bottom_radius = 2.9
	deck.height = 0.3
	deck.radial_segments = 8
	deck.rings = 1
	var door := BoxMesh.new()
	door.size = Vector3(1.3, 2.2, 0.4)
	var window := BoxMesh.new()
	window.size = Vector3(0.9, 1.1, 0.4)
	var hub := SphereMesh.new()
	hub.radius = 0.55
	hub.height = 1.1
	hub.radial_segments = 8
	hub.rings = 4
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	wood.append_from(deck, 0, Transform3D(Basis(), Vector3(0, foot + 8.6, 0)))
	wood.append_from(door, 0, Transform3D(Basis(), Vector3(0, foot + 1.1, 2.85)))
	wood.append_from(window, 0, Transform3D(Basis(), Vector3(0, foot + 5.2, 2.5)))
	wood.append_from(hub, 0, Transform3D(Basis(), Vector3(0, foot + 11.0, 2.75)))
	var wood_mi := MeshInstance3D.new()
	wood_mi.mesh = wood.commit()
	wood_mi.material_override = _mat(_theme.landmark_wood)
	base.add_child(wood_mi)
	_blades = Node3D.new()
	_blades.position = Vector3(0, foot + 11.0, 2.95)
	base.add_child(_blades)
	var spar := BoxMesh.new()
	spar.size = Vector3(0.22, 7.6, 0.2)
	var rail := BoxMesh.new()
	rail.size = Vector3(0.09, 5.6, 0.12)
	var slat := BoxMesh.new()
	slat.size = Vector3(1.5, 0.09, 0.12)
	var cloth := BoxMesh.new()
	cloth.size = Vector3(1.4, 5.4, 0.05)
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sails := SurfaceTool.new()
	sails.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in 4:
		var turn := Basis(Vector3.FORWARD, blade * PI * 0.5)
		frame.append_from(spar, 0, Transform3D(turn, turn * Vector3(0, 3.8, 0.1)))
		frame.append_from(rail, 0, Transform3D(turn, turn * Vector3(1.55, 4.7, 0.12)))
		for s in 6:
			var y := 2.1 + s * 1.04
			frame.append_from(slat, 0, Transform3D(turn, turn * Vector3(0.85, y, 0.12)))
		sails.append_from(cloth, 0, Transform3D(turn, turn * Vector3(0.85, 4.7, 0.04)))
	var frame_mi := MeshInstance3D.new()
	frame_mi.mesh = frame.commit()
	frame_mi.material_override = _mat(_theme.landmark_wood)
	_blades.add_child(frame_mi)
	var sails_mi := MeshInstance3D.new()
	sails_mi.mesh = sails.commit()
	sails_mi.material_override = _mat(_theme.sail)
	_blades.add_child(sails_mi)


func _mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	return m


func _part(parent: Node3D, mesh: Mesh, col: Color, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(col)
	mi.position = at
	parent.add_child(mi)
