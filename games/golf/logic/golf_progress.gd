class_name GolfProgress
extends RefCounted
## Cup Dash progression and rewards (pure): the save namespace (schema 2 + migrate), stars
## per hole, world unlocks, coins, and the stats handed to DailyChallenge.
## Plan: docs/plans/2026-11-19-cup-dash-complete.md (step G).

const SCHEMA := 2
const DEFAULTS := {
	"played": 0,  # Rush matches finished
	"wins": 0,
	"losses": 0,
	"best_score": 0,  # kept from schema 1 (unused since the mini-golf re-base)
	"difficulty": "medium",
	"tutorial_seen": false,
	"mode": "rush",
	"world": "meadow",
	"unlocked": ["meadow"],
	"tour_best": {},  # world id -> best total strokes over par (lower is better)
	"stars": {},  # hole id -> best stars (0-3)
	"aces": 0,
}
## Coins: a Rush win per tier, each hole won, each Tour star, finishing a Tour.
const WIN_COINS := {"easy": 40, "medium": 70, "hard": 120}
const HOLE_WIN_COINS := 10
const STAR_COINS := 5
const TOUR_COINS := 25


## Schema history: 1 = first version (played, wins, losses, best_score, difficulty,
## tutorial_seen); 2 = worlds, unlocks, Tour bests, stars, aces, last mode / world.
static func migrate(old: Dictionary, from: int, _to: int) -> Dictionary:
	var g := old.duplicate(true)
	if from < 2:
		for k in ["mode", "world", "unlocked", "tour_best", "stars", "aces"]:
			if not g.has(k):
				var v: Variant = DEFAULTS[k]
				g[k] = v.duplicate(true) if v is Array or v is Dictionary else v
	return g


## Stars for one hole: 3 for an eagle or better (or a hole-in-one), 2 for a birdie, 1 for par,
## 0 over par or not holed.
static func stars(strokes: int, par: int, holed := true) -> int:
	if not holed or strokes <= 0:
		return 0
	if strokes == 1 or strokes <= par - 2:
		return 3
	if strokes == par - 1:
		return 2
	return 1 if strokes == par else 0


static func is_unlocked(save: Dictionary, world_id: String) -> bool:
	return world_id in (save.get("unlocked", []) as Array)


## Opens the world after `world_id` (winning a Rush match or finishing its Tour). Returns the id
## opened now, or "" if nothing new.
static func unlock_next(save: Dictionary, world_id: String) -> String:
	var ids := GolfWorlds.ids()
	var i := ids.find(world_id)
	if i < 0 or i + 1 >= ids.size():
		return ""
	var next := ids[i + 1]
	var list: Array = save["unlocked"]
	if next in list:
		return ""
	list.append(next)
	return next


## Keeps the best stars per hole; returns how many stars are new.
static func record_stars(save: Dictionary, hole_id: String, earned: int) -> int:
	var table: Dictionary = save["stars"]
	var before := int(table.get(hole_id, 0))
	if earned > before:
		table[hole_id] = earned
		return earned - before
	return 0


## Keeps the best Tour total (strokes over par) per world; true if it is a new best.
static func record_tour(save: Dictionary, world_id: String, over_par: int) -> bool:
	var table: Dictionary = save["tour_best"]
	if not table.has(world_id) or over_par < int(table[world_id]):
		table[world_id] = over_par
		return true
	return false


static func rush_coins(difficulty: String, holes_won: int, won: bool) -> int:
	return holes_won * HOLE_WIN_COINS + (int(WIN_COINS.get(difficulty, 0)) if won else 0)


static func tour_coins(stars_earned: int) -> int:
	return TOUR_COINS + stars_earned * STAR_COINS


## Stats for DailyChallenge.report().
static func daily_stats(
	mode: String, difficulty: String, won: bool, birdies: int, aces: int
) -> Dictionary:
	return {
		"game": "golf",
		"mode": mode,
		"difficulty": difficulty,
		"won": won,
		"birdies": birdies,
		"aces": aces,
	}
