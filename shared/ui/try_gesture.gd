class_name TryGesture
extends RefCounted
## Recognises the player's own attempt at a how-to card's gesture ("Try it"). Pure: give it the
## finger's movement (canvas units), duration and finger count; it names the gesture.
## Thresholds match the games' own input: Stack Drop flick 110 px at 0.9 px/ms, 26 px tap slop.

const TAP_PX := 30.0
const TAP_MS := 350.0
const SWIPE_PX := 60.0
const DRAG_PX := 80.0
const FLICK_PX := 110.0
const FLICK_SPEED := 0.9


## "tap", "two_finger", "flick", "drag" (mostly sideways), "swipe" or "" (nothing clear).
static func classify(delta: Vector2, ms: float, fingers: int) -> String:
	if fingers >= 2:
		return "two_finger"
	var dist := delta.length()
	if dist <= TAP_PX and ms <= TAP_MS:
		return "tap"
	if delta.y >= FLICK_PX and delta.y / maxf(1.0, ms) >= FLICK_SPEED and delta.y > absf(delta.x):
		return "flick"
	if absf(delta.x) >= DRAG_PX and absf(delta.x) > absf(delta.y):
		return "drag"
	if dist >= SWIPE_PX:
		return "swipe"
	return ""


## Does a recognised gesture satisfy what the card asks for? ("hold" = tap on HOLD or two fingers;
## the caller checks the tap landed on the HOLD chip.)
static func satisfies(want: String, got: String) -> bool:
	match want:
		"tap":
			return got == "tap"
		"swipe":
			return got in ["swipe", "drag", "flick"]
		"drag":
			return got == "drag"
		"flick":
			return got == "flick"
		"hold":
			return got == "tap" or got == "two_finger"
	return false
