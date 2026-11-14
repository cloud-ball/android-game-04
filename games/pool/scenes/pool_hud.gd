class_name PoolHud
extends GameShell
## Cue Club HUD on the shared GameShell: a top bar with both players (group by name AND number
## chips, never colour alone), the pause button, the power bar (right), the fine-aim strip (left),
## the spin button + panel, and a one-line message. Holds no game state.

signal shoot(power: float)
signal nudge(dp: float)
signal spin_changed(side: float, top: float)

const ACCENT := Color(0.3, 0.85, 0.8)
const TOP_BAR_H := 108.0

var power_bar: PoolControls.PowerBar
var fine: PoolControls.FineStrip
var spin_btn: PoolControls.SpinButton
var spin_panel: PoolControls.SpinPanel
var top_band := 0.0
var bottom_band := 210.0

var _names: Array[Label] = []
var _groups: Array[Label] = []
var _chips: Array[Control] = []
var _chip_balls: Array = [[], []]
var _msg: Label
var _pause_btn: Button
var _turn := 0


func _ready() -> void:
	configure(
		{
			"title": "Cue Club",
			"accent": ACCENT,
			"modes": {"vs": "vs CPU"},
			"blurbs": {"vs": "Pot your group - solids or stripes - then call and sink the 8."},
			"howto": PoolHowto.cards(),
		}
	)
	mode = "vs"
	var top := UiKit.safe_top(self)
	top_band = top + 10.0 + TOP_BAR_H + 8.0
	bottom_band = 150.0 + _safe_bottom()
	_build_bar(top)
	_build_controls()
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


## Shooter highlight, groups and remaining balls per player.
func set_players(state: PoolState) -> void:
	_turn = state.shooter
	for p in 2:
		var g := state.group[p]
		_groups[p].text = (
			"Open table"
			if g == PoolState.Group.NONE
			else ("Solids 1-7" if g == PoolState.Group.SOLIDS else "Stripes 9-15")
		)
		_names[p].add_theme_color_override(
			"font_color", ACCENT if state.shooter == p else Color(1, 1, 1, 0.55)
		)
		var balls := []
		if g != PoolState.Group.NONE:
			for b in range(1, 16):
				if PoolState.group_of(b) == g and state.on_table[b] == 1:
					balls.append(b)
			if balls.is_empty() and state.on_table[8] == 1:
				balls.append(8)
		_chip_balls[p] = balls
		_chips[p].queue_redraw()


func _draw_chips(c: Control, who: int) -> void:
	var balls: Array = _chip_balls[who]
	var font := UiKit.font(900)
	for i in balls.size():
		var b: int = balls[i]
		var ctr := Vector2(24 + i * 50, 26)
		var col: Color = PoolView.BALL_COLORS[b if b <= 8 else b - 8]
		c.draw_circle(ctr, 21, Color(0.9, 0.88, 0.82) if b >= 9 else col)
		if b >= 9:
			c.draw_rect(Rect2(ctr - Vector2(21, 9), Vector2(42, 18)), col)
		c.draw_circle(ctr, 11, Color(0.95, 0.94, 0.9))
		var t := str(b)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		c.draw_string(
			font, ctr + Vector2(-tw * 0.5, 6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK
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
