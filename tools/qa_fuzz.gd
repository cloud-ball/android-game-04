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
		_fuzz_pool(20000 + s)
		_fuzz_rush(30000 + s)
	for h in _golf_holes():
		_fuzz_golf(h, seeds)
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


# --- Facetfall -------------------------------------------------------------------------------


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


# --- Break & Bank -------------------------------------------------------------------------------


## Random shots (any direction, speed, spin; random ball-in-hand spots and called pockets) through
## the real rules; after each shot every ball on the table is finite, inside the cushions and not
## overlapping another.
func _fuzz_pool(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var m := PoolMatch.new(seed_value, seed_value % 2)
	var r := m.sim.p.radius
	for shot in 250:
		if m.over():
			return
		var where := "seed %d shot %d" % [seed_value, shot]
		if m.state.ball_in_hand != PoolState.Hand.NONE:
			for k in 60:
				var x := rng.randf_range(-m.sim.table.hw, m.sim.table.hw)
				var y := rng.randf_range(-m.sim.table.hl, m.sim.table.hl)
				if m.place_cue(x, y):
					break
		if PoolRules.requires_call(m.state):
			m.call_pocket(rng.randi_range(0, 5))
		var a := rng.randf_range(0.0, TAU)
		var res := m.shoot(
			cos(a),
			sin(a),
			rng.randf_range(0.2, 8.0),
			rng.randf_range(-0.5, 0.5),
			rng.randf_range(-0.5, 0.5)
		)
		if res == null:
			_flag("pool: shoot() returned null", where)
			return
		for i in CueSim.N:
			if m.sim.phase[i] == CueSim.POCKETED:
				continue
			var x := m.sim.px[i]
			var y := m.sim.py[i]
			if is_nan(x) or is_nan(y) or is_inf(x) or is_inf(y):
				_flag("pool: non-finite ball position", "%s ball %d" % [where, i])
			elif (
				(absf(x) > m.sim.table.hw + 1e-4 or absf(y) > m.sim.table.hl + 1e-4)
				and not _in_pocket_mouth(m.sim.table, x, y, r)
			):
				_flag(
					"pool: ball outside the cushions", "%s ball %d (%.4f, %.4f)" % [where, i, x, y]
				)
			for j in range(i + 1, CueSim.N):
				if m.sim.phase[j] == CueSim.POCKETED:
					continue
				var d := Vector2(x - m.sim.px[j], y - m.sim.py[j]).length()
				if d < 2.0 * r - 1e-5:
					_flag(
						"pool: balls overlap",
						"%s balls %d,%d gap %.6f" % [where, i, j, d - 2.0 * r]
					)


## Past the cushion line is fine only inside a pocket's mouth (a ball can rest in the jaws).
func _in_pocket_mouth(t: CueTable, x: float, y: float, r: float) -> bool:
	for k in t.pocket_x.size():
		if Vector2(x - t.pocket_x[k], y - t.pocket_y[k]).length() < t.pocket_r[k] + 2.0 * r:
			return true
	return false


# --- Fairway Flick ------------------------------------------------------------------------------


func _golf_holes() -> PackedStringArray:
	var out := PackedStringArray()
	var dir := "res://games/golf/data/mini/"
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			out.append(dir + f)
	return out


## Random shots from random spots on the course: the ball never sinks into the ground, never
## leaves the hole's grid while still in play, and every shot comes to an end.
func _fuzz_golf(path: String, seeds: int) -> void:
	var spec := MiniBaker.load_spec(path)
	var hole := MiniBaker.bake(spec)
	var preset := CoursePreset.new()
	preset.stimp = 9.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(path)
	var shots := seeds * 3
	for n in shots:
		var x := 0.0
		var z := 0.0
		for k in 200:  # a random start on the playing surface
			x = rng.randf_range(hole.x0, hole.x0 + hole.nx * hole.cell)
			z = rng.randf_range(hole.z0, hole.z0 + hole.nz * hole.cell)
			var sf := hole.surface_at(x, z)
			if sf != HoleData.Surface.OUT and sf != HoleData.Surface.WATER:
				break
		var b := GolfBall.new(hole, preset)
		var a := rng.randf_range(0.0, TAU)
		var sp := rng.randf_range(0.3, 13.0)
		b.putt(x, z, cos(a) * sp, sin(a) * sp)
		var where := (
			"%s shot %d from (%.2f, %.2f) dir %.0f speed %.1f"
			% [path.get_file(), n, x, z, rad_to_deg(a), sp]
		)
		var cap := int(GolfBall.MAX_TIME / GolfFlight.SUBSTEP) + 20
		var r := b.p.radius
		while not b.done() and cap > 0:
			b.substep()
			cap -= 1
			var q := b.pos()
			if is_nan(q.x) or is_nan(q.y) or is_nan(q.z):
				_flag("golf: non-finite ball position", where)
				break
			if b.phase == GolfBall.Phase.ROLL or b.phase == GolfBall.Phase.REST:
				if not hole.contains(q.x, q.z):
					_flag("golf: rolling ball left the grid", where)
					break
				if q.y < hole.height(q.x, q.z) + r - 0.01:
					_flag("golf: ball sank into the ground", "%s at t=%.2f" % [where, b.time])
					break
		if not b.done():
			_flag("golf: shot never ended", where)


## Random legal Rush event sequences: at most one hole winner, wins add up, every hole ends.
func _fuzz_rush(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var m := RushMatch.new(
		PackedStringArray(["You", "A", "B", "C"]), RushMatch.pick_holes(9, 3, rng)
	)
	var holes_won := 0
	while not m.match_over():
		m.start_hole(rng.randi_range(2, 4))
		var steps := 0
		while not m.hole_over() and steps < 400:
			steps += 1
			var i := rng.randi_range(0, 3)
			if m.can_shoot(i):
				m.shot_taken(i)
				var roll := rng.randf()
				if roll < 0.12:
					var w := m.balls_holed([[i, rng.randi_range(0, 3)]])
					if w >= 0:
						holes_won += 1
				else:
					if roll < 0.2:
						m.add_penalty(i)
					m.ball_rested(i)
		var where := "seed %d hole %d" % [seed_value, m.hole_number]
		if not m.hole_over():
			_flag("rush: hole never ended", where)
		var winners := 0
		for k in m.players():
			if m.strokes[k] > m.par + RushMatch.CAP_OVER_PAR + 40:
				_flag("rush: runaway strokes", where)
		if m.hole_winner >= 0:
			winners += 1
		if winners > 1:
			_flag("rush: more than one hole winner", where)
		m.next_hole()
	var total := 0
	for k in m.players():
		total += m.wins[k]
	if total != holes_won or total > m.holes.size():
		_flag("rush: wins do not add up", "seed %d: %d vs %d" % [seed_value, total, holes_won])
