extends GdUnitTestSuite
## The camera fit keeps the whole board inside the HUD-free band on common phone shapes.


func test_board_fits_on_common_aspects() -> void:
	var corners: Array[Vector3] = [
		Vector3(-6, 0, -9), Vector3(6, 0, -9), Vector3(-6, 0, 9), Vector3(6, 0, 9)
	]
	var tan_h := tan(deg_to_rad(SnakeView.FOV_DEG) * 0.5)
	for aspect in [9.0 / 16.0, 9.0 / 19.5, 9.0 / 20.0, 3.0 / 4.0]:
		var t := SnakeView.fit_camera(12.0, 18.0, aspect, SnakeView.TOP_BAND, SnakeView.BOTTOM_BAND)
		var b := SnakeView._ndc_bounds(t, corners, tan_h, tan_h / aspect)
		assert_float(b.x).is_greater_equal(-1.0)
		assert_float(b.y).is_less_equal(1.0)
		assert_float(b.w).is_less_equal(1.0 - 2.0 * SnakeView.TOP_BAND)
		assert_float(b.z).is_greater_equal(-1.0 + 2.0 * SnakeView.BOTTOM_BAND)
