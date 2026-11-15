class_name PresentationClock
extends RefCounted
## Slow motion that never touches the physics: the solver always runs whole fixed substeps in the
## same order; this clock only decides HOW MANY to run on each display tick. At rate 1.0 that is
## exactly SUBSTEPS_PER_TICK; slower rates bank fractions of a substep until a whole one is due.
## Research: docs/research/Fairway Flick mini golf visuals.md ("Slow motion without touching the
## solver"). Pure; unit tested (same end state at any rate schedule).

const SUBSTEPS_PER_TICK := 4

var rate := 1.0  # 1.0 = real time, 0.3 = slow motion
var _bank := 0.0


func reset() -> void:
	rate = 1.0
	_bank = 0.0


## Substeps to run on this display tick.
func take() -> int:
	_bank += SUBSTEPS_PER_TICK * rate
	var n := int(_bank)
	_bank -= n
	return n
