class_name KitBatch
extends RefCounted
## Static CC0 props, batched: every placed model is merged into ONE mesh with one surface per kit
## material name, recoloured by GolfTheme.kit_color. A hundred flowers cost the same draw calls as
## one (research: "Import settings and draw-call discipline"). Build-time only, never per frame.
## Models: games/golf/assets/kenney_nature/*.glb (Kenney Nature Kit, CC0; see ASSETS.md).

const DIR := "res://games/golf/assets/kenney_nature/"

static var _parts := {}  # model name -> Array of [material name, Mesh, surface index, Transform3D]
static var _heights := {}  # model name -> height in model units

var _tools := {}  # material name -> SurfaceTool


## Model height in its own units (to scale a prop to a size in metres).
static func height(model: String) -> float:
	_load(model)
	return _heights[model]


## Place `model` (file name without .glb) with transform `xform` (world space).
func add(model: String, xform: Transform3D) -> void:
	_load(model)
	for part: Array in _parts[model]:
		var name: String = part[0]
		if not _tools.has(name):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_tools[name] = st
		(_tools[name] as SurfaceTool).append_from(
			part[1], part[2], xform * (part[3] as Transform3D)
		)


func is_empty() -> bool:
	return _tools.is_empty()


## Commit everything as one MeshInstance3D under `parent`.
func build(parent: Node3D, theme: GolfTheme, shadows := true) -> MeshInstance3D:
	if _tools.is_empty():
		return null
	var mesh := ArrayMesh.new()
	var names := _tools.keys()
	names.sort()
	for name: String in names:
		(_tools[name] as SurfaceTool).commit(mesh)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = theme.kit_color(name)
		mat.roughness = 0.9
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP  # same soft look as the carpet
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_tools.clear()
	return mi


static func _load(model: String) -> void:
	if _parts.has(model):
		return
	var scene := load(DIR + model + ".glb") as PackedScene
	var root := scene.instantiate()
	var parts: Array = []
	var top := -INF
	var bottom := INF
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var x := Transform3D.IDENTITY
		var n: Node = mi
		while n != root:
			x = (n as Node3D).transform * x
			n = n.get_parent()
		var m := mi.mesh
		for i in m.get_surface_count():
			var mat := m.surface_get_material(i)
			var name: String = mat.resource_name if mat != null else m.surface_get_name(i)
			parts.append([name, m, i, x])
		var box := x * m.get_aabb()
		top = maxf(top, box.end.y)
		bottom = minf(bottom, box.position.y)
	root.free()
	_parts[model] = parts
	_heights[model] = top - bottom
