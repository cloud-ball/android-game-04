class_name CueParams
extends RefCounted
## Physical constants for the cue solver (SI units). Defaults are pool on a 6-ft bar table; sources
## and reasoning in docs/research/Cue Club pool game design.md. Plain vars so tests can vary them.

var g := 9.81
var radius := 0.028575
var mass := 0.17
## Sliding (cloth) friction; rolling resistance (deceleration = mu_roll * g, no 5/7 factor).
## 2026-11-14 (docs/research/Cue Club versus mobile pool games.md): mu_roll 0.012 -> 0.010 and
## e_cushion 0.85 -> 0.95 make the WPA rail test pass (~4.1 table lengths, was 3.4); casual pockets
## 12.7 / 14.0 cm (were pro-spec 11.8 / 13.0) for friendlier breaks and cuts.
var mu_slide := 0.2
var mu_roll := 0.010
## Deceleration of spin about the vertical axis (rad/s^2). 2026-11-14: 10.9 -> 22 (the top of the
## measured range) and x2 again once the ball has stopped: stopped balls twirled in place for
## seconds after side english or a cut (phone feedback).
var spin_decel := 22.0
var spin_decel_still := 2.0
var e_ball := 0.93
var mu_ball := 0.055
## Cushions (Han 2005): restitution, friction, contact height as sin/cos of the contact angle
## (nose at 0.27 R above the ball centre). Literal constants: no sin/cos in the solver.
var e_cushion := 0.95
var mu_cushion := 0.2
var cushion_sin := 0.27
var cushion_cos := 0.9628603221651623
## Playfield between cushion noses; long axis is y (vertical on the phone).
## 2026-11-14: 7-ft (0.991 x 1.981) -> 6-ft bar table (33 x 66 in): the phone fits the table to its
## width, so a shorter table draws every ball ~16% bigger (phone feedback: balls too small).
var table_w := 0.838
var table_l := 1.676
## Pocket mouths (distance between jaw tips) and pocket depths.
var corner_mouth := 0.127
var side_mouth := 0.140
var corner_facing := 0.05
var side_facing := 0.045
## Capture: a ball is pocketed when its centre enters a circle this far behind the mouth line.
var corner_capture_depth := 0.042
var corner_capture_radius := 0.040
var side_capture_depth := 0.040
var side_capture_radius := 0.038
## Cue tip offset limit (fraction of the radius).
var max_tip_offset := 0.5


static func pool() -> CueParams:
	return CueParams.new()


func inertia() -> float:
	return 0.4 * mass * radius * radius
