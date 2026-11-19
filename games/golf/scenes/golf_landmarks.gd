class_name GolfLandmarks
extends RefCounted
## Each world's landmark (original designs, procedural, a handful of draw calls each), placed by
## GolfScenery straight ahead of the tee view (MiniFraming). build() returns the part that turns,
## if any: {"spin": Node3D, "axis": Vector3, "speed": float} (or {}).
## meadow: stone windmill-tower on a knoll; coastal: striped lighthouse on a rocky islet with a
## turning lamp; canyon: a natural rock arch; volcanic: a smoking cone with a glowing crater.


static func build(
	kind: String, parent: Node3D, at: Vector3, view: Vector2, scale: float, theme: GolfTheme
) -> Dictionary:
	var base := Node3D.new()
	base.position = at
	base.rotation.y = atan2(-view.x, -view.y)  # local +z faces the tee
	base.scale = Vector3.ONE * scale
	parent.add_child(base)
	match kind:
		"lighthouse":
			return _lighthouse(base, theme)
		"arch":
			return _arch(base, theme)
		"volcano":
			return _volcano(base, theme)
	return _windmill(base, theme)


## A tapered stone windmill-tower on a grassy knoll, with a wooden balcony, door and window, a
## pointed roof and four lattice sails facing the tee. Parts that share a colour are merged.
static func _windmill(base: Node3D, theme: GolfTheme) -> Dictionary:
	_knoll(base, theme.lawn.lightened(0.04), 26.0, 6.0)
	var foot := 1.35  # knoll height at the tower
	_part(base, _cyl(2.0, 3.0, 12.0, 8), theme.landmark_wall, Vector3(0, foot + 6.0, 0))
	_part(base, _cyl(0.0, 2.7, 3.8, 8), theme.landmark_roof, Vector3(0, foot + 13.9, 0))
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
	wood.append_from(_cyl(2.9, 2.9, 0.3, 8), 0, Transform3D(Basis(), Vector3(0, foot + 8.6, 0)))
	wood.append_from(door, 0, Transform3D(Basis(), Vector3(0, foot + 1.1, 2.85)))
	wood.append_from(window, 0, Transform3D(Basis(), Vector3(0, foot + 5.2, 2.5)))
	wood.append_from(hub, 0, Transform3D(Basis(), Vector3(0, foot + 11.0, 2.75)))
	_merged(base, wood, theme.landmark_wood)
	var blades := Node3D.new()
	blades.position = Vector3(0, foot + 11.0, 2.95)
	base.add_child(blades)
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
	_merged(blades, frame, theme.landmark_wood)
	_merged(blades, sails, theme.sail)
	return {"spin": blades, "axis": Vector3.FORWARD, "speed": 0.6}


## A rocky islet carrying a tapered tower in red and white bands, a dark gallery, a glowing lamp
## room under a red cap, and two light beams turning slowly.
static func _lighthouse(base: Node3D, theme: GolfTheme) -> Dictionary:
	_knoll(base, theme.stone, 22.0, 7.0)
	var foot := 1.8
	var bands := 6
	var h := 2.2
	var white := SurfaceTool.new()
	white.begin(Mesh.PRIMITIVE_TRIANGLES)
	var red := SurfaceTool.new()
	red.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in bands:
		var r0 := 2.6 - 0.15 * b
		var r1 := 2.6 - 0.15 * (b + 1)
		var at := Transform3D(Basis(), Vector3(0, foot + h * (b + 0.5), 0))
		(red if b % 2 == 1 else white).append_from(_cyl(r1, r0, h, 12), 0, at)
	var top := foot + h * bands
	red.append_from(_cyl(0.0, 1.7, 2.0, 12), 0, Transform3D(Basis(), Vector3(0, top + 3.0, 0)))
	_merged(base, white, theme.landmark_wall)
	_merged(base, red, theme.landmark_roof)
	var dark := SurfaceTool.new()
	dark.begin(Mesh.PRIMITIVE_TRIANGLES)
	dark.append_from(_cyl(2.3, 2.3, 0.3, 12), 0, Transform3D(Basis(), Vector3(0, top + 0.15, 0)))
	var door := BoxMesh.new()
	door.size = Vector3(1.1, 2.0, 0.4)
	dark.append_from(door, 0, Transform3D(Basis(), Vector3(0, foot + 1.0, 2.5)))
	_merged(base, dark, theme.landmark_wood)
	var lamp := _part(base, _cyl(1.2, 1.2, 1.7, 12), theme.glow, Vector3(0, top + 1.15, 0))
	glow(lamp, theme.glow, 2.5)
	var head := Node3D.new()
	head.position = Vector3(0, top + 1.15, 0)
	base.add_child(head)
	for side in [-1.0, 1.0]:
		var beam := BoxMesh.new()
		beam.size = Vector3(0.5, 0.5, 9.0)
		var mi := _part(head, beam, theme.glow, Vector3(0, 0, side * 5.0))
		var m := mi.material_override as StandardMaterial3D
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(theme.glow, 0.22)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {"spin": head, "axis": Vector3.UP, "speed": 0.5}


## A natural rock arch: a faceted ring of rock half sunk into the ground (only the arch shows),
## lighter bands on top, boulders at its feet.
static func _arch(base: Node3D, theme: GolfTheme) -> Dictionary:
	# Chunky blocks around a half circle (radius 8 m, ~3 m thick), staggered in and out so the
	# outline reads as weathered rock; alternate blocks take the lighter band colour.
	var block := BoxMesh.new()
	block.size = Vector3(1.0, 1.0, 1.0)
	var dark := SurfaceTool.new()
	dark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var light := SurfaceTool.new()
	light.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 11
	var stagger := [0.0, 0.5, -0.3, 0.7, 0.1, -0.4, 0.6, -0.2, 0.4, -0.5, 0.2]
	for k in steps:
		var t := PI * (k + 0.5) / steps
		var r := 8.0 + float(stagger[k]) * 0.6
		var centre := Vector3(cos(t) * r, sin(t) * r, 0.0)
		var turn := Basis(Vector3.BACK, t)  # the block's x runs out from the centre
		var size := Vector3(3.2 + absf(stagger[k]), 2.8, 3.4 - float(stagger[k]) * 0.8)
		var xf := Transform3D(turn.scaled(size), centre + Vector3(0, -1.0, 0))
		(light if k % 3 == 1 else dark).append_from(block, 0, xf)
	for side in [-1.0, 1.0]:  # broad feet
		var foot := Transform3D(
			Basis.from_scale(Vector3(4.2, 3.0, 4.0)), Vector3(side * 8.0, 0.2, 0.0)
		)
		dark.append_from(block, 0, foot)
	_merged(base, dark, theme.landmark_wall)
	_merged(base, light, theme.landmark_roof)
	var rocks := SurfaceTool.new()
	rocks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var boulder := SphereMesh.new()
	boulder.radial_segments = 7
	boulder.rings = 4
	for b in [[-8.5, 0.0, 2.6], [8.2, 1.5, 2.2], [-6.0, 3.0, 1.6], [10.5, -2.0, 1.8]]:
		var s: float = b[2]
		var t := Transform3D(
			Basis.from_scale(Vector3(s * 1.2, s * 0.8, s)), Vector3(b[0], 0.2, b[1])
		)
		rocks.append_from(boulder, 0, t)
	_merged(base, rocks, theme.landmark_wall.darkened(0.12))
	return {}


## A basalt cone with a glowing crater, lava streaks down its sides and smoke drifting up.
static func _volcano(base: Node3D, theme: GolfTheme) -> Dictionary:
	_part(base, _cyl(3.2, 15.0, 13.0, 10), theme.landmark_wall, Vector3(0, 6.0, 0))
	_part(base, _cyl(2.2, 3.4, 1.4, 10), theme.landmark_roof, Vector3(0, 12.9, 0))
	var crater := _part(base, _cyl(2.6, 2.6, 0.2, 10), theme.glow, Vector3(0, 13.5, 0))
	glow(crater, theme.glow, 3.0)
	var streaks := SurfaceTool.new()
	streaks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var strip := BoxMesh.new()
	strip.size = Vector3(0.7, 8.0, 0.25)
	for a in [0.4, 1.9, 3.3, 5.1]:
		# Lying on the cone (radius 15 at the foot, 3.2 at the top, 13 tall, base at y -0.5) from
		# the rim down: y = up the slope, z = out of the surface.
		var dir := Vector3(sin(a), 0, cos(a))
		var up_slope := (Vector3(0, 13.0, 0) - dir * 11.8).normalized()
		var out := (dir * 13.0 + Vector3(0, 11.8, 0)).normalized()
		var bx := up_slope.cross(out)
		var mid_y := 8.5
		var mid := dir * (15.0 - (mid_y + 0.5) / 13.0 * 11.8 + 0.1) + Vector3(0, mid_y, 0)
		streaks.append_from(strip, 0, Transform3D(Basis(bx, up_slope, out), mid))
	var lava := _merged(base, streaks, theme.glow)
	glow(lava, theme.glow, 1.6)
	var smoke := CPUParticles3D.new()
	smoke.amount = 10  # big alpha puffs: overdraw on the phone
	smoke.lifetime = 7.0
	smoke.preprocess = 7.0
	smoke.position = Vector3(0, 14.0, 0)
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.gravity = Vector3(0.4, 0.35, 0)
	smoke.initial_velocity_min = 0.6
	smoke.initial_velocity_max = 1.2
	smoke.scale_amount_min = 1.8
	smoke.scale_amount_max = 3.4
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 6
	puff.rings = 3
	smoke.mesh = puff
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.32, 0.28, 0.3, 0.45)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.material_override = sm
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	base.add_child(smoke)
	return {}


# --- helpers ---


static func _knoll(base: Node3D, col: Color, width: float, height: float) -> void:
	var knoll := SphereMesh.new()
	knoll.radial_segments = 12
	knoll.rings = 6
	var k := MeshInstance3D.new()
	k.mesh = knoll
	k.scale = Vector3(width, height, width)
	k.position.y = -height * 0.27
	k.material_override = mat(col)
	base.add_child(k)


static func _cyl(top: float, bottom: float, height: float, sides: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = sides
	c.rings = 1
	return c


static func _merged(parent: Node3D, st: SurfaceTool, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat(col)
	parent.add_child(mi)
	return mi


static func _part(parent: Node3D, mesh: Mesh, col: Color, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(col)
	mi.position = at
	parent.add_child(mi)
	return mi


static func glow(mi: MeshInstance3D, col: Color, energy: float) -> void:
	var m := mi.material_override as StandardMaterial3D
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.9
	return m
