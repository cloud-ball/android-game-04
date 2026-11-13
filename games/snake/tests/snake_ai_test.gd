extends GdUnitTestSuite
## CPU rival: chases orbs, and never picks a move flood-fill marks as a trap while a safe one
## exists, unless a difficulty's blunder roll says so (then it still never picks a blocked cell).


func _place(logic: SnakeLogic, who: int, cells: Array, dir: int) -> void:
	var s := logic.snakes[who]
	s.body.clear()
	for c in cells:
		s.body.append(c)
	s.dir = dir


func test_first_step_heads_for_nearest_orb() -> void:
	var c := SnakeConfig.new()
	c.orb_count = 0
	var g := SnakeLogic.new(c, 1, false)
	var head := g.snakes[0].head()
	g.orbs.append(head + Vector2i(3, 0))
	assert_int(SnakeAI.first_step_to_orb(g, 0)).is_equal(SnakeLogic.Dir.RIGHT)


func test_refuses_orb_inside_dead_end() -> void:
	var c := SnakeConfig.new()
	c.orb_count = 0
	c.ai_wander = 0.0
	var g := SnakeLogic.new(c, 1, true)
	# Pocket (0,0)-(0,1) walled by the rival at x=1; the orb at (0,0) is bait.
	_place(
		g,
		0,
		[
			Vector2i(0, 2),
			Vector2i(0, 3),
			Vector2i(0, 4),
			Vector2i(0, 5),
			Vector2i(0, 6),
			Vector2i(0, 7)
		],
		SnakeLogic.Dir.UP
	)
	_place(
		g, 1, [Vector2i(1, 1), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], SnakeLogic.Dir.DOWN
	)
	g.orbs.append(Vector2i(0, 0))
	var rng := RandomNumberGenerator.new()
	assert_int(SnakeAI.first_step_to_orb(g, 0)).is_equal(SnakeLogic.Dir.UP)
	assert_int(SnakeAI.choose(g, 0, rng)).is_equal(SnakeLogic.Dir.RIGHT)


func test_never_chooses_a_trap_when_a_safe_move_exists() -> void:
	var decisions := 0
	for difficulty in ["easy", "medium", "hard"]:
		var cfg := SnakeConfig.for_difficulty(difficulty)
		for seed_value in range(1, 11):
			decisions += _check_match(cfg, seed_value)
	assert_int(decisions).is_greater(300)


func _check_match(cfg: SnakeConfig, seed_value: int) -> int:
	var g := SnakeLogic.new(cfg, seed_value, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31
	var checked := 0
	for i in 400:
		if g.is_over():
			break
		for who in 2:
			var options := SnakeAI.evaluate(g, who)
			var chosen := SnakeAI.choose(g, who, rng, {"blunder": 0.0})
			var any_safe := options.any(func(o: Dictionary) -> bool: return not o.trap)
			if any_safe:
				var pick: Array = options.filter(
					func(o: Dictionary) -> bool: return o.dir == chosen
				)
				(
					assert_bool(pick[0].trap)
					. override_failure_message(
						"seed %d tick %d snake %d chose a trap" % [seed_value, i, who]
					)
					. is_false()
				)
			g.queue_turn(who, chosen)
			checked += 1
		g.step()
	return checked


func test_difficulty_configs_load() -> void:
	assert_float(SnakeConfig.for_difficulty("easy").ai_wander).is_greater(
		SnakeConfig.for_difficulty("hard").ai_wander
	)
	assert_float(SnakeConfig.for_difficulty("medium").base_hz).is_equal(5.5)
	assert_bool(SnakeConfig.for_difficulty("hard").ai_avoid_heads).is_true()
	assert_float(SnakeConfig.for_difficulty("hard").ai_hunt).is_greater(
		SnakeConfig.for_difficulty("easy").ai_hunt
	)
	assert_float(SnakeConfig.for_difficulty("easy").base_hz).is_less(
		SnakeConfig.for_difficulty("medium").base_hz
	)


func test_ai_takes_the_wrap_shortcut() -> void:
	var c := SnakeConfig.new()
	c.orb_count = 0
	c.ai_wander = 0.0
	c.wrap = true
	var g := SnakeLogic.new(c, 1, false)
	_place(g, 0, [Vector2i(0, 5), Vector2i(0, 6), Vector2i(0, 7)], SnakeLogic.Dir.UP)
	g.orbs.append(Vector2i(g.width - 1, 5))
	assert_int(SnakeAI.first_step_to_orb(g, 0)).is_equal(SnakeLogic.Dir.LEFT)
	var left: Array = SnakeAI.evaluate(g, 0).filter(
		func(o: Dictionary) -> bool: return o.dir == SnakeLogic.Dir.LEFT
	)
	assert_bool(left[0].blocked).is_false()
	assert_int(SnakeAI.choose(g, 0, RandomNumberGenerator.new())).is_equal(SnakeLogic.Dir.LEFT)


func test_blunders_never_pick_a_blocked_cell() -> void:
	var picked := 0
	for seed_value in range(1, 8):
		var g := SnakeLogic.new(SnakeConfig.for_difficulty("easy"), seed_value, true)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for i in 300:
			if g.is_over():
				break
			for who in 2:
				var options := SnakeAI.evaluate(g, who)
				var chosen := SnakeAI.choose(g, who, rng, {"blunder": 1.0})
				var open := options.filter(func(o: Dictionary) -> bool: return not o.blocked)
				if not open.is_empty():
					var pick: Array = options.filter(
						func(o: Dictionary) -> bool: return o.dir == chosen
					)
					assert_bool(pick[0].blocked).is_false()
					picked += 1
				g.queue_turn(who, chosen)
			g.step()
	assert_int(picked).is_greater(100)


func test_levels_get_stronger() -> void:
	var e := SnakeConfig.for_difficulty("easy")
	var m := SnakeConfig.for_difficulty("medium")
	var h := SnakeConfig.for_difficulty("hard")
	assert_bool(e.ai_blunder > m.ai_blunder and m.ai_blunder > h.ai_blunder).is_true()
	assert_bool(e.ai_hunt <= m.ai_hunt and m.ai_hunt < h.ai_hunt).is_true()
