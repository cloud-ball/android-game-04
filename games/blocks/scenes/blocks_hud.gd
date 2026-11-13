class_name BlocksHud
extends GameShell
## Stack Drop HUD on top of the shared GameShell overlays. Every rectangle comes from BoardLayout:
## a top band (CPU mini-board, status plate, pause; then a tappable HOLD box beside the NEXT strip).
## Nothing covers the well. Holds no game state.

signal hold_requested

const ACCENT := Color(0.86, 0.72, 1.0)
const PLATE := Color(0.03, 0.035, 0.08, 0.82)  # >= 79% dark plate keeps text at 4.5:1
const CAPTION := 36
const VALUE := 52
const SCORE := 72

## Set by the game before the HUD enters the tree (and again on resize via apply_layout()).
var layout: BoardLayout

var _status: Panel
var _score: Label
var _sub: Label
var _mode_label: Label
var _next_panel: Panel
var _next_draw: Control
var _next_caption: Label
var _hold_btn: Button
var _hold_draw: Control
var _cpu_panel: Panel
var _cpu_draw: Control
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
			(
				BlocksHowto
				. cards(
					{
						"tap": _icon_tap,
						"drag": _icon_drag,
						"drop": _icon_drop,
						"hold": _icon_hold,
						"garbage": BlocksHowto.poster_garbage,
					}
				)
			),
		}
	)
	_build_status()
	_build_next()
	_build_hold()
	_build_cpu()
	_build_pause_button()
	build_shell()
	apply_layout(layout)


func _plate(radius := 26) -> StyleBoxFlat:
	return UiKit.box(PLATE, radius, Color(1, 1, 1, 0.1), 2, 0)


func _build_status() -> void:
	_status = Panel.new()
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.add_theme_stylebox_override("panel", _plate())
	add_child(_status)
	var caption := UiKit.label("SCORE", 34, UiKit.MUTED, 700)
	caption.position = Vector2(24, 2)
	_status.add_child(caption)
	_score = UiKit.label("0", SCORE, UiKit.GOLD, 900)
	_score.position = Vector2(22, 30)
	_score.add_theme_constant_override("outline_size", 6)
	_score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_status.add_child(_score)
	_mode_label = UiKit.label("", CAPTION, UiKit.MUTED, 600)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status.add_child(_mode_label)
	_sub = UiKit.label("", VALUE, Color(0.94, 0.94, 1.0), 800)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status.add_child(_sub)


func _build_next() -> void:
	_next_panel = Panel.new()
	_next_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next_panel.add_theme_stylebox_override("panel", _plate())
	add_child(_next_panel)
	var caption := UiKit.label("NEXT", CAPTION, ACCENT, 900)
	caption.position = Vector2(22, 0)
	caption.size = Vector2(110, 120)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_next_panel.add_child(caption)
	_next_caption = caption
	_next_draw = _drawer(_next_panel, _draw_next)


func _build_hold() -> void:
	_hold_btn = Button.new()
	_hold_btn.focus_mode = Control.FOCUS_NONE
	_hold_btn.add_theme_stylebox_override("normal", _plate(30))
	_hold_btn.add_theme_stylebox_override("hover", _plate(30))
	_hold_btn.add_theme_stylebox_override(
		"pressed", UiKit.box(Color(0.2, 0.18, 0.35, 0.95), 30, ACCENT, 4, 0)
	)
	_hold_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_hold_btn.pressed.connect(func() -> void: hold_requested.emit())
	add_child(_hold_btn)
	var caption := UiKit.label("HOLD", 30, ACCENT, 900)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(0, 4)
	caption.size = Vector2(BoardLayout.HOLD_W, 36)
	_hold_btn.add_child(caption)
	_hold_draw = _drawer(_hold_btn, _draw_hold)


func _build_cpu() -> void:
	_cpu_panel = Panel.new()
	_cpu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cpu_panel.add_theme_stylebox_override("panel", _plate(20))
	add_child(_cpu_panel)
	var caption := UiKit.label("CPU", 30, ACCENT, 900)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(0, 4)
	caption.size = Vector2(BoardLayout.CPU_W, 38)
	_cpu_panel.add_child(caption)
	_cpu_draw = _drawer(_cpu_panel, _draw_cpu)


func _build_pause_button() -> void:
	_pause_btn = UiKit.pause_button(112.0)
	_pause_btn.pressed.connect(
		func() -> void:
			AudioService.play("tap")
			pause_requested.emit()
	)
	add_child(_pause_btn)


func _drawer(parent: Control, fn: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void: fn.call(c))
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## Places every HUD element from the layout (called on start and on every resize).
func apply_layout(l: BoardLayout) -> void:
	layout = l
	if _status == null or l == null:
		return
	_place(_status, l.status)
	_mode_label.position = Vector2(l.status.size.x - 424, 8)
	_mode_label.size = Vector2(400, 44)
	_sub.position = Vector2(l.status.size.x - 424, 50)
	_sub.size = Vector2(400, 64)
	_place(_next_panel, l.next)
	_place(_hold_btn, l.hold)
	_place(_cpu_panel, l.cpu)
	_place(_pause_btn, l.pause)
	_next_caption.size.y = l.next.size.y
	set_focus(l.well)
	# The start hint sits in the upper-middle of the (still empty) well for its ~3 s.
	set_hint_area(
		Rect2(
			l.well.position.x + 40.0,
			l.well.position.y + l.well.size.y * 0.3,
			l.well.size.x - 80.0,
			120
		)
	)
	_next_draw.queue_redraw()
	_hold_draw.queue_redraw()


static func _place(c: Control, r: Rect2) -> void:
	c.position = r.position
	c.size = r.size


func _on_labels_changed() -> void:
	if _mode_label != null:
		_mode_label.text = mode_label()
	if _cpu_panel != null:
		_cpu_panel.visible = mode == "vs"


func show_start(stats_text: String) -> void:
	super.show_start(stats_text)
	_pause_btn.visible = false


func show_howto(from_pause := false) -> void:
	super(from_pause)
	if not from_pause:  # from the pause menu the match resumes afterwards
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
	_next_draw.queue_redraw()
	_hold_draw.queue_redraw()
	_cpu_draw.queue_redraw()


func _draw_next(c: Control) -> void:
	if _player == null or layout == null:
		return
	# Left to right after the caption: the next shard larger, then two smaller ones. Cell sizes are
	# fitted to the strip so 4-wide shards never spill (2 rows tall at most).
	var avail := c.size.x - 130.0
	var big := minf(c.size.y * 0.4, avail / 12.0)
	var small := big * 0.78
	var mid_y := c.size.y * 0.5
	var x := 130.0 + 2.0 * big
	if _player.queue.size() > 0:
		draw_shard_at(c, int(_player.queue[0]), Vector2(x, mid_y), big, 1.0)
	x += 2.0 * big + 0.6 * big + 2.0 * small
	for i in range(1, mini(3, _player.queue.size())):
		draw_shard_at(c, int(_player.queue[i]), Vector2(x, mid_y), small, 0.85)
		x += 4.6 * small


func _draw_hold(c: Control) -> void:
	if _player == null or _player.hold < 0 or layout == null:
		return
	var alpha := 1.0 if _player.can_hold else 0.62  # locked until the next shard
	var top := 40.0
	var cell := minf((c.size.y - top - 8.0) / 2.0, (c.size.x - 20.0) / 4.0)
	var centre := Vector2(c.size.x * 0.5, top + (c.size.y - top) * 0.5)
	draw_shard_at(c, _player.hold, centre, cell, alpha)


func _draw_cpu(c: Control) -> void:
	if _cpu == null:
		return
	var rows := StackState.H - StackState.HIDDEN
	var cell := minf((c.size.x - 12.0) / StackState.W, (c.size.y - 50.0) / rows)
	var origin := Vector2((c.size.x - cell * StackState.W) * 0.5, 42)
	c.draw_rect(Rect2(origin, Vector2(cell * StackState.W, cell * rows)), Color(1, 1, 1, 0.07))
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
			var pos := origin + Vector2(x, y - StackState.HIDDEN) * cell
			c.draw_rect(Rect2(pos, Vector2(cell - 1, cell - 1)), col)
	if _cpu.pending_garbage > 0:
		var h := minf(rows, _cpu.pending_garbage) * cell
		c.draw_rect(
			Rect2(origin + Vector2(-5, rows * cell - h), Vector2(3, h)), Color(1, 0.3, 0.35)
		)


## Draws one shard (spawn orientation) centred on `centre` with square cells of `cell` units:
## gem face, a lighter top band, and a dark gap that doubles as an outline.
static func draw_shard_at(
	c: Control, kind: int, centre: Vector2, cell: float, alpha: float
) -> void:
	var cells := ShardData.cells(kind, 0)
	var min_c := Vector2i(9, 9)
	var max_c := Vector2i(-9, -9)
	for p in cells:
		min_c = Vector2i(mini(min_c.x, p.x), mini(min_c.y, p.y))
		max_c = Vector2i(maxi(max_c.x, p.x), maxi(max_c.y, p.y))
	var span := Vector2(max_c - min_c + Vector2i.ONE)
	var origin := centre - span * cell * 0.5
	var col: Color = BlocksView.GEM_COLORS[kind]
	col.a = alpha
	var gap := maxf(2.0, cell * 0.07)
	for p in cells:
		var r := Rect2(origin + Vector2(p - min_c) * cell, Vector2(cell - gap, cell - gap))
		c.draw_rect(r, col)
		c.draw_rect(
			Rect2(r.position, Vector2(r.size.x, r.size.y * 0.18)), Color(1, 1, 1, 0.3 * alpha)
		)
		c.draw_rect(
			Rect2(r.position + Vector2(0, r.size.y * 0.82), Vector2(r.size.x, r.size.y * 0.18)),
			Color(0, 0, 0, 0.22 * alpha)
		)


## Draws a shard fitted into `box` (used by the how-to illustrations).
static func draw_shard(c: Control, kind: int, box: Rect2, alpha: float) -> void:
	var cell := minf(box.size.x / 4.2, box.size.y / 2.6)
	draw_shard_at(c, kind, box.get_center(), cell, alpha)


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
	c.draw_rect(Rect2(Vector2(28, 70), Vector2(94, 64)), Color(1, 1, 1, 0.2))
	draw_shard(c, 1, Rect2(Vector2(45, 14), Vector2(60, 46)), 1.0)
	c.draw_circle(Vector2(75, 104), 14, Color(1, 1, 1, 0.85))
