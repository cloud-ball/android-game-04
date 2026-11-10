extends GdUnitTestSuite
## Pure-logic tests for Serpent Grid: movement, growth, collisions, input buffer, replays.

const U := SnakeLogic.Dir.UP
const R := SnakeLogic.Dir.RIGHT
const D := SnakeLogic.Dir.DOWN
const L := SnakeLogic.Dir.LEFT


func _cfg(orbs := 0) -> SnakeConfig:
	var c := SnakeConfig.new()
	c.orb_count = orbs
	return c


func _place(logic: SnakeLogic, who: int, cells: Array, dir: int) -> void:
	var s := logic.snakes[who]
	s.body.clear()
	for c in cells:
		s.body.append(c)
	s.dir = dir
	s.queue.clear()


func test_moves_one_cell_per_tick() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	var head := g.snakes[0].head()
	g.step()
	assert_that(g.snakes[0].head()).is_equal(head + Vector2i(0, -1))
	assert_int(g.snakes[0].body.size()).is_equal(3)


func test_eating_grows_and_scores() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	g.orbs.append(g.snakes[0].head() + Vector2i(0, -1))
	g.step()
	assert_int(g.snakes[0].body.size()).is_equal(4)
	assert_int(g.snakes[0].score).is_equal(10)
	assert_int(g.events.size()).is_equal(1)
	assert_str(g.events[0].type).is_equal("eat")
	assert_bool(g.orbs.is_empty()).is_true()


func test_orbs_respawn_on_empty_cells() -> void:
	var g := SnakeLogic.new(_cfg(2), 7, true)
	for i in 200:
		if g.is_over():
			break
		var grid := g.occupancy()
		for o in g.orbs:
			assert_int(grid[o.y * g.width + o.x]).is_equal(0)
		assert_int(g.orbs.size()).is_equal(2)
		g.step()
		_turn_away_from_walls(g)


func test_wall_ends_solo_run() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	for i in 40:
		g.step()
	assert_int(g.result).is_equal(SnakeLogic.Result.SOLO_OVER)
	assert_str(g.snakes[0].crash_cause).is_equal("wall")


func test_self_collision() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	_place(
		g, 0, [Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(6, 5), Vector2i(6, 4)], U
	)
	g.queue_turn(0, R)
	g.step()
	assert_bool(g.snakes[0].alive).is_false()
	assert_str(g.snakes[0].crash_cause).is_equal("self")


func test_moving_into_vacating_tail_is_safe() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	_place(g, 0, [Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(6, 5)], U)
	g.queue_turn(0, R)
	g.step()
	assert_bool(g.snakes[0].alive).is_true()
	assert_that(g.snakes[0].head()).is_equal(Vector2i(6, 5))


func test_growing_into_own_tail_crashes() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	_place(g, 0, [Vector2i(5, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(6, 5)], U)
	g.orbs.append(Vector2i(6, 5))
	g.queue_turn(0, R)
	g.step()
	assert_bool(g.snakes[0].alive).is_false()


func test_input_buffer_is_two_deep_and_rejects_reversals() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	assert_bool(g.queue_turn(0, D)).is_false()  # reversal of UP
	assert_bool(g.queue_turn(0, U)).is_false()  # repeat
	assert_bool(g.queue_turn(0, R)).is_true()
	assert_bool(g.queue_turn(0, R)).is_false()  # repeat of buffered
	assert_bool(g.queue_turn(0, D)).is_true()  # valid after RIGHT
	assert_bool(g.queue_turn(0, L)).is_false()  # buffer full
	g.step()
	assert_int(g.snakes[0].dir).is_equal(R)
	g.step()
	assert_int(g.snakes[0].dir).is_equal(D)


func test_quick_double_swipe_makes_u_turn() -> void:
	var g := SnakeLogic.new(_cfg(), 1, false)
	var head := g.snakes[0].head()
	g.queue_turn(0, R)
	g.queue_turn(0, D)
	g.step()
	g.step()
	assert_that(g.snakes[0].head()).is_equal(head + Vector2i(1, 1))
	assert_bool(g.snakes[0].alive).is_true()


func test_rival_runs_into_player_player_wins() -> void:
	var g := SnakeLogic.new(_cfg(), 1, true)
	_place(g, 0, [Vector2i(3, 10), Vector2i(3, 11), Vector2i(3, 12)], U)
	_place(g, 1, [Vector2i(2, 11), Vector2i(1, 11), Vector2i(0, 11)], R)
	g.step()
	assert_int(g.result).is_equal(SnakeLogic.Result.PLAYER_WON)
	assert_str(g.snakes[1].crash_cause).is_equal("rival")
	assert_int(g.snakes[0].score).is_equal(100)


func test_head_on_is_draw() -> void:
	var g := SnakeLogic.new(_cfg(), 1, true)
	_place(g, 0, [Vector2i(5, 10), Vector2i(5, 11), Vector2i(5, 12)], U)
	_place(g, 1, [Vector2i(5, 8), Vector2i(5, 7), Vector2i(5, 6)], D)
	g.step()
	assert_int(g.result).is_equal(SnakeLogic.Result.DRAW)


func test_swapping_heads_is_draw() -> void:
	var g := SnakeLogic.new(_cfg(), 1, true)
	_place(g, 0, [Vector2i(5, 10), Vector2i(5, 11), Vector2i(5, 12)], U)
	_place(g, 1, [Vector2i(5, 9), Vector2i(5, 8), Vector2i(5, 7)], D)
	g.step()
	assert_int(g.result).is_equal(SnakeLogic.Result.DRAW)


func test_tick_rate_rises_with_length() -> void:
	var c := _cfg()
	var g := SnakeLogic.new(c, 1, false)
	assert_float(g.tick_interval()).is_equal_approx(1.0 / c.base_hz, 1e-6)
	for i in 5:
		g.snakes[0].body.append(g.snakes[0].body.back())
	var hz := c.base_hz + 5.0 * c.hz_per_segment
	assert_float(g.tick_interval()).is_equal_approx(1.0 / hz, 1e-6)


func test_replays_are_bit_exact() -> void:
	assert_array(_play_hashes(1234)).is_equal(_play_hashes(1234))
	assert_array(_play_hashes(1234)).is_not_equal(_play_hashes(999))


func _play_hashes(seed_value: int) -> Array:
	var g := SnakeLogic.new(_cfg(2), seed_value, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := []
	for i in 300:
		if g.is_over():
			break
		g.queue_turn(0, SnakeAI.choose(g, 0, rng))
		g.queue_turn(1, SnakeAI.choose(g, 1, rng))
		g.step()
		out.append(g.board_hash())
	return out


func _turn_away_from_walls(g: SnakeLogic) -> void:
	var rng := RandomNumberGenerator.new()
	for i in g.snakes.size():
		g.queue_turn(i, SnakeAI.choose(g, i, rng))


func test_solo_mode_has_one_snake_and_ends_solo() -> void:
	var g := SnakeLogic.new(_cfg(2), 5, false)
	assert_int(g.snakes.size()).is_equal(1)
	for i in 60:
		g.step()
	assert_int(g.result).is_equal(SnakeLogic.Result.SOLO_OVER)


func test_save_migration_v1_to_v2_keeps_stats() -> void:
	var game_script := load("res://games/snake/scenes/snake_game.gd")
	var g := SaveService.prepare_namespace(
		{"schema": 1, "played": 4, "wins": 2, "best_score": 90},
		2,
		game_script.SAVE_DEFAULTS,
		game_script.migrate_save
	)
	assert_int(int(g["schema"])).is_equal(2)
	assert_int(int(g["wins"])).is_equal(2)
	assert_int(int(g["solo_best"])).is_equal(0)
	assert_bool(g["tutorial_seen"]).is_true()
