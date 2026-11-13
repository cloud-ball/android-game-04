class_name PracticePlan
extends RefCounted
## Decides which first-match practice hint to show (pure). Each rule is [verb, threshold]: once the
## game's progress (shards placed, seconds played, ...) reaches the threshold and the player has
## never done that move, its hint is due. A verb is hinted at most MAX_SHOWS times per match and
## never again once learned.
## `learned` is the game's saved {verb: true} dictionary (edited in place).

const MAX_SHOWS := 2

var rules: Array = []
var learned: Dictionary = {}
var shown: Dictionary = {}
## Ignore the saved flags (dev: --practice), still learn within this session.
var force := false
var _session: Dictionary = {}


func _init(practice_rules: Array = [], saved: Dictionary = {}, force_all := false) -> void:
	rules = practice_rules
	learned = saved
	force = force_all


func is_learned(verb: String) -> bool:
	return _session.has(verb) or (not force and bool(learned.get(verb, false)))


## Records a move the player did. Returns true the first time ever (the caller saves then).
func learn(verb: String) -> bool:
	var first := not _session.has(verb) and not bool(learned.get(verb, false))
	_session[verb] = true
	learned[verb] = true
	return first


## The verb whose hint is due at this progress ("" = none). Counts it as shown.
func due(progress: float) -> String:
	for r in rules:
		var verb: String = r[0]
		if progress >= float(r[1]) and request(verb):
			return verb
	return ""


## Asks to show a hint for a verb outside the threshold rules (e.g. "near an edge"). True = show it.
func request(verb: String) -> bool:
	if is_learned(verb) or int(shown.get(verb, 0)) >= MAX_SHOWS:
		return false
	shown[verb] = int(shown.get(verb, 0)) + 1
	return true


## New match: per-match show counts reset; learned moves stay learned.
func new_match() -> void:
	shown = {}
