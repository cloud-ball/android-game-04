class_name BoardLayout
extends RefCounted
## Screen layout for Stack Drop, as pure arithmetic (no nodes): from the canvas size (1080 wide,
## height follows the phone's aspect) and the safe-area insets it derives the cell size and every
## HUD rectangle, in canvas units. Research: docs/research/Stack Drop board redesign.md;
## HOLD moved to the top band for a bigger tower: docs/plans/2026-11-12-stack-drop-bigger-tower.md.
##   top band : CPU mini-board | status (score, lines, level) | pause
##              CPU mini-board | HOLD | NEXT strip
##   middle   : the 12 x 24 well (garbage meter beside its left edge), pedestal below
##   bottom   : keep-out above the system gesture area

const COLS := StackState.W
const ROWS := StackState.H - StackState.HIDDEN
## Outer margin; nothing tappable and no gesture starts inside it (back-gesture zones).
const SIDE := 42.0
## Horizontal space per side reserved beside the well (meter + posts).
const GUTTER := 72.0
## Width of the well in cells including its corner posts.
const WELL_SPAN := COLS + 0.32
## Width of the pedestal in cells (BlocksView builds a hex of radius PEDESTAL_SPAN / 2).
const PEDESTAL_SPAN := COLS + 0.8
const STATUS_H := 116.0
const ROW_GAP := 16.0
## Second top row (HOLD + NEXT): at least this tall, and at least 48 dp.
const ROW2_MIN_H := 120.0
const PEDESTAL_H := 108.0
const HOLD_W := 150.0
const BAND_GAP := 16.0
const MIN_BOTTOM_INSET := 84.0  # 32 dp gesture area on a 420 dp phone
const PAUSE_HIT := 144.0
const CPU_W := 108.0
const MIN_CELL := 56.0
const MAX_CELL_DP := 42.0
const MIN_TAP_DP := 48.0
## Finger travel per column when dragging, independent of the cell size.
const DRAG_STEP_DP := 36.0

var canvas := Vector2.ZERO
var cell := 0.0
var top := 0.0  # first usable y (safe top + padding)
var bottom := 0.0  # last usable y (above the gesture keep-out)
var well := Rect2()
var status := Rect2()
var pause := Rect2()
var cpu := Rect2()
var next := Rect2()
var hold := Rect2()
var garbage := Rect2()
var pedestal := Rect2()
var keepout_bottom := Rect2()
var drag_step := 0.0


## insets: {top, bottom, left, right} in canvas units. units_per_dp = 1080 / screen width in dp.
## has_cpu = false (Solo) drops the CPU mini-board column so the status plate and HOLD move left.
static func compute(
	canvas_size: Vector2, insets: Dictionary, units_per_dp: float, has_cpu := true
) -> BoardLayout:
	var l := BoardLayout.new()
	l.canvas = canvas_size
	var side := maxf(SIDE, maxf(float(insets.get("left", 0.0)), float(insets.get("right", 0.0))))
	l.top = maxf(float(insets.get("top", 0.0)), 0.0) + BAND_GAP
	l.bottom = canvas_size.y - maxf(float(insets.get("bottom", 0.0)), MIN_BOTTOM_INSET)
	var row2_h := maxf(ROW2_MIN_H, MIN_TAP_DP * units_per_dp)
	var row2_y := l.top + STATUS_H + ROW_GAP
	var well_top_min := row2_y + row2_h + BAND_GAP
	var well_bottom_max := l.bottom - PEDESTAL_H
	var avail_h := well_bottom_max - well_top_min
	var by_width := (canvas_size.x - 2.0 * GUTTER) / WELL_SPAN
	var by_height := avail_h / ROWS
	var by_pedestal := (canvas_size.x - 2.0 * side) / PEDESTAL_SPAN
	var fit := minf(minf(by_width, by_height), by_pedestal)
	l.cell = clampf(fit, MIN_CELL, MAX_CELL_DP * units_per_dp)
	var w := l.cell * COLS
	var h := l.cell * ROWS
	var extra := maxf(0.0, avail_h - h)
	l.well = Rect2((canvas_size.x - w) * 0.5, well_top_min + extra * 0.5, w, h)
	var inner_x := side + CPU_W + 16.0 if has_cpu else side
	l.status = Rect2(inner_x, l.top, canvas_size.x - side - PAUSE_HIT - 14.0 - inner_x, STATUS_H)
	# Pause hit area: PAUSE_HIT wide, as tall as fits above row 2 (>= 48 dp on every phone).
	var pause_h := minf(PAUSE_HIT, STATUS_H + ROW_GAP + 12.0)
	l.pause = Rect2(canvas_size.x - side - PAUSE_HIT, l.top - 12.0, PAUSE_HIT, pause_h)
	if has_cpu:
		l.cpu = Rect2(side, l.top, CPU_W, row2_y + row2_h - l.top)
	l.hold = Rect2(inner_x, row2_y, HOLD_W, row2_h)
	var next_x := l.hold.end.x + 14.0
	l.next = Rect2(next_x, row2_y, canvas_size.x - side - next_x, row2_h)
	l.garbage = Rect2(l.well.position.x - 40.0, l.well.position.y, 22.0, h)
	var ped_w := PEDESTAL_SPAN * l.cell
	l.pedestal = Rect2((canvas_size.x - ped_w) * 0.5, l.well.end.y, ped_w, PEDESTAL_H)
	l.keepout_bottom = Rect2(0.0, l.bottom, canvas_size.x, canvas_size.y - l.bottom)
	l.drag_step = DRAG_STEP_DP * units_per_dp
	return l


## Rects that must never overlap each other (the play field and the HUD blocks).
func blocks() -> Dictionary:
	return {
		"status": status,
		"pause": pause,
		"cpu": cpu,
		"next": next,
		"well": well,
		"garbage": garbage,
		"pedestal": pedestal,
		"hold": hold,
	}


## True when a touch starting at p should be ignored by the board gestures
## (side margins, bottom gesture keep-out, and the tappable HUD buttons).
func rejects_gesture_at(p: Vector2) -> bool:
	return (
		p.x < SIDE
		or p.x > canvas.x - SIDE
		or keepout_bottom.has_point(p)
		or hold.has_point(p)
		or pause.has_point(p)
	)
