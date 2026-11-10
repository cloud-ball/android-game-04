# Park & Pass — Original city driving & parking missions (Phase 3)

Folder: games/drive/ · rules: .claude/rules/drive.md · build estimate: 5–7 weeks · risk: High (vehicle feel + content)
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 23-24. Visual target: docs/refs/drive/keyframe_1..3.png (+ clip.mp4).

## Physics approach
Start with Godot's VehicleBody3D + 4× VehicleWheel3D (raycast vehicle). Plan to move to a custom raycast car (spring-damper per wheel, slip-based lateral grip) if handling feels floaty.

## Tuning starting points
| Parameter | Value |
|---|---|
| Mass | 1200 kg, centre of mass lowered 0.3 m |
| Suspension | stiffness ~40–60, damping ~2–4 compression / 3–5 relaxation (Godot units) |
| Grip | wheel friction slip ~2.5–3.5 for arcade grip |
| Steering | max 0.6 rad, reduced with speed |
| Parking success | within 10° and 0.4 m of the bay, no cones; 3 hits = fail |
| Traffic | Path3D lane splines + IDM-like gap controller; pool 10–20 cars |

## Rules and modes
Mission types: parking, timed delivery through traffic, 'safe driver' (lane + speed limit for 60 s). Ship 10 missions, add more monthly.

## CPU opponent
Traffic cars follow lane splines with a gap controller (accelerate to target speed, brake for the car ahead and for the player); intersections run light timers.

## Controls
Steering wheel or VirtualJoystick (Godot 4.7) on the left; gas + brake on the right; D/R gear toggle; optional tilt steering.

## Camera
Chase cam with velocity look-ahead; top-down parking-assist cam.

## Tests to write first
- Mission detector: pose tolerances, cone hits.
- Traffic never overlaps in a 5-minute headless soak.
- Handling regression: 0–50 km/h time and braking distance within tolerance.

## Pitfalls
Wheel jitter at low speed (sleep threshold, clamp tiny forces); tunnelling through thin barriers (thick colliders); frame-rate-dependent steering.

## Scope cut if behind
Parking-only missions (no traffic) at first.

## The 10-second moment (what the concept clip shows)
Chase cam: the red car overtakes a slow car, stops at a red light while cross traffic passes, pulls away on green. Parking assist: reverse gear, the car swings back between the cones into bay C4 — 'PARKED! ★★★'.

## Open questions
_(fill in during planning)_
