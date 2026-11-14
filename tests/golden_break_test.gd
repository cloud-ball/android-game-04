extends GdUnitTestSuite
## Golden-master break (see .claude/rules/cue-sim.md): the fixed break must end bit-identically.
## Any physics change that moves it needs games/pool/data/golden_break.json regenerated with a
## written justification in the commit. The phone build prints the same hash (Boot --bench=cue).

const GOLDEN := "res://games/pool/data/golden_break.json"


func test_golden_break_is_bit_identical() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	var sim := CueBench.golden_break()
	assert_str(CueBench.fingerprint(sim)).is_equal(data["fingerprint"])


func test_same_break_twice_is_identical() -> void:
	var a := CueBench.fingerprint(CueBench.golden_break())
	var b := CueBench.fingerprint(CueBench.golden_break())
	assert_str(a).is_equal(b)


## The 64-events-per-substep fallback (frictionless separation) must never stand in for real
## break physics, at the golden 9 m/s or at full power (13 m/s).
func test_breaks_never_hit_the_event_cap() -> void:
	var sim := CueBench.golden_break()
	assert_int(sim.events_capped).is_equal(0)
	for seed_value in [1, 2, 3]:
		var m := PoolMatch.new(seed_value, 0)
		m.sim.strike(0.0, 1.0, PoolAim.V_BREAK, 0.0, PoolAim.BREAK_TOP)
		m.sim.run_to_rest(30.0)
		assert_int(m.sim.events_capped).override_failure_message("seed %d" % seed_value).is_equal(0)
