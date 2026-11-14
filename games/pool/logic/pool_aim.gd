class_name PoolAim
extends RefCounted
## Aiming maths for Break & Bank (pure): power curve, lift-off filter and the guideline prediction.
## Research: docs/research/Cue Club pool game design.md (portrait touch controls).
##   speed = v_max * p^2 (8 m/s, 12 m/s on the break): a medium 1.5 m/s shot sits at ~43%
##   of the bar.
##   On release the aim reverts to where it was LIFT_MS earlier (fingers nudge it as they lift).
##   The guideline runs the real solver on a copy of the table until the cue ball's first contact,
##   so the object-ball and cue-ball rays include throw and spin (a geometric line would lie).

const V_MAX := 8.0
const V_BREAK := 13.0
## Break power is gentler than v ~ p^2: a firm pull (85%) breaks at ~11 m/s, not ~9.
const BREAK_GAMMA := 1.2
## Break spin preset: a touch of follow keeps the cue ball moving into the pack instead of parking
## at the apex, where kisses sent it into a side pocket (6-ft table: scratches 29% -> 12% at 85%).
const BREAK_TOP := 0.15
const GAMMA := 2.0
const MIN_POWER := 0.02  # below this the shot is cancelled
const LIFT_MS := 60
const FINE_DEG_PER_DP := 0.03
## Closer than this to the cue ball the finger does not set a direction (metres).
const MIN_POINT_DIST := 0.07

## Aim angle in radians (table frame: 0 = +x, pi/2 = +y = up the table).
var angle := PI * 0.5
# Guideline result (valid after predict()).
var hit_kind := 0  # 0 nothing, 1 ball, 2 cushion, 3 pocket
var hit_ball := -1
var contact := Vector2.ZERO  # cue ball centre at first contact (ghost ball)
var obj_dir := Vector2.ZERO  # object ball direction just after contact
## Direction the cue ball heads once its spin has taken hold (draw bends back, follow goes on);
## zero for a stop shot.
var cue_dir := Vector2.ZERO

var _sim: CueSim
var _hist_t := PackedInt64Array()
var _hist_a := PackedFloat64Array()


static func speed_for(power: float, breaking := false) -> float:
	var p := clampf(power, 0.0, 1.0)
	if breaking:
		return V_BREAK * pow(p, BREAK_GAMMA)
	return V_MAX * pow(p, GAMMA)


func dir() -> Vector2:
	return Vector2(cos(angle), sin(angle))


func set_dir(d: Vector2) -> void:
	if d.length_squared() > 1e-12:
		angle = atan2(d.y, d.x)


## Points the cue from the cue ball at the finger (table coordinates). Ignored when the finger is
## within MIN_POINT_DIST of the cue ball (direction too jumpy). snap_to: candidate ball centres;
## if the aim passes within snap_rad of one's direction it locks onto it (Easy/Medium assist).
func point_at(
	cue: Vector2, finger: Vector2, now_ms: int, snap_to: Array = [], snap_rad := 0.0
) -> void:
	var d := finger - cue
	if d.length() < MIN_POINT_DIST:
		return
	var a := d.angle()
	for c in snap_to:
		var to: Vector2 = c - cue
		if absf(angle_difference(a, to.angle())) < snap_rad:
			a = to.angle()
			break
	angle = a
	record(now_ms)


## Rotates the aim by the angle the finger swept around the cue ball (table coordinates).
func sweep(cue: Vector2, from: Vector2, to: Vector2, now_ms: int) -> void:
	var a0 := (from - cue).angle()
	var a1 := (to - cue).angle()
	if (from - cue).length() < 0.02 or (to - cue).length() < 0.02:
		return  # too close to the cue ball to mean a direction
	angle = wrapf(angle + wrapf(a1 - a0, -PI, PI), -PI, PI)
	record(now_ms)


## Fine aim: degrees per dp of finger travel.
func nudge(dp: float, now_ms: int) -> void:
	angle = wrapf(angle + deg_to_rad(dp * FINE_DEG_PER_DP), -PI, PI)
	record(now_ms)


func record(now_ms: int) -> void:
	_hist_t.append(now_ms)
	_hist_a.append(angle)
	if _hist_t.size() > 32:
		_hist_t = _hist_t.slice(16)
		_hist_a = _hist_a.slice(16)


## Finger lifted at now_ms: take the aim from LIFT_MS before (if it changed since).
func release(now_ms: int) -> void:
	var cutoff := now_ms - LIFT_MS
	for i in range(_hist_t.size() - 1, -1, -1):
		if _hist_t[i] <= cutoff:
			angle = _hist_a[i]
			break
	_hist_t.clear()
	_hist_a.clear()


## Predicts the first contact of a shot on a copy of the table.
func predict(src: CueSim, speed: float, side := 0.0, top := 0.0) -> void:
	if _sim == null:
		_sim = CueSim.new(src.p)
	for arr in ["px", "py", "vx", "vy", "wx", "wy", "wz"]:
		_sim.set(arr, (src.get(arr) as PackedFloat64Array).duplicate())
	_sim.phase = src.phase.duplicate()
	_sim.pocket_of = src.pocket_of.duplicate()
	var d := dir()
	_sim.strike(d.x, d.y, speed, side, top)
	hit_kind = 0
	hit_ball = -1
	obj_dir = Vector2.ZERO
	cue_dir = Vector2.ZERO
	for s in 240 * 4:
		_sim.step(CueSim.SUBSTEP)
		if _sim.log.size() >= 3:
			break
		if not _sim.is_moving():
			break
	contact = Vector2(_sim.px[0], _sim.py[0])
	if _sim.log.size() < 3:
		return
	var kind := _sim.log[0]
	if kind == CueSim.Ev.BALL_HIT:
		hit_kind = 1
		hit_ball = _sim.log[2] if _sim.log[1] == 0 else _sim.log[1]
		# Directions right after the first impulse (later contacts in the substep don't count).
		var cue_first := _sim.log[1] == 0
		var fv := _sim.first_hit_v
		obj_dir = Vector2(fv[4], fv[5]) if cue_first else Vector2(fv[0], fv[1])
		obj_dir = obj_dir.normalized()
		cue_dir = _roll_dir(src.p.radius, fv) if cue_first else Vector2.ZERO
		# The ghost ball: where the cue ball's centre was at the hit.
		contact = Vector2(
			_sim.first_hit[0 if cue_first else 2], _sim.first_hit[1 if cue_first else 3]
		)
	elif kind == CueSim.Ev.CUSHION:
		hit_kind = 2
		cue_dir = Vector2(_sim.vx[0], _sim.vy[0]).normalized()
	elif kind == CueSim.Ev.POCKET:
		hit_kind = 3


## Where a sliding cue ball ends up heading: when the slip u dies, v changes by -(2/7) u.
func _roll_dir(r: float, fv: PackedFloat64Array) -> Vector2:
	var ux := fv[0] - r * fv[3]
	var uy := fv[1] + r * fv[2]
	var v := Vector2(fv[0] - 2.0 / 7.0 * ux, fv[1] - 2.0 / 7.0 * uy)
	return v.normalized() if v.length() > 0.02 else Vector2.ZERO
