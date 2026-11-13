class_name PracticeHint
extends Control
## First-match practice hint: the how-to fingertip loops a gesture over the real board with a short
## caption, until the game reports the move was done (or LOOPS loops pass). Never blocks input
## (mouse_filter IGNORE) and never pauses the game. Canvas coordinates throughout.

const LOOPS := 3
const HOLD_MS := 450.0

var verb := ""
var loops := 0
var caption := ""

var _g: GestureTimeline
var _glyph: GestureGlyph
var _t := 0.0
var _pill: StyleBoxFlat
var _anchor := Vector2.ZERO


func _init(accent := Color.WHITE) -> void:
	_glyph = GestureGlyph.new(accent)
	_pill = UiKit.box(Color(0.04, 0.05, 0.12, 0.88), 32, Color(accent, 0.7), 3)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # moved in _process


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


## Shows a looping hint for a verb. kind: GestureTimeline kind ("none" = caption only).
## anchor: where the caption sits (canvas units, its centre).
func show_hint(
	verb_id: String,
	kind: String,
	from: Vector2,
	to: Vector2,
	text: String,
	anchor: Vector2,
	steps := 1
) -> void:
	if verb == verb_id and visible:
		return
	verb = verb_id
	caption = text
	_anchor = anchor
	_g = GestureTimeline.new(kind, from, to, steps, HOLD_MS)
	_t = 0.0
	loops = 0
	visible = true
	set_process(true)
	queue_redraw()


## Hides the hint (only if it is showing verb_id, when given).
func hide_hint(verb_id := "") -> void:
	if verb_id != "" and verb_id != verb:
		return
	verb = ""
	visible = false
	set_process(false)


func is_showing() -> bool:
	return visible


func advance(ms: float) -> void:
	if not visible or _g == null:
		return
	_t += ms
	if _t >= _g.loop_ms:
		_t -= _g.loop_ms
		loops += 1
		if loops >= LOOPS:
			hide_hint()
			return
	queue_redraw()


func _process(delta: float) -> void:
	advance(delta * 1000.0)


func _draw() -> void:
	if _g == null:
		return
	# Caption pill (fades in with the first loop).
	var a := clampf(_t / 250.0, 0.0, 1.0) if loops == 0 else 1.0
	var font := UiKit.font(800)
	var w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x + 64.0
	var x := clampf(_anchor.x - w * 0.5, 24.0, size.x - w - 24.0)
	var r := Rect2(Vector2(x, _anchor.y - 40.0), Vector2(w, 80))
	modulate.a = a
	draw_style_box(_pill, r)
	draw_string(
		font, r.position + Vector2(32, 54), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE
	)
	_g.evaluate(_t)
	_glyph.draw(self, _g, 1.0)
