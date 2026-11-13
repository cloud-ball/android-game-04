extends Node
## Loads one game at a time with a threaded load behind a loading screen.
## The previous scene is freed. The loading screen stays up until the new scene has rendered a
## few frames, so first-use shader compilation happens behind it instead of as a visible freeze.

signal scene_changed(path: String)

const HUB_SCENE := "res://hub/hub.tscn"
## Frames the new scene renders under the loading screen before it fades out.
const WARM_FRAMES := 3

## Free-form parameters for the scene being opened (e.g. {"difficulty": "hard"}).
var params: Dictionary = {}
var current_game: String = ""

var _pending: String = ""
var _overlay: CanvasLayer
var _label: Label
var _hint: Label
var _spinner: Control
var _fade: ColorRect
var _warm := 0
var _t_start := 0
var _t_loaded := 0
var _spin := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	add_child(_overlay)
	_fade = ColorRect.new()
	_fade.color = Color(0.06, 0.07, 0.14, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_fade)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 28)
	_fade.add_child(col)
	_label = UiKit.label("", 56, Color(1, 1, 1, 0.9), 800)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_label)
	_spinner = Control.new()
	_spinner.custom_minimum_size = Vector2(96, 96)
	_spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_spinner.draw.connect(_draw_spinner)
	col.add_child(_spinner)
	_hint = UiKit.label("Loading…", 36, UiKit.MUTED, 600)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_hint)
	_overlay.visible = false
	set_process(false)


## force opens a game even while its manifest has enabled = false (dev launches via Boot).
func open_game(id: String, extra: Dictionary = {}, force := false) -> bool:
	var m := GameRegistry.get_manifest(id)
	if m == null or (not m.enabled and not force) or m.scene == "":
		push_warning("SceneRouter: game '%s' is not available" % id)
		return false
	current_game = id
	params = extra
	_go(m.scene, m.display_name.to_upper())
	return true


func back_to_hub() -> void:
	current_game = ""
	params = {}
	_go(HUB_SCENE, "")


func _go(path: String, title: String) -> void:
	if _pending != "" or _warm > 0:
		return
	get_tree().paused = false
	_pending = path
	_label.text = title
	_hint.visible = title != ""
	_spinner.visible = title != ""
	_overlay.visible = true
	_fade.modulate.a = 1.0
	_t_start = Time.get_ticks_msec()
	var err := ResourceLoader.load_threaded_request(path, "PackedScene", true)
	if err != OK:
		push_error("SceneRouter: cannot load %s (%s)" % [path, error_string(err)])
		_pending = ""
		_overlay.visible = false
		return
	set_process(true)


func _process(delta: float) -> void:
	_spin += delta * 6.0
	_spinner.queue_redraw()
	if _warm > 0:
		_warm -= 1
		if _warm == 0:
			_reveal()
		return
	var status := ResourceLoader.load_threaded_get_status(_pending)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	var path := _pending
	_pending = ""
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("SceneRouter: failed to load %s" % path)
		_overlay.visible = false
		set_process(false)
		return
	_t_loaded = Time.get_ticks_msec()
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	get_tree().change_scene_to_packed(packed)
	scene_changed.emit(path)
	_warm = WARM_FRAMES


func _reveal() -> void:
	set_process(false)
	if OS.is_debug_build():
		var now := Time.get_ticks_msec()
		print(
			"[load] %d ms to load, %d ms to first frames" % [_t_loaded - _t_start, now - _t_loaded]
		)
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: _overlay.visible = false)


func _draw_spinner() -> void:
	var c := _spinner.size * 0.5
	_spinner.draw_arc(c, 36.0, 0.0, TAU, 48, Color(1, 1, 1, 0.12), 8.0, true)
	_spinner.draw_arc(c, 36.0, _spin, _spin + 1.9, 24, Color(0.62, 0.72, 1.0), 8.0, true)
