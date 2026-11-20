class_name GolfLoadBench
extends RefCounted
## Hole-load benchmark (Boot --bench=golfload [--world=<id>]): times each step of building a hole
## the way golf_game does between holes, for every hole of a world, and prints "[golf-load]"
## lines with the median and worst time per step. Runs on the phone through dev_args.txt.

static var _t := {}


static func run(parent: Node, world: String) -> void:
	_t = {}
	var preset := CoursePreset.new()
	preset.stimp = 9.0
	var theme := GolfTheme.for_world(world)
	var index := 0
	for path in GolfWorlds.holes(world):
		var t0 := Time.get_ticks_usec()
		var spec := MiniBaker.load_spec(path)
		var hole := MiniBaker.bake(spec)
		t0 = _lap("bake", t0)
		var w := Node3D.new()
		parent.add_child(w)
		var scenery := GolfScenery.new()
		w.add_child(scenery)
		scenery.build(hole, spec, 5 + index, theme)
		t0 = _lap("scenery", t0)
		var terrain := GolfTerrain.new()
		w.add_child(terrain)
		terrain.build(hole, theme)
		t0 = _lap("terrain", t0)
		MiniDressing.rails(w, hole, theme)
		t0 = _lap("rails", t0)
		MiniDressing.decor(w, hole, theme, index)
		t0 = _lap("decor", t0)
		GolfCpu.new(hole, preset, spec)
		_lap("cpu_setup", t0)
		w.free()
		index += 1
	var total := 0.0
	for k: String in _t:
		var v: Array = _t[k]
		v.sort()
		var med: float = v[v.size() / 2]
		total += med
		print("[golf-load] %-9s median %6.1f ms  worst %6.1f ms" % [k, med, v[v.size() - 1]])
	print("[golf-load] total     median %6.1f ms (%s)" % [total, world])


static func _lap(key: String, t0: int) -> int:
	var now := Time.get_ticks_usec()
	if not _t.has(key):
		_t[key] = []
	(_t[key] as Array).append((now - t0) / 1000.0)
	return now
