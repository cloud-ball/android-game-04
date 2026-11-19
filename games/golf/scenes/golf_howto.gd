class_name GolfHowto
extends RefCounted
## Fairway Flick how-to cards (HowtoDeck, 920 x 920 design units): a top-down sketch of a hole in
## the game's own colours. 1) drag back and let go (the ball rolls the other way, into the cup);
## 2) Rush: first ball in the cup wins; 3) Tour: par or better earns stars.

const CARPET := Color(0.14, 0.58, 0.26)
const RAIL := Color(0.86, 0.66, 0.42)
const CAP := Color(0.98, 0.95, 0.88)
const LAWN := Color(0.28, 0.46, 0.2)
const RIVALS := [Color.WHITE, Color("#FF7A59"), Color("#5EC8FF"), Color("#FFD84D")]
const BALL_AT := Vector2(460, 560)
const CUP_AT := Vector2(460, 170)


static func cards() -> Array:
	return [
		{
			"title": "Drag back, then let go",
			"sub": "The ball goes the other way. Pull further for more power.",
			"demo": _demo_shot,
			"poster": _poster_shot,
			"gesture":
			GestureTimeline.new(
				"drag", BALL_AT + Vector2(0, 30), BALL_AT + Vector2(0, 190), 3, 900
			),
			"try": "drag",
		},
		{
			"title": "First in the cup wins",
			"sub": "Rush: three CPU golfers play the same hole at once. Three holes a match.",
			"demo": _demo_rush,
			"poster": _poster_rush,
			"gesture": GestureTimeline.new("none", Vector2.ZERO, Vector2.ZERO, 1, 2600),
			"modes": ["rush"],
		},
		{
			"title": "Beat par for stars",
			"sub": "Tour: play all nine holes. Par 1 star, birdie 2, better 3.",
			"demo": _demo_tour,
			"poster": _poster_tour,
			"gesture": GestureTimeline.new("none", Vector2.ZERO, Vector2.ZERO, 1, 2800),
			"modes": ["tour"],
		},
	]


# --- demos ---------------------------------------------------------------------------------------


static func _demo_shot(c: Control, t: float, g: GestureTimeline) -> void:
	var a := _fade(t, g)
	_lane(c, Rect2(310, 90, 300, 560), a)
	_cup(c, CUP_AT, a)
	var pull := clampf((t - g.press_ms) / maxf(1.0, g.lift_ms - g.press_ms), 0.0, 1.0)
	if t < g.press_ms:
		pull = 0.0
	if t < g.lift_ms:
		# Aiming: dotted guide up the lane and a power ring around the ball.
		if pull > 0.0:
			for k in int(2 + pull * 9):
				c.draw_circle(BALL_AT - Vector2(0, 40 + 42 * k), 7.0, Color(1, 1, 1, 0.85 * a))
			c.draw_arc(
				BALL_AT, 64.0, -PI * 0.5, -PI * 0.5 + TAU * pull, 40, Color(1, 0.85, 0.4, a), 10.0
			)
		_ball(c, BALL_AT, Color.WHITE, a)
		return
	# Released: the ball rolls up and drops into the cup.
	var k := clampf((t - g.lift_ms) / 700.0, 0.0, 1.0)
	var e := 1.0 - (1.0 - k) * (1.0 - k)
	var p := BALL_AT.lerp(CUP_AT, e)
	if k < 1.0:
		_ball(c, p, Color.WHITE, a)
	else:
		c.draw_circle(CUP_AT + Vector2(0, -70), 26.0, Color(1, 0.82, 0.18, a))


static func _demo_rush(c: Control, t: float, g: GestureTimeline) -> void:
	var a := _fade(t, g)
	var lanes := [190.0, 360.0, 560.0, 730.0]
	var finish := [0.75, 0.88, 0.55, 0.95]  # share of the race each ball needs; sky blue is first
	var winner := 2
	var d := clampf(t / 2200.0, 0.0, 1.0)
	for i in 4:
		var x: float = lanes[i]
		_lane(c, Rect2(x - 70, 140, 140, 640), a)
		_cup(c, Vector2(x, 200), a)
		var k := minf(1.0, d / finish[i])
		if k < 1.0:
			_ball(c, Vector2(x, lerpf(720.0, 200.0, k)), RIVALS[i], a)
		if i == winner and k >= 1.0:
			_label(c, "WINS!", Vector2(x, 110), Color(1, 0.82, 0.18, a), 40)


static func _demo_tour(c: Control, t: float, g: GestureTimeline) -> void:
	var a := _fade(t, g)
	var earned := [1, 2, 1, 3, 1, 2, 0, 1, 2]
	var shown := int(clampf(t / 260.0, 0.0, 9.0))
	for i in 9:
		var at := Vector2(150 + (i % 3) * 310, 200 + (i / 3) * 250)
		c.draw_circle(at, 78.0, Color(CARPET, 0.9 * a))
		_label(c, str(i + 1), at + Vector2(0, -8), Color(1, 1, 1, a), 52)
		if i < shown:
			var s := "★".repeat(earned[i]) + "☆".repeat(3 - earned[i])
			_label(c, s, at + Vector2(0, 62), Color(1, 0.82, 0.29, a), 40)


# --- posters (150 x 150, reduce motion) ----------------------------------------------------------


static func _poster_shot(c: Control) -> void:
	c.draw_rect(Rect2(45, 10, 60, 130), CARPET)
	c.draw_circle(Vector2(75, 30), 9.0, Color(0.03, 0.03, 0.03))
	for k in 4:
		c.draw_circle(Vector2(75, 100 - 16 * k), 3.5, Color.WHITE)
	c.draw_circle(Vector2(75, 112), 10.0, Color.WHITE)


static func _poster_rush(c: Control) -> void:
	for i in 4:
		var x := 25.0 + i * 33.0
		c.draw_circle(Vector2(x, 40 + (i % 2) * 40 + i * 10), 11.0, RIVALS[i])
	c.draw_circle(Vector2(75, 135), 8.0, Color(0.03, 0.03, 0.03))


static func _poster_tour(c: Control) -> void:
	_label(c, "★★☆", Vector2(75, 70), Color(1, 0.82, 0.29), 46)


# --- drawing -------------------------------------------------------------------------------------


static func _lane(c: Control, r: Rect2, a: float) -> void:
	c.draw_rect(r.grow(18.0), Color(RAIL, a))
	c.draw_rect(r.grow(18.0), Color(CAP, a), false, 6.0)
	c.draw_rect(r, Color(CARPET, a))


static func _cup(c: Control, at: Vector2, a: float) -> void:
	c.draw_circle(at, 22.0, Color(CAP, a))
	c.draw_circle(at, 15.0, Color(0.03, 0.03, 0.03, a))
	c.draw_line(at, at + Vector2(0, -90), Color(1, 1, 1, a), 5.0)
	c.draw_colored_polygon(
		PackedVector2Array([at + Vector2(0, -90), at + Vector2(46, -76), at + Vector2(0, -62)]),
		Color(1, 0.82, 0.18, a)
	)


static func _ball(c: Control, at: Vector2, col: Color, a: float) -> void:
	c.draw_circle(at + Vector2(3, 5), 22.0, Color(0, 0, 0, 0.25 * a))
	c.draw_circle(at, 21.0, Color(col, a))
	c.draw_circle(at + Vector2(-7, -7), 6.0, Color(1, 1, 1, 0.7 * a))


static func _label(c: Control, text: String, centre: Vector2, col: Color, size: int) -> void:
	var font := UiKit.font(900)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	c.draw_string(font, centre + Vector2(-w * 0.5, size * 0.35), text, 0, -1, size, col)


static func _fade(t: float, g: GestureTimeline) -> float:
	return clampf(minf(t / 200.0, (g.loop_ms - t) / 300.0), 0.0, 1.0)
