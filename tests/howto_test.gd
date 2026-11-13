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
