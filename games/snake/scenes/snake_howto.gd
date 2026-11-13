class_name SnakeHowto
extends RefCounted
## Serpent Grid how-to cards: looping demos drawn on a stylised 9 x 9 board (HowtoDeck design
## units, 920 x 920). Movement is keyed to the gesture's lift so the snake turns on the beat.
## Original vector art in the game's own colours.

const N := 9
const CELL := 92.0
const ORIGIN := Vector2(46, 46)
const SPEED := 3.5  # cells per second in the demos
const GRID := Color(0.3, 0.42, 1.0, 0.32)
const EDGE := Color(0.55, 0.7, 1.0, 0.75)
const PLAYER := Color(0.4, 1.0, 0.6)
const CPU := Color(1.0, 0.4, 0.88)
const ORB := Color(1.0, 0.85, 0.3)
## Player route used by the swipe and crash cards: along row 6, then up column 4.
const TURN_PATH := [
	Vector2(0, 6),
	Vector2(1, 6),
	Vector2(2, 6),
	Vector2(3, 6),
	Vector2(4, 6),
	Vector2(4, 5),
	Vector2(4, 4),
	Vector2(4, 3),
	Vector2(4, 2),
	Vector2(4, 1),
	Vector2(4, 0),
]
const TURN_INDEX := 4  # path index of the turn cell


## posters: {"swipe", "wall", "crash"} -> Callable(Control) drawing the static 150 px icon.
static func cards(posters: Dictionary) -> Array:
	var swipe := GestureTimeline.new("swipe", Vector2(720, 790), Vector2(720, 500), 1, 1300)
	var crash := GestureTimeline.new("swipe", Vector2(720, 790), Vector2(720, 500), 1, 1900)
	return [
		{
			"title": "Swipe to turn",
			"sub": "Anywhere on the screen. Orbs make you grow.",
			"demo": _demo_swipe,
			"poster": posters["swipe"],
			"gesture": swipe,
		},
		{
			"title": "Edges wrap around",
			"sub": "Leave one side, come back on the other.",
			"demo": _demo_wrap,
			"poster": posters["wall"],
			"gesture": GestureTimeline.new("none", Vector2.ZERO, Vector2.ZERO, 1, 1830),
		},
		{
			"title": "Make the CPU crash",
			"sub": "Cut across its path with your body.",
			"demo": _demo_crash,
			"poster": posters["crash"],
			"gesture": crash,
			"modes": ["vs"],
		},
	]


# --- demos -------------------------------------------------------------------------------------


static func _demo_swipe(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_board(c, a, 0.0)
	var f := minf(_head_index(t, g), TURN_PATH.size() - 2.0)
	var eat_at := 7.0
	if f < eat_at:
		_orb(c, TURN_PATH[7], a, t)
	else:
		var since := (f - eat_at) / SPEED * 1000.0
		_pop(c, TURN_PATH[7], "+10", since, a)
	var length := 4 if f >= eat_at else 3
	_snake(c, TURN_PATH, f, length, PLAYER, a, false)


static func _demo_wrap(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	var head := minf(3.0 + SPEED * t / 1000.0, 11.6)
	var glow := smoothstep(7.6, 8.5, head) * (1.0 - smoothstep(11.0, 11.6, head))
	_board(c, a, glow)
	# Chevrons outside both edges: out on the right, back in on the left.
	var y := ORIGIN.y + 4.5 * CELL
	_chevron(c, Vector2(ORIGIN.x + N * CELL + 10, y), Color(EDGE, a * (0.4 + 0.6 * glow)))
	_chevron(c, Vector2(ORIGIN.x - 34, y), Color(EDGE, a * (0.4 + 0.6 * glow)))
	for k in 4:
		var p := Vector2(head - k, 4)
		_segment(c, p, _shade(PLAYER, k), a, true)
		if k == 0:
			_eyes(c, p, Vector2.RIGHT, a, true)


static func _demo_crash(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_board(c, a, 0.0)
	var f := minf(_head_index(t, g), TURN_PATH.size() - 1.0)
	_snake(c, TURN_PATH, f, 4, PLAYER, a, false)
	# CPU runs along row 3 into the player's body; it stops dead at the crash.
	var crash_ms := (3.55 + 2.2) / SPEED * 1000.0
	var x := minf(SPEED * t / 1000.0 - 2.2, 3.55)
	var crashed := t >= crash_ms
	var col := CPU if not crashed else CPU.lerp(Color(0.45, 0.45, 0.5), 0.7)
	for k in 3:
		_segment(c, Vector2(x - k, 3), _shade(col, k), a, false)
	_eyes(c, Vector2(x, 3), Vector2.RIGHT, a, false)
	if crashed:
		var since := t - crash_ms
		var at := _center(Vector2(x + 0.5, 3))
		var r := 30.0 + 90.0 * GestureTimeline.decel(since / 400.0)
		var burst := clampf(1.0 - since / 500.0, 0.0, 1.0)
		c.draw_arc(at, r, 0.0, TAU, 32, Color(1, 0.9, 0.4, burst * a), 8.0, true)
		for i in 8:
			var d := Vector2.RIGHT.rotated(i * TAU / 8.0)
			c.draw_line(at + d * r * 0.6, at + d * r * 1.1, Color(1, 0.9, 0.4, burst * a), 6.0)
		_label(c, "CRASH!", at + Vector2(-110, -90 - 40.0 * minf(1.0, since / 600.0)), 56, a)


# --- helpers -----------------------------------------------------------------------------------


## Board fades in for 200 ms and out over the last 300 ms of the loop (no jump on repeat).
static func fade(t: float, g: GestureTimeline) -> float:
	return clampf(minf(t / 200.0, (g.loop_ms - t) / 300.0), 0.0, 1.0)


## Path index of the head: it reaches the turn cell exactly when the swipe lifts.
static func _head_index(t: float, g: GestureTimeline) -> float:
	return TURN_INDEX + SPEED * (t - g.lift_ms) / 1000.0


static func _board(c: Control, a: float, edge_glow: float) -> void:
	var r := Rect2(ORIGIN, Vector2(N, N) * CELL)
	c.draw_rect(r, Color(0.05, 0.07, 0.2, 0.9 * a))
	for i in range(1, N):
		var o := i * CELL
		c.draw_line(ORIGIN + Vector2(o, 0), ORIGIN + Vector2(o, N * CELL), Color(GRID, a), 2.0)
		c.draw_line(ORIGIN + Vector2(0, o), ORIGIN + Vector2(N * CELL, o), Color(GRID, a), 2.0)
	var w := 4.0 + 8.0 * edge_glow
	var ec := Color(EDGE.lerp(Color.WHITE, edge_glow), a)
	c.draw_rect(r, ec, false, 4.0)
	if edge_glow > 0.0:
		var side := Color(0.6, 0.85, 1.0, 0.8 * edge_glow * a)
		c.draw_line(r.position, Vector2(r.position.x, r.end.y), side, w)
		c.draw_line(Vector2(r.end.x, r.position.y), r.end, side, w)


static func _center(p: Vector2) -> Vector2:
	return ORIGIN + (p + Vector2(0.5, 0.5)) * CELL


## A point f along a cell path (extrapolated behind the start so tails slide in from off-board).
static func _along(path: Array, f: float) -> Vector2:
	if f <= 0.0:
		var p0: Vector2 = path[0]
		var p1: Vector2 = path[1]
		return p0 + (p0 - p1) * -f
	var i := mini(int(f), path.size() - 2)
	var a: Vector2 = path[i]
	var b: Vector2 = path[i + 1]
	return a.lerp(b, f - i)


static func _snake(
	c: Control, path: Array, f: float, length: int, col: Color, a: float, wrap: bool
) -> void:
	for k in range(length - 1, -1, -1):
		_segment(c, _along(path, f - k), _shade(col, k), a, wrap)
	var head := _along(path, f)
	var dir := (head - _along(path, f - 0.3)).normalized()
	_eyes(c, head, dir if dir != Vector2.ZERO else Vector2.RIGHT, a, wrap)


static func _shade(col: Color, k: int) -> Color:
	return col.darkened(minf(0.45, 0.13 * k))


## One body cell at grid position p (fractional while moving), clipped to the board; with wrap
## it also appears on the opposite side while crossing an edge.
static func _segment(c: Control, p: Vector2, col: Color, a: float, wrap: bool) -> void:
	var board := Rect2(ORIGIN, Vector2(N, N) * CELL)
	var offsets: Array[float] = [0.0]
	if wrap:
		offsets = [0.0, -float(N), float(N)]
	for ox in offsets:
		var q := Vector2(p.x + ox, p.y)
		var r := Rect2(ORIGIN + q * CELL + Vector2(6, 6), Vector2(CELL - 12, CELL - 12))
		var clip := r.intersection(board)
		if clip.size.x > 1.0 and clip.size.y > 1.0:
			c.draw_rect(clip, Color(col, a))
			var top := Rect2(clip.position, Vector2(clip.size.x, minf(12.0, clip.size.y)))
			c.draw_rect(top, Color(1, 1, 1, 0.25 * a))


static func _eyes(c: Control, p: Vector2, dir: Vector2, a: float, wrap: bool) -> void:
	var x := fposmod(p.x, N) if wrap else p.x
	if x < -0.5 or x > N - 0.5:
		return
	var center := _center(Vector2(x, p.y))
	var side := Vector2(-dir.y, dir.x)
	for s in [-1.0, 1.0]:
		var e: Vector2 = center + dir * 14.0 + side * 16.0 * s
		c.draw_circle(e, 10.0, Color(1, 1, 1, a))
		c.draw_circle(e + dir * 3.0, 5.0, Color(0.05, 0.05, 0.1, a))


static func _orb(c: Control, cell: Vector2, a: float, t: float) -> void:
	var at := _center(cell)
	var pulse := 0.5 + 0.5 * sin(t / 1000.0 * TAU / 1.2)  # calm 1.2 s pulse
	c.draw_circle(at, 34.0 + 6.0 * pulse, Color(ORB, 0.25 * a))
	c.draw_circle(at, 22.0, Color(ORB, a))


static func _pop(c: Control, cell: Vector2, text: String, since: float, a: float) -> void:
	var k := clampf(since / 700.0, 0.0, 1.0)
	var at := _center(cell)
	c.draw_arc(at, 22.0 + 50.0 * k, 0.0, TAU, 28, Color(ORB, (1.0 - k) * a), 6.0, true)
	_label(c, text, at + Vector2(30, -40 - 50.0 * k), 48, a * (1.0 - k * 0.6))


static func _chevron(c: Control, at: Vector2, col: Color) -> void:
	c.draw_polyline(
		PackedVector2Array([at + Vector2(0, -18), at + Vector2(16, 0), at + Vector2(0, 18)]),
		col,
		6.0,
		true
	)


static func _label(c: Control, text: String, at: Vector2, size: int, a: float) -> void:
	var font := UiKit.font(900)
	c.draw_string_outline(
		font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color(0, 0, 0, 0.7 * a)
	)
	c.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 0.92, 0.5, a))
