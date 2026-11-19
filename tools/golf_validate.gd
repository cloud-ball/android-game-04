extends SceneTree
## Fairway Flick hole validator: for every hole of a world (or all), prints the route length, the
## strokes the Hard CPU needs with perfect execution (must be <= par), and a sweep of 144 tee
## shots (all must stop, in under 20 s, with fewer than 15 bounces).
## Run: godot --headless --path . -s res://tools/golf_validate.gd -- [world]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var paths := GolfWorlds.holes(args[0]) if args.size() > 0 else GolfWorlds.all_holes()
	var preset := CoursePreset.new()
	preset.stimp = 9.0
	var bad := 0
	print("hole                 par  route_m  cpu_strokes  sweep(max_t, max_bounce, stuck)")
	for p in paths:
		var spec := MiniBaker.load_spec(p)
		var hole := MiniBaker.bake(spec)
		var field := MiniBaker.flow_field(spec)
		var route := MiniBaker.flow_metres(spec, field, hole.tee)
		var strokes := _cpu_strokes(hole, preset, spec)
		var sweep := _sweep(hole, preset)
		var ok: bool = route < 1e5 and strokes <= hole.par and sweep[2] == 0 and sweep[0] < 20.0
		ok = ok and sweep[1] < 15
		if not ok:
			bad += 1
		print(
			(
				"%-20s %3d  %7.0f  %11s  (%.1f s, %d, %d)%s"
				% [
					p.get_file().get_basename() + " " + str(spec.get("name", "")),
					hole.par,
					route,
					str(strokes) if strokes < 99 else "no",
					sweep[0],
					sweep[1],
					sweep[2],
					"" if ok else "   <-- FAIL"
				]
			)
		)
	print("golf-validate: %d holes, %d failing" % [paths.size(), bad])
	quit()


## Hard CPU's best shots with no aim / speed error, until holed (99 = gave up).
func _cpu_strokes(hole: HoleData, preset: CoursePreset, spec: Dictionary) -> int:
	var cpu := GolfCpu.new(hole, preset, spec)
	var rng := RandomNumberGenerator.new()
	var r := GolfBall.new(hole, preset).p.radius
	var at := hole.tee + Vector3(0, r, 0)
	for s in range(1, 10):
		var v := GolfCpu.pick_with(cpu.ranked(at), 1, 0.0, 0.0, rng)
		var b := GolfBall.new(hole, preset)
		b.putt(at.x, at.z, v.x, v.y)
		b.run_to_rest()
		match b.phase:
			GolfBall.Phase.HOLED:
				return s
			GolfBall.Phase.WATER:
				var q := b.last_safe
				at = Vector3(q.x, hole.height(q.x, q.z) + r, q.z)
			GolfBall.Phase.OUT:
				pass
			_:
				at = b.pos()
	return 99


## [max time, max bounces, shots that never stopped] over 24 directions x 6 speeds from the tee.
func _sweep(hole: HoleData, preset: CoursePreset) -> Array:
	var max_t := 0.0
	var max_b := 0
	var stuck := 0
	for ai in 24:
		var a := TAU * ai / 24.0
		for vi in 6:
			var v := 1.0 + vi * 2.4
			var b := GolfBall.new(hole, preset)
			b.putt(hole.tee.x, hole.tee.z, cos(a) * v, sin(a) * v)
			b.run_to_rest(1.0 / 120.0)
			if not b.done():
				stuck += 1
			max_t = maxf(max_t, b.time)
			max_b = maxi(max_b, b.events.count(GolfBall.Ev.BOUNCE))
	return [max_t, max_b, stuck]
