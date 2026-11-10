extends Node
## Reads games/*/manifest.tres. Adding a game = a folder + a manifest.

const GAMES_DIR := "res://games"

var _manifests: Array[GameManifest] = []


func _ready() -> void:
	reload()


func reload() -> void:
	_manifests = scan(GAMES_DIR)


## All manifests (enabled or not), sorted by order then id.
func all() -> Array[GameManifest]:
	return _manifests


func get_manifest(id: String) -> GameManifest:
	for m in _manifests:
		if m.id == id:
			return m
	return null


static func scan(root: String) -> Array[GameManifest]:
	var out: Array[GameManifest] = []
	for folder in DirAccess.get_directories_at(root):
		# ResourceLoader.exists also handles the .remap files written by exported builds.
		var p := "%s/%s/manifest.tres" % [root, folder]
		if not ResourceLoader.exists(p):
			continue
		var m := load(p) as GameManifest
		if m != null and m.id != "":
			out.append(m)
	out.sort_custom(
		func(a: GameManifest, b: GameManifest) -> bool:
			return a.order < b.order if a.order != b.order else a.id < b.id
	)
	return out
