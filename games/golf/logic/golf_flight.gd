class_name GolfFlight
extends RefCounted
## Fairway Flick ball flight (pure; no nodes). RK4 on position / velocity with drag, Magnus lift and
## gravity; spin magnitude decays per metre travelled, the spin axis stays fixed (TrackMan).
## Research: docs/research/Fairway Flick golf game design.md (ball physics notes, sections 1-3).
## Frame: x right, y up, z towards the player - downrange is -z (Godot's forward), so world
## positions need no conversion. State is PackedFloat64Array; the hot path uses only + - * / and
## sqrt (no pow / exp / trig) so results match across devices.

enum Over { FLYING, HIT, OUT }

## Live: 4 substeps per 60 Hz tick. Tests show 1/60 s is within 0.3 m of carry (planner use).
const SUBSTEP := 1.0 / 240.0
## Wind height profile: w(h) = w_ref * (h / 10 m)^0.15, floored at 0.3, tabulated (no pow).
const WIND_H := [0.0, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 40.0, 80.0]
const WIND_K := [0.3, 0.638, 0.708, 0.785, 0.901, 1.0, 1.110, 1.231, 1.364]
const MPH := 0.44704
const YD := 0.9144
const RPM := TAU / 60.0

var p: GolfParams
## [x, y, z, vx, vy, vz]
var s := PackedFloat64Array()
## Spin: magnitude (rad/s) and fixed unit axis.
var spin := 0.0
var axis := PackedFloat64Array([0.0, 0.0, 0.0])
## Wind at 10 m height (m/s), horizontal.
var wind := PackedFloat64Array([0.0, 0.0, 0.0])
var time := 0.0
var apex := 0.0
var travelled := 0.0

var _k := 0.0  # 0.5 * rho * A / m
var _sr := 0.0  # radius for the spin ratio
var _st := PackedFloat64Array()  # RK4 scratch
var _d := PackedFloat64Array()
var _prev := PackedFloat64Array()


func _init(params: GolfParams = null) -> void:
	p = params if params != null else GolfParams.new()
	_k = 0.5 * p.air_density * p.area() / p.mass
	_sr = p.radius
	s.resize(6)
	_st.resize(6)
	_d.resize(24)
	_prev.resize(6)


## Launch from `at` (Vector3) with ball speed (m/s), launch angle above the horizon, backspin
## (rad/s), spin-axis tilt (deg; + curves right as seen from behind) and heading (deg; 0 = -z,
## + turns right). Trig runs here once per shot, never in the step.
func launch(
	at: Vector3,
	speed: float,
	launch_deg: float,
	backspin: float,
	tilt_deg := 0.0,
	heading_deg := 0.0
) -> void:
	var la := deg_to_rad(launch_deg)
	var hd := deg_to_rad(heading_deg)
	var fwd := Vector3(sin(hd), 0.0, -cos(hd))  # horizontal flight direction
	var right := Vector3(cos(hd), 0.0, sin(hd))
	var v := (fwd * cos(la) + Vector3.UP * sin(la)) * speed
	s[0] = at.x
	s[1] = at.y
	s[2] = at.z
	s[3] = v.x
	s[4] = v.y
	s[5] = v.z
	# Backspin axis points to the player's right (right x forward = up, so the lift points up);
	# tilting its right end down leans the lift right: axis = right * cos(tilt) - up * sin(tilt).
	var t := deg_to_rad(tilt_deg)
	var ax := right * cos(t) - Vector3.UP * sin(t)
	axis[0] = ax.x
	axis[1] = ax.y
	axis[2] = ax.z
	spin = backspin
	time = 0.0
	apex = at.y
	travelled = 0.0


func set_wind(w: Vector3) -> void:
	wind[0] = w.x
	wind[1] = 0.0
	wind[2] = w.z


func pos() -> Vector3:
	return Vector3(s[0], s[1], s[2])


func vel() -> Vector3:
	return Vector3(s[3], s[4], s[5])


## Wind factor at height h above the launch ground (piecewise-linear power law).
static func wind_factor(h: float) -> float:
	if h <= 0.0:
		return WIND_K[0]
	for i in range(1, WIND_H.size()):
		if h < WIND_H[i]:
			var a: float = WIND_H[i - 1]
			var b: float = WIND_H[i]
			return lerpf(WIND_K[i - 1], WIND_K[i], (h - a) / (b - a))
	return WIND_K[WIND_K.size() - 1]


## One RK4 step of dt; spin is held for the step, then decays by K * distance.
func step(dt: float, ground_y := 0.0) -> void:
	var wf := wind_factor(s[1] - ground_y)
	_accel(s, 0, wf)
	for i in 6:
		_st[i] = s[i] + 0.5 * dt * _d[i]
	_accel(_st, 6, wf)
	for i in 6:
		_st[i] = s[i] + 0.5 * dt * _d[6 + i]
	_accel(_st, 12, wf)
	for i in 6:
		_st[i] = s[i] + dt * _d[12 + i]
	_accel(_st, 18, wf)
	var x0 := s[0]
	var y0 := s[1]
	var z0 := s[2]
	for i in 6:
		s[i] += dt / 6.0 * (_d[i] + 2.0 * _d[6 + i] + 2.0 * _d[12 + i] + _d[18 + i])
	var dx := s[0] - x0
	var dy := s[1] - y0
	var dz := s[2] - z0
	var dist := sqrt(dx * dx + dy * dy + dz * dz)
	travelled += dist
	spin *= maxf(0.0, 1.0 - p.spin_decay_per_m * dist)
	time += dt
	apex = maxf(apex, s[1])


## Writes d(state)/dt for `st` into _d[o .. o+5].
func _accel(st: PackedFloat64Array, o: int, wf: float) -> void:
	var rx := st[3] - wind[0] * wf
	var ry := st[4]
	var rz := st[5] - wind[2] * wf
	var v2 := rx * rx + ry * ry + rz * rz
	var v := sqrt(v2)
	_d[o] = st[3]
	_d[o + 1] = st[4]
	_d[o + 2] = st[5]
	if v < 1e-9:
		_d[o + 3] = 0.0
		_d[o + 4] = -p.g
		_d[o + 5] = 0.0
		return
	var sr := spin * _sr / v
	var drag := _k * p.cd(v, sr) * v
	var lift := _k * p.cl(sr) * v
	# Magnus: Cl * |v| * (axis x v_rel)
	var mx := axis[1] * rz - axis[2] * ry
	var my := axis[2] * rx - axis[0] * rz
	var mz := axis[0] * ry - axis[1] * rx
	_d[o + 3] = -drag * rx + lift * mx
	_d[o + 4] = -drag * ry + lift * my - p.g
	_d[o + 5] = -drag * rz + lift * mz


## Flies over flat ground at height `ground_y` until the ball comes back down through it.
## Returns {pos: Vector3 (crossing, interpolated), vel: Vector3, time, apex, spin}.
func fly_to_ground(dt := SUBSTEP, ground_y := 0.0, max_time := 20.0) -> Dictionary:
	var prev := PackedFloat64Array(s)  # one copy per flight; refilled in place each step
	var t_prev := time
	while time < max_time:
		for i in 6:
			prev[i] = s[i]
		t_prev = time
		step(dt, ground_y)
		if s[4] < 0.0 and s[1] <= ground_y:
			break
	var dy := prev[1] - s[1]
	var f := (prev[1] - ground_y) / dy if dy > 1e-12 else 1.0
	var at := Vector3(lerpf(prev[0], s[0], f), lerpf(prev[1], s[1], f), lerpf(prev[2], s[2], f))
	var v := Vector3(lerpf(prev[3], s[3], f), lerpf(prev[4], s[4], f), lerpf(prev[5], s[5], f))
	return {"pos": at, "vel": v, "time": lerpf(t_prev, time, f), "apex": apex, "spin": spin}


## One step over a hole's terrain with exact swept contact (no tunnelling at driver speed). On a
## hit the state is moved back to the contact point. Allocation-free (live use, 4 per tick).
func step_over(hole: HoleData, dt := SUBSTEP) -> int:
	for i in 6:
		_prev[i] = s[i]
	var ta := time
	step(dt, hole.height(s[0], s[2]))
	var t := hole.sweep_d(_prev[0], _prev[1], _prev[2], s[0], s[1], s[2], p.radius)
	if t >= 0.0:
		for i in 6:
			s[i] = _prev[i] + (s[i] - _prev[i]) * t
		time = ta + (time - ta) * t
		return Over.HIT
	if not hole.contains(s[0], s[2]):
		return Over.OUT  # left the grid: out of bounds
	return Over.FLYING


## Flies over a hole until the ball first touches the ground or leaves the grid.
## Returns {hit: bool, pos, vel, normal, surface, time}; OUT surface when it did not land.
func fly_over(hole: HoleData, dt := SUBSTEP, max_time := 20.0) -> Dictionary:
	var r := Over.FLYING
	while r == Over.FLYING and time < max_time:
		r = step_over(hole, dt)
	var hit := r == Over.HIT
	return {
		"hit": hit,
		"pos": pos(),
		"vel": vel(),
		"normal": hole.normal(s[0], s[2]) if hit else Vector3.UP,
		"surface": hole.surface_at(s[0], s[2]) if hit else HoleData.Surface.OUT,
		"time": time
	}


## Fingerprint of the state for golden / determinism tests (exact doubles as hex).
func fingerprint() -> String:
	var b := s.to_byte_array()
	b.append_array(PackedFloat64Array([spin, time]).to_byte_array())
	return b.hex_encode()
