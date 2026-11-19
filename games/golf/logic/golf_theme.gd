class_name GolfTheme
extends RefCounted
## A world's look as pure data (like CoursePreset): every colour the course uses, ordered on a
## value ladder - surroundings darkest, carpet mid, rails lighter, ball / cup rim / aim guide
## brightest - plus which landmark, trees and props dress it. Research: docs/research/Fairway Flick
## mini golf visuals.md ("A strict value ladder", world table). Colour meanings stay fixed across
## worlds: red-orange = danger (bumpers, lava), amber = boost, tan = sand. One constructor per
## world (meadow, coastal, canyon, volcanic); for_world() picks one.

var name := "meadow"
var lawn := Color(0.28, 0.46, 0.2)
var carpet := Color(0.14, 0.58, 0.26)
var sand := Color(0.93, 0.84, 0.62)
var water := Color(0.1, 0.38, 0.6)
var lava := false  # water tiles are lava here (same rules: +1 stroke and a drop)
var rail_body := Color(0.86, 0.66, 0.42)  # lighter than the carpet
var rail_cap := Color(0.98, 0.95, 0.88)
var bumper := Color(0.92, 0.3, 0.2)  # red-orange: a hazard that bounces you
var flag := Color(1.0, 0.82, 0.18)
var cup_rim := Color(1.0, 1.0, 1.0)
var ball := Color(1.0, 1.0, 1.0)
var ball_outline := Color(0.05, 0.08, 0.1)
var bush := Color(0.17, 0.4, 0.2)
var stone := Color(0.64, 0.55, 0.44)  # warm: blue sky light in shade turns grey blue
## Kit materials (trees, wood).
var leaf := Color(0.27, 0.5, 0.2)
var leaf_dark := Color(0.14, 0.37, 0.21)
var bark := Color(0.42, 0.29, 0.18)
var bark_dark := Color(0.32, 0.22, 0.14)
var wood := Color(0.6, 0.46, 0.32)  # fences and planters: darker than the rails
var wood_dark := Color(0.42, 0.3, 0.2)
## Landmark (backdrop: lower contrast than the playfield, framed in the top third).
var landmark := "windmill"  # windmill | lighthouse | arch | volcano
var landmark_wall := Color(0.92, 0.87, 0.77)
var landmark_roof := Color(0.62, 0.27, 0.22)
var landmark_wood := Color(0.38, 0.25, 0.16)
var sail := Color(0.95, 0.92, 0.84)
var glow := Color(1.0, 0.85, 0.45)  # lighthouse lamp / lava
## Saturated, never white or near-white (white is the ball's).
var flowers := [
	Color(1.0, 0.4, 0.55), Color(1.0, 0.78, 0.2), Color(0.66, 0.42, 0.96), Color(1.0, 0.55, 0.25)
]
## Dressing (Kenney Nature Kit models, recoloured): trees [model, min m, max m], Ring 1 props, and
## the small scenes beside play (logs, mushrooms, planters, rocks, canoe, cactus, columns, fire).
var trees := [
	["tree_oak", 6.0, 8.0],
	["tree_default", 7.0, 9.5],
	["tree_pineRoundC", 6.5, 9.0],
	["tree_pineTallA", 8.0, 11.0],
]
var bushes := ["plant_bush", "plant_bushLarge"]
var flower_models := ["flower_redA", "flower_yellowB", "flower_purpleA"]
var vignettes := ["logs", "mushrooms", "planters", "rocks"]
var hills := Color(0.27, 0.42, 0.3)  # the far ring (fog fades it further)
var skyline_trees := true  # a tree line on the mid hills (off: bare mesas / ash hills)
var sun_pitch := -48.0
var sun_yaw := -35.0
var sun_color := Color(1.0, 0.97, 0.9)
var sun_energy := 1.05
var sky_top := Color(0.3, 0.55, 0.88)
var sky_horizon := Color(0.78, 0.88, 0.96)
var ground_bottom := Color(0.2, 0.32, 0.18)
var ground_horizon := Color(0.62, 0.74, 0.7)
var fog_color := Color(0.7, 0.82, 0.92)

var _kit := {}  # kit material name -> colour (built on first use)


## Colours for the CC0 Kenney Nature Kit props (games/golf/assets/kenney_nature), by the kit's
## material names: every prop is recoloured onto this world's palette, so stock kit colours never
## ship (research: "Recolour everything onto Fairway Flick's own palette"). Props stay mid-value:
## darker than the rails and well below the ball. Unknown names return magenta (tested).
func kit_color(material: String) -> Color:
	if _kit.is_empty():
		_kit = {
			"leafsGreen": leaf,
			"leafsDark": leaf_dark,
			"woodBark": bark,
			"woodBarkDark": bark_dark,
			"woodInner": Color(0.8, 0.66, 0.46),
			"wood": wood,
			"woodDark": wood_dark,
			"grass": bush,
			"dirt": stone,
			"stone": stone,
			"stoneDark": stone.darkened(0.3),
			"leafsFall": Color(0.72, 0.36, 0.26),  # the canoe's painted inside
			"colorRed": flowers[0],
			"colorYellow": flowers[1],
			"colorPurple": flowers[2],
			"colorTan": Color(0.86, 0.74, 0.56),
			"_defaultMat": Color(0.8, 0.76, 0.68),  # mushroom stems, caps' undersides, sails
		}
	return _kit.get(material, Color.MAGENTA)


static func for_world(id: String) -> GolfTheme:
	match id:
		"coastal":
			return coastal()
		"canyon":
			return canyon()
		"volcanic":
			return volcanic()
	return meadow()


static func meadow() -> GolfTheme:
	return GolfTheme.new()


## Teal carpet on dune grass, driftwood rails, a low golden sun and long shadows, peach-to-
## lavender sky; a striped lighthouse on a rock; palms.
static func coastal() -> GolfTheme:
	var t := GolfTheme.new()
	t.name = "coastal"
	t.lawn = Color(0.34, 0.47, 0.3)
	t.carpet = Color(0.1, 0.56, 0.56)
	t.sand = Color(0.96, 0.88, 0.68)
	t.water = Color(0.08, 0.42, 0.62)
	t.rail_body = Color(0.8, 0.7, 0.56)  # driftwood
	t.rail_cap = Color(0.97, 0.94, 0.87)
	t.bush = Color(0.25, 0.42, 0.26)
	t.stone = Color(0.62, 0.58, 0.52)
	t.leaf = Color(0.3, 0.55, 0.24)
	t.leaf_dark = Color(0.18, 0.42, 0.24)
	t.bark = Color(0.55, 0.42, 0.3)
	t.wood = Color(0.62, 0.52, 0.4)
	t.landmark = "lighthouse"
	t.landmark_wall = Color(0.95, 0.93, 0.88)
	t.landmark_roof = Color(0.78, 0.22, 0.2)  # the stripes and the cap
	t.landmark_wood = Color(0.3, 0.32, 0.36)  # gallery rail, door
	t.glow = Color(1.0, 0.86, 0.5)
	t.flowers = [Color(1.0, 0.45, 0.6), Color(1.0, 0.8, 0.3), Color(0.6, 0.48, 0.98)]
	t.trees = [
		["tree_palmTall", 7.0, 10.0], ["tree_palmBend", 6.0, 8.5], ["tree_palmShort", 4.5, 6.5]
	]
	t.vignettes = ["canoe", "rocks", "planters", "logs"]
	t.sun_pitch = -24.0
	t.sun_yaw = 55.0
	t.sun_color = Color(1.0, 0.86, 0.68)
	t.sun_energy = 1.15
	t.sky_top = Color(0.42, 0.5, 0.84)
	t.sky_horizon = Color(1.0, 0.82, 0.66)
	t.ground_bottom = Color(0.18, 0.3, 0.34)
	t.ground_horizon = Color(0.86, 0.78, 0.7)
	t.fog_color = Color(0.92, 0.82, 0.76)
	t.hills = Color(0.36, 0.46, 0.4)
	return t


## Terracotta carpet on red earth, chunky sandstone rails, hard warm light, pale hazy sky; a natural
## rock arch; cacti and tall rocks; bare mesas on the horizon.
static func canyon() -> GolfTheme:
	var t := GolfTheme.new()
	t.name = "canyon"
	t.lawn = Color(0.46, 0.28, 0.19)
	t.carpet = Color(0.78, 0.42, 0.24)
	t.sand = Color(0.97, 0.89, 0.72)
	t.water = Color(0.16, 0.46, 0.58)
	t.rail_body = Color(0.9, 0.75, 0.55)  # sandstone
	t.rail_cap = Color(0.98, 0.92, 0.8)
	t.bush = Color(0.36, 0.48, 0.26)  # cactus green
	t.stone = Color(0.66, 0.42, 0.3)
	t.leaf = Color(0.38, 0.52, 0.28)
	t.leaf_dark = Color(0.28, 0.42, 0.24)
	t.bark = Color(0.5, 0.36, 0.26)
	t.wood = Color(0.62, 0.48, 0.34)
	t.landmark = "arch"
	t.landmark_wall = Color(0.78, 0.46, 0.3)
	t.landmark_roof = Color(0.86, 0.6, 0.42)
	t.flowers = [Color(1.0, 0.5, 0.35), Color(1.0, 0.82, 0.3), Color(0.9, 0.45, 0.75)]
	t.trees = [
		["cactus_tall", 3.5, 5.5],
		["cactus_short", 2.0, 3.2],
		["rock_tallA", 4.0, 7.0],
		["rock_tallC", 3.0, 6.0]
	]
	t.bushes = ["cactus_short"]
	t.vignettes = ["rocks", "columns", "cactus", "logs"]
	t.skyline_trees = false
	t.sun_pitch = -58.0
	t.sun_yaw = -20.0
	t.sun_color = Color(1.0, 0.92, 0.8)
	t.sun_energy = 1.2
	t.sky_top = Color(0.5, 0.66, 0.86)
	t.sky_horizon = Color(0.96, 0.88, 0.78)
	t.ground_bottom = Color(0.36, 0.22, 0.15)
	t.ground_horizon = Color(0.88, 0.72, 0.6)
	t.fog_color = Color(0.94, 0.84, 0.74)
	t.hills = Color(0.62, 0.38, 0.27)
	return t


## Violet carpet on black basalt, dark stone rails, a dusky orange sky; a smoking volcano with a
## glowing crater; the water tiles are glowing lava; dark pines and rocks.
static func volcanic() -> GolfTheme:
	var t := GolfTheme.new()
	t.name = "volcanic"
	t.lawn = Color(0.16, 0.14, 0.15)
	t.carpet = Color(0.4, 0.24, 0.6)
	t.sand = Color(0.55, 0.5, 0.48)  # ash
	t.water = Color(1.0, 0.42, 0.08)
	t.lava = true
	t.rail_body = Color(0.52, 0.46, 0.5)  # basalt, still lighter than the carpet
	t.rail_cap = Color(0.82, 0.76, 0.78)
	t.bush = Color(0.22, 0.28, 0.2)
	t.stone = Color(0.3, 0.27, 0.28)
	t.leaf = Color(0.24, 0.3, 0.22)
	t.leaf_dark = Color(0.16, 0.22, 0.18)
	t.bark = Color(0.22, 0.18, 0.16)
	t.bark_dark = Color(0.16, 0.13, 0.12)
	t.wood = Color(0.36, 0.3, 0.28)
	t.wood_dark = Color(0.24, 0.2, 0.18)
	t.landmark = "volcano"
	t.landmark_wall = Color(0.26, 0.22, 0.24)
	t.landmark_roof = Color(0.38, 0.3, 0.3)
	t.glow = Color(1.0, 0.45, 0.1)
	t.flowers = [Color(1.0, 0.45, 0.25), Color(1.0, 0.75, 0.25), Color(0.85, 0.4, 0.95)]
	t.trees = [
		["tree_pineTallA", 6.0, 9.0], ["tree_pineRoundC", 5.0, 7.0], ["rock_tallA", 4.0, 7.0]
	]
	t.bushes = ["plant_bush"]
	t.vignettes = ["rocks", "campfire", "mushrooms", "rocks"]
	t.skyline_trees = false
	t.sun_pitch = -30.0
	t.sun_yaw = 25.0
	t.sun_color = Color(1.0, 0.72, 0.5)
	t.sun_energy = 0.95
	t.sky_top = Color(0.26, 0.17, 0.3)
	t.sky_horizon = Color(0.96, 0.52, 0.3)
	t.ground_bottom = Color(0.1, 0.08, 0.09)
	t.ground_horizon = Color(0.6, 0.34, 0.26)
	t.fog_color = Color(0.62, 0.38, 0.32)
	t.hills = Color(0.2, 0.16, 0.18)
	return t


## Relative luminance (Rec. 709) of an sRGB colour, for the value-ladder test.
static func luminance(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b
