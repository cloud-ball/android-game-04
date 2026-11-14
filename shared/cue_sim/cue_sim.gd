class_name CueSim
extends RefCounted
## Deterministic pool solver (pure; no nodes). Balls move in the table plane with 3D spin.
## Each ball is in one phase with closed-form motion (Kiefl / pooltool):
##   SLIDING  contact slips: friction -mu_slide*g along the fixed initial slip direction
##   ROLLING  no slip: deceleration mu_roll*g along v, in-plane spin locked to v / R
##   SPINNING v = 0, only the vertical spin decays;   STATIONARY at rest;   POCKETED off the table.
## step() runs fixed 1/240 s substeps; inside one it repeatedly finds the earliest event (phase
## change, ball-ball contact, cushion / jaw contact, pocket capture) with swept tests, advances
## every ball analytically to it and resolves it. Ties: transitions, then balls, cushions, points,
## pockets, each by index. At most MAX_EVENTS per substep. Only + - * / sqrt in the hot path
## (no trig / exp), all state in 64-bit packed arrays, so a shot replays bit-exactly.
## Design + sources: docs/games/pool.md, docs/research/Cue Club pool game design.md.

enum { STATIONARY, SPINNING, ROLLING, SLIDING, POCKETED }
## Shot log entries (triples): kind, a, b. BALL_HIT (ball, ball); CUSHION (ball, 0 = a new
## contact, 1 = a ball frozen to that cushion at the strike pressed into it: not a new contact,
## WPA 2.7); POCKET (ball, pocket).
enum Ev { BALL_HIT, CUSHION, POCKET }

const N := 16
const SUBSTEP := 1.0 / 240.0
const MAX_EVENTS := 64
const EPS_V := 1e-6
const EPS_W := 1e-5
const NEVER := 1e30
## Contacts slower than this are perfectly inelastic: stops a rolling ball re-hitting the ball in
## front of it at ever shorter intervals (inelastic collapse).
const SLOW_CONTACT := 0.005
## Contacts closing slower than this just stop the approaching ball (see _ball_ball).
const CREEP := 1e-4
## d . w below -APPROACH_EPS counts as approaching (|d| ~ 0.06 m: ~1e-9 m/s closing speed).
const APPROACH_EPS := 6e-11

var p: CueParams
var table: CueTable
var px := PackedFloat64Array()
var py := PackedFloat64Array()
var vx := PackedFloat64Array()
var vy := PackedFloat64Array()
var wx := PackedFloat64Array()
var wy := PackedFloat64Array()
var wz := PackedFloat64Array()
var phase := PackedInt32Array()
## Which pocket each pocketed ball fell into (-1 = on the table).
var pocket_of := PackedInt32Array()
## Cushion segment each ball was frozen against when the shot was struck (-1 = none); cleared by
## its first contact with any cushion.
var frozen_seg := PackedInt32Array()
## Positions of the two balls at the shot's first ball-ball contact (ax, ay, bx, by): the aim
## guideline's ghost ball.
var first_hit := PackedFloat64Array([0.0, 0.0, 0.0, 0.0])
## Velocities right after that first impulse: a (vx, vy, wx, wy), b (vx, vy).
var first_hit_v := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
## Events since the last strike (kind, a, b triples); see Ev.
var log := PackedInt32Array()
## Impact speed (m/s) of each log entry (one per triple): closing speed for ball-ball, speed into
## the cushion, ball speed into the pocket. Drives sound volume and haptics.
var log_speed := PackedFloat32Array()
var time := 0.0
var substep := SUBSTEP
var events_capped := 0

var _r := 0.0
var _r2 := 0.0
var _a_slide := 0.0
var _a_roll := 0.0
var _a_spin := 0.0
var _ev_t := 0.0
var _ev_kind := 0
var _ev_a := 0
var _ev_b := 0


func _init(params: CueParams = null) -> void:
	p = params if params != null else CueParams.pool()
	table = CueTable.new(p)
	_r = p.radius
	_r2 = 4.0 * _r * _r
	_a_slide = p.mu_slide * p.g
	_a_roll = p.mu_roll * p.g
	_a_spin = p.spin_decel
	for arr in [px, py, vx, vy, wx, wy, wz]:
		arr.resize(N)
	phase.resize(N)
	pocket_of.resize(N)
	frozen_seg.resize(N)
	clear()


## All balls off the table (POCKETED, pocket -1); use place() to set them up.
func clear() -> void:
	for i in N:
		px[i] = 0.0
		py[i] = 0.0
		_zero_motion(i)
		phase[i] = POCKETED
		pocket_of[i] = -1
	log.clear()
	log_speed.clear()
	time = 0.0


## Copies another solver's ball state (for AI rollouts and guideline previews).
func copy_from(o: CueSim) -> void:
	px = o.px.duplicate()
	py = o.py.duplicate()
	vx = o.vx.duplicate()
	vy = o.vy.duplicate()
	wx = o.wx.duplicate()
	wy = o.wy.duplicate()
	wz = o.wz.duplicate()
	phase = o.phase.duplicate()
	pocket_of = o.pocket_of.duplicate()
	log.clear()
	log_speed.clear()
	time = 0.0


func place(i: int, x: float, y: float) -> void:
	px[i] = x
	py[i] = y
	_zero_motion(i)
	phase[i] = STATIONARY
	pocket_of[i] = -1


func on_table(i: int) -> bool:
	return phase[i] != POCKETED


func is_moving() -> bool:
	for i in N:
		if phase[i] != STATIONARY and phase[i] != POCKETED:
			return true
	return false


## Strikes the cue ball (index 0). dir: unit vector in the table plane (computed once at the input
## boundary, so no trig here); speed m/s; side / top: tip offset in ball radii (right / follow +),
## clamped to max_tip_offset. A horizontal cue: the ball leaves straight along dir (no squirt).
func strike(dir_x: float, dir_y: float, speed: float, side := 0.0, top := 0.0) -> void:
	var lim := p.max_tip_offset
	var off2 := side * side + top * top
	if off2 > lim * lim:
		var k := lim / sqrt(off2)
		side *= k
		top *= k
	log.clear()
	log_speed.clear()
	vx[0] = dir_x * speed
	vy[0] = dir_y * speed
	var k2 := 2.5 * speed / _r  # |R w| = 5/2 (offset/R) v
	wx[0] = -dir_y * top * k2
	wy[0] = dir_x * top * k2
	wz[0] = side * k2
	_classify(0)
	_mark_frozen()


## Advances the simulation by dt in fixed substeps (dt should be a multiple of the substep).
func step(dt: float) -> void:
	var n := int(dt / substep + 0.5)
	for s in n:
		_substep(substep)
		time += substep


## Runs until every ball has stopped (or max_time); returns the simulated time.
func run_to_rest(max_time := 60.0) -> float:
	var t0 := time
	while is_moving() and time - t0 < max_time:
		_substep(substep)
		time += substep
	return time - t0


## Kinetic energy (translation + rotation) of all balls on the table.
func energy() -> float:
	var e := 0.0
	var inertia := p.inertia()
	for i in N:
		if phase[i] == POCKETED:
			continue
		e += 0.5 * p.mass * (vx[i] * vx[i] + vy[i] * vy[i])
		e += 0.5 * inertia * (wx[i] * wx[i] + wy[i] * wy[i] + wz[i] * wz[i])
	return e


# --- substep ------------------------------------------------------------------------------------


func _substep(dt: float) -> void:
	var tau := dt
	var count := 0
	while true:
		_find_event(tau)
		if _ev_t > tau:
			_advance_all(tau)
			_settle_contacts()
			return
		_advance_all(_ev_t)
		tau -= _ev_t
		_resolve()
		count += 1
		if count >= MAX_EVENTS:
			events_capped += 1
			_advance_all(tau)
			_separate()
			return


func _find_event(tau: float) -> void:
	_ev_t = NEVER
	# 1. Phase transitions.
	for i in N:
		var t := _transition_time(i)
		if t < _ev_t:
			_set_event(t, 0, i, 0)
	# 2. Ball-ball contacts (swept circles; linear motion within the substep).
	for i in N:
		var ph := phase[i]
		if ph != ROLLING and ph != SLIDING:
			continue
		var reach_i := sqrt(vx[i] * vx[i] + vy[i] * vy[i]) * tau
		for j in N:
			if j == i or phase[j] == POCKETED:
				continue
			var pj := phase[j]
			var j_moves := pj == ROLLING or pj == SLIDING
			if j_moves and j < i:
				continue  # the pair is tested from the lower index
			var dx := px[j] - px[i]
			var dy := py[j] - py[i]
			var wvx := vx[j] - vx[i]
			var wvy := vy[j] - vy[i]
			var reach := reach_i + sqrt(vx[j] * vx[j] + vy[j] * vy[j]) * tau
			var lim := 2.0 * _r + reach
			var c := dx * dx + dy * dy
			if c > lim * lim:
				continue
			var t := _sweep(dx, dy, wvx, wvy, c - _r2)
			if t < _ev_t or (t == _ev_t and _ev_kind > 1):
				_set_event(t, 1, mini(i, j), maxi(i, j))
	# 3-5. Cushions, jaw points and pockets, only for balls near the edge.
	var hw := table.hw
	var hl := table.hl
	for i in N:
		var ph := phase[i]
		if ph != ROLLING and ph != SLIDING:
			continue
		var reach := sqrt(vx[i] * vx[i] + vy[i] * vy[i]) * tau + 0.002
		var edge := _r + reach + 0.08
		if absf(px[i]) < hw - edge and absf(py[i]) < hl - edge:
			continue
		_cushion_events(i, tau)


func _cushion_events(i: int, tau: float) -> void:
	var bx := px[i]
	var by := py[i]
	var bvx := vx[i]
	var bvy := vy[i]
	var tb := table
	for k in tb.seg_x.size():
		var nx := tb.seg_nx[k]
		var ny := tb.seg_ny[k]
		var vn := bvx * nx + bvy * ny
		if vn >= 0.0:
			continue
		var dist := (bx - tb.seg_x[k]) * nx + (by - tb.seg_y[k]) * ny
		if dist < _r * 0.5:
			continue  # behind the cushion line (e.g. inside a pocket)
		var t := (dist - _r) / -vn
		if t < 0.0:
			t = 0.0
		if t > tau or t > _ev_t:
			continue
		var s := (
			(bx + bvx * t - tb.seg_x[k]) * tb.seg_dx[k]
			+ (by + bvy * t - tb.seg_y[k]) * tb.seg_dy[k]
		)
		if s < 0.0 or s > tb.seg_len[k]:
			continue
		if t < _ev_t:
			_set_event(t, 2, i, k)
	for k in tb.pt_x.size():
		var dx := tb.pt_x[k] - bx
		var dy := tb.pt_y[k] - by
		var c := dx * dx + dy * dy - _r * _r
		if c > (_r + 0.2) * (_r + 0.2):
			continue
		var t := _sweep(dx, dy, -bvx, -bvy, c)
		if t < _ev_t:
			_set_event(t, 3, i, k)
	for k in tb.pocket_x.size():
		var dx := tb.pocket_x[k] - bx
		var dy := tb.pocket_y[k] - by
		var rr := tb.pocket_r[k]
		var c := dx * dx + dy * dy - rr * rr
		var t := 0.0 if c <= 0.0 else _sweep(dx, dy, -bvx, -bvy, c)
		if t < _ev_t:
			_set_event(t, 4, i, k)


## Earliest t >= 0 at which |d + w t| shrinks to the contact distance; c = |d|^2 - contact^2.
## Cancellation-free root. NEVER if separating, missing, or approaching slower than ~1e-9 m/s
## (round-off after a resolved contact must not count as a new one at t = 0).
func _sweep(dx: float, dy: float, wvx: float, wvy: float, c: float) -> float:
	var b := dx * wvx + dy * wvy
	if b > -APPROACH_EPS:
		return NEVER
	if c <= 0.0:
		return 0.0  # already touching and approaching
	var a := wvx * wvx + wvy * wvy
	var disc := b * b - a * c
	if disc < 0.0:
		return NEVER
	return c / (-b + sqrt(disc))


func _set_event(t: float, kind: int, a: int, b: int) -> void:
	_ev_t = t
	_ev_kind = kind
	_ev_a = a
	_ev_b = b


func _transition_time(i: int) -> float:
	match phase[i]:
		SLIDING:
			var ux := vx[i] - _r * wy[i]
			var uy := vy[i] + _r * wx[i]
			return (2.0 / 7.0) * sqrt(ux * ux + uy * uy) / _a_slide
		ROLLING:
			return sqrt(vx[i] * vx[i] + vy[i] * vy[i]) / _a_roll
		SPINNING:
			return absf(wz[i]) / (_a_spin * p.spin_decel_still)
	return NEVER


func _resolve() -> void:
	match _ev_kind:
		0:
			_end_phase(_ev_a)
		1:
			_ball_ball(_ev_a, _ev_b)
		2:
			var frozen := frozen_seg[_ev_a] == _ev_b
			frozen_seg[_ev_a] = -1
			_cushion(_ev_a, table.seg_nx[_ev_b], table.seg_ny[_ev_b], frozen)
		3:
			frozen_seg[_ev_a] = -1
			var dx := table.pt_x[_ev_b] - px[_ev_a]
			var dy := table.pt_y[_ev_b] - py[_ev_a]
			var d := sqrt(dx * dx + dy * dy)
			_cushion(_ev_a, -dx / d, -dy / d)
		4:
			_pocket(_ev_a, _ev_b)


# --- motion -------------------------------------------------------------------------------------


func _advance_all(t: float) -> void:
	if t <= 0.0:
		return
	for i in N:
		var ph := phase[i]
		if ph == STATIONARY or ph == POCKETED:
			continue
		_decay_spin(i, t)
		if ph == SLIDING:
			var ux := vx[i] - _r * wy[i]
			var uy := vy[i] + _r * wx[i]
			var u := sqrt(ux * ux + uy * uy)
			if u > 0.0:
				var ex := ux / u
				var ey := uy / u
				var at := _a_slide * t
				px[i] += vx[i] * t - 0.5 * at * t * ex
				py[i] += vy[i] * t - 0.5 * at * t * ey
				vx[i] -= at * ex
				vy[i] -= at * ey
				var k := 2.5 * at / _r
				wx[i] -= k * ey
				wy[i] += k * ex
			else:
				px[i] += vx[i] * t
				py[i] += vy[i] * t
		elif ph == ROLLING:
			var s := sqrt(vx[i] * vx[i] + vy[i] * vy[i])
			if s > 0.0:
				var at := _a_roll * t
				var ex := vx[i] / s
				var ey := vy[i] / s
				px[i] += vx[i] * t - 0.5 * at * t * ex
				py[i] += vy[i] * t - 0.5 * at * t * ey
				vx[i] -= at * ex
				vy[i] -= at * ey
			wx[i] = -vy[i] / _r
			wy[i] = vx[i] / _r


func _decay_spin(i: int, t: float) -> void:
	var w := wz[i]
	var d := _a_spin * t * (p.spin_decel_still if phase[i] == SPINNING else 1.0)
	if w > d:
		wz[i] = w - d
	elif w < -d:
		wz[i] = w + d
	else:
		wz[i] = 0.0


## A phase ran out: snap the exact end state, then classify again.
func _end_phase(i: int) -> void:
	match phase[i]:
		SLIDING:
			wx[i] = -vy[i] / _r
			wy[i] = vx[i] / _r
		ROLLING:
			vx[i] = 0.0
			vy[i] = 0.0
			wx[i] = 0.0
			wy[i] = 0.0
		SPINNING:
			wz[i] = 0.0
	_classify(i)


func _classify(i: int) -> void:
	var ux := vx[i] - _r * wy[i]
	var uy := vy[i] + _r * wx[i]
	var v2 := vx[i] * vx[i] + vy[i] * vy[i]
	if ux * ux + uy * uy > EPS_V * EPS_V:
		phase[i] = SLIDING
	elif v2 > EPS_V * EPS_V:
		phase[i] = ROLLING
		wx[i] = -vy[i] / _r
		wy[i] = vx[i] / _r
	else:
		vx[i] = 0.0
		vy[i] = 0.0
		wx[i] = 0.0
		wy[i] = 0.0
		phase[i] = SPINNING if absf(wz[i]) > EPS_W else STATIONARY
		if phase[i] == STATIONARY:
			wz[i] = 0.0


func _zero_motion(i: int) -> void:
	vx[i] = 0.0
	vy[i] = 0.0
	wx[i] = 0.0
	wy[i] = 0.0
	wz[i] = 0.0


# --- collisions ---------------------------------------------------------------------------------


## Normal impulse (1+e) m/2 v_n; friction impulse along the in-plane tangential slip of the contact
## points, capped by Coulomb (mu Jn) and by m|s|/7, where slip stops (two solid spheres), so
## friction never adds energy. Gives cut-induced and spin-induced throw.
func _ball_ball(a: int, b: int) -> void:
	var dx := px[b] - px[a]
	var dy := py[b] - py[a]
	var d := sqrt(dx * dx + dy * dy)
	if d <= 0.0:
		return
	var nx := dx / d
	var ny := dy / d
	var vn := (vx[a] - vx[b]) * nx + (vy[a] - vy[b]) * ny
	if vn <= 1e-9:
		return  # already separating (or round-off)
	var first := not _logged(Ev.BALL_HIT)
	if first:
		first_hit[0] = px[a]
		first_hit[1] = py[a]
		first_hit[2] = px[b]
		first_hit[3] = py[b]
	_log(Ev.BALL_HIT, a, b, vn)
	if d < 2.0 * _r:
		# Round-off left them overlapping (micrometres): push apart along the normal.
		var push := (2.0 * _r - d) * 0.5
		px[a] -= nx * push
		py[a] -= ny * push
		px[b] += nx * push
		py[b] += ny * push
	if vn < CREEP:
		# Creeping contact: an impulse this small would leave both under the rest threshold and
		# loop forever, so the approaching ball simply stops against the other.
		vx[a] -= nx * vn
		vy[a] -= ny * vn
		_classify(a)
		return
	var m := p.mass
	var e := p.e_ball if vn > SLOW_CONTACT else 0.0
	var jn := (1.0 + e) * 0.5 * m * vn
	vx[a] -= jn * nx / m
	vy[a] -= jn * ny / m
	vx[b] += jn * nx / m
	vy[b] += jn * ny / m
	# In-plane tangent t = (-ny, nx). Contact slip of a against b along t:
	# (v_a + w_a x R n) - (v_b + w_b x (-R n)); the in-plane part only involves w_z:
	# (w x n) in-plane = w_z t, so s = (v_a - v_b).t + R (w_za + w_zb).
	var tx := -ny
	var ty := nx
	var s := (vx[a] - vx[b]) * tx + (vy[a] - vy[b]) * ty + _r * (wz[a] + wz[b])
	var jt := minf(p.mu_ball * jn, m * absf(s) / 7.0)
	if jt > 0.0:
		var sgn := 1.0 if s > 0.0 else -1.0
		var j := jt * sgn
		vx[a] -= j * tx / m
		vy[a] -= j * ty / m
		vx[b] += j * tx / m
		vy[b] += j * ty / m
		# Torque on both: (R n x -j t) = (-R n x j t) = -R j z, so w_z -= R j / I
		# (slip then changes by -2j/m - 2 R^2 j / I = -7 j / m).
		var dw := j * _r / p.inertia()
		wz[a] -= dw
		wz[b] -= dw
	if first:
		first_hit_v[0] = vx[a]
		first_hit_v[1] = vy[a]
		first_hit_v[2] = wx[a]
		first_hit_v[3] = wy[a]
		first_hit_v[4] = vx[b]
		first_hit_v[5] = vy[b]
	_classify(a)
	_classify(b)


## Han (2005) cushion impulse, from pooltool's corrected implementation, in the cushion frame
## (x' into the cushion, y' along it). n_in: unit normal from the ball into the cushion.
func _cushion(i: int, nx_out: float, ny_out: float, frozen := false) -> void:
	var nx := -nx_out
	var ny := -ny_out
	var tx := -ny
	var ty := nx
	var v_x := vx[i] * nx + vy[i] * ny
	if v_x <= 0.0:
		return
	_log(Ev.CUSHION, i, 1 if frozen else 0, v_x)
	var v_y := vx[i] * tx + vy[i] * ty
	var w_x := wx[i] * nx + wy[i] * ny
	var w_y := wx[i] * tx + wy[i] * ty
	var w_z := wz[i]
	var sn := p.cushion_sin
	var cs := p.cushion_cos
	var m := p.mass
	var inertia := p.inertia()
	var sx := v_x * sn + _r * w_y
	var sy := -v_y - _r * w_z * cs + _r * w_x * sn
	var c := -v_x * cs
	var a_coef := 3.5 / m
	var pze := -(1.0 + p.e_cushion) * c * m
	var abs_s := sqrt(sx * sx + sy * sy)
	var pxe := 0.0
	var pye := 0.0
	if abs_s / a_coef <= p.mu_cushion * pze:
		pxe = sx / a_coef
		pye = sy / a_coef
	elif abs_s > 0.0:
		pxe = p.mu_cushion * pze * sx / abs_s
		pye = p.mu_cushion * pze * sy / abs_s
	var big_px := -pxe * sn - pze * cs
	var big_py := pye
	var big_pz := pxe * cs - pze * sn
	v_x += big_px / m
	v_y += big_py / m
	var k := _r / inertia
	w_x += -k * big_py * sn
	w_y += k * (big_px * sn - big_pz * cs)
	w_z += k * big_py * cs
	vx[i] = v_x * nx + v_y * tx
	vy[i] = v_x * ny + v_y * ty
	wx[i] = w_x * nx + w_y * tx
	wy[i] = w_x * ny + w_y * ty
	wz[i] = w_z
	_classify(i)


func _pocket(i: int, k: int) -> void:
	_log(Ev.POCKET, i, k, sqrt(vx[i] * vx[i] + vy[i] * vy[i]))
	_zero_motion(i)
	phase[i] = POCKETED
	pocket_of[i] = k
	px[i] = table.pocket_x[k]
	py[i] = table.pocket_y[k]


## End of a substep: the swept test assumes straight motion, but a sliding ball can speed up
## (e.g. backspin) by up to 1/2 mu g dt^2 ~ 17 um per substep, so a contact may be crossed a
## little. Resolve those as real contacts now (impulse + push apart) so no pair ends overlapped.
func _settle_contacts() -> void:
	for i in N:
		var ph := phase[i]
		if ph != SLIDING and ph != ROLLING:
			continue
		for j in N:
			if j == i or phase[j] == POCKETED:
				continue
			var dx := px[j] - px[i]
			var dy := py[j] - py[i]
			if dx * dx + dy * dy < _r2:
				_ball_ball(mini(i, j), maxi(i, j))
				_push_apart(mini(i, j), maxi(i, j))


func _push_apart(a: int, b: int) -> void:
	var dx := px[b] - px[a]
	var dy := py[b] - py[a]
	var d := sqrt(dx * dx + dy * dy)
	if d >= 2.0 * _r or d <= 0.0:
		return
	var push := (2.0 * _r - d) * 0.5 + 1e-12
	px[a] -= dx / d * push
	py[a] -= dy / d * push
	px[b] += dx / d * push
	py[b] += dy / d * push


## Fallback after too many events in one substep (clusters of touching balls pressing on each
## other, e.g. a spinning ball pinned against a resting one): pairs that touch and still approach
## get a friction-free perfectly inelastic impulse (cannot add energy), and overlapping pairs are
## pushed apart symmetrically, repeating while anything changes (bounded).
func _separate() -> void:
	for pass_i in 16:
		if not _separate_pass():
			return


func _separate_pass() -> bool:
	var changed := false
	for i in N:
		if phase[i] == POCKETED:
			continue
		for j in range(i + 1, N):
			if phase[j] == POCKETED:
				continue
			var dx := px[j] - px[i]
			var dy := py[j] - py[i]
			var d2 := dx * dx + dy * dy
			if d2 >= _r2 + 1e-12 or d2 <= 0.0:
				continue
			var d := sqrt(d2)
			var nx := dx / d
			var ny := dy / d
			var vn := (vx[i] - vx[j]) * nx + (vy[i] - vy[j]) * ny
			if vn > 0.0:
				var h := 0.5 * vn
				vx[i] -= h * nx
				vy[i] -= h * ny
				vx[j] += h * nx
				vy[j] += h * ny
				_classify(i)
				_classify(j)
				changed = true
			if d < 2.0 * _r:
				var push := (2.0 * _r - d) * 0.5 + 1e-12
				px[i] -= nx * push
				py[i] -= ny * push
				px[j] += nx * push
				py[j] += ny * push
				changed = true
	return changed


## Remembers which balls touch a cushion segment at the strike (frozen to it).
func _mark_frozen() -> void:
	var tb := table
	for i in N:
		frozen_seg[i] = -1
		if phase[i] == POCKETED:
			continue
		for k in tb.seg_x.size():
			var dist := (px[i] - tb.seg_x[k]) * tb.seg_nx[k] + (py[i] - tb.seg_y[k]) * tb.seg_ny[k]
			if absf(dist - _r) > 1e-6:
				continue
			var s := (px[i] - tb.seg_x[k]) * tb.seg_dx[k] + (py[i] - tb.seg_y[k]) * tb.seg_dy[k]
			if s >= 0.0 and s <= tb.seg_len[k]:
				frozen_seg[i] = k
				break


func _logged(kind: int) -> bool:
	for i in range(0, log.size(), 3):
		if log[i] == kind:
			return true
	return false


func _log(kind: int, a: int, b: int, speed := 0.0) -> void:
	log_speed.append(speed)
	log.append(kind)
	log.append(a)
	log.append(b)
