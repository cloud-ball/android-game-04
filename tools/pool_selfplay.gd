extends SceneTree
## Headless Break & Bank self-play: CPU levels vs reference "greedy" players (best straight shot,
## Gaussian aim error), alternating breaks, same rack seeds for both sides of a pairing.
## Prints win rate, shots per game, pot rate and the planner's decision time.
## Run: godot --headless --path . -s res://tools/pool_selfplay.gd -- [games]

const REFS := {"casual": 0.6, "average": 0.3}
const PAIRINGS := [
	["easy", "casual"],
	["easy", "average"],
	["medium", "average"],
	["hard", "average"],
	["hard", "casual"]
]
const MAX_SHOTS := 200


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games := int(args[0]) if args.size() > 0 else 40
	print("pairing            cpu_win  shots/game  cpu_pot%  ref_pot%  think_ms")
	for p in PAIRINGS:
		_pairing(p[0], p[1], games)
	quit()


func _pairing(level: String, ref: String, games: int) -> void:
	var wins := 0
	var shots := 0
	var pots := [0, 0]
	var tries := [0, 0]
	var think_us := 0
	var thinks := 0
	for g in games:
		var breaker := g % 2
		var m := PoolMatch.new(3000 + g, breaker)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77 + g
		while not m.over() and m.shots < MAX_SHOTS:
			var who := m.state.shooter  # 0 = CPU level, 1 = reference
			var t0 := Time.get_ticks_usec()
			var plan := (
				PoolCpu.plan(m, level, rng)
				if who == 0
				else PoolCpu.plan(m, "hard", rng, false, float(REFS[ref]))
			)
			if who == 0:
				think_us += Time.get_ticks_usec() - t0
				thinks += 1
			if plan.place != null:
				var p: Vector2 = plan.place
				m.place_cue(p.x, p.y)
			if PoolRules.requires_call(m.state):
				m.call_pocket(maxi(0, int(plan.pocket)))
			var d: Vector2 = plan.dir
			var r := m.shoot(d.x, d.y, plan.speed, plan.side, plan.top)
			if r == null:
				break
			var potted := 0
			for q in PoolShot.from_sim(m.sim).pocketed:
				if q[0] != 0:
					potted += 1
			tries[who] += 1
			pots[who] += 1 if potted > 0 and not r.foul() else 0
		shots += m.shots
		if m.over() and m.state.winner == 0:
			wins += 1
	print(
		(
			"%-6s vs %-8s  %5.0f%%  %10.1f  %7.0f%%  %7.0f%%  %8.0f"
			% [
				level,
				ref,
				100.0 * wins / games,
				float(shots) / games,
				100.0 * pots[0] / maxf(1, tries[0]),
				100.0 * pots[1] / maxf(1, tries[1]),
				think_us / 1000.0 / maxf(1, thinks)
			]
		)
	)
