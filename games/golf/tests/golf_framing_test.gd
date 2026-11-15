extends GdUnitTestSuite
## Backdrop placement: the landmark is in front of the tee view and well clear of play; trees
## never stand on or beside the course.

const HOLES := [
	"res://games/golf/data/mini/meadow_01.json",
	"res://games/golf/data/mini/meadow_02.json",
	"res://games/golf/data/mini/meadow_03.json",
]


func test_landmark_is_ahead_of_the_tee_view_and_clear_of_play() -> void:
	for path in HOLES:
		var spec := MiniBaker.load_spec(path)
		var hole := MiniBaker.bake(spec)
		var view := MiniFraming.tee_view(spec, hole)
		var spot := MiniFraming.landmark_spot(hole, view)
		var tee := Vector2(hole.tee.x, hole.tee.z)
		var dist := tee.distance_to(spot)
		assert_float(dist).is_between(30.0, 80.0)
		var off := rad_to_deg(absf(view.angle_to(spot - tee)))
		assert_float(off).is_less(12.0)
		assert_bool(MiniFraming.clear_of_course(hole, spot.x, spot.y, 10.0)).is_true()


func test_corner_tee_view_points_up_its_first_leg() -> void:
	var spec := MiniBaker.load_spec(HOLES[0])
	var hole := MiniBaker.bake(spec)
	var view := MiniFraming.tee_view(spec, hole)
	assert_float(view.y).is_less(-0.9)  # -z is "up" the map


func test_clearance_rejects_the_course_and_accepts_open_lawn() -> void:
	var hole := MiniBaker.bake(MiniBaker.load_spec(HOLES[1]))
	assert_bool(MiniFraming.clear_of_course(hole, hole.tee.x, hole.tee.z, 1.0)).is_false()
	assert_bool(MiniFraming.clear_of_course(hole, hole.tee.x + 3.5, hole.tee.z, 6.0)).is_false()
	assert_bool(MiniFraming.clear_of_course(hole, hole.tee.x + 60.0, hole.tee.z, 6.0)).is_true()


func test_shadow_falls_away_from_the_sun() -> void:
	# Sun high in the default meadow direction: a 5 m crown's shadow lands a few metres away,
	# on the side the light travels toward.
	var th := GolfTheme.meadow()
	var sp := MiniFraming.shadow_spot(0.0, 0.0, 5.0, th.sun_pitch, th.sun_yaw)
	var fwd := Basis.from_euler(Vector3(deg_to_rad(th.sun_pitch), deg_to_rad(th.sun_yaw), 0))
	var light := fwd * Vector3.FORWARD
	assert_float(sp.length()).is_between(3.0, 6.0)
	assert_float(sp.dot(Vector2(light.x, light.z))).is_greater(0.0)
