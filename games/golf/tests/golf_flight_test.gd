extends GdUnitTestSuite
## GolfFlight against published launch-monitor data (research: ball physics notes, section 7).
## Rows: [name, ball speed mph, launch deg, spin rpm, carry yd]. PGA 2023 and the older LPGA sheet.

const PGA := [
	["driver", 171, 10.4, 2545, 282],
	["3-wood", 162, 9.3, 3663, 249],
	["5-iron", 135, 11.9, 5280, 199],
	["7-iron", 123, 16.1, 7124, 176],
	["PW", 104, 23.7, 9316, 142],
]
## + [apex yd, landing angle deg]
const LPGA := [
	["driver", 140, 13.2, 2611, 218, 25, 37],
	["7-iron", 104, 19.0, 6699, 141, 26, 47],
	["PW", 86, 25.7, 8403, 107, 23, 48],
]
const GOLDEN := "res://games/golf/data/golden_shot.json"


static func shot(
	r: Array, wind := Vector3.ZERO, tilt := 0.0, dt := GolfFlight.SUBSTEP, heading := 0.0
) -> Dictionary:
	var f := GolfFlight.new()
	f.launch(
		Vector3.ZERO,
		float(r[1]) * GolfFlight.MPH,
		r[2],
		float(r[3]) * GolfFlight.RPM,
		tilt,
		heading
	)
	f.set_wind(wind)
	var o := f.fly_to_ground(dt)
	var v: Vector3 = o.vel
	o["carry_yd"] = Vector2(o.pos.x, o.pos.z).length() / GolfFlight.YD
	o["side_yd"] = o.pos.x / GolfFlight.YD
	o["land_deg"] = rad_to_deg(atan2(-v.y, Vector2(v.x, v.z).length()))
	o["flight"] = f
	return o


func test_carry_matches_tour_averages() -> void:
	for r in PGA:
		var o := shot(r)
		var tol := 0.08 if r[0] == "PW" else 0.05
		(
			assert_float(o.carry_yd)
			. override_failure_message("%s carry %.1f yd vs %d" % [r[0], o.carry_yd, r[4]])
			. is_between(r[4] * (1.0 - tol), r[4] * (1.0 + tol))
		)


func test_lpga_carry_apex_and_landing_angle() -> void:
	for r in LPGA:
		var o := shot(r)
		var msg := (
			"%s: carry %.1f apex %.1f land %.1f"
			% [r[0], o.carry_yd, o.apex / GolfFlight.YD, o.land_deg]
		)
		assert_float(o.carry_yd).override_failure_message(msg).is_between(r[4] * 0.95, r[4] * 1.05)
		assert_float(o.apex / GolfFlight.YD).override_failure_message(msg).is_between(
			r[5] - 3.0, r[5] + 3.0
		)
		assert_float(o.land_deg).override_failure_message(msg).is_between(r[6] - 4.0, r[6] + 4.0)


func test_straight_shot_has_no_side_and_tilt_mirrors() -> void:
	var r: Array = PGA[2]
	assert_float(absf(shot(r).side_yd)).is_less(1e-9)
	var right := shot(r, Vector3.ZERO, 10.0)
	var left := shot(r, Vector3.ZERO, -10.0)
	assert_float(right.side_yd).is_greater(0.0)
	assert_float(right.side_yd + left.side_yd).is_equal_approx(0.0, 1e-9)
	assert_float(right.carry_yd - left.carry_yd).is_equal_approx(0.0, 1e-9)
	# TrackMan: ~15 yd at 10 deg on a ~200 yd shot; the research model gives ~21.
	assert_float(right.side_yd).is_between(15.0, 23.0)


func test_heading_rotates_the_whole_shot() -> void:
	var r: Array = PGA[3]
	var a := shot(r)
	var b := shot(r, Vector3.ZERO, 0.0, GolfFlight.SUBSTEP, 30.0)
	assert_float(b.carry_yd).is_equal_approx(a.carry_yd, 1e-4)
	assert_float(b.pos.x).is_greater(0.0)


func test_backspin_lifts_the_ball() -> void:
	var r: Array = PGA[3].duplicate()
	var spun := shot(r)
	r[3] = 0
	var flat := shot(r)
	assert_float(spun.carry_yd).is_greater(flat.carry_yd)
	assert_float(spun.apex).is_greater(flat.apex)


func test_wind_head_costs_more_than_tail_gains() -> void:
	var r: Array = PGA[3]
	var base := shot(r)
	var mph10 := 10.0 * GolfFlight.MPH
	var head: float = shot(r, Vector3(0, 0, mph10)).carry_yd - base.carry_yd
	var tail: float = shot(r, Vector3(0, 0, -mph10)).carry_yd - base.carry_yd
	# Published (tour 7-iron, 10 mph): about -19 / +14.6 yd. Wind here grows with height (power
	# law, 10 mph at 10 m), so the high iron loses a little more into the wind.
	assert_float(head).is_between(-24.0, -15.0)
	assert_float(tail).is_between(11.0, 18.0)
	assert_float(-head).is_greater(tail)
	var cross: Dictionary = shot(r, Vector3(mph10, 0, 0))
	assert_float(absf(cross.carry_yd - base.carry_yd) / base.carry_yd).is_less(0.01)
	assert_float(cross.side_yd).is_between(10.0, 22.0)


func test_wind_profile_grows_with_height() -> void:
	assert_float(GolfFlight.wind_factor(-1.0)).is_equal(0.3)
	assert_float(GolfFlight.wind_factor(10.0)).is_equal_approx(1.0, 1e-9)
	var last := 0.0
	for h in [0.0, 0.7, 1.5, 3.0, 7.0, 15.0, 30.0, 60.0, 120.0]:
		var k := GolfFlight.wind_factor(h)
		assert_float(k).is_greater_equal(last)
		last = k


func test_planning_step_matches_live_step() -> void:
	for r in [PGA[0], PGA[4]]:
		var live := shot(r)
		var coarse := shot(r, Vector3.ZERO, 0.0, 1.0 / 60.0)
		assert_float(absf(live.carry_yd - coarse.carry_yd) * GolfFlight.YD).is_less(0.5)


func test_golden_shot_is_bit_identical() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	var a := GolfBench.golden_flight()
	assert_str(a.fingerprint()).is_equal(data["fingerprint"])
	assert_str(GolfBench.golden_flight().fingerprint()).is_equal(a.fingerprint())
	# The bench copy is the same shot as the table-driven helper.
	assert_str((golden_shot().flight as GolfFlight).fingerprint()).is_equal(a.fingerprint())


## Tour 7-iron, 6 deg of curve, a quartering 4 m/s wind, 12 deg heading.
static func golden_shot() -> Dictionary:
	return shot(PGA[3], Vector3(2.5, 0.0, 3.1), 6.0, GolfFlight.SUBSTEP, 12.0)
