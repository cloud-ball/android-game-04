extends GdUnitTestSuite
## PoolAim: power curve, angular sweep, lift-off filter, solver-driven guideline.


func test_power_curve_is_squared_and_breaks_go_harder() -> void:
	assert_float(PoolAim.speed_for(1.0)).is_equal(8.0)
	assert_float(PoolAim.speed_for(1.0, true)).is_equal(12.0)
	assert_float(PoolAim.speed_for(0.433)).is_equal_approx(1.5, 0.01)  # medium shot ~43% of the bar
	assert_float(PoolAim.speed_for(2.0)).is_equal(8.0)  # clamped


func test_sweep_rotates_by_the_swept_angle_around_the_cue_ball() -> void:
	var a := PoolAim.new()
	a.angle = 0.0
	var cue := Vector2(0.1, 0.2)
	a.sweep(cue, cue + Vector2(0.3, 0.0), cue + Vector2(0.0, 0.3), 0)
	assert_float(a.angle).is_equal_approx(PI * 0.5, 1e-6)  # Vector2 is 32-bit
	a.sweep(cue, cue + Vector2(0.0, 0.3), cue + Vector2(-0.3, 0.0), 10)
	assert_float(absf(a.angle)).is_equal_approx(PI, 1e-6)


func test_fine_aim_is_point_zero_three_degrees_per_dp() -> void:
	var a := PoolAim.new()
	a.angle = 0.0
	a.nudge(100.0, 0)
	assert_float(rad_to_deg(a.angle)).is_equal_approx(3.0, 1e-9)


func test_release_drops_the_last_sixty_ms_of_movement() -> void:
	var a := PoolAim.new()
	a.angle = 0.0
	a.nudge(10.0, 1000)  # 0.3 deg, settled
	a.nudge(10.0, 1100)  # 0.6 deg
	a.nudge(40.0, 1180)  # finger rolls off as it lifts
	a.release(1200)
	assert_float(rad_to_deg(a.angle)).is_equal_approx(0.6, 1e-9)


func test_guideline_straight_hit_sends_the_object_ball_along_the_line() -> void:
	var sim := CueSim.new()
	sim.place(0, 0.0, -0.5)
	sim.place(5, 0.0, 0.0)
	var a := PoolAim.new()
	a.set_dir(Vector2(0.0, 1.0))
	a.predict(sim, 2.0)
	assert_int(a.hit_kind).is_equal(1)
	assert_int(a.hit_ball).is_equal(5)
	assert_float(a.obj_dir.y).is_greater(0.999)
	assert_float(a.contact.y).is_equal_approx(-2.0 * sim.p.radius, 0.001)
	# The real table is untouched.
	assert_float(sim.py[0]).is_equal(-0.5)
	assert_bool(sim.is_moving()).is_false()


func test_guideline_cut_shows_throw_and_draw_bends_back() -> void:
	var sim := CueSim.new()
	var r := sim.p.radius
	sim.place(0, 0.0, -0.3)
	sim.place(5, r, 0.0)  # half-ball cut to the right
	var a := PoolAim.new()
	a.set_dir(Vector2(0.0, 1.0))
	a.predict(sim, 0.5)
	var geometric := Vector2(r, 0.0) - a.contact
	var throw_deg := rad_to_deg(absf(a.obj_dir.angle_to(geometric.normalized())))
	assert_float(throw_deg).is_greater(0.5)  # a slow cut throws: the guideline shows it
	sim.place(0, 0.0, -0.3)
	sim.place(5, 0.0, 0.0)
	a.predict(sim, 2.0, 0.0, -0.4)  # strong draw, straight: the cue ball comes back
	assert_float(a.cue_dir.y).is_less(-0.9)
	a.predict(sim, 2.0, 0.0, 0.4)  # follow: it carries on
	assert_float(a.cue_dir.y).is_greater(0.9)
	a.predict(sim, 1.2, 0.0, 0.0)  # centre ball from 30 cm: a little natural roll -> follows
	assert_float(a.cue_dir.y).is_greater_equal(0.0)
