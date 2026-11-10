# Fairway Flick — Golf vs CPU (Phase 3)

Folder: games/golf/ · rules: .claude/rules/golf.md · build estimate: 4–5 weeks · risk: High (flight + terrain)
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 21-22. Visual target: docs/refs/golf/keyframe_1..3.png (+ clip.mp4).

## Physics approach
Flight = custom RK4 integrator at 240 Hz for drag and Magnus lift; hand off to a Jolt RigidBody3D (CCD on) or a custom roll model on landing.

## Tuning starting points
| Parameter | Value |
|---|---|
| Ball | 42.67 mm, 45.93 g |
| Drag | F = ½ρ·Cd·A·v², Cd ≈ 0.27 low spin → ~0.32 when spin ratio S > 0.1 |
| Lift | Cl ≈ 0.54·S^0.4, clamped to 0.25 (S = ωr/V) |
| Spin decay | ~4% per second |
| Green | rolling decel ~0.6–0.9 m/s² + g·sin(slope) along the fall line |
| Cup capture | drops if centre over the cup and speed < ~1.3 m/s, else lip-out |

## Rules and modes
Nine compact holes built from modular tiles; stroke play vs a CPU rival; wind as a constant velocity offset in the drag term.

## CPU opponent
Grid search over club/power/aim using simulated shots toward a target landing zone, plus skill noise per difficulty.

## Controls
Swipe-back-and-flick swing (speed = power, sideways deviation = hook/slice) or a two-tap meter; drag the aim arrow; spin dot for back/top spin.

## Camera
Behind-ball aim cam → launch follow cam → landing cam; top-down 'green read' with a slope grid.

## Tests to write first
- Integrator: no-spin, no-wind shot is symmetric.
- Carry distance per club within ±3% of the table.
- Ball comes to rest on slopes (sleep threshold).

## Pitfalls
Tunnelling into thin terrain at 70 m/s (CCD + swept raycast); jitter at rest on slopes (force sleep below a velocity threshold).

## Scope cut if behind
Ship as mini-golf (rolling only, no flight model).

## The 10-second moment (what the concept clip shows)
Swipe-swing from behind the ball; the shot climbs with a white trail, fades right in the wind, lands on the green, checks with backspin and curls along the slope grid into the cup — 'BIRDIE!'.

## Open questions
_(fill in during planning)_
