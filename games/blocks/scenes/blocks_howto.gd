class_name BlocksHowto
extends RefCounted
## Stack Drop how-to cards: looping demos on a stylised 6 x 9 mini-well (HowtoDeck design units,
## 920 x 920) using the real shard shapes and gem colours. The board reacts on the gesture's beat:
## rotate on the tap, one column per drag step, drop on the flick's lift.

const COLS := 6
const ROWS := 9
const CELL := 88.0
## Well origin: centred on cards without a side panel, left-aligned when HOLD / CPU sit beside it.
const WELL_CENTRED := Vector2(196, 56)
const WELL_LEFT := Vector2(60, 56)
const SIDE_X := 640.0  # right-hand column: HOLD chip / CPU mini-well
const SIDE_W := 240.0
## Settled blocks (top row first); "#" = filled. Rows 7-8 miss only column 2.
const BASE := [
	"......",
	"......",
	"......",
	"......",
	"......",
	"......",
	"#....#",
	"##.###",
	"##.###",
]
const LONG := 0
const SQUARE := 1
const TEE := 2
const HOOK := 6
const HOOK_B := 5

static var well := WELL_CENTRED


## posters: {"tap", "drag", "drop", "hold", "garbage"} -> Callable(Control) (150 px icons).
static func cards(posters: Dictionary) -> Array:
	var fx := WELL_CENTRED.x + 4.0 * CELL  # centre of the square shard (columns 3-4)
	var shard_mid := WELL_CENTRED + Vector2(1.5 * CELL, 2.0 * CELL)
	return [
		{
			"title": "Tap to rotate",
			"sub": "Tap anywhere. Shards slide off walls if needed.",
			"demo": _demo_rotate,
			"poster": posters["tap"],
			"gesture": GestureTimeline.new("tap", Vector2(810, 470), Vector2(810, 470), 1, 1300),
		},
		{
			"title": "Drag to move",
			"sub": "Each short step moves one column.",
			"demo": _demo_drag,
			"poster": posters["drag"],
			"gesture":
			GestureTimeline.new("drag", shard_mid, shard_mid + Vector2(3 * CELL, 0), 3, 1000),
		},
		{
			"title": "Flick down to drop",
			"sub": "A quick flick slams the shard down.",
			"demo": _demo_flick,
			"poster": posters["drop"],
			"gesture": GestureTimeline.new("flick", Vector2(fx, 190), Vector2(fx, 470), 1, 1300),
		},
		{
			"title": "Tap HOLD to keep",
			"sub": "Save a shard for later. Two fingers work too.",
			"demo": _demo_hold,
			"poster": posters["hold"],
			"gesture": GestureTimeline.new("tap", Vector2(760, 176), Vector2(760, 176), 1, 1600),
			"try": "hold",
			"try_rect": Rect2(Vector2(SIDE_X, WELL_LEFT.y), Vector2(SIDE_W, 240)),
		},
		{
			"title": "Clear rows, send garbage",
			"sub": "Cleared rows push junk into the CPU's tower.",
			"demo": _demo_garbage,
			"poster": posters["garbage"],
			"gesture": GestureTimeline.new("flick", Vector2(280, 150), Vector2(280, 430), 1, 2200),
			"modes": ["vs"],
		},
	]


# --- demos -------------------------------------------------------------------------------------


static func _demo_rotate(c: Control, t: float, g: GestureTimeline) -> void:
	well = WELL_CENTRED
	var a := fade(t, g)
	_well(c, a)
	_base(c, a, 0, 0.0)
	var rot := 1 if t >= g.press_ms else 0
	var pop := 1.0 + 0.12 * clampf(1.0 - (t - g.press_ms) / 150.0, 0.0, 1.0) * float(rot)
	var at := Vector2(2, 1)
	_ghost(c, TEE, rot, int(at.x), a)
	_shard(c, TEE, rot, at, a, pop)


static func _demo_drag(c: Control, t: float, g: GestureTimeline) -> void:
	well = WELL_CENTRED
	var a := fade(t, g)
	_well(c, a)
	_base(c, a, 0, 0.0)
	var col := g.steps_done(t)
	# Column ticks above the well: the ones already passed light up.
	for i in range(1, 4):
		var x := well.x + (i + 1.5) * CELL
		var lit := col >= i
		var tick := Color(1, 1, 1, (0.9 if lit else 0.3) * a)
		c.draw_line(Vector2(x, well.y - 34), Vector2(x, well.y - 12), tick, 6.0 if lit else 4.0)
	var at := Vector2(col, 1)
	_ghost(c, HOOK, 0, col, a)
	_shard(c, HOOK, 0, at, a, 1.0)


static func _demo_flick(c: Control, t: float, g: GestureTimeline) -> void:
	well = WELL_CENTRED
	var a := fade(t, g)
	_well(c, a)
	_base(c, a, 0, 0.0)
	var land := _landing(SQUARE, 0, 2)
	var k := GestureTimeline.accel((t - g.lift_ms + 60.0) / 120.0)
	var y := lerpf(1.0, float(land), k)
	if k < 1.0:
		_ghost(c, SQUARE, 0, 2, a)
	_shard(c, SQUARE, 0, Vector2(2, y), a, 1.0)
	var since := t - (g.lift_ms + 60.0)
	if since > 0.0 and since < 260.0:
		var flash := 1.0 - since / 260.0
		var r := _cells_rect(SQUARE, 0, Vector2(2, land))
		c.draw_rect(r.grow(10.0), Color(1, 1, 1, 0.55 * flash * a))
		for i in 6:
			var px := r.position.x + r.size.x * (i + 0.5) / 6.0
			var up := 30.0 * since / 260.0 * (1.0 + i % 2)
			c.draw_circle(Vector2(px, r.end.y - up), 6.0, Color(1, 1, 1, flash * a))


static func _demo_hold(c: Control, t: float, g: GestureTimeline) -> void:
	well = WELL_LEFT
	var a := fade(t, g)
	_well(c, a)
	_base(c, a, 0, 0.0)
	var chip := Rect2(Vector2(SIDE_X, well.y), Vector2(SIDE_W, 240))
	var pressed := t >= g.press_ms
	var glow := clampf(1.0 - (t - g.press_ms) / 300.0, 0.0, 1.0) if pressed else 0.0
	_chip(c, chip, "HOLD", a, glow)
	var chip_mid := chip.get_center() + Vector2(0, 22)
	var k := GestureTimeline.decel((t - g.press_ms) / 200.0) if pressed else 0.0
	if k < 1.0:
		# The long shard flies from the well into the HOLD chip.
		var from := _cells_rect(LONG, 0, Vector2(1, 0)).get_center()
		var mid := from.lerp(chip_mid, k)
		_shard_at(c, LONG, 0, mid, CELL * lerpf(1.0, 0.42, k), a)
		_ghost(c, LONG, 0, 1, a * (1.0 - k))
	else:
		_shard_at(c, LONG, 0, chip_mid, CELL * 0.42, a)
		var appear := clampf((t - g.press_ms - 200.0) / 200.0, 0.0, 1.0)
		_ghost(c, HOOK_B, 0, 2, a * appear)
		_shard(c, HOOK_B, 0, Vector2(2, 0), a * appear, 1.0)


static func _demo_garbage(c: Control, t: float, g: GestureTimeline) -> void:
	well = WELL_LEFT
	var a := fade(t, g)
	_well(c, a)
	var drop_k := GestureTimeline.accel((t - g.lift_ms + 60.0) / 120.0)
	var landed_ms := g.lift_ms + 60.0
	var clear_ms := landed_ms + 260.0
	var shift := clampf((t - clear_ms - 180.0) / 150.0, 0.0, 1.0)
	var cleared := t >= clear_ms + 180.0
	_base(c, a, 2 if cleared else 0, shift)
	var land := _landing(LONG, 1, 0)
	if not cleared:
		var y := lerpf(0.0, float(land), drop_k)
		if drop_k < 1.0:
			_ghost(c, LONG, 1, 0, a)
		_shard(c, LONG, 1, Vector2(0, y), a, 1.0)
	else:
		# The shard's top two cells survive the clear and slide down with the rows above.
		for row in [land, land + 1]:
			_gem(c, _cell(Vector2(2, row + 2.0 * shift)), BlocksView.GEM_COLORS[LONG], a)
	if t >= clear_ms and t < clear_ms + 180.0:
		var flash := 1.0 - (t - clear_ms) / 180.0
		var rows := Rect2(well + Vector2(0, 7 * CELL), Vector2(COLS * CELL, 2 * CELL))
		c.draw_rect(rows, Color(1, 1, 1, (0.4 + 0.5 * flash) * a))
	# CPU mini-well and the garbage that arrives in it.
	var cpu := Rect2(Vector2(SIDE_X, well.y + 250), Vector2(SIDE_W, 540))
	_chip(c, cpu, "CPU", a, 0.0)
	var send_ms := clear_ms + 120.0
	var arrive_ms := send_ms + 520.0
	var mini := 32.0
	var mw := Rect2(cpu.position + Vector2((SIDE_W - 6 * mini) * 0.5, 70), Vector2(6, 13) * mini)
	var rise := clampf((t - arrive_ms) / 200.0, 0.0, 1.0)
	_cpu_well(c, mw, mini, rise, a)
	if t >= send_ms and t < arrive_ms + 120.0:
		var from := well + Vector2(2.5 * CELL, 8 * CELL)
		var to := mw.position + Vector2(mw.size.x * 0.5, mw.size.y - mini)
		var ctrl := (from + to) * 0.5 + Vector2(0, -420)
		for i in 3:
			var k := clampf((t - send_ms - i * 70.0) / 450.0, 0.0, 1.0)
			if k <= 0.0 or k >= 1.0:
				continue
			var p := from.lerp(ctrl, k).lerp(ctrl.lerp(to, k), k)
			c.draw_circle(p, 22.0, Color(1, 0.75, 0.3, 0.3 * a))
			c.draw_circle(p, 11.0, Color(1, 0.9, 0.55, a))


# --- helpers -----------------------------------------------------------------------------------


static func fade(t: float, g: GestureTimeline) -> float:
	return clampf(minf(t / 200.0, (g.loop_ms - t) / 300.0), 0.0, 1.0)


static func _well(c: Control, a: float) -> void:
	var r := Rect2(well, Vector2(COLS, ROWS) * CELL)
	c.draw_rect(r.grow(10.0), Color(0.78, 0.76, 0.94, 0.85 * a), false, 8.0)
	c.draw_rect(r, Color(0.05, 0.06, 0.14, 0.95 * a))
	var line := Color(0.35, 0.38, 0.6, 0.35 * a)
	for x in range(1, COLS):
		c.draw_line(well + Vector2(x * CELL, 0), well + Vector2(x * CELL, ROWS * CELL), line, 2.0)
	for y in range(1, ROWS):
		c.draw_line(well + Vector2(0, y * CELL), well + Vector2(COLS * CELL, y * CELL), line, 2.0)


## Settled blocks; `removed` bottom rows already cleared, the rest slide down by `shift` of them.
static func _base(c: Control, a: float, removed: int, shift: float) -> void:
	for y in ROWS:
		if y >= ROWS - removed:
			continue
		var row: String = BASE[y]
		for x in COLS:
			if row[x] != "#":
				continue
			var fy := y + (removed * shift if removed > 0 else 0.0)
			_gem(c, _cell(Vector2(x, fy)), _base_color(x, y), a)


static func _base_color(x: int, y: int) -> Color:
	return BlocksView.GEM_COLORS[(x * 3 + y * 5) % BlocksView.GEM_COLORS.size()].darkened(0.15)


static func _cell(p: Vector2) -> Rect2:
	return Rect2(well + p * CELL + Vector2(3, 3), Vector2(CELL - 6, CELL - 6))


static func _gem(c: Control, r: Rect2, col: Color, a: float) -> void:
	c.draw_rect(r, Color(col, a))
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.18)), Color(1, 1, 1, 0.3 * a))
	c.draw_rect(
		Rect2(r.position + Vector2(0, r.size.y * 0.82), Vector2(r.size.x, r.size.y * 0.18)),
		Color(0, 0, 0, 0.22 * a)
	)


static func _shard(c: Control, kind: int, rot: int, box: Vector2, a: float, pop: float) -> void:
	var r := _cells_rect(kind, rot, box)
	var mid := r.get_center()
	for p in ShardData.cells(kind, rot):
		var cell := _cell(box + Vector2(p))
		if pop != 1.0:
			cell = Rect2(mid + (cell.position - mid) * pop, cell.size * pop)
		_gem(c, cell, BlocksView.GEM_COLORS[kind], a)


## A shard centred on a point at any cell size (used while flying into the HOLD chip).
static func _shard_at(c: Control, kind: int, rot: int, mid: Vector2, size: float, a: float) -> void:
	var cells: Array = ShardData.cells(kind, rot)
	var lo := Vector2(99, 99)
	var hi := Vector2(-99, -99)
	for p in cells:
		lo = lo.min(Vector2(p))
		hi = hi.max(Vector2(p))
	var span := (hi - lo + Vector2.ONE) * size
	for p in cells:
		var pos := mid - span * 0.5 + (Vector2(p) - lo) * size
		_gem(
			c,
			Rect2(pos + Vector2(2, 2), Vector2(size - 4, size - 4)),
			BlocksView.GEM_COLORS[kind],
			a
		)


static func _cells_rect(kind: int, rot: int, box: Vector2) -> Rect2:
	var r := Rect2()
	var first := true
	for p in ShardData.cells(kind, rot):
		var cell := _cell(box + Vector2(p))
		r = cell if first else r.merge(cell)
		first = false
	return r


static func _filled(x: int, y: int) -> bool:
	if x < 0 or x >= COLS or y >= ROWS:
		return true
	if y < 0:
		return false
	return BASE[y][x] == "#"


## Box row where the shard comes to rest when dropped in box column x.
static func _landing(kind: int, rot: int, x: int) -> int:
	var y := 0
	while true:
		for p in ShardData.cells(kind, rot):
			if _filled(x + p.x, y + 1 + p.y):
				return y
		y += 1
	return y


static func _ghost(c: Control, kind: int, rot: int, x: int, a: float) -> void:
	if a <= 0.0:
		return
	var y := _landing(kind, rot, x)
	var col := BlocksView.GEM_COLORS[kind].lightened(0.35)
	for p in ShardData.cells(kind, rot):
		c.draw_rect(_cell(Vector2(x, y) + Vector2(p)).grow(-4.0), Color(col, 0.6 * a), false, 4.0)


static func _chip(c: Control, r: Rect2, caption: String, a: float, glow: float) -> void:
	var accent := Color(0.86, 0.72, 1.0)
	c.draw_rect(r, Color(0.03, 0.035, 0.08, 0.85 * a))
	c.draw_rect(
		r, Color(accent.lerp(Color.WHITE, glow), (0.35 + 0.65 * glow) * a), false, 3.0 + 5.0 * glow
	)
	var font := UiKit.font(900)
	var w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
	c.draw_string(
		font,
		r.position + Vector2((r.size.x - w) * 0.5, 46),
		caption,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		36,
		Color(accent, a)
	)


## The CPU's mini tower: a few settled rows; a grey garbage row rises from the bottom.
static func _cpu_well(c: Control, mw: Rect2, cell: float, rise: float, a: float) -> void:
	c.draw_rect(mw, Color(1, 1, 1, 0.06 * a))
	var rows := [[1, 1, 0, 1, 1, 1], [1, 0, 0, 1, 1, 0], [0, 0, 0, 1, 0, 0]]
	for i in rows.size():
		var y := 12 - i - rise
		for x in 6:
			if rows[i][x] == 1:
				var r := Rect2(mw.position + Vector2(x, y) * cell, Vector2(cell - 2, cell - 2))
				c.draw_rect(r, Color(BlocksView.GEM_COLORS[(x + i * 2) % 7], a))
	if rise > 0.0:
		for x in 6:
			if x == 4:
				continue
			var r := Rect2(mw.position + Vector2(x, 13 - rise) * cell, Vector2(cell - 2, cell - 2))
			c.draw_rect(r, Color(BlocksView.GARBAGE_COLOR.lightened(0.2), a))


## Static poster for the garbage card (reduce motion): two cleared rows and an arrow to a tower.
static func poster_garbage(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(150, 150)), Color(0.2, 0.3, 0.8, 0.25))
	for y in 2:
		c.draw_rect(Rect2(Vector2(12, 96 + y * 22), Vector2(70, 18)), Color(1, 1, 1, 0.85))
	c.draw_line(Vector2(70, 80), Vector2(112, 40), Color(1, 0.85, 0.4), 6.0)
	c.draw_colored_polygon(
		PackedVector2Array([Vector2(122, 30), Vector2(100, 34), Vector2(116, 52)]),
		Color(1, 0.85, 0.4)
	)
	c.draw_rect(Rect2(Vector2(104, 70), Vector2(36, 70)), Color(1, 1, 1, 0.12))
	c.draw_rect(Rect2(Vector2(104, 124), Vector2(36, 14)), BlocksView.GARBAGE_COLOR.lightened(0.2))
