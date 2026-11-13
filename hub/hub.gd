extends Control
## Launcher: header with coins, today's challenge, a card per registered game.
## Launch -> tap a card -> tap PLAY = two taps to gameplay.

var _coins_label: Label
var _toast: Label
var _last_back_ms := -100000
var _settings: SettingsSheet


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	AudioService.play_music("hub")
	Economy.coins_changed.connect(
		func(total: int) -> void: _coins_label.text = UiKit.format_int(total)
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _settings != null and _settings.is_open():
			_settings.close()
		elif Time.get_ticks_msec() - _last_back_ms < 2000:
			get_tree().quit()
		else:
			_last_back_ms = Time.get_ticks_msec()
			_show_toast("Press back again to exit")


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
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.offset_bottom = -180
	_toast.modulate.a = 0.0
	add_child(_toast)
	_settings = SettingsSheet.new()
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
	title.add_theme_font_size_override("bold_font_size", 58)
	title.text = "[b]POCKET ARENA [color=#ffc94a]8[/color][/b]"
	left.add_child(title)
	left.add_child(UiKit.label("Play the CPU · offline", 30, UiKit.MUTED, 500))
	row.add_child(left)
	row.add_theme_constant_override("separation", 20)
	var pill := PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override(
		"panel", UiKit.box(Color(1.0, 0.79, 0.29, 0.13), 44, Color(1.0, 0.79, 0.29, 0.35), 2, 18)
	)
	var coins := HBoxContainer.new()
	coins.add_theme_constant_override("separation", 12)
	coins.add_child(UiKit.coin(48))
	_coins_label = UiKit.label(UiKit.format_int(Economy.coins()), 44, UiKit.GOLD, 800)
	coins.add_child(_coins_label)
	pill.add_child(coins)
	row.add_child(pill)
	row.add_child(_gear_button())
	return panel


func _gear_button() -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(116, 116)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_stylebox_override("normal", UiKit.box(Color(1, 1, 1, 0.1), 58))
	b.add_theme_stylebox_override("hover", UiKit.box(Color(1, 1, 1, 0.14), 58))
	b.add_theme_stylebox_override("pressed", UiKit.box(Color(1, 1, 1, 0.2), 58))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var icon := IconGlyph.new("gear", Color(0.85, 0.88, 1.0), 70)
	icon.hole = Color(0.14, 0.15, 0.21)
	UiKit.center(icon, 70)
	b.add_child(icon)
	b.pressed.connect(
		func() -> void:
			AudioService.play("tap")
			_settings.open()
	)
	return b


func _daily_card() -> Control:
	var day := DailyChallenge.today()
	var ch := DailyChallenge.for_day(day, DailyChallenge.enabled_games())
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
	# Pin the pill's right edge 22 px inside the card; it grows leftwards to fit its text.
	pill.anchor_left = 1.0
	pill.anchor_right = 1.0
	pill.offset_left = -22.0
	pill.offset_right = -22.0
	pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var at_bottom := m.enabled
	pill.anchor_top = 1.0 if at_bottom else 0.0
	pill.anchor_bottom = pill.anchor_top
	pill.offset_top = -30.0 if at_bottom else 20.0
	pill.offset_bottom = pill.offset_top
	pill.grow_vertical = Control.GROW_DIRECTION_BEGIN if at_bottom else Control.GROW_DIRECTION_END
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
	# Re-centre on the new text (a shorter message must not keep the old, wider box).
	var m := _toast.get_combined_minimum_size()
	_toast.offset_left = -m.x * 0.5
	_toast.offset_right = m.x * 0.5
	_toast.offset_top = _toast.offset_bottom - m.y
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.3)
