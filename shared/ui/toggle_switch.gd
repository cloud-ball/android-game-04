class_name ToggleSwitch
extends Control
## Large, animated on/off switch drawn in code (Godot's default CheckButton is tiny on phones).

signal toggled(on: bool)

const ON_COLOR := Color(0.24, 0.78, 0.38)
const OFF_COLOR := Color(1, 1, 1, 0.16)

var pressed := false:
	set = set_pressed

var _t := 0.0  # knob position 0 (off) .. 1 (on), animated


func _init(on := false) -> void:
	custom_minimum_size = Vector2(150, 84)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	pressed = on
	_t = 1.0 if on else 0.0


## Sets the state without emitting `toggled` (use toggle() for user actions).
func set_pressed(on: bool) -> void:
	if on == pressed and is_inside_tree():
		return
	pressed = on
	if is_inside_tree():
		create_tween().tween_property(self, "_t", 1.0 if on else 0.0, 0.16).set_trans(
			Tween.TRANS_CUBIC
		)
		set_process(true)
	else:
		_t = 1.0 if on else 0.0
	queue_redraw()


func toggle() -> void:
	set_pressed(not pressed)
	toggled.emit(pressed)


func _process(_delta: float) -> void:
	queue_redraw()
	if is_equal_approx(_t, 1.0 if pressed else 0.0):
		set_process(false)


## Touches reach GUI controls as emulated mouse events (Android default), so handling mouse
## alone avoids double toggles; desktop mouse works the same way.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		accept_event()
		toggle()


func _draw() -> void:
	var h := size.y
	var r := h * 0.5
	var track := Rect2(Vector2.ZERO, size)
	var col := OFF_COLOR.lerp(ON_COLOR, _t)
	draw_rect(Rect2(track.position + Vector2(r, 0), Vector2(size.x - h, h)), col)
	draw_circle(Vector2(r, r), r, col)
	draw_circle(Vector2(size.x - r, r), r, col)
	var knob := Vector2(lerpf(r, size.x - r, _t), r)
	draw_circle(knob + Vector2(0, 3), r - 7, Color(0, 0, 0, 0.25))
	draw_circle(knob, r - 8, Color.WHITE)
