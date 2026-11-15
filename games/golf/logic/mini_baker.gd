class_name MiniBaker
extends RefCounted
## Bakes a mini-golf hole from a tile map (pure, deterministic: + - * / only) into HoleData with
## walls, bumpers, ramps, sand, water, tee and cup.
## Plan: docs/plans/2026-11-15-fairway-flick-minigolf.md (step C).
##
## Spec (games/golf/data/mini/*.json):
##   tile: tile size in metres (default 3)
##   map: rows of characters, top row = far end (-z), bottom row = tee end; left = -x
##     .  nothing (out of bounds; a pit 1.5 m down)    G  green floor      T  tee (green)
##     H  cup (green)    B  green with a bumper         S  sand            W  water
##     ^ v < >  ramp rising one level in the arrow direction (^ = towards -z, the far end)
##   levels: optional rows of digits (same shape); floor height = level x LEVEL_H
## Walls stand on every edge between floor and nothing, and between floor tiles whose heights do not
## meet (a ramp's high side meeting the next level up is open). A ramp whose high side faces nothing
## is a JUMP: that edge, and the landing tile's edge across the gap, stay open. Collinear wall
## pieces are merged.

const LEVEL_H := 0.4
const PIT := -1.5  # gaps inside the map (jumps you fall short of)
const LAWN := -0.3  # the ground around the course
const CELL := 0.1
## Walls are rails this thick (half-width), so the ball's centre never reaches the one-cell strip
## where the ground changes height at a tile edge.
const WALL_HALF := 0.1
const MARGIN := 7.0  # lawn around the course (room for scenery)
const BUMPER_R := 0.45
## Arcade cup: 75 mm radius (regulation 54) and a gentle pull for slow balls close by.
const CUP_R := 0.075
const CUP_PULL := 1.6  # beats the carpet's grip within ~18 cm of the cup
const FLOOR := "GTHBSW^v<>"
## Direction each ramp rises towards (its high edge).
const RAMP_UP := {
	"^": Vector2i(0, -1), "v": Vector2i(0, 1), ">": Vector2i(1, 0), "<": Vector2i(-1, 0)
}


static func load_spec(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


static func bake(spec: Dictionary) -> HoleData:
	var m := _Map.new(spec)
	var d := HoleData.new()
	var x0 := m.x0 - MARGIN
	var z0 := m.z0 - MARGIN
	var w := m.cols * m.tile + 2.0 * MARGIN
	var l := m.rows * m.tile + 2.0 * MARGIN
	d.setup(x0, z0, CELL, int(ceilf(w / CELL)), int(ceilf(l / CELL)))
	d.par = int(spec.get("par", 2))
	d.wall_half = WALL_HALF
	d.cup_r = CUP_R
	d.cup_pull = CUP_PULL
	for j in d.nz + 1:
		for i in d.nx + 1:
			d.heights[j * (d.nx + 1) + i] = m.height(x0 + i * CELL, z0 + j * CELL)
	for j in d.nz:
		for i in d.nx:
			d.surface[j * d.nx + i] = m.surface(x0 + (i + 0.5) * CELL, z0 + (j + 0.5) * CELL)
	m.add_walls(d)
	for t in m.tiles_of("B"):
		var c := m.centre(t.x, t.y)
		d.add_bumper(c.x, c.y, BUMPER_R)
	var tee: Array = m.tiles_of("T")
	var cup: Array = m.tiles_of("H")
	var tc := m.centre(tee[0].x, tee[0].y) if not tee.is_empty() else Vector2.ZERO
	var cc := m.centre(cup[0].x, cup[0].y) if not cup.is_empty() else Vector2.ZERO
	d.tee = Vector3(tc.x, d.height(tc.x, tc.y), tc.y)
	d.pin = Vector3(cc.x, d.height(cc.x, cc.y), cc.y)
	return d


## Tile-grid distance (metres, through floor tiles) from each tile to the cup tile: a flow field
## for the CPU and the solvability check. -1 where the cup cannot be reached.
static func flow_field(spec: Dictionary) -> PackedFloat64Array:
	var m := _Map.new(spec)
	var out := PackedFloat64Array()
	out.resize(m.rows * m.cols)
	out.fill(-1.0)
	var cup: Array = m.tiles_of("H")
	if cup.is_empty():
		return out
	var queue: Array[Vector2i] = [cup[0]]
	out[cup[0].y * m.cols + cup[0].x] = 0.0
	var head := 0
	while head < queue.size():
		var t: Vector2i = queue[head]
		head += 1
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = t + dir
			if not m.inside(n.x, n.y) or not m.solid(n.x, n.y) or m.walled(t, n):
				continue
			if m.at(n.x, n.y) == "W":
				continue
			var k := n.y * m.cols + n.x
			if out[k] < 0.0:
				out[k] = out[t.y * m.cols + t.x] + m.tile
				queue.append(n)
		# Jumps: a landing tile reaches back over the gap to the ramp that launches onto it.
		for ramp in m.ramps_landing_on(t):
			var k2: int = ramp.y * m.cols + ramp.x
			if out[k2] < 0.0:
				out[k2] = out[t.y * m.cols + t.x] + m.tile * 2.0
				queue.append(ramp)
	return out


## Grid helper over the tile map (pure).
class _Map:
	extends RefCounted
	var rows := 0
	var cols := 0
	var tile := 3.0
	var x0 := 0.0
	var z0 := 0.0
	var _chars: Array[String] = []
	var _levels: Array[String] = []

	func _init(spec: Dictionary) -> void:
		tile = float(spec.get("tile", 3.0))
		for r in spec.map:
			_chars.append(str(r))
		for r in spec.get("levels", []):
			_levels.append(str(r))
		rows = _chars.size()
		cols = 0
		for r in _chars:
			cols = maxi(cols, r.length())
		x0 = -cols * tile * 0.5
		z0 = -rows * tile

	func inside(c: int, r: int) -> bool:
		return c >= 0 and r >= 0 and c < cols and r < rows

	func at(c: int, r: int) -> String:
		if not inside(c, r) or c >= _chars[r].length():
			return "."
		return _chars[r][c]

	func solid(c: int, r: int) -> bool:
		return FLOOR.contains(at(c, r))

	func level(c: int, r: int) -> int:
		if r < _levels.size() and c < _levels[r].length():
			return int(_levels[r][c])
		return 0

	func centre(c: int, r: int) -> Vector2:
		return Vector2(x0 + (c + 0.5) * tile, z0 + (r + 0.5) * tile)

	func tiles_of(ch: String) -> Array:
		var out := []
		for r in rows:
			for c in cols:
				if at(c, r) == ch:
					out.append(Vector2i(c, r))
		return out

	func tile_at(x: float, z: float) -> Vector2i:
		return Vector2i(int(floorf((x - x0) / tile)), int(floorf((z - z0) / tile)))

	## Floor height at (x, z) inside tile (c, r); ramps rise one level across the tile.
	func tile_height(c: int, r: int, x: float, z: float) -> float:
		var ch := at(c, r)
		if not FLOOR.contains(ch):
			return PIT
		var base := level(c, r) * LEVEL_H
		var u := clampf((x - (x0 + c * tile)) / tile, 0.0, 1.0)  # 0 left .. 1 right
		var v := clampf((z - (z0 + r * tile)) / tile, 0.0, 1.0)  # 0 far .. 1 near
		match ch:
			"^":
				return base + LEVEL_H * (1.0 - v)
			"v":
				return base + LEVEL_H * v
			">":
				return base + LEVEL_H * u
			"<":
				return base + LEVEL_H * (1.0 - u)
		return base

	## Vertex height: the highest floor among the tiles touching (x, z) (so a jump lip keeps the
	## ramp's height and floors meet cleanly), the pit if none is floor.
	func height(x: float, z: float) -> float:
		var h := -INF
		for o in [
			Vector2(-1e-6, -1e-6), Vector2(1e-6, -1e-6), Vector2(-1e-6, 1e-6), Vector2(1e-6, 1e-6)
		]:
			var t := tile_at(x + o.x, z + o.y)
			if solid(t.x, t.y):
				h = maxf(h, tile_height(t.x, t.y, x, z))
		if h > -INF:
			return h
		var t := tile_at(x, z)
		return PIT if inside(t.x, t.y) else LAWN

	func surface(x: float, z: float) -> int:
		var t := tile_at(x, z)
		match at(t.x, t.y):
			"S":
				return HoleData.Surface.SAND
			"W":
				return HoleData.Surface.WATER
			".":
				return HoleData.Surface.OUT
		return HoleData.Surface.GREEN

	## Edge between tiles a and b (4-neighbours) is a wall if one side has no floor, or if the
	## floor heights along the shared edge differ.
	func walled(a: Vector2i, b: Vector2i) -> bool:
		if _jump_lip(a, b) or _jump_lip(b, a) or _landing_edge(a, b) or _landing_edge(b, a):
			return false
		if not solid(a.x, a.y) or not solid(b.x, b.y):
			return true
		var d := b - a
		# Two sample points on the shared edge, evaluated from each tile's own surface.
		var p0: Vector2
		var p1: Vector2
		if d.x != 0:
			var ex := x0 + maxi(a.x, b.x) * tile
			p0 = Vector2(ex, z0 + a.y * tile + 0.25 * tile)
			p1 = Vector2(ex, z0 + a.y * tile + 0.75 * tile)
		else:
			var ez := z0 + maxi(a.y, b.y) * tile
			p0 = Vector2(x0 + a.x * tile + 0.25 * tile, ez)
			p1 = Vector2(x0 + a.x * tile + 0.75 * tile, ez)
		for p in [p0, p1]:
			var ha := tile_height(a.x, a.y, p.x, p.y)
			var hb := tile_height(b.x, b.y, p.x, p.y)
			if absf(ha - hb) > 0.02:
				return true
		return false

	## a is a ramp whose high edge faces b, and b is nothing: an open jump lip.
	func _jump_lip(a: Vector2i, b: Vector2i) -> bool:
		var ch := at(a.x, a.y)
		return RAMP_UP.has(ch) and RAMP_UP[ch] == b - a and not solid(b.x, b.y)

	## a is a floor tile that a jump lands on, and b is the gap in front of it: the edge is open
	## (a wall there would catch every ball that only just clears the gap).
	func _landing_edge(a: Vector2i, b: Vector2i) -> bool:
		if not solid(a.x, a.y) or solid(b.x, b.y):
			return false
		for ramp in ramps_landing_on(a):
			var up: Vector2i = RAMP_UP[at(ramp.x, ramp.y)]
			if b - a == -up:
				return true
		return false

	## Ramps whose jump lands on tile t (first floor tile within 3 tiles past the lip).
	func ramps_landing_on(t: Vector2i) -> Array:
		var out := []
		for ch in RAMP_UP:
			var up: Vector2i = RAMP_UP[ch]
			for k in range(2, 5):
				var ramp: Vector2i = t - up * k
				if at(ramp.x, ramp.y) != ch or not _jump_lip(ramp, ramp + up):
					continue
				var clear := true
				for g in range(1, k):
					if solid(ramp.x + up.x * g, ramp.y + up.y * g):
						clear = false
				if clear:
					out.append(ramp)
		return out

	func add_walls(d: HoleData) -> void:
		# Horizontal edges (between rows r-1 and r, including the outer ones), merged along x.
		for r in rows + 1:
			var run_start := -1
			for c in cols + 1:
				var wall := c < cols and _edge_h(c, r)
				if wall and run_start < 0:
					run_start = c
				elif not wall and run_start >= 0:
					var z := z0 + r * tile
					d.add_wall(x0 + run_start * tile, z, x0 + c * tile, z)
					run_start = -1
		# Vertical edges (between columns c-1 and c), merged along z.
		for c in cols + 1:
			var run_start := -1
			for r in rows + 1:
				var wall := r < rows and _edge_v(c, r)
				if wall and run_start < 0:
					run_start = r
				elif not wall and run_start >= 0:
					var x := x0 + c * tile
					d.add_wall(x, z0 + run_start * tile, x, z0 + r * tile)
					run_start = -1

	## Wall on the edge above tile row r at column c (between (c, r-1) and (c, r))?
	func _edge_h(c: int, r: int) -> bool:
		var a := Vector2i(c, r - 1)
		var b := Vector2i(c, r)
		if not solid(a.x, a.y) and not solid(b.x, b.y):
			return false
		return walled(a, b)

	## Wall on the edge left of column c at row r (between (c-1, r) and (c, r))?
	func _edge_v(c: int, r: int) -> bool:
		var a := Vector2i(c - 1, r)
		var b := Vector2i(c, r)
		if not solid(a.x, a.y) and not solid(b.x, b.y):
			return false
		return walled(a, b)
