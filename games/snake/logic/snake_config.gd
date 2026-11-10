class_name SnakeConfig
extends Resource
## Tunable data for Serpent Grid (see games/snake/data/*.tres and .claude/rules/snake.md).

@export var width: int = 12
@export var height: int = 18
@export var start_length: int = 3
@export var orb_count: int = 2
## Ticks per second at the start of a match; rises with the longest snake's length.
@export var base_hz: float = 7.0
@export var hz_per_segment: float = 0.12
@export var max_hz: float = 11.0
@export var orb_score: int = 10
@export var crash_bonus: int = 100
## CPU: chance per decision to wander (a random SAFE move) instead of chasing an orb.
@export var ai_wander: float = 0.12
## CPU: treat cells next to the player's head as blocked when it has another safe option
## (avoids head-on draws).
@export var ai_avoid_heads: bool = true
## CPU: chance per decision to look for a move that cuts the player off (forces a crash).
@export var ai_hunt: float = 0.0
## CPU: when hunting, also take moves that leave the player less room than squeeze x its length.
@export var ai_squeeze: float = 1.0


static func for_difficulty(difficulty: String) -> SnakeConfig:
	var path := "res://games/snake/data/%s.tres" % difficulty
	if ResourceLoader.exists(path):
		return load(path) as SnakeConfig
	return SnakeConfig.new()
