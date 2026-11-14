class_name PoolPlanner
extends RefCounted
## Simulation-based Break & Bank CPU (pure; safe to run on a worker thread with its own copies).
## Research: docs/research/Cue Club pool game design.md (CPU) and ... versus mobile pool games.md.
##   1. Every (legal ball, pocket) pair -> ghost-ball aim + an analytic pot chance under the CPU's
##      own aim noise (cut, distances, pocket window). Prune to the best TOP_K.
##   2. Each survivor x speed/spin variants is simulated (1/120 s planning step) and judged by the
##      real rules: fouls are rejected; a pot is scored by pot chance x (1 + position value), where
##      position = best next shots from where the cue ball stops (1.0 / 0.33 / 0.15).
##   3. Robustness: the best few plans are replayed with the CPU's own typical error (aim +-0.8
##      sigma, speed +-1 sigma). Shots that only work when struck perfectly - the cue ball follows
##      into a pocket, another ball is hit first, the 8 drops early - are marked down. Self-play
##      before this: medium scratched on 17% of its shots and lost 6 of 16 games on the 8.
##   4. Hard plays a safety when nothing is likely: a soft legal hit that leaves the opponent the
##      worst next shot. When no pot survives at all, medium and hard play the safest legal hit
##      instead of a blind one (easy keeps the blind hit - beginners do that). Easy picks among
##      its few best plans (human-like variety).
## Execution noise is applied by the caller (PoolCpu._noisy), so planning and luck stay separate.

const LEVEL := {
	"easy":
	{"top_k": 3, "speeds": [1.0], "spins": [0.0], "position": 0.2, "pick": 3, "safety": false},
	"medium":
	{
		"top_k": 6,
		"speeds": [0.8, 1.15],
		"spins": [0.0, 0.3],
		"position": 0.6,
		"pick": 2,
		"safety": false
	},
	"hard":
	{
		"top_k": 9,
		"speeds": [0.75, 1.0, 1.35],
		"spins": [0.0, 0.35, -0.35],
		"position": 1.0,
		"pick": 1,
		"safety": true
	},
}
const MAX_CUT_DEG := 78.0
## Planner shots stop within ~8 s (159 sampled: median 4.1 s, max 7.9 s); 9 s is a safety cap.
const ROLLOUT_SECONDS := 9.0
## Robustness check: plans replayed per level, and how hard fouls / a lost game count.
## Easy skips the check on purpose: careless shots that give away fouls are part of its level.
const ROBUST := {"easy": 0, "medium": 3, "hard": 4}
const FOUL_COST := 0.5
const LOSE_COST := 3.0

var rollouts := 0
var _sim: CueSim


## Returns {dir, speed, side, top, pocket, safety: bool, score} for the shooter in `m`.
func plan(
	m: PoolMatch, difficulty: String, sigma_deg: float, rng: RandomNumberGenerator
) -> Dictionary:
	var lv: Dictionary = LEVEL.get(difficulty, LEVEL["medium"])
	var sim := m.sim
	var cue := Vector2(sim.px[0], sim.py[0])
	var cands := candidates(sim, m.state, cue, sigma_deg)
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.p > b.p)
	cands = cands.slice(0, int(lv.top_k))
	var plans: Array = []
	for c in cands:
		for sm in lv.speeds:
			for top in lv.spins:
				var speed: float = c.speed * sm
				var r := _rollout(m, c.dir, speed, top, c.pocket)
				if r.foul or not r.potted_target(c.ball):
					continue
				var pos := 0.0
				if r.continues:
					pos = _position_value(r.sim, r.state, sigma_deg)
				var score: float = c.p * (1.0 + float(lv.position) * pos)
				plans.append(
					{
						"dir": c.dir,
						"speed": speed,
						"side": 0.0,
						"top": top,
						"pocket": c.pocket,
						"ball": c.ball,
						"safety": false,
						"score": score
					}
				)
	plans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	_robust(m, plans, int(ROBUST.get(difficulty, 3)), sigma_deg, difficulty)
	var best: Dictionary = plans[0] if not plans.is_empty() else {}
	if (plans.is_empty() and difficulty != "easy") or (lv.safety and best.score < 0.3):
		var safe := _safety(m, sigma_deg)
		if not safe.is_empty() and (best.is_empty() or safe.score > best.score):
			return safe
	if plans.is_empty():
		return {}
	var n := mini(int(lv.pick), plans.size())
	return plans[rng.randi_range(0, n - 1)]


## (ball, pocket) options with ghost-ball aim and an analytic pot chance.
static func candidates(sim: CueSim, state: PoolState, cue: Vector2, sigma_deg: float) -> Array:
	var out: Array = []
	var r := sim.p.radius
	for b in PoolRules.legal_targets(state):
		var obj := Vector2(sim.px[b], sim.py[b])
		for k in sim.table.pocket_count():
			var pocket := Vector2(sim.table.pocket_x[k], sim.table.pocket_y[k])
			var to_pocket := pocket - obj
			var d2 := to_pocket.length()
			var ghost := obj - to_pocket / d2 * 2.0 * r
			var to_ghost := ghost - cue
			var d1 := to_ghost.length()
			if d1 < 1e-4:
				continue
			var cut := absf(to_ghost.angle_to(to_pocket))
			if rad_to_deg(cut) > MAX_CUT_DEG:
				continue
			if not _clear(sim, cue, ghost, b) or not _clear(sim, obj, pocket, b):
				continue
			var p := pot_chance(sim, k, to_pocket / d2, d1, d2, cut, sigma_deg)
			if p < 0.02:
				continue
			var speed := clampf(0.9 + 0.9 * d1 + 1.3 * d2 / maxf(cos(cut), 0.3), 1.0, 6.0)
			out.append(
				{"ball": b, "pocket": k, "dir": to_ghost / d1, "speed": speed, "p": p, "cut": cut}
			)
	return out


## Chance the object ball drops, for a Gaussian aim error sigma (deg) at the cue: the cue ball's
## lateral miss d1*e moves the contact normal by d1*e*cos(cut)/(2R), so the object ball strays
## d2 * that at the pocket; the pocket's window narrows with the approach angle.
static func pot_chance(
	sim: CueSim, k: int, approach: Vector2, d1: float, d2: float, cut: float, sigma_deg: float
) -> float:
	var r := sim.p.radius
	var corner := k < 4
	var axis: Vector2
	if corner:
		axis = Vector2(signf(sim.table.pocket_x[k]), signf(sim.table.pocket_y[k])).normalized()
	else:
		axis = Vector2(signf(sim.table.pocket_x[k]), 0.0)
	var cos_a := approach.dot(axis)
	if cos_a < (0.2 if corner else 0.5):
		return 0.0
	var half := (sim.p.corner_mouth if corner else sim.p.side_mouth) * 0.5 - r
	var window := half * cos_a
	var sigma := deg_to_rad(maxf(sigma_deg, 0.02))
	var lateral := d2 * d1 * sigma * cos(cut) / (2.0 * r) + 0.001
	var x := window / (lateral * 1.41421356)
	return tanh(1.2027606 * x)  # erf approximation


static func _clear(sim: CueSim, a: Vector2, b: Vector2, skip: int) -> bool:
	var ab := b - a
	var len2 := ab.length_squared()
	var lim := 2.0 * sim.p.radius
	for i in range(1, CueSim.N):
		if i == skip or not sim.on_table(i):
			continue
		var p := Vector2(sim.px[i], sim.py[i])
		var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0) if len2 > 0.0 else 0.0
		if (a + ab * t).distance_to(p) < lim:
			return false
	return true


class Rollout:
	extends RefCounted
	var sim: CueSim
	var state: PoolState
	var foul := false
	var lost := false
	var won := false
	var continues := false
	var shot: PoolShot

	func potted_target(b: int) -> bool:
		return shot.potted(b)


## Plays the shot noiselessly on a copy (coarse planning step) and applies the real rules.
## On the 8 the pocket is called first, as the game does (pocket < 0 -> pocket 0, like
## PoolCpu's callers): without a call the rules reject the shot, which hid scratches on the 8
## and wrong-pocket 8s from the planner (self-play: most of hard's games lost on the 8).
func _rollout(m: PoolMatch, dir: Vector2, speed: float, top: float, pocket: int) -> Rollout:
	if _sim == null:
		_sim = CueSim.new(m.sim.p)
		_sim.substep = CueSim.SUBSTEP * 2.0
	_sim.copy_from(m.sim)
	_sim.substep = CueSim.SUBSTEP * 2.0
	_sim.strike(dir.x, dir.y, speed, 0.0, top)
	_sim.run_to_rest(ROLLOUT_SECONDS)
	rollouts += 1
	var r := Rollout.new()
	r.sim = _sim
	r.shot = PoolShot.from_sim(_sim)
	var state := m.state
	if PoolRules.requires_call(state) and state.called_pocket < 0:
		state = PoolRules.call_pocket(state, maxi(0, pocket))
	var res := PoolRules.apply_shot(state, r.shot)
	r.state = res.state
	var over := res.outcome == PoolRules.Outcome.GAME_OVER
	r.lost = over and res.winner != m.state.shooter
	r.won = over and res.winner == m.state.shooter
	r.foul = res.foul() or r.lost
	r.continues = res.outcome == PoolRules.Outcome.CONTINUE
	return r


## Replays the top n plans with typical execution error and re-ranks them: the score is scaled
## by how often the pot survives the error, minus the chance of a foul or of losing on the 8.
func _robust(m: PoolMatch, plans: Array, n: int, sigma_deg: float, difficulty: String) -> void:
	var count := mini(n, plans.size())
	if count == 0:
		return
	var sig := deg_to_rad(maxf(sigma_deg, 0.1))
	var ss := float(PoolCpu.SPEED_SIGMA.get(difficulty, 0.09))
	var tries := [[0.8 * sig, 1.0], [-0.8 * sig, 1.0], [0.0, 1.0 + ss], [0.0, 1.0 - ss]]
	# The 8 decides the game (self-play: the cue ball following it in lost most hard games
	# that were lost on the 8), so those shots get a wider, denser check.
	var eight_tries := tries.duplicate()
	for t in [
		[0.4, 1.0], [-0.4, 1.0], [1.5, 1.0], [-1.5, 1.0], [0.0, 1.0 + 2.0 * ss], [1.0, 1.0 - ss]
	]:
		eight_tries.append([float(t[0]) * sig, float(t[1])])
	for i in count:
		var pl: Dictionary = plans[i]
		var ts: Array = eight_tries if int(pl.get("ball", -1)) == 8 else tries
		var pots := 0
		var fouls := 0
		var losses := 0
		for t in ts:
			var dir: Vector2 = (pl.dir as Vector2).rotated(float(t[0]))
			var r := _rollout(m, dir, float(pl.speed) * float(t[1]), float(pl.top), int(pl.pocket))
			if r.lost:
				losses += 1
			elif r.foul:
				fouls += 1
			elif r.continues or r.won:
				pots += 1
		var k := float(ts.size())
		pl.score = (
			float(pl.score) * (0.4 + 0.6 * pots / k)
			- FOUL_COST * fouls / k
			- LOSE_COST * losses / k
		)
	# Only checked plans stay; one that now scores below zero is worse than a safe legal hit.
	var head := plans.slice(0, count).filter(func(p: Dictionary) -> bool: return p.score >= 0.0)
	head.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	plans.assign(head)


## How good the next shots are from where the cue ball stopped (same shooter).
static func _position_value(sim: CueSim, state: PoolState, sigma_deg: float) -> float:
	if not sim.on_table(0):
		return 0.0
	var cue := Vector2(sim.px[0], sim.py[0])
	var ps: Array = []
	for c in candidates(sim, state, cue, sigma_deg):
		ps.append(c.p)
	ps.sort()
	ps.reverse()
	var w := [1.0, 0.33, 0.15]
	var v := 0.0
	for i in mini(3, ps.size()):
		v += w[i] * ps[i]
	return v / 1.48


## Hard only: soft full hits on legal balls; keep the one that leaves the opponent least.
func _safety(m: PoolMatch, sigma_deg: float) -> Dictionary:
	var best := {}
	var cue := Vector2(m.sim.px[0], m.sim.py[0])
	for b in PoolRules.legal_targets(m.state):
		var dir := (Vector2(m.sim.px[b], m.sim.py[b]) - cue).normalized()
		for speed in [1.1, 1.6]:
			var r := _rollout(m, dir, speed, -0.2, -1)
			if r.foul:
				continue
			var opp := r.state.copy()
			var left := _position_value(r.sim, opp, sigma_deg)  # the opponent's chances
			var score := 0.35 * (1.0 - left)
			if best.is_empty() or score > best.score:
				best = {
					"dir": dir,
					"speed": speed,
					"side": 0.0,
					"top": -0.2,
					"pocket": -1,
					"safety": true,
					"score": score
				}
	return best
