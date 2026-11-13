class_name StackAI
extends RefCounted
## CPU placement search for Stack Drop: tries every rotation and column for the current shard
## (and the hold/next shard when allowed), drops it straight down, and scores the resulting
## board with a classic heuristic (aggregate height, holes, bumpiness, lines cleared).
## Difficulty adds random noise / picks among the top few instead of always the best.

const W_HEIGHT := -0.51
const W_LINES := 0.76
const W_HOLES := -0.36
const W_BUMPS := -0.18


## Best placement as {use_hold: bool, kind, rot, x, score}; empty when nothing fits.
## top_k > 1 picks uniformly among the best top_k (weaker play); noise jitters every score.
static func choose(
	s: StackState, rng: RandomNumberGenerator, allow_hold := true, top_k := 1, noise := 0.0
) -> Dictionary:
	var options: Array[Dictionary] = []
	options.append_array(_placements(s, s.kind, false))
	if allow_hold and s.can_hold:
		var other := s.hold if s.hold >= 0 else int(s.queue[0])
		if other != s.kind:
			options.append_array(_placements(s, other, true))
	if options.is_empty():
		return {}
	for o in options:
		if noise > 0.0:
			o.score += rng.randf_range(-noise, noise)
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	var k := clampi(top_k, 1, options.size())
	return options[rng.randi_range(0, k - 1)] if k > 1 else options[0]


## The reducer actions that carry out a chosen placement from the current spawn state.
static func actions_for(s: StackState, plan: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sim := s
	if plan.use_hold:
		out.append({"type": "hold"})
		sim = StackLogic.reduce(sim, out.back())
	var turns := (int(plan.rot) - sim.rot + 4) % 4
	for i in turns:
		out.append({"type": "cw"})
		sim = StackLogic.reduce(sim, out.back())
	var guard := 0
	while sim.px != int(plan.x) and guard < StackState.W:
		var step := {"type": "right" if plan.x > sim.px else "left"}
		var before := sim.px
		sim = StackLogic.reduce(sim, step)
		out.append(step)
		guard += 1
		if sim.px == before:
			break
	out.append({"type": "hard"})
	return out


static func _placements(s: StackState, kind: int, use_hold: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rotations := 1 if kind == ShardData.SQUARE else 4
	for rot in rotations:
		for x in range(-3, StackState.W):
			var y := StackLogic.SPAWN_Y
			if not StackLogic.fits(s, kind, rot, x, y):
				continue
			while StackLogic.fits(s, kind, rot, x, y + 1):
				y += 1
			var score := evaluate_after(s.board, StackLogic.shard_cells(kind, rot, x, y))
			out.append({"use_hold": use_hold, "kind": kind, "rot": rot, "x": x, "score": score})
	return out


## Heuristic score of the board after placing `cells` and clearing full rows (higher = better).
static func evaluate_after(board: PackedByteArray, cells: Array[Vector2i]) -> float:
	var w := StackState.W
	var h := StackState.H
	var b := board.duplicate()
	for c in cells:
		b[c.y * w + c.x] = 1
	var cleared := 0
	var y := h - 1
	while y >= 0:
		var full := true
		for x in w:
			if b[y * w + x] == 0:
				full = false
				break
		if full:
			cleared += 1
			for yy in range(y, 0, -1):
				for x in w:
					b[yy * w + x] = b[(yy - 1) * w + x]
			for x in w:
				b[x] = 0
		else:
			y -= 1
	var heights := PackedInt32Array()
	heights.resize(w)
	var holes := 0
	for x in w:
		var seen_block := false
		for yy in h:
			if b[yy * w + x] != 0:
				if not seen_block:
					heights[x] = h - yy
					seen_block = true
			elif seen_block:
				holes += 1
	var aggregate := 0
	var bumps := 0
	for x in w:
		aggregate += heights[x]
		if x > 0:
			bumps += absi(heights[x] - heights[x - 1])
	return W_HEIGHT * aggregate + W_LINES * cleared + W_HOLES * holes + W_BUMPS * bumps
