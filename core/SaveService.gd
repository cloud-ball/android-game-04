extends Node
## One versioned save file. Each game owns only data["games"][<id>] with its own schema + migrate().
## Unknown keys are preserved. Writes go temp file -> rename, keeping one rolling backup.
## Note: JSON numbers load back as floats; read them with int()/float().

signal saved

const SCHEMA := 1
const DEFAULT_PATH := "user://save.json"
const SECTIONS := ["profile", "economy", "settings", "games"]

var path: String = DEFAULT_PATH
var data: Dictionary = {}


func _ready() -> void:
	load_from_disk()


func load_from_disk() -> void:
	var loaded := _read(path)
	if loaded.is_empty():
		loaded = _read(path + ".bak")
	data = normalize(loaded)


static func blank() -> Dictionary:
	return {"schema": SCHEMA, "profile": {}, "economy": {}, "settings": {}, "games": {}}


## Fills missing sections, keeps every unknown key untouched.
static func normalize(d: Dictionary) -> Dictionary:
	var out := blank()
	for k in d.keys():
		out[k] = d[k]
	for k in SECTIONS:
		if typeof(out[k]) != TYPE_DICTIONARY:
			out[k] = {}
	out["schema"] = maxi(int(out.get("schema", SCHEMA)), SCHEMA)
	return out


## Returns the game's namespace (by reference), creating or migrating it first.
## migrate: func(old: Dictionary, from_schema: int, to_schema: int) -> Dictionary
func game(id: String, schema: int, defaults: Dictionary, migrate := Callable()) -> Dictionary:
	var games: Dictionary = data["games"]
	games[id] = prepare_namespace(games.get(id), schema, defaults, migrate)
	return games[id]


static func prepare_namespace(
	existing: Variant, schema: int, defaults: Dictionary, migrate := Callable()
) -> Dictionary:
	var g: Dictionary
	if typeof(existing) == TYPE_DICTIONARY:
		g = existing
		var from := int(g.get("schema", 0))
		if from < schema and migrate.is_valid():
			g = migrate.call(g, from, schema)
		g["schema"] = maxi(from, schema)
	else:
		g = {"schema": schema}
	for k in defaults.keys():
		if not g.has(k):
			g[k] = defaults[k]
	return g


func save() -> Error:
	var err := write_atomic(path, JSON.stringify(data, "\t"))
	if err == OK:
		saved.emit()
	return err


static func write_atomic(target: String, text: String) -> Error:
	var abs_target := ProjectSettings.globalize_path(target)
	var dir := abs_target.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var tmp := abs_target + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	var bak := abs_target + ".bak"
	if FileAccess.file_exists(abs_target):
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		var e1 := DirAccess.rename_absolute(abs_target, bak)
		if e1 != OK:
			return e1
	return DirAccess.rename_absolute(tmp, abs_target)


static func _read(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var text := FileAccess.get_file_as_string(p)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
