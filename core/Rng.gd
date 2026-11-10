extends Node
## Seeded random streams. Game logic takes a seed or an RNG from here: never call randf()/randi().

var session_seed: int = 0


func _init() -> void:
	session_seed = int(Time.get_unix_time_from_system() * 1000.0) & 0x7fffffff


## A fresh, independent stream for one match or one system.
func make(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


## Next seed in the session sequence (deterministic once session_seed is fixed, e.g. by --seed).
func next_seed() -> int:
	session_seed = (session_seed * 1103515245 + 12345) & 0x7fffffff
	return session_seed


static func unix_day(unix_time: float) -> int:
	return int(floor(unix_time / 86400.0))


static func daily_seed(day: int) -> int:
	return hash("pa8-daily-%d" % day) & 0x7fffffff
