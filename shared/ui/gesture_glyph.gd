class_name GestureGlyph
extends RefCounted
## Draws the original fingertip glyph for a GestureTimeline pose: tap ripple, tapered trail,
## flick speed ghosts, contact dot and a tilted capsule (like a right thumb reaching in from the
## bottom-right). Shared by the how-to cards and the in-match practice hints.
## Coordinates are in the caller's units; k scales them to the control (1.0 = already in pixels).

const ROT := -0.35

var accent := Color.WHITE
var _finger: StyleBoxFlat
var _shadow: StyleBoxFlat


func _init(accent_color := Color.WHITE) -> void:
	accent = accent_color
	_finger = UiKit.box(Color(1, 1, 1, 0.88), 42, Color(0.05, 0.06, 0.12, 0.9), 6)
	_shadow = UiKit.box(Color(0, 0, 0, 0.3), 42)


## Expects the control's transform to already scale by k (draw_set_transform(…, Vector2(k, k))).
func draw(c: CanvasItem, g: GestureTimeline, k: float) -> void:
	if not g.visible:
		return
	var a := g.alpha
	if g.ripple >= 0.0:
		var r := lerpf(18.5, 61.5, g.ripple)
		c.draw_arc(g.pos, r, 0.0, TAU, 40, Color(1, 1, 1, 0.9 * g.ripple_alpha * a), 6.0, true)
	if g.trail_alpha > 0.0:
		var reach := 0.5 * g.from.distance_to(g.to)
		var start := g.pos + (g.trail_from - g.pos).limit_length(reach)
		var tint := accent.lightened(0.5)
		for i in 8:
			var p0 := start.lerp(g.pos, i / 8.0)
			var p1 := start.lerp(g.pos, (i + 1) / 8.0)
			var w := 14.0 * (i + 1) / 8.0
			c.draw_line(p0, p1, Color(tint, g.trail_alpha * a * (0.25 + 0.75 * (i + 1) / 8.0)), w)
	if g.ghosts:
		var dir := (g.to - g.from).normalized()
		for i in range(1, 4):
			c.draw_circle(g.pos - dir * 34.0 * i, 14.0, Color(1, 1, 1, 0.22 * a / i))
		var side := Vector2(-dir.y, dir.x)
		for j in [-1.0, 1.0]:
			var base: Vector2 = g.pos - dir * 40.0 + side * 36.0 * j
			c.draw_line(base, base - dir * 70.0, Color(1, 1, 1, 0.5 * a), 4.0, true)
	if g.down:
		c.draw_circle(g.pos, 26.0, Color(accent, 0.3 * a))
		c.draw_circle(g.pos, 14.0, Color(1.0, 0.95, 0.6, a))
	_finger.bg_color.a = 0.88 * a
	_finger.border_color.a = 0.9 * a
	_shadow.bg_color.a = 0.3 * a
	var body := Rect2(Vector2(-42, -16), Vector2(84, 150))
	c.draw_set_transform(g.pos * k, ROT, Vector2.ONE * k * g.scale)
	c.draw_style_box(_shadow, Rect2(body.position + Vector2(8, 10), body.size))
	c.draw_style_box(_finger, body)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
