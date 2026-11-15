class_name GolfClubs
extends RefCounted
## The bag (pure): launch per club and power, lie effects, and a carry table measured by flying
## each club on the real solver (flat ground, still air, 1/60 s planning step), so aiming can
## say how hard to swing for a distance. Launches: average-amateur TrackMan driver row, other clubs
## scaled down the bag (research: ball physics notes, section 2).

## [name, ball speed mph at full power, launch deg, spin rpm]
const BAG := [
	["Driver", 133.0, 12.6, 3275.0],
	["Hybrid", 112.0, 14.5, 4400.0],
	["7-iron", 96.0, 17.5, 6500.0],
	["Wedge", 81.0, 25.0, 8500.0],
	["Sand W", 62.0, 32.0, 9000.0],
]
const PUTTER := 5
const MAX_POWER := 1.15  # overpower band above 100%
const MAX_PUTT := 5.0  # m/s ground speed at full putter pull
const TABLE_P := [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.15]

## carry[club][k] in metres for TABLE_P[k]
var carry: Array = []


func _init() -> void:
	for c in BAG.size():
		var row := PackedFloat64Array()
		for pw in TABLE_P:
			var f := GolfFlight.new()
			var l := launch(c, pw)
			f.launch(Vector3.ZERO, l[0], l[1], l[2])
			var o := f.fly_to_ground(1.0 / 60.0)
			row.append(-float((o.pos as Vector3).z))
		carry.append(row)


static func count() -> int:
	return BAG.size()


static func name_of(c: int) -> String:
	return "Putter" if c == PUTTER else str(BAG[c][0])


## [ball speed m/s, launch deg, backspin rad/s] for club c at power p (1.0 = full swing).
static func launch(c: int, p: float) -> Array:
	var b: Array = BAG[c]
	return [
		float(b[1]) * GolfFlight.MPH * p,
		float(b[2]) + (1.0 - minf(p, 1.0)) * 3.0,  # softer swings launch a touch higher
		float(b[3]) * GolfFlight.RPM * (0.55 + 0.45 * minf(p, 1.0)),
	]


## Lie: [speed factor, spin factor] for a full-swing club from surface s.
static func lie(s: int) -> Vector2:
	match s:
		HoleData.Surface.ROUGH:
			return Vector2(0.86, 0.55)
		HoleData.Surface.SAND:
			return Vector2(0.72, 0.5)
		HoleData.Surface.FRINGE:
			return Vector2(0.97, 0.9)
		_:
			return Vector2.ONE


func carry_at(c: int, p: float) -> float:
	var row: PackedFloat64Array = carry[c]
	if p <= TABLE_P[0]:
		return row[0] * p / TABLE_P[0]
	for k in range(1, TABLE_P.size()):
		if p <= TABLE_P[k]:
			var t: float = (p - TABLE_P[k - 1]) / (TABLE_P[k] - TABLE_P[k - 1])
			return lerpf(row[k - 1], row[k], t)
	return row[row.size() - 1]


## Power that carries club c `dist` metres (clamped to the table).
func power_for(c: int, dist: float) -> float:
	var row: PackedFloat64Array = carry[c]
	if dist <= row[0]:
		return TABLE_P[0] * dist / maxf(row[0], 0.01)
	for k in range(1, TABLE_P.size()):
		if dist <= row[k]:
			var t: float = (dist - row[k - 1]) / (row[k] - row[k - 1])
			return lerpf(TABLE_P[k - 1], TABLE_P[k], t)
	return MAX_POWER


## The shortest club that carries `dist` at full power (driver if none do).
func pick(dist: float) -> int:
	for c in range(BAG.size() - 1, -1, -1):
		if carry_at(c, 1.0) >= dist:
			return c
	return 0


## Putter ground speed that stops the ball `dist` m away on flat ground with roll decel a,
## aiming ~0.3 m past (dies at the hole rather than short).
static func putt_speed(dist: float, a: float) -> float:
	return sqrt(2.0 * a * (dist + 0.3))
