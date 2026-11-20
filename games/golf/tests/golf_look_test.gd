extends GdUnitTestSuite
## The visual rules that are data: the value ladder of a theme, and slow motion that leaves the
## physics bit-identical.


func test_every_world_keeps_the_value_ladder() -> void:
	var lum := GolfTheme.luminance
	for id in GolfWorlds.ids():
		var t := GolfTheme.for_world(id)
		assert_str(t.name).is_equal(id)
		# Surroundings darkest, then carpet, then rails; ball and cup rim brightest.
		assert_float(lum.call(t.lawn)).override_failure_message(id).is_less(lum.call(t.carpet))
		assert_float(lum.call(t.carpet)).override_failure_message(id).is_less(lum.call(t.rail_body))
		assert_float(lum.call(t.rail_body)).is_less(lum.call(t.ball))
		assert_float(lum.call(t.rail_cap)).is_less_equal(lum.call(t.ball))
		# No flower may compete with the ball's white.
		for f in t.flowers:
			assert_float(lum.call(f)).override_failure_message(id).is_less(lum.call(t.ball) * 0.75)


func test_every_world_dresses_with_shipped_models() -> void:
	var dir := "res://games/golf/assets/kenney_nature/"
	var known := [
		"logs", "mushrooms", "planters", "rocks", "canoe", "columns", "cactus", "campfire"
	]
	for id in GolfWorlds.ids():
		var t := GolfTheme.for_world(id)
		var landmarks := ["windmill", "lighthouse", "arch", "volcano"]
		assert_bool(t.landmark in landmarks).override_failure_message(t.landmark).is_true()
		var models: Array = t.bushes + t.flower_models
		for tree: Array in t.trees:
			models.append(tree[0])
			assert_float(float(tree[1])).is_less_equal(float(tree[2]))
		for m: String in models:
			(
				assert_bool(ResourceLoader.exists(dir + m + ".glb"))
				. override_failure_message(m)
				. is_true()
			)
		for v: String in t.vignettes:
			assert_bool(v in known).override_failure_message(v).is_true()


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


func test_every_kit_material_has_a_theme_colour_below_the_ball() -> void:
	# Every material name used by the shipped kit props is mapped (no stock colours, no magenta),
	# and no prop is as bright as the ball; fence / planter wood stays darker than the rails.
	var lum := GolfTheme.luminance
	var dir := "res://games/golf/assets/kenney_nature/"
	var names := {}
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".glb"):
			continue
		var root := (load(dir + f) as PackedScene).instantiate()
		for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var mat := mi.mesh.surface_get_material(i)
				names[mat.resource_name if mat != null else mi.mesh.surface_get_name(i)] = true
		root.free()
	assert_int(names.size()).is_greater(5)
	for id in GolfWorlds.ids():
		var t := GolfTheme.for_world(id)
		for n: String in names:
			var c := t.kit_color(n)
			var msg := "%s: %s" % [id, n]
			assert_bool(c == Color.MAGENTA).override_failure_message("unmapped " + msg).is_false()
			assert_float(lum.call(c)).override_failure_message(msg).is_less(lum.call(t.ball) * 0.75)
		assert_float(lum.call(t.kit_color("wood"))).is_less(lum.call(t.rail_body))


func test_forecast_matches_a_full_run_without_a_long_frame() -> void:
	var d := MiniBaker.bake(MiniBaker.load_spec("res://games/golf/data/mini/meadow_01.json"))
	var pr := CoursePreset.new()
	pr.stimp = 9.0
	# A gentle straight putt from 1 m in front of the cup (drops), and a long tee shot.
	for shot in [[d.pin.x, d.pin.z + 1.0, 0.0, -1.2], [d.tee.x, d.tee.z, 0.0, -6.0]]:
		var full := GolfBall.new(d, pr)
		full.putt(shot[0], shot[1], shot[2], shot[3])
		full.run_to_rest()
		var copy := GolfBall.new(d, pr)
		copy.putt(shot[0], shot[1], shot[2], shot[3])
		var f := ShotForecast.new()
		f.start(copy)
		var ticks := 0
		while not f.ready and ticks < 100000:
			f.advance()
			ticks += 1
		var substeps := int(ceil(full.time / GolfFlight.SUBSTEP))
		# Never more than STEPS_PER_TICK substeps in one tick: 10x faster than real play.
		assert_int(ticks).is_greater_equal(substeps / ShotForecast.STEPS_PER_TICK)
		var want := full.time if full.phase == GolfBall.Phase.HOLED else -1.0
		assert_float(f.hole_at).is_equal(want)
	var near := GolfBall.new(d, pr)
	near.putt(d.pin.x, d.pin.z + 1.0, 0.0, -1.2)
	near.run_to_rest()
	assert_int(near.phase).is_equal(GolfBall.Phase.HOLED)


## Rail shading near the rails only (hole loading, 2026-11-20) equals the per-vertex scan over
## every rail, on every vertex of a few holes from each world.
func test_rail_shading_grid_matches_the_full_scan() -> void:
	for id in GolfWorlds.ids():
		for p in GolfWorlds.holes(id).slice(0, 3):
			var d := MiniBaker.bake(MiniBaker.load_spec(p))
			var t: GolfTerrain = auto_free(GolfTerrain.new())
			t.hole = d
			var w := d.nx / GolfTerrain.STEP + 1
			var h := d.nz / GolfTerrain.STEP + 1
			t._ao_near_rails(w, h)
			# Both end up as a float32 vertex colour: compare them as the mesh stores them.
			var worst := 0.0
			for j in h:
				for i in w:
					var fast := Color(t._ao_at(i, j), 0, 0).r
					var full := Color(t._ao(t._vertex(i, j)), 0, 0).r
					worst = maxf(worst, absf(fast - full))
			assert_float(worst).override_failure_message(p).is_equal(0.0)
