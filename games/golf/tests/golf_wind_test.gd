extends GdUnitTestSuite
## Coastal wind (HoleData.wind_x / wind_z from the spec's "wind"): a small constant push on a
## ball on the ground. It bends a putt, never moves a ball at rest, stays deterministic and is
## clamped to MiniBaker.WIND_MAX.

const OPEN := ["GGGGG", "GGGGG", "GGGGG", "GGGGG", "GGGGG", "GGGGG", "GGGGG", "GGHGG", "GGTGG"]


static func preset() -> CoursePreset:
	var pr := CoursePreset.new()
	pr.stimp = 9.0
	return pr


static func open_hole(wind: Array) -> HoleData:
	return MiniBaker.bake({"tile": 3.0, "map": OPEN, "wind": wind})


static func roll(d: HoleData, vx: float, vz: float) -> GolfBall:
	var b := GolfBall.new(d, preset())
	b.putt(d.tee.x - 1.0, d.tee.z, vx, vz)
	b.run_to_rest()
	return b


func test_spec_wind_is_read_and_clamped() -> void:
	var d := open_hole([0.08, -0.05])
	assert_float(d.wind_x).is_equal_approx(0.08, 1e-9)
	assert_float(d.wind_z).is_equal_approx(-0.05, 1e-9)
	var strong := open_hole([3.0, 4.0])
	var mag := sqrt(strong.wind_x * strong.wind_x + strong.wind_z * strong.wind_z)
	assert_float(mag).is_equal_approx(MiniBaker.WIND_MAX, 1e-9)
	var calm := MiniBaker.bake({"tile": 3.0, "map": OPEN})
	assert_float(calm.wind_x).is_equal(0.0)
	assert_float(calm.wind_z).is_equal(0.0)


func test_crosswind_bends_a_putt_downwind() -> void:
	var calm := roll(open_hole([0.0, 0.0]), 0.0, -4.0)
	var right := roll(open_hole([MiniBaker.WIND_MAX, 0.0]), 0.0, -4.0)
	var left := roll(open_hole([-MiniBaker.WIND_MAX, 0.0]), 0.0, -4.0)
	assert_int(calm.phase).is_equal(GolfBall.Phase.REST)
	var dx_r := right.pos().x - calm.pos().x
	var dx_l := left.pos().x - calm.pos().x
	# Noticeable (tens of centimetres to a metre and a half) and mirror-symmetric.
	assert_float(dx_r).is_between(0.2, 1.5)
	assert_float(dx_l).is_equal_approx(-dx_r, 1e-6)


func test_tailwind_carries_a_putt_further() -> void:
	var calm := roll(open_hole([0.0, 0.0]), 0.0, -4.0)
	var tail := roll(open_hole([0.0, -MiniBaker.WIND_MAX]), 0.0, -4.0)
	var head := roll(open_hole([0.0, MiniBaker.WIND_MAX]), 0.0, -4.0)
	assert_float(tail.pos().z).is_less(calm.pos().z - 0.2)
	assert_float(head.pos().z).is_greater(calm.pos().z + 0.2)


func test_strongest_wind_never_moves_a_ball_at_rest() -> void:
	for w in [[MiniBaker.WIND_MAX, 0.0], [0.0, -MiniBaker.WIND_MAX], [0.08, 0.08]]:
		var d := open_hole(w)
		var b := GolfBall.new(d, preset())
		b.putt(d.tee.x + 1.0, d.tee.z - 3.0, 0.0, 0.0)
		b.run_to_rest()
		assert_int(b.phase).is_equal(GolfBall.Phase.REST)
		assert_float(b.pos().x).is_equal_approx(d.tee.x + 1.0, 1e-9)
		assert_float(b.pos().z).is_equal_approx(d.tee.z - 3.0, 1e-9)
		assert_float(b.time).is_less(1.0)


func test_windy_putts_are_deterministic_and_step_invariant() -> void:
	var d := open_hole([0.1, -0.05])
	var a := roll(d, 0.6, -5.0)
	var b := roll(d, 0.6, -5.0)
	assert_bool(a.pos() == b.pos()).is_true()
	# The CPU planner and the aim guide step at 1/120 s; live play at 1/240 s.
	var plan := GolfBall.new(d, preset())
	plan.putt(d.tee.x - 1.0, d.tee.z, 0.6, -5.0)
	plan.run_to_rest(GolfCpu.PLAN_DT)
	assert_int(plan.phase).is_equal(a.phase)
	assert_float(plan.pos().distance_to(a.pos())).is_less(0.08)


func test_strongest_wind_stays_under_the_carpet_hold() -> void:
	var pr := preset()
	var hold := GolfSurfaces.STATIC_FACTOR * pr.green_decel()
	assert_float(5.0 / 7.0 * MiniBaker.WIND_MAX).is_less(hold * 0.5)
	assert_float(pr.max_rest_grade(9.81, MiniBaker.WIND_MAX)).is_less(pr.max_rest_grade())


func test_windy_balls_near_the_cup_rest_or_drop_quickly() -> void:
	# At rest and rolling slowly, upwind / downwind / across the cup, inside and at the edge of
	# its pull: every ball settles well before the solver's time cap.
	for w in [[MiniBaker.WIND_MAX, 0.0], [0.0, MiniBaker.WIND_MAX]]:
		var d := open_hole(w)
		for r in [0.15, 0.22, 0.3, 0.34]:
			for side: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				for v: float in [0.0, 0.25]:
					var b := GolfBall.new(d, preset())
					var at: Vector2 = Vector2(d.pin.x, d.pin.z) + side * r
					var vel := -side.orthogonal() * v
					b.putt(at.x, at.y, vel.x, vel.y)
					b.run_to_rest()
					var msg := "w %s r %.2f side %s v %.2f" % [w, r, side, v]
					assert_bool(b.done()).override_failure_message(msg).is_true()
					assert_float(b.time).override_failure_message(msg).is_less(5.0)


func test_ball_pushed_into_a_wall_by_the_wind_rests() -> void:
	var d := open_hole([MiniBaker.WIND_MAX, 0.0])
	var b := GolfBall.new(d, preset())
	# Right-hand rail of the open hole is 7.5 m right of the centre line; start 0.4 m from it.
	b.putt(d.tee.x + 7.0, d.tee.z - 6.0, 0.4, 0.0)
	b.run_to_rest()
	assert_int(b.phase).is_equal(GolfBall.Phase.REST)
	assert_float(b.time).is_less(3.0)


func test_malformed_wind_is_calm() -> void:
	for w in [[], [0.1], "east", 5]:
		var d := MiniBaker.bake({"tile": 3.0, "map": OPEN, "wind": w})
		assert_float(d.wind_x).is_equal(0.0)
		assert_float(d.wind_z).is_equal(0.0)
