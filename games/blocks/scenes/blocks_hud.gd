class_name BlocksHud
extends GameShell
## Stack Drop HUD on top of the shared GameShell overlays: score bar, NEXT (3 shards),
## HOLD (tappable), and the CPU's tower as a live mini view. Holds no game state.

signal hold_requested

const ACCENT := Color(0.86, 0.72, 1.0)

var _score: Label
var _sub: Label
var _mode_label: Label
var _next_draw: Control
var _hold_draw: Control
var _cpu_panel: Control
var _cpu_draw: Control
var _cpu_info: Label
var _pause_btn: Button
var _player: StackState
var _cpu: StackState


func _ready() -> void:
	configure(
		{
			"title": "Stack Drop",
			"accent": ACCENT,
			"modes": {"vs": "vs CPU", "solo": "Solo"},
			"blurbs":
			{
				"vs": "Clear rows to send garbage to the CPU. Make its tower overflow first.",
				"solo": "Clear rows, level up and chase your best score.",
			},
			"howto":
			[
				[_icon_tap, "Tap to rotate.", "Shards turn and slide off walls when they can."],
				[
					_icon_drag,
					"Drag to move.",
					"Slide your finger left or right, one column per step."
				],
				[_icon_drop, "Swipe down to drop.", "A quick flick drops the shard straight down."],
				[
					_icon_hold,
					"Two-finger tap to hold.",
					"Or tap the HOLD box. Swap once per shard."
				],
			],
		}
	)
	var top := UiKit.safe_top(self)
	_build_bar(top)
	_build_side_panels(top)
	build_shell()


func _build_bar(top: float) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 28, Color.TRANSPARENT, 0, 24))
	panel.position = Vector2(16, 20 + top)
	panel.size = Vector2(924, 0)
	add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 2
	panel.add_child(grid)
	var t := UiKit.label("STACK DROP", 38, ACCENT, 900)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(t)
	_mode_label = UiKit.label("", 30, UiKit.MUTED, 600)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_mode_label)
	_score = UiKit.label("0", 46, UiKit.GOLD, 900)
	grid.add_child(_score)
	_sub = UiKit.label("", 32, Color(0.9, 0.9, 1.0), 700)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_sub)
	_pause_btn = UiKit.button("II", Color(1, 1, 1, 0.12), Color.WHITE, 36, 96)
	_pause_btn.custom_minimum_size = Vector2(96, 96)
	_pause_btn.custom_minimum_size = Vector2(112, 112)
	_pause_btn.position = Vector2(952, 34 + top)
	_pause_btn.pressed.connect(func() -> void: pause_requested.emit())
	add_child(_pause_btn)


func _build_side_panels(top: float) -> void:
	# Slim, see-through panels float over the tower's outer columns near the top.
	var y0 := 196.0 + top
	var next := _panel(Vector2(14, y0), Vector2(132, 320), "NEXT")
	_next_draw = _drawer(next, _draw_next)
	var hold := Button.new()
	hold.focus_mode = Control.FOCUS_NONE
	hold.position = Vector2(14, y0 + 334)
	hold.size = Vector2(132, 140)
	for st in ["normal", "hover", "pressed"]:
		var bg := Color(UiKit.PANEL, 0.62).lightened(0.08 if st == "pressed" else 0.0)
		hold.add_theme_stylebox_override(st, UiKit.box(bg, 24, Color(1, 1, 1, 0.12), 2, 0))
	hold.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	hold.pressed.connect(func() -> void: hold_requested.emit())
	add_child(hold)
	_title(hold, "HOLD")
	_hold_draw = _drawer(hold, _draw_hold)
	_cpu_panel = _panel(Vector2(934, y0), Vector2(132, 360), "CPU")
	_cpu_draw = _drawer(_cpu_panel, _draw_cpu)
	_cpu_info = UiKit.label("", 26, UiKit.MUTED, 700)
	_cpu_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cpu_info.position = Vector2(0, 318)
	_cpu_info.size = Vector2(132, 36)
	_cpu_panel.add_child(_cpu_info)


func _panel(pos: Vector2, size: Vector2, caption: String) -> Control:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override(
		"panel", UiKit.box(Color(UiKit.PANEL, 0.62), 22, Color(1, 1, 1, 0.12), 2, 0)
	)
	add_child(p)
	_title(p, caption)
	return p


func _title(parent: Control, caption: String) -> void:
	var l := UiKit.label(caption, 24, ACCENT, 900)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, 8)
	l.size = Vector2(parent.size.x, 32)
	parent.add_child(l)


func _drawer(parent: Control, fn: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(0, 40)
	c.size = parent.size - Vector2(0, 40)
	c.draw.connect(func() -> void: fn.call(c))
	parent.add_child(c)
	return c


func _on_labels_changed() -> void:
	if _mode_label != null:
		_mode_label.text = mode_label()
	if _cpu_panel != null:
		_cpu_panel.visible = mode == "vs"


func show_start(stats_text: String) -> void:
	super.show_start(stats_text)
	_pause_btn.visible = false


func show_howto() -> void:
	super.show_howto()
	_pause_btn.visible = false


func hide_panels() -> void:
	super.hide_panels()
	_pause_btn.visible = true


func show_end(info: Dictionary) -> void:
	super.show_end(info)
	_pause_btn.visible = false


## Push the latest states in; the panels redraw themselves.
func update_states(player: StackState, cpu: StackState) -> void:
	_player = player
	_cpu = cpu
	_score.text = UiKit.format_int(player.score)
	_sub.text = "Lines %d  ·  Lv %d" % [player.lines, player.level]
	if cpu != null:
		_cpu_info.text = "%d lines" % cpu.lines
	_next_draw.queue_redraw()
	_hold_draw.queue_redraw()
	_cpu_draw.queue_redraw()


func _draw_next(c: Control) -> void:
	if _player == null:
		return
	for i in mini(3, _player.queue.size()):
		var slot := (c.size.y - 12) / 3.0
		var box := Rect2(Vector2(12, 4 + i * slot), Vector2(c.size.x - 24, slot - 10))
		draw_shard(c, int(_player.queue[i]), box, 1.0 if i == 0 else 0.8)


func _draw_hold(c: Control) -> void:
	if _player == null or _player.hold < 0:
		return
	var alpha := 1.0 if _player.can_hold else 0.35
	draw_shard(c, _player.hold, Rect2(Vector2(14, 6), Vector2(c.size.x - 28, c.size.y - 20)), alpha)


func _draw_cpu(c: Control) -> void:
	if _cpu == null:
		return
	var rows := StackState.H - StackState.HIDDEN
	var cell := minf((c.size.x - 24) / StackState.W, (c.size.y - 64) / rows)
	var origin := Vector2((c.size.x - cell * StackState.W) * 0.5, 6)
	c.draw_rect(Rect2(origin, Vector2(cell * StackState.W, cell * rows)), Color(1, 1, 1, 0.06))
	for y in range(StackState.HIDDEN, StackState.H):
		for x in StackState.W:
			var v := _cpu.board[y * StackState.W + x]
			if v == 0:
				continue
			var col := (
				BlocksView.GARBAGE_COLOR
				if v == StackState.GARBAGE
				else BlocksView.GEM_COLORS[v - 1]
			)
			var r := Rect2(
				origin + Vector2(x, y - StackState.HIDDEN) * cell, Vector2(cell - 1, cell - 1)
			)
			c.draw_rect(r, col)
	if _cpu.pending_garbage > 0:
		var h := minf(rows, _cpu.pending_garbage) * cell
		c.draw_rect(
			Rect2(origin + Vector2(-8, rows * cell - h), Vector2(5, h)), Color(1, 0.3, 0.35)
		)


## Draws one shard (spawn orientation) centred in `box`.
static func draw_shard(c: Control, kind: int, box: Rect2, alpha: float) -> void:
	var cells := ShardData.cells(kind, 0)
	var min_c := Vector2i(9, 9)
	var max_c := Vector2i(-9, -9)
	for p in cells:
		min_c = Vector2i(mini(min_c.x, p.x), mini(min_c.y, p.y))
		max_c = Vector2i(maxi(max_c.x, p.x), maxi(max_c.y, p.y))
	var span := Vector2(max_c - min_c + Vector2i.ONE)
	var cell := minf(box.size.x / 4.2, box.size.y / 2.6)
	var origin := box.position + (box.size - span * cell) * 0.5
	var col: Color = BlocksView.GEM_COLORS[kind]
	col.a = alpha
	for p in cells:
		var r := Rect2(origin + Vector2(p - min_c) * cell, Vector2(cell - 3, cell - 3))
		c.draw_rect(r, col)
		c.draw_rect(
			Rect2(r.position, Vector2(r.size.x, r.size.y * 0.3)), Color(1, 1, 1, 0.22 * alpha)
		)


# --- how-to illustrations ------------------------------------------------------------------


func _icon_tap(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.4, 0.3, 0.8, 0.25))
	draw_shard(c, 2, Rect2(Vector2(25, 30), Vector2(100, 60)), 1.0)
	c.draw_arc(Vector2(75, 75), 52, -0.6, 2.2, 24, Color.WHITE, 5.0)
	c.draw_circle(Vector2(75, 118), 12, Color(1, 1, 1, 0.85))


func _icon_drag(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.4, 0.3, 0.8, 0.25))
	draw_shard(c, 5, Rect2(Vector2(25, 26), Vector2(100, 60)), 1.0)
	c.draw_line(Vector2(30, 112), Vector2(120, 112), Color.WHITE, 5.0)
	c.draw_colored_polygon(
		PackedVector2Array([Vector2(130, 112), Vector2(114, 102), Vector2(114, 122)]), Color.WHITE
	)
	c.draw_colored_polygon(
		PackedVector2Array([Vector2(20, 112), Vector2(36, 102), Vector2(36, 122)]), Color.WHITE
	)


func _icon_drop(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.4, 0.3, 0.8, 0.25))
	draw_shard(c, 0, Rect2(Vector2(25, 10), Vector2(100, 40)), 1.0)
	c.draw_line(Vector2(75, 52), Vector2(75, 112), Color.WHITE, 5.0)
	c.draw_colored_polygon(
		PackedVector2Array([Vector2(75, 126), Vector2(63, 108), Vector2(87, 108)]), Color.WHITE
	)
	c.draw_rect(Rect2(Vector2(15, 130), Vector2(120, 12)), Color(0.6, 0.55, 0.9))


func _icon_hold(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.4, 0.3, 0.8, 0.25))
	c.draw_circle(Vector2(50, 92), 16, Color(1, 1, 1, 0.85))
	c.draw_circle(Vector2(100, 92), 16, Color(1, 1, 1, 0.85))
	draw_shard(c, 1, Rect2(Vector2(45, 18), Vector2(60, 46)), 1.0)
