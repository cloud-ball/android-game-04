class_name SnakeAI
extends RefCounted
## CPU rival: shortest path to the nearest orb (BFS, i.e. A* with a zero heuristic, which also
## handles several goals at once), rejected when a flood fill shows the move would trap it.
## A move is a trap when the region reachable after it is smaller than the snake's length.
## The AI never picks a trap while a non-trap move exists (tested), except on a deliberate
## "blunder" roll (cfg.ai_blunder, mostly on Easy): then it skips the look-ahead and only
## avoids cells that are blocked right now, so it can wander into a dead end.
## Performance: flood fills stop as soon as the answer is known (cap), and work on flat cell
## indices in packed arrays; a full-board count in GDScript cost up to ~190 ms per tick on a
## mid-range phone.

## Regions larger than this (or than 2x the snake) all count as "plenty of room".
const ROOM_CAP := 48


## Per-direction evaluation for snake `who`: {dir, blocked, area, trap}.
## area is capped (see ROOM_CAP), which is enough to rank moves and to detect traps.
static func evaluate(logic: SnakeLogic, who: int) -> Array[Dictionary]:
	var s := logic.snakes[who]
	var w := logic.width
	var occ := logic.occupancy()
	var out: Array[Dictionary] = []
	for d in 4:
		if d == SnakeLogic.opposite(s.dir):
			continue
		var nh := logic.step_from(s.head(), d)
		var eats := logic.orbs.has(nh)
		var need := s.body.size() + (1 if eats else 0)
		var blocked := not logic.in_bounds(nh)
		var area := 0
		if not blocked:
			var grid := _without_own_tail(logic, who, occ, eats)
			blocked = grid[nh.y * w + nh.x] != 0
			if not blocked:
				area = _flood(logic, grid, nh.y * w + nh.x, maxi(need * 2, ROOM_CAP))
		out.append({"dir": d, "blocked": blocked, "area": area, "trap": blocked or area < need})
	return out


## profile overrides the match config per snake: {wander, avoid_heads, hunt, squeeze, blunder}.
## Used by self-play tuning, where the "player" side runs a fixed baseline profile.
static func choose(
	logic: SnakeLogic, who: int, rng: RandomNumberGenerator, profile: Dictionary = {}
) -> int:
	var wander: float = profile.get("wander", logic.cfg.ai_wander)
	var avoid_heads: bool = profile.get("avoid_heads", logic.cfg.ai_avoid_heads)
	var hunt: float = profile.get("hunt", logic.cfg.ai_hunt)
	var squeeze: float = profile.get("squeeze", logic.cfg.ai_squeeze)
	var blunder: float = profile.get("blunder", logic.cfg.ai_blunder)
	var options := evaluate(logic, who)
	if blunder > 0.0 and rng.randf() < blunder:
		var open: Array = options.filter(func(o: Dictionary) -> bool: return not o.blocked)
		if not open.is_empty():
			var greedy := first_step_to_orb(logic, who)
			for o in open:
				if o.dir == greedy:
					return greedy
			return open[rng.randi_range(0, open.size() - 1)].dir
	var safe: Array = options.filter(func(o: Dictionary) -> bool: return not o.trap)
	if safe.is_empty():
		return _best_area(options)
	var rival := _rival_of(logic, who)
	if avoid_heads and rival != -1:
		var calm: Array = safe.filter(
			func(o: Dictionary) -> bool: return not _near_rival_head(logic, who, o.dir)
		)
		if not calm.is_empty():
			safe = calm
	if rival != -1 and hunt > 0.0 and rng.randf() < hunt:
		var kill := _cutoff_move(logic, who, rival, safe, squeeze)
		if kill != -1:
			return kill
	if rng.randf() < wander:
		return safe[rng.randi_range(0, safe.size() - 1)].dir
	var toward := first_step_to_orb(logic, who)
	for o in safe:
		if o.dir == toward:
			return toward
	return _best_area(safe)


static func _rival_of(logic: SnakeLogic, who: int) -> int:
	for j in logic.snakes.size():
		if j != who and logic.snakes[j].alive:
			return j
	return -1


## The safe move that leaves the rival the least room, if that room is under
## squeeze * rival length (squeeze 1.0 = only moves that trap it outright); otherwise -1.
static func _cutoff_move(
	logic: SnakeLogic, who: int, rival: int, safe: Array, squeeze := 1.0
) -> int:
	var w := logic.width
	var r := logic.snakes[rival]
	var best_dir := -1
	var best_room := int(ceil(r.body.size() * squeeze))
	var occ := logic.occupancy()
	for o in safe:
		var nh: Vector2i = logic.step_from(logic.snakes[who].head(), o.dir)
		var grid := _without_own_tail(logic, who, occ, logic.orbs.has(nh))
		grid[nh.y * w + nh.x] = 1
		var room := 0
		for d in 4:
			if d == SnakeLogic.opposite(r.dir) or room >= best_room:
				continue
			var c := logic.step_from(r.head(), d)
			if logic.in_bounds(c) and grid[c.y * w + c.x] == 0:
				# Only "is it smaller than best_room" matters, so stop counting there.
				room = maxi(room, _flood(logic, grid, c.y * w + c.x, best_room))
		if room < best_room:
			best_room = room
			best_dir = o.dir
	return best_dir


## First direction of a shortest path from the head to the nearest orb, or -1.
static func first_step_to_orb(logic: SnakeLogic, who: int) -> int:
	if logic.orbs.is_empty():
		return -1
	var w := logic.width
	var n := w * logic.height
	var grid := logic.occupancy()
	var is_orb := PackedByteArray()
	is_orb.resize(n)
	for o in logic.orbs:
		is_orb[o.y * w + o.x] = 1
	var wrap := logic.cfg.wrap
	var first := PackedInt32Array()
	first.resize(n)
	first.fill(-1)
	var queue := PackedInt32Array()
	var start := logic.snakes[who].head()
	for d in 4:
		var c := logic.step_from(start, d)
		if logic.in_bounds(c) and grid[c.y * w + c.x] == 0:
			first[c.y * w + c.x] = d
			queue.append(c.y * w + c.x)
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		if is_orb[i] == 1:
			return first[i]
		var x := i % w
		var left := i - 1 if x > 0 else (i + w - 1 if wrap else -1)
		var right := i + 1 if x < w - 1 else (i - w + 1 if wrap else -1)
		var up := i - w if i >= w else (i + n - w if wrap else -1)
		var down := i + w if i + w < n else (i + w - n if wrap else -1)
		for j in [left, right, up, down]:
			if j >= 0 and grid[j] == 0 and first[j] == -1:
				first[j] = first[i]
				queue.append(j)
	return -1


## Occupancy copy with our own tail freed (it moves away this tick unless we grow).
static func _without_own_tail(
	logic: SnakeLogic, who: int, occ: PackedByteArray, eats: bool
) -> PackedByteArray:
	var grid := occ.duplicate()
	var body := logic.snakes[who].body
	if not eats and body.size() > 1:
		var t: Vector2i = body.back()
		grid[t.y * logic.width + t.x] = 0
	return grid


## Number of free cells reachable from cell index `from` (counting it), stopping at `cap`.
static func _flood(logic: SnakeLogic, grid: PackedByteArray, from: int, cap: int) -> int:
	var w := logic.width
	var n := w * logic.height
	var wrap := logic.cfg.wrap
	var seen := grid.duplicate()
	seen[from] = 9
	var stack := PackedInt32Array([from])
	var count := 0
	while not stack.is_empty() and count < cap:
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		count += 1
		var x := i % w
		var left := i - 1 if x > 0 else (i + w - 1 if wrap else -1)
		var right := i + 1 if x < w - 1 else (i - w + 1 if wrap else -1)
		var up := i - w if i >= w else (i + n - w if wrap else -1)
		var down := i + w if i + w < n else (i + w - n if wrap else -1)
		if left >= 0 and seen[left] == 0:
			seen[left] = 9
			stack.append(left)
		if right >= 0 and seen[right] == 0:
			seen[right] = 9
			stack.append(right)
		if up >= 0 and seen[up] == 0:
			seen[up] = 9
			stack.append(up)
		if down >= 0 and seen[down] == 0:
			seen[down] = 9
			stack.append(down)
	return count


static func _near_rival_head(logic: SnakeLogic, who: int, d: int) -> bool:
	var nh := logic.step_from(logic.snakes[who].head(), d)
	for j in logic.snakes.size():
		var r := logic.snakes[j]
		if j != who and r.alive:
			var dx := absi(r.head().x - nh.x)
			var dy := absi(r.head().y - nh.y)
			if logic.cfg.wrap:
				dx = mini(dx, logic.width - dx)
				dy = mini(dy, logic.height - dy)
			var dist := dx + dy
			if dist <= 1:
				return true
	return false


static func _best_area(options: Array) -> int:
	var best: Dictionary = options[0]
	for o in options:
		if o.area > best.area:
			best = o
	return best.dir
