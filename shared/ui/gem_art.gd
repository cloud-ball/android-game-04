class_name GemArt
extends RefCounted
## A 2D emerald-cut gem matching Facetfall's 3D gems (BlocksView.GEM_SHADER): an octagon with a
## flat table facet and eight bevels lit from the top left, a dark outline and a small sparkle.
## Used by the HUD previews, the how-to cards, the CPU mini-board and the hub icon, so every
## picture of a shard looks like a jewel, never a flat square tile (originality review
## 2026-11-17). Draw-time only.
## Performance: every gem is built as plain triangles with per-vertex colours and sent with ONE
## canvas_item_add_triangle_array call (draw_colored_polygon costs a draw call per polygon: the
## first version cost ~11 draw calls per gem and Facetfall fell to 44 fps on the test phone).
## Several gems can share one call through a Batch.

## Brightness of each bevel, clockwise from the top edge (light from the top left).
const BEVEL := [1.42, 1.18, 0.8, 0.66, 0.58, 0.72, 1.12, 1.32]


## Triangles collected for one draw call.
class Batch:
	extends RefCounted
	var points := PackedVector2Array()
	var colors := PackedColorArray()


## One gem, one draw call.
static func draw(c: CanvasItem, r: Rect2, col: Color, a := 1.0) -> void:
	var b := Batch.new()
	add(b, r, col, a)
	flush(c, b)


## Adds a gem's triangles to `b` (draw them with flush()).
static func add(b: Batch, r: Rect2, col: Color, a := 1.0) -> void:
	var s := minf(r.size.x, r.size.y)
	var o := r.position + (r.size - Vector2(s, s)) * 0.5
	var outer := _octagon(o, s, s * 0.22)
	if s < 7.0:  # tiny (CPU mini-board): a flat octagon
		_fan(b, outer, _shade(col, 1.0, a))
		return
	var inset := s * 0.24
	var inner := _octagon(o + Vector2(inset, inset), s - inset * 2.0, s * 0.11)
	for i in 8:
		var j := (i + 1) % 8
		var k := _shade(col, BEVEL[i], a)
		_tri(b, outer[i], outer[j], inner[j], k)
		_tri(b, outer[i], inner[j], inner[i], k)
	_fan(b, inner, _shade(col, 1.02, a))
	# Outline: a thin dark band just inside the octagon's edge.
	var w := maxf(1.0, s * 0.04)
	var rim := _octagon(o + Vector2(w, w), s - 2.0 * w, s * 0.22 - w * 0.4)
	var dark := Color(0, 0, 0, 0.35 * a)
	for i in 8:
		var j := (i + 1) % 8
		_tri(b, outer[i], outer[j], rim[j], dark)
		_tri(b, outer[i], rim[j], rim[i], dark)
	# Sparkle: a small octagon near the top left of the table.
	var g := s * 0.06
	_fan(
		b,
		_octagon(o + Vector2(s * 0.38 - g, s * 0.37 - g), 2.0 * g, g * 0.6),
		Color(1, 1, 1, 0.55 * a)
	)


## Sends everything in `b` as one draw call on `c` (call from inside c's draw).
static func flush(c: CanvasItem, b: Batch) -> void:
	if b.points.is_empty():
		return
	var idx := PackedInt32Array()
	idx.resize(b.points.size())
	for i in idx.size():
		idx[i] = i
	RenderingServer.canvas_item_add_triangle_array(c.get_canvas_item(), idx, b.points, b.colors)


## Octagon in the square (o, s) with corners cut by `cut`, clockwise from the top edge's start.
static func _octagon(o: Vector2, s: float, cut: float) -> PackedVector2Array:
	return PackedVector2Array(
		[
			o + Vector2(cut, 0),
			o + Vector2(s - cut, 0),
			o + Vector2(s, cut),
			o + Vector2(s, s - cut),
			o + Vector2(s - cut, s),
			o + Vector2(cut, s),
			o + Vector2(0, s - cut),
			o + Vector2(0, cut),
		]
	)


static func _tri(b: Batch, p: Vector2, q: Vector2, r: Vector2, col: Color) -> void:
	b.points.append(p)
	b.points.append(q)
	b.points.append(r)
	b.colors.append(col)
	b.colors.append(col)
	b.colors.append(col)


static func _fan(b: Batch, poly: PackedVector2Array, col: Color) -> void:
	for i in range(1, poly.size() - 1):
		_tri(b, poly[0], poly[i], poly[i + 1], col)


static func _shade(col: Color, k: float, a: float) -> Color:
	return Color(minf(col.r * k, 1.0), minf(col.g * k, 1.0), minf(col.b * k, 1.0), col.a * a)
