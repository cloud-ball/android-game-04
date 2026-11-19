class_name KitBatch
extends RefCounted
## Static CC0 props, batched: every placed model is merged into ONE mesh with one surface per kit
## material name, recoloured by GolfTheme.kit_color. A hundred flowers cost the same draw calls as
## one (research: "Import settings and draw-call discipline"). Build-time only, never per frame.
## Models are de-indexed once at load, so placing one is a few native packed-array operations.
## Each vertex carries a sway weight in COLOR.r (its height within the model, 0..1; 0 for props
## placed with sway off); surfaces in SWAY move in the wind via AmbientLife.FOLIAGE_SHADER.
## Models: games/golf/assets/kenney_nature/*.glb (Kenney Nature Kit, CC0; see ASSETS.md).
## Plan: docs/plans/2026-11-15-cup-dash-ambient.md.

const DIR := "res://games/golf/assets/kenney_nature/"
## Kit material name -> sway at full weight (metres): leaves and soft plants only.
const SWAY := {
	"leafsGreen": 0.22,
	"leafsDark": 0.16,
	"grass": 0.05,
	"colorRed": 0.05,
	"colorYellow": 0.05,
	"colorPurple": 0.05,
}

## model -> Array of Dictionary {name, v, n, w (sway weights), z (zeros)}
static var _parts := {}
static var _heights := {}  # model name -> height in model units

var _acc := {}  # material name -> Array of [verts, normals, colours] chunks


## Model height in its own units (to scale a prop to a size in metres).
static func height(model: String) -> float:
	_load(model)
	return _heights[model]


## Every vertex's sway weight for `model` (all parts in order), for tests.
static func weights(model: String) -> PackedFloat32Array:
	_load(model)
	var out := PackedFloat32Array()
	for part: Dictionary in _parts[model]:
		for c in part.w as PackedColorArray:
			out.append(c.r)
	return out


## Place `model` (file name without .glb) with transform `xform` (world space; uniform scale).
## sway: whether its leaves / petals / blades move in the wind (off for rocks with a moss cap).
func add(model: String, xform: Transform3D, sway := true) -> void:
	_load(model)
	var turn := Transform3D(xform.basis.orthonormalized(), Vector3.ZERO)
	for part: Dictionary in _parts[model]:
		var name: String = part.name
		if not _acc.has(name):
			_acc[name] = []  # chunks of [verts, normals, colours]; joined once in build()
		(_acc[name] as Array).append(
			[
				xform * (part.v as PackedVector3Array),
				turn * (part.n as PackedVector3Array),
				part.w if sway else part.z
			]
		)


func is_empty() -> bool:
	return _acc.is_empty()


## Commit everything as one MeshInstance3D under `parent`.
func build(parent: Node3D, theme: GolfTheme, shadows := true) -> MeshInstance3D:
	if _acc.is_empty():
		return null
	var mesh := ArrayMesh.new()
	var names := _acc.keys()
	names.sort()
	var motion := AmbientLife.motion()
	for name: String in names:
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var c := PackedColorArray()
		for chunk: Array in _acc[name]:
			v.append_array(chunk[0])
			n.append_array(chunk[1])
			c.append_array(chunk[2])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_COLOR] = c
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var col := theme.kit_color(name)
		var mat: Material
		if SWAY.has(name) and motion > 0.0:
			var sm := ShaderMaterial.new()
			sm.shader = AmbientLife.foliage_shader()
			sm.set_shader_parameter("albedo", col)  # Godot converts to linear
			sm.set_shader_parameter("amp", SWAY[name])
			mat = sm
		else:
			var st := StandardMaterial3D.new()
			st.albedo_color = col
			st.roughness = 0.9
			st.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP  # the carpet's soft look
			mat = st
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_acc.clear()
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
		var turn := Transform3D(x.basis.orthonormalized(), Vector3.ZERO)
		for i in m.get_surface_count():
			var mat := m.surface_get_material(i)
			var name: String = mat.resource_name if mat != null else m.surface_get_name(i)
			var arrays := m.surface_get_arrays(i)
			var sv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var sn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var idx: PackedInt32Array = (
				arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			)
			var v := PackedVector3Array()
			var nn := PackedVector3Array()
			if idx.is_empty():
				v = sv
				nn = sn
			else:
				for k in idx:
					v.append(sv[k])
					nn.append(sn[k])
			parts.append({"name": name, "v": x * v, "n": turn * nn})
		var box := x * m.get_aabb()
		top = maxf(top, box.end.y)
		bottom = minf(bottom, box.position.y)
	root.free()
	var tall := maxf(top - bottom, 1e-4)
	for part: Dictionary in parts:
		var w := PackedColorArray()
		var z := PackedColorArray()
		for p in part.v as PackedVector3Array:
			w.append(Color(clampf((p.y - bottom) / tall, 0.0, 1.0), 0, 0))
			z.append(Color(0, 0, 0))
		part.w = w
		part.z = z
	_parts[model] = parts
	_heights[model] = top - bottom
