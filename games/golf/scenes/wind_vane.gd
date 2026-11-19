class_name WindVane
extends Control
## HUD wind indicator for the coastal holes: a round dial with an arrow pointing where the wind
## pushes the ball as seen from the camera, longer for a stronger wind, and a WIND caption.
## GolfShell owns it; golf_game turns it with the camera every frame (no allocations).

const SIZE := 120.0

var _wind := Vector2.ZERO  # world x / z push (m/s^2)
var _strength := 0.0  # 0..1 of MiniBaker.WIND_MAX
var _angle := 0.0  # screen angle of the arrow (0 = up, clockwise)


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE + 34.0)
	size = custom_minimum_size
	pivot_offset = Vector2(SIZE, SIZE) * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func set_wind(wx: float, wz: float) -> void:
	_wind = Vector2(wx, wz)
	_strength = clampf(_wind.length() / MiniBaker.WIND_MAX, 0.0, 1.0)
	visible = _strength > 0.01
	queue_redraw()


## The camera's horizontal facing (unit x / z): screen up. Rotates only the arrow layer.
func face(cam_dir: Vector3) -> void:
	if not visible:
		return
	var right := Vector2(-cam_dir.z, cam_dir.x)
	var fwd := Vector2(cam_dir.x, cam_dir.z)
	var a := atan2(_wind.dot(right), _wind.dot(fwd))
	if absf(a - _angle) > 0.01:
		_angle = a
		queue_redraw()


func _draw() -> void:
	var c := Vector2(SIZE, SIZE) * 0.5
	draw_circle(c, SIZE * 0.5, Color(0, 0, 0, 0.45))
	draw_arc(c, SIZE * 0.5 - 3.0, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 3.0, true)
	var len := SIZE * (0.2 + 0.22 * _strength)
	var dir := Vector2(sin(_angle), -cos(_angle))
	var side := Vector2(-dir.y, dir.x)
	var tip := c + dir * len
	var tail := c - dir * len
	var col := Color(0.55, 0.9, 1.0)
	draw_line(tail, tip - dir * 14.0, col, 8.0, true)
	draw_colored_polygon(
		PackedVector2Array([tip, tip - dir * 26.0 + side * 16.0, tip - dir * 26.0 - side * 16.0]),
		col
	)
	var font := get_theme_default_font()
	draw_string(
		font, Vector2(0, SIZE + 28.0), "WIND", HORIZONTAL_ALIGNMENT_CENTER, SIZE, 26, Color.WHITE
	)
