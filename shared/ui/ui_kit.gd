class_name UiKit
extends RefCounted
## Shared look for the hub and every game: one palette, one font, rounded panels.
## Sizes are in canvas units of the 1080x1920 portrait base resolution.

const BG := Color(0.063, 0.071, 0.141)
const PANEL := Color(0.04, 0.05, 0.11, 0.86)
const TEXT := Color(0.96, 0.97, 1.0)
const MUTED := Color(0.68, 0.72, 0.86)
const GOLD := Color(1.0, 0.79, 0.29)
const GREEN := Color(0.24, 0.78, 0.38)
const NEON_GREEN := Color(0.4, 1.0, 0.6)
const MAGENTA := Color(1.0, 0.4, 0.88)

static var _fonts: Dictionary = {}


static func font(weight := 700) -> Font:
	if not _fonts.has(weight):
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["sans-serif", "Roboto", "Helvetica Neue", "Arial"])
		f.font_weight = weight
		_fonts[weight] = f
	return _fonts[weight]


static func label(text: String, size: int, color := TEXT, weight := 700) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func box(
	color: Color, radius := 24, border := Color.TRANSPARENT, border_w := 0, pad := 0.0
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	s.anti_aliasing = true
	return s


static func button(text: String, bg: Color, fg := TEXT, size := 44, min_h := 112) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, min_h)
	b.add_theme_font_override("font", font(800))
	b.add_theme_font_size_override("font_size", size)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, fg)
	var r := mini(min_h / 2, 40)
	b.add_theme_stylebox_override("normal", box(bg, r, Color.TRANSPARENT, 0, 24))
	b.add_theme_stylebox_override("hover", box(bg.lightened(0.08), r, Color.TRANSPARENT, 0, 24))
	b.add_theme_stylebox_override("pressed", box(bg.darkened(0.2), r, Color.TRANSPARENT, 0, 24))
	b.add_theme_stylebox_override("disabled", box(bg.darkened(0.5), r, Color.TRANSPARENT, 0, 24))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func() -> void: AudioService.play("tap"))
	return b


## A small drawn coin (no glyph needed from the system font).
static func coin(size := 36.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(
		func() -> void:
			var r := size * 0.5
			c.draw_circle(Vector2(r, r), r, GOLD)
			c.draw_circle(Vector2(r, r), r * 0.66, GOLD.darkened(0.2))
			c.draw_circle(Vector2(r, r), r * 0.5, GOLD.lightened(0.15))
	)
	return c


## In-game pause button shared by the games: a dark disc with two drawn bars, centred in a
## larger invisible touch area (set the button's size to the hit area, >= 48 dp).
static func pause_button(disc := 112.0) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var plate := Panel.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override(
		"panel", box(Color(0.03, 0.035, 0.08, 0.82), int(disc / 2), Color(1, 1, 1, 0.16), 2)
	)
	b.add_child(plate)
	center(plate, disc)
	var bars := Control.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(
		func() -> void:
			var u := disc / 96.0
			var h := 40.0 * u
			var y := (disc - h) * 0.5
			bars.draw_rect(Rect2(Vector2(disc * 0.5 - 16 * u, y), Vector2(10 * u, h)), Color.WHITE)
			bars.draw_rect(Rect2(Vector2(disc * 0.5 + 6 * u, y), Vector2(10 * u, h)), Color.WHITE)
	)
	plate.add_child(bars)
	bars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return b


## Centres a fixed-size control (e.g. an icon) inside its parent, whatever the parent's size.
static func center(ctrl: Control, side: float) -> void:
	ctrl.anchor_left = 0.5
	ctrl.anchor_top = 0.5
	ctrl.anchor_right = 0.5
	ctrl.anchor_bottom = 0.5
	ctrl.offset_left = -side * 0.5
	ctrl.offset_top = -side * 0.5
	ctrl.offset_right = side * 0.5
	ctrl.offset_bottom = side * 0.5


## Height of the notch/status bar in canvas units (0 on desktop).
static func safe_top(node: Node) -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.y <= 0:
		return 0.0
	return maxf(0.0, float(safe.position.y)) * node.get_viewport().get_visible_rect().size.y / win.y


static func format_int(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out
