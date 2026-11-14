class_name PoolHowto
extends RefCounted
## Cue Club how-to cards (HowtoDeck, 920 x 920 design units): a stylised top-down mini table.
## Controls: point to aim (+ the fine-aim edge), pull the power bar to shoot, spin the cue ball.
## Rules: solids or stripes then the 8, call the 8's pocket, fouls give ball in hand.

const CLOTH := Color(0.07, 0.5, 0.47)
const WOOD := Color(0.42, 0.22, 0.12)
const T := Rect2(150, 90, 500, 740)  # cloth area
const BALL := 26.0
const CALL_POCKET := Vector2(650, 90)  # top-right corner of T
const SOLID_COLS := ["#F2C230", "#D9312B", "#1E8C4E"]
const STRIPE_COLS := ["#2456C8", "#F07A1E", "#8B1E2E"]


static func cards() -> Array:
	return [
		{
			"title": "Point to aim",
			"sub":
			"Touch the table - the cue points at your finger. Slide the left edge to fine-tune.",
			"demo": _demo_aim,
			"poster": _poster_aim,
			"gesture": GestureTimeline.new("drag", Vector2(250, 420), Vector2(480, 330), 3, 1000),
			"try": "swipe",
		},
		{
			"title": "Pull to shoot",
			"sub": "Pull the power bar on the right down, then let go. Further = harder.",
			"demo": _demo_power,
			"poster": _poster_power,
			"gesture": GestureTimeline.new("swipe", Vector2(790, 330), Vector2(790, 640), 1, 1500),
			"try": "swipe",
		},
		{
			"title": "Spin the cue ball",
			"sub": "Tap the white-ball button. Low draws the cue ball back, high follows through.",
			"demo": _demo_spin,
			"poster": _poster_spin,
			"gesture": GestureTimeline.new("tap", Vector2(460, 300), Vector2(460, 300), 1, 1700),
			"try": "tap",
		},
		{
			"title": "Solids or stripes",
			"sub": "Your first pot picks your group. Clear it, then sink the 8 to win.",
			"demo": _demo_groups,
			"poster": _poster_groups,
			"gesture": GestureTimeline.new("none", Vector2.ZERO, Vector2.ZERO, 1, 2600),
		},
		{
			"title": "Call the 8",
			"sub": "On the 8, tap a pocket first. The 8 in any other pocket loses.",
			"demo": _demo_call,
			"poster": _poster_call,
			"gesture": GestureTimeline.new("tap", CALL_POCKET, CALL_POCKET, 1, 1800),
			"try": "tap",
		},
		{
			"title": "Fouls give ball in hand",
			"sub":
			(
				"Pot the white, hit the wrong ball first or touch no cushion:"
				+ " your rival places the white anywhere."
			),
			"demo": _demo_hand,
			"poster": _poster_hand,
			"gesture": GestureTimeline.new("drag", Vector2(300, 640), Vector2(430, 420), 3, 1000),
			"try": "drag",
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


## A striped ball: white with a coloured band (the circle clipped to |y| < 0.55 R).
static func _stripe(c: Control, p: Vector2, col: Color, a: float, number := "") -> void:
	c.draw_circle(p + Vector2(4, 5), BALL, Color(0, 0, 0, 0.3 * a))
	c.draw_circle(p, BALL, Color(0.95, 0.94, 0.9, a))
	var band := PackedVector2Array()
	for i in 32:
		var ang := TAU * i / 32.0
		band.append(
			p + Vector2(cos(ang) * BALL, clampf(sin(ang) * BALL, -0.55 * BALL, 0.55 * BALL))
		)
	c.draw_colored_polygon(band, Color(col, a))
	c.draw_circle(p + Vector2(-8, -9), 7, Color(1, 1, 1, 0.5 * a))
	if number != "":
		c.draw_circle(p, 12, Color(1, 1, 1, a))
		c.draw_string(
			UiKit.font(900),
			p + Vector2(-11, 6),
			number,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color(0, 0, 0, a)
		)


static func _chip(c: Control, centre: Vector2, text: String, col: Color, a: float) -> void:
	var size := 40
	var w := UiKit.font(900).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	c.draw_rect(
		Rect2(centre - Vector2(w * 0.5 + 24, 34), Vector2(w + 48, 62)), Color(0, 0, 0, 0.7 * a)
	)
	c.draw_string(
		UiKit.font(900),
		centre + Vector2(-w * 0.5, 14),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		Color(col, a)
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
	g.evaluate(t)
	var finger := g.pos if g.visible and t >= g.press_ms else g.to
	var d := (finger - cue).normalized()
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


static func _demo_groups(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_table(c, a)
	var since := t - g.press_ms
	var solids := [Vector2(250, 300), Vector2(300, 520), Vector2(230, 690)]
	var stripes := [Vector2(560, 330), Vector2(520, 560), Vector2(580, 700)]
	var nums := ["1", "3", "6"]
	var snums := ["10", "13", "15"]
	# The 3 rolls into the left side pocket, then the group is yours.
	var roll := clampf(since / 500.0, 0.0, 1.0)
	var pocket := Vector2(T.position.x - 6, T.position.y + T.size.y * 0.5)
	for i in 3:
		var p: Vector2 = solids[i]
		var alpha := a
		if i == 1:
			p = p.lerp(pocket, GestureTimeline.accel(roll))
			alpha = a * (1.0 - clampf((roll - 0.85) / 0.15, 0.0, 1.0))
		var lit := clampf((since - 650.0) / 250.0, 0.0, 1.0)
		if i != 1 and lit > 0.0:
			c.draw_arc(p, BALL + 10, 0.0, TAU, 32, Color(1, 0.9, 0.5, a * lit), 5.0)
		_ball(c, p, Color(SOLID_COLS[i]), alpha, nums[i])
	for i in 3:
		_stripe(c, stripes[i], Color(STRIPE_COLS[i]), a, snums[i])
	_ball(c, Vector2(400, 430), Color("#16161B"), a, "8")
	var chip := clampf((since - 650.0) / 250.0, 0.0, 1.0)
	if chip > 0.0:
		_chip(c, Vector2(400, 180), "YOU: SOLIDS", Color(1, 0.9, 0.5), a * chip)
	var last := clampf((since - 1500.0) / 300.0, 0.0, 1.0)
	if last > 0.0:
		_chip(c, Vector2(400, 790), "THEN THE 8", Color.WHITE, a * last)


static func _demo_call(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_table(c, a)
	var called := t >= g.press_ms + 60.0
	var pockets := [
		T.position,
		Vector2(T.end.x, T.position.y),
		Vector2(T.position.x, T.end.y),
		T.end,
		Vector2(T.position.x - 6, T.position.y + T.size.y * 0.5),
		Vector2(T.end.x + 6, T.position.y + T.size.y * 0.5),
	]
	for p in pockets:
		var on: bool = called and p == CALL_POCKET
		c.draw_arc(
			p, 44, 0.0, TAU, 40, Color(1, 0.85, 0.3, a) if on else Color(1, 1, 1, 0.5 * a), 6.0
		)
	var eight := Vector2(540, 250)
	var d := (CALL_POCKET - eight).normalized()
	var cue := eight - d * 260.0
	var since := t - g.lift_ms - 250.0
	var hit := 220.0
	if since < 0.0:
		_ball(c, eight, Color("#16161B"), a, "8")
		_ball(c, cue, Color("#F4F1E6"), a)
		return
	var contact := eight - d * 2.0 * BALL
	var k := clampf(since / hit, 0.0, 1.0)
	_ball(c, cue.lerp(contact, k), Color("#F4F1E6"), a)
	var go := clampf((since - hit) / 450.0, 0.0, 1.0)
	if go < 1.0:
		_ball(c, eight.lerp(CALL_POCKET, GestureTimeline.decel(go)), Color("#16161B"), a, "8")
	if go >= 1.0:
		_chip(c, Vector2(400, 460), "WIN!", Color(1, 0.9, 0.5), a)


static func _demo_hand(c: Control, t: float, g: GestureTimeline) -> void:
	var a := fade(t, g)
	_table(c, a)
	_ball(c, Vector2(470, 300), Color("#D9312B"), a, "3")
	_stripe(c, Vector2(300, 260), Color("#2456C8"), a, "10")
	_ball(c, Vector2(560, 520), Color("#16161B"), a, "8")
	g.evaluate(t)
	var cue: Vector2 = g.from
	if t >= g.lift_ms:
		cue = g.to
	elif t >= g.press_ms:
		cue = g.pos
	c.draw_arc(cue, BALL + 16, 0.0, TAU, 32, Color(1, 1, 1, 0.45 * a), 4.0)
	_ball(c, cue, Color("#F4F1E6"), a)
	_chip(c, Vector2(400, 180), "BALL IN HAND", Color(1.0, 0.6, 0.55), a)


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


static func _poster_groups(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 150, 150), Color(CLOTH, 1.0))
	c.draw_circle(Vector2(45, 60), 16, Color(SOLID_COLS[1]))
	c.draw_circle(Vector2(105, 60), 16, Color(0.95, 0.94, 0.9))
	c.draw_rect(Rect2(89, 52, 32, 16), Color(STRIPE_COLS[0]))
	c.draw_circle(Vector2(75, 108), 16, Color("#16161B"))


static func _poster_call(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 150, 150), Color(CLOTH, 1.0))
	c.draw_circle(Vector2(130, 20), 16, Color(0.02, 0.02, 0.03))
	c.draw_arc(Vector2(130, 20), 26, 0.0, TAU, 24, Color(1, 0.85, 0.3), 4.0)
	c.draw_circle(Vector2(70, 90), 16, Color("#16161B"))


static func _poster_hand(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 150, 150), Color(CLOTH, 1.0))
	c.draw_circle(Vector2(75, 80), 16, Color("#F4F1E6"))
	c.draw_arc(Vector2(75, 80), 28, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 3.0)
