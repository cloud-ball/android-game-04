class_name HoleBaker
extends RefCounted
## Turns a hole description (a Dictionary loaded from games/golf/data/holes/*.json) into HoleData:
## a vertex height grid plus a surface grid. Pure and deterministic: only + - * / sqrt, no trig /
## pow / exp, so every device bakes bit-identical ground. Research: docs/research/Fairway Flick
## courses and maps.md ("A parametric spec, a static baker and a two-stage validator").
##
## Spec (metres; x right, z towards the player, downrange is -z):
##   path: [[x, z], ...]          centre line, tee -> green
##   elevation: [[s, h], ...]     height at distance s along the path (linear between keys)
##   fairway: [{from, to, width}] full fairway width between path distances
##   green: {x, z, rx, rz, axis: [ux, uz], tilt: [gx, gz], crown, fringe}
##   tee: {x, z, w, l}            flat tee box (w across, l along the first leg)
##   stamps: [{type: sand|water|out|bump, x, z, rx, rz, axis, depth | h}]
##   pins: [[x, z], ...]          first is the default
##   cell, margin, out_dist       grid size, grid border, out-of-bounds distance from the path

const ROUGH_RISE := 0.03  # ground rises gently away from the corridor (frames the hole)


static func load_spec(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	return data if data is Dictionary else {}


static func bake(spec: Dictionary) -> HoleData:
	var cell := float(spec.get("cell", 0.5))
	var margin := float(spec.get("margin", 30.0))
	var path: Array = spec.path
	var green: Dictionary = spec.green
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in path:
		lo = Vector2(minf(lo.x, p[0]), minf(lo.y, p[1]))
		hi = Vector2(maxf(hi.x, p[0]), maxf(hi.y, p[1]))
	var gr := maxf(float(green.rx), float(green.rz)) + float(green.get("fringe", 2.0))
	lo = Vector2(minf(lo.x, green.x - gr), minf(lo.y, green.z - gr)) - Vector2(margin, margin)
	hi = Vector2(maxf(hi.x, green.x + gr), maxf(hi.y, green.z + gr)) + Vector2(margin, margin)
	var d := HoleData.new()
	d.setup(lo.x, lo.y, cell, int(ceilf((hi.x - lo.x) / cell)), int(ceilf((hi.y - lo.y) / cell)))
	d.par = int(spec.get("par", 4))
	var ctx := _Ctx.new(spec)
	for j in d.nz + 1:
		for i in d.nx + 1:
			d.heights[j * (d.nx + 1) + i] = ctx.height(d.x0 + i * cell, d.z0 + j * cell)
	for j in d.nz:
		for i in d.nx:
			d.surface[j * d.nx + i] = ctx.surface(d.x0 + (i + 0.5) * cell, d.z0 + (j + 0.5) * cell)
	var t: Dictionary = spec.tee
	d.tee = Vector3(t.x, d.height(t.x, t.z), t.z)
	var pins: Array = spec.get("pins", [[green.x, green.z]])
	d.pin = Vector3(pins[0][0], 0.0, pins[0][1])
	d.pin.y = d.height(d.pin.x, d.pin.z)
	return d


## Bake-time geometry helpers (pure). Shapes are packed as 8 floats:
## [x, z, ux, uz, rx, rz, value, kind] with kind 0 bump, 1 sand, 2 water, 3 out; each is only
## tested inside its bounding box, and points far outside the hole skip all shape work.
class _Ctx:
	extends RefCounted
	const BUMP := 0
	const SAND := 1
	const WATER := 2
	const OUT := 3
	var path := PackedFloat64Array()  # x0, z0, x1, z1, ...
	var cum := PackedFloat64Array()  # distance along the path at each point
	var elev: Array = []
	var fw := PackedFloat64Array()  # from, to, half width per fairway piece
	var shapes := PackedFloat64Array()
	var green := PackedFloat64Array()  # one shape (value = crown)
	var green_tilt := Vector2.ZERO
	var fringe := 2.0
	var tee := PackedFloat64Array()  # one shape
	var out_dist := 45.0
	var tee_h := 0.0
	var green_h := 0.0
	var _s := 0.0  # scratch: along-path distance of the last query
	var _d := 0.0  # scratch: distance from the path

	func _init(spec: Dictionary) -> void:
		for pt in spec.path:
			path.append(float(pt[0]))
			path.append(float(pt[1]))
		cum.append(0.0)
		for k in range(1, path.size() / 2):
			var dx := path[2 * k] - path[2 * k - 2]
			var dz := path[2 * k + 1] - path[2 * k - 1]
			cum.append(cum[k - 1] + sqrt(dx * dx + dz * dz))
		elev = spec.get("elevation", [[0.0, 0.0]])
		for f in spec.get("fairway", []):
			fw.append_array([float(f.from), float(f.to), float(f.width) * 0.5])
		var kinds := {"bump": BUMP, "sand": SAND, "water": WATER, "out": OUT}
		for st in spec.get("stamps", []):
			var v := float(st.get("h", 0.0)) if st.type == "bump" else float(st.get("depth", 0.4))
			shapes.append_array(_shape(st, v, kinds.get(st.type, OUT)))
		var g: Dictionary = spec.green
		green = _shape(g, float(g.get("crown", 0.0)), -1)
		var tl: Array = g.get("tilt", [0.0, 0.0])
		green_tilt = Vector2(tl[0], tl[1])
		fringe = float(g.get("fringe", 2.0))
		var t: Dictionary = spec.tee
		tee = _shape({"x": t.x, "z": t.z, "rx": float(t.w) * 0.5, "rz": float(t.l) * 0.5}, 0.0, -1)
		out_dist = float(spec.get("out_dist", 45.0))
		_project(tee[0], tee[1])
		tee_h = _elev(_s) + 0.15
		_project(green[0], green[1])
		green_h = _elev(_s)

	static func _shape(sh: Dictionary, value: float, kind: int) -> PackedFloat64Array:
		var ux := 1.0
		var uz := 0.0
		if sh.has("axis"):
			var ax: Array = sh.axis
			var l := sqrt(float(ax[0]) * float(ax[0]) + float(ax[1]) * float(ax[1]))
			ux = float(ax[0]) / l
			uz = float(ax[1]) / l
		return PackedFloat64Array(
			[float(sh.x), float(sh.z), ux, uz, float(sh.rx), float(sh.rz), value, float(kind)]
		)

	## Ellipse norm (< 1 inside) of shape `o` in `arr`, grown by `grow` metres; 99 if far away.
	static func _q(arr: PackedFloat64Array, o: int, x: float, z: float, grow := 0.0) -> float:
		var dx := x - arr[o]
		var dz := z - arr[o + 1]
		var rx := arr[o + 4] + grow
		var rz := arr[o + 5] + grow
		var br := maxf(rx, rz)
		if dx > br or dx < -br or dz > br or dz < -br:
			return 99.0
		var a := (dx * arr[o + 2] + dz * arr[o + 3]) / rx
		var b := (-dx * arr[o + 3] + dz * arr[o + 2]) / rz
		return a * a + b * b

	## Nearest point on the centre line: sets _s (along) and _d (distance).
	func _project(x: float, z: float) -> void:
		var best := INF
		for k in range(path.size() / 2 - 1):
			var ax := path[2 * k]
			var az := path[2 * k + 1]
			var dx := path[2 * k + 2] - ax
			var dz := path[2 * k + 3] - az
			var t := clampf(((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz), 0.0, 1.0)
			var qx := ax + dx * t - x
			var qz := az + dz * t - z
			var dd := qx * qx + qz * qz
			if dd < best:
				best = dd
				_s = cum[k] + t * (cum[k + 1] - cum[k])
		_d = sqrt(best)

	func _elev(s: float) -> float:
		if s <= float(elev[0][0]):
			return float(elev[0][1])
		for k in range(1, elev.size()):
			var a: Array = elev[k - 1]
			var b: Array = elev[k]
			if s <= float(b[0]):
				return lerpf(a[1], b[1], (s - float(a[0])) / (float(b[0]) - float(a[0])))
		return float(elev[elev.size() - 1][1])

	static func _smooth(e0: float, e1: float, v: float) -> float:
		var t := clampf((v - e0) / (e1 - e0), 0.0, 1.0)
		return t * t * (3.0 - 2.0 * t)

	func height(x: float, z: float) -> float:
		_project(x, z)
		var h := _elev(_s) + ROUGH_RISE * maxf(0.0, _d - 18.0)
		if _d > out_dist + 25.0:
			return h  # far outside the hole: no features
		for o in range(0, shapes.size(), 8):
			if int(shapes[o + 7]) == BUMP:
				var q := _q(shapes, o, x, z)
				if q < 1.0:
					h += shapes[o + 6] * (1.0 - q) * (1.0 - q)
		var tq := _q(tee, 0, x, z, 3.0)
		if tq < 1.0:
			h = lerpf(h, tee_h, _smooth(1.0, 0.45, tq))
		# Green: a tilted, gently crowned plane, blended in over the fringe and 3 m beyond.
		var gq := _q(green, 0, x, z, fringe + 3.0)
		if gq < 1.0:
			var hg := green_h + green_tilt.x * (x - green[0]) + green_tilt.y * (z - green[1])
			hg += green[6] * maxf(0.0, 1.0 - _q(green, 0, x, z))
			h = lerpf(h, hg, _smooth(1.0, 0.55, gq))
		for o in range(0, shapes.size(), 8):
			var kind := int(shapes[o + 7])
			if kind == SAND or kind == WATER:
				var q := _q(shapes, o, x, z)
				if q < 1.0:
					h -= shapes[o + 6] * (1.0 - q)
		return h

	## Fairway half width at path distance s (rounded ends), 0 outside every piece.
	func _fairway_half(s: float) -> float:
		var best := 0.0
		for o in range(0, fw.size(), 3):
			var a := fw[o]
			var b := fw[o + 1]
			if s < a or s > b:
				continue
			var hw := fw[o + 2]
			var cap := minf(hw, (b - a) * 0.5)
			var into := minf(s - a, b - s)
			if into < cap:
				var k := 1.0 - into / cap
				hw *= sqrt(maxf(0.0, 1.0 - k * k))
			best = maxf(best, hw)
		return best

	func surface(x: float, z: float) -> int:
		_project(x, z)
		if _d > out_dist:
			return HoleData.Surface.OUT
		var s := HoleData.Surface.ROUGH
		if _d <= _fairway_half(_s):
			s = HoleData.Surface.FAIRWAY
		if _q(tee, 0, x, z) <= 1.0:
			s = HoleData.Surface.TEE
		if _q(green, 0, x, z, fringe) <= 1.0:
			s = HoleData.Surface.FRINGE
			if _q(green, 0, x, z) <= 1.0:
				s = HoleData.Surface.GREEN
		for o in range(0, shapes.size(), 8):
			var kind := int(shapes[o + 7])
			if kind != BUMP and _q(shapes, o, x, z) <= 1.0:
				s = (
					HoleData.Surface.SAND
					if kind == SAND
					else (HoleData.Surface.WATER if kind == WATER else HoleData.Surface.OUT)
				)
		return s
