extends GdUnitTestSuite
## A damaged or hand-edited save must never crash a game: values of the wrong type fall back to
## their defaults (numbers may be int or float, as JSON loads them).


func test_wrong_types_in_a_game_namespace_fall_back_to_defaults() -> void:
	var defaults := {"wins": 0, "difficulty": "medium", "learned": [], "seen": false, "best": {}}
	var tampered := {
		"schema": 1, "wins": "lots", "difficulty": 3, "learned": 5, "seen": "yes", "best": []
	}
	var g := SaveService.prepare_namespace(tampered, 1, defaults)
	assert_int(g["wins"]).is_equal(0)
	assert_str(g["difficulty"]).is_equal("medium")
	assert_that(g["learned"]).is_equal([])
	assert_bool(g["seen"]).is_false()
	assert_that(g["best"]).is_equal({})


func test_right_types_are_kept_and_json_floats_count_as_numbers() -> void:
	var defaults := {"wins": 0, "difficulty": "medium", "learned": []}
	var g := SaveService.prepare_namespace(
		{"schema": 1, "wins": 7.0, "difficulty": "hard", "learned": ["tap"]}, 1, defaults
	)
	assert_float(float(g["wins"])).is_equal(7.0)
	assert_str(g["difficulty"]).is_equal("hard")
	assert_that(g["learned"]).is_equal(["tap"])


func test_settings_and_coins_survive_wrong_types() -> void:
	var keep_settings: Dictionary = SaveService.data["settings"].duplicate(true)
	var keep_economy: Dictionary = SaveService.data["economy"].duplicate(true)
	SaveService.data["settings"]["sound"] = [1, 2]
	SaveService.data["economy"]["coins"] = {"x": 1}
	assert_bool(SettingsService.sound_on()).is_true()  # default
	assert_int(Economy.coins()).is_equal(0)
	SaveService.data["economy"]["coins"] = -50.0
	assert_int(Economy.coins()).is_equal(0)  # never negative
	SaveService.data["settings"] = keep_settings
	SaveService.data["economy"] = keep_economy
