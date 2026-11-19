class_name BlocksView
extends Node3D
## 3D crystal tower for Facetfall. Reads a BlocksState every frame and draws it; never owns game
## state. Design notes: docs/research/Facetfall board redesign.md.
## - Orthographic camera locked to the canvas width, pitched 9 deg: 1 world unit = 1 cell =
##   BoardLayout.cell canvas units, identical at the top and bottom of the tower.
## - Cut-gem slabs (0.93 x 0.93 face, 0.55 deep): a table facet, four lit bevels and a glyph per
##   shard, shaded in the shader (no lights), in a jewel palette on a lightness ladder; the back
##   pane is tinted crystal without a grid (originality review 2026-11-17).
## - A pedestal sized to fit inside the side margins, with a soft contact shadow.

## Jewel palette, deliberately unlike the classic falling-block colour scheme (no shard keeps the
## classic colour of its shape), on a lightness ladder ~8 L* apart so shards stay distinct in
## greyscale and for colour-blind players; each shard also carries its own glyph.
## Index = shard kind A..G. Originality review 2026-11-17 (docs/store/SHIP_CHECKLIST.md).
const GEM_COLORS: Array[Color] = [
	Color("#8E2340"),  # A long   - garnet      (L* 33)  glyph: bar
	Color("#2F55C4"),  # B square - sapphire    (L* 40)  glyph: dot
	Color("#178060"),  # C tee    - emerald     (L* 48)  glyph: chevron
	Color("#9A6BE0"),  # D skew   - amethyst    (L* 55)  glyph: cross
	Color("#D9799E"),  # E skew   - rose quartz (L* 62)  glyph: diagonal
	Color("#E2A840"),  # F hook   - topaz       (L* 73)  glyph: ring
	Color("#9FE6DC"),  # G hook   - aquamarine  (L* 87)  glyph: diamond
]
const GARBAGE_COLOR := Color("#4A5068")
const GLYPH_GARBAGE := 7
const FACE := 0.93
const DEPTH := 0.55
const PITCH_DEG := 9.0
const SWAY_DEG := 4.0  # slow turn of the tower: its crystal sides catch the light
const CAMERA_DISTANCE := 60.0

const GEM_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
varying vec3 lp;
varying float glyph;
varying float lift;
void vertex() {
	lp = VERTEX;
	glyph = INSTANCE_CUSTOM.r * 8.0;
	lift = INSTANCE_CUSTOM.g;
}
float glyph_mask(int g, vec2 p) {
	float r = length(p);
	if (g == 0) { return step(abs(p.y), 0.15) * step(abs(p.x), 0.6); }
	if (g == 1) { return 1.0 - smoothstep(0.24, 0.3, r); }
	if (g == 2) {
		float d = abs(p.x) * 0.85 + p.y;
		return step(abs(d - 0.12), 0.13) * step(abs(p.x), 0.56);
	}
	if (g == 3) {
		float v = step(abs(p.x), 0.12) * step(abs(p.y), 0.52);
		return max(v, step(abs(p.y), 0.12) * step(abs(p.x), 0.52));
	}
	if (g == 4) { return step(abs(p.x + p.y), 0.17) * step(r, 0.72); }
	if (g == 5) { return step(abs(r - 0.4), 0.1); }
	if (g == 6) { return step(abs(abs(p.x) + abs(p.y) - 0.46), 0.1); }
	return step(0.5, fract((p.x - p.y) * 2.2));
}
void fragment() {
	vec3 a = abs(lp) * 2.0;
	vec3 base = COLOR.rgb;
	vec3 col;
	if (a.z >= a.x && a.z >= a.y) {
		// Front face cut like a gem: a flat table in the middle and four bevel facets, lit from
		// the top left (top facet brightest, bottom darkest), dark seams between facets, a
		// sparkle on the table and the shard's glyph etched into it.
		vec2 f = lp.xy * 2.0;
		vec2 af = abs(f);
		float table = 0.56;
		float m = max(af.x, af.y);
		float k;
		if (m < table) {
			k = 1.02 + 0.12 * (f.y - f.x) * 0.5;
		} else if (af.y >= af.x) {
			k = f.y > 0.0 ? 1.42 : 0.58;
		} else {
			k = f.x < 0.0 ? 1.16 : 0.78;
		}
		// Emerald cut: chamfered corners on the table and on the outline (an octagon, not a tile).
		float dia = af.x + af.y;
		float seam = 1.0 - smoothstep(0.0, 0.05, abs(m - table));
		seam = max(seam, (1.0 - smoothstep(0.0, 0.05, abs(af.x - af.y))) * step(table, m));
		seam = max(seam, smoothstep(0.9, 0.98, m));
		float chamfer = 1.0 - smoothstep(0.0, 0.05, abs(dia - table * 1.55));
		seam = max(seam, chamfer * step(dia, table * 1.6) * step(table * 0.75, m));
		float cut = smoothstep(1.48, 1.56, dia);  // outside the octagon: the dark setting
		float glint = (1.0 - smoothstep(0.0, 0.16, length(f - vec2(-0.28, 0.3)))) * 0.55;
		float g = glyph_mask(int(glyph + 0.5), f / table * 0.62) * step(m, table - 0.06);
		col = base * k * mix(0.9, 1.08, f.y * 0.5 + 0.5);
		col = mix(col, col * 0.72, g);
		col = mix(col, base * 0.35, seam * 0.85);
		col += vec3(glint);
		col = mix(col, base * 0.22, cut);
	} else if (a.y >= a.x) {
		col = base * (lp.y > 0.0 ? 1.18 : 0.55);  // top face catches light, underside is dark
	} else {
		col = base * 0.68;  // side faces
	}
	ALBEDO = col * (1.0 + 0.12 * lift);
}
"""

const GHOST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;
varying vec3 lp;
void vertex() {
	lp = VERTEX;
}
void fragment() {
	vec3 a = abs(lp) * 2.0;
	float mid = max(min(a.x, a.y), min(max(a.x, a.y), a.z));
	float edge = smoothstep(0.84, 0.94, mid);
	ALBEDO = COLOR.rgb;
	ALPHA = 0.08 + 0.75 * edge;
}
"""

const PANE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec2 cells = vec2(12.0, 24.0);
uniform vec3 pane : source_color = vec3(0.06, 0.09, 0.17);
uniform vec3 glint : source_color = vec3(0.32, 0.42, 0.62);
void fragment() {
	// The back of a crystal tower: deep tinted glass, no grid. Two soft diagonal reflections and
	// frosted edges give it depth; the landing preview shows where a shard will go.
	float shade = mix(0.8, 1.12, 1.0 - UV.y);
	vec3 c = pane * shade;
	float diag = UV.x * 0.55 + UV.y;
	float band = smoothstep(0.06, 0.0, abs(fract(diag * 0.9) - 0.32)) * 0.22;
	band += smoothstep(0.025, 0.0, abs(fract(diag * 0.9 + 0.17) - 0.32)) * 0.14;
	float edge = smoothstep(0.08, 0.0, min(UV.x, 1.0 - UV.x)) * 0.35;
	ALBEDO = c + glint * (band + edge);
}
"""

const SOLID_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform vec3 top_color : source_color;
uniform vec3 side_color : source_color;
uniform float rim = 0.0;
varying vec3 wn;
varying vec3 lp;
void vertex() {
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	lp = VERTEX;
}
void fragment() {
	float up = smoothstep(0.6, 0.9, wn.y);
	vec3 c = mix(side_color, top_color, up);
	c *= 1.0 + rim * smoothstep(0.17, 0.25, lp.y) * (1.0 - up);
	ALBEDO = c;
}
"""

const SHADOW_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float strength = 0.5;
void fragment() {
	float r = length((UV - 0.5) * 2.0);
	ALBEDO = vec3(0.0);
	ALPHA = strength * (1.0 - smoothstep(0.15, 1.0, r));
}
"""

var camera: Camera3D
var layout: BoardLayout

var _locked: MultiMesh
var _active: MultiMesh
var _ghost: MultiMesh
var _burst_pool: Array[CPUParticles3D] = []
var _next_burst := 0
var _flash_rows: Array[MeshInstance3D] = []
var _garbage_bar: MeshInstance3D
var _garbage_mat: ShaderMaterial
var _cam_base := Transform3D()
var _pivot := Vector3.ZERO
var _time := 0.0
var _shake := 0.0
var _active_visual := Vector2.ZERO
var _active_key := ""


func setup(board_layout: BoardLayout) -> void:
	layout = board_layout
	_add_environment()
	_add_tower()
	var gem := _material(GEM_SHADER)
	_locked = _multimesh(BlocksState.W * BlocksState.H, gem, true)
	_active = _multimesh(4, gem, true)
	_ghost = _multimesh(4, _material(GHOST_SHADER), false)
	for i in 4:
		var flash := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(BlocksState.W, 1.0, DEPTH + 0.1)
		flash.mesh = box
		flash.material_override = _flat(Color(1, 1, 1), 2.2)
		flash.visible = false
		add_child(flash)
		_flash_rows.append(flash)
	for i in 4:
		_burst_pool.append(_make_burst())
	_garbage_bar = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(1, 1, 0.3)
	_garbage_bar.mesh = bar
	_garbage_mat = _flat(Color(1.0, 0.8, 0.25), 1.0)
	_garbage_bar.material_override = _garbage_mat
	_garbage_bar.visible = false
	add_child(_garbage_bar)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.near = 1.0
	camera.far = 200.0
	add_child(camera)
	camera.make_current()
	apply_layout(board_layout)


## Re-aims the camera for a (new) layout: no fitting search, just the layout's numbers.
func apply_layout(board_layout: BoardLayout) -> void:
	layout = board_layout
	camera.size = layout.canvas.x / layout.cell
	_cam_base = camera_transform(layout)
	_pivot = Vector3(0, (BlocksState.H - BlocksState.HIDDEN) * 0.5, 0)
	camera.transform = _cam_base


## Orthographic camera transform that maps the well centre to the layout's well centre.
static func camera_transform(l: BoardLayout) -> Transform3D:
	var pitch := deg_to_rad(PITCH_DEG)
	var fwd := Vector3(0, -sin(pitch), -cos(pitch))
	var up := Vector3(0, cos(pitch), -sin(pitch))
	var centre := Vector3(0, (BlocksState.H - BlocksState.HIDDEN) * 0.5, 0)
	# Canvas y grows downwards; shift so the well centre lands on the layout's well centre.
	var m := (l.canvas.y * 0.5 - l.well.get_center().y) / l.cell
	var pos := centre - fwd * CAMERA_DISTANCE - up * m
	return Transform3D(Basis.looking_at(fwd, up), pos)


## World centre of board cell (x, y); row 0 is the top hidden row, the floor is at y = 0.
static func cell_pos(x: float, y: float) -> Vector3:
	return Vector3(x - (BlocksState.W - 1) * 0.5, (BlocksState.H - 1 - y) + 0.5, 0.0)


func render(s: BlocksState, delta: float) -> void:
	_time += delta
	var n := 0
	for y in range(BlocksState.HIDDEN, BlocksState.H):
		for x in BlocksState.W:
			var v := s.board[y * BlocksState.W + x]
			if v == 0:
				continue
			_put(_locked, n, cell_pos(x, y), v, 0.0)
			n += 1
	_locked.visible_instance_count = n
	_render_active(s, delta)
	_render_garbage(s.pending_garbage)
	var sway := sin(_time * 0.3) * deg_to_rad(SWAY_DEG)
	var rot := Transform3D(Basis(Vector3.UP, sway), Vector3.ZERO)
	var t := Transform3D(Basis(), _pivot) * rot * Transform3D(Basis(), -_pivot) * _cam_base
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 3.0)
		t = t.translated_local(Vector3(sin(_time * 61.0), cos(_time * 53.0), 0) * _shake * 0.08)
	camera.transform = t


func _put(mm: MultiMesh, i: int, p: Vector3, value: int, lift: float) -> void:
	mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(FACE, FACE, DEPTH)), p))
	var garbage := value == BlocksState.GARBAGE
	# Instance colours reach the shader as-is; the palette is sRGB, ALBEDO expects linear.
	var col := GARBAGE_COLOR if garbage else GEM_COLORS[value - 1]
	mm.set_instance_color(i, col.srgb_to_linear())
	var glyph := GLYPH_GARBAGE if garbage else value - 1
	mm.set_instance_custom_data(i, Color(glyph / 8.0, lift, 0, 0))


func _render_active(s: BlocksState, delta: float) -> void:
	if s.kind < 0 or s.over:
		_active.visible_instance_count = 0
		_ghost.visible_instance_count = 0
		return
	var key := "%d/%d/%d" % [s.kind, s.pieces, int(s.can_hold)]
	var target := Vector2(s.px, s.py)
	if key != _active_key or _active_visual.distance_to(target) > 3.0:
		_active_visual = target
		_active_key = key
	else:
		_active_visual = _active_visual.lerp(target, 1.0 - exp(-delta * 28.0))
	var cells := ShardData.cells(s.kind, s.rot)
	var gy := BlocksLogic.ghost_y(s)
	var shown := 0
	var ghosts := 0
	for c in cells:
		var cy: float = _active_visual.y + c.y
		if cy >= BlocksState.HIDDEN - 0.5:
			_put(_active, shown, cell_pos(_active_visual.x + c.x, cy), s.kind + 1, 1.0)
			shown += 1
		if gy > s.py and gy + c.y >= BlocksState.HIDDEN:
			var gp := cell_pos(s.px + c.x, gy + c.y)
			_ghost.set_instance_transform(
				ghosts, Transform3D(Basis.from_scale(Vector3(FACE, FACE, DEPTH)), gp)
			)
			_ghost.set_instance_color(ghosts, GEM_COLORS[s.kind].lightened(0.35).srgb_to_linear())
			ghosts += 1
	_active.visible_instance_count = shown
	_ghost.visible_instance_count = ghosts


## Pending garbage: a meter flush against the well's left edge, yellow -> orange -> red.
func _render_garbage(pending: int) -> void:
	_garbage_bar.visible = pending > 0
	if pending <= 0:
		return
	var h := float(mini(pending, BlocksState.H - BlocksState.HIDDEN))
	var x := (layout.garbage.get_center().x - layout.canvas.x * 0.5) / layout.cell
	var w := layout.garbage.size.x / layout.cell
	_garbage_bar.scale = Vector3(w, h, 1)
	_garbage_bar.position = Vector3(x, h * 0.5, 0.1)
	var col := Color(1.0, 0.82, 0.25)
	if pending > 4:
		col = Color(1.0, 0.25, 0.25)
	elif pending > 2:
		col = Color(1.0, 0.55, 0.15)
	var pulse := 1.0 + 0.25 * sin(_time * (6.0 if pending > 4 else 3.0))
	_garbage_mat.set_shader_parameter("c", col)
	_garbage_mat.set_shader_parameter("e", pulse)


## Rows that were just cleared: flash them, then shatter into crystal fragments.
func clear_fx(rows: PackedInt32Array) -> void:
	for i in mini(rows.size(), _flash_rows.size()):
		var f := _flash_rows[i]
		f.position = cell_pos((BlocksState.W - 1) * 0.5, rows[i])
		f.visible = true
		f.scale = Vector3.ONE
		var tw := f.create_tween()
		tw.tween_property(f, "scale", Vector3(1.02, 0.15, 1.0), 0.18)
		tw.tween_callback(func() -> void: f.visible = false)
		var b := _burst_pool[_next_burst]
		_next_burst = (_next_burst + 1) % _burst_pool.size()
		b.position = f.position
		b.restart()
		b.emitting = true
	_shake = 0.3 + 0.12 * rows.size()


func hard_drop_fx() -> void:
	_shake = maxf(_shake, 0.2)


func _multimesh(count: int, mat: Material, custom: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = custom
	mm.mesh = BoxMesh.new()
	mm.instance_count = count
	mm.visible_instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return mm


func _add_environment() -> void:
	# Orthographic rays are parallel, so a sky would render as one flat colour: draw the
	# background as a 2D gradient on a canvas layer behind the 3D view instead.
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = -1
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR  # unshaded palette stays exact
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.15  # resting gems never bloom; clear flashes do
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	back.add_child(_gradient_rect([Color("#2B1D4A"), Color("#171431"), Color("#0B0A17")], false))
	var front := CanvasLayer.new()
	front.layer = 1
	add_child(front)
	front.add_child(
		_gradient_rect([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.22)], true)
	)


static func _gradient_rect(colors: Array, radial: bool) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray(colors)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 256
	if radial:
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.48)
		tex.fill_to = Vector2(1.15, 1.1)
	else:
		tex.fill_from = Vector2(0.5, 0.0)
		tex.fill_to = Vector2(0.5, 1.0)
	var r := TextureRect.new()
	r.texture = tex
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _add_tower() -> void:
	var w := float(BlocksState.W)
	var h := float(BlocksState.H - BlocksState.HIDDEN)
	var pane := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	pane.mesh = quad
	var pane_mat := _material(PANE_SHADER)
	pane_mat.set_shader_parameter("cells", Vector2(w, h))
	pane.material_override = pane_mat
	pane.position = Vector3(0, h * 0.5, -DEPTH * 0.5 - 0.04)
	add_child(pane)
	var frame := _solid(Color("#C9C4F0"), Color("#8E88C2"), 0.0)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.12, h + 0.12, 0.7), Vector3(sx * (w * 0.5 + 0.08), h * 0.5, 0), frame)
	_box(Vector3(w + 0.28, 0.08, 0.7), Vector3(0, h + 0.04, 0), frame)
	# Sill under the well, then a visible gap, then the pedestal (a hex flattened in depth).
	var sill := _solid(Color("#5B5394"), Color("#3B3566"), 0.0)
	_box(Vector3(w + 0.5, 0.16, 0.9), Vector3(0, -0.08, 0), sill)
	var holder := Node3D.new()
	holder.scale = Vector3(1, 1, 0.33)
	holder.position = Vector3(0, -0.47, 0)
	add_child(holder)
	var hex := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = BoardLayout.PEDESTAL_SPAN * 0.5 - 0.25
	cyl.bottom_radius = BoardLayout.PEDESTAL_SPAN * 0.5
	cyl.height = 0.5
	cyl.radial_segments = 6
	cyl.rings = 1
	hex.mesh = cyl
	hex.rotation.y = PI / 6.0  # corners point along +-X
	hex.material_override = _solid(Color("#2E2850"), Color("#1A1630"), 0.35)
	holder.add_child(hex)
	var shadow := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(13.5, 4.2)
	shadow.mesh = sq
	shadow.rotation.x = -PI / 2.0
	shadow.position = Vector3(0, -0.73, 0)
	shadow.material_override = _material(SHADOW_SHADER)
	add_child(shadow)


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	m.position = pos
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)


func _make_burst() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(BlocksState.W * 0.5, 0.35, 0.2)
	var shard := PrismMesh.new()
	shard.size = Vector3(0.18, 0.24, 0.08)
	p.mesh = shard
	p.direction = Vector3(0, 1, 0.6)
	p.spread = 70.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0, -12.0, 0)
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.17, 0.34, 0.5, 0.67, 0.84])
	ramp.colors = PackedColorArray(
		[GEM_COLORS[0], GEM_COLORS[1], GEM_COLORS[2], GEM_COLORS[3], GEM_COLORS[5], GEM_COLORS[6]]
	)
	p.color_initial_ramp = ramp
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	p.material_override = mat
	add_child(p)
	return p


static func _material(code: String) -> ShaderMaterial:
	var s := Shader.new()
	s.code = code
	var m := ShaderMaterial.new()
	m.shader = s
	return m


static func _solid(top: Color, side: Color, rim: float) -> ShaderMaterial:
	var m := _material(SOLID_SHADER)
	m.set_shader_parameter("top_color", top)
	m.set_shader_parameter("side_color", side)
	m.set_shader_parameter("rim", rim)
	return m


static func _flat(color: Color, energy: float) -> ShaderMaterial:
	var m := _material(
		(
			"shader_type spatial;\nrender_mode unshaded;\nuniform vec3 c : source_color;\n"
			+ "uniform float e = 1.0;\nvoid fragment() { ALBEDO = c * e; }\n"
		)
	)
	m.set_shader_parameter("c", color)
	m.set_shader_parameter("e", energy)
	return m
