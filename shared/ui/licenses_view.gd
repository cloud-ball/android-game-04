class_name LicensesView
extends CanvasLayer
## Full-screen, scrollable open-source notices (Settings → About → "Open-source licences"). The
## Godot Engine is MIT-licensed and bundles third-party components under their own licences; their
## notices must ship with the app. The text comes from the engine itself (Engine.get_license_text,
## get_copyright_info, get_license_info), so it always matches the engine version we ship.


func _ready() -> void:
	layer = 120
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 40
	col.offset_right = -40
	col.offset_top = 60
	col.offset_bottom = -40
	col.add_theme_constant_override("separation", 24)
	bg.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	var title := UiKit.label("Open-source licences", 48, Color.WHITE, 800)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := UiKit.button("Close", Color(1, 1, 1, 0.12), Color.WHITE, 32, 96)
	close.pressed.connect(queue_free)
	top.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var body := UiKit.label(notices(), 24, Color(0.85, 0.87, 0.95), 400)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)


## The full notice text: the app's own line, Godot's licence, then every bundled component.
static func notices() -> String:
	var out := PackedStringArray()
	out.append("Playjar is made with the Godot Engine (godotengine.org).")
	out.append("")
	out.append(Engine.get_license_text())
	out.append("")
	out.append("Third-party components in the Godot Engine:")
	for item: Dictionary in Engine.get_copyright_info():
		out.append("")
		out.append(str(item.get("name", "")))
		for part: Dictionary in item.get("parts", []):
			for line in part.get("copyright", []):
				out.append("  © " + str(line))
			out.append("  Licence: " + str(part.get("license", "")))
	var texts := Engine.get_license_info()
	for key in texts:
		out.append("")
		out.append("— " + str(key) + " —")
		out.append(str(texts[key]))
	return "\n".join(out)
