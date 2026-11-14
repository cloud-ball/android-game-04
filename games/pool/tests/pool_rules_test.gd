extends GdUnitTestSuite
## Casual 8 rules: the research's 40 fixtures (docs/research/Cue Club pool game design notes/
## eight_ball_rules.md), as hand-built shots plus a few built from real solver shots.

const SOLIDS := PoolState.Group.SOLIDS
const STRIPES := PoolState.Group.STRIPES
const O := PoolRules.Outcome
const F := PoolRules.Foul
const R := PoolRules.Reason


## A PLAY state: player 0 shooting; groups [g0, g1]; balls in `gone` already pocketed.
func _play(g0 := PoolState.Group.NONE, gone: Array = []) -> PoolState:
	var s := PoolState.new_rack(0)
	s.phase = PoolState.Phase.PLAY
	s.ball_in_hand = PoolState.Hand.NONE
	if g0 != PoolState.Group.NONE:
		s.group[0] = g0
		s.group[1] = STRIPES if g0 == SOLIDS else SOLIDS
	for b in gone:
		s.on_table[b] = 0
	return s


func _shot(first: int, rail := true, pocketed: Array = [], off: Array = []) -> PoolShot:
	var s := PoolShot.new()
	s.first_contact = first
	s.rail_after_contact = rail
	s.pocketed = pocketed
	s.off_table = PackedInt32Array(off)
	return s


func _all_solids_gone() -> Array:
	return [1, 2, 3, 4, 5, 6, 7]


# --- break ------------------------------------------------------------------------------------


func test_01_break_pots_a_solid_breaker_continues_table_open() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [[3, 0]]))
	assert_int(r.outcome).is_equal(O.CONTINUE)
	assert_bool(r.state.table_open()).is_true()
	assert_int(r.state.phase).is_equal(PoolState.Phase.PLAY)
	assert_int(r.state.on_table[3]).is_equal(0)


func test_02_break_pots_one_of_each_still_open() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [[3, 0], [12, 5]]))
	assert_int(r.outcome).is_equal(O.CONTINUE)
	assert_bool(r.state.table_open()).is_true()
	assert_bool(r.assigned).is_false()


func test_03_dry_break_passes_the_turn_without_a_foul() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true))
	assert_int(r.outcome).is_equal(O.SWITCH)
	assert_bool(r.foul()).is_false()
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.NONE)
	assert_int(r.state.shooter).is_equal(1)


func test_04_strict_break_needs_four_rail_balls() -> void:
	var weak := _shot(1, true)
	weak.break_rail_balls = 3
	var r := PoolRules.apply_shot(PoolState.new_rack(0), weak, {"strict_break": true})
	assert_bool(r.fouls.has(F.ILLEGAL_BREAK)).is_true()
	var good := _shot(1, true)
	good.break_rail_balls = 4
	r = PoolRules.apply_shot(PoolState.new_rack(0), good, {"strict_break": true})
	assert_bool(r.foul()).is_false()


func test_05_eight_on_the_break_is_respotted_and_breaker_continues() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [[8, 2]]))
	assert_int(r.outcome).is_equal(O.CONTINUE)
	assert_int(r.state.on_table[8]).is_equal(1)
	assert_bool(r.respots.has(8)).is_true()
	assert_int(r.state.phase).is_equal(PoolState.Phase.PLAY)


func test_06_eight_and_scratch_on_the_break_respot_ball_in_hand() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [[8, 2], [0, 4]]))
	assert_int(r.outcome).is_equal(O.SWITCH)
	assert_int(r.state.on_table[8]).is_equal(1)
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.ANYWHERE)
	assert_int(r.state.phase).is_equal(PoolState.Phase.PLAY)


func test_07_break_scratch_keeps_pots_down_table_open() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [[2, 0], [0, 3]]))
	assert_bool(r.fouls.has(F.SCRATCH)).is_true()
	assert_int(r.state.on_table[2]).is_equal(0)
	assert_bool(r.state.table_open()).is_true()
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.ANYWHERE)


func test_08_break_drives_a_stripe_off_the_table() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [], [11]))
	assert_bool(r.fouls.has(F.OBJECT_OFF_TABLE)).is_true()
	assert_bool(r.respots.has(11)).is_true()
	assert_int(r.state.on_table[11]).is_equal(1)
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.ANYWHERE)


func test_09_break_drives_the_eight_off_the_table_is_not_a_loss() -> void:
	var r := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [], [8]))
	assert_int(r.outcome).is_not_equal(O.GAME_OVER)
	assert_int(r.state.on_table[8]).is_equal(1)
	assert_bool(r.foul()).is_true()


func test_10_respot_with_the_foot_spot_taken_goes_towards_the_foot_rail() -> void:
	var sim := CueSim.new()
	var foot := sim.table.hl * 0.5
	sim.place(0, 0.0, -0.5)
	sim.place(3, 0.0, foot)
	PoolRack.spot(sim, 8)
	assert_float(sim.px[8]).is_equal(0.0)
	assert_float(sim.py[8]).is_greater(foot)
	assert_float(sim.py[8] - foot).is_greater_equal(2.0 * sim.p.radius)
	assert_float(sim.py[8] - foot).is_less(2.0 * sim.p.radius + 0.001)


# --- open table ---------------------------------------------------------------------------------


func test_11_first_legal_pot_assigns_groups() -> void:
	var r := PoolRules.apply_shot(_play(), _shot(10, true, [[10, 1]]))
	assert_bool(r.assigned).is_true()
	assert_int(r.state.group[0]).is_equal(STRIPES)
	assert_int(r.state.group[1]).is_equal(SOLIDS)
	assert_int(r.outcome).is_equal(O.CONTINUE)


func test_12_mixed_pot_goes_to_the_first_contacted_group() -> void:
	var r := PoolRules.apply_shot(_play(), _shot(4, true, [[4, 1], [13, 2]]))
	assert_int(r.state.group[0]).is_equal(SOLIDS)
	assert_int(r.outcome).is_equal(O.CONTINUE)


func test_13_take_what_you_make() -> void:
	var r := PoolRules.apply_shot(_play(), _shot(4, true, [[13, 2]]))
	assert_int(r.state.group[0]).is_equal(STRIPES)
	assert_int(r.outcome).is_equal(O.CONTINUE)


func test_14_hitting_the_eight_first_on_an_open_table_is_a_foul() -> void:
	var r := PoolRules.apply_shot(_play(), _shot(8, true))
	assert_bool(r.fouls.has(F.WRONG_BALL)).is_true()
	assert_bool(r.state.table_open()).is_true()
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.ANYWHERE)


func test_15_pot_plus_scratch_open_table_stays_open() -> void:
	var r := PoolRules.apply_shot(_play(), _shot(2, true, [[2, 0], [0, 1]]))
	assert_bool(r.foul()).is_true()
	assert_bool(r.state.table_open()).is_true()
	assert_int(r.state.on_table[2]).is_equal(0)


func test_16_hitting_nothing_is_a_foul() -> void:
	var r := PoolRules.apply_shot(_play(), _shot(-1, true))
	assert_array(Array(r.fouls)).contains([F.NO_CONTACT])


func test_17_no_rail_after_contact_is_a_foul() -> void:
	var r := PoolRules.apply_shot(_play(), _shot(5, false))
	assert_array(Array(r.fouls)).contains([F.NO_RAIL])


func test_18_a_frozen_rail_ball_does_not_count_as_a_rail() -> void:
	# A ball frozen to the right rail (away from the side pocket), pushed along the rail and, in a
	# second shot, pressed straight into it: neither is a new cushion contact (WPA 2.7).
	var sim := CueSim.new()
	var r := sim.p.radius
	var x := sim.table.hw - r
	sim.place(0, x, 0.15)
	sim.place(5, x, 0.35)
	sim.strike(0.0, 1.0, 0.4)
	sim.run_to_rest()
	var along := PoolShot.from_sim(sim)
	assert_int(along.first_contact).is_equal(5)
	assert_bool(along.rail_after_contact).is_false()
	assert_array(Array(PoolRules.apply_shot(_play(), along).fouls)).contains([F.NO_RAIL])
	sim.place(0, x - 0.25, -0.4)
	sim.place(5, x, -0.4)
	sim.strike(1.0, 0.0, 0.3)
	sim.run_to_rest()
	var into := PoolShot.from_sim(sim)
	assert_int(into.first_contact).is_equal(5)
	assert_bool(into.rail_after_contact).is_false()


func test_19_open_table_with_a_group_gone_may_play_the_eight() -> void:
	var s := _play(PoolState.Group.NONE, _all_solids_gone())
	assert_bool(PoolRules.requires_call(s)).is_true()
	s = PoolRules.call_pocket(s, 3)
	var r := PoolRules.apply_shot(s, _shot(8, true, [[8, 3]]))
	assert_int(r.outcome).is_equal(O.GAME_OVER)
	assert_int(r.reason).is_equal(R.WIN)
	assert_int(r.winner).is_equal(0)


# --- assigned table -----------------------------------------------------------------------------


func test_20_own_ball_first_and_potted_continues() -> void:
	var r := PoolRules.apply_shot(_play(SOLIDS), _shot(3, true, [[3, 0]]))
	assert_int(r.outcome).is_equal(O.CONTINUE)


func test_21_potting_only_an_opponent_ball_passes_the_turn() -> void:
	var r := PoolRules.apply_shot(_play(SOLIDS), _shot(3, true, [[12, 0]]))
	assert_int(r.outcome).is_equal(O.SWITCH)
	assert_bool(r.foul()).is_false()
	assert_int(r.state.on_table[12]).is_equal(0)
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.NONE)


func test_22_opponent_ball_first_is_a_foul_even_if_own_ball_drops() -> void:
	var r := PoolRules.apply_shot(_play(SOLIDS), _shot(12, true, [[3, 0]]))
	assert_bool(r.fouls.has(F.WRONG_BALL)).is_true()
	assert_int(r.state.on_table[3]).is_equal(0)
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.ANYWHERE)


func test_23_first_contact_from_the_solver_is_the_first_ball_touched() -> void:
	var sim := CueSim.new()
	var r := sim.p.radius
	sim.place(0, 0.0, -0.5)
	sim.place(3, 0.0, -0.2)
	sim.place(12, 0.0, -0.2 + 2.0 * r + 0.001)  # right behind the 3
	sim.strike(0.0, 1.0, 2.0)
	sim.run_to_rest()
	assert_int(PoolShot.from_sim(sim).first_contact).is_equal(3)


func test_24_object_ball_off_table_is_a_foul_and_respotted() -> void:
	var r := PoolRules.apply_shot(_play(SOLIDS), _shot(3, true, [], [3]))
	assert_bool(r.fouls.has(F.OBJECT_OFF_TABLE)).is_true()
	assert_int(r.state.on_table[3]).is_equal(1)
	assert_bool(r.respots.has(3)).is_true()


func test_25_cue_ball_off_table_gives_ball_in_hand() -> void:
	var r := PoolRules.apply_shot(_play(SOLIDS), _shot(3, true, [], [0]))
	assert_bool(r.fouls.has(F.CUE_OFF_TABLE)).is_true()
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.ANYWHERE)


# --- the 8 --------------------------------------------------------------------------------------


func _on_eight(pocket := 2) -> PoolState:
	return PoolRules.call_pocket(_play(SOLIDS, _all_solids_gone()), pocket)


func test_26_eight_in_the_called_pocket_wins() -> void:
	var r := PoolRules.apply_shot(_on_eight(2), _shot(8, true, [[8, 2]]))
	assert_int(r.reason).is_equal(R.WIN)
	assert_int(r.winner).is_equal(0)
	assert_int(r.state.phase).is_equal(PoolState.Phase.GAME_OVER)


func test_27_eight_in_another_pocket_loses() -> void:
	var r := PoolRules.apply_shot(_on_eight(2), _shot(8, true, [[8, 5]]))
	assert_int(r.reason).is_equal(R.WRONG_POCKET)
	assert_int(r.winner).is_equal(1)


func test_28_eight_with_a_scratch_loses() -> void:
	var r := PoolRules.apply_shot(_on_eight(2), _shot(8, true, [[8, 2], [0, 4]]))
	assert_int(r.reason).is_equal(R.EIGHT_WITH_FOUL)
	assert_int(r.winner).is_equal(1)


func test_29_last_ball_and_the_eight_together_is_an_early_eight() -> void:
	var s := _play(SOLIDS, [1, 2, 3, 4, 5, 6])  # only the 7 left
	var r := PoolRules.apply_shot(s, _shot(7, true, [[7, 1], [8, 2]]))
	assert_int(r.reason).is_equal(R.EARLY_EIGHT)
	assert_int(r.winner).is_equal(1)


func test_30_eight_early_by_combination_loses() -> void:
	var r := PoolRules.apply_shot(_play(SOLIDS), _shot(3, true, [[8, 0]]))
	assert_int(r.reason).is_equal(R.EARLY_EIGHT)


func test_31_eight_after_hitting_the_wrong_ball_first() -> void:
	var r := PoolRules.apply_shot(_on_eight(2), _shot(12, true, [[8, 2]]))
	assert_int(r.reason).is_equal(R.EIGHT_WITH_FOUL)
	var early := PoolRules.apply_shot(_play(SOLIDS), _shot(12, true, [[8, 2]]))
	assert_int(early.reason).is_equal(R.EARLY_EIGHT)  # not cleared outranks the foul


func test_32_scratch_while_on_the_eight_is_a_plain_foul_unless_pro() -> void:
	var r := PoolRules.apply_shot(_on_eight(2), _shot(8, true, [[0, 1]]))
	assert_int(r.outcome).is_equal(O.SWITCH)
	assert_int(r.state.ball_in_hand).is_equal(PoolState.Hand.ANYWHERE)
	var pro := PoolRules.apply_shot(
		_on_eight(2), _shot(8, true, [[0, 1]]), {"scratch_on_8_loses": true}
	)
	assert_int(pro.reason).is_equal(R.SCRATCH_ON_EIGHT)
	assert_int(pro.winner).is_equal(1)


func test_33_eight_off_the_table_loses() -> void:
	var r := PoolRules.apply_shot(_on_eight(2), _shot(8, true, [], [8]))
	assert_int(r.reason).is_equal(R.EIGHT_OFF_TABLE)


func test_34_shot_on_the_eight_without_a_call_is_rejected() -> void:
	var s := _play(SOLIDS, _all_solids_gone())
	var before := s.fingerprint()
	var r := PoolRules.apply_shot(s, _shot(8, true, [[8, 2]]))
	assert_int(r.outcome).is_equal(O.REJECTED)
	assert_str(r.state.fingerprint()).is_equal(before)


func test_35_potting_the_last_group_ball_puts_you_on_the_eight() -> void:
	var s := _play(SOLIDS, [1, 2, 3, 4, 5, 6])
	var r := PoolRules.apply_shot(s, _shot(7, true, [[7, 1]]))
	assert_int(r.outcome).is_equal(O.CONTINUE)
	assert_bool(PoolRules.requires_call(r.state)).is_true()
	assert_array(Array(PoolRules.legal_targets(r.state))).is_equal([8])


# --- meta ---------------------------------------------------------------------------------------


func test_36_twenty_four_shots_without_a_pot_rerack() -> void:
	var s := _play(SOLIDS)
	s.breaker = 1
	var last: PoolRules.Result
	for i in PoolRules.STALEMATE_SHOTS:
		last = PoolRules.apply_shot(s, _shot(3 if s.shooter == 0 else 12, true))
		s = last.state
	assert_int(last.outcome).is_equal(O.RERACK)
	assert_int(s.phase).is_equal(PoolState.Phase.BREAK)
	assert_int(s.shooter).is_equal(1)
	assert_bool(s.table_open()).is_true()


func test_37_stalemate_counter_resets_on_any_pot_even_a_foul() -> void:
	var s := _play(SOLIDS)
	s.shots_without_pot = 20
	var r := PoolRules.apply_shot(s, _shot(12, true, [[3, 0]]))  # wrong ball first, a pot
	assert_bool(r.foul()).is_true()
	assert_int(r.state.shots_without_pot).is_equal(0)


func test_38_rack_is_deterministic_and_apply_shot_is_pure() -> void:
	var a := CueSim.new()
	var b := CueSim.new()
	PoolRack.setup(a, 99)
	PoolRack.setup(b, 99)
	assert_bool(a.px == b.px and a.py == b.py).is_true()
	var s := _play(SOLIDS)
	var before := s.fingerprint()
	var r1 := PoolRules.apply_shot(s, _shot(3, true, [[3, 0]]))
	var r2 := PoolRules.apply_shot(s, _shot(3, true, [[3, 0]]))
	assert_str(s.fingerprint()).is_equal(before)
	assert_str(r1.state.fingerprint()).is_equal(r2.state.fingerprint())


func test_39_balls_are_conserved_over_a_scripted_game() -> void:
	var s := PoolRules.apply_shot(PoolState.new_rack(0), _shot(1, true, [[9, 0]])).state
	var potted := 1
	var script := [[1, [[1, 2]]], [2, [[2, 3]]], [3, []], [10, [[10, 1]]], [4, [[4, 0], [11, 5]]]]
	for step in script:
		var r := PoolRules.apply_shot(s, _shot(step[0], true, step[1]))
		s = r.state
		potted += step[1].size()
		var left := 0
		for b in range(1, 16):
			left += s.on_table[b]
		assert_int(left + potted).is_equal(15)


func test_40_no_group_is_ever_assigned_on_the_break_or_a_foul() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 300:
		var s := _play() if i % 2 == 0 else PoolState.new_rack(0)
		var pots := []
		for b in range(1, 16):
			if b != 8 and rng.randf() < 0.15:
				pots.append([b, rng.randi_range(0, 5)])
		if rng.randf() < 0.3:
			pots.append([0, 1])
		var fc := rng.randi_range(-1, 15)
		var r := PoolRules.apply_shot(s, _shot(fc, rng.randf() < 0.5, pots))
		if s.phase == PoolState.Phase.BREAK or r.foul():
			assert_bool(r.assigned).is_false()
		var counts := [r.outcome == O.CONTINUE, r.outcome == O.SWITCH, r.outcome == O.GAME_OVER]
		assert_int(counts.count(true) + int(r.outcome == O.RERACK)).is_equal(1)
		if not r.state.table_open():
			assert_int(r.state.group[0]).is_not_equal(r.state.group[1])
