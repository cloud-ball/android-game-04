extends SceneTree
## Headless Cup Dash self-play for Rush tuning. Plays every hole K times for ONE golfer type
## (a CPU tier, or the human "baseline") and writes one CSV row per play: when the ball dropped
## (seconds since the hole started, counting thinking / aiming pauses and the real roll time) or
## that it never did (stroke cap par + 3). Rush balls never touch, so golfers can be simulated
## apart and combined afterwards (tools/golf_selfplay_report.py: head-to-head and Rush matches).
## Same solver, rules and planner as the game (GolfBall, RushMatch cap, GolfCpu).
## Run: godot --headless --path . -s res://tools/golf_selfplay.gd -- <easy|medium|hard|baseline>
##      <plays per hole> <out.csv> [aim=<deg>,speed=<frac>,k=<top k>] (tier knob overrides, tuning)

## The human proxy: a decent player who plans well but aims by hand (slower, less exact).
const BASE_AIM_DEG := 2.0
const BASE_SPEED_SIGMA := 0.06
const BASE_PAUSE := [2.3, 3.8]  # seconds between the ball stopping and the next shot

var holes := GolfWorlds.all_holes()
var knobs := {}  # tuning overrides for a CPU tier: aim (deg), speed (fraction), k (top k)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var who := args[0] if args.size() > 0 else "medium"
	var plays := int(args[1]) if args.size() > 1 else 20
	var out_path := args[2] if args.size() > 2 else "user://golf_selfplay_%s.csv" % who
	if args.size() > 3:
		for kv in args[3].split(",", false):
			var pair := kv.split("=")
			knobs[pair[0]] = float(pair[1])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_line("who,hole,run,holed,time,strokes")
	var preset := CoursePreset.new()
	preset.stimp = 9.0
	var t0 := Time.get_ticks_msec()
	for h in holes.size():
		var spec := MiniBaker.load_spec(holes[h])
		var hole := MiniBaker.bake(spec)
		var cpu := GolfCpu.new(hole, preset, spec)
		for run in plays:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1000 * (h + 1) + run * 7 + (17 if who == "baseline" else 0)
			var r := _play(cpu, hole, preset, who, rng)
			f.store_line("%s,%d,%d,%d,%.3f,%d" % [who, h, run, r[0], r[1], r[2]])
		print(
			"[golf-selfplay] %s hole %d done (%d s)" % [who, h, (Time.get_ticks_msec() - t0) / 1000]
		)
	f.close()
	quit()


## One golfer's hole: [holed 0/1, time of the drop, strokes].
func _play(
	cpu: GolfCpu, hole: HoleData, preset: CoursePreset, who: String, rng: RandomNumberGenerator
) -> Array:
	var tiers := {
		"easy": GolfCpu.Tier.EASY, "medium": GolfCpu.Tier.MEDIUM, "hard": GolfCpu.Tier.HARD
	}
	var radius := GolfBall.new(hole, preset).p.radius
	var at := hole.tee + Vector3(0, radius, 0)
	var t := 0.0
	var strokes := 0
	while strokes < hole.par + RushMatch.CAP_OVER_PAR:
		var v: Vector2
		if who == "baseline":
			t += rng.randf_range(BASE_PAUSE[0], BASE_PAUSE[1])
			v = GolfCpu.pick_with(cpu.ranked(at), 1, BASE_AIM_DEG, BASE_SPEED_SIGMA, rng)
		else:
			var tier: int = tiers[who]
			var span: Array = GolfCpu.THINK_S[tier]
			t += rng.randf_range(span[0], span[1])
			var aim: float = knobs.get("aim", GolfCpu.AIM_SIGMA_DEG[tier])
			var sp: float = knobs.get("speed", GolfCpu.SPEED_SIGMA[tier])
			var k := int(knobs.get("k", GolfCpu.TOP_K[tier]))
			v = GolfCpu.pick_with(cpu.ranked(at), k, aim, sp, rng)
		strokes += 1
		var b := GolfBall.new(hole, preset)
		b.putt(at.x, at.z, v.x, v.y)
		b.run_to_rest()
		t += b.time
		match b.phase:
			GolfBall.Phase.HOLED:
				return [1, t, strokes]
			GolfBall.Phase.WATER:
				strokes += 1
				var q := hole.water_drop(b.last_safe, hole.tee)
				at = Vector3(q.x, q.y + radius, q.z)
			GolfBall.Phase.OUT:
				strokes += 1
			_:
				at = b.pos()
	return [0, t, strokes]
