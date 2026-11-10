extends Control
## Launcher: header with coins, today's challenge, a card per registered game.
## Launch -> tap a card -> tap PLAY = two taps to gameplay.

var _coins_label: Label
var _toast: Label
var _settings: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Economy.coins_changed.connect(
		func(total: int) -> void: _coins_label.text = UiKit.format_int(total)
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _settings != null and _settings.visible:
			_settings.visible = false
		else:
			get_tree().quit()


func _build() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var grad := Gradient.new()
	grad.set_color(0, Color(0.09, 0.1, 0.22))
	grad.set_color(1, Color(0.17, 0.09, 0.27))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0.3, 1)
	bg.texture = tex
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", 40 + int(UiKit.safe_top(self)))
	margin.add_theme_constant_override("margin_bottom", 48)
	scroll.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 32)
	margin.add_child(col)

	col.add_child(_header())
	col.add_child(_daily_card())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 28)
	for m in GameRegistry.all():
		grid.add_child(_game_card(m))
	col.add_child(grid)
	var foot := UiKit.label("More games arrive in free updates", 30, UiKit.MUTED, 500)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(foot)

	_toast = UiKit.label("", 36, UiKit.TEXT)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.position.y -= 220
	_toast.modulate.a = 0.0
	add_child(_toast)
	_settings = _settings_panel()
	add_child(_settings)


func _header() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 32, Color.TRANSPARENT, 0, 32))
	var row := HBoxContainer.new()
	panel.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_override("bold_font", UiKit.font(900))
	title.add_theme_font_size_override("bold_font_size", 62)
	title.text = "[b]POCKET ARENA [color=#ffc94a]8[/color][/b]"
	left.add_child(title)
	left.add_child(UiKit.label("Play the CPU · offline", 30, UiKit.MUTED, 500))
	row.add_child(left)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	var coins := HBoxContainer.new()
	coins.alignment = BoxContainer.ALIGNMENT_END
	coins.add_theme_constant_override("separation", 12)
	coins.add_child(UiKit.coin(40))
	_coins_label = UiKit.label(UiKit.format_int(Economy.coins()), 44, UiKit.GOLD, 800)
	coins.add_child(_coins_label)
	right.add_child(coins)
	var gear := UiKit.button("Settings", Color(1, 1, 1, 0.1), UiKit.MUTED, 28, 64)
	gear.pressed.connect(func() -> void: _settings.visible = true)
	right.add_child(gear)
	row.add_child(right)
	return panel


func _daily_card() -> Control:
	var day := DailyChallenge.today()
	var ch := DailyChallenge.for_day(day)
	var done := DailyChallenge.done_today(SaveService.data["profile"], day)
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(0, 190)
	var col_a := Color(1.0, 0.55, 0.25) if not done else Color(0.25, 0.6, 0.4)
	var col_b := Color(0.93, 0.3, 0.5) if not done else Color(0.2, 0.45, 0.45)
	for st in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(st, UiKit.box(col_a.lerp(col_b, 0.5), 32))
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 36
	inner.offset_top = 26
	inner.add_theme_constant_override("separation", 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(UiKit.label("DAILY CHALLENGE", 28, Color(1, 1, 1, 0.85), 800))
	var m := GameRegistry.get_manifest(ch.game)
	var game_name := m.display_name if m != null else ""
	inner.add_child(UiKit.label("%s · %s" % [ch.text, game_name], 42, Color.WHITE, 800))
	var reward := "Done today · new challenge tomorrow" if done else "+%d coins" % ch.reward
	inner.add_child(UiKit.label(reward, 30, Color(1, 1, 1, 0.9), 600))
	card.add_child(inner)
	card.pressed.connect(func() -> void: _open(ch.game))
	return card


func _game_card(m: GameManifest) -> Control:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_NONE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 330)
	var border := m.accent if m.enabled else Color(1, 1, 1, 0.25)
	var bg := m.accent_dark if m.enabled else m.accent_dark.darkened(0.35)
	card.add_theme_stylebox_override("normal", UiKit.box(bg, 30, border, 4))
	card.add_theme_stylebox_override("hover", UiKit.box(bg.lightened(0.05), 30, border, 4))
	card.add_theme_stylebox_override("pressed", UiKit.box(bg.darkened(0.2), 30, border, 4))
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var icon := GameIcon.new(m.icon_kind, m.accent)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_bottom = -110
	icon.offset_top = 16
	if not m.enabled:
		icon.modulate = Color(1, 1, 1, 0.45)
	card.add_child(icon)

	var name_box := VBoxContainer.new()
	name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	name_box.position = Vector2(28, -118)
	name_box.add_theme_constant_override("separation", 0)
	name_box.add_child(UiKit.label(m.display_name, 40, Color.WHITE, 800))
	name_box.add_child(UiKit.label(m.subtitle, 28, UiKit.MUTED, 500))
	card.add_child(name_box)

	var pill := UiKit.label(
		" PLAY " if m.enabled else " %s " % m.coming_label,
		28,
		Color.WHITE if m.enabled else UiKit.GOLD,
		900
	)
	var pill_bg := UiKit.GREEN if m.enabled else Color(0, 0, 0, 0.55)
	pill.add_theme_stylebox_override("normal", UiKit.box(pill_bg, 26, Color.TRANSPARENT, 0, 10))
	pill.set_anchors_preset(
		Control.PRESET_TOP_RIGHT if not m.enabled else Control.PRESET_BOTTOM_RIGHT
	)
	pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pill.position = Vector2(-22, 20) if not m.enabled else Vector2(-22, -84)
	card.add_child(pill)
	card.pressed.connect(func() -> void: _open(m.id))
	return card


func _open(id: String) -> void:
	var m := GameRegistry.get_manifest(id)
	if m == null:
		return
	if not m.enabled:
		_show_toast("%s is coming in a free update" % m.display_name)
		return
	SceneRouter.open_game(id)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.add_theme_stylebox_override(
		"normal", UiKit.box(UiKit.PANEL, 28, Color.TRANSPARENT, 0, 22)
	)
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.3)


func _settings_panel() -> Control:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(820, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override(
		"panel", UiKit.box(Color(0.1, 0.11, 0.22), 36, Color.TRANSPARENT, 0, 48)
	)
	shade.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 28)
	panel.add_child(col)
	col.add_child(UiKit.label("Settings", 56, Color.WHITE, 900))
	for item in [["sound", "Sound effects"], ["haptics", "Vibration"]]:
		var t := CheckButton.new()
		t.text = item[1]
		t.focus_mode = Control.FOCUS_NONE
		t.button_pressed = bool(SettingsService.get_value(item[0]))
		t.add_theme_font_override("font", UiKit.font(700))
		t.add_theme_font_size_override("font_size", 42)
		var key: String = item[0]
		t.toggled.connect(func(on: bool) -> void: SettingsService.set_value(key, on))
		col.add_child(t)
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	col.add_child(
		UiKit.label(
			"Pocket Arena 8 · v%s · no account, no tracking" % version, 26, UiKit.MUTED, 500
		)
	)
	var close := UiKit.button("Close", UiKit.GREEN)
	close.pressed.connect(func() -> void: shade.visible = false)
	col.add_child(close)
	return shade
