class_name SettingsSheet
extends Control
## Bottom sheet with the player's settings, shared by the hub and the in-game pause menu.
## Large rows (icon, label, hint, switch); the whole row is a tap target. Closes on Done, the
## close button, a tap on the dimmed area, or Android back (callers ask `is_open()` first).

signal closed

const ROWS := [
	["music", "music", "Music", "Background music in menus and games"],
	["sound", "sound", "Sound effects", "Taps, orbs, crashes and wins"],
	["haptics", "vibrate", "Vibration", "Short buzzes when you eat or crash"],
	["reduce_motion", "motion", "Reduce motion", "Still pictures instead of how-to animations"],
]
const SHEET_BG := Color(0.09, 0.1, 0.21)

var _shade: ColorRect
var _sheet: PanelContainer
var _switches: Dictionary = {}
var _open := false


func _ready() -> void:
	# Already in the tree here: set offsets too, or the sheet keeps its initial 0x0 size.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.6)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.gui_input.connect(_on_shade_input)
	add_child(_shade)
	_sheet = PanelContainer.new()
	var style := UiKit.box(SHEET_BG, 0, Color(1, 1, 1, 0.08), 0, 0)
	style.corner_radius_top_left = 56
	style.corner_radius_top_right = 56
	style.content_margin_left = 56
	style.content_margin_right = 56
	style.content_margin_top = 28
	style.content_margin_bottom = 64
	_sheet.add_theme_stylebox_override("panel", style)
	_sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_sheet.add_child(col)
	col.add_child(_handle())
	col.add_child(_title_row())
	col.add_child(_spacer(20))
	for row in ROWS:
		col.add_child(_setting_row(row[0], row[1], row[2], row[3]))
		col.add_child(_divider())
	col.add_child(_spacer(32))
	col.add_child(_about())
	col.add_child(_spacer(36))
	var done := UiKit.button("Done", UiKit.GREEN, Color.WHITE, 52, 136)
	done.pressed.connect(close)
	col.add_child(done)


func is_open() -> bool:
	return _open


func open() -> void:
	for key in _switches:
		(_switches[key] as ToggleSwitch).set_pressed(bool(SettingsService.get_value(key)))
	_open = true
	visible = true
	await get_tree().process_frame  # let the sheet compute its height before sliding
	var h := _sheet.size.y
	_sheet.position.y = size.y
	_shade.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_sheet, "position:y", size.y - h, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_OUT
	)
	tw.tween_property(_shade, "modulate:a", 1.0, 0.2)


func close() -> void:
	if not _open:
		return
	_open = false
	var tw := create_tween().set_parallel()
	tw.tween_property(_sheet, "position:y", size.y, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(
		Tween.EASE_IN
	)
	tw.tween_property(_shade, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(
		func() -> void:
			visible = false
			closed.emit()
	)


func _on_shade_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and not mb.pressed:
		close()


func _handle() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 30)
	c.draw.connect(
		func() -> void:
			var w := 110.0
			var r := Rect2(Vector2((c.size.x - w) * 0.5, 4), Vector2(w, 12))
			c.draw_rect(r, Color(1, 1, 1, 0.25))
	)
	return c


func _title_row() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 120)
	var title := UiKit.label("Settings", 64, Color.WHITE, 900)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var x := Button.new()
	x.focus_mode = Control.FOCUS_NONE
	x.custom_minimum_size = Vector2(104, 104)
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed"]:
		var bg := Color(1, 1, 1, 0.16 if st == "pressed" else 0.08)
		x.add_theme_stylebox_override(st, UiKit.box(bg, 52))
	x.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var icon := IconGlyph.new("close", UiKit.MUTED, 64)
	UiKit.center(icon, 64)
	x.add_child(icon)
	x.pressed.connect(close)
	row.add_child(x)
	return row


func _setting_row(key: String, icon_kind: String, title: String, hint: String) -> Control:
	var row := Button.new()
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0, 160)
	row.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	row.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	row.add_theme_stylebox_override("pressed", UiKit.box(Color(1, 1, 1, 0.05), 28))
	row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 32)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(h)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiKit.box(Color(0.3, 0.45, 1.0, 0.22), 30))
	badge.custom_minimum_size = Vector2(104, 104)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glyph := IconGlyph.new(icon_kind, Color(0.72, 0.8, 1.0), 60)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(glyph)
	h.add_child(badge)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(UiKit.label(title, 46, Color.WHITE, 800))
	var sub := UiKit.label(hint, 30, UiKit.MUTED, 500)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(sub)
	h.add_child(text)
	var sw := ToggleSwitch.new(bool(SettingsService.get_value(key)))
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.toggled.connect(func(on: bool) -> void: _apply(key, on))
	h.add_child(sw)
	_switches[key] = sw
	row.pressed.connect(sw.toggle)
	return row


func _apply(key: String, on: bool) -> void:
	SettingsService.set_value(key, on)
	AudioService.play("tap")
	if key == "haptics" and on:
		AudioService.buzz(25)


func _about() -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override(
		"panel", UiKit.box(Color(1, 1, 1, 0.05), 32, Color.TRANSPARENT, 0, 32)
	)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 26)
	box.add_child(h)
	var icon := IconGlyph.new("info", UiKit.MUTED, 64)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	text.add_child(UiKit.label("Pocket Arena 8 · v%s" % version, 34, Color.WHITE, 700))
	var note := UiKit.label(
		"Plays offline. No account, no ads, no data collected.", 28, UiKit.MUTED, 500
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(note)
	h.add_child(text)
	return box


static func _divider() -> Control:
	var d := ColorRect.new()
	d.color = Color(1, 1, 1, 0.07)
	d.custom_minimum_size = Vector2(0, 2)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


static func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
