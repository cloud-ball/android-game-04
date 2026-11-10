class_name SnakeHud
extends CanvasLayer
## 2D overlay for Serpent Grid: score bar, banners, how-to-play, start / pause / result panels.
## Holds no game state; snake_game.gd pushes values in and listens to the signals.

signal play_requested(difficulty: String, mode: String)
signal rematch_requested
signal exit_requested
signal pause_requested
signal resume_requested
signal howto_closed
signal mode_changed(mode: String)

const DIFFICULTIES := ["easy", "medium", "hard"]
const MODES := ["vs", "solo"]
const MODE_NAMES := {"vs": "vs CPU", "solo": "Solo"}
const BLURBS := {
	"vs": "Eat orbs to grow. Make the CPU snake crash first.",
	"solo": "Eat orbs, grow long, beat your best score.",
}

var difficulty := "medium"
var mode := "vs"

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
var _howto: Control
var _count: Label
var _diff_buttons: Dictionary = {}
var _mode_buttons: Dictionary = {}
var _blurb: Label
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
	_howto = _build_howto()


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


func _segmented(options: Array, names: Dictionary, on_pick: Callable, store: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for key in options:
		var b := UiKit.button(
			str(names.get(key, key.capitalize())), Color(1, 1, 1, 0.1), Color.WHITE, 38, 100
		)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: on_pick.call(key))
		store[key] = b
		row.add_child(b)
	return row


func _build_start() -> Control:
	var parts := _overlay()
	var col: VBoxContainer = parts[1]
	col.add_child(_center(UiKit.label("SERPENT GRID", 76, UiKit.NEON_GREEN, 900)))
	_blurb = UiKit.label(BLURBS["vs"], 36, UiKit.MUTED, 500)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_blurb)
	col.add_child(_segmented(MODES, MODE_NAMES, set_mode, _mode_buttons))
	col.add_child(_segmented(DIFFICULTIES, {}, set_difficulty, _diff_buttons))
	_start_stats = UiKit.label("", 32, UiKit.MUTED, 600)
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
	col.add_child(_center(UiKit.label("HOW TO PLAY", 64, UiKit.NEON_GREEN, 900)))
	var steps := [
		["swipe", "Swipe anywhere to turn.", "Two quick swipes make a tight U-turn."],
		["orb", "Eat glowing orbs to grow.", "Each orb is +10. Longer snakes move faster."],
		["crash", "Make the CPU crash first.", "Cut it off so it hits you, a wall or itself."],
		["wall", "Don't crash yourself.", "Walls, your own tail and the rival all end the run."],
	]
	for step in steps:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 30)
		row.add_child(_howto_icon(step[0]))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.add_child(UiKit.label(step[1], 40, Color.WHITE, 800))
		var sub := UiKit.label(step[2], 30, UiKit.MUTED, 500)
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


## Small drawn illustrations for the how-to screen (original vector art, no images).
func _howto_icon(kind: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(150, 150)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void: _draw_howto(c, kind))
	return c


static func _draw_howto(c: Control, kind: String) -> void:
	var g := UiKit.NEON_GREEN
	var bg := Color(0.2, 0.3, 0.8, 0.25)
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(150, 150)), bg)
	match kind:
		"swipe":
			c.draw_circle(Vector2(45, 95), 22, Color(1, 1, 1, 0.85))
			c.draw_line(Vector2(60, 80), Vector2(120, 40), Color.WHITE, 8.0)
			c.draw_colored_polygon(
				PackedVector2Array([Vector2(130, 32), Vector2(103, 37), Vector2(118, 58)]),
				Color.WHITE
			)
		"orb":
			for i in 3:
				c.draw_rect(Rect2(Vector2(20 + i * 30, 80), Vector2(26, 26)), g * (0.6 + 0.2 * i))
			c.draw_circle(Vector2(118, 93), 14, UiKit.GOLD)
			c.draw_string(
				UiKit.font(900), Vector2(88, 52), "+10", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, g
			)
		"crash":
			for i in 4:
				c.draw_rect(Rect2(Vector2(62, 20 + i * 30), Vector2(26, 26)), g * 0.8)
			for i in 2:
				c.draw_rect(Rect2(Vector2(10 + i * 26, 78), Vector2(24, 24)), UiKit.MAGENTA)
			c.draw_circle(Vector2(56, 90), 12, Color(1, 0.9, 0.4))
		"wall":
			c.draw_rect(Rect2(Vector2(124, 10), Vector2(10, 130)), Color(0.55, 0.7, 1.0))
			for i in 3:
				c.draw_rect(Rect2(Vector2(36 + i * 28, 62), Vector2(26, 26)), g * (0.6 + 0.2 * i))
			c.draw_line(Vector2(20, 20), Vector2(50, 50), Color(1, 0.4, 0.4), 6.0)
			c.draw_line(Vector2(50, 20), Vector2(20, 50), Color(1, 0.4, 0.4), 6.0)


func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _highlight(buttons: Dictionary, selected: String) -> void:
	for key in buttons:
		var b: Button = buttons[key]
		var bg := Color(0.3, 0.45, 1.0) if key == selected else Color(1, 1, 1, 0.1)
		b.add_theme_stylebox_override("normal", UiKit.box(bg, 40, Color.TRANSPARENT, 0, 24))
		b.add_theme_stylebox_override(
			"hover", UiKit.box(bg.lightened(0.08), 40, Color.TRANSPARENT, 0, 24)
		)


func _update_mode_label() -> void:
	_mode.text = "%s · %s" % [MODE_NAMES[mode], difficulty.capitalize()]


func set_difficulty(d: String) -> void:
	difficulty = d
	_highlight(_diff_buttons, d)
	_update_mode_label()


func set_mode(m: String) -> void:
	mode = m
	_highlight(_mode_buttons, m)
	_blurb.text = BLURBS[m]
	_cpu.visible = m == "vs"
	_update_mode_label()
	mode_changed.emit(m)


func show_start(stats_text: String) -> void:
	_start_stats.text = stats_text
	_start.visible = true
	_pause_btn.visible = false


func set_start_stats(stats_text: String) -> void:
	_start_stats.text = stats_text


func show_howto() -> void:
	_howto.visible = true
	_pause_btn.visible = false


func hide_panels() -> void:
	_start.visible = false
	_pause.visible = false
	_end.visible = false
	_howto.visible = false
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
