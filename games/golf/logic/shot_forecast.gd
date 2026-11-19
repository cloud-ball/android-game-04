class_name ShotForecast
extends RefCounted
## Will this shot drop, and when? Runs a copy of the shot ahead of the real ball, at most
## STEPS_PER_TICK fixed substeps per display tick (10x real time), so the answer never costs a
## frame hitch at release (running the whole shot at once took up to ~45 ms on desktop, more on a
## phone). The same solver and the same steps make the answer exact. Used to time slow motion
## around great hole-outs; pure, unit tested.

const STEPS_PER_TICK := 40  # real play runs PresentationClock.SUBSTEPS_PER_TICK (4) per tick

var ready := false
var hole_at := -1.0  # solver time of the cup drop; -1 if the shot does not drop

var _ball: GolfBall
var _left := 0


## ball: a fresh GolfBall already struck exactly like the real one.
func start(ball: GolfBall) -> void:
	_ball = ball
	ready = false
	hole_at = -1.0
	_left = int(GolfBall.MAX_TIME / GolfFlight.SUBSTEP) + 10  # same hard stop as run_to_rest


## Advance by one display tick's budget; sets `ready` (and `hole_at`) when the copy comes to rest.
func advance() -> void:
	if ready or _ball == null:
		return
	var n := STEPS_PER_TICK
	while n > 0 and _left > 0 and not _ball.done():
		_ball.substep()
		n -= 1
		_left -= 1
	if _ball.done() or _left <= 0:
		ready = true
		hole_at = _ball.time if _ball.phase == GolfBall.Phase.HOLED else -1.0
		_ball = null
