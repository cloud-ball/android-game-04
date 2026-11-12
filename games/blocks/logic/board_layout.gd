class_name BoardLayout
extends RefCounted
## Screen layout for Stack Drop, as pure arithmetic (no nodes): from the canvas size (1080 wide,
## height follows the phone's aspect) and the safe-area insets it derives the cell size and every
## HUD rectangle, in canvas units. Design: docs/research/Stack Drop board redesign.md.
##   top band    : CPU mini-board | status (score, lines, level) | pause, then the NEXT strip
##   middle      : the 9 x 18 well (garbage meter flush against its left edge), pedestal below
##   bottom band : HOLD (thumb reach), then a keep-out above the system gesture area

const COLS := 9
const ROWS := 18
## Outer margin; nothing tappable and no gesture starts inside it (back-gesture zones).
const SIDE := 42.0
## Horizontal space per side reserved beside the well (meter + posts + breathing room).
const GUTTER := 130.0
## Width of the well in cells including its corner posts.
const WELL_SPAN := 9.32
const STATUS_H := 120.0
const NEXT_GAP := 12.0
const NEXT_H := 130.0
const TOP_TO_WELL := 278.0  # status + gap + NEXT strip + gap
const PEDESTAL_H := 140.0
const HOLD_W := 216.0
const HOLD_H := 168.0
const BAND_GAP := 16.0
const MIN_BOTTOM_INSET := 84.0  # 32 dp gesture area on a 420 dp phone
const PAUSE_HIT := 144.0
const CPU_W := 108.0
const MIN_CELL := 56.0
const MAX_CELL_DP := 38.0
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
static func compute(canvas_size: Vector2, insets: Dictionary, units_per_dp: float) -> BoardLayout:
	var l := BoardLayout.new()
	l.canvas = canvas_size
	var side := maxf(SIDE, maxf(float(insets.get("left", 0.0)), float(insets.get("right", 0.0))))
	l.top = maxf(float(insets.get("top", 0.0)), 0.0) + BAND_GAP
	l.bottom = canvas_size.y - maxf(float(insets.get("bottom", 0.0)), MIN_BOTTOM_INSET) - BAND_GAP
	var well_top_min := l.top + TOP_TO_WELL
	var well_bottom_max := l.bottom - HOLD_H - BAND_GAP - PEDESTAL_H
	var avail_h := well_bottom_max - well_top_min
	var by_width := (canvas_size.x - 2.0 * GUTTER) / WELL_SPAN
	var by_height := avail_h / ROWS
	l.cell = clampf(minf(by_width, by_height), MIN_CELL, MAX_CELL_DP * units_per_dp)
	var w := l.cell * COLS
	var h := l.cell * ROWS
	var extra := maxf(0.0, avail_h - h)
	l.well = Rect2((canvas_size.x - w) * 0.5, well_top_min + extra * 0.5, w, h)
	l.status = Rect2(
		side + CPU_W + 20.0,
		l.top,
		canvas_size.x - 2.0 * side - CPU_W - 20.0 - PAUSE_HIT - 14.0,
		STATUS_H
	)
	l.pause = Rect2(canvas_size.x - side - PAUSE_HIT, l.top - 12.0, PAUSE_HIT, PAUSE_HIT)
	l.cpu = Rect2(side, l.top, CPU_W, STATUS_H + NEXT_GAP + NEXT_H)
	l.next = Rect2(
		l.status.position.x,
		l.top + STATUS_H + NEXT_GAP,
		canvas_size.x - side - l.status.position.x,
		NEXT_H
	)
	l.garbage = Rect2(l.well.position.x - 50.0, l.well.position.y, 30.0, h)
	var ped_w := 10.4 * l.cell
	l.pedestal = Rect2((canvas_size.x - ped_w) * 0.5, l.well.end.y, ped_w, PEDESTAL_H)
	l.hold = Rect2(side, l.bottom - HOLD_H, HOLD_W, HOLD_H)
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
