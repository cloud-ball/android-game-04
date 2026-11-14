class_name PoolControls
extends RefCounted
## Break & Bank touch controls (docs/research/Cue Club pool game design.md, portrait touch controls).
##   PowerBar: pull down to load (v = v_max p^2), release to shoot; back under 2% cancels.
##   FineStrip: vertical drag nudges the aim by 0.03 deg per dp (wide touch area at the edge).
##   SpinPad: a cue-ball button; tap opens a large panel where the dot moves by relative drag at
##   half gain inside the 0.5 R limit ring, plus presets. Spin resets after each shot.

const TEAL := Color(0.3, 0.85, 0.8)


class PowerBar:
	extends Control
	signal fired(power: float)
	signal changed(power: float)
	var power := 0.0
	var breaking := false
	var units_per_dp := 2.57
	var _down := false
	var _start_y := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_down = true
				_start_y = mb.position.y
				power = 0.0
			elif _down:
				_down = false
				if power >= PoolAim.MIN_POWER:
					fired.emit(power)
				power = 0.0
				changed.emit(power)
			queue_redraw()
			accept_event()
		var mm := event as InputEventMouseMotion
		if mm != null and _down:
			var track := size.y - 60.0
			power = clampf((mm.position.y - _start_y) / track, 0.0, 1.0)
			changed.emit(power)
			queue_redraw()
			accept_event()

	func _draw() -> void:
		var w := 26.0
		var x := size.x - w - 52.0
		var top := 30.0
		var h := size.y - 60.0
		draw_style_box(
			UiKit.box(Color(0, 0, 0, 0.45), 13, Color(1, 1, 1, 0.25), 2), Rect2(x, top, w, h)
		)
		var fill := h * power
		if fill > 0.0:
			var col := TEAL.lerp(Color(1.0, 0.45, 0.25), power)
			draw_style_box(UiKit.box(col, 11), Rect2(x + 3, top + 3, w - 6, maxf(fill - 6.0, 4.0)))
		for t in [0.25, 0.5, 0.75]:
			draw_line(
				Vector2(x - 8, top + h * t), Vector2(x, top + h * t), Color(1, 1, 1, 0.4), 2.0
			)
		var font := UiKit.font(800)
		var label := "POWER" if power <= 0.0 else "%.1f m/s" % PoolAim.speed_for(power, breaking)
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(
			font,
			Vector2(x + w * 0.5 - tw * 0.5, top + h + 44),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			28,
			Color(1, 1, 1, 0.85)
		)


class FineStrip:
	extends Control
	signal nudged(dp: float)
	var units_per_dp := 2.57
	var _down := false
	var _last_y := 0.0
	var _offset := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			_down = mb.pressed
			_last_y = mb.position.y
			accept_event()
		var mm := event as InputEventMouseMotion
		if mm != null and _down:
			var dy := mm.position.y - _last_y
			_last_y = mm.position.y
			_offset = fposmod(_offset + dy, 24.0)
			nudged.emit(-dy / units_per_dp)
			queue_redraw()
			accept_event()

	func _draw() -> void:
		var w := 30.0
		var x := 18.0
		var top := 30.0
		var h := size.y - 60.0
		draw_style_box(
			UiKit.box(Color(0, 0, 0, 0.45), 15, Color(1, 1, 1, 0.25), 2), Rect2(x, top, w, h)
		)
		var y := top + _offset
		while y < top + h:
			draw_line(Vector2(x + 7, y), Vector2(x + w - 7, y), Color(1, 1, 1, 0.35), 2.0)
			y += 24.0
		var font := UiKit.font(800)
		draw_string(
			font,
			Vector2(x - 4, top + h + 44),
			"FINE",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			28,
			Color(1, 1, 1, 0.85)
		)


## Small cue-ball button showing the current tip offset; opens the panel.
class SpinButton:
	extends Button
	var side := 0.0
	var top := 0.0

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 6.0
		draw_circle(c, r + 4.0, Color(0, 0, 0, 0.45))
		draw_circle(c, r, Color(0.95, 0.94, 0.9))
		draw_arc(c, r * 0.5, 0.0, TAU, 32, Color(0, 0, 0, 0.2), 2.0, true)
		draw_circle(c + Vector2(side, -top) * r, r * 0.16, Color(0.85, 0.12, 0.1))
		var font := UiKit.font(800)
		var tw := font.get_string_size("SPIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(
			font,
			Vector2(c.x - tw * 0.5, size.y + 30),
			"SPIN",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			26,
			Color(1, 1, 1, 0.85)
		)


## Full spin panel: big cue ball, relative drag at 0.5 gain, 0.5 R ring, presets, Done.
class SpinPanel:
	extends Control
	signal chosen(side: float, top: float)
	const PRESETS := [
		["Centre", 0.0, 0.0],
		["Follow", 0.0, 0.4],
		["Draw", 0.0, -0.45],
		["Left", -0.4, 0.0],
		["Right", 0.4, 0.0]
	]
	var side := 0.0
	var top := 0.0
	var _ball: Control
	var _drag := false
	var _last := Vector2.ZERO

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		visible = false
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.55)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(shade)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override(
			"panel", UiKit.box(Color(0.07, 0.08, 0.15, 0.97), 40, TEAL.darkened(0.2), 3, 36)
		)
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		add_child(panel)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 22)
		panel.add_child(col)
		var title := UiKit.label("CUE BALL SPIN", 44, TEAL, 900)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(title)
		_ball = Control.new()
		_ball.custom_minimum_size = Vector2(560, 560)
		_ball.draw.connect(_draw_ball)
		_ball.gui_input.connect(_ball_input)
		col.add_child(_ball)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		for p in PRESETS:
			var b := UiKit.button(p[0], Color(1, 1, 1, 0.12), Color.WHITE, 30, 112)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void: _set_spin(p[1], p[2]))
			row.add_child(b)
		col.add_child(row)
		var done := UiKit.button("Done", UiKit.GREEN, Color.WHITE, 46, 128)
		done.pressed.connect(close)
		col.add_child(done)

	func open(s: float, t: float) -> void:
		side = s
		top = t
		visible = true
		_ball.queue_redraw()

	func close() -> void:
		visible = false
		chosen.emit(side, top)

	func _set_spin(s: float, t: float) -> void:
		side = s
		top = t
		_ball.queue_redraw()

	func _ball_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			_drag = mb.pressed
			_last = mb.position
		var mm := event as InputEventMouseMotion
		if mm != null and _drag:
			var r := _ball.size.x * 0.5 - 20.0
			var d := (mm.position - _last) * 0.5 / r  # relative drag, half gain
			_last = mm.position
			var v := Vector2(side + d.x, top - d.y)
			if v.length() > 0.5:
				v = v.normalized() * 0.5
			_set_spin(v.x, v.y)

	func _draw_ball() -> void:
		var c := _ball.size * 0.5
		var r := _ball.size.x * 0.5 - 20.0
		_ball.draw_circle(c, r, Color(0.95, 0.94, 0.9))
		_ball.draw_arc(c, r * 0.5, 0.0, TAU, 64, Color(0, 0, 0, 0.25), 3.0, true)
		_ball.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(0, 0, 0, 0.08), 2.0)
		_ball.draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(0, 0, 0, 0.08), 2.0)
		_ball.draw_circle(c + Vector2(side, -top) * r, 34.0, Color(0.85, 0.12, 0.1))
		var font := UiKit.font(700)
		var hint := "Drag the dot · follow up, draw down, side left/right"
		var tw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		_ball.draw_string(
			font,
			Vector2(c.x - tw * 0.5, _ball.size.y - 2),
			hint,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color(1, 1, 1, 0.6)
		)
