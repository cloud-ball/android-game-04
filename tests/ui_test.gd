extends GdUnitTestSuite
## Shared UI widgets: the toggle switch's state and signal behaviour.


func test_toggle_switch_emits_and_flips() -> void:
	var sw: ToggleSwitch = auto_free(ToggleSwitch.new(false))
	var seen: Array[bool] = []
	sw.toggled.connect(func(on: bool) -> void: seen.append(on))
	sw.toggle()
	sw.toggle()
	assert_array(seen).is_equal([true, false])
	assert_bool(sw.pressed).is_false()


func test_set_pressed_is_silent() -> void:
	var sw: ToggleSwitch = auto_free(ToggleSwitch.new(false))
	var count := [0]
	sw.toggled.connect(func(_on: bool) -> void: count[0] += 1)
	sw.set_pressed(true)
	assert_bool(sw.pressed).is_true()
	assert_int(count[0]).is_equal(0)


func test_icons_draw_without_errors() -> void:
	for kind in ["gear", "music", "sound", "sound_off", "vibrate", "motion", "close", "info"]:
		var icon: IconGlyph = auto_free(IconGlyph.new(kind))
		assert_str(icon.kind).is_equal(kind)
