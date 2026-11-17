class_name FxWarmup
extends Node
## One-time shader warm-up during the first hole's intro. Effects that only appear later (the aim
## guide and trail, the aim ring, rail sparks, puffs, splashes, confetti, the power meter and the
## big score text) made the renderer compile their shaders on first use: a ~2 s freeze on the
## first drag of a session (seen on the emulator, 2026-11-17). Here every one of them is drawn for
## a few frames - same materials, same vertex formats - but too small or too faint to see, while
## the intro card is up; then the copies are freed. Research: docs/research/Fairway Flick mini golf
## visuals.md ("Stutter, not frame rate, is the hidden polish killer"; plan row 8).

const FRAMES := 4

var _left := FRAMES
var _nodes: Array[Node] = []
var _font: Font
var _font_size := 34


## cam: the play camera (copies ride in front of it, so they are always in view).
## particles: emitters to copy (materials and meshes are shared, so the cache warms).
## vc_material: the material of the ImmediateMesh guide / trail (vertex colours).
## meshes: other late-appearing meshes (copied with their materials).
## labels: big score labels (copied with sample text, nearly transparent).
## hud: the CanvasLayer / Control the power meter draws on; font: its numeral font.
func start(
	cam: Camera3D,
	particles: Array,
	vc_material: Material,
	meshes: Array,
	labels: Array,
	hud: Node,
	font: Font,
) -> void:
	_font = font
	var root := Node3D.new()
	root.position = Vector3(0, 0, -3.0)
	root.scale = Vector3.ONE * 0.001  # sub-pixel, but drawn
	cam.add_child(root)
	_nodes.append(root)
	for p: CPUParticles3D in particles:
		var c := p.duplicate() as CPUParticles3D
		root.add_child(c)
		c.position = Vector3.ZERO
		c.restart()
	var im := ImmediateMesh.new()  # same vertex format as the guide and trail
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector3.ZERO, Vector3.RIGHT, Vector3.UP]:
		im.surface_set_color(Color(1, 1, 1, 0.5))
		im.surface_add_vertex(v)
	im.surface_end()
	var tri := MeshInstance3D.new()
	tri.mesh = im
	tri.material_override = vc_material
	root.add_child(tri)
	for m: MeshInstance3D in meshes:
		var copy := MeshInstance3D.new()
		copy.mesh = m.mesh
		copy.material_override = m.material_override
		root.add_child(copy)
	for l: Label in labels:
		var c2 := l.duplicate() as Label
		c2.text = "HOLE IN ONE! ★☆"
		c2.modulate.a = 0.01
		l.get_parent().add_child(c2)
		_nodes.append(c2)
	var canvas := Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_meter.bind(canvas))
	hud.add_child(canvas)
	_nodes.append(canvas)


func _process(_delta: float) -> void:
	_left -= 1
	if _left > 0:
		return
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	queue_free()


## The power meter's draw calls (line, arcs, numerals), nearly transparent.
func _draw_meter(canvas: Control) -> void:
	var c := Color(1, 1, 1, 0.01)
	var at := Vector2(40, 40)
	canvas.draw_line(at, at + Vector2(20, 20), c, 6.0)
	canvas.draw_arc(at, 70.0, 0.0, TAU, 48, c, 8.0)
	canvas.draw_arc(at, 70.0, 0.0, PI, 48, c, 12.0)
	if _font != null:
		canvas.draw_string(_font, at, "0123456789%", 0, -1, _font_size, c)
