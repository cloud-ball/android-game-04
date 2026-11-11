extends GdUnitTestSuite
## Hub-level tests: project settings, save service, registry, boot args, swipe detection.

const SaveScript := preload("res://core/SaveService.gd")
const BootScript := preload("res://core/Boot.gd")
const TEST_DIR := "user://test_saves"


func after_test() -> void:
	for f in ["save.json", "save.json.bak", "save.json.tmp"]:
		var p := ProjectSettings.globalize_path("%s/%s" % [TEST_DIR, f])
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func test_project_settings_match_guide() -> void:
	assert_str(str(ProjectSettings.get_setting("physics/3d/physics_engine"))).is_equal(
		"Jolt Physics"
	)
	(
		assert_int(int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")))
		. is_equal(60)
	)
	assert_bool(bool(ProjectSettings.get_setting("physics/common/physics_interpolation"))).is_true()
	var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	assert_str(method).is_equal("mobile")


func test_normalize_preserves_unknown_keys() -> void:
	var d := SaveScript.normalize({"future_thing": 5, "games": {"zzz": {"schema": 9}}})
	assert_int(int(d["future_thing"])).is_equal(5)
	assert_dict(d["games"]).contains_keys(["zzz"])
	assert_dict(d).contains_keys(["profile", "economy", "settings", "games"])


func test_old_save_without_game_key_gets_defaults() -> void:
	var g := SaveScript.prepare_namespace(null, 1, {"best": 0, "wins": 0})
	assert_int(int(g["schema"])).is_equal(1)
	assert_int(int(g["best"])).is_equal(0)


func test_migrate_runs_for_older_schema() -> void:
	var migrate := func(old: Dictionary, _from: int, _to: int) -> Dictionary:
		old["best_score"] = old.get("best", 0)
		old.erase("best")
		return old
	var g := SaveScript.prepare_namespace({"schema": 1, "best": 42}, 2, {"wins": 0}, migrate)
	assert_int(int(g["schema"])).is_equal(2)
	assert_int(int(g["best_score"])).is_equal(42)
	assert_int(int(g["wins"])).is_equal(0)


func test_newer_schema_is_not_downgraded() -> void:
	var g := SaveScript.prepare_namespace({"schema": 5, "x": 1}, 2, {})
	assert_int(int(g["schema"])).is_equal(5)


func test_save_roundtrip_with_backup() -> void:
	var svc: Node = auto_free(SaveScript.new())
	svc.path = TEST_DIR + "/save.json"
	svc.load_from_disk()
	svc.data["economy"]["coins"] = 10
	assert_int(svc.save()).is_equal(OK)
	svc.data["economy"]["coins"] = 20
	assert_int(svc.save()).is_equal(OK)
	var again: Node = auto_free(SaveScript.new())
	again.path = svc.path
	again.load_from_disk()
	assert_int(int(again.data["economy"]["coins"])).is_equal(20)
	var bak: Variant = JSON.parse_string(FileAccess.get_file_as_string(svc.path + ".bak"))
	assert_int(int(bak["economy"]["coins"])).is_equal(10)


func test_corrupt_save_falls_back_to_backup() -> void:
	var svc: Node = auto_free(SaveScript.new())
	svc.path = TEST_DIR + "/save.json"
	svc.load_from_disk()
	svc.data["economy"]["coins"] = 7
	svc.save()
	svc.save()
	var f := FileAccess.open(svc.path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	svc.load_from_disk()
	assert_int(int(svc.data["economy"]["coins"])).is_equal(7)


func test_registry_lists_all_eight_with_released_games_enabled() -> void:
	var list := GameRegistry.scan("res://games")
	assert_int(list.size()).is_equal(8)
	assert_str(list[0].id).is_equal("snake")
	var enabled := list.filter(func(m: GameManifest) -> bool: return m.enabled).map(
		func(m: GameManifest) -> String: return m.id
	)
	assert_array(enabled).contains_exactly_in_any_order(["snake", "blocks"])


func test_enabled_games_have_loadable_scenes() -> void:
	for m in GameRegistry.scan("res://games"):
		if m.enabled:
			assert_bool(ResourceLoader.exists(m.scene)).override_failure_message(m.scene).is_true()


func test_boot_arg_parsing() -> void:
	var o := BootScript.parse_args(
		PackedStringArray(
			["--game=snake", "--bot", "--quit-after", "300", "--shot=user://a_%d.png"]
		)
	)
	assert_str(str(o["game"])).is_equal("snake")
	assert_bool(o["bot"]).is_true()
	assert_str(str(o["quit-after"])).is_equal("300")
	assert_str(str(o["shot"])).is_equal("user://a_%d.png")


func test_swipe_detector_chains_swipes_in_one_drag() -> void:
	var s := SwipeDetector.new()
	s.threshold = 40.0
	var dirs: Array[int] = []
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(100, 100)
	s.feed(touch)
	for p in [Vector2(120, 100), Vector2(150, 102), Vector2(152, 150), Vector2(153, 170)]:
		var drag := InputEventScreenDrag.new()
		drag.position = p
		var d := s.feed(drag)
		if d != -1:
			dirs.append(d)
	assert_array(dirs).is_equal([SwipeDetector.Dir.RIGHT, SwipeDetector.Dir.DOWN])


func test_daily_challenge_only_uses_enabled_games() -> void:
	for day in 30:
		assert_str(str(DailyChallenge.for_day(day, ["snake"]).game)).is_equal("snake")
	var seen := {}
	for day in 30:
		seen[DailyChallenge.for_day(day, ["snake", "blocks"]).game] = true
	assert_bool(seen.has("blocks") and seen.has("snake")).is_true()


func test_blocks_challenges_check_their_stats() -> void:
	var lines := {"id": "blocks_lines_20", "game": "blocks"}
	assert_bool(DailyChallenge.is_met(lines, {"game": "blocks", "lines": 21})).is_true()
	assert_bool(DailyChallenge.is_met(lines, {"game": "snake", "lines": 99})).is_false()
