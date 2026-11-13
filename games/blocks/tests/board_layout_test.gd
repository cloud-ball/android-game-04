extends GdUnitTestSuite
## BoardLayout: cell size, well placement and HUD rectangles across phone shapes.

## [canvas height, top inset, bottom inset, units per dp]
const PHONES := {
	"20:9 Vivo (420 dp)": [2400.0, 100.0, 84.0, 1080.0 / 420.0],
	"19.5:9 (411 dp)": [2340.0, 90.0, 84.0, 1080.0 / 411.0],
	"21:9 tall": [2520.0, 110.0, 84.0, 1080.0 / 411.0],
	"16:9 legacy (360 dp)": [1920.0, 0.0, 0.0, 1080.0 / 360.0],
}


func _layout(spec: Array) -> BoardLayout:
	return BoardLayout.compute(
		Vector2(1080.0, spec[0]), {"top": spec[1], "bottom": spec[2]}, spec[3]
	)


func test_vivo_gets_the_researched_cell_size() -> void:
	var l := _layout(PHONES["20:9 Vivo (420 dp)"])
	assert_float(l.cell).is_between(70.0, 80.0)
	var dp := l.cell / (1080.0 / 420.0)
	assert_float(dp).is_between(27.0, 31.0)
	# Well about 84% of the width and about three quarters of the height.
	assert_float(l.well.size.x / 1080.0).is_between(0.8, 0.88)
	assert_float(l.well.size.y / 2400.0).is_between(0.7, 0.8)


func test_well_is_centred_and_hold_sits_in_the_top_band() -> void:
	var l := _layout(PHONES["20:9 Vivo (420 dp)"])
	assert_float(l.well.get_center().y / 2400.0).is_between(0.45, 0.56)
	assert_float(l.hold.end.y).is_less(l.well.position.y)
	assert_float(l.hold.position.y).is_equal_approx(l.next.position.y, 0.01)
	assert_float(l.well.get_center().x).is_equal_approx(540.0, 0.5)


func test_hud_blocks_never_overlap_on_any_phone() -> void:
	for name in PHONES:
		var l := _layout(PHONES[name])
		var rects := l.blocks()
		var keys := rects.keys()
		for i in keys.size():
			var a: Rect2 = rects[keys[i]]
			(
				assert_bool(Rect2(Vector2.ZERO, l.canvas).encloses(a))
				. override_failure_message("%s: %s leaves the canvas" % [name, keys[i]])
				. is_true()
			)
			for j in range(i + 1, keys.size()):
				var b: Rect2 = rects[keys[j]]
				(
					assert_bool(a.intersects(b))
					. override_failure_message("%s: %s overlaps %s" % [name, keys[i], keys[j]])
					. is_false()
				)


func test_everything_stays_above_the_gesture_area() -> void:
	for name in PHONES:
		var l := _layout(PHONES[name])
		for key in l.blocks():
			var r: Rect2 = l.blocks()[key]
			(
				assert_bool(r.end.y <= l.bottom + 0.01)
				. override_failure_message("%s: %s runs into the bottom keep-out" % [name, key])
				. is_true()
			)


func test_pedestal_fits_inside_the_side_margins() -> void:
	for name in PHONES:
		var l := _layout(PHONES[name])
		assert_bool(l.pedestal.position.x >= BoardLayout.SIDE).is_true()
		assert_bool(l.pedestal.end.x <= l.canvas.x - BoardLayout.SIDE).is_true()


func test_solo_layout_drops_the_cpu_column() -> void:
	var spec: Array = PHONES["20:9 Vivo (420 dp)"]
	var vs := _layout(spec)
	var solo := BoardLayout.compute(
		Vector2(1080.0, spec[0]), {"top": spec[1], "bottom": spec[2]}, spec[3], false
	)
	assert_float(solo.status.position.x).is_equal_approx(BoardLayout.SIDE, 0.01)
	assert_float(solo.hold.position.x).is_equal_approx(BoardLayout.SIDE, 0.01)
	assert_float(solo.status.size.x).is_greater(vs.status.size.x)
	assert_float(solo.cpu.size.x).is_equal(0.0)
	assert_that(solo.well).is_equal(vs.well)


func test_tap_targets_meet_48dp_on_the_narrowest_phone() -> void:
	var l := _layout(PHONES["16:9 legacy (360 dp)"])
	var units_per_dp := 1080.0 / 360.0
	for r in [l.hold, l.pause]:
		assert_float(minf(r.size.x, r.size.y) / units_per_dp).is_greater_equal(48.0)


func test_drag_step_is_physical_not_cell_based() -> void:
	var vivo := _layout(PHONES["20:9 Vivo (420 dp)"])
	assert_float(vivo.drag_step).is_equal_approx(36.0 * 1080.0 / 420.0, 0.01)


func test_gestures_rejected_on_buttons_margins_and_bottom() -> void:
	var l := _layout(PHONES["20:9 Vivo (420 dp)"])
	assert_bool(l.rejects_gesture_at(l.hold.get_center())).is_true()
	assert_bool(l.rejects_gesture_at(l.pause.get_center())).is_true()
	assert_bool(l.rejects_gesture_at(Vector2(20, 1200))).is_true()
	assert_bool(l.rejects_gesture_at(Vector2(540, 2390))).is_true()
	assert_bool(l.rejects_gesture_at(l.well.get_center())).is_false()
