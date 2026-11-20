extends Node
## UI audit (debug builds; Boot --uiaudit). Opens every screen of the hub and of each released game
## - start screen, how-to, play HUD, pause, settings, end screen, licences - and checks every
## visible, enabled button: a tap at its centre reaches it (nothing on top), it is fully on
## screen, it is big enough for a finger, it does not overlap another button, and its text fits.
## Visible labels must be on screen too. Saves a screenshot per screen and a report to
## user://audit/<w>x<h>/. Run at several window shapes with --resolution.

const MIN_PX := 96.0  # ~36 dp on a 411 dp-wide phone: smaller is flagged
const DP := 411.0 / 1080.0  # design px -> dp on a typical phone

var _dir := ""
var _lines: PackedStringArray = []
var _issues := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var size := get_viewport().get_visible_rect().size
	_dir = "user://audit/%dx%d/" % [int(size.x), int(size.y)]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	_log("UI audit - viewport %d x %d design px" % [int(size.x), int(size.y)])
	await _frames(45)
	await _hub()
	for m in GameRegistry.scan("res://games"):
		if m.enabled:
			await _game(m.id)
	_log("TOTAL ISSUES: %d" % _issues)
	var f := FileAccess.open(_dir + "report.txt", FileAccess.WRITE)
	f.store_string("\n".join(_lines))
	f.close()
	get_tree().quit()


func _hub() -> void:
	var hub := get_tree().current_scene
	await _audit("hub", [hub])
	var settings: Node = hub.get("_settings")
	settings.call("open")
	await _frames(30)
	await _audit("hub_settings", [settings])
	var lic := _button_with_text(settings, "licen")
	if lic != null:
		lic.pressed.emit()
		await _frames(30)
		var views := get_tree().root.find_children("*", "LicensesView", true, false)
		await _audit("hub_licences", views)
		for v in views:
			v.queue_free()
		await _frames(5)
	settings.call("close")
	await _frames(20)


func _game(id: String) -> void:
	SceneRouter.open_game(id, {}, true)
	await SceneRouter.scene_changed
	await _frames(60)
	var shells := get_tree().current_scene.find_children("*", "GameShell", true, false)
	if shells.is_empty():
		_issue("%s: no GameShell found" % id)
		return
	var shell: GameShell = shells[0]
	if shell.howto_open():
		shell.close_howto()
		await _frames(10)
	shell.show_start("Best 12 · 3 wins")
	await _frames(20)
	await _audit(id + "_start", [shell._start])
	shell.hide_panels()
	shell.show_howto()
	await _frames(40)
	await _audit(id + "_howto", [shell._howto])
	shell.close_howto()
	await _frames(10)
	shell.play_requested.emit("medium", shell.mode)
	await _frames(240)
	await _audit(id + "_play", [get_tree().current_scene])
	shell.pause_requested.emit()
	await _frames(20)
	await _audit(id + "_pause", [shell._pause])
	shell._settings.open()
	await _frames(30)
	await _audit(id + "_settings", [shell._settings])
	shell._settings.close()
	await _frames(20)
	shell.resume_requested.emit()
	await _frames(20)
	shell.hide_panels()
	var end := {
		"title": "YOU WIN!",
		"color": UiKit.GOLD,
		"cause": "A long cause line to see how the end card copes with two lines of text",
		"stats": "Best 1,234 · 12 wins of 20",
		"coins": 120,
		"daily": "Daily goal done · +150 coins",
	}
	shell.show_end(end)
	await _frames(30)
	await _audit(id + "_end", [shell._end])
	shell.hide_panels()
	SceneRouter.back_to_hub()
	await SceneRouter.scene_changed
	await _frames(40)


## Checks the buttons and labels under `roots` (the panel that is meant to be active on this
## screen); the hit test still sees everything drawn on top of them.
func _audit(screen: String, roots: Array) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_dir + screen + ".png")
	var vp := get_viewport().get_visible_rect()
	var buttons: Array[BaseButton] = []
	var found: Array[Node] = []
	for root: Node in roots:
		found.append_array(root.find_children("*", "BaseButton", true, false))
	for n in found:
		var b := n as BaseButton
		if (
			b.is_visible_in_tree()
			and not b.disabled
			and b.mouse_filter != Control.MOUSE_FILTER_IGNORE
		):
			buttons.append(b)
	_log("[%s] %d buttons" % [screen, buttons.size()])
	for b in buttons:
		var r := b.get_global_rect()
		var tag := _name(b)
		if r.size.x < 1.0 or r.size.y < 1.0:
			_issue("%s: %s has no size (%s) - cannot be tapped" % [screen, tag, r.size])
			continue
		if minf(r.size.x, r.size.y) < MIN_PX:
			_issue(
				(
					"%s: %s small %dx%d px (~%dx%d dp)"
					% [screen, tag, r.size.x, r.size.y, r.size.x * DP, r.size.y * DP]
				)
			)
		if not vp.encloses(r.grow(-1.0)):
			_issue("%s: %s partly off screen %s (screen %s)" % [screen, tag, r, vp.size])
		var hit := _hovered(r.get_center())
		if hit != b and (hit == null or not b.is_ancestor_of(hit)):
			_issue("%s: %s blocked at its centre by %s" % [screen, tag, _name(hit)])
		var b_text := b as Button
		if b_text != null and b_text.text != "" and not b_text.clip_text:
			var font := b_text.get_theme_font("font")
			var fs := b_text.get_theme_font_size("font_size")
			var w := font.get_string_size(b_text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if w > r.size.x - 8.0:
				_issue("%s: %s text wider (%d) than the button (%d)" % [screen, tag, w, r.size.x])
	for i in buttons.size():
		for j in range(i + 1, buttons.size()):
			var a := buttons[i]
			var c := buttons[j]
			if a.is_ancestor_of(c) or c.is_ancestor_of(a):
				continue
			var ov := a.get_global_rect().intersection(c.get_global_rect())
			if ov.size.x > 4.0 and ov.size.y > 4.0:
				_issue("%s: %s overlaps %s" % [screen, _name(a), _name(c)])
	var labels: Array[Node] = []
	for root: Node in roots:
		labels.append_array(root.find_children("*", "Label", true, false))
	for n in labels:
		var l := n as Label
		if not l.is_visible_in_tree() or l.text.strip_edges() == "" or l.modulate.a < 0.05:
			continue
		var span := _text_span(l)
		if span.x < vp.position.x - 2.0 or span.y > vp.end.x + 2.0:
			_issue(
				(
					"%s: text '%s' runs off screen (x %d..%d)"
					% [screen, l.text.left(30), span.x, span.y]
				)
			)


## Horizontal extent of a label's text on screen (not its box: centred labels are wide).
func _text_span(l: Label) -> Vector2:
	var r := l.get_global_rect()
	var font := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var widest := 0.0
	for line in l.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var scale := l.get_global_transform().get_scale().x
	widest *= scale
	if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
		widest = minf(widest, r.size.x)
	match l.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			return Vector2(r.get_center().x - widest * 0.5, r.get_center().x + widest * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return Vector2(r.end.x - widest, r.end.x)
	return Vector2(r.position.x, r.position.x + widest)


## The control a touch at `p` lands on (topmost one taking input), via a hover probe.
func _hovered(p: Vector2) -> Control:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	get_viewport().push_input(ev, true)
	return get_viewport().gui_get_hovered_control()


func _button_with_text(root: Node, part: String) -> Button:
	for n in root.find_children("*", "Button", true, false):
		if (n as Button).text.to_lower().contains(part):
			return n
	return null


func _name(c: Control) -> String:
	if c == null:
		return "nothing"
	var b := c as Button
	var text := b.text.replace("\n", " ").left(24) if b != null and b.text != "" else ""
	var label := "'%s'" % text if text != "" else str(c.get_path()).get_file()
	return "%s %s" % [c.get_class(), label]


func _issue(text: String) -> void:
	_issues += 1
	_log("  ! " + text)


func _log(text: String) -> void:
	_lines.append(text)
	print("[ui-audit] " + text)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
