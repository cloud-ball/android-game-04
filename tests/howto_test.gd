extends GdUnitTestSuite
## How-to cards: the fingertip timeline and the deck (loops, pause, mode filter, signals).


func _deck(cards: Array, motion_off := false) -> HowtoDeck:
	var deck: HowtoDeck = auto_free(HowtoDeck.new(Color.WHITE))
	add_child(deck)
	deck.open(cards, motion_off)
	return deck


func _card(kind := "tap", modes: Array = []) -> Dictionary:
	var card := {
		"title": "T",
		"sub": "S",
		"demo": func(_c: Control, _t: float, _g: GestureTimeline) -> void: pass,
		"poster": func(_c: Control) -> void: pass,
		"gesture": GestureTimeline.new(kind, Vector2(100, 100), Vector2(100, 400), 3, 700),
	}
	if not modes.is_empty():
		card["modes"] = modes
	return card


# --- GestureTimeline ---------------------------------------------------------------------------


func test_timeline_phases_add_up() -> void:
	var g := GestureTimeline.new("swipe", Vector2.ZERO, Vector2(0, 300), 1, 700)
	assert_float(g.press_ms).is_equal(370.0)
	assert_float(g.lift_ms).is_equal(570.0)
	assert_float(g.loop_ms).is_equal(570.0 + 700.0 + 200.0 + 800.0)
	var flick := GestureTimeline.new("flick", Vector2.ZERO, Vector2(0, 300))
	assert_float(flick.action_ms()).is_equal(120.0)
	var drag := GestureTimeline.new("drag", Vector2.ZERO, Vector2(300, 0), 3)
	assert_float(drag.action_ms()).is_equal(480.0)


func test_swipe_glyph_travels_and_leaves_a_trail() -> void:
	var g := GestureTimeline.new("swipe", Vector2(0, 300), Vector2(0, 0), 1, 700)
	g.evaluate(0.0)
	assert_float(g.alpha).is_equal(0.0)
	g.evaluate(g.press_ms + 100.0)
	assert_bool(g.down).is_true()
	assert_float(g.pos.y).is_between(0.0, 299.0)
	assert_float(g.trail_alpha).is_equal(1.0)
	g.evaluate(g.lift_ms + 10.0)
	assert_bool(g.down).is_false()
	assert_float(g.pos.y).is_equal_approx(0.0, 0.01)
	g.evaluate(g.loop_ms - 10.0)
	assert_bool(g.visible).is_false()


func test_tap_ripple_follows_android_timing() -> void:
	var g := GestureTimeline.new("tap", Vector2(50, 50), Vector2(50, 50))
	g.evaluate(g.press_ms + 75.0)
	assert_float(g.ripple_alpha).is_equal_approx(1.0, 0.01)
	g.evaluate(g.press_ms + 225.0)
	assert_float(g.ripple).is_equal_approx(1.0, 0.01)
	g.evaluate(g.press_ms + 380.0)
	assert_float(g.ripple).is_equal(-1.0)


func test_drag_steps_one_column_at_a_time() -> void:
	var g := GestureTimeline.new("drag", Vector2(0, 0), Vector2(300, 0), 3, 700)
	assert_int(g.steps_done(g.press_ms)).is_equal(0)
	assert_int(g.steps_done(g.step_done_ms(1))).is_equal(1)
	assert_int(g.steps_done(g.step_done_ms(2) - 1.0)).is_equal(1)
	assert_int(g.steps_done(g.lift_ms)).is_equal(3)
	# During a dwell the finger rests exactly on a column.
	g.evaluate(g.step_done_ms(1) + 50.0)
	assert_float(g.pos.x).is_equal_approx(100.0, 0.01)


func test_rule_cards_have_no_glyph() -> void:
	var g := GestureTimeline.new("none", Vector2.ZERO, Vector2.ZERO, 1, 1000)
	for t in [0.0, 400.0, 900.0]:
		g.evaluate(t)
		assert_bool(g.visible).is_false()


# --- HowtoDeck ---------------------------------------------------------------------------------


func test_demo_stops_after_three_loops_and_replays() -> void:
	var deck := _deck([_card()])
	var g := deck.gesture()
	deck.advance(g.loop_ms * 2.5)
	assert_bool(deck.finished).is_false()
	deck.advance(g.loop_ms)
	assert_bool(deck.finished).is_true()
	assert_float(deck.t).is_equal(deck.result_ms())
	deck.toggle_pause()  # on a finished demo this is Replay
	assert_bool(deck.finished).is_false()
	assert_float(deck.t).is_equal(0.0)


func test_tap_pauses_and_resumes() -> void:
	var deck := _deck([_card()])
	deck.advance(100.0)
	deck.toggle_pause()
	deck.advance(500.0)
	assert_float(deck.t).is_equal(100.0)
	deck.toggle_pause()
	deck.advance(50.0)
	assert_float(deck.t).is_equal(150.0)


func test_next_then_play_on_the_last_card() -> void:
	var deck := _deck([_card(), _card("swipe")])
	var got: Array = []
	deck.closed.connect(func(play: bool) -> void: got.append(play))
	assert_str(deck._next.text).is_equal("Next")
	deck._next.pressed.emit()
	assert_int(deck.index).is_equal(1)
	assert_str(deck._next.text).is_equal("PLAY")
	deck._next.pressed.emit()
	assert_array(got).is_equal([true])
	assert_bool(deck.is_open()).is_false()


func test_skip_closes_without_playing() -> void:
	var deck := _deck([_card(), _card()])
	var got: Array = []
	deck.closed.connect(func(play: bool) -> void: got.append(play))
	deck.close(false)
	assert_array(got).is_equal([false])


func test_reduce_motion_holds_still() -> void:
	var deck := _deck([_card()], true)
	deck.advance(5000.0)
	assert_float(deck.t).is_equal(0.0)


func test_cpu_only_cards_are_hidden_in_solo() -> void:
	var shell: GameShell = auto_free(GameShell.new())
	shell.configure({"howto": [_card(), _card("tap", ["vs"]), _card()]})
	shell.mode = "vs"
	assert_int(shell.howto_cards().size()).is_equal(3)
	shell.mode = "solo"
	assert_int(shell.howto_cards().size()).is_equal(2)


func test_game_cards_are_short_and_well_formed() -> void:
	var posters := {}
	for k in ["swipe", "wall", "crash", "tap", "drag", "drop", "hold", "garbage"]:
		posters[k] = func(_c: Control) -> void: pass
	var all: Array = SnakeHowto.cards(posters) + BlocksHowto.cards(posters)
	assert_int(all.size()).is_equal(8)
	for card in all:
		assert_int(String(card.title).split(" ").size()).is_less_equal(4)
		assert_int(String(card.sub).split(" ").size()).is_less_equal(9)
		var g: GestureTimeline = card.gesture
		assert_float(g.loop_ms).is_between(2400.0, 3800.0)


# --- Try it ------------------------------------------------------------------------------------


func test_try_gesture_classifies_like_the_games() -> void:
	assert_str(TryGesture.classify(Vector2(5, 4), 120, 1)).is_equal("tap")
	assert_str(TryGesture.classify(Vector2(0, 300), 150, 1)).is_equal("flick")
	assert_str(TryGesture.classify(Vector2(0, 300), 900, 1)).is_equal("swipe")  # slow: not a flick
	assert_str(TryGesture.classify(Vector2(200, 30), 500, 1)).is_equal("drag")
	assert_str(TryGesture.classify(Vector2(0, -120), 200, 1)).is_equal("swipe")
	assert_str(TryGesture.classify(Vector2(2, 2), 80, 2)).is_equal("two_finger")
	assert_bool(TryGesture.satisfies("swipe", "drag")).is_true()
	assert_bool(TryGesture.satisfies("flick", "swipe")).is_false()
	assert_bool(TryGesture.satisfies("hold", "two_finger")).is_true()


func test_doing_the_gesture_ticks_the_card_and_replays_without_the_glyph() -> void:
	var deck := _deck([_card("flick"), _card()])
	var g := deck.gesture()
	deck.advance(g.loop_ms + 10.0)
	assert_bool(deck.try_open()).is_true()
	assert_bool(deck.try_gesture(Vector2(0, 40), 100.0, 1, Vector2.ZERO)).is_false()  # too short
	assert_bool(deck.try_gesture(Vector2(0, 300), 150.0, 1, Vector2.ZERO)).is_true()
	assert_bool(deck.tried.has(0)).is_true()
	assert_bool(deck.user_turn).is_true()
	assert_float(deck.t).is_equal(g.press_ms)


func test_hold_card_wants_the_hold_chip_or_two_fingers() -> void:
	var card := _card("tap")
	card["try"] = "hold"
	card["try_rect"] = Rect2(640, 56, 240, 240)
	var deck := _deck([card])
	var k := deck._side / HowtoDeck.DESIGN
	assert_bool(deck.try_gesture(Vector2.ZERO, 100.0, 1, Vector2(100, 600) * k)).is_false()
	assert_bool(deck.try_gesture(Vector2.ZERO, 100.0, 1, Vector2(760, 170) * k)).is_true()
	deck.tried.clear()
	assert_bool(deck.try_gesture(Vector2.ZERO, 100.0, 2, Vector2(100, 600) * k)).is_true()


func test_rule_cards_have_nothing_to_try() -> void:
	var deck := _deck([_card("none")])
	assert_str(deck.try_kind()).is_equal("")
	assert_bool(deck.try_gesture(Vector2(0, 300), 150.0, 1, Vector2.ZERO)).is_false()


func test_from_the_pause_menu_the_last_button_just_closes() -> void:
	var deck: HowtoDeck = auto_free(HowtoDeck.new(Color.WHITE))
	add_child(deck)
	deck.open([_card()], false, "GOT IT")
	var got: Array = []
	deck.closed.connect(func(play: bool) -> void: got.append(play))
	assert_str(deck._next.text).is_equal("GOT IT")
	deck._next.pressed.emit()
	assert_array(got).is_equal([false])


# --- First-match practice ------------------------------------------------------------------------


func test_practice_hints_follow_progress_and_retire_when_learned() -> void:
	var saved := {}
	var plan := PracticePlan.new([["rotate", 2], ["move", 3]], saved)
	assert_str(plan.due(1)).is_equal("")
	assert_str(plan.due(2)).is_equal("rotate")
	assert_bool(plan.learn("rotate")).is_true()
	assert_bool(plan.learn("rotate")).is_false()  # only the first time asks for a save
	assert_bool(saved.get("rotate", false)).is_true()
	assert_str(plan.due(5)).is_equal("move")
	assert_str(plan.due(6)).is_equal("move")  # second showing this match
	assert_str(plan.due(7)).is_equal("")  # at most twice per match
	plan.new_match()
	assert_str(plan.due(7)).is_equal("move")


func test_saved_moves_are_never_hinted_unless_forced() -> void:
	var plan := PracticePlan.new([["swipe", 4.0]], {"swipe": true})
	assert_str(plan.due(10.0)).is_equal("")
	var forced := PracticePlan.new([["swipe", 4.0]], {"swipe": true}, true)
	assert_str(forced.due(10.0)).is_equal("swipe")


func test_practice_hint_shows_then_retires_after_its_loops() -> void:
	var hint: PracticeHint = auto_free(PracticeHint.new(Color.WHITE))
	add_child(hint)
	hint.show_hint("rotate", "tap", Vector2(500, 900), Vector2(500, 900), "Tap", Vector2(540, 600))
	assert_bool(hint.is_showing()).is_true()
	assert_int(hint.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)  # never blocks play
	hint.hide_hint("move")  # another verb: stays
	assert_bool(hint.is_showing()).is_true()
	for i in 200:
		hint.advance(50.0)
	assert_bool(hint.is_showing()).is_false()


func test_save_migrations_mark_experienced_players() -> void:
	var blocks_game: GDScript = load("res://games/blocks/scenes/blocks_game.gd")
	var old: Dictionary = blocks_game.migrate_save({"schema": 1, "played": 4}, 1, 2)
	assert_bool(old["learned"].get("hold", false)).is_true()
	var fresh: Dictionary = blocks_game.migrate_save({"schema": 1, "played": 0}, 1, 2)
	assert_bool(fresh.has("learned")).is_false()
	var snake_game: GDScript = load("res://games/snake/scenes/snake_game.gd")
	var s: Dictionary = snake_game.migrate_save({"schema": 2, "played": 3}, 2, 3)
	assert_bool(s["learned"].get("swipe", false)).is_true()
	assert_bool(s["learned"].get("wrap", false)).is_false()  # wrap edges still get a hint


func test_container_defaults_are_copied_not_shared() -> void:
	var defaults := {"learned": {}}
	var a := SaveService.prepare_namespace(null, 1, defaults)
	a["learned"]["x"] = true
	assert_bool(defaults["learned"].is_empty()).is_true()
