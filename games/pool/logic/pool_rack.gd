class_name PoolRack
extends RefCounted
## Sets up an 8-ball rack on a CueSim: apex ball on the foot spot (+y half-way to the top rail),
## 8 in the middle of the third row, one solid and one stripe on the back corners; cue ball on the
## head spot. A seeded jitter (default up to 0.2 mm) varies each break while staying bit-exact.

const ROWS := [[1], [9, 2], [10, 8, 3], [11, 4, 13, 6], [5, 14, 7, 15, 12]]
const ROW_STEP := 0.8660254037844386  # sqrt(3) / 2
const DEFAULT_JITTER := 0.0002


static func setup(sim: CueSim, seed_value := 1, jitter := DEFAULT_JITTER) -> void:
	sim.clear()
	var r := sim.p.radius
	var hl := sim.table.hl
	var spacing := 2.0 * r + jitter + 1e-7
	var state := [maxi(1, seed_value)]
	sim.place(0, 0.0, -hl * 0.5)
	var apex_y := hl * 0.5
	for row in ROWS.size():
		var balls: Array = ROWS[row]
		for k in balls.size():
			var x := (k - row * 0.5) * spacing
			var y := apex_y + row * spacing * ROW_STEP
			# Offsets of at most 0.45 * jitter / 2 per axis cannot close the jitter gap.
			x += (_rand(state) - 0.5) * jitter * 0.45
			y += (_rand(state) - 0.5) * jitter * 0.45
			sim.place(balls[k], x, y)


## xorshift32 in [0, 1); state is a one-element array so the caller's sequence advances.
static func _rand(state: Array) -> float:
	var x: int = state[0]
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= x >> 17
	x ^= (x << 5) & 0xFFFFFFFF
	state[0] = x
	return float(x & 0xFFFFFF) / 16777216.0


## Puts a ball back (WPA 1.5): on the foot spot, else the nearest free point on the long string
## (the centre line) towards the foot rail, then towards the head. Never touching the cue ball.
static func spot(sim: CueSim, ball: int) -> void:
	var r := sim.p.radius
	var foot := sim.table.hl * 0.5
	var y := foot
	while y <= sim.table.hl - r:
		if _free(sim, ball, 0.0, y):
			sim.place(ball, 0.0, y)
			return
		y += 0.0005
	y = foot
	while y >= -sim.table.hl + r:
		if _free(sim, ball, 0.0, y):
			sim.place(ball, 0.0, y)
			return
		y -= 0.0005


static func _free(sim: CueSim, ball: int, x: float, y: float) -> bool:
	var r := sim.p.radius
	for i in CueSim.N:
		if i == ball or not sim.on_table(i):
			continue
		var dx: float = sim.px[i] - x
		var dy: float = sim.py[i] - y
		var need := 2.0 * r + (0.001 if i == 0 else 0.0)  # a gap from the cue ball
		if dx * dx + dy * dy < need * need:
			return false
	return true
