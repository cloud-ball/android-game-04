class_name GolfScenery
extends Node3D
## Course dressing (render only): gradient sky, a mid skyline of wooded hills, a ring of distant
## hills, the world's landmark (meadow: a stone windmill-tower on a knoll), water surfaces over the
## spec's water stamps, CC0 kit trees kept clear of play, a park fence and a few small scenes beside
## the play view (KitBatch, recoloured by GolfTheme). The landmark stands straight ahead of the tee
## view (MiniFraming) so the portrait camera sees it. Original low-poly look; seeded.
## Research: docs/research/Fairway Flick courses and maps.md ("Themes are physics presets plus a
## fifteen-mesh visual kit").

const WATER_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_disabled;
uniform vec3 deep : source_color = vec3(0.08, 0.27, 0.42);
uniform vec3 shallow : source_color = vec3(0.2, 0.5, 0.62);
uniform float glow = 0.0;  // lava: emissive, slow churn, opaque
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float t = TIME * 0.6;
	float ripple = sin(wpos.x * 1.7 + t) * sin(wpos.z * 1.3 - t * 0.8) * 0.5 + 0.5;
	vec3 col = mix(deep, shallow, smoothstep(0.55, 1.0, r)) + vec3(0.06) * ripple;
	ALBEDO = col;
	EMISSION = col * glow * (0.7 + 0.6 * ripple);
	ROUGHNESS = mix(0.15, 0.85, step(0.5, glow));
	METALLIC = 0.0;
	ALPHA = mix(0.92, 1.0, step(0.5, glow));
}
"""

const LANDMARK_SCALE := 0.8  # ~14 m tall: fills the top third of the play view, not more
const GROUND_Y := MiniBaker.LAWN  # the terrain's apron level outside the baked grid

## Where the landmark's top half is, for the intro's establishing shot.
var landmark := Vector3.ZERO

var _spin: Dictionary = {}  # the landmark part that turns (GolfLandmarks.build)
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
	_fence(hole, spot)
	_vignettes(hole, seed_value, spot)
	_life(hole, seed_value)
	var at := Vector3(spot.x, GROUND_Y, spot.y)
	_spin = GolfLandmarks.build(_theme.landmark, self, at, view, LANDMARK_SCALE, _theme)
	landmark = Vector3(spot.x, GROUND_Y + 11.0 * LANDMARK_SCALE, spot.y)


## Ground height for dressing: the baked lawn inside the grid, the ground disc outside it.
func _ground_y(x: float, z: float) -> float:
	return _hole.height(x, z) if _hole.contains(x, z) else GROUND_Y


func _process(delta: float) -> void:
	if not _spin.is_empty():
		_spin.spin.rotate_object_local(_spin.axis, delta * float(_spin.speed))


func _environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = _theme.sky_top
	sky_mat.sky_horizon_color = _theme.sky_horizon
	sky_mat.ground_bottom_color = _theme.ground_bottom
	sky_mat.ground_horizon_color = _theme.ground_horizon
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	# Filmic with a touch of exposure and saturation: a bright, sunny toy-diorama look. (Exposure
	# was 1.18 while the terrain colours were wrongly converted to linear twice - see GolfTerrain.)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.04
	env.fog_enabled = true
	env.fog_light_color = _theme.fog_color
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
	sun.light_energy = _theme.sun_energy
	sun.light_color = _theme.sun_color
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
		var c := _theme.hills
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
	if _theme.lava:
		mat.set_shader_parameter("deep", _theme.water)
		mat.set_shader_parameter("shallow", _theme.glow)
		mat.set_shader_parameter("glow", 1.4)
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
	if _theme.skyline_trees:
		_multi(crown, _theme.bush.lerp(_theme.lawn, 0.2), crowns, Vector3.ZERO, false)


## Kit trees (TREES) on open lawn around play. They keep MiniFraming.TREE_CLEAR from the course
## (never between the camera and the ball), off the landmark's knoll, out of the tee's line of
## sight to it, and never where their shadow would fall on the course.
func _trees(hole: HoleData, seed_value: int, spot: Vector2) -> void:
	var rng := Rng.make(seed_value)
	var batch := KitBatch.new()
	var step_m := 6.0
	var reach := 24.0
	var tee := Vector2(hole.tee.x, hole.tee.z)
	var z := hole.z0 - reach
	while z < hole.z0 + hole.nz * hole.cell + reach:
		var x := hole.x0 - reach
		while x < hole.x0 + hole.nx * hole.cell + reach:
			var px := x + rng.randf_range(-2.5, 2.5)
			var pz := z + rng.randf_range(-2.5, 2.5)
			var kind: Array = _theme.trees[rng.randi_range(0, _theme.trees.size() - 1)]
			var tall := rng.randf_range(kind[1], kind[2])
			var yaw := rng.randf_range(0.0, TAU)
			var q := Vector2(px, pz)
			# Clear of play, near enough to frame it, off the knoll, out of the tee's view of the
			# landmark, its shadow off the course, and not down in a pit.
			var ok := (
				MiniFraming.clear_of_course(hole, px, pz, MiniFraming.TREE_CLEAR)
				and not MiniFraming.clear_of_course(hole, px, pz, reach)
				and q.distance_to(spot) > 13.0
				and Geometry2D.get_closest_point_to_segment(q, tee, spot).distance_to(q) > 7.0
				and _shade_clear(hole, px, pz, tall)
				and _ground_y(px, pz) > MiniBaker.LAWN - 0.1
			)
			if ok:
				var sc := tall / KitBatch.height(kind[0])
				var b := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * sc)
				batch.add(kind[0], Transform3D(b, Vector3(px, _ground_y(px, pz), pz)))
			x += step_m
		z += step_m
	batch.build(self, _theme)


## The crown's shadow (about two thirds up the tree, crown ~0.35 x height wide) stays off the
## course.
func _shade_clear(hole: HoleData, x: float, z: float, tall: float) -> bool:
	var sp := MiniFraming.shadow_spot(x, z, tall * 0.65, _theme.sun_pitch, _theme.sun_yaw)
	return MiniFraming.clear_of_course(hole, sp.x, sp.y, tall * 0.35)


## A fenced park: low kit fence panels along the edge of the baked lawn, skipped where they would
## cross the tee's view of the landmark, touch the course, or hang over a pit.
func _fence(hole: HoleData, spot: Vector2) -> void:
	var batch := KitBatch.new()
	var inset := 1.5
	var x0 := hole.x0 + inset
	var z0 := hole.z0 + inset
	var x1 := hole.x0 + hole.nx * hole.cell - inset
	var z1 := hole.z0 + hole.nz * hole.cell - inset
	var tee := Vector2(hole.tee.x, hole.tee.z)
	var corners := [Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)]
	var panel := 3.0
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		var d := (b - a).normalized()
		var count := int(a.distance_to(b) / panel)
		for i in count:
			var c := a + d * (i + 0.5) * (a.distance_to(b) / count)
			var ok := (
				MiniFraming.clear_of_course(hole, c.x, c.y, 2.0)
				and Geometry2D.get_closest_point_to_segment(c, tee, spot).distance_to(c) > 6.0
				and _ground_y(c.x, c.y) > MiniBaker.LAWN - 0.1
			)
			if not ok:
				continue
			var basis := Basis(Vector3.UP, atan2(-d.y, d.x)) * Basis.from_scale(Vector3(3, 2, 3))
			# The model's panel sits on its tile's back edge (z -0.465): centre it on the line.
			var at := Vector3(c.x, _ground_y(c.x, c.y), c.y) + basis * Vector3(0, 0, 0.465)
			batch.add("fence_simple", Transform3D(basis, at), false)
	batch.build(self, _theme)


## Two to four small scenes on the lawn beside the play view (research: "story vignettes"), from
## the world's list (GolfTheme.vignettes). Seeded per hole.
func _vignettes(hole: HoleData, seed_value: int, spot: Vector2) -> void:
	var rng := Rng.make(seed_value * 13 + 5)
	var big := KitBatch.new()
	var small := KitBatch.new()
	var tee := Vector2(hole.tee.x, hole.tee.z)
	var along := (spot - tee).normalized()
	var side := Vector2(-along.y, along.x)
	var length := tee.distance_to(spot) - MiniFraming.LANDMARK_BEYOND
	var placed := 0
	for attempt in 24:
		if placed >= 4:
			break
		var t := rng.randf_range(0.15, 0.95) * length
		var lat := rng.randf_range(7.0, 13.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		var c := tee + along * t + side * lat
		if (
			not MiniFraming.clear_of_course(hole, c.x, c.y, 3.0)
			or _ground_y(c.x, c.y) < MiniBaker.LAWN - 0.1
		):
			continue
		var y := _ground_y(c.x, c.y)
		var yaw := rng.randf_range(0.0, TAU)
		var turn := Basis(Vector3.UP, yaw)
		var at := func(dx: float, dz: float) -> Vector3:
			return Vector3(c.x, y, c.y) + turn * Vector3(dx, 0, dz)
		var kind: String = _theme.vignettes[placed % _theme.vignettes.size()]
		_vignette(kind, big, small, rng, turn, at)
		placed += 1
	big.build(self, _theme)
	small.build(self, _theme, false)


## Butterflies over lawn spots just outside the rails (spread out), birds around the landmark.
func _life(hole: HoleData, seed_value: int) -> void:
	var rng := Rng.make(seed_value * 7 + 11)
	var spots := PackedVector3Array()
	var w := hole.walls
	var tries := 0
	while spots.size() < AmbientLife.BUTTERFLIES and tries < 60 and w.size() >= 4:
		tries += 1
		var o := rng.randi_range(0, w.size() / 4 - 1) * 4
		var a := Vector2(w[o], w[o + 1])
		var b := Vector2(w[o + 2], w[o + 3])
		var d := (b - a).normalized()
		var q := a.lerp(b, rng.randf()) + Vector2(-d.y, d.x) * (1.3 if rng.randf() < 0.5 else -1.3)
		if hole.surface_at(q.x, q.y) != HoleData.Surface.OUT:
			continue
		var y := hole.height(q.x, q.y)
		if y < MiniBaker.LAWN - 0.05:
			continue
		var p := Vector3(q.x, y, q.y)
		var near := false
		for s in spots:
			near = near or s.distance_to(p) < 4.0
		if not near:
			spots.append(p)
	var life := AmbientLife.new()
	add_child(life)
	life.build(spots, landmark, _theme)


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


## One small scene: logs (pile and stumps), mushrooms (in tall grass), planters (with flowers),
## rocks (a rock garden), canoe (pulled up with a log), columns (fallen ruins), cactus (a cluster
## with rocks), campfire (stones and logs, a warm glow).
func _vignette(
	kind: String,
	big: KitBatch,
	small: KitBatch,
	rng: RandomNumberGenerator,
	turn: Basis,
	at: Callable
) -> void:
	var sc := func(s: float) -> Basis: return turn.scaled(Vector3.ONE * s)
	var jitter := func(r: float) -> Vector3:
		return at.call(rng.randf_range(-r, r), rng.randf_range(-r, r))
	match kind:
		"logs":
			big.add("log_stack", Transform3D(sc.call(2.6), at.call(0, 0)), false)
			big.add("stump_round", Transform3D(sc.call(2.2), at.call(1.4, 0.6)))
			big.add("stump_round", Transform3D(sc.call(1.8), at.call(1.1, -1.0)))
		"mushrooms":
			for m in 4:
				var model := "mushroom_redGroup" if m % 2 == 0 else "mushroom_tanGroup"
				small.add(model, Transform3D(sc.call(2.0), jitter.call(1.0)), false)
			for g in 3:
				small.add("grass_large", Transform3D(sc.call(2.2), jitter.call(1.2)))
		"planters":
			for k in 2:
				var p3: Vector3 = at.call(k * 1.5 - 0.75, 0)
				big.add("pot_large", Transform3D(sc.call(2.2), p3), false)
				for f in 3:
					var fl: String = _theme.flower_models[f % _theme.flower_models.size()]
					var off := Vector3(f * 0.35 - 0.35, 0.33, rng.randf_range(-0.15, 0.15))
					small.add(fl, Transform3D(sc.call(1.6), p3 + turn * off))
		"rocks":
			big.add("rock_largeA", Transform3D(sc.call(2.2), at.call(0, 0)), false)
			for r in 3:
				big.add("rock_smallA", Transform3D(sc.call(1.6), jitter.call(1.6)), false)
		"canoe":
			big.add("canoe", Transform3D(sc.call(2.4), at.call(0, 0)))
			big.add("log", Transform3D(sc.call(2.0), at.call(1.6, 0.8)))
			big.add("rock_smallA", Transform3D(sc.call(1.8), at.call(-1.4, -0.6)), false)
		"columns":
			big.add("statue_column", Transform3D(sc.call(2.4), at.call(0, 0)))
			var fallen := turn * Basis(Vector3.FORWARD, PI * 0.5)
			var lying := Transform3D(fallen.scaled(Vector3.ONE * 2.0), at.call(1.8, 0.4))
			big.add("statue_column", lying)
			big.add("rock_smallA", Transform3D(sc.call(1.6), at.call(-1.2, 0.8)), false)
		"cactus":
			big.add("cactus_tall", Transform3D(sc.call(2.4), at.call(0, 0)))
			big.add("cactus_short", Transform3D(sc.call(2.0), at.call(1.3, 0.5)))
			big.add("rock_smallA", Transform3D(sc.call(1.6), at.call(-1.0, 0.9)), false)
		"campfire":
			big.add("campfire_stones", Transform3D(sc.call(2.4), at.call(0, 0)), false)
			big.add("log", Transform3D(sc.call(1.8), at.call(1.5, 0.3)))
			big.add("log", Transform3D(sc.call(1.8), at.call(-1.3, 0.9)))
			var ember := OmniLight3D.new()
			ember.light_color = _theme.glow
			ember.light_energy = 1.2
			ember.omni_range = 3.0
			ember.position = at.call(0, 0) + Vector3(0, 0.6, 0)
			add_child(ember)
