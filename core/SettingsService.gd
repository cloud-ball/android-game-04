extends Node
## Player settings stored in the save file's "settings" section.

signal changed(key: String, value: Variant)

const DEFAULTS := {"sound": true, "haptics": true}


func get_value(key: String) -> Variant:
	var s: Dictionary = SaveService.data["settings"]
	return s.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	SaveService.data["settings"][key] = value
	SaveService.save()
	changed.emit(key, value)


func sound_on() -> bool:
	return bool(get_value("sound"))


func haptics_on() -> bool:
	return bool(get_value("haptics"))
