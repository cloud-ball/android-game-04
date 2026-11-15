extends GdUnitTestSuite
## MiniBaker: tile maps -> walled holes; ramps, jumps, flow field and a scripted solvability check.

const HOLES := [
	"res://games/golf/data/mini/meadow_01.json",
	"res://games/golf/data/mini/meadow_02.json",
	"res://games/golf/data/mini/meadow_03.json",
]
const R := 0.021335


static func spec(path: String) -> Dictionary:
	return MiniBaker.load_spec(path)


static func preset() -> CoursePreset:
	var pr := CoursePreset.new()
	pr.stimp = 9.0
	return pr


func test_bakes_are_deterministic_and_tee_cup_placed() -> void:
	for p in HOLES:
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
	var s := spec(HOLES[1])
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
	var d := MiniBaker.bake(spec(HOLES[2]))
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
	for p in HOLES.slice(0, 2):
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
	for p in HOLES:
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


## A scripted golfer (greedy on the flow field, then straight at the cup) holes out in par + 2.
func test_every_hole_is_solvable() -> void:
	for p in HOLES:
		var s := spec(p)
		var d := MiniBaker.bake(s)
		var f := MiniBaker.flow_field(s)
		var at := Vector2(d.tee.x, d.tee.z)
		var strokes := 0
		var holed := false
		while strokes < d.par + 2 and not holed:
			strokes += 1
			var best := INF
			var best_at := at
			for ai in 48:
				var a := TAU * ai / 48.0
				for vi in 10:
					var v := 1.5 + vi * 1.3
					var b := GolfBall.new(d, preset())
					b.putt(at.x, at.y, cos(a) * v, sin(a) * v)
					b.run_to_rest(1.0 / 60.0)
					if b.phase == GolfBall.Phase.HOLED:
						holed = true
						best = -1.0
						break
					if b.phase != GolfBall.Phase.REST:
						continue
					var q := b.pos()
					var fl := flow_at(s, f, q.x, q.z)
					if fl < 0.0:
						continue
					var score := fl + Vector2(q.x - d.pin.x, q.z - d.pin.z).length()
					if score < best:
						best = score
						best_at = Vector2(q.x, q.z)
				if holed:
					break
			at = best_at
		assert_bool(holed).override_failure_message("%s not holed in %d" % [p, strokes]).is_true()
