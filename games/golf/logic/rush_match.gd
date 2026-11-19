class_name RushMatch
extends RefCounted
## Rush rules (pure, no nodes): everyone plays the same hole at once as ghost balls. The first
## ball in the cup wins the hole; balls that drop in the same display tick are ordered by the
## substep they dropped in, then by fewer strokes, then by player order. A hole also ends when
## nobody can play on (everyone holed or out). Water costs a stroke. Reaching par + CAP_OVER_PAR
## strokes without holing takes a player out of that hole. A match is HOLES holes: most holes won
## takes it, ties go to the fewest total strokes, and an exact tie is a draw (winner -1).
## Plan: docs/plans/2026-11-19-fairway-flick-complete.md (step E2).

enum State { READY, MOVING, HOLED, OUT }

const HOLES := 3
const CAP_OVER_PAR := 3

var names: PackedStringArray
var holes: PackedInt32Array  # indices into the world's hole list, in play order
var hole_number := 0  # 0-based index into `holes`
var par := 3
var strokes := PackedInt32Array()  # this hole
var total := PackedInt32Array()  # whole match
var wins := PackedInt32Array()
var state := PackedInt32Array()
var hole_winner := -1


func _init(player_names: PackedStringArray, hole_order: PackedInt32Array) -> void:
	names = player_names
	holes = hole_order
	var n := names.size()
	# (Packed arrays are values: resize each one directly, not through a loop variable.)
	strokes.resize(n)
	total.resize(n)
	wins.resize(n)
	state.resize(n)
	total.fill(0)
	wins.fill(0)


## Draws `count` different holes out of `available` (seeded).
static func pick_holes(available: int, count: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var pool := PackedInt32Array()
	for i in available:
		pool.append(i)
	var out := PackedInt32Array()
	for k in mini(count, available):
		var j := rng.randi_range(0, pool.size() - 1)
		out.append(pool[j])
		pool.remove_at(j)
	return out


func start_hole(hole_par: int) -> void:
	par = hole_par
	hole_winner = -1
	strokes.fill(0)
	state.fill(State.READY)


func players() -> int:
	return names.size()


func can_shoot(i: int) -> bool:
	return hole_winner < 0 and state[i] == State.READY


func shot_taken(i: int) -> void:
	strokes[i] += 1
	total[i] += 1
	state[i] = State.MOVING


## The ball stopped on the course (or was put back after water: call add_penalty first).
func ball_rested(i: int) -> void:
	if state[i] != State.MOVING:
		return
	state[i] = State.OUT if strokes[i] >= par + CAP_OVER_PAR else State.READY


func add_penalty(i: int) -> void:
	strokes[i] += 1
	total[i] += 1


## Everyone who dropped during one display tick, as [player, substep] pairs; the first wins the
## hole if it is still open. Returns the winner of this tick (or -1).
func balls_holed(drops: Array) -> int:
	var first := -1
	var best_sub := 1 << 30
	for d: Array in drops:
		var i: int = d[0]
		var sub: int = d[1]
		state[i] = State.HOLED
		var earlier := sub < best_sub
		var same_tie := sub == best_sub and first >= 0
		if (
			earlier
			or (
				same_tie
				and (strokes[i] < strokes[first] or (strokes[i] == strokes[first] and i < first))
			)
		):
			first = i
			best_sub = sub
	if first >= 0 and hole_winner < 0:
		hole_winner = first
		wins[first] += 1
		return first
	return -1


func hole_over() -> bool:
	if hole_winner >= 0:
		return true
	for i in players():
		if state[i] == State.READY or state[i] == State.MOVING:
			return false
	return true


## Moves on; false when the match is finished.
func next_hole() -> bool:
	hole_number += 1
	return hole_number < holes.size()


func match_over() -> bool:
	return hole_number >= holes.size()


## Match winner: most holes won, then fewest total strokes; -1 for an exact tie.
func winner() -> int:
	var order := standings()
	if order.size() > 1 and _same(order[0], order[1]):
		return -1
	return order[0]


## Player indices from first to last place (stable for equal records).
func standings() -> PackedInt32Array:
	var idx: Array = []
	for i in players():
		idx.append(i)
	idx.sort_custom(
		func(a: int, b: int) -> bool:
			if wins[a] != wins[b]:
				return wins[a] > wins[b]
			if total[a] != total[b]:
				return total[a] < total[b]
			return a < b
	)
	return PackedInt32Array(idx)


func _same(a: int, b: int) -> bool:
	return wins[a] == wins[b] and total[a] == total[b]
