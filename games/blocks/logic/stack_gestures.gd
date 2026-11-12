class_name StackGestures
extends RefCounted
## Turns touch input into Stack Drop actions (pure: feed events + time, get action names).
##   tap                      -> "cw"
##   horizontal drag          -> "left"/"right", one per `cell_px` dragged (follows the finger)
##   slow drag down           -> "soft", one per `cell_px`
##   fast flick down          -> "hard" (on release)
##   second finger tap        -> "hold"

## Viewport pixels the finger moves for one column/row step.
var cell_px := 70.0
## A tap: released within this time and distance.
var tap_ms := 260
var tap_px := 26.0
## A flick down: at least this far and this fast (px per ms) at release.
var flick_px := 110.0
var flick_speed := 0.9
## Optional: func(position) -> bool; touches that start where it returns true are ignored
## (HUD buttons, screen-edge back-gesture zones, the bottom gesture area).
var reject := Callable()

var _down := false
var _start := Vector2.ZERO
var _anchor := Vector2.ZERO
var _start_ms := 0
var _moved := false
var _axis := ""  # "", "h" or "v" once the drag commits to a direction
var _fingers := 0


## Feed one input event; returns the actions it produced (often none).
func feed(event: InputEvent, now_ms: int) -> PackedStringArray:
	var out := PackedStringArray()
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_fingers += 1
			if _fingers == 2:
				out.append("hold")
				_moved = true  # the first finger's lift is not a tap any more
				return out
			if _fingers == 1:
				if reject.is_valid() and reject.call(t.position):
					return out
				_down = true
				_start = t.position
				_anchor = t.position
				_start_ms = now_ms
				_moved = false
				_axis = ""
		else:
			_fingers = maxi(0, _fingers - 1)
			if _fingers == 0 and _down:
				_down = false
				out.append_array(_release(t.position, now_ms))
	elif event is InputEventScreenDrag and _down and _fingers == 1:
		out.append_array(_drag((event as InputEventScreenDrag).position))
	return out


func _drag(pos: Vector2) -> PackedStringArray:
	var out := PackedStringArray()
	var total := pos - _start
	if _axis == "" and total.length() > tap_px:
		_axis = "h" if absf(total.x) > absf(total.y) else "v"
		_moved = true
	if _axis == "h":
		while pos.x - _anchor.x >= cell_px:
			out.append("right")
			_anchor.x += cell_px
		while _anchor.x - pos.x >= cell_px:
			out.append("left")
			_anchor.x -= cell_px
	elif _axis == "v":
		while pos.y - _anchor.y >= cell_px:
			out.append("soft")
			_anchor.y += cell_px
	return out


func _release(pos: Vector2, now_ms: int) -> PackedStringArray:
	var out := PackedStringArray()
	var total := pos - _start
	var elapsed := maxi(1, now_ms - _start_ms)
	if not _moved and elapsed <= tap_ms and total.length() <= tap_px:
		out.append("cw")
	elif _axis == "v" and total.y >= flick_px and total.y / elapsed >= flick_speed:
		out.append("hard")
	return out
