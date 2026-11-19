class_name MiniDressing
extends RefCounted
## Fairway Flick mini-golf course dressing (render only, built once per hole): the merged bevelled
## rail mesh, bumpers, the outlined ball, and flower beds / bushes outside the rails. Colours come
## from the world's GolfTheme. Split out of golf_game.gd.

const RAIL_BEVEL := 0.045


## Rails: one merged mesh for the whole hole - a bevelled wooden profile swept along every wall
## segment, its top following the ground (smooth beside ramps), sides in the body colour, top and
## bevels in the light cap colour (one draw). Then the bumpers.
static func rails(world: Node3D, hole: HoleData, theme: GolfTheme) -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var w := hole.walls
	var t := maxf(hole.wall_half, 0.05)
	var b := RAIL_BEVEL
	var body := theme.rail_body
	var cap := theme.rail_cap
	# Profile across the rail (offset from the centre line, height above the local top):
	# outer side -> bevel -> top -> bevel -> inner side; base well below the ground.
	var prof := [
		Vector2(-t, -10.0),
		Vector2(-t, -b),
		Vector2(-t + b, 0.0),
		Vector2(t - b, 0.0),
		Vector2(t, -b),
		Vector2(t, -10.0)
	]
	var pcols := [body, cap, cap, cap, body]
	for o in range(0, w.size(), 4):
		var a := Vector2(w[o], w[o + 1])
		var e := Vector2(w[o + 2], w[o + 3])
		var length := a.distance_to(e)
		var dir := (e - a) / length
		var nrm := Vector2(-dir.y, dir.x)
		# Extend past both ends by t so corners close.
		var a2 := a - dir * t
		var n := maxi(1, int(ceilf((length + 2.0 * t) / 0.25)))
		for k in n:
			var s0 := float(k) / n * (length + 2.0 * t)
			var s1 := float(k + 1) / n * (length + 2.0 * t)
			var c0 := a2 + dir * s0
			var c1 := a2 + dir * s1
			var top0 := hole.height(c0.x, c0.y) + hole.wall_height
			var top1 := hole.height(c1.x, c1.y) + hole.wall_height
			for f in prof.size() - 1:
				var p0: Vector2 = prof[f]
				var p1: Vector2 = prof[f + 1]
				var v00 := Vector3(
					c0.x + nrm.x * p0.x, maxf(top0 + p0.y, MiniBaker.PIT), c0.y + nrm.y * p0.x
				)
				var v01 := Vector3(
					c0.x + nrm.x * p1.x, maxf(top0 + p1.y, MiniBaker.PIT), c0.y + nrm.y * p1.x
				)
				var v10 := Vector3(
					c1.x + nrm.x * p0.x, maxf(top1 + p0.y, MiniBaker.PIT), c1.y + nrm.y * p0.x
				)
				var v11 := Vector3(
					c1.x + nrm.x * p1.x, maxf(top1 + p1.y, MiniBaker.PIT), c1.y + nrm.y * p1.x
				)
				var fn := (v01 - v00).cross(v10 - v00).normalized()
				if (
					fn.dot(
						Vector3(nrm.x * (p0.x + p1.x), (p0.y + p1.y) + 10.0, nrm.y * (p0.x + p1.x))
					)
					< 0.0
				):
					fn = -fn
				for v in [v00, v10, v11, v00, v11, v01]:
					verts.append(v)
					norms.append(fn)
					cols.append(pcols[f])
		# End caps (flat).
		for end in [[a2, -dir], [e + dir * t, dir]]:
			var c: Vector2 = end[0]
			var d2: Vector2 = end[1]
			var top := hole.height(c.x, c.y) + hole.wall_height
			var q0 := Vector3(c.x - nrm.x * t, MiniBaker.PIT, c.y - nrm.y * t)
			var q1 := Vector3(c.x + nrm.x * t, MiniBaker.PIT, c.y + nrm.y * t)
			var q2 := Vector3(c.x + nrm.x * t, top - b, c.y + nrm.y * t)
			var q3 := Vector3(c.x - nrm.x * t, top - b, c.y - nrm.y * t)
			for v in [q0, q1, q2, q0, q2, q3]:
				verts.append(v)
				norms.append(Vector3(d2.x, 0.0, d2.y))
				cols.append(body)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.65
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	world.add_child(mi)
	var bp := hole.bumpers
	for o in range(0, bp.size(), 3):
		var cyl := CylinderMesh.new()
		cyl.top_radius = bp[o + 2]
		cyl.bottom_radius = bp[o + 2]
		cyl.height = 0.5
		cyl.radial_segments = 24
		var at := Vector3(bp[o], hole.height(bp[o], bp[o + 1]) + 0.25, bp[o + 1])
		part(world, cyl, theme.bumper, at)
		var ring := CylinderMesh.new()
		ring.top_radius = bp[o + 2] + 0.01
		ring.bottom_radius = bp[o + 2] + 0.01
		ring.height = 0.12
		ring.radial_segments = 24
		part(world, ring, theme.rail_cap, at)


## The ball: shaded white with a toon highlight and rim light, plus a thin dark outline (inverted
## hull) so it reads against any carpet.
static func ball(world: Node3D, radius: float, theme: GolfTheme) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sphere(radius)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = theme.ball
	mat.roughness = 0.3
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.rim_enabled = true
	mat.rim = 0.4
	mat.rim_tint = 0.3
	mat.emission_enabled = true
	mat.emission = theme.ball * 0.25  # never muddy in shade
	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.albedo_color = theme.ball_outline
	outline.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.grow = true
	outline.grow_amount = radius * 0.12
	mat.next_pass = outline
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	return mi


## Ring 1: kit bushes, stones, flower clusters and grass tufts on the lawn just outside the rails
## (seeded per hole). Everything stays below about rail height so it never hides the ball; bushes
## and stones cast shadows, the small pieces do not. Two draw calls per colour, not per prop.
static func decor(world: Node3D, hole: HoleData, theme: GolfTheme, index: int) -> void:
	var rng := Rng.make(4242 + index)
	var big := KitBatch.new()
	var small := KitBatch.new()
	var w := hole.walls
	for o in range(0, w.size(), 4):
		var a := Vector2(w[o], w[o + 1])
		var b := Vector2(w[o + 2], w[o + 3])
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var nrm := Vector2(-dir.y, dir.x)
		var t := 0.4
		while t < length - 0.4:
			for side in [-1.0, 1.0]:
				var off: float = side * rng.randf_range(0.55, 1.4)
				var q: Vector2 = a + dir * t + nrm * off
				var roll := rng.randf()
				var yaw := rng.randf_range(0.0, TAU)
				if hole.surface_at(q.x, q.y) != HoleData.Surface.OUT:
					continue
				var y := hole.height(q.x, q.y)
				if y < MiniBaker.LAWN - 0.05:
					continue  # not in the gaps
				var turn := Basis(Vector3.UP, yaw)
				var at := Vector3(q.x, y, q.y)
				if roll < 0.14:  # a low stone
					big.add("rock_smallA", Transform3D(turn.scaled(Vector3.ONE * 1.3), at), false)
				elif roll < 0.48:  # a bush, about rail height
					var bushes := theme.bushes
					var model: String = bushes[0] if roll < 0.36 else bushes[bushes.size() - 1]
					var sz := rng.randf_range(1.6, 2.0)
					big.add(model, Transform3D(turn.scaled(Vector3.ONE * sz), at))
				elif roll < 0.58:  # a grass tuft
					small.add("grass_large", Transform3D(turn.scaled(Vector3.ONE * 1.3), at))
				else:  # a cluster of three flowers of one kind
					var kinds := theme.flower_models
					var model2: String = kinds[rng.randi_range(0, kinds.size() - 1)]
					for k in 3:
						var fq := (
							q + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3))
						)
						var fs := rng.randf_range(1.2, 1.5)
						var ft := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
							Vector3.ONE * fs
						)
						small.add(model2, Transform3D(ft, Vector3(fq.x, y, fq.y)))
			t += rng.randf_range(0.7, 1.2)
	big.build(world, theme)
	small.build(world, theme, false)


static func part(world: Node3D, mesh: Mesh, col: Color, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mi.material_override = mat
	mi.position = at
	world.add_child(mi)


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s
