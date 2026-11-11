class_name SwipeDetector
extends RefCounted
## Turns touch/mouse drags into 4-way swipes. A single drag can emit several swipes
## (the origin resets after each), so quick zig-zags register as separate turns.

enum Dir { UP, RIGHT, DOWN, LEFT }

## Minimum travel in viewport pixels before a swipe fires.
var threshold: float = 48.0

var _origin := Vector2.ZERO
var _down := false


## Feed every input event; returns a Dir value, or -1 when no swipe fired.
func feed(event: InputEvent) -> int:
	if event is InputEventScreenTouch:
		_down = event.pressed
		_origin = event.position
		return -1
	if event is InputEventScreenDrag and _down:
		return _track(event.position)
	return -1


func _track(pos: Vector2) -> int:
	var d := pos - _origin
	if d.length() < threshold:
		return -1
	_origin = pos
	return direction_of(d)


static func direction_of(d: Vector2) -> int:
	if absf(d.x) > absf(d.y):
		return Dir.RIGHT if d.x > 0.0 else Dir.LEFT
	return Dir.DOWN if d.y > 0.0 else Dir.UP
