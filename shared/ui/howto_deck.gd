class_name HowtoDeck
extends Control
## Animated how-to cards: one verb per card, each a short looping demo drawn live on a stylised
## mini-board (the game supplies the drawing) with an original fingertip glyph driven by
## GestureTimeline. Header HOW TO PLAY + Skip; stage; title + sub-line; progress dots; Back / Next,
## PLAY (or GOT IT from the pause menu) on the last card. Demos loop LOOPS times, then freeze on
## their result frame with a Replay chip; the corner button pauses / resumes. "Try it": after the
## first loop the stage accepts the real gesture (TryGesture); doing it replays the board's reaction
## without the glyph and ticks the card. Cards change only through the buttons (a swipe inside the
## demo must not flip the card). With "reduce motion" on, each card shows its static poster.
## Design: docs/plans/2026-11-13-howto-cards.md.
##
## A card: {title, sub, demo: Callable(stage: Control, t_ms: float, g: GestureTimeline),
##          poster: Callable(c: Control) drawing in a 150 x 150 box, gesture: GestureTimeline,
##          try?: "tap" | "swipe" | "drag" | "flick" | "hold", try_rect?: Rect2 (design units)}
## Demos draw in DESIGN x DESIGN units; the deck scales them to the stage.

signal closed(play: bool)

const DESIGN := 920.0
const LOOPS := 3
const POSTER := 150.0
const STAGE_MAX := 860.0
const STAGE_MIN := 480.0
## Pause / play button in the stage's top-left corner (>= 48 dp).
const PAUSE_BTN := Rect2(14, 14, 123, 123)

var accent := Color.WHITE
var cards: Array = []
var index := 0
var t := 0.0
var loops := 0
var paused := false
var finished := false
var reduce_motion := false
## Cards whose gesture the player has done themselves.
var tried: Dictionary = {}
## Label of the last card's button; PLAY starts the match, anything else just closes.
var last_label := "PLAY"
## True while the board replays its reaction to the player's own gesture (glyph hidden).
var user_turn := false

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
var _glyph: GestureGlyph
var _chip: StyleBoxFlat
var _pill: StyleBoxFlat
var _pill_ok: StyleBoxFlat
var _press_pos := Vector2.ZERO
var _press_ms := 0
var _fingers := 0
var _tracking := false


func _init(accent_color := Color.WHITE) -> void:
	accent = accent_color
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # moved in _process
	_stage_style = UiKit.box(Color(0.03, 0.035, 0.09), 36, Color(accent, 0.28), 3)
	_glyph = GestureGlyph.new(accent)
	_chip = UiKit.box(Color(0.06, 0.07, 0.16, 0.92), 40, Color(1, 1, 1, 0.25), 2)
	_pill = UiKit.box(Color(accent, 0.9), 30)
	_pill_ok = UiKit.box(UiKit.GREEN, 30)


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
				close(last_label == "PLAY")
			else:
				show_card(index + 1)
	)
	row.add_child(_next)
	return row


## Opens the deck on the first card. motion_off shows the static posters (Reduce motion).
## final: the last card's button ("PLAY" starts the match; e.g. "GOT IT" from the pause menu).
func open(deck_cards: Array, motion_off := false, final := "PLAY") -> void:
	cards = deck_cards
	reduce_motion = motion_off
	last_label = final
	tried = {}
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
	_next.text = last_label if index == cards.size() - 1 else "Next"
	_next.scale = Vector2.ONE
	restart()
	_dots.queue_redraw()


func restart() -> void:
	t = 0.0
	loops = 0
	paused = false
	finished = false
	user_turn = false
	_tracking = false
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
		user_turn = false
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


## What the card asks the player to try ("" = nothing to try, e.g. a rule card).
func try_kind() -> String:
	if cards.is_empty():
		return ""
	var card: Dictionary = cards[index]
	if card.has("try"):
		return card["try"]
	var kind: String = gesture().kind
	return "" if kind == "none" else kind


## The prompt appears once the demo has played through once.
func try_open() -> bool:
	return try_kind() != "" and not reduce_motion and (loops >= 1 or finished)


## The player's own gesture on the stage: delta/ms/fingers in canvas units, at = press position
## in stage pixels. Returns true when it matched the card.
func try_gesture(delta: Vector2, ms: float, fingers: int, at: Vector2) -> bool:
	var want := try_kind()
	if want == "" or reduce_motion:
		return false
	var got := TryGesture.classify(delta, ms, fingers)
	if not TryGesture.satisfies(want, got):
		return false
	var card: Dictionary = cards[index]
	if want == "hold" and got == "tap" and card.has("try_rect"):
		var k := _side / DESIGN
		var r: Rect2 = card["try_rect"]
		if not Rect2(r.position * k, r.size * k).grow(24.0).has_point(at):
			return false
	_on_tried()
	return true


func _on_tried() -> void:
	tried[index] = true
	# Replay the board's reaction to "your" gesture, without the glyph.
	var g := gesture()
	user_turn = true
	finished = false
	paused = false
	t = g.press_ms
	loops = mini(loops, LOOPS - 1)
	set_process(visible)
	AudioService.play("tap", 1.3)
	if is_inside_tree():
		_next.pivot_offset = _next.size * 0.5
		var tw := create_tween()
		tw.tween_property(_next, "scale", Vector2(1.08, 1.08), 0.15)
		tw.tween_property(_next, "scale", Vector2.ONE, 0.2)
	_stage.queue_redraw()


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


## The stage takes the player's attempts ("Try it"); the corner button pauses; on a finished demo
## the Replay chip restarts it. Touches arrive as emulated mouse events; a second finger is seen as
## a screen touch with index 1.
func _on_stage_input(event: InputEvent) -> void:
	var st := event as InputEventScreenTouch
	if st != null and st.index > 0 and st.pressed and _tracking:
		_fingers = 2
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if mb.pressed:
		if PAUSE_BTN.has_point(mb.position) and not reduce_motion:
			toggle_pause()
			return
		if finished and _replay_rect().has_point(mb.position):
			restart()
			return
		_tracking = true
		_fingers = 1
		_press_pos = mb.position
		_press_ms = Time.get_ticks_msec()
	elif _tracking:
		_tracking = false
		var ms := float(Time.get_ticks_msec() - _press_ms)
		try_gesture(mb.position - _press_pos, ms, _fingers, _press_pos)


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
	if not finished and not user_turn:
		g.evaluate(t)
		_glyph.draw(_stage, g, k)
	_stage.draw_set_transform(Vector2.ZERO)
	_draw_pause_button()
	if tried.has(index):
		_draw_pill("✓ Nice!", _pill_ok)
	elif try_open():
		_draw_pill("Your turn - try it!", _pill)
	if paused:
		_draw_paused()
	elif finished:
		_draw_replay()


func _draw_poster() -> void:
	if reduce_motion and not cards.is_empty():
		var poster: Callable = cards[index].poster
		poster.call(_poster)


func _draw_pause_button() -> void:
	var c := PAUSE_BTN.get_center()
	_stage.draw_circle(c, 38.0, Color(0, 0, 0, 0.45))
	if paused:
		_stage.draw_colored_polygon(
			PackedVector2Array([c + Vector2(-12, -18), c + Vector2(18, 0), c + Vector2(-12, 18)]),
			Color.WHITE
		)
	else:
		_stage.draw_rect(Rect2(c + Vector2(-14, -16), Vector2(9, 32)), Color(1, 1, 1, 0.85))
		_stage.draw_rect(Rect2(c + Vector2(5, -16), Vector2(9, 32)), Color(1, 1, 1, 0.85))


func _draw_pill(text: String, style: StyleBoxFlat) -> void:
	var font := UiKit.font(800)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 56.0
	var r := Rect2(Vector2((_side - w) * 0.5, 22), Vector2(w, 64))
	_stage.draw_style_box(style, r)
	_stage.draw_string(
		font, r.position + Vector2(28, 44), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE
	)


func _draw_paused() -> void:
	var c := _stage.size * 0.5
	_stage.draw_circle(c, 70.0, Color(0, 0, 0, 0.55))
	_stage.draw_rect(Rect2(c + Vector2(-26, -30), Vector2(18, 60)), Color.WHITE)
	_stage.draw_rect(Rect2(c + Vector2(8, -30), Vector2(18, 60)), Color.WHITE)


func _replay_rect() -> Rect2:
	var w := 300.0
	return Rect2(Vector2((_side - w) * 0.5, _side - 123.0 - 24.0), Vector2(w, 123.0))


func _draw_replay() -> void:
	var r := _replay_rect()
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
