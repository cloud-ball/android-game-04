class_name GameShell
extends CanvasLayer
## Reusable overlay screens for any mini-game: start (mode + difficulty), how-to, countdown,
## banners, pause (with Settings) and results. Holds no game state: the game sets it up with
## configure(), pushes values in and listens to the signals. Extend it to add a game's own HUD.

signal play_requested(difficulty: String, mode: String)
signal rematch_requested
signal exit_requested
signal pause_requested
signal resume_requested
signal howto_closed
signal mode_changed(mode: String)

const DIFFICULTIES := ["easy", "medium", "hard"]

var difficulty := "medium"
var mode := ""
## Set by configure(): title, accent, modes {id: label}, blurbs {id: text},
## howto [[icon_draw: Callable(Control), title, subtitle], ...]
var title := ""
var accent := Color.WHITE
var modes: Dictionary = {}
var blurbs: Dictionary = {}
var howto_steps: Array = []

var _banner: Label
var _banner_sub: Label
var _hint: Label
var _count: Label
var _start: Control
var _pause: Control
var _end: Control
var _howto: Control
var _blurb: Label
var _start_stats: Label
var _diff_buttons: Dictionary = {}
var _mode_buttons: Dictionary = {}
var _end_title: Label
var _end_cause: Label
var _end_stats: Label
var _end_coins: Label
var _end_daily: Label
var _settings: SettingsSheet


func configure(cfg: Dictionary) -> void:
	title = cfg.get("title", "")
	accent = cfg.get("accent", Color.WHITE)
	modes = cfg.get("modes", {})
	blurbs = cfg.get("blurbs", {})
	howto_steps = cfg.get("howto", [])


## Call from the subclass's _ready() after configure() and after adding its own HUD nodes.
func build_shell() -> void:
	layer = 10
	_banner = _centered_label("", 92, Color.WHITE, 620)
	_banner.add_theme_constant_override("outline_size", 18)
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	_banner_sub = _centered_label("", 40, Color.WHITE, 740)
	_banner_sub.add_theme_constant_override("outline_size", 10)
	_banner_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	_banner.modulate.a = 0.0
	_banner_sub.modulate.a = 0.0
	_hint = _centered_label("", 40, UiKit.MUTED, 1560)
	_hint.modulate.a = 0.0
	_count = _centered_label("", 220, Color.WHITE, 760)
	_start = _build_start()
	_pause = _build_pause()
	_end = _build_end()
	_howto = _build_howto()
	_settings = SettingsSheet.new()
	add_child(_settings)


## Centres banners and the countdown on a play area (e.g. the board) instead of fixed heights.
func set_focus(area: Rect2) -> void:
	var cy := area.get_center().y
	_banner.position.y = cy - 190.0
	_banner_sub.position.y = cy - 60.0
	_count.position.y = cy - 160.0
	_hint.position.y = area.end.y - 150.0


## Puts the start-of-match hint in a free screen area instead of over the play field.
func set_hint_area(area: Rect2) -> void:
	_hint.position = area.position
	_hint.size = area.size
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 36)


func _centered_label(text: String, size: int, color: Color, y: float) -> Label:
	var l := UiKit.label(text, size, color, 900)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(1080, size * 1.4)
	l.pivot_offset = l.size * 0.5
	add_child(l)
	return l


func _overlay() -> Array:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	add_child(shade)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", UiKit.box(Color(0.07, 0.08, 0.17, 0.96), 40, accent.darkened(0.2), 3, 52)
	)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(900, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	shade.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 26)
	panel.add_child(col)
	return [shade, col]


func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _segmented(options: Array, names: Dictionary, on_pick: Callable, store: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for key in options:
		var label := str(names.get(key, String(key).capitalize()))
		var b := UiKit.button(label, Color(1, 1, 1, 0.1), Color.WHITE, 38, 100)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: on_pick.call(key))
		store[key] = b
		row.add_child(b)
	return row


func _build_start() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	col.add_child(_center(UiKit.label(title.to_upper(), 76, accent, 900)))
	_blurb = UiKit.label("", 36, UiKit.MUTED, 500)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_blurb)
	if modes.size() > 1:
		col.add_child(_segmented(modes.keys(), modes, set_mode, _mode_buttons))
	col.add_child(_segmented(DIFFICULTIES, {}, set_difficulty, _diff_buttons))
	_start_stats = UiKit.label("", 36, UiKit.MUTED, 600)
	_start_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_start_stats)
	var play := UiKit.button("PLAY", UiKit.GREEN, Color.WHITE, 60, 140)
	play.pressed.connect(func() -> void: play_requested.emit(difficulty, mode))
	col.add_child(play)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var help := UiKit.button("How to play", Color(1, 1, 1, 0.08), UiKit.MUTED, 34, 90)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help.pressed.connect(show_howto)
	row.add_child(help)
	var back := UiKit.button("Back to hub", Color(1, 1, 1, 0.08), UiKit.MUTED, 34, 90)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func() -> void: exit_requested.emit())
	row.add_child(back)
	col.add_child(row)
	return parts[0]


func _build_pause() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	col.add_child(_center(UiKit.label("PAUSED", 76, Color.WHITE, 900)))
	var buttons := [
		["Resume", UiKit.GREEN, 48, 130, func() -> void: resume_requested.emit()],
		["Restart", Color(1, 1, 1, 0.12), 40, 110, func() -> void: rematch_requested.emit()],
		["Settings", Color(1, 1, 1, 0.12), 40, 110, func() -> void: _settings.open()],
		["Back to hub", Color(1, 1, 1, 0.08), 34, 90, func() -> void: exit_requested.emit()],
	]
	for b in buttons:
		var fg := UiKit.MUTED if b[0] == "Back to hub" else Color.WHITE
		var btn := UiKit.button(b[0], b[1], fg, b[2], b[3])
		btn.pressed.connect(b[4])
		col.add_child(btn)
	return parts[0]


func _build_end() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	_end_title = _center(UiKit.label("", 96, Color.WHITE, 900))
	col.add_child(_end_title)
	_end_cause = _center(UiKit.label("", 36, UiKit.MUTED, 600))
	col.add_child(_end_cause)
	_end_stats = _center(UiKit.label("", 40, Color.WHITE, 700))
	_end_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_end_stats)
	var coins := HBoxContainer.new()
	coins.alignment = BoxContainer.ALIGNMENT_CENTER
	coins.add_theme_constant_override("separation", 14)
	coins.add_child(UiKit.coin(48))
	_end_coins = UiKit.label("", 52, UiKit.GOLD, 900)
	coins.add_child(_end_coins)
	col.add_child(coins)
	_end_daily = _center(UiKit.label("", 36, Color(1.0, 0.7, 0.45), 800))
	col.add_child(_end_daily)
	var again := UiKit.button("PLAY AGAIN", UiKit.GREEN, Color.WHITE, 54, 136)
	again.pressed.connect(func() -> void: rematch_requested.emit())
	col.add_child(again)
	var hub := UiKit.button("Back to hub", Color(1, 1, 1, 0.08), UiKit.MUTED, 34, 90)
	hub.pressed.connect(func() -> void: exit_requested.emit())
	col.add_child(hub)
	return parts[0]


func _build_howto() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	col.add_child(_center(UiKit.label("HOW TO PLAY", 64, accent, 900)))
	for step in howto_steps:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 30)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(150, 150)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var draw_fn: Callable = step[0]
		icon.draw.connect(func() -> void: draw_fn.call(icon))
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.add_child(UiKit.label(step[1], 40, Color.WHITE, 800))
		var sub := UiKit.label(step[2], 32, UiKit.MUTED, 500)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(sub)
		row.add_child(text)
		col.add_child(row)
	var ok := UiKit.button("GOT IT", UiKit.GREEN, Color.WHITE, 52, 130)
	ok.pressed.connect(
		func() -> void:
			_howto.visible = false
			howto_closed.emit()
	)
	col.add_child(ok)
	return parts[0]


func _highlight(buttons: Dictionary, selected: String) -> void:
	for key in buttons:
		var b: Button = buttons[key]
		var bg := Color(0.3, 0.45, 1.0) if key == selected else Color(1, 1, 1, 0.1)
		b.add_theme_stylebox_override("normal", UiKit.box(bg, 40, Color.TRANSPARENT, 0, 24))
		b.add_theme_stylebox_override(
			"hover", UiKit.box(bg.lightened(0.08), 40, Color.TRANSPARENT, 0, 24)
		)


func set_difficulty(d: String) -> void:
	difficulty = d
	_highlight(_diff_buttons, d)
	_on_labels_changed()


func set_mode(m: String) -> void:
	mode = m
	_highlight(_mode_buttons, m)
	_blurb.text = str(blurbs.get(m, ""))
	_on_labels_changed()
	mode_changed.emit(m)


## Subclasses update their own labels (e.g. "vs CPU · Medium") here.
func _on_labels_changed() -> void:
	pass


func mode_label() -> String:
	return "%s · %s" % [modes.get(mode, ""), difficulty.capitalize()]


func show_start(stats_text: String) -> void:
	_start_stats.text = stats_text
	_start.visible = true


func set_start_stats(stats_text: String) -> void:
	_start_stats.text = stats_text


func show_howto() -> void:
	_howto.visible = true


func hide_panels() -> void:
	_start.visible = false
	_pause.visible = false
	_end.visible = false
	_howto.visible = false


func show_pause(on: bool) -> void:
	_pause.visible = on


func settings_open() -> bool:
	return _settings.is_open()


func close_settings() -> void:
	_settings.close()


func show_countdown(text: String) -> void:
	_count.text = text
	_count.scale = Vector2(1.4, 1.4)
	_count.modulate.a = 1.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_count, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_count, "modulate:a", 0.0, 0.3).set_delay(0.5)


func show_hint(text: String) -> void:
	_hint.text = text
	var tw := create_tween()
	tw.tween_property(_hint, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.6)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.6)


func banner(text: String, sub: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_sub.text = sub
	_banner.scale = Vector2(0.6, 0.6)
	_banner.modulate.a = 1.0
	_banner_sub.modulate.a = 1.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4).set_delay(1.4)
	tw.tween_property(_banner_sub, "modulate:a", 0.0, 0.4).set_delay(1.4)


## info: {title, color, cause, stats, coins, daily}
func show_end(info: Dictionary) -> void:
	_end_title.text = info.title
	_end_title.add_theme_color_override("font_color", info.color)
	_end_cause.text = info.cause
	_end_stats.text = info.stats
	_end_coins.text = "+%d" % info.coins
	_end_daily.text = info.daily
	_end_daily.visible = info.daily != ""
	_end.visible = true
