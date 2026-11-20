class_name GolfShell
extends GameShell
## Cup Dash screens: the shared GameShell (start with mode + difficulty, how-to, pause, end)
## plus the hole HUD (top panel, banners, aim hint, MAP, pause, power ring) on a layer under the
## overlays, and a world picker on the start screen (locked worlds greyed out).

signal world_changed(world_id: String)
signal map_pressed

const ACCENT := Color(0.45, 0.9, 0.55)
const COVER_IN := 0.15  # s: fade to the cover before a hole is built
const COVER_OUT := 0.3  # s: fade back in on the new hole

var world := "meadow"
## Under the overlays: the hole HUD and the Rush strip / cards live here.
var hud: Control
var hud_top: Label
var hud_info: Label
var shot_banner: Label  # (GameShell already has banner())
var stars: Label
var card: Label
var hint: Label
var map_btn: Button
var power_ui: Control
var wind: WindVane
## A solid panel over the 3D view and the hole HUD (under the menus) while a hole is built.
var cover: ColorRect

var _unlocked: Array = ["meadow"]
var _covering := false
var _world_buttons: Dictionary = {}


func setup(unlocked: Array) -> void:
	_unlocked = unlocked
	configure(
		{
			"title": "Cup Dash",
			"accent": ACCENT,
			"modes": {"rush": "Rush vs CPU", "tour": "Tour"},
			"blurbs":
			{
				"rush":
				"Race three CPU golfers: first ball in the cup wins the hole. Win to open a new world.",
				"tour":
				"Play nine holes on your own: par earns a star. Finish to open a new world.",
			},
			"howto": GolfHowto.cards(),
		}
	)
	_build_hud()
	build_shell()
	_add_world_picker()
	cover = ColorRect.new()
	cover.color = Color(0.03, 0.05, 0.09)
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP  # no stray taps while the hole is built
	cover.visible = false
	add_child(cover)
	move_child(cover, hud.get_index() + 1)


func show_hud(on: bool) -> void:
	hud.visible = on


## Fades the cover in, runs `work` (building a hole: a few hundred ms on a phone) while the screen
## is covered, lets the new hole render two frames, then fades out - a short transition instead of
## a visible freeze. A second request while one is running is ignored.
func covered(work: Callable) -> void:
	if _covering:
		return
	_covering = true
	cover.visible = true
	var tw := create_tween()
	tw.tween_property(cover, "modulate:a", 1.0, COVER_IN)
	await tw.finished
	work.call()
	await get_tree().process_frame
	await get_tree().process_frame
	tw = create_tween()
	tw.tween_property(cover, "modulate:a", 0.0, COVER_OUT)
	await tw.finished
	cover.visible = false
	_covering = false


func set_world(id: String) -> void:
	world = id
	_highlight(_world_buttons, id)


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var top := UiKit.safe_top(self)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.03, 0.12, 0.08, 0.66), 26))
	panel.position = Vector2(24, top + 10)
	panel.size = Vector2(900, 140)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(panel)
	hud_top = UiKit.label("", 40, Color.WHITE, 900)
	hud_top.position = Vector2(28, 12)
	panel.add_child(hud_top)
	hud_info = UiKit.label("", 32, Color(1, 1, 1, 0.85), 700)
	hud_info.position = Vector2(28, 76)
	panel.add_child(hud_info)
	var pause := UiKit.pause_button(112.0)
	pause.position = Vector2(1080 - 24 - UiKit.PAUSE_HIT, top + 10)  # same spot as the other games
	pause.pressed.connect(func() -> void: pause_requested.emit())
	hud.add_child(pause)
	shot_banner = _outlined(88, UiKit.GOLD, 18)
	shot_banner.position = Vector2(0, 560)
	shot_banner.size = Vector2(1080, 260)
	stars = _outlined(96, UiKit.GOLD, 16)
	stars.position = Vector2(0, 830)
	stars.size = Vector2(1080, 140)
	card = _outlined(76, Color.WHITE, 18)
	card.position = Vector2(0, 480)
	card.size = Vector2(1080, 420)
	var h := get_viewport().get_visible_rect().size.y
	hint = _outlined(32, Color.WHITE, 10)
	hint.position = Vector2(40, h - 230)
	hint.size = Vector2(1000, 100)
	map_btn = UiKit.button("MAP", Color(0, 0, 0, 0.5), Color.WHITE, 30, 90)
	map_btn.position = Vector2(1080 - 24 - 150, top + 166)
	map_btn.size = Vector2(150, 90)
	map_btn.pressed.connect(func() -> void: map_pressed.emit())
	hud.add_child(map_btn)
	wind = WindVane.new()
	wind.position = Vector2(1080 - 24 - 135, top + 280)
	hud.add_child(wind)
	power_ui = Control.new()
	power_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	power_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(power_ui)


func _outlined(size: int, col: Color, outline: int) -> Label:
	var l := UiKit.label("", size, col, 900)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(l)
	return l


## A row of world buttons under the mode choice; locked worlds are greyed out (the blurbs say how
## to open them).
func _add_world_picker() -> void:
	var cols := _start.find_children("*", "VBoxContainer", true, false)
	if cols.is_empty():
		return
	var col: VBoxContainer = cols[0]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for w: Dictionary in GolfWorlds.WORLDS:
		var open: bool = w.id in _unlocked
		var b := UiKit.button(w.name, Color(1, 1, 1, 0.1), Color.WHITE, 32, 90)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not open
		var id: String = w.id
		b.pressed.connect(
			func() -> void:
				set_world(id)
				world_changed.emit(id)
		)
		_world_buttons[id] = b
		row.add_child(b)
	col.add_child(row)
	col.move_child(row, mini(3, col.get_child_count() - 1))
	set_world(world)
