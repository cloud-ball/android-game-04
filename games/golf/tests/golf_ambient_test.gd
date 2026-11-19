extends GdUnitTestSuite
## Ambient life is render-only but its data rules are testable: sway weights keep bases planted,
## and critter paths are pure functions of time that stay where they belong.


func test_tree_sway_weights_run_from_base_to_top() -> void:
	var w := KitBatch.weights("tree_oak")
	assert_int(w.size()).is_greater(0)
	var lo := INF
	var hi := -INF
	for x in w:
		lo = minf(lo, x)
		hi = maxf(hi, x)
	assert_float(lo).is_less(0.05)
	assert_float(hi).is_greater(0.95)
	assert_float(hi).is_less_equal(1.0)


func test_models_are_de_indexed_into_whole_triangles() -> void:
	for model in ["tree_oak", "plant_bush", "fence_simple", "flower_redA"]:
		assert_int(KitBatch.weights(model).size() % 3).is_equal(0)


func test_butterflies_loop_close_to_their_spot_and_above_the_lawn() -> void:
	var c := Vector3(3.0, -0.3, -4.0)
	for k in AmbientLife.BUTTERFLIES:
		for step in 400:
			var p := AmbientLife.butterfly_at(c, k, step * 0.05)
			assert_float(Vector2(p.x - c.x, p.z - c.z).length()).is_less(1.5)
			assert_float(p.y - c.y).is_between(0.3, 1.0)


func test_critter_paths_are_pure_functions_of_time() -> void:
	var c := Vector3(1, 2, 3)
	assert_vector(AmbientLife.butterfly_at(c, 2, 7.25)).is_equal(
		AmbientLife.butterfly_at(c, 2, 7.25)
	)
	assert_vector(AmbientLife.bird_at(c, 1, 3.5)).is_equal(AmbientLife.bird_at(c, 1, 3.5))
	# Birds keep a wide ring round the landmark, never diving into it.
	for step in 200:
		var p := AmbientLife.bird_at(c, 3, step * 0.3)
		assert_float(Vector2(p.x - c.x, p.z - c.z).length()).is_greater(20.0)


func test_a_batch_holds_every_placed_copy() -> void:
	var batch := KitBatch.new()
	batch.add("tree_oak", Transform3D(Basis(), Vector3(0, 0, 0)))
	batch.add("tree_oak", Transform3D(Basis().scaled(Vector3.ONE * 5.0), Vector3(9, 0, 2)))
	var parent: Node3D = auto_free(Node3D.new())
	var mi := batch.build(parent, GolfTheme.meadow())
	var total := 0
	for i in mi.mesh.get_surface_count():
		total += (mi.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	assert_int(mi.mesh.get_surface_count()).is_equal(2)  # leaves, bark: one surface each
	assert_int(total).is_equal(2 * KitBatch.weights("tree_oak").size())
