class_name HowtoDeck
extends Control
## Animated how-to cards: one verb per card, each a short looping demo drawn live on a stylised
## mini-board (the game supplies the drawing) with an original fingertip glyph driven by
## GestureTimeline. Header HOW TO PLAY + Skip; stage; title + sub-line; progress dots; Back / Next,
## PLAY on the last card. Demos loop LOOPS times, then freeze on their result frame with a Replay
## chip; tapping the stage pauses / resumes. Cards change only through the buttons (players copy
## the gestures inside the demo, so a swipe must not flip the card). With "reduce motion" on, each
## card shows its static poster instead. Design: docs/plans/2026-11-13-howto-cards.md.
##
## A card: {title, sub, demo: Callable(stage: Control, t_ms: float, g: GestureTimeline),
##          poster: Callable(c: Control) drawing in a 150 x 150 box, gesture: GestureTimeline}
## Demos draw in DESIGN x DESIGN units; the deck scales them to the stage.

signal closed(play: bool)

const DESIGN := 920.0
const LOOPS := 3
const POSTER := 150.0
const STAGE_MAX := 860.0
const STAGE_MIN := 480.0
const GLYPH_ROT := -0.35  # tilted like a right thumb reaching in from the bottom-right

var accent := Color.WHITE
var cards: Array = []
var index := 0
var t := 0.0
var loops := 0
var paused := false
var finished := false
var reduce_motion := false

var _panel: PanelContainer
var _stage: Control
var _title: Label
var _sub: Label
var _dots: Control
## Static poster (Reduce motion): its own 150 x 150 control, scaled up inside the stage.
var _poster: Control
var _back: Button
var _next: Button
var _side := STAGE_MAX
var _stage_style: StyleBoxFlat
var _finger: StyleBoxFlat
var _finger_shadow: StyleBoxFlat
var _chip: StyleBoxFlat


func _init(accent_color := Color.WHITE) -> void:
	accent = accent_color
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # moved in _process
	_stage_style = UiKit.box(Color(0.03, 0.035, 0.09), 36, Color(accent, 0.28), 3)
	_finger = UiKit.box(Color(1, 1, 1, 0.88), 42, Color(0.05, 0.06, 0.12, 0.9), 6)
	_finger_shadow = UiKit.box(Color(0, 0, 0, 0.3), 42)
	_chip = UiKit.box(Color(0.06, 0.07, 0.16, 0.92), 40, Color(1, 1, 1, 0.25), 2)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(
		"panel", UiKit.box(Color(0.07, 0.08, 0.17, 0.97), 40, accent.darkened(0.2), 3, 28)
	)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	_panel.add_child(col)
	col.add_child(_header())
	_stage = Control.new()
	_stage.draw.connect(_draw_stage)
	_stage.gui_input.connect(_on_stage_input)
	_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_stage)
	_poster = Control.new()
	_poster.size = Vector2(POSTER, POSTER)
	_poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_poster.draw.connect(_draw_poster)
	_stage.add_child(_poster)
	_title = UiKit.label("", 52, Color.WHITE, 800)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_sub = UiKit.label("", 34, UiKit.MUTED, 500)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_sub)
	_dots = Control.new()
	_dots.custom_minimum_size = Vector2(0, 28)
	_dots.draw.connect(_draw_dots)
	col.add_child(_dots)
	col.add_child(_footer())
	set_process(false)


func _header() -> Control:
	var row := HBoxContainer.new()
	var title := UiKit.label("HOW TO PLAY", 44, accent, 900)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var skip := UiKit.button("Skip", Color(1, 1, 1, 0.0), UiKit.MUTED, 38, 123)
	skip.custom_minimum_size.x = 190
	skip.pressed.connect(func() -> void: close(false))
	row.add_child(skip)
	return row


func _footer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_back = UiKit.button("Back", Color(1, 1, 1, 0.12), Color.WHITE, 40, 130)
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back.pressed.connect(func() -> void: show_card(index - 1))
	row.add_child(_back)
	_next = UiKit.button("Next", UiKit.GREEN, Color.WHITE, 46, 130)
	_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next.size_flags_stretch_ratio = 1.4
	_next.pressed.connect(
		func() -> void:
			if index >= cards.size() - 1:
				close(true)
			else:
				show_card(index + 1)
	)
	row.add_child(_next)
	return row


## Opens the deck on the first card. motion_off shows the static posters (Reduce motion).
func open(deck_cards: Array, motion_off := false) -> void:
	cards = deck_cards
	reduce_motion = motion_off
	var h := get_viewport_rect().size.y if is_inside_tree() else 2400.0
	_side = clampf(h - 800.0, STAGE_MIN, STAGE_MAX)
	_stage.custom_minimum_size = Vector2(_side, _side)
	_panel.custom_minimum_size = Vector2(_side + 56.0, 0)
	visible = true
	show_card(0)


func close(play: bool) -> void:
	visible = false
	set_process(false)
	closed.emit(play)


func is_open() -> bool:
	return visible


func show_card(i: int) -> void:
	if cards.is_empty():
		return
	index = clampi(i, 0, cards.size() - 1)
	var card: Dictionary = cards[index]
	_title.text = card.title
	_sub.text = card.sub
	_back.visible = index > 0  # Next spans the row on the first card
	_next.text = "PLAY" if index == cards.size() - 1 else "Next"
	restart()
	_dots.queue_redraw()


func restart() -> void:
	t = 0.0
	loops = 0
	paused = false
	finished = false
	set_process(visible and not reduce_motion)
	_stage.queue_redraw()


func gesture() -> GestureTimeline:
	return cards[index].gesture


## Moves the current demo forward by ms (also used by tests and the screenshot hook).
func advance(ms: float) -> void:
	if paused or finished or reduce_motion or cards.is_empty():
		return
	var g := gesture()
	t += ms
	while t >= g.loop_ms:
		loops += 1
		if loops >= LOOPS:
			finished = true
			t = result_ms()
			set_process(false)
			break
		t -= g.loop_ms
	_stage.queue_redraw()


## The frame a finished demo rests on: half-way through holding the result.
func result_ms() -> float:
	var g := gesture()
	return g.lift_ms + g.hold * 0.5


func toggle_pause() -> void:
	if finished:
		restart()
		return
	paused = not paused
	set_process(not paused)
	_stage.queue_redraw()


## Dev/screenshot hook: show card i frozen at t_ms.
func debug_freeze(i: int, t_ms: float) -> void:
	show_card(i)
	t = t_ms
	set_process(false)
	_stage.queue_redraw()


func _process(delta: float) -> void:
	advance(delta * 1000.0)


func _on_stage_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		toggle_pause()
		accept_event()


# --- drawing ------------------------------------------------------------------------------------


func _draw_stage() -> void:
	if cards.is_empty():
		return
	var card: Dictionary = cards[index]
	var k := _side / DESIGN
	_stage.draw_style_box(_stage_style, Rect2(Vector2.ZERO, Vector2(_side, _side)))
	_poster.visible = reduce_motion
	if reduce_motion:
		var s := _side * 0.62 / POSTER
		_poster.scale = Vector2(s, s)
		_poster.position = Vector2.ONE * (_side - POSTER * s) * 0.5
		_poster.queue_redraw()
		return
	var g: GestureTimeline = card.gesture
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var demo: Callable = card.demo
	demo.call(_stage, t, g)
	if not finished:
		g.evaluate(t)
		_draw_glyph(g, k)
	_stage.draw_set_transform(Vector2.ZERO)
	if paused:
		_draw_paused()
	elif finished:
		_draw_replay()


func _draw_poster() -> void:
	if reduce_motion and not cards.is_empty():
		var poster: Callable = cards[index].poster
		poster.call(_poster)


func _draw_glyph(g: GestureTimeline, k: float) -> void:
	if not g.visible:
		return
	var c := _stage
	var a := g.alpha
	if g.ripple >= 0.0:
		var r := lerpf(18.5, 61.5, g.ripple)
		c.draw_arc(g.pos, r, 0.0, TAU, 40, Color(1, 1, 1, 0.9 * g.ripple_alpha * a), 6.0, true)
	if g.trail_alpha > 0.0:
		var reach := 0.5 * g.from.distance_to(g.to)
		var start := g.pos + (g.trail_from - g.pos).limit_length(reach)
		for i in 8:
			var p0 := start.lerp(g.pos, i / 8.0)
			var p1 := start.lerp(g.pos, (i + 1) / 8.0)
			var w := 14.0 * (i + 1) / 8.0
			var col := Color(
				accent.lightened(0.5), g.trail_alpha * a * (0.25 + 0.75 * (i + 1) / 8.0)
			)
			c.draw_line(p0, p1, col, w, true)
	if g.ghosts:
		var dir := (g.to - g.from).normalized()
		for i in range(1, 4):
			c.draw_circle(g.pos - dir * 34.0 * i, 14.0, Color(1, 1, 1, 0.22 * a / i))
		var side := Vector2(-dir.y, dir.x)
		for j in [-1.0, 1.0]:
			var base: Vector2 = g.pos - dir * 40.0 + side * 36.0 * j
			c.draw_line(base, base - dir * 70.0, Color(1, 1, 1, 0.5 * a), 4.0, true)
	if g.down:
		c.draw_circle(g.pos, 26.0, Color(accent, 0.3 * a))
		c.draw_circle(g.pos, 14.0, Color(1.0, 0.95, 0.6, a))
	# Fingertip capsule: tip just past the contact point, body towards the bottom-right.
	_finger.bg_color.a = 0.88 * a
	_finger.border_color.a = 0.9 * a
	_finger_shadow.bg_color.a = 0.3 * a
	var body := Rect2(Vector2(-42, -16), Vector2(84, 150))
	c.draw_set_transform(g.pos * k, GLYPH_ROT, Vector2.ONE * k * g.scale)
	c.draw_style_box(_finger_shadow, Rect2(body.position + Vector2(8, 10), body.size))
	c.draw_style_box(_finger, body)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))


func _draw_paused() -> void:
	var c := _stage.size * 0.5
	_stage.draw_circle(c, 70.0, Color(0, 0, 0, 0.55))
	_stage.draw_rect(Rect2(c + Vector2(-26, -30), Vector2(18, 60)), Color.WHITE)
	_stage.draw_rect(Rect2(c + Vector2(8, -30), Vector2(18, 60)), Color.WHITE)


func _draw_replay() -> void:
	var w := 300.0
	var r := Rect2(Vector2((_side - w) * 0.5, _side - 123.0 - 24.0), Vector2(w, 123.0))
	_stage.draw_style_box(_chip, r)
	var ic := r.position + Vector2(70, 61.5)
	_stage.draw_arc(ic, 22.0, 0.6, TAU - 0.3, 24, Color.WHITE, 6.0, true)
	_stage.draw_colored_polygon(
		PackedVector2Array([ic + Vector2(22, -14), ic + Vector2(36, 4), ic + Vector2(8, 4)]),
		Color.WHITE
	)
	_stage.draw_string(
		UiKit.font(800), r.position + Vector2(108, 75), "Replay", HORIZONTAL_ALIGNMENT_LEFT, -1, 38
	)


func _draw_dots() -> void:
	var n := cards.size()
	if n <= 1:
		return
	var gap := 20.0
	var dot := 16.0
	var pill := 44.0
	var total := pill + (n - 1) * dot + (n - 1) * gap
	var x := (_dots.size.x - total) * 0.5
	var y := _dots.size.y * 0.5
	for i in n:
		if i == index:
			var r := Rect2(Vector2(x, y - dot * 0.5), Vector2(pill, dot))
			_dots.draw_style_box(UiKit.box(accent, 8), r)
			x += pill + gap
		else:
			_dots.draw_arc(
				Vector2(x + dot * 0.5, y), dot * 0.5 - 1.5, 0.0, TAU, 20, Color(1, 1, 1, 0.55), 3.0
			)
			x += dot + gap
