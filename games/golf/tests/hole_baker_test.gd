extends GdUnitTestSuite
## HoleBaker on the shipped hole specs: deterministic bakes and structural playability checks
## (research: courses and maps report, "two-stage validator" - this is the fast stage).

const SPECS := ["res://games/golf/data/holes/meadow_03.json"]


static func baked(path: String) -> HoleData:
	return HoleBaker.bake(HoleBaker.load_spec(path))


func test_bake_is_deterministic() -> void:
	for p in SPECS:
		var a := baked(p)
		var b := baked(p)
		assert_bool(a.heights == b.heights).is_true()
		assert_bool(a.surface == b.surface).is_true()


func test_structure_of_every_hole() -> void:
	var pr := CoursePreset.new()
	for p in SPECS:
		var spec := HoleBaker.load_spec(p)
		var d := HoleBaker.bake(spec)
		var msg: String = p
		# Tee on the tee box, nearly flat.
		assert_int(d.surface_at(d.tee.x, d.tee.z)).override_failure_message(msg).is_equal(
			HoleData.Surface.TEE
		)
		assert_float(d.gradient(d.tee.x, d.tee.z).length()).override_failure_message(msg).is_less(
			0.02
		)
		# Every pin on the green, on a slope a ball can rest on, ringed by green or fringe.
		for pin in spec.pins:
			var x := float(pin[0])
			var z := float(pin[1])
			assert_int(d.surface_at(x, z)).override_failure_message(msg).is_equal(
				HoleData.Surface.GREEN
			)
			assert_float(d.gradient(x, z).length()).override_failure_message(msg).is_less(
				pr.max_rest_grade() * 0.5
			)
			for k in 8:
				var ang := TAU * k / 8.0
				var s := d.surface_at(x + cos(ang) * 3.0, z + sin(ang) * 3.0)
				assert_bool(s == HoleData.Surface.GREEN or s == HoleData.Surface.FRINGE).is_true()
		# Green ringed by fringe (never straight into rough).
		var g: Dictionary = spec.green
		for k in 16:
			var e := _edge(g, TAU * k / 16.0)
			var s := d.surface_at(float(g.x) + e.x, float(g.z) + e.y)
			(
				assert_bool(
					s in [HoleData.Surface.FRINGE, HoleData.Surface.GREEN, HoleData.Surface.SAND]
				)
				. override_failure_message("%s edge %d -> %d" % [msg, k, s])
				. is_true()
			)
		# A landing area: fairway at least 25 m wide somewhere 150-220 m out (first leg runs
		# straight down -z from the tee on this course's long holes; generalise with the spec).
		var widest := 0.0
		for s in range(150, 221, 5):
			var w := 0.0
			for dx in range(-40, 41):
				if d.surface_at(float(dx), -float(s)) == HoleData.Surface.FAIRWAY:
					w += 1.0
			widest = maxf(widest, w)
		assert_float(widest).override_failure_message(msg).is_greater_equal(25.0)


## A point 0.5 m outside the green ellipse edge (in the fringe) at angle `ang` (relative to centre).
static func _edge(g: Dictionary, ang: float) -> Vector2:
	var ax: Array = g.get("axis", [1.0, 0.0])
	var u := Vector2(ax[0], ax[1]).normalized()
	var v := Vector2(-u.y, u.x)
	var local := Vector2(cos(ang) * (float(g.rx) + 0.5), sin(ang) * (float(g.rz) + 0.5))
	return u * local.x + v * local.y


func test_clubs_carry_ladder_and_aim_helpers() -> void:
	var c := GolfClubs.new()
	var last := 1e9
	for k in GolfClubs.count():
		var full := c.carry_at(k, 1.0)
		assert_float(full).is_less(last)  # driver longest, sand wedge shortest
		last = full
		# power_for inverts carry_at
		assert_float(c.carry_at(k, c.power_for(k, full * 0.7))).is_equal_approx(full * 0.7, 0.5)
	assert_float(c.carry_at(0, 1.0)).is_between(160.0, 195.0)  # average amateur driver ~178 m
	assert_int(c.pick(100.0)).is_equal(2)  # 7-iron (wedge tops out ~87 m)
	assert_int(c.pick(80.0)).is_equal(3)  # wedge
	assert_int(c.pick(400.0)).is_equal(0)  # nothing reaches: driver
	assert_float(GolfClubs.putt_speed(3.0, 0.6)).is_equal_approx(sqrt(2.0 * 0.6 * 3.3), 1e-9)
