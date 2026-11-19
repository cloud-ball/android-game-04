class_name GolfTrails
extends RefCounted
## Two line effects on the hole (render only): the speed trail behind a fast ball (a small ring
## buffer, drawn as a fading ribbon) and the dotted aim guide (the ball's real path for its first
## moments, same solver, up to the second rail hit).

var _pts := PackedVector3Array()
var _speed := PackedFloat32Array()
var _head := 0
var _n := 0


func _init(size := 20) -> void:
	_pts.resize(size)
	_speed.resize(size)


func reset() -> void:
	_n = 0


func push(p: Vector3, speed: float) -> void:
	if speed < 1.0:
		_n = maxi(0, _n - 1)
		return
	_head = (_head + 1) % _pts.size()
	_pts[_head] = p + Vector3(0, 0.03, 0)
	_speed[_head] = speed
	_n = mini(_n + 1, _pts.size())


func draw(im: ImmediateMesh, fallback_dir: Vector3, show: bool) -> void:
	im.clear_surfaces()
	if _n < 2 or not show:
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var size := _pts.size()
	for k in _n:
		var idx := (_head - k + size) % size
		var nxt := (_head - mini(k + 1, _n - 1) + size) % size
		var q := _pts[idx]
		var d := q - _pts[nxt]
		if d.length() < 1e-4:
			d = fallback_dir
		var side := Vector3(-d.z, 0.0, d.x).normalized()
		var w := clampf(_speed[idx] * 0.006, 0.01, 0.05) * (1.0 - float(k) / _n)
		var a := 0.55 * (1.0 - float(k) / _n)
		im.surface_set_color(Color(1, 1, 1, a))
		im.surface_add_vertex(q - side * w)
		im.surface_set_color(Color(1, 1, 1, a))
		im.surface_add_vertex(q + side * w)
	im.surface_end()


## Dotted guide: the ball's real path for the first `seconds` (same solver).
static func draw_guide(
	im: ImmediateMesh,
	hole: HoleData,
	preset: CoursePreset,
	params: GolfParams,
	from: Vector3,
	dir: Vector3,
	speed: float,
	seconds: float,
) -> void:
	im.clear_surfaces()
	var b := GolfBall.new(hole, preset, params)
	var v := dir * speed
	b.putt(from.x, from.z, v.x, v.z)
	var pts := PackedVector3Array()
	var t := 0.0
	var walls := 0
	while t < seconds and not b.done():
		b.substep(1.0 / 120.0)
		t += 1.0 / 120.0
		if int(t * 120.0) % 4 == 0:
			pts.append(b.pos())
		if b.events.count(GolfBall.Ev.WALL) > walls:
			walls = b.events.count(GolfBall.Ev.WALL)
			if walls >= 2:
				break
	if pts.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := Vector3(-dir.z, 0.0, dir.x) * 0.035
	var fwd := dir * 0.035
	for k in range(0, pts.size(), 2):
		var q := pts[k] + Vector3(0, 0.03, 0)
		var col := Color(1, 1, 1, 0.9 * (1.0 - float(k) / pts.size()))
		for vtx in [
			q - side - fwd,
			q + side - fwd,
			q + side + fwd,
			q - side - fwd,
			q + side + fwd,
			q - side + fwd
		]:
			im.surface_set_color(col)
			im.surface_add_vertex(vtx)
	im.surface_end()
