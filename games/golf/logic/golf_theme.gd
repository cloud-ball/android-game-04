class_name GolfTheme
extends RefCounted
## A world's look as pure data (like CoursePreset): every colour the course uses, ordered on a
## value ladder - surroundings darkest, carpet mid, rails lighter, ball / cup rim / aim guide
## brightest. Research: docs/research/Fairway Flick mini golf visuals.md ("A strict value ladder").
## Colour meanings stay fixed across worlds: red-orange = danger, amber = boost, tan = sand.

var name := "meadow"
var lawn := Color(0.32, 0.54, 0.23)
var carpet := Color(0.2, 0.62, 0.32)
var sand := Color(0.93, 0.84, 0.62)
var water := Color(0.1, 0.38, 0.6)
var rail_body := Color(0.86, 0.66, 0.42)  # light painted wood, lighter than the carpet
var rail_cap := Color(0.98, 0.95, 0.88)
var bumper := Color(0.92, 0.3, 0.2)  # red-orange: a hazard that bounces you
var flag := Color(1.0, 0.82, 0.18)
var cup_rim := Color(1.0, 1.0, 1.0)
var ball := Color(1.0, 1.0, 1.0)
var ball_outline := Color(0.05, 0.08, 0.1)
var bush := Color(0.17, 0.4, 0.2)
## Saturated, never white or near-white (white is the ball's).
var flowers := [
	Color(1.0, 0.4, 0.55), Color(1.0, 0.78, 0.2), Color(0.66, 0.42, 0.96), Color(1.0, 0.55, 0.25)
]
var sun_pitch := -48.0
var sun_yaw := -35.0
var sky_top := Color(0.3, 0.55, 0.88)
var sky_horizon := Color(0.78, 0.88, 0.96)


static func meadow() -> GolfTheme:
	return GolfTheme.new()


## Relative luminance (Rec. 709) of an sRGB colour, for the value-ladder test.
static func luminance(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b
