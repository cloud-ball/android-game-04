extends SceneTree
## Headless self-play for Serpent Grid difficulty tuning.
## The CPU (each difficulty's data file) plays a fixed baseline "player" profile.
## Run: godot --headless --path . -s res://tools/snake_selfplay.gd -- [matches]
##      [wander,avoid,hunt,squeeze,blunder ...]
## Targets (CPU win rate vs baseline): easy ~25%, medium ~50%, hard ~70%.

const BASELINE := {"wander": 0.12, "avoid_heads": true, "hunt": 0.0, "squeeze": 1.0, "blunder": 0.0}
const MAX_TICKS := 1500


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var matches := int(args[0]) if args.size() > 0 else 200
	if args.size() > 1:
		for spec in args.slice(1):
			var parts := spec.split(",")
			var cfg := SnakeConfig.for_difficulty("medium")
			cfg.ai_wander = float(parts[0])
			cfg.ai_avoid_heads = parts.size() <= 1 or parts[1] == "1"
			cfg.ai_hunt = float(parts[2]) if parts.size() > 2 else 0.0
			cfg.ai_squeeze = float(parts[3]) if parts.size() > 3 else 1.0
			cfg.ai_blunder = float(parts[4]) if parts.size() > 4 else 0.0
			_report(spec, cfg, matches)
	else:
		for d in ["easy", "medium", "hard"]:
			_report(d, SnakeConfig.for_difficulty(d), matches)
	quit()


func _report(label: String, cfg: SnakeConfig, matches: int) -> void:
	var cpu_wins := 0
	var player_wins := 0
	var draws := 0
	var ticks := 0
	for m in matches:
		var g := SnakeLogic.new(cfg, 1000 + m, true)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77 + m
		while not g.is_over() and g.tick_count < MAX_TICKS:
			g.queue_turn(0, SnakeAI.choose(g, 0, rng, BASELINE))
			g.queue_turn(1, SnakeAI.choose(g, 1, rng))
			g.step()
		ticks += g.tick_count
		match g.result:
			SnakeLogic.Result.CPU_WON:
				cpu_wins += 1
			SnakeLogic.Result.PLAYER_WON:
				player_wins += 1
			_:
				draws += 1
	print(
		(
			"%-8s cpu_win %5.1f%%  player_win %5.1f%%  draw/timeout %5.1f%%  avg ticks %d"
			% [
				label,
				100.0 * cpu_wins / matches,
				100.0 * player_wins / matches,
				100.0 * draws / matches,
				ticks / matches
			]
		)
	)
