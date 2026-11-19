class_name GolfWorlds
extends RefCounted
## The course catalogue (pure data): worlds in play order, each with its holes (tile-map specs in
## games/golf/data/mini/) and its look (GolfTheme). Everything that lists holes reads it here.
## Plan: docs/plans/2026-11-19-cup-dash-complete.md (steps F, H).

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
	{
		"id": "coastal",
		"name": "Coast",
		"holes":
		[
			"coastal_01",
			"coastal_02",
			"coastal_03",
			"coastal_04",
			"coastal_05",
			"coastal_06",
			"coastal_07",
			"coastal_08",
			"coastal_09",
		],
	},
	{
		"id": "canyon",
		"name": "Canyon",
		"holes":
		[
			"canyon_01",
			"canyon_02",
			"canyon_03",
			"canyon_04",
			"canyon_05",
			"canyon_06",
			"canyon_07",
			"canyon_08",
			"canyon_09",
		],
	},
	{
		"id": "volcanic",
		"name": "Volcano",
		"holes":
		[
			"volcanic_01",
			"volcanic_02",
			"volcanic_03",
			"volcanic_04",
			"volcanic_05",
			"volcanic_06",
			"volcanic_07",
			"volcanic_08",
			"volcanic_09",
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
