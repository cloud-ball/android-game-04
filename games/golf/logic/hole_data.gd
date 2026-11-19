class_name HoleData
extends RefCounted
## One hole's terrain as data (pure; no nodes): a vertex height grid plus one surface type per cell.
## Research: docs/research/Fairway Flick golf game design.md (Godot implementation notes) - holes
## are authored from tiles, then baked into this grid; physics, rendering and the minimap read it.
## Frame: x right, y up, z towards the player (downrange is -z). Cell (i, j) spans
## x0 + i*cell .. +cell and z0 + j*cell .. +cell. Each cell is two triangles split along the
## (i, j) -> (i+1, j+1) diagonal, exactly like the render mesh, so the ball never floats or sinks.

enum Surface { OUT, TEE, FAIRWAY, ROUGH, FRINGE, GREEN, SAND, WATER, PATH }

const DROP_CLEAR := 0.3  # metres of dry ground around a ball dropped after water
var x0 := 0.0
var z0 := 0.0
var cell := 0.5
var nx := 0  # cells along x
var nz := 0  # cells along z
## (nx + 1) * (nz + 1) vertex heights, row-major in z: index = j * (nx + 1) + i.
var heights := PackedFloat32Array()
## nx * nz surface types (Surface), index = j * nx + i.
var surface := PackedByteArray()
var tee := Vector3.ZERO
var pin := Vector3.ZERO
var par := 3
## Mini-golf walls: 4 floats per segment (x0, z0, x1, z1); all walls are `wall_height` tall.
var walls := PackedFloat64Array()
var wall_height := 0.4
## Half the thickness of a wall rail (the ball keeps radius + this from the wall's centre line).
var wall_half := 0.0
## Cup radius (regulation 54 mm; arcade holes use a larger cup) and an arcade "pull": a slow ball
## within CUP_PULL_R of the cup is drawn in at up to this many m/s^2 (0 = real golf).
var cup_r := 0.054
var cup_pull := 0.0
## Round bumpers: 3 floats each (x, z, radius).
var bumpers := PackedFloat64Array()


func setup(origin_x: float, origin_z: float, cell_size: float, cells_x: int, cells_z: int) -> void:
	x0 = origin_x
	z0 = origin_z
	cell = cell_size
	nx = cells_x
	nz = cells_z
	heights.resize((nx + 1) * (nz + 1))
	heights.fill(0.0)
	surface.resize(nx * nz)
	surface.fill(Surface.FAIRWAY)


## Fills vertex heights from f(x, z) -> float and surfaces from s(x, z) -> int (cell centres).
func fill(height_fn: Callable, surface_fn := Callable()) -> void:
	for j in nz + 1:
		for i in nx + 1:
			heights[j * (nx + 1) + i] = height_fn.call(x0 + i * cell, z0 + j * cell)
	if surface_fn.is_valid():
		for j in nz:
			for i in nx:
				surface[j * nx + i] = surface_fn.call(x0 + (i + 0.5) * cell, z0 + (j + 0.5) * cell)


func add_wall(x0: float, z0: float, x1: float, z1: float) -> void:
	walls.append_array(PackedFloat64Array([x0, z0, x1, z1]))


## A closed chain of walls through the given [x, z] points.
func add_wall_loop(points: Array) -> void:
	for k in points.size():
		var a: Array = points[k]
		var b: Array = points[(k + 1) % points.size()]
		add_wall(a[0], a[1], b[0], b[1])


func add_bumper(x: float, z: float, r: float) -> void:
	bumpers.append_array(PackedFloat64Array([x, z, r]))


func contains(x: float, z: float) -> bool:
	return x >= x0 and z >= z0 and x <= x0 + nx * cell and z <= z0 + nz * cell


func _h(i: int, j: int) -> float:
	return heights[clampi(j, 0, nz) * (nx + 1) + clampi(i, 0, nx)]


## Ground height at (x, z), on the render triangles. Outside the grid: the nearest edge height.
func height(x: float, z: float) -> float:
	var fx := clampf((x - x0) / cell, 0.0, nx)
	var fz := clampf((z - z0) / cell, 0.0, nz)
	var i := mini(int(fx), nx - 1)
	var j := mini(int(fz), nz - 1)
	var u := fx - i
	var v := fz - j
	var h00 := _h(i, j)
	var h11 := _h(i + 1, j + 1)
	if u >= v:
		var h10 := _h(i + 1, j)
		return h00 + (h10 - h00) * u + (h11 - h10) * v
	var h01 := _h(i, j + 1)
	return h00 + (h11 - h01) * u + (h01 - h00) * v


## Slope (dh/dx, dh/dz) of the triangle under (x, z).
func gradient(x: float, z: float) -> Vector2:
	var fx := clampf((x - x0) / cell, 0.0, nx)
	var fz := clampf((z - z0) / cell, 0.0, nz)
	var i := mini(int(fx), nx - 1)
	var j := mini(int(fz), nz - 1)
	var h00 := _h(i, j)
	var h11 := _h(i + 1, j + 1)
	if fx - i >= fz - j:
		var h10 := _h(i + 1, j)
		return Vector2(h10 - h00, h11 - h10) / cell
	var h01 := _h(i, j + 1)
	return Vector2(h11 - h01, h01 - h00) / cell


## Slope (dh/dx, dh/dz) written into out[0], out[1] in 64-bit (Vector2 is 32-bit); no allocation.
func grad_into(x: float, z: float, out: PackedFloat64Array) -> void:
	var fx := clampf((x - x0) / cell, 0.0, nx)
	var fz := clampf((z - z0) / cell, 0.0, nz)
	var i := mini(int(fx), nx - 1)
	var j := mini(int(fz), nz - 1)
	var h00 := _h(i, j)
	var h11 := _h(i + 1, j + 1)
	if fx - i >= fz - j:
		var h10 := _h(i + 1, j)
		out[0] = (h10 - h00) / cell
		out[1] = (h11 - h10) / cell
	else:
		var h01 := _h(i, j + 1)
		out[0] = (h11 - h01) / cell
		out[1] = (h01 - h00) / cell


## Unit surface normal under (x, z).
func normal(x: float, z: float) -> Vector3:
	var g := gradient(x, z)
	return Vector3(-g.x, 1.0, -g.y).normalized()


func surface_at(x: float, z: float) -> int:
	if not contains(x, z):
		return Surface.OUT
	var i := mini(int((x - x0) / cell), nx - 1)
	var j := mini(int((z - z0) / cell), nz - 1)
	return surface[j * nx + i]


## Where a ball is replaced after going into water: from the spot it entered, walk back towards
## `back_to` (the tee) until there are DROP_CLEAR metres of dry, in-play surface all round, so the
## next shot does not start on the water's edge. Falls back to `back_to`. Pure.
func water_drop(entered: Vector3, back_to: Vector3) -> Vector3:
	var p := Vector2(entered.x, entered.z)
	var goal := Vector2(back_to.x, back_to.z)
	var dist := p.distance_to(goal)
	if dist > 1e-6:
		var dir := (goal - p) / dist
		var t := 0.0
		while t <= dist:
			var q := p + dir * t
			if _dry_around(q.x, q.y, DROP_CLEAR):
				return Vector3(q.x, height(q.x, q.y), q.y)
			t += 0.05
	return Vector3(goal.x, height(goal.x, goal.y), goal.y)


func _dry_around(x: float, z: float, r: float) -> bool:
	for k in 9:
		var qx := x
		var qz := z
		if k > 0:
			var a := TAU * (k - 1) / 8.0
			qx += cos(a) * r
			qz += sin(a) * r
		var sf := surface_at(qx, qz)
		if sf == Surface.WATER or sf == Surface.OUT:
			return false
	return true


## First time the ball (centre a -> b, radius r) touches the ground, as a fraction of the segment
## in [0, 1], or -1 if it stays clear. The ground under the segment is piecewise linear (cells and
## their diagonals), so clearance f(t) = y - h - r is linear on each piece: the root is exact and a
## fast ball cannot step through a thin ridge between samples.
## Vector3 is 32-bit, so the solver passes 64-bit coordinates through sweep_d().
func sweep(a: Vector3, b: Vector3, r: float) -> float:
	return sweep_d(a.x, a.y, a.z, b.x, b.y, b.z, r)


func sweep_d(ax: float, ay: float, az: float, bx: float, by: float, bz: float, r: float) -> float:
	var f_prev := ay - height(ax, az) - r
	if f_prev <= 0.0:
		return 0.0
	var ts := _breaks(ax, az, bx, bz)
	var t_prev := 0.0
	for t in ts:
		var f := ay + (by - ay) * t - height(ax + (bx - ax) * t, az + (bz - az) * t) - r
		if f <= 0.0:
			return t_prev + (t - t_prev) * f_prev / (f_prev - f)
		f_prev = f
		t_prev = t
	return -1.0


## Sorted fractions in (0, 1] where the segment's ground track crosses a grid line or a cell
## diagonal, ending with 1. Allocates one small array per call (a few entries per substep).
func _breaks(pax: float, paz: float, pbx: float, pbz: float) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	var ax := (pax - x0) / cell
	var az := (paz - z0) / cell
	var dx := (pbx - x0) / cell - ax
	var dz := (pbz - z0) / cell - az
	_grid_crossings(ax, dx, out)
	_grid_crossings(az, dz, out)
	out.append(1.0)
	out.sort()
	# Diagonal crossings: inside each piece, u - v = (x - i) - (z - j) changes sign at most once.
	var extra := PackedFloat64Array()
	var t0 := 0.0
	for t1 in out:
		var tm := (t0 + t1) * 0.5
		var ci := floorf(ax + dx * tm)
		var cj := floorf(az + dz * tm)
		var d0 := (ax + dx * t0 - ci) - (az + dz * t0 - cj)
		var dd := dx - dz
		if absf(dd) > 1e-12:
			var tc := t0 - d0 / dd
			if tc > t0 and tc < t1:
				extra.append(tc)
		t0 = t1
	if not extra.is_empty():
		out.append_array(extra)
		out.sort()
	return out


static func _grid_crossings(start: float, delta: float, out: PackedFloat64Array) -> void:
	if absf(delta) < 1e-12:
		return
	var lo := minf(start, start + delta)
	var hi := maxf(start, start + delta)
	var k := floorf(lo) + 1.0
	while k < hi:
		out.append((k - start) / delta)
		k += 1.0
