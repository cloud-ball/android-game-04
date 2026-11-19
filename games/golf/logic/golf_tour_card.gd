class_name GolfTourCard
extends RefCounted
## A Tour scorecard (pure): one entry per hole played alone, with stars (GolfProgress.stars) and
## the totals the end screen, the save and the daily challenges need.

var entries: Array[Dictionary] = []


## Records a finished hole; returns its stars.
func add(hole_id: String, par: int, strokes: int, holed: bool) -> int:
	var s := GolfProgress.stars(strokes, par, holed)
	entries.append({"id": hole_id, "par": par, "strokes": strokes, "holed": holed, "stars": s})
	return s


func holes_played() -> int:
	return entries.size()


func strokes() -> int:
	var n := 0
	for e in entries:
		n += int(e.strokes)
	return n


func over_par() -> int:
	var n := 0
	for e in entries:
		n += int(e.strokes) - int(e.par)
	return n


func stars() -> int:
	var n := 0
	for e in entries:
		n += int(e.stars)
	return n


func birdies() -> int:
	var n := 0
	for e in entries:
		if e.holed and int(e.strokes) == int(e.par) - 1:
			n += 1
	return n


func aces() -> int:
	var n := 0
	for e in entries:
		if e.holed and int(e.strokes) == 1:
			n += 1
	return n
