extends GdUnitTestSuite
## GolfBall: bounce, skid / spin-back, roll, rest on slopes, cup, water, out of bounds
## (research: ball physics notes, sections 4-7).

const R := 0.021335
const GOLDEN := "res://games/golf/data/golden_ball.json"


static func hole(
	surface := HoleData.Surface.GREEN, grade_x := 0.0, pin := Vector3(0, 0, -1000)
) -> HoleData:
	var d := HoleData.new()
	d.setup(-30.0, -320.0, 0.5, 120, 650)
	d.fill(
		func(x: float, _z: float) -> float: return grade_x * x,
		func(_x: float, _z: float) -> int: return surface
	)
	d.pin = pin
	return d


static func preset(stimp := 10.0, firm := false) -> CoursePreset:
	var pr := CoursePreset.new()
	pr.stimp = stimp
	pr.firm_greens = firm
	return pr


## Lands a ball (no air drag over a 3 mm drop) with speed, angle below horizontal and backspin.
static func land(b: GolfBall, speed: float, below_deg: float, spin: float) -> void:
	b.strike(Vector3(0, R + 0.003, 0), speed, -below_deg, spin)
	b.flight._k = 0.0
	var guard := 0
	while b.bounces == 0 and guard < 1000:
		b.substep()
		guard += 1


func test_stimpmeter_roll_matches_the_rating() -> void:
	for st in [8.0, 10.0, 12.0]:
		var b := GolfBall.new(hole(), preset(st))
		b.putt(0.0, 0.0, 0.0, -CoursePreset.STIMP_V0)
		b.run_to_rest()
		assert_int(b.phase).is_equal(GolfBall.Phase.REST)
		assert_float(-b.pos().z).is_equal_approx(st * CoursePreset.FT, st * CoursePreset.FT * 0.02)


## Haake's measured green bounce: 18.6 m/s, 44.4 deg from vertical, 484 rad/s backspin -> about
## 4.3-5.1 m/s out, leaving with topspin (Penner's model: 154 rad/s; measured 145).
func test_haake_bounce_on_a_soft_green() -> void:
	var b := GolfBall.new(hole(), preset())
	land(b, 18.6, 90.0 - 44.4, 484.0)
	assert_int(b.phase).is_equal(GolfBall.Phase.FLY)
	var v := b.flight.vel()
	assert_float(v.length()).is_between(3.8, 5.5)
	assert_float(v.y).is_greater(0.0)
	assert_float(b.flight.axis[0]).is_less(0.0)  # spin axis flipped: topspin
	assert_float(b.flight.spin).is_between(120.0, 200.0)


## Penner: on a firm green a 9-iron landing at 23.8 m/s, 34 deg from vertical holds with ~809
## rad/s and pulls back with more spin (his model: 0 / 1.1 / 4.7 m back for 809 / 1000 / 1200).
func test_backspin_holds_or_pulls_back_on_a_firm_green() -> void:
	var runs: Array[float] = []
	for w in [809.0, 1000.0, 1200.0]:
		var b := GolfBall.new(hole(), preset(10.0, true))
		land(b, 23.8, 56.0, w)
		b.run_to_rest()
		runs.append(-b.pos().z)
	assert_float(absf(runs[0])).is_less(1.0)
	assert_float(runs[1]).is_less(0.0)
	assert_float(runs[2]).is_less(-1.5)
	assert_float(runs[2]).is_less(runs[1])


func test_driver_rolls_out_and_a_wedge_sits_down() -> void:
	var d := GolfBall.new(hole(HoleData.Surface.FAIRWAY), preset())
	d.strike(Vector3(0, R, 0), 171 * GolfFlight.MPH, 10.4, 2545 * GolfFlight.RPM)
	d.run_to_rest()
	assert_int(d.phase).is_equal(GolfBall.Phase.REST)
	assert_float(-d.pos().z / GolfFlight.YD - 274.2).is_between(8.0, 30.0)
	var w := GolfBall.new(hole(), preset())
	w.strike(Vector3(0, R, 0), 104 * GolfFlight.MPH, 23.7, 9316 * GolfFlight.RPM)
	w.run_to_rest()
	assert_float(absf(-w.pos().z / GolfFlight.YD - 133.7)).is_less(3.0)


## A ball at rest stays on a green below the Stimp-derived limit and runs away above it.
func test_rest_on_slopes_follows_green_speed() -> void:
	for st in [8.0, 10.0, 11.0]:
		var pr := preset(st)
		var limit := pr.max_rest_grade()
		var stays := GolfBall.new(hole(HoleData.Surface.GREEN, limit * 0.9), pr)
		stays.putt(0.0, -5.0, 0.0, 0.0)
		stays.run_to_rest()
		assert_int(stays.phase).is_equal(GolfBall.Phase.REST)
		assert_float(stays.pos().x).is_equal_approx(0.0, 0.01)
		var runs := GolfBall.new(hole(HoleData.Surface.GREEN, limit * 1.2), pr)
		runs.putt(0.0, -5.0, 0.0, 0.0)
		runs.run_to_rest()
		assert_float(absf(runs.pos().x)).is_greater(1.0)
	# Limits: about 10.8% at Stimp 8, 8.6% at 10, 7.9% at 11.
	assert_float(preset(10.0).max_rest_grade()).is_between(0.08, 0.09)


## Putt from 5 m so the ball reaches the cup at `arrive` m/s with lateral offset b.
static func putt_at(arrive: float, b: float) -> GolfBall:
	var pr := preset()
	var ball := GolfBall.new(hole(HoleData.Surface.GREEN, 0.0, Vector3(0, 0, -5)), pr)
	var v0 := sqrt(arrive * arrive + 2.0 * pr.green_decel() * 5.0)
	ball.putt(b, 0.0, 0.0, -v0)
	ball.run_to_rest()
	return ball


func test_cup_capture_and_lip_outs() -> void:
	assert_int(putt_at(1.30, 0.0).phase).is_equal(GolfBall.Phase.HOLED)
	assert_int(putt_at(1.60, 0.0).phase).is_equal(GolfBall.Phase.HOLED)  # rim assist
	var hard := putt_at(1.75, 0.0)
	assert_int(hard.phase).is_not_equal(GolfBall.Phase.HOLED)
	assert_bool(GolfBall.Ev.LIP in hard.events).is_true()
	# 5 cm off centre the limit is ~0.37 m/s (free fall 0.30 x rim 1.24). The notes' example of
	# "0.05 m at 0.5 m/s -> holed" contradicts their own formula; the formula is the sourced part.
	assert_int(putt_at(0.3, 0.05).phase).is_equal(GolfBall.Phase.HOLED)
	assert_int(putt_at(0.5, 0.05).phase).is_not_equal(GolfBall.Phase.HOLED)
	assert_int(putt_at(0.3, 0.056).phase).is_not_equal(GolfBall.Phase.HOLED)  # misses the edge
	assert_int(putt_at(1.0, 0.045).phase).is_not_equal(GolfBall.Phase.HOLED)  # too fast that wide
	assert_int(putt_at(0.08, 0.0).phase).is_equal(GolfBall.Phase.HOLED)  # dies into the hole


func test_water_and_out_of_bounds() -> void:
	var d := hole(HoleData.Surface.FAIRWAY)
	d.fill(
		func(_x: float, _z: float) -> float: return 0.0,
		func(_x: float, z: float) -> int:
			return HoleData.Surface.WATER if z < -100.0 and z > -160.0 else HoleData.Surface.FAIRWAY
	)
	var b := GolfBall.new(d, preset())
	b.strike(Vector3(0, R, 0), 96 * GolfFlight.MPH, 17.5, 6500 * GolfFlight.RPM)
	b.run_to_rest()
	assert_int(b.phase).is_equal(GolfBall.Phase.WATER)
	assert_bool(GolfBall.Ev.WATER in b.events).is_true()
	var rolls := GolfBall.new(d, preset())
	rolls.putt(0.0, -90.0, 0.0, -8.0)
	rolls.run_to_rest()
	assert_int(rolls.phase).is_equal(GolfBall.Phase.WATER)
	assert_float(rolls.last_safe.z).is_greater(-100.5)
	var ob := GolfBall.new(hole(HoleData.Surface.FAIRWAY), preset())
	ob.strike(Vector3(0, R, 0), 133 * GolfFlight.MPH, 12.6, 3275 * GolfFlight.RPM, 0.0, 70.0)
	ob.run_to_rest()
	assert_int(ob.phase).is_equal(GolfBall.Phase.OUT)


## Random shots over rolling mixed ground always finish, never below the surface.
func test_every_shot_finishes_above_ground() -> void:
	var d := HoleData.new()
	d.setup(-40.0, -300.0, 0.5, 160, 610)
	d.fill(
		func(x: float, z: float) -> float:
			return 2.0 * sin(x * 0.11) * sin(z * 0.05) + 0.3 * sin(z * 0.7),
		func(x: float, z: float) -> int:
			var k := int(absf(x * 0.13 + z * 0.07)) % 5
			return [
				HoleData.Surface.FAIRWAY,
				HoleData.Surface.ROUGH,
				HoleData.Surface.GREEN,
				HoleData.Surface.SAND,
				HoleData.Surface.FRINGE
			][k]
	)
	d.pin = Vector3(3, 0, -150)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 12:
		var b := GolfBall.new(d, preset())
		var y := d.height(0.0, 0.0) + R
		b.strike(
			Vector3(0, y, 0),
			rng.randf_range(20.0, 70.0),
			rng.randf_range(8.0, 30.0),
			rng.randf_range(200.0, 900.0),
			rng.randf_range(-8.0, 8.0),
			rng.randf_range(-15.0, 15.0)
		)
		b.run_to_rest()
		assert_bool(b.done()).override_failure_message("shot %d" % k).is_true()
		if b.phase == GolfBall.Phase.REST:
			var p := b.pos()
			assert_float(p.y - d.height(p.x, p.z)).is_greater_equal(R - 1e-4)


func test_golden_ball_is_bit_identical() -> void:
	var a := golden_ball()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	assert_str(a.fingerprint()).is_equal(data["fingerprint"])
	assert_str(golden_ball().fingerprint()).is_equal(a.fingerprint())


## 7-iron with a little curve onto a sloped, firm green with a pin: flight, bounces, skid, roll.
static func golden_ball() -> GolfBall:
	var d := hole(HoleData.Surface.GREEN, 0.012, Vector3(4.0, 0.0, -150.0))
	var b := GolfBall.new(d, preset(11.0, true))
	b.strike(Vector3(0, R, 0), 96 * GolfFlight.MPH, 17.5, 6500 * GolfFlight.RPM, 3.0, 2.0)
	b.flight.set_wind(Vector3(1.2, 0.0, 0.8))
	b.run_to_rest()
	return b
