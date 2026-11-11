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


func test_rows_follow_screen_shape() -> void:
	assert_int(SnakeConfig.rows_for_aspect(9.0 / 16.0)).is_equal(18)
	assert_int(SnakeConfig.rows_for_aspect(1260.0 / 2800.0)).is_equal(22)
	assert_int(SnakeConfig.rows_for_aspect(9.0 / 19.5)).is_equal(21)
	assert_int(SnakeConfig.rows_for_aspect(3.0 / 4.0)).is_equal(18)


func test_tall_board_fits_tall_phone() -> void:
	var aspect := 1260.0 / 2800.0
	var rows := SnakeConfig.rows_for_aspect(aspect)
	var hh := rows * 0.5
	var corners: Array[Vector3] = [
		Vector3(-6, 0, -hh), Vector3(6, 0, -hh), Vector3(-6, 0, hh), Vector3(6, 0, hh)
	]
	var tan_h := tan(deg_to_rad(SnakeView.FOV_DEG) * 0.5)
	var t := SnakeView.fit_camera(12.0, rows, aspect, SnakeView.TOP_BAND, SnakeView.BOTTOM_BAND)
	var b := SnakeView._ndc_bounds(t, corners, tan_h, tan_h / aspect)
	assert_float(b.w).is_less_equal(1.0 - 2.0 * SnakeView.TOP_BAND)
	assert_float(b.z).is_greater_equal(-1.0 + 2.0 * SnakeView.BOTTOM_BAND)
	# The board should use most of the free band height.
	var band := (1.0 - 2.0 * SnakeView.TOP_BAND) - (-1.0 + 2.0 * SnakeView.BOTTOM_BAND)
	assert_float((b.w - b.z) / band).is_greater(0.8)
