# Cue Club — 8-ball pool vs CPU (Phase 1)

Folder: games/pool/ · rules: .claude/rules/cue-sim.md · build estimate: 4–5 weeks · risk: Medium–High (custom physics)
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 9-10. Visual target: docs/refs/pool/keyframe_1..3.png (+ clip.mp4).

## Physics approach
Custom deterministic solver (shared/cue_sim): balls move in the table plane with 3D spin; fixed 1/240 s substeps; analytic sliding → rolling phases; swept-circle (time-of-impact) collisions so nothing tunnels. Jolt is not used for ball motion; pockets are geometric capture tests.

## Tuning starting points
| Parameter | Value |
|---|---|
| Sliding cloth friction μs | ≈ 0.2 (measured 0.178–0.245) |
| Rolling friction μr | ≈ 0.01–0.016 |
| Rolling deceleration | 5/7 · μr · g |
| Ball–ball restitution | ≈ 0.93 |
| Ball–ball friction | ≈ 0.05–0.06 (gives throw and cut-induced spin) |
| Cushion restitution | start 0.85, tune by feel (published values conflict: 0.82 measured vs 0.98 in one model) |
| Cue tip offset | clamp spin input to 0.5 R (avoids miscues) |
| Balls / table | 57.15 mm, ~170 g; 9-ft playfield 2.54 × 1.27 m |

## Rules and modes
8-ball state machine: open table → groups assigned on first legal pot → fouls (scratch, wrong ball first, no rail) → ball-in-hand → 8-ball win/loss (early 8 = loss).

## CPU opponent
Enumerate (object ball, pocket) pairs → ghost-ball aim → sample N power/spin values → simulate each to rest with the headless solver → score: pot success, cue-ball position value (how many next shots), scratch penalty, safety value. Easy N=8, ±2.5° aim noise, no position play; Medium N=32, ±1.0°; Hard N=128, ±0.3° plus two-ply lookahead. Budget ~150 ms spread across frames behind a 'thinking' camera pan.

## Controls
Drag anywhere to rotate aim (fine-aim slider on the right edge); pull the vertical power bar and release; spin dot on a cue-ball inset for english.

## Camera
Top-down 3/4 by default → lerps low behind the cue during the stroke → follow cam on the fastest ball.

## Tests to write first
- Golden-master break: fixed seed + cue velocity → identical final positions to 1e-6.
- Energy never increases during a shot.
- Straight stop shot leaves the cue ball within 1 cm.
- 10,000 random shots → no ball overlaps.

## Pitfalls
Frame-rate-dependent friction; not sorting multiple collisions inside one substep by time of impact; rule-state bugs (open table, fouls, early 8).

## Scope cut if behind
Ship without spin (centre-ball only) if behind.

## The 10-second moment (what the concept clip shows)
Drag to aim (dotted line + ghost ball), pull the power bar, release. The camera swoops low behind the cue; stripe 11 is cut into the corner pocket (+50), the cue ball draws back to the centre with backspin — 'DRAW SHOT', 'YOUR TURN AGAIN'.

## Open questions
_(fill in during planning)_
