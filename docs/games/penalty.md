# Top Corner — Penalty shootout vs CPU (Phase 2)

Folder: games/penalty/ · rules: .claude/rules/penalty.md · build estimate: 2–3 weeks · risk: Medium
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 19-20. Visual target: docs/refs/penalty/keyframe_1..3.png (+ clip.mp4).

## Physics approach
Custom flight integrator (as for golf) for drag + Magnus; after any contact (post, keeper, net) the ball becomes a Jolt RigidBody3D. Net = a few low-restitution StaticBody3D panels, or a vertex shader for visual flex.

## Tuning starting points
| Parameter | Value |
|---|---|
| Ball | 0.22 m, ~0.43 kg |
| Drag crisis | blend Cd 0.45 → 0.2 across ~15–20 m/s (critical Re 2.2–3.0×10⁵) |
| Magnus side force | coefficient ~0.2–0.3; exaggerate ~1.5× for fun |
| Keeper reaction | Easy 320 ms · Medium 220 ms · Hard 150 ms |
| Keeper reach | 2.6–3.2 m dive; error ±0.5 / 0.3 / 0.15 m |
| Hard mode | pre-commits ('guesses early') 30% of the time |

## Rules and modes
You shoot five, then keep five (swipe to dive), then sudden death. Free-kick-with-wall challenge as a later add-on.

## CPU opponent
Keeper state machine Idle → Read (reaction delay) → Commit dive → Recover; predicts the crossing point each frame with the same integrator. CPU striker picks corners with a weighted random + your recent dive history.

## Controls
Swipe from the ball: direction = aim, length/time = power, curvature (quadratic fit of the touch points) = curl. Keeping: swipe to dive.

## Camera
Broadcast angle behind the shooter; elevated behind-the-goal view when keeping.

## Tests to write first
- Integrator: a straight swipe produces no lateral drift.
- Keeper difficulty table matches spec (reaction/reach).
- Swipe-curve fit on recorded touch fixtures.

## Pitfalls
Frame-rate-dependent integration; keeper that is perfect (always add reaction delay and reach error).

## Scope cut if behind
Shooting only (no keeping) in the first update.

## The 10-second moment (what the concept clip shows)
A curved swipe bends the ball around the keeper's full-stretch dive into the top corner; slow-motion net ripple — 'GOAL!'. Then you keep: swipe to dive, fingertips push the CPU's shot onto the post — 'SAVED!'.

## Open questions
_(fill in during planning)_
