# Carrom Corner — Carrom vs CPU (Phase 2)

Folder: games/carrom/ · rules: .claude/rules/cue-sim.md · build estimate: 2.5–3 weeks (after pool) · risk: Medium (reuses pool core)
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 17-18. Visual target: docs/refs/carrom/keyframe_1..3.png (+ clip.mp4).

## Physics approach
Reuses shared/cue_sim in 'disc mode': discs slide and don't roll (kinetic friction only), small yaw spin for visuals.

## Tuning starting points
| Parameter | Value |
|---|---|
| Disc–board friction μk | ≈ 0.08–0.12 (powdered board) |
| Disc–disc restitution | ≈ 0.75–0.85 |
| Rail restitution | ≈ 0.6–0.7 |
| Masses | striker ~15 g, coins ~5.5 g (≈2.7×) |
| Sizes | 74 cm playing surface, 4.45 cm pockets, 41.3 mm striker, 31.8 mm coins |

## Rules and modes
Turn order, queen + 'cover' rule, fouls (striker pocketed, coin returned), baseline striker-placement validation.

## CPU opponent
Same simulation search as pool; candidate shots = direct, single rail rebound and cuts; difficulty by noise and sample count.

## Controls
Slide the striker along the baseline (horizontal drag), drag back from it to aim and set power (slingshot), release to flick.

## Camera
Fixed top-down, rotated so your baseline is at the bottom, ~15° tilt for depth.

## Tests to write first
- Disc-mode golden master (no rolling phase).
- Striker placement always inside the baseline.
- Queen/cover rule cases.

## Pitfalls
Disc stacking jitter if you use a rigid-body engine instead of the shared solver.

## Scope cut if behind
No 'thumb' cut shots for the AI in v1.

## The 10-second moment (what the concept clip shows)
The striker slides along the baseline, a slingshot pull aims it, and it cracks into the queen, which drops into the corner — 'QUEEN POCKETED'. Next shot a white coin covers her — 'QUEEN COVERED! +50'.

## Open questions
_(fill in during planning)_
