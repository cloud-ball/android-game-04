extends Node
## Command-line options for development, screenshots and smoke tests (pass them after "--"):
##   --game=<id>          open a game straight away
##   --difficulty=<d>     easy | medium | hard
##   --mode=<m>           vs | solo
##   --bot                the player's side is driven by the CPU (scripted smoke runs)
##   --autostart          skip the game's start overlay
##   --seed=<n>           fix the session seed
##   --shot=<path>        save screenshots (use %d in the path when --shot-count > 1)
##   --shot-at=<frames>   first screenshot frame (default 120); --shot-every=<frames> (default 90)
##   --shot-count=<n>     number of screenshots (default 1)
##   --quit-after=<n>     quit after n frames
##   --fps                print frames per second to the log once a second

var options: Dictionary = {}
var bot := false

var _frame := 0
var _shots_taken := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	options = parse_args(OS.get_cmdline_user_args())
	bot = options.has("bot")
	if options.has("seed"):
		Rng.session_seed = int(options["seed"])
	if options.has("game"):
		var extra := {}
		for key in ["difficulty", "mode"]:
			if options.has(key):
				extra[key] = options[key]
		if options.has("autostart") or bot:
			extra["autostart"] = true
		SceneRouter.open_game.call_deferred(options["game"], extra)
	set_process(options.has("shot") or options.has("quit-after") or options.has("fps"))


func _process(_delta: float) -> void:
	_frame += 1
	if options.has("fps") and _frame % 60 == 0:
		var rid := get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(rid, true)
		print(
			(
				"[fps] %d  process %.1f ms  render cpu %.1f ms  gpu %.1f ms  draws %d"
				% [
					Engine.get_frames_per_second(),
					Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
					RenderingServer.viewport_get_measured_render_time_cpu(rid),
					RenderingServer.viewport_get_measured_render_time_gpu(rid),
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				]
			)
		)
	if options.has("shot"):
		var at := int(options.get("shot-at", 120))
		var every := maxi(1, int(options.get("shot-every", 90)))
		var count := int(options.get("shot-count", 1))
		if _shots_taken < count and _frame >= at and (_frame - at) % every == 0:
			_save_shot(str(options["shot"]))
	if options.has("quit-after") and _frame >= int(options["quit-after"]):
		get_tree().quit()


func _save_shot(pattern: String) -> void:
	var p := pattern % _shots_taken if pattern.contains("%d") else pattern
	var img := get_viewport().get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(p)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err := img.save_png(abs_path)
	print("[shot] %s -> %s" % [abs_path, error_string(err)])
	_shots_taken += 1


## Accepts "--key=value", "--key value" and bare "--flag".
static func parse_args(args: PackedStringArray) -> Dictionary:
	var out := {}
	var i := 0
	while i < args.size():
		var a := args[i]
		if a.begins_with("--"):
			var body := a.substr(2)
			if body.contains("="):
				out[body.get_slice("=", 0)] = body.substr(body.find("=") + 1)
			elif i + 1 < args.size() and not args[i + 1].begins_with("--"):
				out[body] = args[i + 1]
				i += 1
			else:
				out[body] = true
		i += 1
	return out
