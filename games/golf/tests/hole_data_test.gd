extends GdUnitTestSuite
## HoleData: height / slope / surface sampling on the render triangles and exact swept contact.


func _plane(h: Callable, size := 40) -> HoleData:
	var d := HoleData.new()
	d.setup(-10.0, -float(size), 0.5, 40, size * 2)
	d.fill(h)
	return d


func test_plane_is_reproduced_exactly() -> void:
	var d := _plane(func(x: float, z: float) -> float: return 2.0 + 0.1 * x - 0.05 * z)
	for pt in [Vector2(0.3, -1.7), Vector2(-9.9, -39.9), Vector2(4.26, -12.13), Vector2(0.0, 0.0)]:
		assert_float(d.height(pt.x, pt.y)).is_equal_approx(2.0 + 0.1 * pt.x - 0.05 * pt.y, 1e-5)
		var g := d.gradient(pt.x, pt.y)
		assert_float(g.x).is_equal_approx(0.1, 1e-5)
		assert_float(g.y).is_equal_approx(-0.05, 1e-5)
	var n := d.normal(1.0, -5.0)
	assert_float(n.length()).is_equal_approx(1.0, 1e-6)  # Vector3 is 32-bit
	assert_float(n.dot(Vector3(-0.1, 1.0, 0.05).normalized())).is_equal_approx(1.0, 1e-6)


func test_vertices_and_continuity_on_bumpy_ground() -> void:
	var d := _plane(func(x: float, z: float) -> float: return 0.6 * sin(x * 0.7) * cos(z * 0.4))
	# Vertex values come back exactly; neighbouring triangles agree on shared edges.
	assert_float(d.height(d.x0 + 3 * d.cell, d.z0 + 7 * d.cell)).is_equal(d._h(3, 7))
	for k in 20:
		var x := -9.0 + k * 0.83
		var z := -30.0 + k * 1.37
		var e := 1e-7
		assert_float(d.height(x + e, z)).is_equal_approx(d.height(x - e, z), 1e-5)
		assert_float(d.height(x, z + e)).is_equal_approx(d.height(x, z - e), 1e-5)


func test_surface_lookup_and_outside() -> void:
	var d := HoleData.new()
	d.setup(0.0, 0.0, 1.0, 4, 4)
	d.fill(
		func(_x: float, _z: float) -> float: return 0.0,
		func(x: float, _z: float) -> int:
			return HoleData.Surface.GREEN if x > 2.0 else HoleData.Surface.ROUGH
	)
	assert_int(d.surface_at(3.5, 1.0)).is_equal(HoleData.Surface.GREEN)
	assert_int(d.surface_at(0.5, 1.0)).is_equal(HoleData.Surface.ROUGH)
	assert_int(d.surface_at(-0.1, 1.0)).is_equal(HoleData.Surface.OUT)
	assert_int(d.surface_at(2.0, 9.0)).is_equal(HoleData.Surface.OUT)


func test_sweep_finds_the_exact_contact() -> void:
	var d := _plane(func(x: float, _z: float) -> float: return 0.2 * x)
	var r := 0.021335
	var t := d.sweep(Vector3(1.0, 3.0, -5.0), Vector3(1.0, -1.0, -5.0), r)
	var hit := Vector3(1.0, 3.0, -5.0).lerp(Vector3(1.0, -1.0, -5.0), t)
	assert_float(hit.y).is_equal_approx(0.2 + r, 1e-6)
	assert_float(d.sweep(Vector3(0, 5, -5), Vector3(1, 5, -6), r)).is_equal(-1.0)
	assert_float(d.sweep(Vector3(0, -1, -5), Vector3(1, 5, -6), r)).is_equal(0.0)


## A ridge one vertex wide (0.13 m across at the ball's height) is far thinner than one 1/240 s
## step at 70 m/s (0.29 m): sampling only step ends would fly straight through it.
func test_fast_ball_cannot_tunnel_through_a_thin_ridge() -> void:
	var d := HoleData.new()
	d.setup(-5.0, -60.0, 0.5, 20, 120)
	d.fill(func(_x: float, z: float) -> float: return 3.0 if absf(z + 30.0) < 0.01 else 0.0)
	var f := GolfFlight.new()
	f.launch(Vector3(0.0, 2.6, -2.0), 70.0, 0.0, 0.0)
	var o := f.fly_over(d)
	assert_bool(o.hit).is_true()
	assert_float(o.pos.z).is_between(-30.5, -29.5)


## Random launches over rolling ground: the 1/240 s contact agrees with a 20x finer step (a skipped
## crossing would put it metres later), and the contact point never sits below the surface.
func test_contact_matches_a_much_finer_step() -> void:
	var d := _plane(
		func(x: float, z: float) -> float:
			return 1.5 * sin(x * 0.9) * sin(z * 0.35) + 0.4 * sin(z * 2.1),
		120
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for k in 30:
		var at := Vector3(rng.randf_range(-6, 6), 3.0 + rng.randf() * 2.0, rng.randf_range(-10, -2))
		var speed := rng.randf_range(15.0, 70.0)
		var launch := rng.randf_range(-12.0, 25.0)
		var heading := rng.randf_range(-20.0, 20.0)
		var coarse := GolfFlight.new()
		coarse.launch(at, speed, launch, 300.0, 0.0, heading)
		var a := coarse.fly_over(d)
		var fine := GolfFlight.new()
		fine.launch(at, speed, launch, 300.0, 0.0, heading)
		var b := fine.fly_over(d, GolfFlight.SUBSTEP / 20.0)
		assert_bool(a.hit).is_equal(b.hit)
		if a.hit:
			var pa: Vector3 = a.pos
			var fl: GolfFlight = coarse
			assert_float(pa.distance_to(b.pos)).override_failure_message("launch %d" % k).is_less(
				0.05
			)
			# Exact 64-bit state, not the 32-bit Vector3 copy.
			assert_float(fl.s[1] - d.height(fl.s[0], fl.s[2])).is_greater_equal(0.021335 - 1e-9)


func test_flat_hole_landing_matches_flat_flight() -> void:
	var d := _plane(func(_x: float, _z: float) -> float: return 0.0, 220)
	var r := 0.021335
	var a := GolfFlight.new()
	a.launch(Vector3(0, r, 0), 55.0, 16.0, 746.0)
	var over := a.fly_over(d)
	var b := GolfFlight.new()
	b.launch(Vector3(0, r, 0), 55.0, 16.0, 746.0)
	var flat := b.fly_to_ground(GolfFlight.SUBSTEP, r)
	assert_bool(over.hit).is_true()
	assert_float((over.pos as Vector3).distance_to(flat.pos)).is_less(0.01)
	assert_int(over.surface).is_equal(HoleData.Surface.FAIRWAY)
