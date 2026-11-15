extends GdUnitTestSuite
## Mini-golf walls, bumpers and hops (docs/plans/2026-11-15-fairway-flick-minigolf.md, step B).

const R := 0.021335
const GOLDEN := "res://games/golf/data/golden_minigolf.json"


## A flat 12 x 30 m green box with walls all round, cup far away unless given.
static func box(pin := Vector3(0, 0, -1000), height_fn := Callable()) -> HoleData:
	var d := HoleData.new()
	d.setup(-6.0, -30.0, 0.25, 48, 120)
	d.fill(
		height_fn if height_fn.is_valid() else func(_x: float, _z: float) -> float: return 0.0,
		func(_x: float, _z: float) -> int: return HoleData.Surface.GREEN
	)
	d.add_wall_loop([[-6.0, 0.0], [6.0, 0.0], [6.0, -30.0], [-6.0, -30.0]])
	d.pin = pin
	return d


static func ball(d: HoleData) -> GolfBall:
	var pr := CoursePreset.new()
	pr.stimp = 10.0
	return GolfBall.new(d, pr)


func test_wall_bounce_mirrors_the_angle_and_keeps_most_speed() -> void:
	var b := ball(box())
	# Roll towards the right wall (x = 6) at 45 degrees from (0, -10).
	b.putt(0.0, -10.0, 4.0, -4.0)
	var hit := false
	for k in 2000:
		b.substep()
		if GolfBall.Ev.WALL in b.events:
			hit = true
			break
	assert_bool(hit).is_true()
	# After the bounce: moving left (-x), still forward (-z); speed reduced by e / keep, not more.
	assert_float(b._vx).is_less(0.0)
	assert_float(b._vz).is_less(0.0)
	var speed := sqrt(b._vx * b._vx + b._vz * b._vz)
	# 5.66 m/s at the start, ~5.0 at the wall after 6 m of green; then normal x0.8, tangent x0.9.
	assert_float(speed).is_between(3.9, 5.0)
	assert_float(absf(b._vx) / absf(b._vz)).is_between(0.8, 0.95)  # 0.8 / 0.9 = 0.89


func test_fast_ball_never_passes_a_wall() -> void:
	for dt in [GolfFlight.SUBSTEP, 1.0 / 60.0]:
		var b := ball(box())
		b.putt(5.5, -15.0, 14.0, 0.3)  # 14 m/s at the wall 0.5 m away
		b.run_to_rest(dt)
		assert_int(b.phase).is_equal(GolfBall.Phase.REST)
		assert_float(b.pos().x).is_between(-6.0, 6.0 - R + 1e-6)
		assert_float(b.pos().z).is_between(-30.0, 0.0)


func test_ball_stays_in_a_walled_box_after_many_bounces() -> void:
	var b := ball(box())
	b.putt(-3.0, -5.0, 9.0, -11.0)
	b.run_to_rest()
	assert_int(b.phase).is_equal(GolfBall.Phase.REST)
	var p := b.pos()
	assert_float(p.x).is_between(-6.0, 6.0)
	assert_float(p.z).is_between(-30.0, 0.0)
	var walls := 0
	for e in b.events:
		if e == GolfBall.Ev.WALL:
			walls += 1
	assert_int(walls).is_greater(3)


func test_bumper_reverses_a_head_on_hit_and_deflects_a_glancing_one() -> void:
	var d := box()
	d.add_bumper(0.0, -15.0, 0.5)
	var head := ball(d)
	head.putt(0.0, -5.0, 0.0, -5.0)
	for k in 1500:
		head.substep()
		if GolfBall.Ev.WALL in head.events:
			break
	assert_float(head._vz).is_greater(0.0)  # coming back
	assert_float(absf(head._vx)).is_less(1e-6)
	var glance := ball(d)
	glance.putt(0.4, -5.0, 0.0, -5.0)  # 0.4 m off the bumper's centre
	for k in 1500:
		glance.substep()
		if GolfBall.Ev.WALL in glance.events:
			break
	assert_float(glance._vx).is_greater(0.3)  # pushed to +x
	assert_float(glance._vz).is_less(0.0)  # still mostly forward


## Rolling off a 0.3 m ledge the ball flies, lands beyond the edge and keeps going.
func test_ball_hops_off_a_ledge() -> void:
	var d := box(
		Vector3(0, 0, -1000), func(_x: float, z: float) -> float: return 0.3 if z > -12.0 else 0.0
	)
	var b := ball(d)
	b.putt(0.0, -8.0, 0.0, -3.0)
	b.run_to_rest()
	assert_bool(GolfBall.Ev.HOP in b.events).is_true()
	assert_bool(GolfBall.Ev.BOUNCE in b.events).is_true()
	assert_float(b.pos().z).is_less(-12.5)


func test_ramp_without_a_lip_keeps_the_ball_on_the_ground() -> void:
	var d := box(
		Vector3(0, 0, -1000),
		func(_x: float, z: float) -> float: return clampf((-z - 8.0) * 0.1, 0.0, 0.6)
	)
	var b := ball(d)
	b.putt(0.0, -4.0, 0.0, -5.0)
	b.run_to_rest()
	assert_bool(GolfBall.Ev.HOP in b.events).is_false()
	assert_int(b.phase).is_equal(GolfBall.Phase.REST)


## Banked off the right wall (x = 6): some aim and pace drops it (the wall keeps 0.9 of the
## sideways speed and 0.8 of the straight-on speed, so the rebound is not a perfect mirror).
func test_walled_putt_can_still_drop() -> void:
	var holed := 0
	for ai in 30:
		var dir := (Vector2(7.0 + ai * 0.2, -20.0) - Vector2(0.0, -5.0)).normalized()
		for vi in 16:
			var v := 3.0 + vi * 0.3
			var b := ball(box(Vector3(2.0, 0.0, -20.0)))
			b.putt(0.0, -5.0, dir.x * v, dir.y * v)
			b.run_to_rest(1.0 / 60.0)
			if b.phase == GolfBall.Phase.HOLED and GolfBall.Ev.WALL in b.events:
				holed += 1
	assert_int(holed).is_greater(0)


func test_golden_minigolf_shot_is_bit_identical() -> void:
	var a := GolfBench.golden_minigolf()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	assert_str(a.fingerprint()).is_equal(data["fingerprint"])
	assert_str(GolfBench.golden_minigolf().fingerprint()).is_equal(a.fingerprint())
