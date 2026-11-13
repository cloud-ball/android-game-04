class_name PoolMatch
extends RefCounted
## One Casual 8 rack: the solver plus the rules state, kept in step (pure; no nodes).
## Live play: strike(), step the sim until it rests, then settle().
## Headless: shoot() does all three.
## settle() turns the shot log into a PoolShot, applies the rules, re-spots balls, returns the cue
## ball after a scratch (ball in hand) and re-racks on a stalemate.

var sim: CueSim
var state: PoolState
var last: PoolRules.Result
var opts := {}
var rack_seed := 1
var shots := 0


func _init(seed_value := 1, breaker := 0, options := {}) -> void:
	sim = CueSim.new()
	rack_seed = seed_value
	opts = options
	state = PoolState.new_rack(breaker)
	PoolRack.setup(sim, rack_seed)


func over() -> bool:
	return state.phase == PoolState.Phase.GAME_OVER


## Places the cue ball for ball in hand (kitchen = behind the head string on the break).
## Returns false if the spot is not legal (overlap, outside the area).
func place_cue(x: float, y: float) -> bool:
	if state.ball_in_hand == PoolState.Hand.NONE or not cue_spot_ok(x, y):
		return false
	sim.place(0, x, y)
	return true


func cue_spot_ok(x: float, y: float) -> bool:
	var r := sim.p.radius
	if absf(x) > sim.table.hw - r or absf(y) > sim.table.hl - r:
		return false
	if state.ball_in_hand == PoolState.Hand.KITCHEN and y > -sim.table.hl * 0.5:
		return false
	for i in range(1, CueSim.N):
		if sim.on_table(i):
			var dx: float = sim.px[i] - x
			var dy: float = sim.py[i] - y
			if dx * dx + dy * dy < 4.0 * r * r:
				return false
	return true


func call_pocket(pocket: int) -> void:
	state = PoolRules.call_pocket(state, pocket)


## Starts a shot. Returns false (nothing happens) when the 8 needs a call first.
func strike(dir_x: float, dir_y: float, speed: float, side := 0.0, top := 0.0) -> bool:
	if over() or (PoolRules.requires_call(state) and state.called_pocket < 0):
		return false
	if not sim.on_table(0):
		_return_cue_ball()
	sim.strike(dir_x, dir_y, speed, side, top)
	return true


## After the balls stop: apply the rules and fix up the table. Returns the rules result.
func settle() -> PoolRules.Result:
	var shot := PoolShot.from_sim(sim)
	last = PoolRules.apply_shot(state, shot, opts)
	shots += 1
	if last.outcome == PoolRules.Outcome.RERACK:
		rack_seed += 1
		PoolRack.setup(sim, rack_seed)
		state = last.state
		return last
	state = last.state
	for b in last.respots:
		PoolRack.spot(sim, b)
	if not sim.on_table(0):
		_return_cue_ball()
	return last


## Headless convenience: strike, run to rest, settle.
func shoot(dir_x: float, dir_y: float, speed: float, side := 0.0, top := 0.0) -> PoolRules.Result:
	if not strike(dir_x, dir_y, speed, side, top):
		return null
	sim.run_to_rest()
	return settle()


## A scratched cue ball comes back to the head spot (or the nearest free point); the player may
## then move it anywhere legal with place_cue().
func _return_cue_ball() -> void:
	var y := -sim.table.hl * 0.5
	var r := sim.p.radius
	while y > -sim.table.hl + r:
		if cue_spot_ok_any(0.0, y):
			sim.place(0, 0.0, y)
			return
		y -= 0.002
	sim.place(0, 0.0, -sim.table.hl * 0.5)


func cue_spot_ok_any(x: float, y: float) -> bool:
	var r := sim.p.radius
	for i in range(1, CueSim.N):
		if sim.on_table(i):
			var dx: float = sim.px[i] - x
			var dy: float = sim.py[i] - y
			if dx * dx + dy * dy < 4.0 * r * r:
				return false
	return true
