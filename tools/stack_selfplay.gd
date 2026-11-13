extends SceneTree
## Headless self-play for Stack Drop difficulty tuning (vs CPU matches, fixed 60 Hz steps).
## Each difficulty's CPU (StackDifficulty) plays simulated
## human profiles. Reports CPU win rate, match length, lines and the AI's planning cost.
## Run: godot --headless --path . -s res://tools/stack_selfplay.gd -- [matches]
##      [start,think,top_k,noise,hold ...]   (try CPU settings instead of the shipped ones)

const STEP := 1.0 / 60.0
const MAX_SECONDS := 600.0
## Simulated players: seconds per shard, how many top options they pick from, judgement noise.
const PROFILES := {
	"casual": {"think": 2.6, "top_k": 4, "noise": 1.6, "hold": false},
	"average": {"think": 1.9, "top_k": 3, "noise": 0.9, "hold": true},
	"good": {"think": 1.3, "top_k": 2, "noise": 0.4, "hold": true},
}

var _plan_us := 0
var _plans := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var matches := int(args[0]) if args.size() > 0 else 30
	print(
		(
			"board %d x %d, %d matches per cell"
			% [StackState.W, StackState.H - StackState.HIDDEN, matches]
		)
	)
	print("difficulty  player    cpu_win  avg_min  cpu_lines/min  player_lines/min")
	var specs := args.slice(1)
	if specs.is_empty():
		for d in ["easy", "medium", "hard"]:
			for p in PROFILES:
				_report(d, StackDifficulty.LEVELS[d], p, matches)
	for spec in specs:
		var v: PackedStringArray = spec.split(",")
		var lv := {
			"start": int(v[0]),
			"think": float(v[1]),
			"top_k": int(v[2]),
			"noise": float(v[3]),
			"hold": v[4] == "1",
		}
		for p in PROFILES:
			_report(spec, lv, p, matches)
	print(
		(
			"AI plan cost: %.1f ms average over %d plans (desktop, single thread)"
			% [_plan_us / 1000.0 / maxf(1.0, _plans), _plans]
		)
	)
	quit()


func _report(label: String, lv: Dictionary, profile: String, matches: int) -> void:
	var cpu_wins := 0
	var secs := 0.0
	var cpu_lines := 0
	var player_lines := 0
	for m in matches:
		var r := _match(lv, profile, 4000 + m)
		cpu_wins += 1 if r.cpu_won else 0
		secs += r.seconds
		cpu_lines += r.cpu_lines
		player_lines += r.player_lines
	var minutes := secs / 60.0
	print(
		(
			"%-10s  %-8s  %5.0f%%  %7.1f  %13.1f  %16.1f"
			% [
				label,
				profile,
				100.0 * cpu_wins / matches,
				minutes / matches,
				cpu_lines / maxf(0.01, minutes),
				player_lines / maxf(0.01, minutes)
			]
		)
	)


func _match(lv: Dictionary, profile: String, seed_value: int) -> Dictionary:
	var pr: Dictionary = PROFILES[profile]
	var player := StackLogic.new_game(seed_value, int(lv.start))
	var cpu := StackLogic.new_game(seed_value, int(lv.start))
	var cpu_rng := RandomNumberGenerator.new()
	cpu_rng.seed = seed_value * 7 + 1
	var p_rng := RandomNumberGenerator.new()
	p_rng.seed = seed_value * 13 + 5
	var cpu_t := 0.0
	var p_t := 0.0
	var t := 0.0
	while t < MAX_SECONDS and not player.over and not cpu.over:
		t += STEP
		player = StackLogic.reduce(player, {"type": "tick", "dt": STEP})
		p_t += STEP
		if p_t >= float(pr.think) and not player.over:
			p_t = 0.0
			player = _place(player, p_rng, pr)
			if player.outgoing > 0:
				cpu = StackLogic.reduce(cpu, {"type": "garbage", "rows": player.outgoing})
		cpu_t += STEP
		var think := StackDifficulty.think_at(float(lv.think), cpu.level)
		if cpu_t >= think and not cpu.over:
			cpu_t = 0.0
			cpu = _place(cpu, cpu_rng, lv)
			if cpu.outgoing > 0:
				player = StackLogic.reduce(player, {"type": "garbage", "rows": cpu.outgoing})
	return {
		"cpu_won": player.over and not cpu.over,
		"seconds": t,
		"cpu_lines": cpu.lines,
		"player_lines": player.lines,
	}


func _place(s: StackState, rng: RandomNumberGenerator, p: Dictionary) -> StackState:
	var t0 := Time.get_ticks_usec()
	var plan := StackAI.choose(s, rng, bool(p.hold), int(p.top_k), float(p.noise))
	_plan_us += Time.get_ticks_usec() - t0
	_plans += 1
	if plan.is_empty():
		return StackLogic.reduce(s, {"type": "hard"})
	for a in StackAI.actions_for(s, plan):
		s = StackLogic.reduce(s, a)
	return s
