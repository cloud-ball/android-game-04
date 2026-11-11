class_name GameIcon
extends Control
## Simple vector art for hub cards, drawn in code (original, no imported images).

var kind := ""
var accent := Color.WHITE


func _init(icon_kind := "", accent_color := Color.WHITE) -> void:
	kind = icon_kind
	accent = accent_color
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := size
	var u := minf(s.x, s.y) / 10.0
	var c := s * Vector2(0.5, 0.42)
	match kind:
		"snake":
			_snake(c, u)
		"pool":
			_pool(c, u)
		"blocks":
			_blocks(c, u)
		"chess":
			_chess(c, u)
		"carrom":
			_carrom(c, u)
		"penalty":
			_penalty(c, u)
		"golf":
			_golf(c, u)
		"drive":
			_drive(c, u)


func _snake(c: Vector2, u: float) -> void:
	var grid := Color(0.3, 0.45, 1.0, 0.35)
	for i in range(-4, 5):
		draw_line(c + Vector2(i * u, -3.5 * u), c + Vector2(i * u, 3.5 * u), grid, 2.0)
	for j in range(-3, 4):
		draw_line(c + Vector2(-4 * u, j * u), c + Vector2(4 * u, j * u), grid, 2.0)
	var cells := [Vector2(-3, 1), Vector2(-2, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(0, 0)]
	cells.append_array([Vector2(1, 0), Vector2(1, -1)])
	for i in cells.size():
		var k := 0.55 + 0.45 * float(i) / cells.size()
		var p: Vector2 = c + cells[i] * u
		draw_rect(Rect2(p + Vector2(0.08, 0.08) * u, Vector2(0.84, 0.84) * u), accent * k)
	draw_circle(c + Vector2(2.5, -1.5) * u, 0.35 * u, UiKit.GOLD)
	var rival := [Vector2(-1, -2), Vector2(-2, -2), Vector2(-3, -2)]
	for p in rival:
		draw_rect(
			Rect2(c + p * u + Vector2(0.08, 0.08) * u, Vector2(0.84, 0.84) * u), UiKit.MAGENTA
		)


func _pool(c: Vector2, u: float) -> void:
	draw_rect(Rect2(c - Vector2(4.2, 3) * u, Vector2(8.4, 6) * u), Color(0.35, 0.2, 0.1))
	draw_rect(Rect2(c - Vector2(3.7, 2.5) * u, Vector2(7.4, 5) * u), accent.darkened(0.25))
	var balls := [[Vector2(1.2, 0), UiKit.GOLD], [Vector2(1.9, -0.4), Color.RED]]
	balls.append_array([[Vector2(1.9, 0.4), Color(0.2, 0.3, 1)], [Vector2(-1.8, 0), Color.WHITE]])
	for b in balls:
		draw_circle(c + b[0] * u, 0.38 * u, b[1])


func _blocks(c: Vector2, u: float) -> void:
	draw_rect(Rect2(c - Vector2(2.5, 3.6) * u, Vector2(5, 7.2) * u), Color(1, 1, 1, 0.12))
	var tones := [accent, accent.darkened(0.25), Color(0.3, 0.55, 1.0), Color(0.95, 0.7, 0.3)]
	for y in 3:
		for x in 5:
			if (x + y * 2) % 7 != 0:
				var r := Rect2(c + Vector2(x - 2.5, 2.6 - y) * u, Vector2(0.92, 0.92) * u)
				draw_rect(r, tones[(x + y) % tones.size()])
	for p in [Vector2(-0.5, -1.4), Vector2(0.5, -1.4), Vector2(0.5, -2.4), Vector2(0.5, -0.4)]:
		draw_rect(Rect2(c + p * u, Vector2(0.92, 0.92) * u), accent.lightened(0.2))


func _chess(c: Vector2, u: float) -> void:
	for y in 4:
		for x in 4:
			var col := accent if (x + y) % 2 == 0 else accent.darkened(0.55)
			draw_rect(Rect2(c + Vector2(x - 2, y - 2) * u * 1.4, Vector2.ONE * u * 1.4), col)
	var base := c + Vector2(0, 1.2) * u
	var body := PackedVector2Array([base + Vector2(-1.1, 0) * u, base + Vector2(1.1, 0) * u])
	body.append_array([base + Vector2(0.45, -2.2) * u, base + Vector2(-0.45, -2.2) * u])
	draw_colored_polygon(body, Color(0.97, 0.95, 0.9))
	draw_circle(base + Vector2(0, -2.6) * u, 0.7 * u, Color(0.97, 0.95, 0.9))


func _carrom(c: Vector2, u: float) -> void:
	draw_rect(Rect2(c - Vector2(3.6, 3.6) * u, Vector2(7.2, 7.2) * u), Color(0.4, 0.22, 0.1))
	draw_rect(Rect2(c - Vector2(3.2, 3.2) * u, Vector2(6.4, 6.4) * u), accent)
	draw_arc(c, 1.3 * u, 0, TAU, 32, Color(0.4, 0.25, 0.15), 3.0)
	for p in [Vector2(-3.2, -3.2), Vector2(3.2, -3.2), Vector2(-3.2, 3.2), Vector2(3.2, 3.2)]:
		draw_circle(c + p * u, 0.45 * u, Color(0.1, 0.07, 0.05))
	draw_circle(c, 0.35 * u, Color(0.85, 0.15, 0.25))
	for p in [Vector2(0.8, 0.2), Vector2(-0.7, 0.5), Vector2(0.1, -0.9)]:
		draw_circle(c + p * u, 0.32 * u, Color(0.15, 0.1, 0.08))


func _penalty(c: Vector2, u: float) -> void:
	var w := Color(0.97, 0.97, 1.0)
	draw_rect(Rect2(c - Vector2(4, 2) * u, Vector2(8, 3.2) * u), Color(1, 1, 1, 0.15))
	draw_polyline(
		PackedVector2Array(
			(
				[c + Vector2(-4, 1.2) * u, c + Vector2(-4, -2) * u, c + Vector2(4, -2) * u]
				+ [c + Vector2(4, 1.2) * u]
			)
		),
		w,
		5.0
	)
	draw_circle(c + Vector2(1.5, 2.6) * u, 0.6 * u, w)


func _golf(c: Vector2, u: float) -> void:
	draw_circle(c + Vector2(0, 1.6) * u, 3.0 * u, accent.darkened(0.3))
	draw_line(c + Vector2(0.5, 1.6) * u, c + Vector2(0.5, -2.6) * u, Color.WHITE, 4.0)
	var flag := PackedVector2Array([c + Vector2(0.5, -2.6) * u, c + Vector2(2.4, -2.0) * u])
	flag.append(c + Vector2(0.5, -1.4) * u)
	draw_colored_polygon(flag, Color(0.9, 0.15, 0.2))
	draw_circle(c + Vector2(-1.4, 2.4) * u, 0.3 * u, Color.WHITE)


func _drive(c: Vector2, u: float) -> void:
	var road := PackedVector2Array([c + Vector2(-1.2, -3.5) * u, c + Vector2(1.2, -3.5) * u])
	road.append_array([c + Vector2(3.8, 3.5) * u, c + Vector2(-3.8, 3.5) * u])
	draw_colored_polygon(road, Color(0.22, 0.23, 0.27))
	for i in 3:
		var y := -2.6 + i * 2.0
		draw_line(c + Vector2(0, y) * u, c + Vector2(0, y + 0.9) * u, UiKit.GOLD, 4.0)
	draw_rect(Rect2(c + Vector2(-1.3, 0.6) * u, Vector2(2.6, 2.4) * u), accent)
	draw_rect(Rect2(c + Vector2(-1.0, 0.9) * u, Vector2(2.0, 0.8) * u), accent.darkened(0.45))
