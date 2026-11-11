extends GdUnitTestSuite
## Touch gestures -> actions: tap rotates, drags move per cell, flick drops, two fingers hold.


func _touch(p: Vector2, down: bool, index := 0) -> InputEventScreenTouch:
	var t := InputEventScreenTouch.new()
	t.position = p
	t.pressed = down
	t.index = index
	return t


func _drag(p: Vector2) -> InputEventScreenDrag:
	var d := InputEventScreenDrag.new()
	d.position = p
	return d


func _run(g: StackGestures, steps: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for s in steps:
		out.append_array(g.feed(s[0], s[1]))
	return out


func test_quick_tap_rotates() -> void:
	var g := StackGestures.new()
	var out := _run(
		g, [[_touch(Vector2(300, 900), true), 0], [_touch(Vector2(305, 902), false), 120]]
	)
	assert_array(Array(out)).is_equal(["cw"])


func test_long_press_is_not_a_tap() -> void:
	var g := StackGestures.new()
	var out := _run(
		g, [[_touch(Vector2(300, 900), true), 0], [_touch(Vector2(300, 900), false), 900]]
	)
	assert_bool(out.is_empty()).is_true()


func test_horizontal_drag_moves_one_column_per_cell() -> void:
	var g := StackGestures.new()
	g.cell_px = 50.0
	var out := _run(
		g,
		[
			[_touch(Vector2(100, 900), true), 0],
			[_drag(Vector2(140, 902)), 30],
			[_drag(Vector2(260, 905)), 60],
			[_drag(Vector2(170, 905)), 90],
			[_touch(Vector2(170, 905), false), 400],
		]
	)
	assert_array(Array(out)).is_equal(["right", "right", "right", "left"])


func test_fast_flick_down_hard_drops() -> void:
	var g := StackGestures.new()
	var out := _run(
		g,
		[
			[_touch(Vector2(300, 600), true), 0],
			[_drag(Vector2(302, 700)), 60],
			[_touch(Vector2(303, 800), false), 120],
		]
	)
	assert_bool(out.has("hard")).is_true()


func test_slow_drag_down_soft_drops_without_hard_drop() -> void:
	var g := StackGestures.new()
	g.cell_px = 50.0
	var out := _run(
		g,
		[
			[_touch(Vector2(300, 600), true), 0],
			[_drag(Vector2(300, 660)), 300],
			[_drag(Vector2(300, 720)), 600],
			[_touch(Vector2(300, 720), false), 900],
		]
	)
	assert_array(Array(out)).is_equal(["soft", "soft"])


func test_second_finger_holds_and_cancels_the_tap() -> void:
	var g := StackGestures.new()
	var out := _run(
		g,
		[
			[_touch(Vector2(300, 900), true, 0), 0],
			[_touch(Vector2(600, 900), true, 1), 40],
			[_touch(Vector2(600, 900), false, 1), 90],
			[_touch(Vector2(300, 900), false, 0), 110],
		]
	)
	assert_array(Array(out)).is_equal(["hold"])
