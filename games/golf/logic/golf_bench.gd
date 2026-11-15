class_name GolfBench
extends RefCounted
## Fairway Flick solver benchmark (step 5 of docs/plans/2026-11-14-fairway-flick-courses.md):
## `--bench=golf` prints "[golf-bench]" lines and quits. On the phone:
##   adb shell run-as <package> sh -c 'echo --bench=golf > files/dev_args.txt'
## Also prints the golden hashes, so cross-device bit-exactness can be checked against the tests.


## Tour 7-iron, 6 deg of curve, a quartering 4 m/s wind, 12 deg heading, to the ground
## (golf_flight_test.gd / golden_shot.json).
static func golden_flight() -> GolfFlight:
	var f := GolfFlight.new()
	f.launch(Vector3.ZERO, 123.0 * GolfFlight.MPH, 16.1, 7124.0 * GolfFlight.RPM, 6.0, 12.0)
	f.set_wind(Vector3(2.5, 0.0, 3.1))
	f.fly_to_ground(GolfFlight.SUBSTEP)
	return f


## 7-iron with a little curve and wind onto a firm Stimp-11 green sloping 1.2% with a pin
## (golf_ball_test.gd / golden_ball.json).
static func golden_ball() -> GolfBall:
	var d := HoleData.new()
	d.setup(-30.0, -320.0, 0.5, 120, 650)
	d.fill(
		func(x: float, _z: float) -> float: return 0.012 * x,
		func(_x: float, _z: float) -> int: return HoleData.Surface.GREEN
	)
	d.pin = Vector3(4.0, 0.0, -150.0)
	var pr := CoursePreset.new()
	pr.stimp = 11.0
	pr.firm_greens = true
	var b := GolfBall.new(d, pr)
	b.strike(Vector3(0, b.p.radius, 0), 96 * GolfFlight.MPH, 17.5, 6500 * GolfFlight.RPM, 3.0, 2.0)
	b.flight.set_wind(Vector3(1.2, 0.0, 0.8))
	b.run_to_rest()
	return b


## Mini-golf golden shot: a walled green with a bumper and a 0.3 m ledge, banked towards the cup.
static func golden_minigolf() -> GolfBall:
	var d := HoleData.new()
	d.setup(-6.0, -30.0, 0.25, 48, 120)
	d.fill(
		func(_x: float, z: float) -> float: return 0.3 if z > -12.0 else 0.0,
		func(_x: float, _z: float) -> int: return HoleData.Surface.GREEN
	)
	d.add_wall_loop([[-6.0, 0.0], [6.0, 0.0], [6.0, -30.0], [-6.0, -30.0]])
	d.add_bumper(1.5, -18.0, 0.6)
	d.pin = Vector3(-2.0, 0.0, -26.0)
	var pr := CoursePreset.new()
	pr.stimp = 10.0
	var b := GolfBall.new(d, pr)
	b.putt(0.0, -4.0, 3.1, -7.4)
	b.run_to_rest()
	return b


## Rolling ground with mixed surfaces, like a real hole.
static func bench_hole() -> HoleData:
	var d := HoleData.new()
	d.setup(-40.0, -300.0, 0.5, 160, 610)
	d.fill(
		func(x: float, z: float) -> float:
			return 2.0 * sin(x * 0.11) * sin(z * 0.05) + 0.3 * sin(z * 0.7),
		func(x: float, z: float) -> int:
			return (
				HoleData.Surface.GREEN
				if absf(z + 150.0) < 15.0
				else (HoleData.Surface.FAIRWAY if absf(x) < 15.0 else HoleData.Surface.ROUGH)
			)
	)
	d.pin = Vector3(2.0, 0.0, -150.0)
	return d


static func run() -> void:
	print("[golf-bench] golden flight hash %s" % golden_flight().fingerprint().md5_text())
	print("[golf-bench] golden ball hash %s" % golden_ball().fingerprint().md5_text())
	print("[golf-bench] golden minigolf hash %s" % golden_minigolf().fingerprint().md5_text())
	var d := bench_hole()
	# [name, ball mph, launch deg, rpm]
	var shots := [
		["driver", 133.0, 12.6, 3275.0],
		["7-iron", 96.0, 17.5, 6500.0],
		["wedge", 81.0, 25.0, 8500.0],
	]
	for dt in [GolfFlight.SUBSTEP, 1.0 / 120.0, 1.0 / 60.0]:
		var total_us := 0
		var steps := 0
		var n := 0
		for s in shots:
			for k in 3:
				var b := GolfBall.new(d)
				var y := d.height(0.0, 0.0) + b.p.radius
				b.strike(
					Vector3(0, y, 0),
					float(s[1]) * GolfFlight.MPH,
					s[2],
					float(s[3]) * GolfFlight.RPM,
					(k - 1) * 4.0,
					(k - 1) * 3.0
				)
				var t0 := Time.get_ticks_usec()
				b.run_to_rest(dt)
				total_us += Time.get_ticks_usec() - t0
				steps += int(b.time / dt + 0.5)
				n += 1
		print(
			(
				"[golf-bench] step 1/%d: %.1f us/substep, %.1f ms per full shot to rest (%d shots)"
				% [roundi(1.0 / dt), float(total_us) / maxi(1, steps), total_us / 1000.0 / n, n]
			)
		)
	# Putts: rolling only.
	var t1 := Time.get_ticks_usec()
	var putts := 20
	for k in putts:
		var b := GolfBall.new(d)
		b.putt(2.0 + k * 0.2, -140.0, 0.0, -2.5)
		b.run_to_rest(1.0 / 120.0)
	print(
		(
			"[golf-bench] putt rollout (1/120): %.2f ms each (%d)"
			% [(Time.get_ticks_usec() - t1) / 1000.0 / putts, putts]
		)
	)
