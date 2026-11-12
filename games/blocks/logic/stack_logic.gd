class_name StackLogic
extends RefCounted
## Pure Stack Drop rules: reduce(state, action) -> new state. Never mutates its input.
## Actions are Dictionaries:
##   {type: "left"|"right"|"cw"|"ccw"|"soft"|"hard"|"hold"}
##   {type: "tick", dt: float}          gravity + lock delay (call with a fixed step)
##   {type: "garbage", rows: int}       queue garbage from the opponent (added on the next lock)
## Events of the step are left in new_state.events.

const LOCK_DELAY := 0.5
const MAX_LOCK_RESETS := 15
const PREVIEW := 3
const LINE_SCORES := [0, 100, 300, 500, 800]
## Garbage rows sent for clearing 0..4 lines at once.
const GARBAGE_SENT := [0, 0, 1, 2, 4]
const SPAWN_X := 3
## Shards appear in the top visible rows (row HIDDEN); the 2 hidden rows above are headroom
## for rotations. Top-out = a new shard cannot fit there.
const SPAWN_Y := StackState.HIDDEN


## A fresh game with the first shard already spawned.
static func new_game(seed_value: int, start_level := 1) -> StackState:
	var s := StackState.new()
	s.board.resize(StackState.W * StackState.H)
	s.rng = (seed_value & 0xffffffff) if (seed_value & 0xffffffff) != 0 else 0x9e3779b9
	s.start_level = maxi(1, start_level)
	s.level = s.start_level
	_refill(s)
	_spawn_next(s)
	return s


static func reduce(state: StackState, action: Dictionary) -> StackState:
	var s := state.copy()
	s.events = []
	s.outgoing = 0
	if s.over:
		return s
	match action.get("type", ""):
		"left":
			_shift(s, -1)
		"right":
			_shift(s, 1)
		"cw":
			_rotate(s, 1)
		"ccw":
			_rotate(s, 3)
		"soft":
			if _fits(s, s.kind, s.rot, s.px, s.py + 1):
				s.py += 1
				s.score += 1
				_fell(s)
		"hard":
			var rows := 0
			while _fits(s, s.kind, s.rot, s.px, s.py + 1):
				s.py += 1
				rows += 1
			s.score += rows * 2
			s.events.append({"type": "hard_drop", "rows": rows})
			_lock(s)
		"hold":
			_hold(s)
		"tick":
			_tick(s, float(action.get("dt", 0.0)))
		"garbage":
			s.pending_garbage += maxi(0, int(action.get("rows", 0)))
	return s


## Rows per second of gravity at a level.
static func gravity(level: int) -> float:
	return minf(20.0, 1.0 + 0.55 * (level - 1))


## Where the active shard would land (row of its box).
static func ghost_y(s: StackState) -> int:
	var y := s.py
	while _fits(s, s.kind, s.rot, s.px, y + 1):
		y += 1
	return y


## Board cells of a shard placed at (x, y) with rotation rot.
static func shard_cells(kind: int, rot: int, x: int, y: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in ShardData.cells(kind, rot):
		out.append(Vector2i(x + c.x, y + c.y))
	return out


static func fits(s: StackState, kind: int, rot: int, x: int, y: int) -> bool:
	return _fits(s, kind, rot, x, y)


static func _fits(s: StackState, kind: int, rot: int, x: int, y: int) -> bool:
	if kind < 0:
		return false
	for c in ShardData.cells(kind, rot):
		var cx: int = x + c.x
		var cy: int = y + c.y
		if cx < 0 or cx >= StackState.W or cy < 0 or cy >= StackState.H:
			return false
		if s.board[cy * StackState.W + cx] != 0:
			return false
	return true


static func _shift(s: StackState, dx: int) -> void:
	if _fits(s, s.kind, s.rot, s.px + dx, s.py):
		s.px += dx
		s.events.append({"type": "move", "dx": dx})
		_on_ground_action(s)


static func _rotate(s: StackState, quarter_turns: int) -> void:
	var to := (s.rot + quarter_turns) % 4
	var tests := ShardData.kicks(s.kind, s.rot, to)
	for i in tests.size():
		var k: Vector2i = tests[i]
		if _fits(s, s.kind, to, s.px + k.x, s.py + k.y):
			s.px += k.x
			s.py += k.y
			s.rot = to
			s.events.append({"type": "rotate", "kick": i})
			if s.py > s.lowest_y:
				_fell(s)
			_on_ground_action(s)
			return


## A successful move/rotation while resting on the stack restarts the lock timer (capped).
static func _on_ground_action(s: StackState) -> void:
	if not _fits(s, s.kind, s.rot, s.px, s.py + 1) and s.lock_resets < MAX_LOCK_RESETS:
		s.lock_timer = 0.0
		s.lock_resets += 1


## Called when the shard moved down: reaching a new lowest row restores the lock resets.
static func _fell(s: StackState) -> void:
	if s.py > s.lowest_y:
		s.lowest_y = s.py
		s.lock_resets = 0
		s.lock_timer = 0.0


static func _tick(s: StackState, dt: float) -> void:
	if _fits(s, s.kind, s.rot, s.px, s.py + 1):
		s.gravity_acc += dt * gravity(s.level)
		while s.gravity_acc >= 1.0:
			s.gravity_acc -= 1.0
			if not _fits(s, s.kind, s.rot, s.px, s.py + 1):
				s.gravity_acc = 0.0
				break
			s.py += 1
			_fell(s)
		return
	s.gravity_acc = 0.0
	s.lock_timer += dt
	if s.lock_timer >= LOCK_DELAY:
		_lock(s)


static func _hold(s: StackState) -> void:
	if not s.can_hold:
		return
	var current := s.kind
	if s.hold < 0:
		s.hold = current
		_spawn_next(s)
	else:
		s.kind = s.hold
		s.hold = current
		_place_at_spawn(s)
	s.can_hold = false
	s.events.append({"type": "hold"})


static func _lock(s: StackState) -> void:
	var cells := shard_cells(s.kind, s.rot, s.px, s.py)
	var all_hidden := true
	for c in cells:
		s.board[c.y * StackState.W + c.x] = s.kind + 1
		if c.y >= StackState.HIDDEN:
			all_hidden = false
	s.pieces += 1
	s.events.append({"type": "lock", "cells": cells, "kind": s.kind})
	if all_hidden:
		_top_out(s, "lock_out")
		return
	var cleared := _clear_rows(s)
	var sent: int = GARBAGE_SENT[cleared.size()]
	# Clearing lines first cancels garbage that is waiting for us.
	var cancel := mini(sent, s.pending_garbage)
	s.pending_garbage -= cancel
	s.outgoing = sent - cancel
	if s.pending_garbage > 0:
		_add_garbage(s, s.pending_garbage)
		s.pending_garbage = 0
		if s.over:
			return
	s.can_hold = true
	_spawn_next(s)


## Removes full rows; returns their indices (top to bottom, as they were before removal).
static func _clear_rows(s: StackState) -> PackedInt32Array:
	var full := PackedInt32Array()
	for y in StackState.H:
		var row_full := true
		for x in StackState.W:
			if s.board[y * StackState.W + x] == 0:
				row_full = false
				break
		if row_full:
			full.append(y)
	if full.is_empty():
		return full
	var kept := PackedByteArray()
	for y in StackState.H:
		if not full.has(y):
			kept.append_array(s.board.slice(y * StackState.W, (y + 1) * StackState.W))
	var fresh := PackedByteArray()
	fresh.resize(full.size() * StackState.W)
	fresh.append_array(kept)
	s.board = fresh
	var n := full.size()
	s.score += LINE_SCORES[n] * s.level
	s.lines += n
	s.level = s.start_level + int(s.lines / 10.0)
	s.events.append({"type": "clear", "rows": full, "count": n})
	return full


static func _add_garbage(s: StackState, rows: int) -> void:
	var w := StackState.W
	var gap := _next_rand(s) % w
	for i in rows * w:
		if s.board[i] != 0:
			_top_out(s, "garbage")
	var shifted := s.board.slice(rows * w)
	for r in rows:
		for x in w:
			shifted.append(0 if x == gap else StackState.GARBAGE)
	s.board = shifted
	s.events.append({"type": "garbage_in", "rows": rows, "gap": gap})


static func _spawn_next(s: StackState) -> void:
	s.kind = s.queue[0]
	s.queue = s.queue.slice(1)
	_refill(s)
	_place_at_spawn(s)


static func _place_at_spawn(s: StackState) -> void:
	s.rot = 0
	s.px = SPAWN_X
	s.py = SPAWN_Y
	s.lowest_y = SPAWN_Y
	s.lock_timer = 0.0
	s.lock_resets = 0
	s.gravity_acc = 0.0
	s.events.append({"type": "spawn", "kind": s.kind})
	if not _fits(s, s.kind, s.rot, s.px, s.py):
		_top_out(s, "block_out")


static func _top_out(s: StackState, why: String) -> void:
	if s.over:
		return
	s.over = true
	s.events.append({"type": "top_out", "why": why})


## Keeps at least two full bags queued (7-bag: each shard once per shuffled bag).
static func _refill(s: StackState) -> void:
	while s.queue.size() < ShardData.COUNT + PREVIEW:
		var bag := PackedByteArray([0, 1, 2, 3, 4, 5, 6])
		for i in range(bag.size() - 1, 0, -1):
			var j := _next_rand(s) % (i + 1)
			var t := bag[i]
			bag[i] = bag[j]
			bag[j] = t
		s.queue.append_array(bag)


## xorshift32 stored in the state (deterministic on every platform).
static func _next_rand(s: StackState) -> int:
	var x := s.rng
	x ^= (x << 13) & 0xffffffff
	x ^= x >> 17
	x ^= (x << 5) & 0xffffffff
	s.rng = x & 0xffffffff
	return s.rng
