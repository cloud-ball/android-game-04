# Fairway Flick — Golf vs CPU (Phase 3)

Folder: games/golf/ · rules: .claude/rules/golf.md · build estimate: 4–5 weeks · risk: High (flight + terrain)
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 21-22. Visual target: docs/refs/golf/keyframe_1..3.png (+ clip.mp4).

## Physics approach
Updated 2026-11-14 from docs/research/Fairway Flick golf game design.md: one custom deterministic solver from strike
to rest - RK4 flight (live 4 x 1/240 s substeps), Penner-style bounce with a per-surface tilt, Stimp-calibrated roll,
analytic cup. No Jolt hand-off (no determinism guarantee; the CPU needs cheap cloned rollouts). Real-metre physics;
the course is short by design. Plan: docs/plans/2026-11-14-fairway-flick.md.

## Tuning starting points
| Parameter | Value |
|---|---|
| Ball | 42.67 mm, 45.93 g, rho 1.225 kg/m^3 |
| Drag | Cd = 0.225 + 0.275 x ramp(Re 5e4 -> 1e5) + 0.18 x (1 - e^-3S^2) (was a 0.27 -> 0.32 step: drives ~12% short) |
| Lift | Cl = 1.99S - 3.255S^2 to S = 0.25, then linear (slope 0.3625), no clamp (the old 0.25 clamp flattened irons) |
| Spin decay | ~0.001 per metre travelled (~4%/s), applied as a per-step factor |
| Clubs | Driver ~175 m carry, hybrid ~150, 7-iron ~130, wedge ~95 (partial to 10 m), putter |
| Bounce | soft green e = Penner e(v), mu 0.40, tilt 15 deg; fairway e 0.22, mu 0.5, 16 deg; rough / sand / path tuned by feel |
| Green | a = v0^2 / (2 x Stimp), v0 1.83 m/s (Stimp 10 -> ~0.6 m/s^2) + (5/7) g sin(slope) along the fall line |
| Cup | capture speed falls with offset: 1.31 m/s centred (free fall), up to 1.63 m/s with rim help; lip-out keeps 50-70% |
| Wind | 0-10 m/s per hole (seeded), power-law height profile, zero on a rolling ball |

## Rules and modes
Nine executive-length holes (par 32: 4 x par 3, 4 x par 4, 1 x par 5), authored from tiles and baked to a height grid
plus a surface grid, with a playability validator. Modes: 9-hole stroke play, 3-hole match-play duel, closest-to-pin
tiebreak. Pick up at triple bogey; water / out of bounds +1 stroke.

## CPU opponent
Expected-strokes planner (strokes-gained table) over simulated candidates on a worker thread; Easy / Medium / Hard
execute with high- / mid- / low-handicap error (Broadie 2008). No rubber-banding; targets ~70 / 50 / 30 % player wins.

## Controls
Pull back from the ball and release: pull distance = power, release timing = accuracy, overpower band, tap to cancel
(swipe-speed power is the top consistency complaint in reviews; a flick stays optional). Drag a landing marker to aim;
spin behind a ball-icon panel; moving-dot slope grid on greens; tap-tap meter as an accessibility option.

## Camera
Behind-ball aim cam → launch follow cam → landing cam; top-down 'green read' with a slope grid.

## Tests to write first
- Integrator: no-spin, no-wind shot is symmetric.
- Carry distance per club within ±5% (driver to 7-iron) / ±8% (wedges) of the table (±3% is not reachable with
  published models).
- Ball comes to rest on slopes (sleep threshold).

## Pitfalls
Tunnelling into thin terrain at 70 m/s (CCD + swept raycast); jitter at rest on slopes (force sleep below a velocity threshold).

## Scope cut if behind
Ship as mini-golf (rolling only, no flight model).

## The 10-second moment (what the concept clip shows)
Swipe-swing from behind the ball; the shot climbs with a white trail, fades right in the wind, lands on the green, checks with backspin and curls along the slope grid into the cup — 'BIRDIE!'.

## Open questions
_(fill in during planning)_
