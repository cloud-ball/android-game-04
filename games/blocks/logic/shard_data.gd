class_name ShardData
extends RefCounted
## The seven Stack Drop shards (A-G): cell layouts per rotation and the wall-kick tables.
## Cells are (x, y) inside the shard's box with +y = DOWN. Rotation states: 0, R, 2, L.
## A = long (4 in a row), B = square, C = tee, D = skew right, E = skew left, F/G = hooks.

const NAMES := ["A", "B", "C", "D", "E", "F", "G"]
const COUNT := 7
const LONG := 0
const SQUARE := 1
const ROT_NAMES := ["0", "R", "2", "L"]
const KICKS_PATH := "res://games/blocks/data/kicks.json"

## Spawn-orientation cells and box size per shard.
const SPAWN := [
	[[0, 1], [1, 1], [2, 1], [3, 1]],
	[[1, 0], [2, 0], [1, 1], [2, 1]],
	[[1, 0], [0, 1], [1, 1], [2, 1]],
	[[1, 0], [2, 0], [0, 1], [1, 1]],
	[[0, 0], [1, 0], [1, 1], [2, 1]],
	[[0, 0], [0, 1], [1, 1], [2, 1]],
	[[2, 0], [0, 1], [1, 1], [2, 1]],
]
const BOX := [4, 4, 3, 3, 3, 3, 3]

## _cells[kind][rot] = Array[Vector2i]
static var _cells: Array = []
static var _kicks: Dictionary = {}


static func cells(kind: int, rot: int) -> Array:
	if _cells.is_empty():
		_build_cells()
	return _cells[kind][rot]


## Kick offsets to try for a rotation, converted to +y = DOWN. Empty for the square.
static func kicks(kind: int, from_rot: int, to_rot: int) -> Array:
	if kind == SQUARE:
		return [Vector2i.ZERO]
	if _kicks.is_empty():
		_load_kicks()
	var table: Dictionary = _kicks["long" if kind == LONG else "standard"]
	return table["%s>%s" % [ROT_NAMES[from_rot], ROT_NAMES[to_rot]]]


static func raw_kick_table() -> Dictionary:
	if _kicks.is_empty():
		_load_kicks()
	return _kicks


static func _build_cells() -> void:
	for kind in COUNT:
		var per_rot: Array = []
		var current: Array[Vector2i] = []
		for c in SPAWN[kind]:
			current.append(Vector2i(c[0], c[1]))
		for r in 4:
			per_rot.append(current.duplicate())
			if kind == SQUARE:
				continue
			var n: int = BOX[kind] - 1
			var next: Array[Vector2i] = []
			for c in current:
				next.append(Vector2i(n - c.y, c.x))  # clockwise in a +y-down box
			current = next
		_cells.append(per_rot)


static func _load_kicks() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(KICKS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ShardData: cannot read %s" % KICKS_PATH)
		return
	for table_name in ["standard", "long"]:
		var src: Dictionary = parsed[table_name]
		var out := {}
		for key in src:
			var tests: Array[Vector2i] = []
			for pair in src[key]:
				tests.append(Vector2i(int(pair[0]), -int(pair[1])))  # data is +y up
			out[key] = tests
		_kicks[table_name] = out
