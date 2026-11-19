class_name GemArt
extends RefCounted
## A 2D emerald-cut gem matching Facetfall's 3D gems (BlocksView.GEM_SHADER): an octagon with a
## flat table facet and eight bevels lit from the top left, a dark outline and a small sparkle.
## Used by the HUD previews, the how-to cards, the CPU mini-board and the hub icon, so every
## picture of a shard looks like a jewel, never a flat square tile (originality review
## 2026-11-17). Draw-time only.

## Brightness of each bevel, clockwise from the top edge (light from the top left).
const BEVEL := [1.42, 1.18, 0.8, 0.66, 0.58, 0.72, 1.12, 1.32]


static func draw(c: CanvasItem, r: Rect2, col: Color, a := 1.0) -> void:
	var s := minf(r.size.x, r.size.y)
	var o := r.position + (r.size - Vector2(s, s)) * 0.5
	var outer := _octagon(o, s, s * 0.22)
	var inset := s * 0.24
	var inner := _octagon(o + Vector2(inset, inset), s - inset * 2.0, s * 0.11)
	if s >= 7.0:
		for i in 8:
			var j := (i + 1) % 8
			var quad := PackedVector2Array([outer[i], outer[j], inner[j], inner[i]])
			c.draw_colored_polygon(quad, _shade(col, BEVEL[i], a))
		c.draw_colored_polygon(inner, _shade(col, 1.02, a))
		var closed := outer.duplicate()
		closed.append(outer[0])
		c.draw_polyline(closed, Color(0, 0, 0, 0.35 * a), maxf(1.0, s * 0.04))
		c.draw_circle(o + Vector2(s * 0.38, s * 0.37), s * 0.06, Color(1, 1, 1, 0.55 * a))
	else:
		c.draw_colored_polygon(outer, _shade(col, 1.0, a))  # tiny (CPU mini-board): outline only


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


static func _shade(col: Color, k: float, a: float) -> Color:
	return Color(minf(col.r * k, 1.0), minf(col.g * k, 1.0), minf(col.b * k, 1.0), col.a * a)
