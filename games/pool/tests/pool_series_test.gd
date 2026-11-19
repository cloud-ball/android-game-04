extends GdUnitTestSuite
## PoolSeries: single rack vs best of 3, alternating breaks, runs and pot rate.


func test_single_rack_ends_after_one_frame() -> void:
	var s := PoolSeries.new("vs")
	assert_int(s.breaker()).is_equal(0)
	assert_bool(s.record_frame(1)).is_true()
	assert_int(s.winner()).is_equal(1)


func test_best_of_three_alternates_breaks_and_needs_two_frames() -> void:
	var s := PoolSeries.new("bo3")
	assert_bool(s.record_frame(0)).is_false()
	assert_int(s.frame_no).is_equal(2)
	assert_int(s.breaker()).is_equal(1)
	assert_int(s.winner()).is_equal(-1)
	assert_bool(s.record_frame(1)).is_false()
	assert_int(s.breaker()).is_equal(0)
	assert_bool(s.record_frame(1)).is_true()
	assert_int(s.winner()).is_equal(1)
	assert_int(s.frames[0]).is_equal(1)
	assert_int(s.frames[1]).is_equal(2)


func test_runs_and_pot_rate() -> void:
	var s := PoolSeries.new("vs")
	s.record_shot(0, 1, false)
	s.record_shot(0, 2, false)
	s.record_shot(0, 1, false)
	s.record_shot(0, 0, false)  # miss ends the run
	s.record_shot(0, 1, true)  # a pot on a foul does not count
	s.record_shot(0, 1, false)
	assert_int(s.best_run[0]).is_equal(3)
	assert_int(s.run[0]).is_equal(1)
	assert_int(s.balls[0]).is_equal(6)
	assert_float(s.pot_rate(0)).is_equal_approx(4.0 / 6.0, 1e-6)
	assert_float(s.pot_rate(1)).is_equal(0.0)


func test_save_schema_1_gains_the_mode_and_keeps_counts() -> void:
	var game_script: GDScript = load("res://games/pool/scenes/pool_game.gd")
	var old := {"schema": 1, "played": 4, "wins": 3, "losses": 1, "difficulty": "hard"}
	var g := SaveService.prepare_namespace(
		old, game_script.SAVE_SCHEMA, game_script.SAVE_DEFAULTS, game_script.migrate_save
	)
	assert_int(int(g["schema"])).is_equal(2)
	assert_str(str(g["mode"])).is_equal("vs")
	assert_int(int(g["wins"])).is_equal(3)
	assert_str(str(g["difficulty"])).is_equal("hard")
