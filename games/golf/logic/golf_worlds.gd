class_name GolfWorlds
extends RefCounted
## The course catalogue (pure data): worlds in play order, each with its holes (tile-map specs in
## games/golf/data/mini/) and its look (GolfTheme). Everything that lists holes reads it here.
## Plan: docs/plans/2026-11-19-fairway-flick-complete.md (steps F, H).

const DIR := "res://games/golf/data/mini/"
const WORLDS := [
	{
		"id": "meadow",
		"name": "Meadow",
		"holes":
		[
			"meadow_01",
			"meadow_02",
			"meadow_03",
			"meadow_04",
			"meadow_05",
			"meadow_06",
			"meadow_07",
			"meadow_08",
			"meadow_09",
		],
	},
]


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for w: Dictionary in WORLDS:
		out.append(w.id)
	return out


static func world(id: String) -> Dictionary:
	for w: Dictionary in WORLDS:
		if w.id == id:
			return w
	return WORLDS[0]


## Hole spec paths of one world, in order.
static func holes(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for h in world(id).holes:
		out.append(DIR + str(h) + ".json")
	return out


## Every hole of every world (tests, tools).
static func all_holes() -> PackedStringArray:
	var out := PackedStringArray()
	for w: Dictionary in WORLDS:
		out.append_array(holes(w.id))
	return out
