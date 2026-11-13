extends GdUnitTestSuite
## Cue solver physics: closed-form phases, collisions, cushions, pockets, determinism, energy.
## Expected values from docs/research/Cue Club pool game design.md (computed from the cited
## equations).

const G := 9.81


func _sim(params: CueParams = null) -> CueSim:
	return CueSim.new(params)


## Runs substeps until cond(sim) is true (or max seconds pass).
func _until(sim: CueSim, cond: Callable, max_s := 10.0) -> void:
	var steps := int(max_s * 240.0)
	for s in steps:
		if cond.call(sim):
			return
		sim.step(CueSim.SUBSTEP)


func test_stun_shot_slides_then_rolls_at_five_sevenths() -> void:
	var sim := _sim()
	sim.place(0, 0.0, -0.8)
	sim.strike(0.0, 1.0, 2.0)
	assert_int(sim.phase[0]).is_equal(CueSim.SLIDING)
	_until(sim, func(s: CueSim) -> bool: return s.phase[0] == CueSim.ROLLING)
	var t_slide := 2.0 * 2.0 / (7.0 * 0.2 * G)  # 0.291 s
	assert_float(sim.time).is_between(t_slide - 0.0001, t_slide + CueSim.SUBSTEP)
	# At the substep after the transition the ball has rolled a little: speed ~ 5/7 v0.
	assert_float(sim.vy[0]).is_equal_approx(2.0 * 5.0 / 7.0, 0.002)
	var slide_dist := 2.0 * t_slide - 0.5 * 0.2 * G * t_slide * t_slide  # 0.499 m
	assert_float(sim.py[0] + 0.8).is_equal_approx(slide_dist, 0.006)


func test_draw_back_speed_is_two_sevenths_of_r_omega() -> void:
	var sim := _sim()
	sim.place(0, 0.0, 0.0)
	var r := sim.p.radius
	sim.wx[0] = 1.0 / r  # pure backspin relative to +y, R w = 1 m/s, ball at rest
	sim._classify(0)
	assert_int(sim.phase[0]).is_equal(CueSim.SLIDING)
	_until(sim, func(s: CueSim) -> bool: return s.phase[0] == CueSim.ROLLING)
	assert_float(sim.vy[0]).is_equal_approx(-2.0 / 7.0, 0.002)


func test_rolling_deceleration_is_mu_roll_times_g() -> void:
	var sim := _sim()
	sim.place(0, 0.0, -0.9)
	sim.strike(0.0, 1.0, 1.0, 0.0, 0.4)  # 0.4 R above centre: natural roll at once
	assert_int(sim.phase[0]).is_equal(CueSim.ROLLING)
	sim.step(1.0)
	assert_float(sim.vy[0]).is_equal_approx(1.0 - 0.012 * G, 1e-9)


func test_ninety_degree_rule_for_a_stun_cut() -> void:
	var params := CueParams.pool()
	params.e_ball = 1.0
	params.mu_ball = 0.0
	var sim := _sim(params)
	var r := params.radius
	sim.place(0, 0.0, -0.1)
	sim.place(1, r, 0.0)  # half-ball cut, object ball ~4 cm ahead
	sim.strike(0.0, 1.0, 3.0)
	_until(sim, func(s: CueSim) -> bool: return s.log.size() >= 3)
	var cue := Vector2(sim.vx[0], sim.vy[0]).normalized()
	var obj := Vector2(sim.vx[1], sim.vy[1]).normalized()
	assert_float(absf(cue.dot(obj))).is_less(0.02)


func test_thirty_degree_rule_for_a_rolling_half_ball_hit() -> void:
	var sim := _sim()
	var r := sim.p.radius
	sim.place(0, 0.0, -0.6)
	sim.place(1, r, 0.0)
	sim.strike(0.0, 1.0, 1.5, 0.0, 0.4)
	_until(sim, func(s: CueSim) -> bool: return s.log.size() >= 3)
	_until(sim, func(s: CueSim) -> bool: return s.phase[0] == CueSim.ROLLING)
	var deg := rad_to_deg(absf(atan2(sim.vx[0], sim.vy[0])))
	assert_float(deg).is_between(27.0, 36.0)


func test_cut_throws_and_outside_gearing_english_does_not() -> void:
	var sim := _sim()
	var r := sim.p.radius
	# Cue ball touching the object ball at a 30 deg cut, moving +y at 1 m/s, no spin.
	var n := Vector2(0.5, 0.8660254037844386)  # line of centres
	sim.place(0, 0.0, 0.0)
	sim.place(1, n.x * 2.0 * r, n.y * 2.0 * r)
	sim.vy[0] = 1.0
	sim._ball_ball(0, 1)
	var throw_deg := rad_to_deg(Vector2(sim.vx[1], sim.vy[1]).angle_to(n))
	assert_float(absf(throw_deg)).is_greater(0.5)  # cut-induced throw
	# Same cut with gearing english: the contact points do not slip, so no throw.
	sim.place(0, 0.0, 0.0)
	sim.place(1, n.x * 2.0 * r, n.y * 2.0 * r)
	sim.vy[0] = 1.0
	var t := Vector2(-n.y, n.x)
	sim.wz[0] = -Vector2(0.0, 1.0).dot(t) / r  # makes the contact slip zero
	sim._ball_ball(0, 1)
	var geared := rad_to_deg(Vector2(sim.vx[1], sim.vy[1]).angle_to(n))
	assert_float(absf(geared)).is_less(1e-6)


func test_energy_never_increases() -> void:
	for seed_value in [3, 11]:
		var sim := _sim()
		PoolRack.setup(sim, seed_value)
		sim.strike(0.05, 0.99874921777, 8.0, 0.2, -0.2)
		var before := sim.energy()
		while sim.is_moving():
			sim.step(CueSim.SUBSTEP)
			var now := sim.energy()
			assert_float(now).is_less_equal(before * (1.0 + 1e-12) + 1e-15)
			before = now


func test_balls_never_overlap_or_leave_the_table() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for shot in 6:
		var sim := _sim()
		PoolRack.setup(sim, shot + 1)
		var a := rng.randf_range(-0.3, 0.3)
		sim.strike(sin(a), cos(a), rng.randf_range(4.0, 11.0), rng.randf_range(-0.5, 0.5), 0.0)
		var two_r := 2.0 * sim.p.radius
		var guard := 0
		while sim.is_moving() and guard < 240 * 20:
			sim.step(CueSim.SUBSTEP * 4)
			guard += 4
			for i in CueSim.N:
				if not sim.on_table(i):
					continue
				assert_float(absf(sim.px[i])).is_less(sim.table.hw + 0.1)
				assert_float(absf(sim.py[i])).is_less(sim.table.hl + 0.1)
				for j in range(i + 1, CueSim.N):
					if sim.on_table(j):
						var dx: float = sim.px[i] - sim.px[j]  # 64-bit (Vector2 is 32-bit)
						var dy: float = sim.py[i] - sim.py[j]
						var d := sqrt(dx * dx + dy * dy)
						assert_float(d).is_greater_equal(two_r - 1e-9)


func test_stop_shot_leaves_the_cue_ball_within_a_centimetre() -> void:
	# Centre ball from 5 mm away: still a stun (no spin) at contact. With e = 0.93 the cue ball
	# keeps (1 - e) / 2 of its speed and creeps ~0.6-0.8 cm at 1.5 m/s (1.1-1.3 cm at 2 m/s).
	var sim := _sim()
	var r := sim.p.radius
	sim.place(1, 0.0, -0.1)
	sim.place(0, 0.0, -0.1 - 2.0 * r - 0.005)
	sim.strike(0.0, 1.0, 1.5)
	_until(sim, func(s: CueSim) -> bool: return s.log.size() >= 3)
	_until(sim, func(s: CueSim) -> bool: return s.phase[0] == CueSim.STATIONARY)
	assert_float(sim.py[0] - (-0.1 - 2.0 * r)).is_between(0.0, 0.01)


func test_straight_shots_drop_into_corner_and_side_pockets() -> void:
	var sim := _sim()
	sim.place(0, 0.0, 0.0)
	var d := Vector2(sim.table.hw, sim.table.hl).normalized()
	sim.strike(d.x, d.y, 3.0)
	sim.run_to_rest()
	assert_bool(sim.on_table(0)).is_false()
	assert_int(sim.pocket_of[0]).is_equal(3)
	sim.place(0, 0.0, 0.0)
	sim.strike(-1.0, 0.0, 2.0)
	sim.run_to_rest()
	assert_int(sim.pocket_of[0]).is_equal(4)


func test_rail_rebound_and_running_english() -> void:
	var sim := _sim()
	sim.place(0, 0.0, 0.5)
	sim.strike(0.0, 1.0, 2.0, 0.0, 0.4)  # rolling straight into the top rail
	_until(sim, func(s: CueSim) -> bool: return s.vy[0] < 0.0)
	var back := -sim.vy[0] / 2.0
	assert_float(back).is_between(0.4, 0.9)
	assert_float(absf(sim.vx[0])).is_less(1e-9)
	# Right english sends it back to the right (+x).
	sim.place(0, 0.0, 0.5)
	sim.strike(0.0, 1.0, 2.0, 0.4, 0.0)
	_until(sim, func(s: CueSim) -> bool: return s.vy[0] < 0.0)
	assert_float(sim.vx[0]).is_greater(0.05)


func test_render_rate_does_not_change_the_result() -> void:
	var a := _sim()
	var b := _sim()
	for s in [a, b]:
		PoolRack.setup(s, 5)
		s.strike(0.0, 1.0, 9.0)
	for f in 240:
		a.step(1.0 / 60.0)  # 4 substeps per frame
	for f in 480:
		b.step(1.0 / 120.0)  # 2 substeps per frame
	assert_bool(a.px == b.px and a.py == b.py and a.vx == b.vx).is_true()


func test_half_size_substeps_agree_closely() -> void:
	var a := _sim()
	var b := _sim()
	b.substep = CueSim.SUBSTEP * 0.5
	for s in [a, b]:
		s.place(0, 0.0, -0.6)
		s.place(1, 0.1, 0.2)
		s.strike(0.12, 0.99277, 2.5, 0.0, 0.2)
		s.run_to_rest()
	for i in [0, 1]:
		assert_float(absf(a.px[i] - b.px[i])).is_less(0.002)
		assert_float(absf(a.py[i] - b.py[i])).is_less(0.002)
