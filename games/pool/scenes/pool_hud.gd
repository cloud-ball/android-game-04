class_name PoolHud
extends GameShell
## Break & Bank HUD on the shared GameShell: a top bar with both players (group by name AND number
## chips, never colour alone) - each row is a ball tray: the group's 7 balls + the 8, bright while
## still to pot, dimmed once potted, the 8 ringed when it is the target; a potted ball's slot
## pulses as it dims (a fly-in from the pocket pulled the eye off the table) - frame pips for
## best of 3, the pause button, the power bar (right), the fine-aim strip (left), the spin button
## + panel, and a one-line message. Holds no game state.

signal shoot(power: float)
signal nudge(dp: float)
signal spin_changed(side: float, top: float)

const ACCENT := Color(0.3, 0.85, 0.8)
const TOP_BAR_H := 108.0
const SLOT := 50.0  # tray slot pitch
const PULSE_TIME := 0.5

var power_bar: PoolControls.PowerBar
var fine: PoolControls.FineStrip
var spin_btn: PoolControls.SpinButton
var spin_panel: PoolControls.SpinPanel
var top_band := 0.0
var bottom_band := 210.0

var _names: Array[Label] = []
var _groups: Array[Label] = []
var _chips: Array[Control] = []
var _pips: Array[Control] = []
var _panel: Panel
## Tray state per player: group (PoolState.Group), balls in slot order, on the 8.
var _tray_group := PackedInt32Array([0, 0])
var _on_eight := [false, false]
var _on_table := PackedByteArray()
var _frames := PackedInt32Array([0, 0])
var _frame_target := 1
## Potted balls whose tray slot is pulsing: ball -> [t 0..1, owner]. They count as gone at once.
var _pulses := {}
var _msg: Label
var _pause_btn: Button
var _turn := 0


func _ready() -> void:
	configure(
		{
			"title": "Break & Bank",
			"accent": ACCENT,
			"modes": {"vs": "Single rack", "bo3": "Best of 3"},
			"blurbs":
			{
				"vs": "Pot your group - solids or stripes - then call and sink the 8.",
				"bo3": "First to two racks wins. Breaks alternate; a match win pays double.",
			},
			"howto": PoolHowto.cards(),
		}
	)
	mode = "vs"
	var top := UiKit.safe_top(self)
	top_band = top + 10.0 + TOP_BAR_H + 8.0
	bottom_band = 150.0 + _safe_bottom()
	_on_table.resize(16)
	_on_table.fill(1)
	_build_bar(top)
	_build_controls()
	set_process(false)
	build_shell()
	spin_panel = PoolControls.SpinPanel.new()
	add_child(spin_panel)
	spin_panel.chosen.connect(
		func(s: float, t: float) -> void:
			spin_btn.side = s
			spin_btn.top = t
			spin_btn.queue_redraw()
			spin_changed.emit(s, t)
	)


## Height of the system gesture / navigation area at the bottom, in canvas units.
func _safe_bottom() -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var win := Vector2(DisplayServer.window_get_size())
	var k := get_viewport().get_visible_rect().size.x / maxf(1.0, win.x)
	return maxf(0.0, (win.y - DisplayServer.get_display_safe_area().end.y) * k)


func _build_bar(top: float) -> void:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 28, Color(1, 1, 1, 0.08), 2))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(24, top + 10)
	panel.size = Vector2(1080 - 48 - 144 - 12, TOP_BAR_H)
	add_child(panel)
	_panel = panel
	for p in 2:
		var x := 26.0 if p == 0 else panel.size.x * 0.5 + 10.0
		var name := UiKit.label("YOU" if p == 0 else "CPU", 38, Color.WHITE, 900)
		name.position = Vector2(x, 6)
		panel.add_child(name)
		_names.append(name)
		var grp := UiKit.label("Open table", 28, UiKit.MUTED, 700)
		grp.position = Vector2(x + 100, 14)
		panel.add_child(grp)
		_groups.append(grp)
		var chips := Control.new()
		chips.position = Vector2(x, 54)
		chips.size = Vector2(panel.size.x * 0.5 - 40, 60)
		chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var who := p
		chips.draw.connect(func() -> void: _draw_chips(chips, who))
		panel.add_child(chips)
		_chips.append(chips)
		var pips := Control.new()
		pips.position = Vector2(x + 330, 12)
		pips.size = Vector2(80, 34)
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.draw.connect(func() -> void: _draw_pips(pips, who))
		panel.add_child(pips)
		_pips.append(pips)
	_pause_btn = UiKit.pause_button(112.0)
	_pause_btn.position = Vector2(1080 - 24 - 144, top + 10 + (TOP_BAR_H - 144) * 0.5)
	_pause_btn.size = Vector2(144, 144)
	_pause_btn.pressed.connect(
		func() -> void:
			AudioService.play("tap")
			pause_requested.emit()
	)
	add_child(_pause_btn)


func _build_controls() -> void:
	var h := get_viewport().get_visible_rect().size.y
	var bar_top := top_band + (h - top_band - bottom_band) * 0.3
	var bar_h := minf(860.0, h - bar_top - bottom_band - 40.0)
	power_bar = PoolControls.PowerBar.new()
	power_bar.position = Vector2(1080 - 150, bar_top)
	power_bar.size = Vector2(150, bar_h)
	power_bar.fired.connect(func(p: float) -> void: shoot.emit(p))
	add_child(power_bar)
	fine = PoolControls.FineStrip.new()
	fine.position = Vector2(0, bar_top)
	fine.size = Vector2(150, bar_h)
	fine.nudged.connect(func(dp: float) -> void: nudge.emit(dp))
	add_child(fine)
	spin_btn = PoolControls.SpinButton.new()
	spin_btn.position = Vector2(30, h - bottom_band - 8)
	spin_btn.size = Vector2(108, 108)
	spin_btn.pressed.connect(func() -> void: spin_panel.open(spin_btn.side, spin_btn.top))
	add_child(spin_btn)
	_msg = UiKit.label("", 34, Color(1, 1, 1, 0.9), 700)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.position = Vector2(180, h - bottom_band + 14)
	_msg.size = Vector2(680, 110)
	add_child(_msg)
	set_controls(false)


## Player controls on/off (off during CPU turns, rolling balls and overlays).
func set_controls(on: bool) -> void:
	for c in [power_bar, fine, spin_btn]:
		c.visible = on
	_msg.visible = true


func set_breaking(on: bool) -> void:
	power_bar.breaking = on


func reset_spin(top := 0.0) -> void:
	spin_btn.side = 0.0
	spin_btn.top = top
	spin_btn.queue_redraw()
	spin_changed.emit(0.0, top)


func set_message(text: String) -> void:
	_msg.text = text


## Shooter highlight, groups, the ball trays and (best of 3) the frame score.
func set_players(state: PoolState, series: PoolSeries = null) -> void:
	_turn = state.shooter
	_on_table = state.on_table.duplicate()
	if series != null:
		_frames = series.frames.duplicate()
		_frame_target = series.target
	for p in 2:
		var g := state.group[p]
		_tray_group[p] = g
		_groups[p].text = (
			"Open table"
			if g == PoolState.Group.NONE
			else ("Solids 1-7" if g == PoolState.Group.SOLIDS else "Stripes 9-15")
		)
		_names[p].add_theme_color_override(
			"font_color", ACCENT if state.shooter == p else Color(1, 1, 1, 0.55)
		)
		var left := 0
		for b in range(1, 16):
			if g != PoolState.Group.NONE and PoolState.group_of(b) == g and _on_table[b] == 1:
				left += 1
		_on_eight[p] = g != PoolState.Group.NONE and left == 0
		_chips[p].queue_redraw()
		_pips[p].queue_redraw()


## Slot index of ball b in its owner's tray (the 8 is the last slot).
static func slot_of(b: int) -> int:
	if b == 8:
		return 7
	return b - 1 if b < 8 else b - 9


## Owner of a potted ball: its group's player, else the shooter.
func _owner(b: int, state: PoolState) -> int:
	var g := PoolState.group_of(b)
	for p in 2:
		if g != PoolState.Group.NONE and state.group[p] == g:
			return p
	return state.shooter


## A ball dropped: its tray slot pulses and dims (nothing on an open table - no trays yet).
func ball_potted(b: int, state: PoolState) -> void:
	var who := _owner(b, state)
	if _tray_group[who] == PoolState.Group.NONE:
		return
	_pulses[b] = [0.0, who]
	set_process(true)


func _process(delta: float) -> void:
	for b in _pulses.keys():
		var pulse: Array = _pulses[b]
		pulse[0] += delta / PULSE_TIME
		_chips[pulse[1]].queue_redraw()
		if pulse[0] >= 1.0:
			_pulses.erase(b)
	if _pulses.is_empty():
		set_process(false)


func _draw_chips(c: Control, who: int) -> void:
	var g := _tray_group[who]
	if g == PoolState.Group.NONE:
		return
	var balls := range(1, 8) if g == PoolState.Group.SOLIDS else range(9, 16)
	balls.append(8)
	for b in balls:
		var ctr := Vector2(24 + slot_of(b) * SLOT, 26)
		var gone: bool = _on_table[b] == 0 or _pulses.has(b)
		if _pulses.has(b):
			var k: float = _pulses[b][0]
			var e := 1.0 - pow(1.0 - k, 3.0)
			c.draw_arc(
				ctr, lerpf(22.0, 36.0, e), 0.0, TAU, 32, Color(1, 1, 1, 0.9 * (1.0 - k)), 4.0
			)
			draw_ball_chip(c, ctr, b, lerpf(21.0, 15.0, e), lerpf(1.0, 0.3, e))
		elif b == 8:
			var target: bool = _on_eight[who] and not gone
			if target:
				c.draw_arc(ctr, 25, 0.0, TAU, 32, UiKit.GOLD, 4.0)
			draw_ball_chip(c, ctr, b, 21.0, 1.0 if target else 0.35)
		elif gone:
			c.draw_circle(ctr, 21, Color(1, 1, 1, 0.07))
			draw_ball_chip(c, ctr, b, 15.0, 0.3)
		else:
			draw_ball_chip(c, ctr, b, 21.0, 1.0)


## Best of 3: one pip per frame needed, filled for frames won.
func _draw_pips(c: Control, who: int) -> void:
	if _frame_target < 2:
		return
	for i in _frame_target:
		var ctr := Vector2(14 + i * 32, 17)
		if i < _frames[who]:
			c.draw_circle(ctr, 11, UiKit.GOLD)
		else:
			c.draw_arc(ctr, 10, 0.0, TAU, 24, Color(1, 1, 1, 0.45), 3.0)


## A numbered ball chip (stripes as a band), radius r, faded by alpha.
static func draw_ball_chip(c: CanvasItem, ctr: Vector2, b: int, r: float, alpha: float) -> void:
	var col: Color = PoolView.BALL_COLORS[b if b <= 8 else b - 8]
	var white := Color(0.9, 0.88, 0.82, alpha)
	c.draw_circle(ctr, r, white if b >= 9 else Color(col, alpha))
	if b >= 9:
		c.draw_rect(
			Rect2(ctr - Vector2(r, r * 0.43), Vector2(r * 2.0, r * 0.86)), Color(col, alpha)
		)
	c.draw_circle(ctr, r * 0.52, Color(0.95, 0.94, 0.9, alpha))
	var font := UiKit.font(900)
	var size := int(r * 0.76)
	var t := str(b)
	var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	c.draw_string(
		font,
		ctr + Vector2(-tw * 0.5, size * 0.37),
		t,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		Color(0, 0, 0, alpha)
	)


func show_start(stats_text: String) -> void:
	super(stats_text)
	_pause_btn.visible = false
	set_controls(false)


func show_howto(from_pause := false) -> void:
	super(from_pause)
	if not from_pause:
		_pause_btn.visible = false


func hide_panels() -> void:
	super()
	_pause_btn.visible = true


func show_end(info: Dictionary) -> void:
	super(info)
	_pause_btn.visible = false
	set_controls(false)
