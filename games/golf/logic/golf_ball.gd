class_name GolfBall
extends RefCounted
## One golf shot from strike to rest (pure; no nodes): flight (GolfFlight) -> bounces -> skid ->
## roll -> rest, the cup, water and out of bounds. Research: ball physics notes, sections 4-6.
## - Bounce: Penner's Daish model with a per-surface tilt (GolfSurfaces), in the plane of the
##   ball's motion; spin about the vertical is dropped on landing.
## - After the last bounce the ball skids: friction (mu g) moves its velocity V and its "rolling
##   velocity" W = -r * backspin towards each other (dV = -mu g s dt, dW = +5/2 mu g s dt, slip
##   s = V - W), so backspin can stop the ball or pull it back. Then it rolls: constant
##   deceleration per surface plus (5/7) g along the slope; it rests below a speed / slope limit.
## - Cup: captured if the ball's path crosses the cup with speed <= 1.24 x the free-fall limit
##   (2 sqrt(R^2 - b^2) - r) sqrt(g / 2r) for offset b (1.31 m/s centred, 1.63 with rim help);
##   faster balls lip out, deflected away and slowed.
## Fixed substeps, 64-bit state, only + - * / sqrt in the hot path. Allocation-free per substep.

enum Phase { READY, FLY, ROLL, REST, HOLED, WATER, OUT }
enum Ev { BOUNCE, ROLL, LIP, HOLED, WATER, OUT, WALL, HOP }

const CUP_R := 0.054
## Bounce -> roll once the rebound is lower than ~5 mm (Penner): v_n < sqrt(2 g h).
const ROLL_VN := 0.313
const SLEEP_V := 0.03
const SLEEP_T := 0.25
const MAX_TIME := 40.0
const RIM_ASSIST := 1.24
const LIP_KEEP := 0.6
const SLIP_EPS := 0.01
## Mini-golf walls and bumpers: normal restitution and tangential keep on a hit.
const E_WALL := 0.8
const WALL_KEEP := 0.9
## A rolling ball leaves the ground when the ground falls away faster than it can follow (ledges,
## ramp lips): hop if the ground's vertical speed under the ball drops by more than HOP_MIN_DV in
## one step (under 0.5 m/s would be a hop below ~1.3 cm - the crest of a gentle ramp - not worth
## leaving the ground model for).
const HOP_MIN_DV := 0.5
const HOP_MIN_SPEED := 1.0

var p: GolfParams
var hole: HoleData
var surf: GolfSurfaces
var flight: GolfFlight
var phase := Phase.READY
var time := 0.0
var bounces := 0
## Where the ball last was on playable ground (strike point, bounces, rolling) - for drops.
var last_safe := Vector3.ZERO
## Event log for sounds / UI: kind (Ev) and speed (m/s).
var events := PackedInt32Array()
var event_speed := PackedFloat32Array()

# Ground state while skidding / rolling (horizontal x, z).
var _x := 0.0
var _z := 0.0
var _vx := 0.0
var _vz := 0.0
var _wx := 0.0  # rolling velocity: equals V when rolling without slip
var _wz := 0.0
var _sleep := 0.0
var _cup_skip := false
var _g := PackedFloat64Array([0.0, 0.0])
var _hn := PackedFloat64Array([0.0, 0.0])  # contact normal of the last wall sweep
var _fly_prev := PackedFloat64Array([0.0, 0.0])  # horizontal position before a flight step
var _gvy_prev := 0.0  # ground vertical speed under the rolling ball, last step
var _k_cup := 0.0


func _init(h: HoleData, preset: CoursePreset = null, params: GolfParams = null) -> void:
	hole = h
	var pr := preset if preset != null else CoursePreset.new()
	p = params if params != null else GolfParams.new()
	p.apply_preset(pr)
	surf = GolfSurfaces.new(pr)
	flight = GolfFlight.new(p)
	_k_cup = sqrt(p.g / (2.0 * p.radius))


func strike(
	at: Vector3,
	speed: float,
	launch_deg: float,
	backspin: float,
	tilt_deg := 0.0,
	heading_deg := 0.0
) -> void:
	flight.launch(at, speed, launch_deg, backspin, tilt_deg, heading_deg)
	phase = Phase.FLY
	time = 0.0
	bounces = 0
	last_safe = at
	events.clear()
	event_speed.clear()
	_sleep = 0.0
	_cup_skip = false


## Starts a putt / roll from rest at (x, z) with ground velocity (vx, vz), rolling without slip.
func putt(x: float, z: float, vx: float, vz: float) -> void:
	phase = Phase.ROLL
	time = 0.0
	bounces = 0
	events.clear()
	event_speed.clear()
	_x = x
	_z = z
	_vx = vx
	_vz = vz
	_wx = vx
	_wz = vz
	_sleep = 0.0
	_cup_skip = false
	_gvy_prev = 0.0
	last_safe = pos()


func done() -> bool:
	return phase == Phase.REST or phase >= Phase.HOLED


func pos() -> Vector3:
	if phase == Phase.FLY or phase == Phase.READY:
		return flight.pos()
	return Vector3(_x, hole.height(_x, _z) + p.radius, _z)


## Ground speed while rolling (0 in flight).
func roll_speed() -> float:
	return sqrt(_vx * _vx + _vz * _vz) if phase == Phase.ROLL else 0.0


func run_to_rest(dt := GolfFlight.SUBSTEP) -> void:
	var cap := int(MAX_TIME / dt) + 10  # hard stop even if something goes wrong
	while not done() and cap > 0:
		substep(dt)
		cap -= 1


func substep(dt := GolfFlight.SUBSTEP) -> void:
	match phase:
		Phase.FLY:
			_fly_prev[0] = flight.s[0]
			_fly_prev[1] = flight.s[2]
			var r := flight.step_over(hole, dt)
			time = flight.time
			if r == GolfFlight.Over.FLYING or r == GolfFlight.Over.HIT:
				_fly_walls()
			if r == GolfFlight.Over.HIT:
				_land()
			elif r == GolfFlight.Over.OUT:
				_finish(Phase.OUT, Ev.OUT, flight.vel().length())
		Phase.ROLL:
			_roll(dt)
			time += dt
	if not done() and time > MAX_TIME:
		phase = Phase.REST


func _event(kind: int, speed: float) -> void:
	events.append(kind)
	event_speed.append(speed)


func _finish(ph: int, ev: int, speed: float) -> void:
	phase = ph
	_event(ev, speed)


# --- landing -------------------------------------------------------------------------------------


func _land() -> void:
	var s := flight.s
	var x := s[0]
	var z := s[2]
	var surface := hole.surface_at(x, z)
	var vx := s[3]
	var vy := s[4]
	var vz := s[5]
	var speed := sqrt(vx * vx + vy * vy + vz * vz)
	if surface == HoleData.Surface.WATER:
		_finish(Phase.WATER, Ev.WATER, speed)
		return
	if surface == HoleData.Surface.OUT:
		_finish(Phase.OUT, Ev.OUT, speed)
		return
	# Straight into the cup.
	var cx := x - hole.pin.x
	var cz := z - hole.pin.z
	if cx * cx + cz * cz < (CUP_R - 0.5 * p.radius) * (CUP_R - 0.5 * p.radius):
		_x = hole.pin.x
		_z = hole.pin.z
		_finish(Phase.HOLED, Ev.HOLED, speed)
		return
	last_safe = Vector3(x, s[1], z)
	# Surface normal n from the slope (64-bit).
	hole.grad_into(x, z, _g)
	var il := 1.0 / sqrt(1.0 + _g[0] * _g[0] + _g[1] * _g[1])
	var nx := -_g[0] * il
	var ny := il
	var nz := -_g[1] * il
	var vn := vx * nx + vy * ny + vz * nz  # < 0 inbound
	var tx := vx - vn * nx
	var ty := vy - vn * ny
	var tz := vz - vn * nz
	var vt := sqrt(tx * tx + ty * ty + tz * tz)
	if vt > 1e-9:
		tx /= vt
		ty /= vt
		tz /= vt
	else:
		tx = 0.0
		ty = 0.0
		tz = -1.0
	# Backspin axis for motion along t on a surface with normal n: b = t x n.
	var bx := ty * nz - tz * ny
	var by := tz * nx - tx * nz
	var bz := tx * ny - ty * nx
	var ax := flight.axis
	var w_in := flight.spin * (ax[0] * bx + ax[1] * by + ax[2] * bz)
	# Penner's bounce in the frame tilted by beta.
	var sb := surf.sin_b[surface]
	var cb := surf.cos_b[surface]
	var vin := -vn
	var vxp := vt * cb - vin * sb
	var vyp := vt * sb + vin * cb
	if vyp < 0.0:
		vyp = 0.0
	var e := surf.restitution(surface, vyp)
	var mu := surf.mu[surface]
	var r := p.radius
	var vrxp := 0.0
	var w_out := 0.0
	var mu_c := 2.0 * (vxp + r * w_in) / (7.0 * (1.0 + e) * maxf(vyp, 1e-9))
	if mu < mu_c:
		vrxp = vxp - mu * vyp * (1.0 + e)
		w_out = w_in - 5.0 * mu / (2.0 * r) * vyp * (1.0 + e)
	else:
		vrxp = 5.0 / 7.0 * vxp - 2.0 / 7.0 * r * w_in
		w_out = -vrxp / r
	var vryp := e * vyp
	var vrx := vrxp * cb - vryp * sb
	var vry := vrxp * sb + vryp * cb
	bounces += 1
	_event(Ev.BOUNCE, speed)
	if vry < ROLL_VN:
		_start_ground(
			x, z, tx * vrx + nx * vry, tz * vrx + nz * vry, -r * w_out * tx, -r * w_out * tz
		)
		return
	# Back into the air: new velocity, spin about +-b. Lift off the surface by 10 um so the next
	# swept test starts clear.
	s[3] = tx * vrx + nx * vry
	s[4] = ty * vrx + ny * vry
	s[5] = tz * vrx + nz * vry
	s[0] += nx * 1e-5
	s[1] += ny * 1e-5
	s[2] += nz * 1e-5
	var sgn := 1.0 if w_out >= 0.0 else -1.0
	ax[0] = bx * sgn
	ax[1] = by * sgn
	ax[2] = bz * sgn
	flight.spin = absf(w_out)


func _start_ground(x: float, z: float, vx: float, vz: float, wx: float, wz: float) -> void:
	phase = Phase.ROLL
	_x = x
	_z = z
	_vx = vx
	_vz = vz
	_wx = wx
	_wz = wz
	_sleep = 0.0
	_gvy_prev = 0.0
	_event(Ev.ROLL, sqrt(vx * vx + vz * vz))


# --- ground --------------------------------------------------------------------------------------


func _roll(dt: float) -> void:
	var surface := hole.surface_at(_x, _z)
	if surface == HoleData.Surface.WATER:
		_finish(Phase.WATER, Ev.WATER, roll_speed())
		return
	if surface == HoleData.Surface.OUT:
		_finish(Phase.OUT, Ev.OUT, roll_speed())
		return
	var g := p.g
	hole.grad_into(_x, _z, _g)
	var l2 := 1.0 + _g[0] * _g[0] + _g[1] * _g[1]
	# Horizontal pull of gravity along the surface (full for a sliding ball).
	var ax := -g * _g[0] / l2
	var az := -g * _g[1] / l2
	var px := _x
	var pz := _z
	var sx := _vx - _wx
	var sz := _vz - _wz
	var slip := sqrt(sx * sx + sz * sz)
	if slip > SLIP_EPS:
		var f := surf.mu[surface] * g / slip
		_vx += (ax - f * sx) * dt
		_vz += (az - f * sz) * dt
		_wx += 2.5 * f * sx * dt
		_wz += 2.5 * f * sz * dt
		if (_vx - _wx) * sx + (_vz - _wz) * sz <= 0.0:  # slip ran out: rolling from here
			_wx = _vx
			_wz = _vz
		_sleep = 0.0
	else:
		var a := surf.roll[surface]
		ax *= 5.0 / 7.0
		az *= 5.0 / 7.0
		var pull := sqrt(ax * ax + az * az)
		var hold := pull < GolfSurfaces.STATIC_FACTOR * a
		var sp := sqrt(_vx * _vx + _vz * _vz)
		if sp < 1e-9 and hold:
			_vx = 0.0
			_vz = 0.0
		else:
			_vx += ax * dt
			_vz += az * dt
			sp = sqrt(_vx * _vx + _vz * _vz)
			if sp > 1e-12:
				var k := maxf(0.0, sp - a * dt) / sp
				_vx *= k
				_vz *= k
		_wx = _vx
		_wz = _vz
		sp = sqrt(_vx * _vx + _vz * _vz)
		_sleep = _sleep + dt if sp < SLEEP_V and hold else 0.0
	var h0 := hole.height(_x, _z)
	var bounced := _move(dt)
	if not hole.contains(_x, _z):
		_finish(Phase.OUT, Ev.OUT, roll_speed())
		return
	# Ledges and ramp lips: the ground drops away faster than the ball can follow -> it flies.
	var gvy := (hole.height(_x, _z) - h0) / dt
	var sp2 := _vx * _vx + _vz * _vz
	if not bounced and sp2 > HOP_MIN_SPEED * HOP_MIN_SPEED and gvy - _gvy_prev < -HOP_MIN_DV:
		_hop(h0, _gvy_prev)
		return
	_gvy_prev = 0.0 if bounced else gvy
	if _cup(px, pz):
		return
	if hole.surface_at(_x, _z) != HoleData.Surface.WATER:
		last_safe = Vector3(px, 0.0, pz)
	if _sleep >= SLEEP_T:
		_vx = 0.0
		_vz = 0.0
		phase = Phase.REST
		# Died with its centre over the hole: it drops.
		var hx := _x - hole.pin.x
		var hz := _z - hole.pin.z
		if hx * hx + hz * hz < CUP_R * CUP_R:
			_x = hole.pin.x
			_z = hole.pin.z
			_finish(Phase.HOLED, Ev.HOLED, 0.0)


## Moves the rolling ball by its velocity for dt, bouncing off walls and bumpers in time order
## (up to four contacts per step). Returns true if anything was hit.
func _move(dt: float) -> bool:
	var remaining := dt
	var hit := false
	for it in 4:
		var dx := _vx * remaining
		var dz := _vz * remaining
		var t := _sweep2d(_x, _z, dx, dz, p.radius)
		if t > 1.0:
			_x += dx
			_z += dz
			return hit
		var nx := _hn[0]
		var nz := _hn[1]
		_x += dx * t + nx * 1e-5
		_z += dz * t + nz * 1e-5
		var vn := _vx * nx + _vz * nz
		var tx := _vx - vn * nx
		var tz := _vz - vn * nz
		_vx = tx * WALL_KEEP - E_WALL * vn * nx
		_vz = tz * WALL_KEEP - E_WALL * vn * nz
		_wx = _vx
		_wz = _vz
		_sleep = 0.0
		_event(Ev.WALL, -vn)
		hit = true
		remaining *= 1.0 - t
	return hit


## Airborne: below the wall tops a flying ball bounces off walls and bumpers too.
func _fly_walls() -> void:
	var fs := flight.s
	if fs[1] - hole.height(fs[0], fs[2]) > hole.wall_height + p.radius:
		return
	var dx := fs[0] - _fly_prev[0]
	var dz := fs[2] - _fly_prev[1]
	var t := _sweep2d(_fly_prev[0], _fly_prev[1], dx, dz, p.radius)
	if t > 1.0:
		return
	var nx := _hn[0]
	var nz := _hn[1]
	fs[0] = _fly_prev[0] + dx * t + nx * 1e-5
	fs[2] = _fly_prev[1] + dz * t + nz * 1e-5
	var vn := fs[3] * nx + fs[5] * nz
	var tx := fs[3] - vn * nx
	var tz := fs[5] - vn * nz
	fs[3] = tx * WALL_KEEP - E_WALL * vn * nx
	fs[5] = tz * WALL_KEEP - E_WALL * vn * nz
	_event(Ev.WALL, -vn)


## Earliest fraction of the move (px, pz) + (dx, dz) at which a ball of radius r touches a wall
## or bumper; the contact normal (pointing at the ball) goes into _hn. 2.0 when nothing is hit.
func _sweep2d(px: float, pz: float, dx: float, dz: float, r: float) -> float:
	var best := 2.0
	var w := hole.walls
	for o in range(0, w.size(), 4):
		best = _toi_segment(px, pz, dx, dz, w[o], w[o + 1], w[o + 2], w[o + 3], r, best)
	var b := hole.bumpers
	for o in range(0, b.size(), 3):
		best = _toi_circle(px, pz, dx, dz, b[o], b[o + 1], b[o + 2] + r, best)
	return best


## Circle vs segment a-b (face, then the two end points); returns the new best time.
func _toi_segment(
	px: float,
	pz: float,
	dx: float,
	dz: float,
	ax: float,
	az: float,
	bx: float,
	bz: float,
	r: float,
	best: float
) -> float:
	var ex := bx - ax
	var ez := bz - az
	var len2 := ex * ex + ez * ez
	if len2 > 1e-12:
		var il := 1.0 / sqrt(len2)
		var nx := -ez * il
		var nz := ex * il
		var s0 := (px - ax) * nx + (pz - az) * nz
		var sv := dx * nx + dz * nz
		if s0 < 0.0:
			nx = -nx
			nz = -nz
			s0 = -s0
			sv = -sv
		if sv < 0.0:  # approaching the face
			var t := 0.0 if s0 <= r else (s0 - r) / -sv
			if t < best:
				var u := ((px + dx * t - ax) * ex + (pz + dz * t - az) * ez) / len2
				if u >= 0.0 and u <= 1.0:
					best = t
					_hn[0] = nx
					_hn[1] = nz
	best = _toi_circle(px, pz, dx, dz, ax, az, r, best)
	return _toi_circle(px, pz, dx, dz, bx, bz, r, best)


## Point (px, pz) moving by (dx, dz) vs a circle at (cx, cz) of radius rr.
func _toi_circle(
	px: float, pz: float, dx: float, dz: float, cx: float, cz: float, rr: float, best: float
) -> float:
	var qx := px - cx
	var qz := pz - cz
	var a := dx * dx + dz * dz
	var b := 2.0 * (qx * dx + qz * dz)
	var c := qx * qx + qz * qz - rr * rr
	var t := 2.0
	if c <= 0.0:
		if b < 0.0:
			t = 0.0  # already overlapping and moving inwards: push out now
	elif a > 1e-18:
		var disc := b * b - 4.0 * a * c
		if disc >= 0.0:
			t = (-b - sqrt(disc)) / (2.0 * a)
	if t < 0.0 or t > 1.0 or t >= best:
		return best
	var hx := qx + dx * t
	var hz := qz + dz * t
	var hl := sqrt(hx * hx + hz * hz)
	if hl < 1e-12:
		return best
	_hn[0] = hx / hl
	_hn[1] = hz / hl
	return t


## The rolling ball leaves the ground from height h0 with the ground's previous vertical speed.
func _hop(h0: float, vy: float) -> void:
	var fs := flight.s
	fs[0] = _x
	fs[1] = h0 + p.radius + 1e-4
	fs[2] = _z
	fs[3] = _vx
	fs[4] = vy
	fs[5] = _vz
	flight.spin = 0.0
	flight.time = time
	flight.apex = fs[1]
	phase = Phase.FLY
	_event(Ev.HOP, sqrt(_vx * _vx + _vz * _vz))


## Did the roll from (px, pz) to the current point cross the cup? Captures or lips out.
func _cup(px: float, pz: float) -> bool:
	var cx := hole.pin.x
	var cz := hole.pin.z
	var dx := _x - px
	var dz := _z - pz
	var len2 := dx * dx + dz * dz
	var ex := _x - cx
	var ez := _z - cz
	if _cup_skip:
		if ex * ex + ez * ez > (CUP_R + p.radius) * (CUP_R + p.radius):
			_cup_skip = false
		return false
	# Judge the putt where its path passes the cup centre: b is the sideways offset of the path
	# (the foot of the perpendicular must fall inside this step).
	if len2 < 1e-18:
		return false
	var t := ((cx - px) * dx + (cz - pz) * dz) / len2
	if t < 0.0 or t > 1.0:
		return false
	var qx := px + dx * t - cx
	var qz := pz + dz * t - cz
	var b2 := qx * qx + qz * qz
	if b2 >= CUP_R * CUP_R:
		return false
	var sp := sqrt(_vx * _vx + _vz * _vz)
	var chord := 2.0 * sqrt(CUP_R * CUP_R - b2) - p.radius
	var v_max := RIM_ASSIST * maxf(chord, 0.0) * _k_cup
	if sp <= v_max:
		_x = cx
		_z = cz
		_vx = 0.0
		_vz = 0.0
		_finish(Phase.HOLED, Ev.HOLED, sp)
		return true
	# Lip out: turn away from the cup centre in proportion to the offset, keep 60% speed. q is the
	# closest point of the path relative to the cup, so it points away from the cup.
	var b := sqrt(b2)
	var ux := _vx / sp
	var uz := _vz / sp
	var ox := qx / b if b > 1e-6 else -uz
	var oz := qz / b if b > 1e-6 else ux
	var turn := 0.3 + 0.7 * b / CUP_R
	var nx := ux + ox * turn
	var nz := uz + oz * turn
	var nl := sqrt(nx * nx + nz * nz)
	_vx = nx / nl * sp * LIP_KEEP
	_vz = nz / nl * sp * LIP_KEEP
	_wx = _vx
	_wz = _vz
	_cup_skip = true
	_event(Ev.LIP, sp)
	return false


## Fingerprint for golden / determinism tests.
func fingerprint() -> String:
	var b := (
		PackedFloat64Array([_x, _z, _vx, _vz, time, float(phase), float(bounces)]).to_byte_array()
	)
	b.append_array(flight.s.to_byte_array())
	return b.hex_encode()
