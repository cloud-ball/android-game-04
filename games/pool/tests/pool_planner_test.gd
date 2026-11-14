extends GdUnitTestSuite
## PoolPlanner: analytic pot chance, simulated plans, no fouls.


func _table(cue: Vector2, balls: Dictionary) -> PoolMatch:
	var m := PoolMatch.new(1, 0)
	m.sim.clear()
	m.sim.place(0, cue.x, cue.y)
	for b in balls:
		var p: Vector2 = balls[b]
		m.sim.place(b, p.x, p.y)
	m.state = PoolState.new_rack(0)
	m.state.phase = PoolState.Phase.PLAY
	m.state.ball_in_hand = PoolState.Hand.NONE
	for b in range(1, 16):
		m.state.on_table[b] = 1 if balls.has(b) else 0
	return m


func test_pot_chance_falls_with_distance_cut_and_noise() -> void:
	var sim := CueSim.new()
	var approach := Vector2(sim.table.hw, sim.table.hl).normalized()
	var near := PoolPlanner.pot_chance(sim, 3, approach, 0.3, 0.3, 0.0, 0.5)
	var far := PoolPlanner.pot_chance(sim, 3, approach, 1.0, 1.0, 0.0, 0.5)
	var cut := PoolPlanner.pot_chance(sim, 3, approach, 0.3, 0.3, deg_to_rad(50), 0.5)
	var sloppy := PoolPlanner.pot_chance(sim, 3, approach, 0.3, 0.3, 0.0, 1.5)
	assert_float(near).is_greater(far)
	assert_float(near).is_greater(sloppy)
	assert_float(cut).is_greater(0.0)
	assert_float(near).is_less_equal(1.0)


func test_planner_pots_an_easy_straight_shot() -> void:
	var hw := 0.4955
	var hl := 0.9905
	var target := Vector2(hw, hl) * 0.75
	var dir := Vector2(hw, hl).normalized()
	# A stripe and the 8 elsewhere, so the open table is not "on the 8".
	var m := _table(target - dir * 0.4, {3: target, 12: Vector2(-0.3, -0.6), 8: Vector2(-0.3, 0.5)})
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var plan := PoolPlanner.new().plan(m, "hard", 0.3, rng)
	assert_bool(plan.is_empty()).is_false()
	assert_float((plan.dir as Vector2).dot(dir)).is_greater(0.99)
	m.shoot(plan.dir.x, plan.dir.y, plan.speed, plan.side, plan.top)
	assert_bool(m.sim.on_table(3)).is_false()


func test_planner_never_returns_a_fouling_plan() -> void:
	for seed_value in [3, 9, 21]:
		var m := PoolMatch.new(seed_value, 0)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		m.shoot(0.0, 1.0, 11.0)  # break
		if m.over() or m.state.phase != PoolState.Phase.PLAY:
			continue
		var plan := PoolPlanner.new().plan(m, "medium", 0.0, rng)
		if plan.is_empty():
			continue
		if PoolRules.requires_call(m.state):
			m.call_pocket(maxi(0, int(plan.pocket)))
		var r := m.shoot(plan.dir.x, plan.dir.y, plan.speed, plan.side, plan.top)
		assert_bool(r.foul()).override_failure_message("seed %d" % seed_value).is_false()
