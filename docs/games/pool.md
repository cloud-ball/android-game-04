# Break & Bank — 8-ball pool vs CPU (Phase 1)

Folder: games/pool/ · rules: .claude/rules/cue-sim.md · build estimate: 4–5 weeks · risk: Medium–High (custom physics)
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 9-10. Visual target: docs/refs/pool/keyframe_1..3.png (+ clip.mp4).

## Physics approach
Custom deterministic solver (shared/cue_sim): balls move in the table plane with 3D spin; fixed 1/240 s substeps; closed-form sliding / rolling / spinning / stationary phases (friction never depends on step size); swept-circle (time-of-impact) events in time order, ties by ball index, max 64 per substep. State in PackedFloat64Array (Godot vectors are 32-bit); no sin/cos/exp in the hot path. Jolt is not used for ball motion; pockets are cushions (rails, facings, jaw points) plus a capture circle. Research: docs/research/Cue Club pool game design.md (updated 2026-11-13).

## Tuning starting points
| Parameter | Value |
|---|---|
| Sliding cloth friction μs | 0.20 (measured 0.178–0.245) |
| Rolling friction μr | 0.012 |
| Rolling deceleration | **μr · g = 0.118 m/s²** (was wrongly 5/7 · μr · g: balls rolled 40% too far) |
| Spin (z) deceleration | 10.9 rad/s² |
| Ball–ball restitution | 0.93 |
| Ball–ball friction | 0.055 constant; tangential impulse capped at m·|slip|/7 (throw, no energy gain) |
| Cushions | Han 2005 (pooltool's corrected source), sinθ 0.27, e_c 0.85, μ_c 0.2; ball slides after every rail |
| Cue tip offset | clamp spin input to 0.5 R (avoids miscues); squirt / swerve / massé / jump off |
| Balls / table | 57.15 mm, 170 g; **6-ft bar playfield 1.676 × 0.838 m** (2026-11-14, was 7-ft: balls ~16% bigger on screen; break preset to a light follow, BREAK_TOP 0.15) |
| Pockets | mouths: corner 11.8 cm, side 13.0 cm; facings into the pocket; capture circle |

## Rules and modes
"Casual 8" (WPA 2025 with every option fixed): open table → groups on the first legal pot after the break (both groups → the group hit first) → fouls (scratch, wrong ball first, no ball to a rail after contact, ball off table) → ball in hand anywhere after every foul (break too) → only the 8's pocket is called. 8 on the break is re-spotted. Loss: 8 on a foul, 8 before the group is cleared (cleared state snapshotted at shot start), 8 in the wrong pocket, 8 off the table.

## CPU opponent
Enumerate (object ball, pocket) pairs → prune to 6–10 with an analytic pot probability → ghost-ball aim → simulate ~10 / 40 / 100 variants (Easy / Medium / Hard) at a 1/120 s planning step on worker threads → score pot chance (with its own noise), cue-ball position (next shots 1.0/0.33/0.15), scratch penalty, safety when the best shot < 65%. Gaussian aim noise σ 0.6° / 0.26° / 0.12° (clamped 3σ) plus speed/spin noise; heuristic second ply; 2–3 precomputed breaks. Budget: 1–3 s of visible thinking (150 ms buys only 1–4 rollouts in GDScript).

## Controls
Table long axis vertical, never rotated. Angular drag around the cue ball for coarse aim (last 50–80 ms before lift ignored); fine-aim strip on the LEFT edge (≥ 72 dp, 0.03°/dp); pull-down power bar on the right, v = v_max · p², 8 m/s (12 m/s on the break); spin inset that opens a 200–240 dp panel + Follow/Stun/Draw presets; guideline computed by the solver (shows throw).

## Camera
KEEP_WIDTH, ~22° FOV, pitched 10–15° (top-down 3/4); moves only after release (0.4–0.6 s); damped centroid follow, never the fastest ball; reduce-motion toggle.

## Tests to write first
- Golden-master break: fixed seed + cue velocity → identical final positions to 1e-6 (per-platform golden if trig differs).
- Energy never increases during a shot.
- Stun shot: slides 2v/(7μs g) then rolls at 5/7 v; draw-back speed (2/7)Rω.
- Straight stop shot at ≤ 1.5 m/s leaves the cue ball within 1 cm (e = 0.93 creeps 1.06 cm at 2 m/s).
- 90° rule (e = 1, μ = 0), 30° rule (rolling half-ball hit), outside gearing english ≈ 0 throw.
- Random shots → no ball overlaps; same shot stepped at different rates ends identically.

## Pitfalls
Frame-rate-dependent friction; not sorting multiple collisions inside one substep by time of impact; rule-state bugs (open table, fouls, early 8).

## Scope cut if behind
Ship with vertical spin only (Follow / Stun / Draw) if behind — the 10-second moment is a draw shot.

## The 10-second moment (what the concept clip shows)
Drag to aim (dotted line + ghost ball), pull the power bar, release. The camera swoops low behind the cue; stripe 11 is cut into the corner pocket (+50), the cue ball draws back to the centre with backspin — 'DRAW SHOT', 'YOUR TURN AGAIN'.

## Open questions
_(fill in during planning)_
