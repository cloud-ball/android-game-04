class_name PoolCpu
extends RefCounted
## Cue Club CPU. Pure: reads a PoolMatch, returns a plan
## {dir: Vector2, speed, side, top, pocket, place: Vector2 or null}.
##   break: hard at the apex ball; ball in hand: sets up a straight-in shot;
##   otherwise PoolPlanner (simulated shots, position play, Hard safeties); if it finds nothing,
##   the basic choice: the clear (ball, pocket) pair with the best cut and distance.
## Execution noise (Gaussian aim / speed) is applied last, so luck is separate from planning.
## planner = false gives the basic "greedy" player (used as a reference in self-play).

## Made weaker after phone play (2026-11-13): roughly double the research's starting sigmas.
const AIM_SIGMA := {"easy": 1.4, "medium": 0.7, "hard": 0.32}
const SPEED_SIGMA := {"easy": 0.14, "medium": 0.09, "hard": 0.05}
## Easy / Medium pick among their best few shots (not always the best one).
const PICK_FROM := {"easy": 4, "medium": 2, "hard": 1}
const MAX_CUT_DEG := 72.0


static func plan(
	m: PoolMatch, difficulty: String, rng: RandomNumberGenerator, planner := true, sigma := -1.0
) -> Dictionary:
	var aim_sigma: float = sigma if sigma >= 0.0 else float(AIM_SIGMA.get(difficulty, 0.7))
	var sim := m.sim
	var s := m.state
	var out := {
		"dir": Vector2.UP, "speed": 3.0, "side": 0.0, "top": 0.0, "pocket": -1, "place": null
	}
	if s.phase == PoolState.Phase.BREAK:
		if s.ball_in_hand != PoolState.Hand.NONE:
			out.place = Vector2(0.0, -sim.table.hl * 0.5)
		var from: Vector2 = out.place if out.place != null else _pos(sim, 0)
		out.dir = (_pos(sim, 1) - from).normalized()
		out.speed = {"easy": 9.5, "medium": 10.5, "hard": 11.5}.get(difficulty, 10.5)
		return _noisy(out, difficulty, rng, aim_sigma)
	var targets := PoolRules.legal_targets(s)
	if s.ball_in_hand == PoolState.Hand.ANYWHERE:
		var spot := _ball_in_hand(m, targets)
		if spot != Vector2.INF:
			out.place = spot
	var cue: Vector2 = out.place if out.place != null else _pos(sim, 0)
	if planner:
		var work := m
		if out.place != null:
			work = m.snapshot()
			work.sim.place(0, cue.x, cue.y)
		var pl := PoolPlanner.new().plan(work, difficulty, aim_sigma, rng)
		if not pl.is_empty():
			for key in ["dir", "speed", "side", "top", "pocket"]:
				out[key] = pl[key]
			return _noisy(out, difficulty, rng, aim_sigma)
	var options: Array = []
	for b in targets:
		for k in sim.table.pocket_count():
			var c := _candidate(sim, cue, b, k)
			if not c.is_empty():
				c["pocket"] = k
				options.append(c)
	options.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.score > y.score)
	var best := -1.0
	if not options.is_empty():
		var n := mini(int(PICK_FROM.get(difficulty, 1)), options.size())
		var c: Dictionary = options[rng.randi_range(0, n - 1)]
		best = c.score
		out.dir = c.dir
		out.speed = c.speed
		out.pocket = c.pocket
	if best < 0.0 and not targets.is_empty():
		# Nothing clear: hit the nearest legal ball firmly (avoid the no-rail foul).
		var nearest: int = targets[0]
		for b in targets:
			if cue.distance_to(_pos(sim, b)) < cue.distance_to(_pos(sim, nearest)):
				nearest = b
		out.dir = (_pos(sim, nearest) - cue).normalized()
		out.speed = 3.0
		out.pocket = 0
	return _noisy(out, difficulty, rng, aim_sigma)


## One (ball, pocket) option: ghost-ball aim, cut angle, clear paths. Empty if unplayable.
static func _candidate(sim: CueSim, cue: Vector2, b: int, k: int) -> Dictionary:
	var r := sim.p.radius
	var obj := _pos(sim, b)
	var pocket := Vector2(sim.table.pocket_x[k], sim.table.pocket_y[k])
	var to_pocket := pocket - obj
	var d2 := to_pocket.length()
	var ghost := obj - to_pocket / d2 * 2.0 * r
	var to_ghost := ghost - cue
	var d1 := to_ghost.length()
	if d1 < 1e-4:
		return {}
	var cut := rad_to_deg(to_ghost.angle_to(to_pocket))
	if absf(cut) > MAX_CUT_DEG:
		return {}
	if k >= 4 and absf(to_pocket.normalized().x) < 0.45:
		return {}  # too shallow into a side pocket
	if not _clear(sim, cue, ghost, [0, b]) or not _clear(sim, obj, pocket, [0, b]):
		return {}
	var c := cos(deg_to_rad(cut))
	var speed := clampf(1.0 + 1.1 * d1 + 1.5 * d2 / maxf(c, 0.35), 1.2, 6.5)
	return {"dir": to_ghost / d1, "speed": speed, "score": c * c / (0.4 + d1 + d2)}


## No ball (other than the excluded ones) within 2R of the segment a-b.
static func _clear(sim: CueSim, a: Vector2, b: Vector2, skip: Array) -> bool:
	var ab := b - a
	var len2 := ab.length_squared()
	var lim := 2.0 * sim.p.radius
	for i in CueSim.N:
		if i in skip or not sim.on_table(i):
			continue
		var p := _pos(sim, i)
		var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0) if len2 > 0.0 else 0.0
		if (a + ab * t).distance_to(p) < lim:
			return false
	return true


## Ball in hand: a straight-in shot 25-35 cm behind the easiest ball.
static func _ball_in_hand(m: PoolMatch, targets: PackedInt32Array) -> Vector2:
	var sim := m.sim
	var best := Vector2.INF
	var best_len := INF
	for b in targets:
		for k in sim.table.pocket_count():
			var obj := _pos(sim, b)
			var pocket := Vector2(sim.table.pocket_x[k], sim.table.pocket_y[k])
			var d2 := obj.distance_to(pocket)
			if d2 >= best_len:
				continue
			var dir := (pocket - obj) / d2
			if k >= 4 and absf(dir.x) < 0.45:
				continue
			for back in [0.3, 0.22, 0.4]:
				var spot: Vector2 = obj - dir * (2.0 * sim.p.radius + back)
				if m.cue_spot_ok(spot.x, spot.y) and _clear(sim, obj, pocket, [0, b]):
					if _clear(sim, spot, obj, [0, b]):
						best = spot
						best_len = d2
						break
	return best


static func _noisy(
	out: Dictionary, difficulty: String, rng: RandomNumberGenerator, sigma: float
) -> Dictionary:
	var err := clampf(rng.randfn(0.0, sigma), -3.0 * sigma, 3.0 * sigma)
	out.dir = (out.dir as Vector2).rotated(deg_to_rad(err))
	var ss: float = SPEED_SIGMA.get(difficulty, 0.05)
	out.speed = float(out.speed) * (1.0 + clampf(rng.randfn(0.0, ss), -3.0 * ss, 3.0 * ss))
	return out


static func _pos(sim: CueSim, i: int) -> Vector2:
	return Vector2(sim.px[i], sim.py[i])
