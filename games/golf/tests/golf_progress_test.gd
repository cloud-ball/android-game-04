extends GdUnitTestSuite
## Cup Dash progression: save migration 1 -> 2, stars, unlocks, records, coins, daily goals.


func test_schema_1_save_migrates_and_keeps_its_stats() -> void:
	var old := {"schema": 1, "played": 5, "wins": 2, "losses": 3, "difficulty": "hard"}
	var g := SaveService.prepare_namespace(
		old, GolfProgress.SCHEMA, GolfProgress.DEFAULTS, GolfProgress.migrate
	)
	assert_int(int(g["schema"])).is_equal(2)
	assert_int(int(g["wins"])).is_equal(2)
	assert_str(g["difficulty"]).is_equal("hard")
	assert_that(g["unlocked"]).is_equal(["meadow"])
	assert_that(g["stars"]).is_equal({})


func test_a_save_without_golf_gets_defaults() -> void:
	var g := SaveService.prepare_namespace(
		null, GolfProgress.SCHEMA, GolfProgress.DEFAULTS, GolfProgress.migrate
	)
	assert_str(g["mode"]).is_equal("rush")
	assert_bool(GolfProgress.is_unlocked(g, "meadow")).is_true()


func test_stars_per_hole() -> void:
	assert_int(GolfProgress.stars(1, 3)).is_equal(3)  # ace
	assert_int(GolfProgress.stars(1, 2)).is_equal(3)  # ace on a par 2
	assert_int(GolfProgress.stars(2, 4)).is_equal(3)  # eagle
	assert_int(GolfProgress.stars(2, 3)).is_equal(2)  # birdie
	assert_int(GolfProgress.stars(3, 3)).is_equal(1)  # par
	assert_int(GolfProgress.stars(4, 3)).is_equal(0)  # bogey
	assert_int(GolfProgress.stars(3, 3, false)).is_equal(0)  # not holed


func test_unlocks_follow_the_world_order_once() -> void:
	var g := GolfProgress.DEFAULTS.duplicate(true)
	var ids := GolfWorlds.ids()
	if ids.size() < 2:
		assert_str(GolfProgress.unlock_next(g, ids[0])).is_equal("")
		return
	assert_str(GolfProgress.unlock_next(g, ids[0])).is_equal(ids[1])
	assert_str(GolfProgress.unlock_next(g, ids[0])).is_equal("")  # already open
	assert_bool(GolfProgress.is_unlocked(g, ids[1])).is_true()


func test_records_keep_the_best() -> void:
	var g := GolfProgress.DEFAULTS.duplicate(true)
	assert_int(GolfProgress.record_stars(g, "meadow_01", 2)).is_equal(2)
	assert_int(GolfProgress.record_stars(g, "meadow_01", 1)).is_equal(0)
	assert_int(GolfProgress.record_stars(g, "meadow_01", 3)).is_equal(1)
	assert_bool(GolfProgress.record_tour(g, "meadow", 4)).is_true()
	assert_bool(GolfProgress.record_tour(g, "meadow", 6)).is_false()
	assert_bool(GolfProgress.record_tour(g, "meadow", -1)).is_true()


func test_coins() -> void:
	assert_int(GolfProgress.rush_coins("hard", 2, true)).is_equal(2 * 10 + 120)
	assert_int(GolfProgress.rush_coins("easy", 1, false)).is_equal(10)
	assert_int(GolfProgress.tour_coins(7)).is_equal(25 + 35)


func test_golf_daily_challenges() -> void:
	var by_id := {}
	for c in DailyChallenge.LIST:
		by_id[c.id] = c
	var win_easy := GolfProgress.daily_stats("rush", "easy", true, 0, 0)
	assert_bool(DailyChallenge.is_met(by_id["golf_win_rush"], win_easy)).is_true()
	assert_bool(DailyChallenge.is_met(by_id["golf_win_medium"], win_easy)).is_false()
	var tour := GolfProgress.daily_stats("tour", "medium", false, 3, 1)
	assert_bool(DailyChallenge.is_met(by_id["golf_birdies_3"], tour)).is_true()
	assert_bool(DailyChallenge.is_met(by_id["golf_ace"], tour)).is_true()
	assert_bool(DailyChallenge.is_met(by_id["golf_win_rush"], tour)).is_false()


func test_tour_card_totals() -> void:
	var card := GolfTourCard.new()
	assert_int(card.add("m1", 2, 1, true)).is_equal(3)  # ace
	assert_int(card.add("m2", 3, 2, true)).is_equal(2)  # birdie
	assert_int(card.add("m3", 3, 6, false)).is_equal(0)  # out of strokes
	assert_int(card.holes_played()).is_equal(3)
	assert_int(card.strokes()).is_equal(9)
	assert_int(card.over_par()).is_equal(1)
	assert_int(card.stars()).is_equal(5)
	assert_int(card.birdies()).is_equal(2)  # one under par: the par-2 ace counts too
	assert_int(card.aces()).is_equal(1)
