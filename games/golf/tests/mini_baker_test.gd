extends GdUnitTestSuite
## MiniBaker: tile maps -> walled holes; ramps, jumps, flow field and a scripted solvability check.

const R := 0.021335

var holes := GolfWorlds.all_holes()


static func spec(path: String) -> Dictionary:
	return MiniBaker.load_spec(path)


static func preset() -> CoursePreset:
	var pr := CoursePreset.new()
	pr.stimp = 9.0
	return pr


func test_bakes_are_deterministic_and_tee_cup_placed() -> void:
	for p in holes:
		var a := MiniBaker.bake(spec(p))
		var b := MiniBaker.bake(spec(p))
		(
			assert_bool(a.heights == b.heights and a.surface == b.surface and a.walls == b.walls)
			. is_true()
		)
		assert_int(a.surface_at(a.tee.x, a.tee.z)).is_equal(HoleData.Surface.GREEN)
		assert_int(a.surface_at(a.pin.x, a.pin.z)).is_equal(HoleData.Surface.GREEN)
		assert_int(a.walls.size() / 4).is_greater(3)


func test_ramp_heights_and_open_top() -> void:
	var s := spec(holes[1])
	var d := MiniBaker.bake(s)
	# Ramp tile (row 3, col 2): z from -12 (top, high) to -9 (bottom, low); x centre 0.
	assert_float(d.height(0.0, -9.05)).is_less(0.05)
	assert_float(d.height(0.0, -11.95)).is_greater(0.35)
	assert_float(d.height(0.0, -13.5)).is_equal_approx(MiniBaker.LEVEL_H, 1e-6)
	# A ball rolled up the ramp reaches the upper green (no wall at the ramp top).
	var b := GolfBall.new(d, preset())
	b.putt(0.0, -7.5, 0.0, -6.0)
	b.run_to_rest()
	assert_float(b.pos().z).is_less(-12.0)


func test_a_fast_shot_clears_the_jump_and_a_slow_one_falls_in() -> void:
	var d := MiniBaker.bake(spec(holes[2]))
	var fast := GolfBall.new(d, preset())
	fast.putt(0.0, -4.5, 0.0, -11.0)
	fast.run_to_rest()
	assert_bool(GolfBall.Ev.HOP in fast.events).is_true()
	assert_int(fast.phase).is_not_equal(GolfBall.Phase.OUT)
	assert_float(fast.pos().z).is_less(-12.0)
	var slow := GolfBall.new(d, preset())
	slow.putt(0.0, -4.5, 0.0, -5.0)
	slow.run_to_rest()
	assert_bool(slow.phase == GolfBall.Phase.OUT or slow.pos().z > -12.0).is_true()


func test_balls_stay_inside_the_walls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for p in holes.slice(0, 2):
		var d := MiniBaker.bake(spec(p))
		for k in 25:
			var b := GolfBall.new(d, preset())
			var a := rng.randf_range(0.0, TAU)
			var v := rng.randf_range(2.0, 14.0)
			b.putt(d.tee.x, d.tee.z, cos(a) * v, sin(a) * v)
			b.run_to_rest(1.0 / 60.0)
			assert_int(b.phase).override_failure_message("%s shot %d" % [p, k]).is_not_equal(
				GolfBall.Phase.OUT
			)


func test_flow_field_reaches_the_tee() -> void:
	for p in holes:
		var s := spec(p)
		var f := MiniBaker.flow_field(s)
		var d := MiniBaker.bake(s)
		assert_float(flow_at(s, f, d.tee.x, d.tee.z)).override_failure_message(p).is_greater(0.0)


## Flow distance (m) from a point to the cup: tile distance + distance inside the tile.
static func flow_at(s: Dictionary, f: PackedFloat64Array, x: float, z: float) -> float:
	var tile := float(s.get("tile", 3.0))
	var rows: int = s.map.size()
	var cols := 0
	for r in s.map:
		cols = maxi(cols, str(r).length())
	var c := int(floorf((x + cols * tile * 0.5) / tile))
	var r2 := int(floorf((z + rows * tile) / tile))
	if c < 0 or r2 < 0 or c >= cols or r2 >= rows:
		return -1.0
	return f[r2 * cols + c]


## Every hole can be played within par: the Hard CPU golfer, with no aim or speed error, holes
## out in par strokes or fewer (step F gate; tools/golf_validate.gd prints the full table).
func test_every_hole_is_playable_within_par() -> void:
	for p in holes:
		var s := spec(p)
		var d := MiniBaker.bake(s)
		var cpu := GolfCpu.new(d, preset(), s)
		var rng := RandomNumberGenerator.new()
		var r := GolfBall.new(d, preset()).p.radius
		var at := d.tee + Vector3(0, r, 0)
		var strokes := 0
		var holed := false
		while strokes < d.par and not holed:
			strokes += 1
			var v := GolfCpu.pick_with(cpu.ranked(at), 1, 0.0, 0.0, rng)
			var b := GolfBall.new(d, preset())
			b.putt(at.x, at.z, v.x, v.y)
			b.run_to_rest()
			holed = b.phase == GolfBall.Phase.HOLED
			if b.phase == GolfBall.Phase.REST:
				at = b.pos()
			elif b.phase == GolfBall.Phase.WATER:
				var q := d.water_drop(b.last_safe, d.tee)
				at = Vector3(q.x, q.y + r, q.z)
		(
			assert_bool(holed)
			. override_failure_message("%s not holed within par %d" % [p, d.par])
			. is_true()
		)


## Regression (phone feedback "stuck / bad bouncing" on the par 3s): every shot from every tee comes
## to rest quickly without chattering.
func test_every_shot_finishes_without_chatter() -> void:
	for p in holes:
		var d := MiniBaker.bake(spec(p))
		for ai in 24:
			var a := TAU * ai / 24.0
			for vi in 6:
				var v := 1.0 + vi * 2.4
				var b := GolfBall.new(d, preset())
				b.putt(d.tee.x, d.tee.z, cos(a) * v, sin(a) * v)
				b.run_to_rest(1.0 / 120.0)
				var msg := "%s a %d v %.1f" % [p.get_file(), ai * 15, v]
				assert_bool(b.done()).override_failure_message(msg).is_true()
				assert_float(b.time).override_failure_message(msg).is_less(20.0)
				(
					assert_int(b.events.count(GolfBall.Ev.BOUNCE))
					. override_failure_message(msg)
					. is_less(15)
				)


## Regression: over the top of the Step Up ramp at speed the ball hops once and lands (it used to
## start the hop inside the higher floor and bounce ~70 times in place).
func test_ramp_crest_hop_lands_cleanly() -> void:
	var d := MiniBaker.bake(spec(holes[1]))
	var b := GolfBall.new(d, preset())
	var a := deg_to_rad(70.0)
	b.putt(d.tee.x, d.tee.z, cos(a) * 11.4, sin(a) * 11.4)
	b.run_to_rest()
	assert_int(b.events.count(GolfBall.Ev.BOUNCE)).is_less(10)


## Regression: a ball that stops just inside the cup's pull zone rests (it used to wait forever).
func test_ball_stopping_near_the_cup_rests_or_drops() -> void:
	var d := MiniBaker.bake(spec(holes[0]))
	for r in [0.12, 0.2, 0.3, 0.34]:
		var b := GolfBall.new(d, preset())
		b.putt(d.pin.x - r, d.pin.z, 0.0, 0.0)
		b.run_to_rest()
		assert_bool(b.done()).is_true()
		assert_float(b.time).override_failure_message("r %.2f" % r).is_less(5.0)
		if r <= 0.12:
			assert_int(b.phase).is_equal(GolfBall.Phase.HOLED)
