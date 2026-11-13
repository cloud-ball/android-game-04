class_name SnakeLogic
extends RefCounted
## Pure grid logic for Serpent Grid. No nodes; same seed + same inputs -> same game.
## Coordinates: x 0..width-1 left->right, y 0..height-1 far->near (UP = toward y 0).
## With cfg.wrap the board is a torus: stepping off an edge re-enters on the opposite edge.
## Both snakes move at the same time each tick. A snake may move into a tail cell that is
## vacated on that same tick. Head-on (same cell or swapped cells) crashes both.

enum Dir { UP, RIGHT, DOWN, LEFT }
enum Result { ONGOING, PLAYER_WON, CPU_WON, DRAW, SOLO_OVER }

const PLAYER := 0
const CPU := 1
const STEP: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const BUFFER_DEPTH := 2


class Serpent:
	var body: Array[Vector2i] = []
	var prev_body: Array[Vector2i] = []
	var dir: int = Dir.UP
	var queue: Array[int] = []
	var alive := true
	var score := 0
	var eaten := 0
	var crash_cause := ""

	func head() -> Vector2i:
		return body[0]


var cfg: SnakeConfig
var width: int
var height: int
var vs_cpu: bool
var snakes: Array[Serpent] = []
var orbs: Array[Vector2i] = []
var tick_count := 0
var result: int = Result.ONGOING
## Events from the latest tick, for renderers/audio: {type: "eat"|"crash", who, cell, cause}.
var events: Array[Dictionary] = []

var _rng := RandomNumberGenerator.new()


func _init(config: SnakeConfig = null, seed_value: int = 1, with_cpu := true) -> void:
	cfg = config if config != null else SnakeConfig.new()
	width = cfg.width
	height = cfg.height
	vs_cpu = with_cpu
	_rng.seed = seed_value
	var x0 := 2
	var y0 := height - 1 - cfg.start_length
	snakes.append(_make_snake(Vector2i(x0, y0), Dir.UP))
	if vs_cpu:
		snakes.append(_make_snake(Vector2i(width - 1 - x0, cfg.start_length), Dir.DOWN))
	for i in cfg.orb_count:
		_spawn_orb()


func _make_snake(head: Vector2i, dir: int) -> Serpent:
	var s := Serpent.new()
	s.dir = dir
	for i in cfg.start_length:
		s.body.append(head - STEP[dir] * i)
	s.prev_body = s.body.duplicate()
	return s


static func opposite(d: int) -> int:
	return (d + 2) % 4


## Buffer a turn (2 deep). Ignores repeats and reversals relative to the last buffered direction.
func queue_turn(who: int, d: int) -> bool:
	var s := snakes[who]
	var last: int = s.queue.back() if not s.queue.is_empty() else s.dir
	if d == last or d == opposite(last) or s.queue.size() >= BUFFER_DEPTH:
		return false
	s.queue.append(d)
	return true


## The cell one step from c in direction d (wrapped onto the board when cfg.wrap is on).
func step_from(c: Vector2i, d: int) -> Vector2i:
	var n := c + STEP[d]
	if cfg.wrap:
		n = Vector2i(posmod(n.x, width), posmod(n.y, height))
	return n


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_over() -> bool:
	return result != Result.ONGOING


func longest() -> int:
	var n := 0
	for s in snakes:
		n = maxi(n, s.body.size())
	return n


## Seconds per tick right now.
func tick_interval() -> float:
	var hz := cfg.base_hz + cfg.hz_per_segment * float(longest() - cfg.start_length)
	return 1.0 / clampf(hz, 1.0, cfg.max_hz)


func step() -> void:
	if is_over():
		return
	events.clear()
	var new_heads: Array[Vector2i] = []
	var grows: Array[bool] = []
	for s in snakes:
		s.prev_body = s.body.duplicate()
		if s.alive and not s.queue.is_empty():
			s.dir = s.queue.pop_front()
		var nh := step_from(s.head(), s.dir)
		new_heads.append(nh)
		grows.append(s.alive and orbs.has(nh))
	var new_bodies: Array = []
	for i in snakes.size():
		var s := snakes[i]
		var nb: Array[Vector2i] = [new_heads[i]]
		nb.append_array(s.body.slice(0, s.body.size() if grows[i] else s.body.size() - 1))
		new_bodies.append(nb)
	var causes: Array[String] = []
	for i in snakes.size():
		causes.append(_crash_cause(i, new_heads, new_bodies) if snakes[i].alive else "")
	# A crashed snake does not move, so its tail stays put: a survivor heading into a cell that
	# crashed body still holds crashes too (otherwise the last frame shows them overlapping).
	var changed := true
	while changed:
		changed = false
		for i in snakes.size():
			if not snakes[i].alive or causes[i] != "":
				continue
			for j in snakes.size():
				if j != i and causes[j] != "" and snakes[j].body.has(new_heads[i]):
					causes[i] = "rival"
					changed = true
	for i in snakes.size():
		var s := snakes[i]
		if not s.alive:
			continue
		if causes[i] != "":
			s.alive = false
			s.crash_cause = causes[i]
			events.append({"type": "crash", "who": i, "cell": new_heads[i], "cause": s.crash_cause})
			continue
		s.body = new_bodies[i]
		if grows[i]:
			orbs.erase(new_heads[i])
			s.score += cfg.orb_score
			s.eaten += 1
			events.append({"type": "eat", "who": i, "cell": new_heads[i]})
	while orbs.size() < cfg.orb_count and _spawn_orb():
		pass
	tick_count += 1
	_update_result()


## "" when the move is safe, otherwise "wall" | "self" | "rival" | "head".
func _crash_cause(i: int, new_heads: Array[Vector2i], new_bodies: Array) -> String:
	var h := new_heads[i]
	if not in_bounds(h):
		return "wall"
	var own: Array[Vector2i] = new_bodies[i]
	if own.find(h, 1) != -1:
		return "self"
	for j in snakes.size():
		if j == i or not snakes[j].alive:
			continue
		if new_heads[j] == h:
			return "head"
		var other: Array[Vector2i] = new_bodies[j]
		if other.find(h, 1) != -1:
			return "rival"
	return ""


func _update_result() -> void:
	var p := snakes[PLAYER]
	if not vs_cpu:
		if not p.alive:
			result = Result.SOLO_OVER
		return
	var c := snakes[CPU]
	if not p.alive and not c.alive:
		result = Result.DRAW
	elif not p.alive:
		result = Result.CPU_WON
	elif not c.alive:
		result = Result.PLAYER_WON
		p.score += cfg.crash_bonus


func _spawn_orb() -> bool:
	var grid := occupancy()
	var empty: Array[Vector2i] = []
	for y in height:
		for x in width:
			var c := Vector2i(x, y)
			if grid[y * width + x] == 0 and not orbs.has(c):
				empty.append(c)
	if empty.is_empty():
		return false
	orbs.append(empty[_rng.randi_range(0, empty.size() - 1)])
	return true


## width*height bytes: 0 empty, 1 + snake index for body cells (alive or not).
func occupancy() -> PackedByteArray:
	var g := PackedByteArray()
	g.resize(width * height)
	for i in snakes.size():
		for c in snakes[i].body:
			if in_bounds(c):
				g[c.y * width + c.x] = i + 1
	return g


## Stable fingerprint of the whole board, for replay tests.
func board_hash() -> int:
	var parts: Array = [tick_count, result, orbs]
	for s in snakes:
		parts.append([s.body, s.dir, s.alive, s.score])
	return hash(str(parts))
