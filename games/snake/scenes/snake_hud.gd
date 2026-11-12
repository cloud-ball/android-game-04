class_name SnakeHud
extends GameShell
## Serpent Grid's HUD: its own score bar and pause button on top of the shared GameShell
## overlays (start, how-to, countdown, banners, pause, results). Holds no game state.

const MODES := ["vs", "solo"]

var _you: Label
var _cpu: Label
var _mode: Label
var _speed: Label
var _pause_btn: Button


func _ready() -> void:
	configure(
		{
			"title": "Serpent Grid",
			"accent": UiKit.NEON_GREEN,
			"modes": {"vs": "vs CPU", "solo": "Solo"},
			"blurbs":
			{
				"vs": "Eat orbs to grow. Make the CPU snake crash first.",
				"solo": "Eat orbs, grow long, beat your best score.",
			},
			"howto":
			[
				[
					_draw_howto.bind("swipe"),
					"Swipe anywhere to turn.",
					"Two quick swipes make a tight U-turn."
				],
				[
					_draw_howto.bind("orb"),
					"Eat glowing orbs to grow.",
					"Each orb is +10. Longer snakes move faster."
				],
				[
					_draw_howto.bind("crash"),
					"Make the CPU crash first.",
					"Cut it off so it runs into you or itself."
				],
				[
					_draw_howto.bind("wall"),
					"Edges wrap around.",
					"Go out one side, come back on the other. Only tails crash."
				],
			],
		}
	)
	mode = "vs"
	_build_bar(UiKit.safe_top(self))
	build_shell()


func _build_bar(top: float) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 28, Color.TRANSPARENT, 0, 26))
	panel.position = Vector2(32, 28 + top)
	panel.size = Vector2(1016, 0)
	add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 2
	panel.add_child(grid)
	var name_label := UiKit.label("SERPENT GRID", 38, UiKit.NEON_GREEN, 900)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(name_label)
	_mode = UiKit.label("vs CPU", 36, UiKit.MUTED, 600)
	_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_mode)
	_you = UiKit.label("YOU 000 · length 3", 38, Color(0.85, 1.0, 0.9), 800)
	grid.add_child(_you)
	_cpu = UiKit.label("CPU 000 · length 3", 38, UiKit.MAGENTA, 800)
	_cpu.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(_cpu)
	_speed = UiKit.label("", 36, UiKit.MUTED, 600)
	_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed.position = Vector2(0, 222 + top)
	_speed.size = Vector2(1080, 40)
	add_child(_speed)
	_pause_btn = UiKit.button("II", Color(1, 1, 1, 0.12), Color.WHITE, 36, 96)
	_pause_btn.custom_minimum_size = Vector2(96, 96)
	_pause_btn.position = Vector2(952, 206 + top)
	_pause_btn.pressed.connect(func() -> void: pause_requested.emit())
	add_child(_pause_btn)


## Small drawn illustrations for the how-to screen (original vector art, no images).
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
			# Snake leaving the right edge and coming back in on the left.
			var edge := Color(0.55, 0.7, 1.0, 0.6)
			c.draw_rect(Rect2(Vector2(6, 10), Vector2(6, 130)), edge)
			c.draw_rect(Rect2(Vector2(138, 10), Vector2(6, 130)), edge)
			for i in 2:
				c.draw_rect(Rect2(Vector2(84 + i * 28, 90), Vector2(26, 26)), g * (0.6 + 0.2 * i))
			c.draw_rect(Rect2(Vector2(16, 90), Vector2(26, 26)), g * 1.1)
			c.draw_arc(Vector2(75, 90), 62, PI * 1.05, PI * 1.95, 24, Color.WHITE, 5.0)
			c.draw_colored_polygon(
				PackedVector2Array([Vector2(14, 78), Vector2(10, 98), Vector2(30, 88)]), Color.WHITE
			)


func _on_labels_changed() -> void:
	_mode.text = mode_label()
	_cpu.visible = mode == "vs"


func show_start(stats_text: String) -> void:
	super(stats_text)
	_pause_btn.visible = false


func show_howto() -> void:
	super()
	_pause_btn.visible = false


func hide_panels() -> void:
	super()
	_pause_btn.visible = true


func show_end(info: Dictionary) -> void:
	super(info)
	_pause_btn.visible = false


func set_scores(you_score: int, you_len: int, cpu_score: int, cpu_len: int, hz: float) -> void:
	_you.text = "YOU %03d · length %d" % [you_score, you_len]
	_cpu.text = "CPU %03d · length %d" % [cpu_score, cpu_len]
	_speed.text = "speed %.1f tiles/s" % hz
