extends GdUnitTestSuite
## CPU golfer: finds a straight ace, avoids water when a safe shot exists, is deterministic for a
## seed, stays within its rollout budget, and Easy is less accurate than Hard.


func _preset() -> CoursePreset:
	var p := CoursePreset.new()
	p.stimp = 9.0
	return p


func _cpu(spec: Dictionary) -> GolfCpu:
	return GolfCpu.new(MiniBaker.bake(spec), _preset(), spec)


func _straight() -> Dictionary:
	return {
		"id": "t_straight",
		"name": "Straight",
		"par": 2,
		"tile": 3.0,
		"map": ["H", "G", "G", "G", "T"]
	}


func test_finds_an_ace_on_a_straight_hole() -> void:
	var cpu := _cpu(_straight())
	var best: Array = cpu.search(cpu.hole.tee)[0]
	assert_float(best[0]).is_less(0.0)  # holed


func test_keeps_out_of_the_water_when_a_safe_shot_exists() -> void:
	var spec := {
		"id": "t_water",
		"name": "Pond",
		"par": 3,
		"tile": 3.0,
		"map": [".GHG.", ".GWG.", ".GWG.", ".GGG.", "..T.."],
	}
	var cpu := _cpu(spec)
	var rng := RandomNumberGenerator.new()
	for s in 6:
		rng.seed = 100 + s
		var v := cpu.choose(cpu.hole.tee, GolfCpu.Tier.HARD, rng)
		assert_float(cpu.evaluate(cpu.hole.tee, v.x, v.y)).is_less(900.0)


func test_same_seed_same_shot() -> void:
	var spec := MiniBaker.load_spec("res://games/golf/data/mini/meadow_01.json")
	var cpu := _cpu(spec)
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	assert_vector(cpu.choose(cpu.hole.tee, GolfCpu.Tier.MEDIUM, a)).is_equal(
		cpu.choose(cpu.hole.tee, GolfCpu.Tier.MEDIUM, b)
	)


func test_search_budget() -> void:
	var spec := MiniBaker.load_spec("res://games/golf/data/mini/meadow_02.json")
	var cpu := _cpu(spec)
	var t0 := Time.get_ticks_usec()
	cpu.search(cpu.hole.tee)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("[golf-cpu] %d rollouts in %.0f ms" % [cpu.simulated, ms])
	assert_int(cpu.simulated).is_less_equal(90)


func test_easy_scatters_more_than_hard() -> void:
	var cpu := _cpu(_straight())
	var spread := []
	for tier in [GolfCpu.Tier.EASY, GolfCpu.Tier.HARD]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var angles := PackedFloat64Array()
		for k in 12:
			angles.append(cpu.choose(cpu.hole.tee, tier, rng).angle())
		var mean := 0.0
		for x in angles:
			mean += x / angles.size()
		var dev := 0.0
		for x in angles:
			dev += (x - mean) * (x - mean) / angles.size()
		spread.append(sqrt(dev))
	assert_float(spread[0]).is_greater(spread[1])


func test_threaded_think_matches_the_serial_search() -> void:
	var spec := MiniBaker.load_spec("res://games/golf/data/mini/meadow_02.json")
	var cpu := _cpu(spec)
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 9
	b.seed = 9
	var serial := cpu.choose(cpu.hole.tee, GolfCpu.Tier.HARD, a)
	var t0 := Time.get_ticks_usec()
	var think := GolfCpuThink.new(cpu, cpu.hole.tee, GolfCpu.Tier.HARD, b)
	var threaded := think.finish()
	print("[golf-cpu] threaded think %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	assert_vector(threaded).is_equal(serial)
