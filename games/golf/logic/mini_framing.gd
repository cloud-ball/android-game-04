class_name MiniFraming
extends RefCounted
## Where the backdrop goes so the portrait play camera actually sees it (render planning, pure).
## The play camera sits behind the ball and looks along the aim, so the landmark goes straight
## ahead of the tee view, past the far end of the course: it lands in the top third of the frame
## on the first shot and in the intro fly-over. Trees and props keep clear of play so they never
## stand between the camera and the ball.
## Research: docs/research/Fairway Flick mini golf visuals.md ("Reviewers reward themed places");
## plan: docs/plans/2026-11-15-fairway-flick-landmark.md.

const LANDMARK_BEYOND := 30.0  # metres past the far edge of the course, on the tee view line
const LANDMARK_SIDE := 3.0  # sideways, away from the cup, so it never hides the flag
const TREE_CLEAR := 6.0  # trees stay at least this far from any course cell


## The tee view: the first aim, along the flow field (round corners), flattened to x/z.
static func tee_view(spec: Dictionary, hole: HoleData) -> Vector2:
	var d := MiniBaker.flow_dir(spec, hole.pin, hole.tee)
	return Vector2(d.x, d.z).normalized()


## Ground spot (x, z) for the landmark.
static func landmark_spot(hole: HoleData, view: Vector2) -> Vector2:
	var tee := Vector2(hole.tee.x, hole.tee.z)
	var d := view.normalized()
	var far := 0.0
	var w := hole.walls
	for o in range(0, w.size(), 2):
		far = maxf(far, (Vector2(w[o], w[o + 1]) - tee).dot(d))
	var side := Vector2(-d.y, d.x)
	var cup := Vector2(hole.pin.x, hole.pin.z)
	var away := -1.0 if (cup - tee).dot(side) > 0.0 else 1.0
	return tee + d * (far + LANDMARK_BEYOND) + side * away * LANDMARK_SIDE


## Where the shadow of a tree crown `height` metres up falls, for a sun at pitch / yaw (degrees,
## as on the DirectionalLight3D). Trees whose shadow would land on the course are left out.
static func shadow_spot(x: float, z: float, height: float, pitch: float, yaw: float) -> Vector2:
	var fwd := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0)) * Vector3.FORWARD
	var flat := Vector2(fwd.x, fwd.z)
	return Vector2(x, z) + flat / maxf(-fwd.y, 0.2) * height


## True when nothing within `r` metres of (x, z) is course (centre, two rings of 12 samples).
static func clear_of_course(hole: HoleData, x: float, z: float, r: float) -> bool:
	if hole.surface_at(x, z) != HoleData.Surface.OUT:
		return false
	for ring in [0.5, 1.0]:
		for k in 12:
			var a := TAU * k / 12.0
			var rr: float = r * ring
			if hole.surface_at(x + cos(a) * rr, z + sin(a) * rr) != HoleData.Surface.OUT:
				return false
	return true
