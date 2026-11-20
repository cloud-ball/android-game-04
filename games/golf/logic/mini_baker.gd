class_name MiniBaker
extends RefCounted
## Bakes a mini-golf hole from a tile map (pure, deterministic: + - * / only) into HoleData with
## walls, bumpers, ramps, sand, water, tee and cup.
## Plan: docs/plans/2026-11-15-cup-dash-minigolf.md (step C).
##
## Spec (games/golf/data/mini/*.json):
##   tile: tile size in metres (default 3)
##   map: rows of characters, top row = far end (-z), bottom row = tee end; left = -x
##     .  nothing (out of bounds; a pit 1.5 m down)    G  green floor      T  tee (green)
##     H  cup (green)    B  green with a bumper         S  sand            W  water
##     ^ v < >  ramp rising one level in the arrow direction (^ = towards -z, the far end)
##   levels: optional rows of digits (same shape); floor height = level x LEVEL_H
##   wind: optional [x, z] push on a rolling ball in m/s^2 (+x right, -z towards the far end),
##     clamped to WIND_MAX in length
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
## Strongest wind: a rolling ball feels 5/7 of it, well under the carpet's static hold, so a ball
## at rest never creeps; over a 3 s roll it drifts a ball about a metre.
const WIND_MAX := 0.12
const FLOOR := "GTHBSW^v<>"
const EDGE := -1000000  # _Map._runs: a grid line on a tile edge
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
	var wind: Variant = spec.get("wind", [])
	var two: bool = wind is Array and (wind as Array).size() >= 2
	var wx := float(wind[0]) if two else 0.0  # a malformed "wind" is calm
	var wz := float(wind[1]) if two else 0.0
	var wl := sqrt(wx * wx + wz * wz)  # 64-bit (a Vector2 would round to 32)
	var k := WIND_MAX / wl if wl > WIND_MAX else 1.0
	d.wind_x = wx * k
	d.wind_z = wz * k
	m.fill_grids(d, x0, z0)
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


## The height and surface grids computed point by point with _Map.height / surface: the slow
## reference that _Map.fill_grids must match bit for bit (tests). Returns [heights, surface].
static func reference_grids(spec: Dictionary) -> Array:
	var m := _Map.new(spec)
	var d := bake(spec)
	var heights := PackedFloat32Array()
	heights.resize(d.heights.size())
	var surface := PackedByteArray()
	surface.resize(d.surface.size())
	for j in d.nz + 1:
		for i in d.nx + 1:
			heights[j * (d.nx + 1) + i] = m.height(d.x0 + i * CELL, d.z0 + j * CELL)
	for j in d.nz:
		for i in d.nx:
			surface[j * d.nx + i] = m.surface(d.x0 + (i + 0.5) * CELL, d.z0 + (j + 0.5) * CELL)
	return [heights, surface]


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


## Direction to aim from a point: toward the neighbouring tile closest to the cup on the flow
## field (round corners), or straight at the cup when already on its tile or off the map.
static func flow_dir(spec: Dictionary, pin: Vector3, from: Vector3) -> Vector3:
	var straight := Vector3(pin.x - from.x, 0.0, pin.z - from.z)
	var f := flow_field(spec)
	var tile := float(spec.get("tile", 3.0))
	var rows: int = spec.map.size()
	var cols := 0
	for r in spec.map:
		cols = maxi(cols, str(r).length())
	var c := int(floorf((from.x + cols * tile * 0.5) / tile))
	var r := int(floorf((from.z + rows * tile) / tile))
	if c < 0 or r < 0 or c >= cols or r >= rows or f[r * cols + c] <= tile * 0.5:
		return straight.normalized() if straight.length() > 0.01 else Vector3(0, 0, -1)
	var best := Vector2i(c, r)
	var best_v := f[r * cols + c]
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var n := Vector2i(c + dx, r + dz)
			if n.x < 0 or n.y < 0 or n.x >= cols or n.y >= rows:
				continue
			var v := f[n.y * cols + n.x]
			if v >= 0.0 and v < best_v:
				best_v = v
				best = n
	var tc := Vector3(
		-cols * tile * 0.5 + (best.x + 0.5) * tile, 0.0, -rows * tile + (best.y + 0.5) * tile
	)
	var d := Vector3(tc.x - from.x, 0.0, tc.z - from.z)
	if best == Vector2i(c, r) or d.length() < 0.01:
		return straight.normalized()
	return d.normalized()


## Route distance (metres along the flow field) from a world point to the cup's tile; 1e5 when the
## point is off the map or on a tile that cannot reach the cup. `field` from flow_field(spec).
static func flow_metres(spec: Dictionary, field: PackedFloat64Array, q: Vector3) -> float:
	var tile := float(spec.get("tile", 3.0))
	var rows: int = spec.map.size()
	var cols := 0
	for r in spec.map:
		cols = maxi(cols, str(r).length())
	var c := int(floorf((q.x + cols * tile * 0.5) / tile))
	var r := int(floorf((q.z + rows * tile) / tile))
	if c < 0 or r < 0 or c >= cols or r >= rows or field[r * cols + c] < 0.0:
		return 1e5
	return field[r * cols + c]


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

	## height() and surface() for every grid point at once, bit-identical to calling them point by
	## point (MiniBaker.reference_grids, tested) but much faster. Everything that depends only on
	## the column or the row is worked out once; along a grid row, the points between two tile
	## edges lie in one tile, so a run of them is filled in one go unless the tile is a sideways
	## ramp. Points on tile edges take the full max-of-touching-tiles path. The nudge is the same
	## float32-rounded 1e-6 that height() adds through its Vector2 offsets.
	func fill_grids(d: HoleData, gx0: float, gz0: float) -> void:
		var kind := PackedInt32Array()  # per tile: -1 no floor, 0 flat, 1 ^, 2 v, 3 >, 4 <
		var base := PackedFloat64Array()
		var surf := PackedByteArray()
		kind.resize(rows * cols)
		base.resize(rows * cols)
		surf.resize(rows * cols)
		for r in rows:
			for c in cols:
				var ch := at(c, r)
				var k := r * cols + c
				kind[k] = ("^v><".find(ch) + 1) if FLOOR.contains(ch) else -1
				base[k] = level(c, r) * LEVEL_H
				surf[k] = surface(x0 + (c + 0.5) * tile, z0 + (r + 0.5) * tile)
		var e: float = Vector2(1e-6, 0.0).x
		var cx := _axis(d.nx + 1, gx0, x0, e)  # [tile at x - e, at x + e, at x, u - e, u + e]
		var rz := _axis(d.nz + 1, gz0, z0, e)
		var runs := _runs(cx[0], cx[1])
		var heights := PackedFloat32Array()
		for j in d.nz + 1:
			var r0: int = rz[0][j]
			if r0 != rz[1][j]:  # on a tile edge: every point the full way
				for i in d.nx + 1:
					heights.append(_point_h(kind, base, cx, rz, i, j))
				continue
			var v: float = rz[3][j]
			for run: Vector3i in runs:
				if run.z == EDGE:
					heights.append(_point_h(kind, base, cx, rz, run.x, j))
					continue
				var c := run.z
				var k := -1 if not inside(c, r0) else kind[r0 * cols + c]
				if k == 3 or k == 4:  # sideways ramp: height changes along the row
					for i in range(run.x, run.y):
						heights.append(_tile_h(kind, base, c, r0, cx[3][i], v))
				else:
					var h := _tile_h(kind, base, c, r0, 0.0, v)
					if h == -INF:
						h = PIT if inside(c, r0) else LAWN
					heights.append_array(_filled(run.y - run.x, h))
		d.heights = heights
		var sc := PackedInt32Array()
		for i in d.nx:
			sc.append(int(floorf((gx0 + (i + 0.5) * CELL - x0) / tile)))
		var srun := _runs(sc, sc)
		var surface_grid := PackedByteArray()
		for j in d.nz:
			var r := int(floorf((gz0 + (j + 0.5) * CELL - z0) / tile))
			for run: Vector3i in srun:
				var code: int = surf[r * cols + run.z] if inside(run.z, r) else HoleData.Surface.OUT
				var seg := PackedByteArray()
				seg.resize(run.y - run.x)
				seg.fill(code)
				surface_grid.append_array(seg)
		d.surface = surface_grid

	## The full height() rule at grid point (i, j): the highest floor among the touching tiles,
	## else the pit inside the map and the lawn outside it.
	func _point_h(
		kind: PackedInt32Array, base: PackedFloat64Array, cx: Array, rz: Array, i: int, j: int
	) -> float:
		var c0: int = cx[0][i]
		var c1: int = cx[1][i]
		var r0: int = rz[0][j]
		var r1: int = rz[1][j]
		var h := _tile_h(kind, base, c0, r0, cx[3][i], rz[3][j])
		if c1 != c0:
			h = maxf(h, _tile_h(kind, base, c1, r0, cx[4][i], rz[3][j]))
		if r1 != r0:
			h = maxf(h, _tile_h(kind, base, c0, r1, cx[3][i], rz[4][j]))
			if c1 != c0:
				h = maxf(h, _tile_h(kind, base, c1, r1, cx[4][i], rz[4][j]))
		if h == -INF:
			h = PIT if inside(cx[2][i], rz[2][j]) else LAWN
		return h

	## Runs of grid lines that lie in one tile column: Vector3i(start, end, tile) where lo == hi,
	## and Vector3i(i, i + 1, EDGE) for a line on a tile edge (lo != hi).
	func _runs(lo: PackedInt32Array, hi: PackedInt32Array) -> Array[Vector3i]:
		var out: Array[Vector3i] = []
		var i := 0
		while i < lo.size():
			if lo[i] != hi[i]:
				out.append(Vector3i(i, i + 1, EDGE))
				i += 1
				continue
			var start := i
			while i < lo.size() and lo[i] == lo[start] and hi[i] == lo[start]:
				i += 1
			out.append(Vector3i(start, i, lo[start]))
		return out

	static func _filled(count: int, value: float) -> PackedFloat32Array:
		var a := PackedFloat32Array()
		a.resize(count)
		a.fill(value)
		return a

	## Per grid line along one axis: tile index at p - e, p + e and p, and the position across
	## the first two tiles (0..1), exactly as tile_at() and tile_height() compute them.
	func _axis(count: int, g0: float, m0: float, e: float) -> Array:
		var lo := PackedInt32Array()
		var hi := PackedInt32Array()
		var mid := PackedInt32Array()
		var flo := PackedFloat64Array()
		var fhi := PackedFloat64Array()
		for i in count:
			var p := g0 + i * CELL
			var a := int(floorf((p + -e - m0) / tile))
			var b := int(floorf((p + e - m0) / tile))
			lo.append(a)
			hi.append(b)
			mid.append(int(floorf((p - m0) / tile)))
			flo.append(clampf((p - (m0 + a * tile)) / tile, 0.0, 1.0))
			fhi.append(clampf((p - (m0 + b * tile)) / tile, 0.0, 1.0))
		return [lo, hi, mid, flo, fhi]

	## tile_height() from the flat tile arrays; -INF where the tile has no floor.
	func _tile_h(
		kind: PackedInt32Array, base: PackedFloat64Array, c: int, r: int, u: float, v: float
	) -> float:
		if c < 0 or r < 0 or c >= cols or r >= rows:
			return -INF
		var k := r * cols + c
		var h := -INF
		match kind[k]:
			0:
				h = base[k]
			1:
				h = base[k] + LEVEL_H * (1.0 - v)
			2:
				h = base[k] + LEVEL_H * v
			3:
				h = base[k] + LEVEL_H * u
			4:
				h = base[k] + LEVEL_H * (1.0 - u)
		return h

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
