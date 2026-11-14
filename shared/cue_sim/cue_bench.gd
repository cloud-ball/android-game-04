class_name CueBench
extends RefCounted
## Solver benchmark + determinism fingerprint, runnable on desktop and on the phone
## (Boot --bench=cue). Prints "[cue-bench]" lines: microseconds per substep, milliseconds per
## shot to rest at the live 1/240 s step and the 1/120 s AI planning step, and a hash of the
## golden break's final state (compare desktop vs Android for bit-exact cross-platform play).

const GOLDEN_SEED := 7
const GOLDEN_SPEED := 9.0


## The golden break: fixed rack seed + cue velocity, run to rest.
static func golden_break() -> CueSim:
	var sim := CueSim.new()
	PoolRack.setup(sim, GOLDEN_SEED)
	sim.strike(0.0, 1.0, GOLDEN_SPEED)
	sim.run_to_rest()
	return sim


## Full-precision fingerprint of a resting table (positions, pockets).
static func fingerprint(sim: CueSim) -> String:
	var parts := PackedStringArray()
	for i in CueSim.N:
		parts.append("%d:%.17f,%.17f,%d" % [i, sim.px[i], sim.py[i], sim.pocket_of[i]])
	return ",".join(parts)


static func run() -> void:
	var golden := golden_break()
	print("[cue-bench] golden break hash %s" % fingerprint(golden).md5_text())
	for step_name in ["live 1/240", "plan 1/120"]:
		var total_us := 0
		var total_substeps := 0
		var shots := 6
		for s in shots:
			var sim := CueSim.new()
			if step_name.begins_with("plan"):
				sim.substep = CueSim.SUBSTEP * 2.0
			PoolRack.setup(sim, 100 + s)
			var dx := 0.02 * (s - 2.5)
			sim.strike(dx, sqrt(1.0 - dx * dx), 6.0 + s, 0.1 * (s % 3 - 1), 0.0)
			var t0 := Time.get_ticks_usec()
			var t := sim.run_to_rest(30.0)
			total_us += Time.get_ticks_usec() - t0
			total_substeps += int(t / sim.substep + 0.5)
		print(
			(
				"[cue-bench] %s: %.1f us/substep, %.1f ms per break-like shot (%d shots)"
				% [step_name, float(total_us) / total_substeps, total_us / 1000.0 / shots, shots]
			)
		)
	# A typical mid-game shot: few balls, cue ball + one object ball moving.
	var t1 := Time.get_ticks_usec()
	var n := 10
	for s in n:
		var sim := CueSim.new()
		sim.substep = CueSim.SUBSTEP * 2.0
		PoolRack.setup(sim, 200 + s)
		for i in range(9, 16):
			sim.phase[i] = CueSim.POCKETED
		sim.place(0, 0.1, -0.3)
		sim.strike(0.3, 0.9539392014, 2.5, 0.0, -0.2)
		sim.run_to_rest(30.0)
	print(
		(
			"[cue-bench] plan 1/120 mid-game shot: %.1f ms each"
			% ((Time.get_ticks_usec() - t1) / 1000.0 / n)
		)
	)
