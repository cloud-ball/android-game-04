extends Node3D
## Fairway Flick controller (placeholder while the game is built behind enabled = false).
## Plan: docs/plans/2026-11-14-fairway-flick.md. The ball will be moved by a custom solver in
## _process-rendered steps, so root physics interpolation is OFF (CLAUDE.md).

const SAVE_SCHEMA := 1
const SAVE_DEFAULTS := {
	"played": 0,
	"wins": 0,
	"losses": 0,
	"best_score": 0,
	"difficulty": "medium",
	"tutorial_seen": false,
}

var _save: Dictionary


## Schema history: 1 = first version. Bump SAVE_SCHEMA and handle `from` here on any change.
static func migrate_save(old: Dictionary, _from: int, _to: int) -> Dictionary:
	return old


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # see CLAUDE.md
	_save = SaveService.game("golf", SAVE_SCHEMA, SAVE_DEFAULTS, migrate_save)
	_build_placeholder()


func _build_placeholder() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.78, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 80)
	ground.mesh = plane
	var turf := StandardMaterial3D.new()
	turf.albedo_color = Color(0.25, 0.58, 0.26)
	ground.material_override = turf
	add_child(ground)
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var p := GolfParams.new()
	sphere.radius = p.radius * 4.0  # drawn large so it reads on the placeholder
	sphere.height = sphere.radius * 2.0
	ball.mesh = sphere
	ball.position = Vector3(0, sphere.radius, 0)
	add_child(ball)
	var cam := Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 60.0
	cam.position = Vector3(0, 1.6, 3.0)
	add_child(cam)
	cam.look_at(Vector3(0, 0, -6))
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := UiKit.label("FAIRWAY FLICK", 64, Color.WHITE, 900)
	title.position = Vector2(0, 200)
	title.size = Vector2(1080, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(title)
	var sub := UiKit.label("Under construction", 36, Color(0.1, 0.22, 0.32), 700)
	sub.position = Vector2(0, 290)
	sub.size = Vector2(1080, 60)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(sub)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneRouter.back_to_hub()
