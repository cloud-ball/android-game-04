class_name StackDifficulty
extends RefCounted
## Stack Drop difficulty data (pure): the player's start level and how the CPU plays.
## Tune with tools/stack_selfplay.gd. 12 x 24 board, vs its "average" player profile (2026-11-13):
## Easy wins ~27%, Medium ~53%, Hard ~100% (Hard ~35% vs the "good" profile).

## Per difficulty: player's start level, CPU seconds per shard, CPU top_k, noise, hold.
const LEVELS := {
	"easy": {"start": 1, "think": 2.2, "top_k": 3, "noise": 0.6, "hold": false},
	"medium": {"start": 2, "think": 1.9, "top_k": 3, "noise": 0.9, "hold": true},
	"hard": {"start": 4, "think": 1.15, "top_k": 1, "noise": 0.2, "hold": true},
}


## Seconds the CPU spends per shard at its current level (it speeds up 7% per level).
static func cpu_think(difficulty: String, level: int) -> float:
	return think_at(float(LEVELS[difficulty].think), level)


static func think_at(base_think: float, level: int) -> float:
	return base_think / (1.0 + 0.07 * (level - 1))
