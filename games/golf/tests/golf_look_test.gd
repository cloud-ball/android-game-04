extends GdUnitTestSuite
## The visual rules that are data: the value ladder of a theme, and slow motion that leaves the
## physics bit-identical.


func test_meadow_value_ladder() -> void:
	var t := GolfTheme.meadow()
	var lum := GolfTheme.luminance
	# Surroundings darkest, then carpet, then rails; ball and cup rim brightest.
	assert_float(lum.call(t.lawn)).is_less(lum.call(t.carpet))
	assert_float(lum.call(t.carpet)).is_less(lum.call(t.rail_body))
	assert_float(lum.call(t.rail_body)).is_less(lum.call(t.ball))
	assert_float(lum.call(t.rail_cap)).is_less_equal(lum.call(t.ball))
	# No flower may compete with the ball's white.
	for f in t.flowers:
		assert_float(lum.call(f)).is_less(lum.call(t.ball) * 0.75)


func test_clock_runs_four_substeps_per_tick_at_full_rate() -> void:
	var c := PresentationClock.new()
	for k in 10:
		assert_int(c.take()).is_equal(4)


func test_slow_motion_keeps_the_shot_bit_identical() -> void:
	var d := MiniBaker.bake(MiniBaker.load_spec("res://games/golf/data/mini/meadow_02.json"))
	var pr := CoursePreset.new()
	pr.stimp = 9.0
	var a := GolfBall.new(d, pr)
	var b := GolfBall.new(d, pr)
	a.putt(d.tee.x, d.tee.z, 1.2, -9.0)
	b.putt(d.tee.x, d.tee.z, 1.2, -9.0)
	a.run_to_rest()
	var clock := PresentationClock.new()
	var tick := 0
	while not b.done() and tick < 20000:
		tick += 1
		clock.rate = 0.3 if (tick / 40) % 2 == 1 else 1.0  # alternate slow and normal
		for i in clock.take():
			if b.done():
				break
			b.substep()
	assert_str(b.fingerprint()).is_equal(a.fingerprint())
