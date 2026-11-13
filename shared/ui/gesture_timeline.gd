class_name GestureTimeline
extends RefCounted
## Pose of the how-to fingertip glyph over one demo loop (pure; no nodes). One instance per card:
## call evaluate(t_ms) and read the fields.
## Phases (ms): enter, anticipate, action, hold, exit, rest.
## Timings follow Android's own touch feedback (ripple 75 in / 225 grow / 150 out, 100 ms tap) and
## Material 3 easing; see docs/research/How to play tutorial videos.md.
##   tap   : press, ripple, lift            swipe : 200 ms ease-out stroke with a tapered trail
##   drag  : steps of 60 ms move + 100 ms dwell (one column each)
##   flick : 120 ms ease-in burst with speed ghosts       none : no glyph (rule cards)

const ENTER := 250.0
const ANTICIPATE := 120.0
const EXIT := 200.0
const REST := 800.0
const TAP := 100.0
const RIPPLE_IN := 75.0
const RIPPLE_GROW := 225.0
const RIPPLE_OUT := 150.0
const SWIPE := 200.0
const DRAG_MOVE := 60.0
const DRAG_DWELL := 100.0
const FLICK := 120.0
## Glyph slides this far (design units) while entering / leaving.
const SLIDE := 60.0
const KINDS := ["tap", "swipe", "drag", "flick", "none"]

var kind := "none"
var from := Vector2.ZERO
var to := Vector2.ZERO
var steps := 1
var hold := 700.0

## Derived timings (ms from loop start).
var press_ms := ENTER + ANTICIPATE
var lift_ms := 0.0
var exit_ms := 0.0
var loop_ms := 0.0

## Pose after evaluate().
var visible := false
var pos := Vector2.ZERO
var alpha := 0.0
var scale := 1.0
var down := false
## Ripple: progress 0..1 of its growth (-1 = none) and its alpha.
var ripple := -1.0
var ripple_alpha := 0.0
## Trail from trail_from to pos (swipe/flick), alpha 0 = hidden.
var trail_from := Vector2.ZERO
var trail_alpha := 0.0
## Flick speed ghosts on/off.
var ghosts := false


func _init(
	gesture_kind := "none",
	start := Vector2.ZERO,
	end := Vector2.ZERO,
	n_steps := 1,
	hold_ms := 700.0
) -> void:
	assert(KINDS.has(gesture_kind))
	kind = gesture_kind
	from = start
	to = end
	steps = maxi(1, n_steps)
	hold = hold_ms
	lift_ms = press_ms + action_ms()
	exit_ms = lift_ms + hold
	loop_ms = exit_ms + EXIT + REST


func action_ms() -> float:
	match kind:
		"tap":
			return TAP
		"swipe":
			return SWIPE
		"drag":
			return steps * (DRAG_MOVE + DRAG_DWELL)
		"flick":
			return FLICK
	return 0.0


## Time (ms) at which drag step i (1-based) has finished moving; the board snaps then.
func step_done_ms(i: int) -> float:
	return press_ms + (i - 1) * (DRAG_MOVE + DRAG_DWELL) + DRAG_MOVE


## How many drag steps are complete at time t.
func steps_done(t: float) -> int:
	var n := 0
	for i in range(1, steps + 1):
		if t >= step_done_ms(i):
			n = i
	return n


func evaluate(t: float) -> void:
	visible = kind != "none" and t < exit_ms + EXIT
	down = false
	ripple = -1.0
	ripple_alpha = 0.0
	trail_alpha = 0.0
	ghosts = false
	scale = 1.0
	if not visible:
		alpha = 0.0
		return
	var away := Vector2(SLIDE * 0.6, SLIDE)  # the glyph arrives from / leaves towards bottom-right
	if t < ENTER:
		var k := decel(t / ENTER)
		pos = from + away * (1.0 - k)
		alpha = k
	elif t < press_ms:
		pos = from
		alpha = 1.0
		scale = lerpf(1.0, 0.95, (t - ENTER) / ANTICIPATE)
	elif t < lift_ms:
		alpha = 1.0
		down = true
		scale = 0.95
		_action(t - press_ms)
	elif t < exit_ms:
		pos = to if kind != "tap" else from
		alpha = 1.0
		_after_lift(t - lift_ms)
	else:
		var k := accel((t - exit_ms) / EXIT)
		pos = (to if kind != "tap" else from) + away * k
		alpha = 1.0 - k
		_after_lift(t - lift_ms)
	if kind == "tap":
		_ripple(t - press_ms)


func _action(a: float) -> void:
	match kind:
		"tap":
			pos = from
		"swipe":
			pos = from.lerp(to, decel(a / SWIPE))
			trail_from = from
			trail_alpha = 1.0
		"flick":
			pos = from.lerp(to, accel(a / FLICK))
			trail_from = from
			trail_alpha = 1.0
			ghosts = true
		"drag":
			var per := DRAG_MOVE + DRAG_DWELL
			var i := mini(int(a / per), steps - 1)
			var within := a - i * per
			var k := (float(i) + minf(1.0, within / DRAG_MOVE)) / steps
			pos = from.lerp(to, k)


## Trails fade quickly after the finger lifts.
func _after_lift(since: float) -> void:
	if kind == "swipe" or kind == "flick":
		trail_from = from
		trail_alpha = clampf(1.0 - since / 220.0, 0.0, 1.0)


func _ripple(since_press: float) -> void:
	if since_press < 0.0:
		return
	var total := RIPPLE_GROW + RIPPLE_OUT
	if since_press > total:
		return
	ripple = clampf(since_press / RIPPLE_GROW, 0.0, 1.0)
	ripple_alpha = minf(1.0, since_press / RIPPLE_IN)
	if since_press > RIPPLE_GROW:
		ripple_alpha = 1.0 - (since_press - RIPPLE_GROW) / RIPPLE_OUT


## Material-style curves: decelerate for entrances, accelerate for exits.
static func decel(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - c, 3.0)


static func accel(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * c
