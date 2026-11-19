class_name RushField
extends Node3D
## The CPU golfers of a Rush match (render + flow; rules live in RushMatch, shots in GolfCpu).
## Each rival has its own GolfBall stepped in lockstep with the player's ball (the same number of
## fixed substeps per tick, so "first in the cup" is fair even in slow motion), a ghost ball (no
## collisions) with a floating name tag, and a think timer: it plans on the shared background lane
## (GolfCpuThink) and shoots after a short, seeded pause. Player index 0 is "You"; rivals are 1..3.
## Plan: docs/plans/2026-11-19-fairway-flick-complete.md (step E3).

const NAMES := ["Mira", "Otis", "Kai"]
## Bright, distinct ghost colours (top of the value ladder, like the ball): coral, sky, sunflower.
const COLORS := [Color("#FF7A59"), Color("#5EC8FF"), Color("#FFD84D")]

var rush: RushMatch
var tier: int = GolfCpu.Tier.MEDIUM

var _rng: RandomNumberGenerator
var _hole: HoleData
var _preset: CoursePreset
var _cpu: GolfCpu
var _rivals: Array[_Rival] = []
var _live := false
var _radius := 0.02135


class _Rival:
	extends RefCounted
	var ball: GolfBall
	var at := Vector3.ZERO  # where the next shot starts (ball centre)
	var moving := false
	var think: GolfCpuThink
	var wait := 0.0
	var rng: RandomNumberGenerator
	var mesh: MeshInstance3D
	var tag: Label3D


func setup(rush_match: RushMatch, cpu_tier: int, seed_value: int) -> void:
	rush = rush_match
	tier = cpu_tier
	_rng = Rng.make(seed_value)
	_rivals.clear()
	for k in rush.players() - 1:
		var r := _Rival.new()
		r.rng = Rng.make(seed_value * 31 + 7 * (k + 1))
		_rivals.append(r)


## A new hole: rivals back on the tee, fresh ghosts in `world` (freed with the hole).
func begin_hole(hole: HoleData, spec: Dictionary, preset: CoursePreset, world: Node3D) -> void:
	_hole = hole
	_preset = preset
	_cpu = GolfCpu.new(hole, preset, spec)
	_live = false
	for k in _rivals.size():
		var r := _rivals[k]
		if r.think != null:
			r.think.cancel()
		r.think = null
		r.moving = false
		r.ball = GolfBall.new(hole, preset)
		_radius = r.ball.p.radius
		r.at = hole.tee + Vector3(0, _radius, 0)
		r.mesh = _ghost(world, COLORS[k])
		r.tag = _tag(world, NAMES[k], COLORS[k])


## Rivals start playing (after the hole's intro).
func go() -> void:
	_live = true


func stop() -> void:
	_live = false
	for r in _rivals:
		if r.think != null:
			r.think.cancel()
		r.think = null


## Advances every rival by `n` fixed substeps and settles this tick's drops (the player's, if
## `player_drop` >= 0, is the substep the player's ball fell in). Returns the hole winner decided
## this tick, or -1.
func step(n: int, delta: float, player_drop: int) -> int:
	var drops: Array = []
	if player_drop >= 0:
		drops.append([0, player_drop])
	if _live and rush.hole_winner < 0:
		for k in _rivals.size():
			var sub := _advance(k, n, delta)
			if sub >= 0:
				drops.append([k + 1, sub])
	if drops.is_empty():
		return -1
	return rush.balls_holed(drops)


## "…" while a rival plans or waits, "rolling", or "" (see RushHud).
func thinking(i: int) -> bool:
	if i < 1 or i > _rivals.size():
		return false
	var r := _rivals[i - 1]
	return r.think != null


## Places ghosts and tags each frame; ghosts grow with distance like the player's ball.
func update_visuals(cam_pos: Vector3) -> void:
	for k in _rivals.size():
		var r := _rivals[k]
		if r.mesh == null or not is_instance_valid(r.mesh):
			continue
		var p := r.ball.pos() if r.moving else r.at
		var holed := rush.state[k + 1] == RushMatch.State.HOLED
		var s := clampf(p.distance_to(cam_pos) * 0.006 / _radius, 2.0, 12.0)
		r.mesh.scale = Vector3.ONE * s
		r.mesh.position = p + Vector3(0, _radius * (s - 1.0), 0)
		r.mesh.visible = not holed
		r.tag.position = p + Vector3(0, _radius * (2.0 * s) + 0.12, 0)
		r.tag.visible = not holed
		r.tag.modulate.a = 0.45 if rush.state[k + 1] == RushMatch.State.OUT else 1.0


func _advance(k: int, n: int, delta: float) -> int:
	var r := _rivals[k]
	var i := k + 1
	if r.moving:
		var dropped := -1
		for s in n:
			r.ball.substep()
			if r.ball.done():
				if r.ball.phase == GolfBall.Phase.HOLED:
					dropped = s
				break
		if r.ball.done():
			r.moving = false
			match r.ball.phase:
				GolfBall.Phase.HOLED:
					pass  # settled through the drops of this tick
				GolfBall.Phase.WATER:
					rush.add_penalty(i)
					var q := _hole.water_drop(r.ball.last_safe, _hole.tee)
					r.at = Vector3(q.x, q.y + _radius, q.z)
					rush.ball_rested(i)
				GolfBall.Phase.OUT:
					rush.add_penalty(i)
					rush.ball_rested(i)
				_:
					r.at = r.ball.pos()
					rush.ball_rested(i)
		return dropped
	if not rush.can_shoot(i):
		return -1
	if r.think == null:
		r.think = GolfCpuThink.new(_cpu, r.at, tier, r.rng)
		r.think.start()
		var span: Array = GolfCpu.THINK_S[tier]
		r.wait = r.rng.randf_range(span[0], span[1])
		return -1
	r.wait -= delta
	if r.wait > 0.0 or not r.think.poll():
		return -1
	var v := r.think.shot
	r.think = null
	rush.shot_taken(i)
	r.ball = GolfBall.new(_hole, _preset)
	r.ball.putt(r.at.x, r.at.z, v.x, v.y)
	r.moving = true
	return -1


static func _ghost(world: Node3D, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.02135
	s.height = 0.0427
	s.radial_segments = 16
	s.rings = 8
	mi.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, 0.78)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.35
	m.roughness = 0.4
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	return mi


static func _tag(world: Node3D, text: String, col: Color) -> Label3D:
	var t := Label3D.new()
	t.text = text
	t.font = UiKit.font(800)
	t.font_size = 44
	t.outline_size = 12
	t.outline_modulate = Color(0, 0, 0, 0.7)
	t.modulate = col.lightened(0.15)
	t.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	t.fixed_size = true
	t.pixel_size = 0.0011
	t.no_depth_test = true
	world.add_child(t)
	return t
