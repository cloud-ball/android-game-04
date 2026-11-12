extends SceneTree
## QA fuzzer: drives the pure game rules with random inputs and checks invariants after every
## step. Prints one line per violation (first few per kind) and a summary.
## Run: godot --headless --path . -s res://tools/qa_fuzz.gd -- [seeds]

var _violations := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds := int(args[0]) if args.size() > 0 else 40
	var t0 := Time.get_ticks_msec()
	for s in seeds:
		_fuzz_blocks(1000 + s)
		_fuzz_snake(5000 + s, true)
		_fuzz_snake(9000 + s, false)
	print("QA fuzz: %d seeds in %d ms" % [seeds, Time.get_ticks_msec() - t0])
	if _violations.is_empty():
		print("QA fuzz: no invariant violations")
	for k in _violations:
		print("QA fuzz VIOLATION x%d: %s" % [_violations[k].count, k])
		for ex in _violations[k].examples:
			print("    e.g. ", ex)
	quit()


func _flag(kind: String, detail: String) -> void:
	if not _violations.has(kind):
		_violations[kind] = {"count": 0, "examples": []}
	_violations[kind].count += 1
	if _violations[kind].examples.size() < 3:
		_violations[kind].examples.append(detail)


# --- Stack Drop -------------------------------------------------------------------------------


func _fuzz_blocks(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var kinds := ["left", "right", "cw", "ccw", "soft", "hard", "hold"]
	var s := StackLogic.new_game(seed_value, 1 + seed_value % 8)
	var prev_score := 0
	var prev_lines := 0
	for i in 4000:
		var a := {"type": "tick", "dt": 1.0 / 60.0}
		var r := rng.randf()
		if r < 0.35:
			a = {"type": kinds[rng.randi_range(0, kinds.size() - 1)]}
		elif r < 0.37:
			a = {"type": "garbage", "rows": rng.randi_range(1, 4)}
		var before := s.fingerprint()
		var n := StackLogic.reduce(s, a)
		if s.fingerprint() != before:
			_flag("blocks: reduce mutated its input", "seed %d step %d %s" % [seed_value, i, a])
		s = n
		var where := "seed %d step %d after %s" % [seed_value, i, a.type]
		for v in s.board:
			if v > StackState.GARBAGE:
				_flag("blocks: invalid cell value", where)
				break
		if not s.over:
			if not StackLogic.fits(s, s.kind, s.rot, s.px, s.py):
				_flag("blocks: active shard overlaps the board or walls", where)
			if s.queue.size() < StackLogic.PREVIEW:
				_flag("blocks: preview queue too short", where)
			for c in StackLogic.shard_cells(s.kind, s.rot, s.px, s.py):
				if c.y < StackState.HIDDEN:
					_flag("blocks: active shard partly in hidden rows (invisible)", where)
					break
		for y in StackState.HIDDEN:
			for x in StackState.W:
				if s.board[y * StackState.W + x] != 0 and not s.over:
					_flag(
						"blocks: locked cell in hidden rows while playing (invisible block)", where
					)
		if s.score < prev_score:
			_flag("blocks: score decreased", where)
		if s.lines < prev_lines:
			_flag("blocks: lines decreased", where)
		if s.level != s.start_level + int(s.lines / 10.0):
			_flag("blocks: level out of sync with lines", where)
		prev_score = s.score
		prev_lines = s.lines
		if s.over:
			s = StackLogic.new_game(seed_value + i, 1)
			prev_score = 0
			prev_lines = 0


# --- Serpent Grid ------------------------------------------------------------------------------


func _fuzz_snake(seed_value: int, wrap: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cfg := SnakeConfig.for_difficulty(["easy", "medium", "hard"][seed_value % 3]).duplicate()
	cfg.wrap = wrap
	cfg.height = [18, 20, 22][seed_value % 3]
	var g := SnakeLogic.new(cfg, seed_value, seed_value % 2 == 0)
	for i in 3000:
		for who in g.snakes.size():
			if rng.randf() < 0.3:
				g.queue_turn(who, rng.randi_range(0, 3))
			elif rng.randf() < 0.7:
				g.queue_turn(who, SnakeAI.choose(g, who, rng))
		g.step()
		var where := "seed %d wrap %s step %d" % [seed_value, wrap, i]
		var occupied := {}
		for si in g.snakes.size():
			var s := g.snakes[si]
			for k in s.body.size():
				var c := s.body[k]
				if not g.in_bounds(c):
					_flag("snake: body cell out of bounds", where)
				if k > 0:
					var d := c - s.body[k - 1]
					var dx := absi(d.x)
					var dy := absi(d.y)
					if wrap:
						dx = mini(dx, g.width - dx)
						dy = mini(dy, g.height - dy)
					if dx + dy != 1:
						_flag("snake: body not contiguous", "%s snake %d seg %d" % [where, si, k])
				if s.alive and occupied.has(c):
					_flag("snake: two living segments share a cell", where)
				occupied[c] = true
		for o in g.orbs:
			if occupied.has(o):
				_flag("snake: orb spawned on a snake", where)
		if g.orbs.size() != cfg.orb_count and occupied.size() + g.orbs.size() < g.width * g.height:
			_flag("snake: orb count wrong while the board has room", where)
		if g.is_over():
			g = SnakeLogic.new(cfg, seed_value + i, seed_value % 2 == 0)
