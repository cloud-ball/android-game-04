extends GdUnitTestSuite
## PoolMatch: the solver and the Casual 8 rules kept in step over whole games.

# --- solver + rules together ----------------------------------------------------------------------


## A crude shooter: aims straight at a random legal ball, random speed; calls the nearest pocket
## to the 8 when needed; ball in hand: tries random spots.
func _random_turn(m: PoolMatch, rng: RandomNumberGenerator) -> PoolRules.Result:
	if m.state.ball_in_hand == PoolState.Hand.ANYWHERE:
		for t in 30:
			if m.place_cue(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.9, 0.9)):
				break
	if PoolRules.requires_call(m.state):
		m.call_pocket(rng.randi_range(0, 5))
	var targets := PoolRules.legal_targets(m.state)
	var tx := 0.0
	var ty := 1.0
	if not targets.is_empty():
		var b: int = targets[rng.randi_range(0, targets.size() - 1)]
		tx = m.sim.px[b] - m.sim.px[0]
		ty = m.sim.py[b] - m.sim.py[0]
	var d := sqrt(tx * tx + ty * ty)
	var speed := 9.0 if m.state.phase == PoolState.Phase.BREAK else rng.randf_range(1.0, 5.0)
	return m.shoot(tx / d, ty / d, speed, rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3))


func test_random_games_with_the_solver_stay_consistent_and_end() -> void:
	var finished := 0
	for g in 4:
		var rng := RandomNumberGenerator.new()
		rng.seed = 100 + g
		var m := PoolMatch.new(g + 1)
		for turn in 160:
			if m.over():
				break
			var r := _random_turn(m, rng)
			assert_object(r).is_not_null()
			# The rules' view of the table matches the solver's.
			for b in range(1, 16):
				assert_int(m.state.on_table[b]).is_equal(1 if m.sim.on_table(b) else 0)
			assert_bool(m.sim.on_table(0)).is_true()
		if m.over():
			finished += 1
			assert_int(m.state.winner).is_between(0, 1)
	assert_int(finished).is_greater(0)
