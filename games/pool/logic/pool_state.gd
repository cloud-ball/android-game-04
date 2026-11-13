class_name PoolState
extends RefCounted
## Casual 8 game state (plain data; PoolRules.apply_shot returns a new one, never mutates this).
## Balls: 0 cue, 1-7 solids, 8, 9-15 stripes. Players 0 (human) and 1 (CPU).

enum Phase { BREAK, PLAY, GAME_OVER }
enum Group { NONE, SOLIDS, STRIPES }
enum Hand { NONE, KITCHEN, ANYWHERE }

var phase := Phase.BREAK
var shooter := 0
var breaker := 0
## group[player]; both NONE while the table is open.
var group := PackedInt32Array([Group.NONE, Group.NONE])
## on_table[ball] for object balls 1..15 (index 0 unused).
var on_table := PackedByteArray()
var ball_in_hand := Hand.KITCHEN
## Pocket called for the 8 (-1 = none); required before any shot on the 8.
var called_pocket := -1
var shots_without_pot := 0
var fouls := PackedInt32Array([0, 0])
var winner := -1
var end_reason := 0


static func new_rack(first_breaker := 0) -> PoolState:
	var s := PoolState.new()
	s.on_table.resize(16)
	for b in range(1, 16):
		s.on_table[b] = 1
	s.breaker = first_breaker
	s.shooter = first_breaker
	return s


func copy() -> PoolState:
	var s := PoolState.new()
	s.phase = phase
	s.shooter = shooter
	s.breaker = breaker
	s.group = group.duplicate()
	s.on_table = on_table.duplicate()
	s.ball_in_hand = ball_in_hand
	s.called_pocket = called_pocket
	s.shots_without_pot = shots_without_pot
	s.fouls = fouls.duplicate()
	s.winner = winner
	s.end_reason = end_reason
	return s


func table_open() -> bool:
	return group[0] == Group.NONE


static func group_of(ball: int) -> int:
	if ball >= 1 and ball <= 7:
		return Group.SOLIDS
	if ball >= 9 and ball <= 15:
		return Group.STRIPES
	return Group.NONE


func left_in(g: int) -> int:
	var n := 0
	for b in range(1, 16):
		if on_table[b] == 1 and group_of(b) == g:
			n += 1
	return n


func fingerprint() -> String:
	return var_to_str(
		[
			phase,
			shooter,
			breaker,
			group,
			on_table,
			ball_in_hand,
			called_pocket,
			shots_without_pot,
			fouls,
			winner,
			end_reason
		]
	)
