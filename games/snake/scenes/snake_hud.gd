class_name SnakeHud
extends CanvasLayer
## 2D overlay for Serpent Grid: score bar, banners, start / pause / result panels.
## Holds no game state; snake_game.gd pushes values in and listens to the signals.

signal play_requested(difficulty: String)
signal rematch_requested
signal exit_requested
signal pause_requested
signal resume_requested

const DIFFICULTIES := ["easy", "medium", "hard"]

var difficulty := "medium"

var _you: Label
var _cpu: Label
var _mode: Label
var _speed: Label
var _banner: Label
var _banner_sub: Label
var _hint: Label
var _start: Control
var _pause: Control
var _end: Control
var _count: Label
var _diff_buttons: Dictionary = {}
var _start_stats: Label
var _end_title: Label
var _end_cause: Label
var _end_stats: Label
var _end_coins: Label
var _end_daily: Label
var _pause_btn: Button


func _ready() -> void:
	layer = 10
	var top := UiKit.safe_top(self)
	_build_bar(top)
	_build_banner()
	_hint = _centered_label("Swipe anywhere to turn", 40, UiKit.MUTED, 1560)
	_hint.modulate.a = 0.0
	_count = _centered_label("", 220, Color.WHITE, 760)
	_start = _build_start()
	_pause = _build_pause()
	_end = _build_end()


func _build_bar(top: float) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 28, Color.TRANSPARENT, 0, 26))
	panel.position = Vector2(32, 28 + top)
	panel.size = Vector2(1016, 0)
	add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 2
	panel.add_child(grid)
	var title := UiKit.label("SERPENT GRID", 38, UiKit.NEON_GREEN, 900)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(title)
	_mode = UiKit.label("vs CPU", 30, UiKit.MUTED, 600)
	_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_mode)
	_you = UiKit.label("YOU 000 · length 3", 34, Color(0.85, 1.0, 0.9), 800)
	grid.add_child(_you)
	_cpu = UiKit.label("CPU 000 · length 3", 34, UiKit.MAGENTA, 800)
	_cpu.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_cpu)
	_speed = UiKit.label("", 28, UiKit.MUTED, 500)
	_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed.position = Vector2(0, 222 + top)
	_speed.size = Vector2(1080, 40)
	add_child(_speed)
	_pause_btn = UiKit.button("II", Color(1, 1, 1, 0.12), Color.WHITE, 36, 96)
	_pause_btn.custom_minimum_size = Vector2(96, 96)
	_pause_btn.position = Vector2(952, 206 + top)
	_pause_btn.pressed.connect(func() -> void: pause_requested.emit())
	add_child(_pause_btn)


func _build_banner() -> void:
	_banner = _centered_label("", 92, Color.WHITE, 620)
	_banner.add_theme_constant_override("outline_size", 18)
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_banner_sub = _centered_label("", 40, Color.WHITE, 740)
	_banner_sub.add_theme_constant_override("outline_size", 10)
	_banner_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_banner.modulate.a = 0.0
	_banner_sub.modulate.a = 0.0


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
		"panel", UiKit.box(Color(0.07, 0.08, 0.17, 0.96), 40, Color(0.3, 0.45, 1.0, 0.6), 3, 52)
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


func _build_start() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	col.add_child(_center(UiKit.label("SERPENT GRID", 76, UiKit.NEON_GREEN, 900)))
	var blurb := UiKit.label(
		"Eat orbs to grow. Make the CPU snake crash first.", 36, UiKit.MUTED, 500
	)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(blurb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for d in DIFFICULTIES:
		var b := UiKit.button(d.capitalize(), Color(1, 1, 1, 0.1), Color.WHITE, 38, 100)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: set_difficulty(d))
		_diff_buttons[d] = b
		row.add_child(b)
	col.add_child(row)
	_start_stats = UiKit.label("", 32, UiKit.MUTED, 600)
	_start_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_start_stats)
	var play := UiKit.button("PLAY", UiKit.GREEN, Color.WHITE, 60, 140)
	play.pressed.connect(func() -> void: play_requested.emit(difficulty))
	col.add_child(play)
	var back := UiKit.button("Back to hub", Color(1, 1, 1, 0.08), UiKit.MUTED, 34, 90)
	back.pressed.connect(func() -> void: exit_requested.emit())
	col.add_child(back)
	return parts[0]


func _build_pause() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	col.add_child(_center(UiKit.label("PAUSED", 76, Color.WHITE, 900)))
	var resume := UiKit.button("Resume", UiKit.GREEN, Color.WHITE, 48, 130)
	resume.pressed.connect(func() -> void: resume_requested.emit())
	col.add_child(resume)
	var restart := UiKit.button("Restart", Color(1, 1, 1, 0.12), Color.WHITE, 40, 110)
	restart.pressed.connect(func() -> void: rematch_requested.emit())
	col.add_child(restart)
	var quit := UiKit.button("Back to hub", Color(1, 1, 1, 0.08), UiKit.MUTED, 34, 90)
	quit.pressed.connect(func() -> void: exit_requested.emit())
	col.add_child(quit)
	return parts[0]


func _build_end() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	_end_title = _center(UiKit.label("", 96, Color.WHITE, 900))
	col.add_child(_end_title)
	_end_cause = _center(UiKit.label("", 36, UiKit.MUTED, 600))
	col.add_child(_end_cause)
	_end_stats = _center(UiKit.label("", 40, Color.WHITE, 700))
	col.add_child(_end_stats)
	var coins := HBoxContainer.new()
	coins.alignment = BoxContainer.ALIGNMENT_CENTER
	coins.add_theme_constant_override("separation", 14)
	coins.add_child(UiKit.coin(48))
	_end_coins = UiKit.label("", 52, UiKit.GOLD, 900)
	coins.add_child(_end_coins)
	col.add_child(coins)
	_end_daily = _center(UiKit.label("", 32, Color(1.0, 0.7, 0.45), 800))
	col.add_child(_end_daily)
	var again := UiKit.button("REMATCH", UiKit.GREEN, Color.WHITE, 54, 136)
	again.pressed.connect(func() -> void: rematch_requested.emit())
	col.add_child(again)
	var hub := UiKit.button("Back to hub", Color(1, 1, 1, 0.08), UiKit.MUTED, 34, 90)
	hub.pressed.connect(func() -> void: exit_requested.emit())
	col.add_child(hub)
	return parts[0]


func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func set_difficulty(d: String) -> void:
	difficulty = d
	_mode.text = "vs CPU · %s" % d.capitalize()
	for key in _diff_buttons:
		var b: Button = _diff_buttons[key]
		var on: bool = key == d
		var bg := Color(0.3, 0.45, 1.0) if on else Color(1, 1, 1, 0.1)
		b.add_theme_stylebox_override("normal", UiKit.box(bg, 40, Color.TRANSPARENT, 0, 24))
		b.add_theme_stylebox_override(
			"hover", UiKit.box(bg.lightened(0.08), 40, Color.TRANSPARENT, 0, 24)
		)


func show_start(stats_text: String) -> void:
	_start_stats.text = stats_text
	_start.visible = true
	_pause_btn.visible = false


func hide_panels() -> void:
	_start.visible = false
	_pause.visible = false
	_end.visible = false
	_pause_btn.visible = true


func show_pause(on: bool) -> void:
	_pause.visible = on


func show_countdown(text: String) -> void:
	_count.text = text
	_count.scale = Vector2(1.4, 1.4)
	_count.modulate.a = 1.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_count, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_count, "modulate:a", 0.0, 0.3).set_delay(0.5)


func show_hint() -> void:
	var tw := create_tween()
	tw.tween_property(_hint, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.4)
	tw.tween_property(_hint, "modulate:a", 0.0, 0.6)


func set_scores(you_score: int, you_len: int, cpu_score: int, cpu_len: int, hz: float) -> void:
	_you.text = "YOU %03d · length %d" % [you_score, you_len]
	_cpu.text = "CPU %03d · length %d" % [cpu_score, cpu_len]
	_speed.text = "speed %.1f tiles/s" % hz


func banner(text: String, sub: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_sub.text = sub
	_banner.scale = Vector2(0.6, 0.6)
	_banner.modulate.a = 1.0
	_banner_sub.modulate.a = 1.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4).set_delay(1.6)
	tw.tween_property(_banner_sub, "modulate:a", 0.0, 0.4).set_delay(1.6)


## info: {title, color, cause, score, length, best, coins, daily}
func show_end(info: Dictionary) -> void:
	_end_title.text = info.title
	_end_title.add_theme_color_override("font_color", info.color)
	_end_cause.text = info.cause
	_end_stats.text = "Score %d  ·  Length %d  ·  Best %d" % [info.score, info.length, info.best]
	_end_coins.text = "+%d" % info.coins
	_end_daily.text = info.daily
	_end_daily.visible = info.daily != ""
	_end.visible = true
	_pause_btn.visible = false
