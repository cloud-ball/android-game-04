class_name GolfCpuThink
extends RefCounted
## Runs one GolfCpu choice off the main thread without ever blocking it: start(), then call poll()
## once per frame until it returns true; `shot` is then the velocity to play. All CPU golfers share
## ONE background lane (a static queue served by a single WorkerThreadPool task at a time):
## GDScript object calls take an engine-wide lock, so rollouts on several threads mostly wait on
## each other (measured 2026-11-19: 60 rollouts 994 ms serial vs 1282 ms as a group task) and would
## also slow the main thread. Same result as GolfCpu.choose() for the same RNG state (tested).

static var _queue: Array[GolfCpuThink] = []
static var _running: GolfCpuThink = null
static var _task := -1

var shot := Vector2.ZERO
var done := false

var _cpu: GolfCpu
var _from: Vector3
var _tier: int
var _rng: RandomNumberGenerator
var _started := false


func _init(cpu: GolfCpu, from: Vector3, tier: int, rng: RandomNumberGenerator) -> void:
	_cpu = cpu
	_from = from
	_tier = tier
	_rng = rng


func start() -> void:
	if _started:
		return
	_started = true
	_queue.append(self)
	_pump()


## True once `shot` is ready. Cheap; call every frame.
func poll() -> bool:
	_pump()
	return done


## Blocks until done (tests, headless self-play).
func finish() -> Vector2:
	start()
	while not poll():
		OS.delay_usec(500)
	return shot


## Drops this request (e.g. the match ended) if it has not started running.
func cancel() -> void:
	_queue.erase(self)


func _work() -> void:
	shot = _cpu.choose(_from, _tier, _rng)


static func _pump() -> void:
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		WorkerThreadPool.wait_for_task_completion(_task)  # already finished: releases it
		_task = -1
		_running.done = true
		_running = null
	if _queue.is_empty():
		return
	_running = _queue.pop_front()
	_task = WorkerThreadPool.add_task(_running._work, false, "golf cpu")
