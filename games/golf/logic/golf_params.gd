class_name GolfParams
extends RefCounted
## Fairway Flick physical constants and aerodynamic coefficients (SI units). Pure; no nodes.
## Sources and reasoning: docs/research/Fairway Flick golf game design.md (ball physics notes).
## The coefficient curves are polynomial / piecewise-linear on purpose: no pow / exp in the solver
## hot path (cross-device determinism, the golf rules).

## Drag-crisis table (see cd()): logistic blend at Re 50,000 + 5,000 * i.
const CRISIS_RE0 := 50000.0
const CRISIS_STEP := 5000.0
const CRISIS := [
	0.9975, 0.9933, 0.9820, 0.9526, 0.8808, 0.7311, 0.5, 0.2689, 0.1192, 0.0474, 0.0180, 0.0067, 0.0
]

var g := 9.81
var air_density := 1.225  # kg/m^3
var radius := 0.021335  # 42.67 mm ball
var mass := 0.04593  # kg
## Reynolds number per m/s of airspeed for this ball at sea level (Re ~ 2,890 * V).
var re_per_speed := 2890.0
## Drag: Cd = cd_min + cd_crisis * crisis(Re) + cd_spin * spin_term(S). crisis(Re) is the logistic
## 1 / (1 + e^(0.0002 (Re - 80000))) the research validated against TrackMan, tabulated every
## 5,000 from Re 50,000 (1) to 110,000 (0) and interpolated linearly (no exp at run time).
var cd_min := 0.225
var cd_crisis := 0.275
var cd_spin := 0.18
## Lift: Cl = 1.99 S - 3.255 S^2 up to S = 0.25, then linear with slope 0.3625 (no clamp).
var cl_a := 1.99
var cl_b := 3.255
var cl_knee := 0.25
var cl_slope := 0.3625
## Spin decay per metre travelled (about 4 %/s at typical speeds).
var spin_decay_per_m := 0.001


## Course conditions: thinner air (altitude) lowers density and, with it, the Reynolds number
## per m/s, so the drag crisis moves with the air (both must scale together).
func apply_preset(preset: CoursePreset) -> void:
	air_density = 1.225 * preset.air_factor
	re_per_speed = 2890.0 * preset.air_factor


func area() -> float:
	return PI * radius * radius


func inertia() -> float:
	return 0.4 * mass * radius * radius


## Drag coefficient for airspeed v (m/s) and spin ratio s = omega * r / v.
func cd(v: float, s: float) -> float:
	return cd_min + cd_crisis * crisis(re_per_speed * v) + cd_spin * _spin_term(s)


## Drag-crisis blend: ~1 below Re 50,000 (subcritical), 0 above 110,000.
static func crisis(re: float) -> float:
	var x := (re - CRISIS_RE0) / CRISIS_STEP
	if x <= 0.0:
		return 1.0 if x < -1.0 else lerpf(1.0, CRISIS[0], x + 1.0)
	var i := int(x)
	if i >= CRISIS.size() - 1:
		return 0.0
	return lerpf(CRISIS[i], CRISIS[i + 1], x - i)


## Lift coefficient for spin ratio s (continuous at the knee, never clamped).
func cl(s: float) -> float:
	var x := maxf(s, 0.0)
	if x <= cl_knee:
		return cl_a * x - cl_b * x * x
	var at_knee := cl_a * cl_knee - cl_b * cl_knee * cl_knee
	return at_knee + cl_slope * (x - cl_knee)


## 1 - e^(-3 s^2) without exp: its 5-term Taylor series in x = 3 s^2, with x held at <= 1.2
## (s <= 0.63, past every full shot's launch spin ratio). Error < 0.004 on that range.
static func _spin_term(s: float) -> float:
	var x := minf(3.0 * s * s, 1.2)
	return x * (1.0 - x * (0.5 - x * (1.0 / 6.0 - x * (1.0 / 24.0 - x / 120.0))))
