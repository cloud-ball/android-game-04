class_name PoolHowto
extends RefCounted
## Cue Club how-to cards (HowtoDeck, 920 x 920 design units): a stylised top-down mini table.
## Drag to aim (the aim line swings with the finger), pull the power bar to shoot (the ball drops),
## spin the cue ball (a draw shot comes back).

const CLOTH := Color(0.07, 0.5, 0.47)
const WOOD := Color(0.42, 0.22, 0.12)
const T := Rect2(150, 90, 500, 740)  # cloth area
const BALL := 26.0


static func cards() -> Array:
	return [
		{
			"title": "Drag to aim",
			"sub": "Drag anywhere around the white ball.",
			"demo": _demo_aim,
			"poster": _poster_aim,
			"gesture": GestureTimeline.new("drag", Vector2(250, 760), Vector2(550, 760), 3, 1000),
			"try": "drag",
		},
		{
			"title": "Pull to shoot",
			"sub": "Pull the power bar down, then let go.",
			"demo": _demo_power,
			"poster": _poster_power,
			"gesture": GestureTimeline.new("swipe", Vector2(790, 330), Vector2(790, 640), 1, 1500),
			"try": "swipe",
		},
		{
			"title": "Spin the cue ball",
			"sub": "Low on the ball draws it back. High follows.",
			"demo": _demo_spin,
			"poster": _poster_spin,
			"gesture": GestureTimeline.new("tap", Vector2(460, 300), Vector2(460, 300), 1, 1700),
			"try": "tap",
		},
	]


static func fade(t: float, g: GestureTimeline) -> float:
	return clampf(minf(t / 200.0, (g.loop_ms - t) / 300.0), 0.0, 1.0)


static func _table(c: Control, a: float) -> void:
	c.draw_rect(T.grow(34), Color(WOOD, a))
	c.draw_rect(T, Color(CLOTH, a))
	for p in [T.position, Vector2(T.end.x, T.position.y), Vector2(T.position.x, T.end.y), T.end]:
		c.draw_circle(p, 30, Color(0.02, 0.02, 0.03, a))
	for y in [T.position.y + T.size.y * 0.5]:
		c.draw_circle(Vector2(T.position.x - 6, y), 28, Color(0.02, 0.02, 0.03, a))
		c.draw_circle(Vector2(T.end.x + 6, y), 28, Color(0.02, 0.02, 0.03, a))


static func _ball(c: Control, p: Vector2, col: Color, a: float, number := "") -> void:
	c.draw_circle(p + Vector2(4, 5), BALL, Color(0, 0, 0, 0.3 * a))
	c.draw_circle(p, BALL, Color(col, a))
	c.draw_circle(p + Vector2(-8, -9), 7, Color(1, 1, 1, 0.5 * a))
	if number != "":
		c.draw_circle(p, 12, Color(1, 1, 1, a))
		c.draw_string(
			UiKit.font(900),
			p + Vector2(-6, 6),
			number,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color(0, 0, 0, a)
		)


static func _dashes(c: Control, a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b) / 22.0)
	for i in n:
		if i % 2 == 0:
			c.draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 5.0)


static func _demo_aim(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_table(c, a)
	var cue := Vector2(400, 620)
	var obj := Vector2(480, 330)
	_ball(c, obj, Color("#D9312B"), a, "3")
	var k := clampf((t - g.press_ms) / g.action_ms(), 0.0, 1.0)
	var ang := lerpf(-2.2, (obj - cue).angle(), k)
	var d := Vector2.from_angle(ang)
	_dashes(c, cue, cue + d * 300.0, Color(1, 1, 1, 0.8 * a))
	c.draw_line(cue - d * 60.0, cue - d * 320.0, Color(0.86, 0.72, 0.5, a), 10.0)
	_ball(c, cue, Color("#F4F1E6"), a)
	c.draw_arc(cue, 70, 0.0, TAU, 40, Color(1, 1, 1, 0.15 * a), 3.0)


static func _demo_power(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_table(c, a)
	var pull := clampf((t - g.press_ms) / g.action_ms(), 0.0, 1.0) if t < g.lift_ms else 0.0
	var bar := Rect2(770, 300, 40, 380)
	c.draw_rect(bar, Color(0, 0, 0, 0.5 * a))
	c.draw_rect(Rect2(bar.position, Vector2(40, 380 * pull)), Color(0.3, 0.85, 0.8, a))
	var cue := Vector2(400, 640)
	var obj := Vector2(400, 360)
	var pocket := Vector2(T.position.x + 250, T.position.y)
	var since := t - g.lift_ms
	var hit := 240.0
	if since < 0.0:
		_ball(c, obj, Color("#2456C8"), a, "2")
		c.draw_line(
			cue + Vector2(0, 60 + 80 * pull), cue + Vector2(0, 330), Color(0.86, 0.72, 0.5, a), 10.0
		)
		_ball(c, cue, Color("#F4F1E6"), a)
	else:
		var cy := lerpf(cue.y, obj.y + 2.0 * BALL, clampf(since / hit, 0.0, 1.0))
		_ball(c, Vector2(cue.x, cy), Color("#F4F1E6"), a)
		var ok := clampf((since - hit) / 380.0, 0.0, 1.0)
		if ok < 1.0:
			_ball(c, obj.lerp(Vector2(pocket.x, pocket.y + 30), ok), Color("#2456C8"), a, "2")


static func _demo_spin(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_table(c, a)
	# A spin ball inset where the finger taps low (draw).
	var inset := Vector2(460, 240)
	c.draw_circle(inset, 70, Color(0.95, 0.94, 0.9, a))
	var dot := inset + Vector2(0, 40) if t >= g.press_ms else inset
	c.draw_circle(dot, 14, Color(0.85, 0.12, 0.1, a))
	var cue := Vector2(400, 700)
	var obj := Vector2(400, 470)
	var since := t - g.lift_ms - 200.0
	if since < 0.0:
		_ball(c, obj, Color("#6B3FA0"), a, "4")
		_ball(c, cue, Color("#F4F1E6"), a)
		return
	var hit := 260.0
	if since < hit:
		_ball(c, obj, Color("#6B3FA0"), a, "4")
		_ball(c, cue.lerp(obj + Vector2(0, 2.0 * BALL), since / hit), Color("#F4F1E6"), a)
		return
	var k := clampf((since - hit) / 700.0, 0.0, 1.0)
	_ball(
		c,
		(obj + Vector2(0, 2.0 * BALL)).lerp(Vector2(400, 690), GestureTimeline.decel(k)),
		Color("#F4F1E6"),
		a
	)
	_ball(
		c,
		obj.lerp(Vector2(400, 110), clampf(k * 1.6, 0.0, 1.0)),
		Color("#6B3FA0"),
		a * (1.0 - clampf(k * 1.6 - 0.9, 0.0, 1.0)),
		"4"
	)
	c.draw_string(
		UiKit.font(900),
		Vector2(470, 650),
		"DRAW!",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		44,
		Color(1, 0.9, 0.5, a * k)
	)


static func _poster_aim(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 150, 150), Color(CLOTH, 1.0))
	c.draw_circle(Vector2(75, 105), 14, Color("#F4F1E6"))
	c.draw_line(Vector2(75, 105), Vector2(110, 30), Color.WHITE, 3.0)
	c.draw_arc(Vector2(75, 105), 32, 3.5, 5.6, 20, Color(1, 1, 1, 0.8), 4.0)


static func _poster_power(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 150, 150), Color(CLOTH, 1.0))
	c.draw_rect(Rect2(105, 20, 22, 110), Color(0, 0, 0, 0.5))
	c.draw_rect(Rect2(105, 20, 22, 70), Color(0.3, 0.85, 0.8))
	c.draw_line(Vector2(80, 40), Vector2(80, 110), Color.WHITE, 4.0)
	c.draw_colored_polygon(
		PackedVector2Array([Vector2(68, 100), Vector2(92, 100), Vector2(80, 122)]), Color.WHITE
	)


static func _poster_spin(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 150, 150), Color(CLOTH, 1.0))
	c.draw_circle(Vector2(75, 75), 52, Color(0.95, 0.94, 0.9))
	c.draw_circle(Vector2(75, 105), 11, Color(0.85, 0.12, 0.1))
