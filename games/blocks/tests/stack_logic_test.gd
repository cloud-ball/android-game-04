extends GdUnitTestSuite
## Stack Drop rules: bag, kick data + behaviour, movement, gravity, lock delay, clears, scoring,
## hold, garbage, top-out and bit-exact replays.

const W := StackState.W
const H := StackState.H

## Reference kick offsets (+y up), one entry per rotation case.
const EXPECTED_STANDARD := {
	"0>R": [[0, 0], [-1, 0], [-1, 1], [0, -2], [-1, -2]],
	"R>0": [[0, 0], [1, 0], [1, -1], [0, 2], [1, 2]],
	"R>2": [[0, 0], [1, 0], [1, -1], [0, 2], [1, 2]],
	"2>R": [[0, 0], [-1, 0], [-1, 1], [0, -2], [-1, -2]],
	"2>L": [[0, 0], [1, 0], [1, 1], [0, -2], [1, -2]],
	"L>2": [[0, 0], [-1, 0], [-1, -1], [0, 2], [-1, 2]],
	"L>0": [[0, 0], [-1, 0], [-1, -1], [0, 2], [-1, 2]],
	"0>L": [[0, 0], [1, 0], [1, 1], [0, -2], [1, -2]],
}
const EXPECTED_LONG := {
	"0>R": [[0, 0], [-2, 0], [1, 0], [-2, -1], [1, 2]],
	"R>0": [[0, 0], [2, 0], [-1, 0], [2, 1], [-1, -2]],
	"R>2": [[0, 0], [-1, 0], [2, 0], [-1, 2], [2, -1]],
	"2>R": [[0, 0], [1, 0], [-2, 0], [1, -2], [-2, 1]],
	"2>L": [[0, 0], [2, 0], [-1, 0], [2, 1], [-1, -2]],
	"L>2": [[0, 0], [-2, 0], [1, 0], [-2, -1], [1, 2]],
	"L>0": [[0, 0], [1, 0], [-2, 0], [1, -2], [-2, 1]],
	"0>L": [[0, 0], [-1, 0], [2, 0], [-1, 2], [2, -1]],
}
const ROT := {"0": 0, "R": 1, "2": 2, "L": 3}


func _act(s: StackState, type: String, extra := {}) -> StackState:
	var a := {"type": type}
	a.merge(extra)
	return StackLogic.reduce(s, a)


## A state with a chosen active shard at a chosen place (board empty unless given).
func _with_shard(kind: int, rot := 0, x := 3, y := 2) -> StackState:
	var s := StackLogic.new_game(7)
	s.kind = kind
	s.rot = rot
	s.px = x
	s.py = y
	s.lowest_y = y
	return s


func _fill_row(s: StackState, y: int, gap := -1) -> void:
	for x in W:
		s.board[y * W + x] = 0 if x == gap else 1


# --- bag ---------------------------------------------------------------------------------


func test_seven_bag_never_repeats_within_a_bag() -> void:
	var s := StackLogic.new_game(12345)
	var seen: Array[int] = [s.kind]
	while seen.size() < 70:
		s = _act(s, "hard")
		s.board.fill(0)  # keep the board empty so the game never tops out
		seen.append(s.kind)
	for b in 10:
		var bag := seen.slice(b * 7, b * 7 + 7)
		bag.sort()
		assert_array(bag).is_equal([0, 1, 2, 3, 4, 5, 6])


func test_preview_has_three_or_more_shards() -> void:
	assert_int(StackLogic.new_game(3).queue.size()).is_greater_equal(StackLogic.PREVIEW)


# --- kick data: one case per rotation transition ----------------------------------------


func test_standard_kick_table_matches_spec() -> void:
	_check_table(ShardData.raw_kick_table()["standard"], EXPECTED_STANDARD)


func test_long_kick_table_matches_spec() -> void:
	_check_table(ShardData.raw_kick_table()["long"], EXPECTED_LONG)


func _check_table(actual: Dictionary, expected: Dictionary) -> void:
	assert_int(actual.size()).is_equal(8)
	for key in expected:
		var tests: Array = actual[key]
		assert_int(tests.size()).override_failure_message(key).is_equal(5)
		for i in 5:
			var want := Vector2i(expected[key][i][0], -expected[key][i][1])
			assert_that(tests[i]).override_failure_message("%s test %d" % [key, i]).is_equal(want)


func test_kick_lookup_covers_every_transition() -> void:
	for key in EXPECTED_STANDARD:
		var parts: PackedStringArray = key.split(">")
		var a: int = ROT[parts[0]]
		var b: int = ROT[parts[1]]
		assert_int(ShardData.kicks(2, a, b).size()).is_equal(5)
		assert_int(ShardData.kicks(ShardData.LONG, a, b).size()).is_equal(5)
	assert_int(ShardData.kicks(ShardData.SQUARE, 0, 1).size()).is_equal(1)


# --- kick behaviour ------------------------------------------------------------------------


func test_tee_rotates_off_the_left_wall_with_a_kick() -> void:
	# Tee in state R (nub right) with its stem in column 0: turning back to state 0 needs
	# columns -1..1, so the plain rotation fails and the second kick (+1, 0) is used.
	var s := _with_shard(2, 1, -1, 6)
	assert_bool(StackLogic.fits(s, 2, 1, -1, 6)).is_true()
	s = _act(s, "ccw")
	assert_int(s.rot).is_equal(0)
	assert_int(s.px).is_equal(0)
	var rotations := s.events.filter(func(e: Dictionary) -> bool: return e.type == "rotate")
	assert_int(rotations[0].kick).is_equal(1)


func test_long_rotates_next_to_the_right_wall_with_a_kick() -> void:
	# Long shard vertical (state R) against the right wall; rotating to 2 needs a kick.
	var s := _with_shard(ShardData.LONG, 1, W - 3, 8)
	s = _act(s, "cw")
	assert_int(s.rot).is_equal(2)
	for c in StackLogic.shard_cells(s.kind, s.rot, s.px, s.py):
		assert_bool(c.x >= 0 and c.x < W).is_true()
	var rotations := s.events.filter(func(e: Dictionary) -> bool: return e.type == "rotate")
	assert_int(rotations.size()).is_equal(1)
	assert_int(rotations[0].kick).is_greater(0)


func test_rotation_fails_cleanly_when_no_kick_fits() -> void:
	var s := _with_shard(ShardData.LONG, 0, 2, H - 4)
	for y in range(H - 6, H):
		_fill_row(s, y, -1)
	for x in range(2, 6):
		s.board[(H - 3) * W + x] = 0  # a one-row tunnel exactly as long as the shard
	s.py = H - 4
	var after := _act(s, "cw")
	assert_int(after.rot).is_equal(0)
	assert_bool(after.events.is_empty()).is_true()


func test_square_never_changes_cells_when_rotated() -> void:
	var s := _with_shard(ShardData.SQUARE)
	var before := StackLogic.shard_cells(s.kind, s.rot, s.px, s.py)
	s = _act(s, "cw")
	assert_array(StackLogic.shard_cells(s.kind, s.rot, s.px, s.py)).contains_exactly_in_any_order(
		before
	)


# --- movement, gravity, locking ------------------------------------------------------------


func test_walls_stop_sideways_moves() -> void:
	var s := _with_shard(2, 0, 0, 5)
	s = _act(s, "left")
	assert_int(s.px).is_equal(0)
	for i in 10:
		s = _act(s, "right")
	assert_int(s.px).is_equal(W - 3)


func test_gravity_moves_one_row_per_second_at_level_one() -> void:
	var s := _with_shard(2, 0, 3, 2)
	for i in 60:
		s = _act(s, "tick", {"dt": 1.0 / 60.0})
	assert_int(s.py).is_equal(3)


func test_hard_drop_lands_on_ghost_scores_and_locks() -> void:
	var s := _with_shard(2, 0, 3, 2)
	var ghost := StackLogic.ghost_y(s)
	var rows := ghost - s.py
	var kind := s.kind
	s = _act(s, "hard")
	assert_int(s.score).is_equal(rows * 2)
	assert_int(s.cell(4, ghost)).is_equal(kind + 1)
	assert_int(s.pieces).is_equal(1)


func test_lock_delay_is_half_a_second() -> void:
	var s := _with_shard(2, 0, 3, H - 2)
	for i in 29:
		s = _act(s, "tick", {"dt": 1.0 / 60.0})
	assert_int(s.pieces).is_equal(0)
	for i in 2:
		s = _act(s, "tick", {"dt": 1.0 / 60.0})
	assert_int(s.pieces).is_equal(1)


func test_moves_reset_lock_delay_but_only_fifteen_times() -> void:
	var s := _with_shard(2, 0, 3, H - 2)
	var frames := 0
	while s.pieces == 0 and frames < 2000:
		s = _act(s, "tick", {"dt": 1.0 / 60.0})
		frames += 1
		if frames % 20 == 0:
			s = _act(s, "left" if (frames / 20) % 2 == 0 else "right")
	# 15 resets of ~20 frames each, then the remaining 30-frame delay.
	assert_int(s.pieces).is_equal(1)
	assert_int(frames).is_between(15 * 20, 15 * 20 + 40)


# --- clears, scoring, levels -------------------------------------------------------------


func test_single_and_quad_clear_scores_by_level() -> void:
	var s := _with_shard(ShardData.LONG, 1, 6, H - 4)  # vertical long shard in column 8
	for y in range(H - 4, H):
		_fill_row(s, y, 8)
	s.level = 2
	s = _act(s, "hard")
	assert_int(s.lines).is_equal(4)
	assert_int(s.score).is_equal(800 * 2)
	assert_int(s.outgoing).is_equal(4)
	(
		assert_int(s.events.filter(func(e: Dictionary) -> bool: return e.type == "clear")[0].count)
		. is_equal(4)
	)


func test_level_rises_every_ten_lines() -> void:
	var s := StackLogic.new_game(9, 1)
	s.lines = 9
	s = _with_line_clear(s)
	assert_int(s.lines).is_equal(10)
	assert_int(s.level).is_equal(2)


func _with_line_clear(s: StackState) -> StackState:
	s.kind = ShardData.LONG
	s.rot = 0
	s.px = 0
	s.py = H - 2
	_fill_row(s, H - 1, -1)
	for x in 4:
		s.board[(H - 1) * W + x] = 0
	s.py = H - 2  # long shard (row 1 of its box) sits on row H-1
	return _act(s, "hard")


# --- hold ------------------------------------------------------------------------------------


func test_hold_once_per_shard() -> void:
	var s := StackLogic.new_game(21)
	var first := s.kind
	var next := s.queue[0]
	s = _act(s, "hold")
	assert_int(s.hold).is_equal(first)
	assert_int(s.kind).is_equal(next)
	var again := _act(s, "hold")
	assert_int(again.kind).is_equal(next)  # second hold ignored
	s = _act(s, "hard")
	s = _act(s, "hold")
	assert_int(s.kind).is_equal(first)  # swapped back after a lock


# --- garbage and top-out ---------------------------------------------------------------------


func test_garbage_arrives_on_next_lock_with_one_gap() -> void:
	var s := StackLogic.new_game(5)
	s = _act(s, "garbage", {"rows": 2})
	assert_int(s.pending_garbage).is_equal(2)
	s = _act(s, "hard")
	for y in [H - 1, H - 2]:
		var holes := 0
		for x in W:
			if s.cell(x, y) == 0:
				holes += 1
		assert_int(holes).override_failure_message("row %d" % y).is_less_equal(1)
	assert_int(s.pending_garbage).is_equal(0)


func test_clearing_lines_cancels_incoming_garbage() -> void:
	var s := _with_shard(ShardData.LONG, 1, 6, H - 4)
	for y in range(H - 4, H):
		_fill_row(s, y, 8)
	s.pending_garbage = 3
	s = _act(s, "hard")
	assert_int(s.pending_garbage).is_equal(0)
	assert_int(s.outgoing).is_equal(1)  # 4 sent - 3 cancelled


func test_blocked_spawn_ends_the_game() -> void:
	var s := StackLogic.new_game(4)
	for y in range(0, H):
		_fill_row(s, y, 0)
	s.board[0] = 0
	s.kind = ShardData.SQUARE
	s.px = 3
	s.py = 0
	for x in range(4, 6):
		for y in 2:
			s.board[y * W + x] = 0
	s = _act(s, "hard")
	assert_bool(s.over).is_true()


func test_reduce_never_mutates_its_input() -> void:
	var s := StackLogic.new_game(77)
	var print_before := s.fingerprint()
	StackLogic.reduce(s, {"type": "hard"})
	assert_int(s.fingerprint()).is_equal(print_before)


# --- replays -------------------------------------------------------------------------------


func test_replays_are_bit_exact() -> void:
	assert_array(_replay(2026)).is_equal(_replay(2026))
	assert_array(_replay(2026)).is_not_equal(_replay(2027))


func _replay(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var kinds := ["left", "right", "cw", "ccw", "soft", "hard", "hold"]
	var s := StackLogic.new_game(seed_value)
	var prints := []
	for i in 600:
		var a := {"type": "tick", "dt": 1.0 / 60.0}
		if i % 7 == 0:
			a = {"type": kinds[rng.randi_range(0, kinds.size() - 1)]}
		if i % 97 == 0:
			a = {"type": "garbage", "rows": 1}
		s = StackLogic.reduce(s, a)
		prints.append(s.fingerprint())
	return prints
