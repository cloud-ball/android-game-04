extends GdUnitTestSuite
## Shared UI widgets: the toggle switch, icons and buttons that must stay tappable.


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


## Regression (Cup Dash, 2026-11-20): the golf pause button was 0 x 0 and could not be tapped.
func test_pause_button_has_a_touch_area() -> void:
	var b: Button = auto_free(UiKit.pause_button())
	assert_float(b.size.x).is_equal(UiKit.PAUSE_HIT)
	assert_float(b.size.y).is_equal(UiKit.PAUSE_HIT)


func test_every_cup_dash_hud_button_can_be_tapped() -> void:
	var shell: GolfShell = auto_free(GolfShell.new())
	add_child(shell)
	shell.setup(["meadow"])
	var buttons := shell.hud.find_children("*", "Button", true, false)
	assert_int(buttons.size()).is_greater_equal(2)  # pause and MAP
	for b: Button in buttons:
		assert_float(b.size.x).override_failure_message(b.name).is_greater_equal(80.0)
		assert_float(b.size.y).override_failure_message(b.name).is_greater_equal(80.0)
