extends GdUnitTestSuite
## GolfParams: ball constants and the aerodynamic curves (research report, ball physics notes).


func test_ball_constants() -> void:
	var p := GolfParams.new()
	assert_float(p.radius * 2.0).is_equal_approx(0.04267, 1e-6)
	assert_float(p.mass).is_equal_approx(0.04593, 1e-6)
	assert_float(p.inertia()).is_equal_approx(0.4 * p.mass * p.radius * p.radius, 1e-12)


func test_drag_crisis_and_spin() -> void:
	var p := GolfParams.new()
	# Slow ball (Re < 5e4): high drag; full-shot speeds (Re > 1e5): ~0.225 without spin.
	assert_float(p.cd(10.0, 0.0)).is_equal_approx(0.5, 1e-6)
	assert_float(p.cd(60.0, 0.0)).is_equal_approx(0.225, 1e-6)
	# Spin adds drag, never more than the cap of the spin term.
	assert_float(p.cd(60.0, 0.2)).is_greater(p.cd(60.0, 0.0))
	assert_float(p.cd(60.0, 0.6)).is_less(0.225 + 0.18)
	# The Taylor spin term tracks 1 - e^(-3 s^2) closely.
	for s in [0.05, 0.1, 0.2, 0.3, 0.45, 0.6]:
		var exact := 1.0 - exp(-3.0 * s * s)
		assert_float(GolfParams._spin_term(s)).is_equal_approx(exact, 0.005)


func test_lift_is_continuous_and_unclamped() -> void:
	var p := GolfParams.new()
	assert_float(p.cl(0.0)).is_equal(0.0)
	var below := p.cl(0.25 - 1e-6)
	var above := p.cl(0.25 + 1e-6)
	assert_float(above - below).is_less(1e-5)
	assert_float(p.cl(0.25)).is_equal_approx(0.2941, 1e-3)
	# Irons and wedges (S 0.3-0.45) keep gaining lift (the old clamp at 0.25 flattened them).
	assert_float(p.cl(0.45)).is_greater(0.25)


func test_save_without_golf_key_loads_with_defaults() -> void:
	# The save rules moved to GolfProgress (schema 2) in step G.
	var g := SaveService.prepare_namespace(
		null, GolfProgress.SCHEMA, GolfProgress.DEFAULTS, GolfProgress.migrate
	)
	assert_int(int(g["schema"])).is_equal(GolfProgress.SCHEMA)
	assert_int(int(g["played"])).is_equal(0)
	assert_str(str(g["difficulty"])).is_equal("medium")
