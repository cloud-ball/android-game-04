class_name PoolSeries
extends RefCounted
## A Cue Club match: one rack ("vs") or first to two frames ("bo3"), plus the per-player numbers
## for the end card. Pure; no nodes. Breaks alternate by frame, player 0 breaks the first.

const TARGET := {"vs": 1, "bo3": 2}

var target := 1
var frames := PackedInt32Array([0, 0])
var frame_no := 1
## Per player: shots taken, shots that potted a ball without a foul, balls potted (not the cue).
var shots := PackedInt32Array([0, 0])
var pot_shots := PackedInt32Array([0, 0])
var balls := PackedInt32Array([0, 0])
var run := PackedInt32Array([0, 0])
var best_run := PackedInt32Array([0, 0])


func _init(mode := "vs") -> void:
	target = int(TARGET.get(mode, 1))


func breaker() -> int:
	return (frame_no - 1) % 2


func record_shot(who: int, potted: int, foul: bool) -> void:
	shots[who] += 1
	balls[who] += potted
	if potted > 0 and not foul:
		pot_shots[who] += 1
		run[who] += 1
		best_run[who] = maxi(best_run[who], run[who])
	else:
		run[who] = 0


## A frame ended; returns true when that decided the match.
func record_frame(winner: int) -> bool:
	frames[winner] += 1
	run[0] = 0
	run[1] = 0
	if over():
		return true
	frame_no += 1
	return false


func over() -> bool:
	return frames[0] >= target or frames[1] >= target


func winner() -> int:
	if not over():
		return -1
	return 0 if frames[0] >= target else 1


func pot_rate(who: int) -> float:
	return float(pot_shots[who]) / maxf(1.0, float(shots[who]))
