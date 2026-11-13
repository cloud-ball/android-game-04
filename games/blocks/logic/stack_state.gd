class_name StackState
extends RefCounted
## Complete Stack Drop game state. Plain data: StackLogic.reduce() copies it and returns a new one,
## so any game can be replayed bit-exactly from (seed, actions).
## Board: W x H cells, row 0 at the top; the top HIDDEN rows are the spawn area (not drawn).

const W := 12
const H := 26
const HIDDEN := 2
const GARBAGE := 8  # board value for garbage cells (shards are 1..7)

## Cell values: 0 empty, 1..7 shard kind + 1, GARBAGE.
var board := PackedByteArray()
## Active shard: kind 0..6 (or -1 when none), rotation 0..3, box position.
var kind := -1
var rot := 0
var px := 0
var py := 0
## Upcoming shard kinds (the first 3 are shown as the preview).
var queue := PackedByteArray()
var hold := -1
var can_hold := true
## Our own xorshift32 state, so the RNG is copied together with the board.
var rng := 1
var score := 0
var lines := 0
var level := 1
var start_level := 1
var pieces := 0
var gravity_acc := 0.0
var lock_timer := 0.0
var lock_resets := 0
var lowest_y := 0
## Garbage rows waiting to be added to this board (from the opponent).
var pending_garbage := 0
## Garbage rows this board produced on its latest lock (the controller sends them on).
var outgoing := 0
var over := false
## What happened during the latest reduce(): Array of Dictionaries ({type: ...}).
var events: Array = []


func copy() -> StackState:
	var s := StackState.new()
	s.board = board.duplicate()
	s.kind = kind
	s.rot = rot
	s.px = px
	s.py = py
	s.queue = queue.duplicate()
	s.hold = hold
	s.can_hold = can_hold
	s.rng = rng
	s.score = score
	s.lines = lines
	s.level = level
	s.start_level = start_level
	s.pieces = pieces
	s.gravity_acc = gravity_acc
	s.lock_timer = lock_timer
	s.lock_resets = lock_resets
	s.lowest_y = lowest_y
	s.pending_garbage = pending_garbage
	s.outgoing = outgoing
	s.over = over
	return s


func cell(x: int, y: int) -> int:
	return board[y * W + x]


## Height of the stack in each column (0 = empty column), counted from the floor.
func column_heights() -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(W)
	for x in W:
		for y in H:
			if board[y * W + x] != 0:
				out[x] = H - y
				break
	return out


func fingerprint() -> int:
	return hash(
		str([board, kind, rot, px, py, queue, hold, can_hold, rng, score, lines, level, over])
	)
