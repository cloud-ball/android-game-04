class_name IconGlyph
extends Control
## Small vector icons drawn in code (no image assets): gear, music, sound, sound_off, vibrate,
## close, info. Scales to the control's size; colour via `color`.

var kind := ""
var color := Color.WHITE
## Colour of the gear's centre hole (match the background behind the icon).
var hole := Color(0.08, 0.09, 0.2)


func _init(icon_kind := "", icon_color := Color.WHITE, side := 64.0) -> void:
	kind = icon_kind
	color = icon_color
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_kind(icon_kind: String) -> void:
	kind = icon_kind
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var u := s / 100.0
	match kind:
		"gear":
			_gear(o, u)
		"music":
			_music(o, u)
		"sound", "sound_off":
			_sound(o, u, kind == "sound_off")
		"vibrate":
			_vibrate(o, u)
		"motion":
			_motion(o, u)
		"close":
			draw_line(o + Vector2(26, 26) * u, o + Vector2(74, 74) * u, color, 10 * u, true)
			draw_line(o + Vector2(74, 26) * u, o + Vector2(26, 74) * u, color, 10 * u, true)
		"info":
			draw_arc(o + Vector2(50, 50) * u, 40 * u, 0, TAU, 40, color, 7 * u, true)
			draw_circle(o + Vector2(50, 30) * u, 6 * u, color)
			draw_line(o + Vector2(50, 45) * u, o + Vector2(50, 74) * u, color, 9 * u, true)


func _gear(o: Vector2, u: float) -> void:
	var c := o + Vector2(50, 50) * u
	for i in 8:
		var a := TAU * i / 8.0
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x)
		var tooth := PackedVector2Array(
			[
				c + dir * 28 * u - side * 9 * u,
				c + dir * 44 * u - side * 7 * u,
				c + dir * 44 * u + side * 7 * u,
				c + dir * 28 * u + side * 9 * u,
			]
		)
		draw_colored_polygon(tooth, color)
	draw_circle(c, 33 * u, color)
	draw_circle(c, 14 * u, hole)


func _music(o: Vector2, u: float) -> void:
	draw_circle(o + Vector2(30, 74) * u, 13 * u, color)
	draw_circle(o + Vector2(70, 66) * u, 13 * u, color)
	draw_line(o + Vector2(41, 74) * u, o + Vector2(41, 22) * u, color, 7 * u, true)
	draw_line(o + Vector2(81, 66) * u, o + Vector2(81, 14) * u, color, 7 * u, true)
	var beam := PackedVector2Array(
		[o + Vector2(38, 18) * u, o + Vector2(84, 8) * u, o + Vector2(84, 22) * u]
	)
	beam.append(o + Vector2(38, 32) * u)
	draw_colored_polygon(beam, color)


func _sound(o: Vector2, u: float, muted: bool) -> void:
	var body := PackedVector2Array(
		[o + Vector2(12, 38) * u, o + Vector2(32, 38) * u, o + Vector2(54, 18) * u]
	)
	body.append_array([o + Vector2(54, 82) * u, o + Vector2(32, 62) * u, o + Vector2(12, 62) * u])
	draw_colored_polygon(body, color)
	if muted:
		draw_line(o + Vector2(66, 36) * u, o + Vector2(90, 64) * u, color, 7 * u, true)
		draw_line(o + Vector2(90, 36) * u, o + Vector2(66, 64) * u, color, 7 * u, true)
		return
	draw_arc(o + Vector2(54, 50) * u, 16 * u, -0.9, 0.9, 16, color, 7 * u, true)
	draw_arc(o + Vector2(54, 50) * u, 32 * u, -0.9, 0.9, 20, color, 7 * u, true)


## Reduce motion: a ball with a short motion trail behind it.
func _motion(o: Vector2, u: float) -> void:
	draw_circle(o + Vector2(66, 50) * u, 18 * u, color)
	for i in 3:
		var y := 36.0 + i * 14.0
		draw_line(o + Vector2(14 + i * 6, y) * u, o + Vector2(42, y) * u, color, 6 * u, true)


func _vibrate(o: Vector2, u: float) -> void:
	var phone := Rect2(o + Vector2(32, 14) * u, Vector2(36, 72) * u)
	draw_rect(phone, color, false, 7 * u)
	draw_line(o + Vector2(44, 76) * u, o + Vector2(56, 76) * u, color, 5 * u, true)
	for sgn in [-1.0, 1.0]:
		var x0: float = 50.0 + sgn * 30.0
		var x1: float = 50.0 + sgn * 40.0
		var pts := PackedVector2Array()
		for i in 5:
			pts.append(o + Vector2(x0 if i % 2 == 0 else x1, 30 + i * 10) * u)
		draw_polyline(pts, color, 5 * u, true)
