class_name DailyChallenge
extends RefCounted
## One challenge per calendar day (UTC), rotating through games that are enabled.
## Completion is stored in the save's profile.daily = {day, done}; the reward is paid once.

const LIST: Array[Dictionary] = [
	{"id": "win_medium", "game": "snake", "text": "Beat the CPU on Medium", "reward": 150},
	{"id": "length_12", "game": "snake", "text": "Grow to length 12", "reward": 120},
	{"id": "score_150", "game": "snake", "text": "Score 150 in one match", "reward": 150},
	{"id": "win_hard", "game": "snake", "text": "Beat the CPU on Hard", "reward": 250},
	{"id": "eat_8", "game": "snake", "text": "Eat 8 orbs in one match", "reward": 100},
]


static func for_day(day: int) -> Dictionary:
	return LIST[posmod(day, LIST.size())]


## stats: {game, difficulty, won, length, score, eaten}
static func is_met(ch: Dictionary, stats: Dictionary) -> bool:
	if ch.game != stats.get("game", ""):
		return false
	match ch.id:
		"win_medium":
			return stats.won and stats.difficulty in ["medium", "hard"]
		"win_hard":
			return stats.won and stats.difficulty == "hard"
		"length_12":
			return stats.length >= 12
		"score_150":
			return stats.score >= 150
		"eat_8":
			return stats.eaten >= 8
	return false


static func today() -> int:
	return Rng.unix_day(Time.get_unix_time_from_system())


static func done_today(profile: Dictionary, day: int) -> bool:
	var d: Variant = profile.get("daily", {})
	return typeof(d) == TYPE_DICTIONARY and int(d.get("day", -1)) == day and bool(d.get("done"))


## Marks today's challenge done if the stats meet it. Returns the reward to pay (0 if none).
static func report(profile: Dictionary, day: int, stats: Dictionary) -> int:
	var ch := for_day(day)
	if done_today(profile, day) or not is_met(ch, stats):
		return 0
	profile["daily"] = {"day": day, "done": true}
	return int(ch.reward)
