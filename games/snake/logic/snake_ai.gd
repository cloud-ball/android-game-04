class_name SnakeAI
extends RefCounted
## CPU rival: shortest path to the nearest orb (BFS, i.e. A* with a zero heuristic, which also
## handles several goals at once), rejected when a flood fill shows the move would trap it.
## A move is a trap when the region reachable after it is smaller than the snake's length.
## The AI never picks a trap while a non-trap move exists (tested).


## Per-direction evaluation for snake `who`: {dir, blocked, area, trap}.
static func evaluate(logic: SnakeLogic, who: int) -> Array[Dictionary]:
	var s := logic.snakes[who]
	var out: Array[Dictionary] = []
	for d in 4:
		if d == SnakeLogic.opposite(s.dir):
			continue
		var nh := s.head() + SnakeLogic.STEP[d]
		var eats := logic.orbs.has(nh)
		var grid := _grid_after_move(logic, who, eats)
		var blocked := not logic.in_bounds(nh) or grid[nh.y * logic.width + nh.x] != 0
		var area := 0
		if not blocked:
			grid[nh.y * logic.width + nh.x] = 1
			area = _flood(logic, grid, nh)
		var need := s.body.size() + (1 if eats else 0)
		out.append({"dir": d, "blocked": blocked, "area": area, "trap": blocked or area < need})
	return out


static func choose(logic: SnakeLogic, who: int, rng: RandomNumberGenerator) -> int:
	var cfg := logic.cfg
	var options := evaluate(logic, who)
	var safe: Array = options.filter(func(o: Dictionary) -> bool: return not o.trap)
	if safe.is_empty():
		return _best_area(options)
	if cfg.ai_avoid_heads and logic.snakes.size() > 1:
		var calm: Array = safe.filter(
			func(o: Dictionary) -> bool: return not _near_rival_head(logic, who, o.dir)
		)
		if not calm.is_empty():
			safe = calm
	if rng.randf() < cfg.ai_wander:
		return safe[rng.randi_range(0, safe.size() - 1)].dir
	var toward := first_step_to_orb(logic, who)
	for o in safe:
		if o.dir == toward:
			return toward
	return _best_area(safe)


## First direction of a shortest path from the head to the nearest orb, or -1.
static func first_step_to_orb(logic: SnakeLogic, who: int) -> int:
	if logic.orbs.is_empty():
		return -1
	var w := logic.width
	var grid := logic.occupancy()
	var start := logic.snakes[who].head()
	var first := PackedInt32Array()
	first.resize(w * logic.height)
	first.fill(-1)
	var frontier: Array[Vector2i] = []
	for d in 4:
		var c := start + SnakeLogic.STEP[d]
		if logic.in_bounds(c) and grid[c.y * w + c.x] == 0 and first[c.y * w + c.x] == -1:
			first[c.y * w + c.x] = d
			frontier.append(c)
	var i := 0
	while i < frontier.size():
		var c := frontier[i]
		i += 1
		if logic.orbs.has(c):
			return first[c.y * w + c.x]
		for d in 4:
			var n := c + SnakeLogic.STEP[d]
			if logic.in_bounds(n) and grid[n.y * w + n.x] == 0 and first[n.y * w + n.x] == -1:
				first[n.y * w + n.x] = first[c.y * w + c.x]
				frontier.append(n)
	return -1


static func _grid_after_move(logic: SnakeLogic, who: int, eats: bool) -> PackedByteArray:
	var grid := logic.occupancy()
	# Our own tail moves away this tick unless we grow.
	var body := logic.snakes[who].body
	if not eats and body.size() > 1:
		var t: Vector2i = body.back()
		grid[t.y * logic.width + t.x] = 0
	return grid


static func _flood(logic: SnakeLogic, grid: PackedByteArray, from: Vector2i) -> int:
	var w := logic.width
	var seen := grid.duplicate()
	var stack: Array[Vector2i] = [from]
	var count := 0
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		count += 1
		for d in 4:
			var n := c + SnakeLogic.STEP[d]
			if logic.in_bounds(n) and seen[n.y * w + n.x] == 0:
				seen[n.y * w + n.x] = 9
				stack.append(n)
	return count


static func _near_rival_head(logic: SnakeLogic, who: int, d: int) -> bool:
	var nh := logic.snakes[who].head() + SnakeLogic.STEP[d]
	for j in logic.snakes.size():
		var r := logic.snakes[j]
		if j != who and r.alive:
			var dist := absi(r.head().x - nh.x) + absi(r.head().y - nh.y)
			if dist <= 1:
				return true
	return false


static func _best_area(options: Array) -> int:
	var best: Dictionary = options[0]
	for o in options:
		if o.area > best.area:
			best = o
	return best.dir
