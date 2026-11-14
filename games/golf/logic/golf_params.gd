class_name GolfParams
extends RefCounted
## Fairway Flick physical constants and aerodynamic coefficients (SI units). Pure; no nodes.
## Sources and reasoning: docs/research/Fairway Flick golf game design.md (ball physics notes).
## The coefficient curves are polynomial / piecewise-linear on purpose: no pow / exp in the solver
## hot path (cross-device determinism, the golf rules).

var g := 9.81
var air_density := 1.225  # kg/m^3
var radius := 0.021335  # 42.67 mm ball
var mass := 0.04593  # kg
## Reynolds number per m/s of airspeed for this ball at sea level (Re ~ 2,890 * V).
var re_per_speed := 2890.0
## Drag: Cd = CD_MIN + CD_CRISIS * ramp(Re) + CD_SPIN * spin_term(S).
## ramp = 1 at Re <= RE_LOW, 0 at Re >= RE_HIGH, linear between (the drag crisis).
var cd_min := 0.225
var cd_crisis := 0.275
var cd_spin := 0.18
var re_low := 50000.0
var re_high := 100000.0
## Lift: Cl = 1.99 S - 3.255 S^2 up to S = 0.25, then linear with slope 0.3625 (no clamp).
var cl_a := 1.99
var cl_b := 3.255
var cl_knee := 0.25
var cl_slope := 0.3625
## Spin decay per metre travelled (about 4 %/s at typical speeds).
var spin_decay_per_m := 0.001


func area() -> float:
	return PI * radius * radius


func inertia() -> float:
	return 0.4 * mass * radius * radius


## Drag coefficient for airspeed v (m/s) and spin ratio s = omega * r / v.
func cd(v: float, s: float) -> float:
	var re := re_per_speed * v
	var ramp := clampf((re_high - re) / (re_high - re_low), 0.0, 1.0)
	return cd_min + cd_crisis * ramp + cd_spin * _spin_term(s)


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
