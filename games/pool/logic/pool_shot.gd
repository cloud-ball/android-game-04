class_name PoolShot
extends RefCounted
## What happened in one shot, as the rules need it (built from CueSim's event log, or by hand in
## tests). Cushion entries in the log are contact *beginnings* (impulses), so a ball resting
## frozen against a rail never counts as a new rail contact (WPA 2.7).

## First object ball the cue ball touched (-1 = none).
var first_contact := -1
## Some ball began a cushion contact at or after the first contact.
var rail_after_contact := false
## [ball, pocket] pairs in order (cue ball included).
var pocketed: Array = []
## Balls that left the table (not reachable in the 2.5D solver, kept for completeness).
var off_table := PackedInt32Array()
## Distinct object balls that touched a cushion (strict break rule only).
var break_rail_balls := 0


static func from_sim(sim: CueSim) -> PoolShot:
	var s := PoolShot.new()
	var log := sim.log
	var rails := {}
	var i := 0
	while i < log.size():
		var kind := log[i]
		var a := log[i + 1]
		var b := log[i + 2]
		match kind:
			CueSim.Ev.BALL_HIT:
				if s.first_contact == -1 and (a == 0 or b == 0):
					s.first_contact = b if a == 0 else a
			CueSim.Ev.CUSHION:
				if b == 0:  # 1 = a frozen ball pressed into its cushion: not a new contact
					if s.first_contact != -1:
						s.rail_after_contact = true
					if a != 0:
						rails[a] = true
			CueSim.Ev.POCKET:
				s.pocketed.append([a, b])
		i += 3
	s.break_rail_balls = rails.size()
	return s


func potted(ball: int) -> bool:
	for p in pocketed:
		if p[0] == ball:
			return true
	return false


func pocket_of(ball: int) -> int:
	for p in pocketed:
		if p[0] == ball:
			return p[1]
	return -1
