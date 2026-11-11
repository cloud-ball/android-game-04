extends Node
## Loads one game at a time with a threaded load behind a loading screen.
## The previous scene is freed.

signal scene_changed(path: String)

const HUB_SCENE := "res://hub/hub.tscn"

## Free-form parameters for the scene being opened (e.g. {"difficulty": "hard"}).
var params: Dictionary = {}
var current_game: String = ""

var _pending: String = ""
var _overlay: CanvasLayer
var _label: Label
var _fade: ColorRect


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
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 56)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_fade.add_child(_label)
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
	if _pending != "":
		return
	get_tree().paused = false
	_pending = path
	_label.text = title
	_overlay.visible = true
	_fade.modulate.a = 1.0
	var err := ResourceLoader.load_threaded_request(path, "PackedScene", true)
	if err != OK:
		push_error("SceneRouter: cannot load %s (%s)" % [path, error_string(err)])
		_pending = ""
		_overlay.visible = false
		return
	set_process(true)


func _process(_delta: float) -> void:
	var status := ResourceLoader.load_threaded_get_status(_pending)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	set_process(false)
	var path := _pending
	_pending = ""
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("SceneRouter: failed to load %s" % path)
		_overlay.visible = false
		return
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	get_tree().change_scene_to_packed(packed)
	scene_changed.emit(path)
	var tw := create_tween()
	tw.tween_interval(0.05)
	tw.tween_property(_fade, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: _overlay.visible = false)
