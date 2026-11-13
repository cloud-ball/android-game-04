class_name PoolRules
extends RefCounted
## "Casual 8" rules (docs/research/Cue Club pool game design.md, rules R1-R20): WPA 2025 8-ball
## with every option fixed. Only the 8's pocket is called; ball in hand anywhere after every foul
## (break too); the 8 on the break is re-spotted; the table stays open after the break; groups go
## to the first legal pot (first-contacted group wins a mixed pot); 24 shots without a pot re-rack.
## apply_shot() is pure: it reads a state and a PoolShot and returns a PoolResult with a new state.
## Evaluation order matters: "group cleared" is snapshotted at shot start, so the last group ball
## plus the 8 on the same stroke is an early 8, not a win.

enum Foul {SCRATCH, CUE_OFF_TABLE, NO_CONTACT, WRONG_BALL, NO_RAIL, OBJECT_OFF_TABLE, ILLEGAL_BREAK}
enum Outcome { CONTINUE, SWITCH, GAME_OVER, RERACK, REJECTED }
enum Reason {
	NONE, WIN, EIGHT_OFF_TABLE, EARLY_EIGHT, EIGHT_WITH_FOUL, WRONG_POCKET, SCRATCH_ON_EIGHT
}

const STALEMATE_SHOTS := 24
const FOUL_TEXT := {
	Foul.SCRATCH: "Scratch - the cue ball went in",
	Foul.CUE_OFF_TABLE: "The cue ball left the table",
	Foul.NO_CONTACT: "The cue ball hit nothing",
	Foul.WRONG_BALL: "Wrong ball hit first",
	Foul.NO_RAIL: "No ball reached a cushion",
	Foul.OBJECT_OFF_TABLE: "A ball left the table",
	Foul.ILLEGAL_BREAK: "Weak break",
}


class Result:
	extends RefCounted
	var outcome := 0
	var fouls := PackedInt32Array()
	var reason := 0
	var winner := -1
	var assigned := false
	## Balls to put back on the table (the game places them with PoolRack.spot).
	var respots := PackedInt32Array()
	var state: PoolState

	func foul() -> bool:
		return not fouls.is_empty()


## Options: strict_break (4 balls to a rail), scratch_on_8_loses (Pro modes; off by default).
static func apply_shot(s: PoolState, shot: PoolShot, opts := {}) -> Result:
	var r := Result.new()
	var st := s.copy()
	r.state = st
	if s.phase == PoolState.Phase.GAME_OVER:
		r.outcome = Outcome.REJECTED
		return r
	var cleared := cleared_at_start(s)
	var breaking := s.phase == PoolState.Phase.BREAK
	if requires_call(s) and s.called_pocket < 0:
		r.outcome = Outcome.REJECTED  # the UI must collect the 8's pocket first; no foul
		r.state = s.copy()
		return r
	# 1. What went where.
	var pots := PackedInt32Array()
	for p in shot.pocketed:
		if p[0] != 0 and p[0] != 8:
			pots.append(p[0])
	var eight_down := shot.potted(8)
	var eight_off := shot.off_table.has(8)
	var cue_potted := shot.potted(0)
	var cue_off := shot.off_table.has(0)
	# 2. Fouls.
	if cue_potted:
		r.fouls.append(Foul.SCRATCH)
	elif cue_off:
		r.fouls.append(Foul.CUE_OFF_TABLE)
	var fc := shot.first_contact
	if fc == -1:
		r.fouls.append(Foul.NO_CONTACT)
	elif not breaking and _wrong_first(s, fc, cleared):
		r.fouls.append(Foul.WRONG_BALL)
	if not breaking and pots.is_empty() and not eight_down and fc != -1:
		if not shot.rail_after_contact:
			r.fouls.append(Foul.NO_RAIL)
	for b in shot.off_table:
		if b != 0:
			r.fouls.append(Foul.OBJECT_OFF_TABLE)
			break
	var foul := r.foul()
	if foul:
		st.fouls[s.shooter] += 1
	# 3. The break.
	if breaking:
		return _break(s, st, r, shot, pots, eight_down or eight_off, foul, opts)
	# 4. The 8 went down or off: game over.
	if eight_down or eight_off:
		_remove_pocketed(st, shot)
		st.phase = PoolState.Phase.GAME_OVER
		r.outcome = Outcome.GAME_OVER
		if eight_off:
			r.reason = Reason.EIGHT_OFF_TABLE
		elif not cleared:
			r.reason = Reason.EARLY_EIGHT
		elif foul:
			r.reason = Reason.EIGHT_WITH_FOUL
		elif shot.pocket_of(8) != s.called_pocket:
			r.reason = Reason.WRONG_POCKET
		else:
			r.reason = Reason.WIN
		r.winner = s.shooter if r.reason == Reason.WIN else 1 - s.shooter
		st.winner = r.winner
		st.end_reason = r.reason
		return r
	if bool(opts.get("scratch_on_8_loses", false)) and cleared and (cue_potted or cue_off):
		_remove_pocketed(st, shot)
		st.phase = PoolState.Phase.GAME_OVER
		r.outcome = Outcome.GAME_OVER
		r.reason = Reason.SCRATCH_ON_EIGHT
		r.winner = 1 - s.shooter
		st.winner = r.winner
		st.end_reason = r.reason
		return r
	# 5. Re-spot off-table object balls; pocketed balls leave.
	_respot_off_table(st, r, shot)
	_remove_pocketed(st, shot)
	st.called_pocket = -1
	# 9 (early). Stalemate counter: any object-ball pot resets it, even on a foul.
	if pots.is_empty():
		st.shots_without_pot = s.shots_without_pot + 1
	else:
		st.shots_without_pot = 0
	# 6. Foul: opponent, ball in hand anywhere, groups unchanged.
	if foul:
		_switch(st, PoolState.Hand.ANYWHERE)
		r.outcome = Outcome.SWITCH
		return _stalemate(st, r)
	# 7. Open table: assign groups on the first legal pot.
	if s.table_open():
		if pots.is_empty():
			_switch(st, PoolState.Hand.NONE)
			r.outcome = Outcome.SWITCH
			return _stalemate(st, r)
		var g := _assign_group(s, fc, pots, cleared)
		st.group[s.shooter] = g
		st.group[1 - s.shooter] = (
			PoolState.Group.STRIPES if g == PoolState.Group.SOLIDS else PoolState.Group.SOLIDS
		)
		r.assigned = true
		if _any_in(pots, g):
			st.ball_in_hand = PoolState.Hand.NONE
			r.outcome = Outcome.CONTINUE
		else:
			_switch(st, PoolState.Hand.NONE)
			r.outcome = Outcome.SWITCH
		return _stalemate(st, r)
	# 8. Assigned table: continue on any own-group pot.
	if _any_in(pots, s.group[s.shooter]):
		st.ball_in_hand = PoolState.Hand.NONE
		r.outcome = Outcome.CONTINUE
	else:
		_switch(st, PoolState.Hand.NONE)
		r.outcome = Outcome.SWITCH
	return _stalemate(st, r)


## Shot-start snapshot: is the shooter on the 8? (Open table: if either group is already empty
## the shooter may claim it and play the 8 - WPA 4.4.)
static func cleared_at_start(s: PoolState) -> bool:
	if s.table_open():
		return s.left_in(PoolState.Group.SOLIDS) == 0 or s.left_in(PoolState.Group.STRIPES) == 0
	return s.left_in(s.group[s.shooter]) == 0


static func requires_call(s: PoolState) -> bool:
	return s.phase == PoolState.Phase.PLAY and cleared_at_start(s)


## Calls the 8's pocket for the next shot (returns a new state).
static func call_pocket(s: PoolState, pocket: int) -> PoolState:
	var st := s.copy()
	st.called_pocket = pocket
	return st


## Which balls the shooter may legally hit first right now (for the aim line and the CPU).
static func legal_targets(s: PoolState) -> PackedInt32Array:
	var out := PackedInt32Array()
	var on_eight := cleared_at_start(s)
	for b in range(1, 16):
		if s.on_table[b] != 1:
			continue
		if s.phase == PoolState.Phase.BREAK:
			out.append(b)
		elif on_eight:
			if b == 8:
				out.append(b)
		elif s.table_open():
			if b != 8:
				out.append(b)
		elif PoolState.group_of(b) == s.group[s.shooter]:
			out.append(b)
	return out


static func _wrong_first(s: PoolState, fc: int, cleared: bool) -> bool:
	if cleared:
		return fc != 8
	if s.table_open():
		return fc == 8
	return PoolState.group_of(fc) != s.group[s.shooter]


static func _break(
	s: PoolState,
	st: PoolState,
	r: Result,
	shot: PoolShot,
	pots: PackedInt32Array,
	eight_gone: bool,
	foul: bool,
	opts: Dictionary
) -> Result:
	_remove_pocketed(st, shot)
	if eight_gone:
		st.on_table[8] = 1
		r.respots.append(8)
	_respot_off_table(st, r, shot)
	st.phase = PoolState.Phase.PLAY
	st.shots_without_pot = 0 if not pots.is_empty() else s.shots_without_pot
	if foul:
		_switch(st, PoolState.Hand.ANYWHERE)
		r.outcome = Outcome.SWITCH
	elif not pots.is_empty() or eight_gone:
		st.ball_in_hand = PoolState.Hand.NONE
		r.outcome = Outcome.CONTINUE
	else:
		if bool(opts.get("strict_break", false)) and shot.break_rail_balls < 4:
			r.fouls.append(Foul.ILLEGAL_BREAK)
		_switch(st, PoolState.Hand.NONE)
		r.outcome = Outcome.SWITCH
	return r


static func _assign_group(s: PoolState, fc: int, pots: PackedInt32Array, cleared: bool) -> int:
	if cleared:
		# Temporary claim of the empty group (the shooter is on the 8 with it).
		return (
			PoolState.Group.SOLIDS
			if s.left_in(PoolState.Group.SOLIDS) == 0
			else PoolState.Group.STRIPES
		)
	var first := PoolState.group_of(fc)
	if _any_in(pots, first):
		return first
	return PoolState.group_of(pots[0])


static func _any_in(pots: PackedInt32Array, g: int) -> bool:
	for b in pots:
		if PoolState.group_of(b) == g:
			return true
	return false


static func _remove_pocketed(st: PoolState, shot: PoolShot) -> void:
	for p in shot.pocketed:
		if p[0] != 0:
			st.on_table[p[0]] = 0


static func _respot_off_table(st: PoolState, r: Result, shot: PoolShot) -> void:
	for b in shot.off_table:
		if b != 0 and b != 8:
			st.on_table[b] = 1
			r.respots.append(b)


static func _switch(st: PoolState, hand: int) -> void:
	st.shooter = 1 - st.shooter
	st.ball_in_hand = hand


static func _stalemate(st: PoolState, r: Result) -> Result:
	if st.shots_without_pot < STALEMATE_SHOTS:
		return r
	var fresh := PoolState.new_rack(st.breaker)
	fresh.fouls = st.fouls
	r.state = fresh
	r.outcome = Outcome.RERACK
	r.respots.clear()
	return r
