class_name GolfSurfaces
extends RefCounted
## Bounce and roll parameters per HoleData.Surface (pure). Bounce = Penner's Daish model in a frame
## tilted by a fixed per-surface angle beta (Biber et al. 2023: no worse than Penner's crater
## angle); roll = constant deceleration. Research: ball physics notes, sections 4-5. Green values
## are sourced; fairway / fringe / rough / sand / path are starting points to tune (unsourced).
## Sines and cosines are literals, never computed at run time (cross-device determinism).

## Static hold: a ball at rest stays put while the slope pull is below this x the roll decel.
const STATIC_FACTOR := 1.1
## Bounce angle beta per degree used: [sin, cos].
const BETA := {
	0: [0.0, 1.0],
	3: [0.05233595624294383, 0.9986295347545738],
	15: [0.25881904510252074, 0.9659258262890683],
	16: [0.27563735581699916, 0.9612616959383189],
	18: [0.3090169943749474, 0.9510565162951535],
}

## Per surface (index = HoleData.Surface): restitution (-1 = Penner's speed curve), restitution
## scale, friction, bounce-tilt sin / cos, rolling deceleration (m/s^2).
var e := PackedFloat64Array()
var e_scale := PackedFloat64Array()
var mu := PackedFloat64Array()
var sin_b := PackedFloat64Array()
var cos_b := PackedFloat64Array()
var roll := PackedFloat64Array()


func _init(preset: CoursePreset = null) -> void:
	var pr := preset if preset != null else CoursePreset.new()
	var n := HoleData.Surface.size()
	for arr in [e, e_scale, mu, sin_b, cos_b, roll]:
		arr.resize(n)
	var fair_roll := 1.2 if pr.firm_fairways else 1.6
	_define(HoleData.Surface.TEE, 0.22, 0.5, 16, fair_roll)
	_define(HoleData.Surface.FAIRWAY, 0.22, 0.5, 16, fair_roll)
	_define(HoleData.Surface.FRINGE, 0.18, 0.45, 16, 1.0)
	_define(HoleData.Surface.ROUGH, 0.12, 0.7, 18, 4.5)
	_define(HoleData.Surface.SAND, 0.03, 0.8, 0, 8.0)
	_define(HoleData.Surface.PATH, 0.5, 0.5, 3, 0.8)
	if pr.firm_greens:
		# Penner's firm-green values (mu 0.25 with his ~15 deg crater angle): the ball holds or pulls
		# back with high spin. 11 deg (the notes' first guess) never spun back; this spins back about
		# half Penner's distances (+0.2 / -0.6 / -2.1 m at 809 / 1000 / 1200 rad/s) - tune by feel.
		_define(HoleData.Surface.GREEN, -1.0, 0.25, 15, pr.green_decel(), 1.0)
	else:
		_define(HoleData.Surface.GREEN, -1.0, 0.40, 15, pr.green_decel(), 1.0)
	# Terminal surfaces: the ball is gone (penalty); values unused.
	_define(HoleData.Surface.WATER, 0.0, 1.0, 0, 50.0)
	_define(HoleData.Surface.OUT, 0.0, 1.0, 0, 50.0)


func _define(s: int, rest: float, fric: float, beta: int, decel: float, scale := 1.0) -> void:
	e[s] = rest
	e_scale[s] = scale
	mu[s] = fric
	sin_b[s] = BETA[beta][0]
	cos_b[s] = BETA[beta][1]
	roll[s] = decel


## Restitution for a normal impact speed vn (m/s) on surface s.
func restitution(s: int, vn: float) -> float:
	if e[s] >= 0.0:
		return e[s]
	var p := 0.120 if vn > 20.0 else 0.510 - 0.0375 * vn + 0.000903 * vn * vn
	return minf(p * e_scale[s], 0.9)
