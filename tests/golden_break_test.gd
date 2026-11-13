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
