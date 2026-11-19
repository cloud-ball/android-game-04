extends GdUnitTestSuite
## Rush rules: first in the cup wins, same-tick ties, stroke cap, water, all-out holes, match
## winner with tie-break, draws, and hole draws.


func _match() -> RushMatch:
	var m := RushMatch.new(
		PackedStringArray(["You", "Ana", "Bo", "Cy"]), PackedInt32Array([0, 1, 2])
	)
	m.start_hole(3)
	return m


func test_first_ball_in_wins_the_hole_and_closes_it() -> void:
	var m := _match()
	m.shot_taken(1)
	m.shot_taken(0)
	assert_int(m.balls_holed([[1, 2]])).is_equal(1)
	assert_bool(m.hole_over()).is_true()
	assert_bool(m.can_shoot(0)).is_false()
	assert_int(m.wins[1]).is_equal(1)
	assert_int(m.balls_holed([[0, 0]])).is_equal(-1)  # later drops do not win
	assert_int(m.wins[0]).is_equal(0)


func test_same_tick_drops_are_ordered_by_substep_then_strokes_then_player() -> void:
	var m := _match()
	m.shot_taken(2)
	m.shot_taken(3)
	assert_int(m.balls_holed([[3, 3], [2, 1]])).is_equal(2)  # earlier substep
	var n := _match()
	n.shot_taken(0)
	n.ball_rested(0)
	n.shot_taken(0)  # player 0 on stroke 2
	n.shot_taken(1)  # player 1 on stroke 1
	assert_int(n.balls_holed([[0, 2], [1, 2]])).is_equal(1)  # fewer strokes
	var o := _match()
	o.shot_taken(3)
	o.shot_taken(2)
	assert_int(o.balls_holed([[3, 1], [2, 1]])).is_equal(2)  # then player order


func test_stroke_cap_takes_a_player_out() -> void:
	var m := _match()
	for k in 6:  # par 3 + 3
		assert_bool(m.can_shoot(0)).is_true()
		m.shot_taken(0)
		m.ball_rested(0)
	assert_int(m.state[0]).is_equal(RushMatch.State.OUT)
	assert_bool(m.can_shoot(0)).is_false()


func test_water_costs_a_stroke() -> void:
	var m := _match()
	m.shot_taken(0)
	m.add_penalty(0)
	m.ball_rested(0)
	assert_int(m.strokes[0]).is_equal(2)
	assert_int(m.total[0]).is_equal(2)
	assert_bool(m.can_shoot(0)).is_true()


func test_a_hole_where_everyone_is_out_has_no_winner() -> void:
	var m := _match()
	for i in 4:
		for k in 6:
			m.shot_taken(i)
			m.ball_rested(i)
	assert_bool(m.hole_over()).is_true()
	assert_int(m.hole_winner).is_equal(-1)


func test_match_winner_most_holes_then_fewest_strokes_and_draws() -> void:
	var m := _match()
	m.wins = PackedInt32Array([1, 1, 1, 0])
	m.total = PackedInt32Array([9, 8, 10, 7])
	assert_int(m.winner()).is_equal(1)
	assert_that(Array(m.standings())).is_equal([1, 0, 2, 3])
	m.total = PackedInt32Array([8, 8, 10, 7])
	assert_int(m.winner()).is_equal(-1)  # exact tie for first


func test_three_holes_then_the_match_ends() -> void:
	var m := _match()
	assert_bool(m.next_hole()).is_true()
	assert_bool(m.next_hole()).is_true()
	assert_bool(m.next_hole()).is_false()
	assert_bool(m.match_over()).is_true()


func test_hole_draws_are_distinct_and_seeded() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 5
	b.seed = 5
	var h := RushMatch.pick_holes(9, 3, a)
	assert_that(Array(h)).is_equal(Array(RushMatch.pick_holes(9, 3, b)))
	assert_int(h.size()).is_equal(3)
	assert_bool(h[0] != h[1] and h[1] != h[2] and h[0] != h[2]).is_true()
