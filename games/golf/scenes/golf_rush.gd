class_name GolfRush
extends Node
## Rush glue for the hole screen (GolfGame): owns the rules (RushMatch), the CPU golfers
## (RushField) and the overlay (RushHud), and drives hole and match changes. GolfGame only reports
## its own ball (shot taken, how it ended, the substep it dropped in) and asks can_shoot().
## Plan: docs/plans/2026-11-19-fairway-flick-complete.md (step E3).

enum Phase { PLAYING, HOLE_CARD, MATCH_CARD }

const HOLE_CARD_TIME := 2.8

var rush: RushMatch
var field: RushField
var hud: RushHud

var _game: Node  # GolfGame
var _save: Dictionary
var _holes := 1
var _tier := 1
var _phase := Phase.PLAYING
var _t := 0.0


func setup(
	game: Node, layer: CanvasLayer, top: float, tier: int, hole_count: int, save: Dictionary
) -> void:
	_game = game
	_save = save
	_tier = tier
	_holes = hole_count
	field = RushField.new()
	add_child(field)
	hud = RushHud.new()
	layer.add_child(hud)
	var names := PackedStringArray(["You"])
	names.append_array(PackedStringArray(RushField.NAMES))
	var colors: Array = [Color.WHITE]
	colors.append_array(RushField.COLORS)
	hud.build(top, names, colors)
	hud.again.connect(new_match)
	_new_rules(names)


## World hole index to load first.
func first_hole() -> int:
	return rush.holes[0]


## Starts a fresh match (Play again): new holes, rivals back on the first tee.
func new_match() -> void:
	_new_rules(rush.names)
	hud.hide_card()
	_game.load_hole(rush.holes[0])


func begin_hole(hole: HoleData, spec: Dictionary, preset: CoursePreset, world: Node3D) -> void:
	rush.start_hole(hole.par)
	field.begin_hole(hole, spec, preset, world)
	hud.hide_card()
	_phase = Phase.PLAYING


## Rivals may start (the player's first aim after the intro).
func go() -> void:
	if _phase == Phase.PLAYING:
		field.go()


func can_shoot() -> bool:
	return _phase == Phase.PLAYING and rush.can_shoot(0)


## Returns the player's stroke count after the shot.
func shot_taken() -> int:
	rush.shot_taken(0)
	return rush.strokes[0]


## The player's ball stopped (any way but holing, which arrives through tick's `drop`). Returns a
## banner line for the player, or "".
func shot_over(phase: int) -> String:
	var line := ""
	match phase:
		GolfBall.Phase.WATER:
			rush.add_penalty(0)
			line = "Splash!\n+1 stroke"
		GolfBall.Phase.OUT:
			rush.add_penalty(0)
			line = "Out!\n+1 stroke · try again"
	if phase != GolfBall.Phase.HOLED:
		rush.ball_rested(0)
	if rush.state[0] == RushMatch.State.OUT:
		line = "Out of strokes\nthe others play on"
	return line


func strokes() -> int:
	return rush.strokes[0]


## One display tick: rivals advance `steps` substeps in lockstep with the player; `drop` is the
## substep the player's ball fell in this tick (or -1).
func tick(delta: float, steps: int, drop: int) -> void:
	match _phase:
		Phase.PLAYING:
			if field.step(steps, delta, drop) == 0:
				AudioService.play("win")
			hud.update(rush, field.thinking)
			if rush.hole_over():
				_phase = Phase.HOLE_CARD
				_t = 0.0
				field.stop()
				hud.show_hole(rush)
		Phase.HOLE_CARD:
			_t += delta
			if _t > HOLE_CARD_TIME:
				if rush.next_hole():
					_game.load_hole(rush.holes[rush.hole_number])
				else:
					_phase = Phase.MATCH_CARD
					_record()
					hud.show_match(rush)


func hud_line() -> String:
	return "RUSH · HOLE %d/%d" % [rush.hole_number + 1, rush.holes.size()]


func _new_rules(names: PackedStringArray) -> void:
	var seed_value := Rng.next_seed()
	var rng := Rng.make(seed_value)
	rush = RushMatch.new(names, RushMatch.pick_holes(_holes, RushMatch.HOLES, rng))
	field.setup(rush, _tier, seed_value)
	_phase = Phase.PLAYING


func _record() -> void:
	_save["played"] = int(_save.get("played", 0)) + 1
	if rush.winner() == 0:
		_save["wins"] = int(_save.get("wins", 0)) + 1
	else:
		_save["losses"] = int(_save.get("losses", 0)) + 1
	SaveService.save()
