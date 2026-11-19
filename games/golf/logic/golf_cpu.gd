class_name GolfCpu
extends RefCounted
## A CPU golfer (pure, deterministic): searches shots with the real solver and plays one with
## human-like error. Coarse fan of directions around the hole's route (flow field) plus straight at
## the cup, at several speeds; then a finer search around the three best. Each candidate is rolled
## to rest at the planner step (1/120 s, allowed by .claude/rules/golf.md) and scored: holed is
## best (sooner is better), water / out is worst, otherwise route metres left to the cup plus a
## little straight-line distance. Tiers differ in aim / speed error and, on Easy, in which of the
## top shots they pick. Safe to run on a worker thread (HoleData is only read).
## Plan: docs/plans/2026-11-19-fairway-flick-complete.md (step E1).

enum Tier { EASY, MEDIUM, HARD }

const AIM_SIGMA_DEG := [3.0, 1.5, 0.5]
const SPEED_SIGMA := [0.08, 0.04, 0.015]  # fraction of the planned speed
const TOP_K := [3, 2, 1]
const PICK_MARGIN := 2.5  # Easy / Medium only pick among shots this close to the best score
const PLAN_DT := 1.0 / 120.0
const PLAN_MAX_T := 8.0
const COARSE_SPEEDS := [1.3, 2.2, 3.4, 5.0, 7.2, 10.5]
const COARSE_ANGLES := [-30.0, -22.5, -15.0, -7.5, 0.0, 7.5, 15.0, 22.5, 30.0]
const FINE_ANGLES := [-3.0, 0.0, 3.0]
const FINE_SPEEDS := [0.9, 1.0, 1.1]
const MAX_SPEED := 13.0

var hole: HoleData
var preset: CoursePreset
var spec: Dictionary
var field: PackedFloat64Array
var simulated := 0  # rollouts done by the last search (budget checks)

# The last search, reused when another golfer plays from the very same spot (everyone tees off
# from the tee): only the error model differs between them.
var _cache_from := Vector3(INF, INF, INF)
var _cache: Array = []


func _init(h: HoleData, p: CoursePreset, hole_spec: Dictionary) -> void:
	hole = h
	preset = p
	spec = hole_spec
	field = MiniBaker.flow_field(spec)


## Every candidate from `from`, best first: [score, vx, vz]. Deterministic. (GolfCpuThink runs
## the same two stages on worker threads.)
func search(from: Vector3) -> Array:
	simulated = 0
	var out := _score_all(from, coarse_candidates(from))
	out.sort_custom(better)
	out.append_array(_score_all(from, fine_candidates(out)))
	out.sort_custom(better)
	return out


## Stage 1: [angle, speed] pairs fanned around the route and straight at the cup.
func coarse_candidates(from: Vector3) -> Array:
	var route := MiniBaker.flow_dir(spec, hole.pin, from)
	var base := atan2(route.z, route.x)
	var to_pin := Vector2(hole.pin.x - from.x, hole.pin.z - from.z).angle()
	var out: Array = []
	for sp in COARSE_SPEEDS:
		for da in COARSE_ANGLES:
			out.append([base + deg_to_rad(da), sp])
		out.append([to_pin, sp])
	return out


## Stage 2: small angle / speed changes around the three best scored shots (`ranked`, sorted).
func fine_candidates(ranked: Array) -> Array:
	var out: Array = []
	for k in mini(3, ranked.size()):
		var c: Array = ranked[k]
		var a := atan2(c[2], c[1])
		var sp0 := Vector2(c[1], c[2]).length()
		for da in FINE_ANGLES:
			for f in FINE_SPEEDS:
				if da == 0.0 and f == 1.0:
					continue
				out.append([a + deg_to_rad(da), minf(sp0 * f, MAX_SPEED)])
	return out


## [angle, speed] -> [score, vx, vz].
func scored(from: Vector3, cand: Array) -> Array:
	var a: float = cand[0]
	var sp: float = cand[1]
	var vx := cos(a) * sp
	var vz := sin(a) * sp
	return [evaluate(from, vx, vz), vx, vz]


## The shot this golfer actually plays: a pick among its best options, then aim / speed error.
func choose(from: Vector3, tier: int, rng: RandomNumberGenerator) -> Vector2:
	if from != _cache_from:
		_cache = search(from)
		_cache_from = from
	return pick(_cache, tier, rng)


## Error model on top of a ranked search (shared by choose() and GolfCpuThink).
static func pick(all: Array, tier: int, rng: RandomNumberGenerator) -> Vector2:
	var best: float = all[0][0]
	var pool := 1
	while pool < mini(TOP_K[tier], all.size()) and float(all[pool][0]) <= best + PICK_MARGIN:
		pool += 1
	var chosen: Array = all[rng.randi_range(0, pool - 1)]
	var a := atan2(chosen[2], chosen[1])
	var sp := Vector2(chosen[1], chosen[2]).length()
	var aim_sigma := deg_to_rad(AIM_SIGMA_DEG[tier])
	a += clampf(rng.randfn(0.0, aim_sigma), -3.0 * aim_sigma, 3.0 * aim_sigma)
	var s_sigma: float = SPEED_SIGMA[tier]
	sp *= 1.0 + clampf(rng.randfn(0.0, s_sigma), -3.0 * s_sigma, 3.0 * s_sigma)
	sp = clampf(sp, 0.3, MAX_SPEED)
	return Vector2(cos(a), sin(a)) * sp


## Score of one shot (lower is better).
func evaluate(from: Vector3, vx: float, vz: float) -> float:
	simulated += 1
	var b := GolfBall.new(hole, preset)
	b.putt(from.x, from.z, vx, vz)
	while not b.done() and b.time < PLAN_MAX_T:
		b.substep(PLAN_DT)
	match b.phase:
		GolfBall.Phase.HOLED:
			return -100.0 + b.time
		GolfBall.Phase.WATER, GolfBall.Phase.OUT:
			return 1000.0
	var q := b.pos()
	var metres := MiniBaker.flow_metres(spec, field, q)
	if metres >= 1e5:
		return 900.0
	return metres + 0.25 * Vector2(q.x - hole.pin.x, q.z - hole.pin.z).length()


func _score_all(from: Vector3, cands: Array) -> Array:
	var out: Array = []
	for c in cands:
		out.append(scored(from, c))
	return out


## Sort order: lower score first, ties broken by velocity so the order never depends on threads.
static func better(p: Array, q: Array) -> bool:
	if p[0] != q[0]:
		return p[0] < q[0]
	if p[1] != q[1]:
		return p[1] < q[1]
	return p[2] < q[2]
