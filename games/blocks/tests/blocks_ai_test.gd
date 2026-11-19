extends GdUnitTestSuite
## Facetfall CPU: legal placements, takes an obvious multi-line clear, and survives long.

const W := BlocksState.W
const H := BlocksState.H


func test_fills_a_four_deep_well_with_the_long_shard() -> void:
	var s := BlocksLogic.new_game(3)
	for y in range(H - 4, H):
		for x in W - 1:
			s.board[y * W + x] = 1
	s.kind = ShardData.LONG
	s.rot = 0
	s.px = BlocksLogic.SPAWN_X
	s.py = BlocksLogic.SPAWN_Y
	var plan := BlocksAI.choose(s, RandomNumberGenerator.new(), false)
	assert_int(int(plan.rot) % 2).is_equal(1)
	for a in BlocksAI.actions_for(s, plan):
		s = BlocksLogic.reduce(s, a)
	assert_int(s.lines).is_equal(4)


func test_planned_actions_always_end_in_a_lock() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var s := BlocksLogic.new_game(11)
	for i in 60:
		if s.over:
			break
		var pieces := s.pieces
		var plan := BlocksAI.choose(s, rng)
		assert_bool(plan.is_empty()).is_false()
		for a in BlocksAI.actions_for(s, plan):
			s = BlocksLogic.reduce(s, a)
		assert_int(s.pieces).is_equal(pieces + 1)


func test_best_play_survives_two_hundred_shards() -> void:
	var rng := RandomNumberGenerator.new()
	var s := BlocksLogic.new_game(42)
	for i in 200:
		for a in BlocksAI.actions_for(s, BlocksAI.choose(s, rng)):
			s = BlocksLogic.reduce(s, a)
	assert_bool(s.over).is_false()
	assert_int(s.lines).is_greater(60)
