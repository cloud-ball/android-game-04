# Fairway Flick — arcade mini-golf vs CPU rivals (Phase 3)

> Re-based 2026-11-15 (user feedback after the first long hole): the game is arcade MINI-golf, not
> full-course golf. Plan: docs/plans/2026-11-15-fairway-flick-minigolf.md. The long-course notes
> below are kept for the physics they still use; clubs and swings are dropped.

Folder: games/golf/ · rules: .claude/rules/golf.md · risk: Medium (walls + race AI)
Research: docs/research/Fairway Flick golf game design.md (physics, CPU), Fairway Flick courses and
maps.md (themes, progression, pipeline).

## The game
Short walled holes (20-60 m, par 2-4) built from tiles: straights, bends, ramps, humps, bumpers, sand,
water, gaps. Slingshot shot: press the ball, drag back, a dotted guide shows the simulated path,
release. Rush mode: you and 2-3 CPU rivals play at once (ghost balls), first in the cup wins the hole,
3 holes per match. Worlds = the four researched themes; win matches to unlock the next world.

## Physics
Custom deterministic solver (GolfBall + GolfFlight on HoleData): rolling with per-surface
deceleration and (5/7) g slope pull, Penner bounces, offset-dependent cup capture, walls and bumpers
(swept circle vs segment / circle, time-ordered), airborne hops off ramps via the flight model with
zero lift. 4 x 1/240 s substeps per tick; + - * / sqrt only in the hot path.

## Tuning starting points
| Parameter | Value |
|---|---|
| Ball | 42.67 mm, 45.93 g, rho 1.225 kg/m^3 |
| Drag | Cd = 0.225 + 0.275 x crisis(Re) (logistic around Re 8e4, tabulated) + 0.18 x (1 - e^-3S^2) (was a 0.27 -> 0.32 step: drives ~12% short) |
| Lift | Cl = 1.99S - 3.255S^2 to S = 0.25, then linear (slope 0.3625), no clamp (the old 0.25 clamp flattened irons) |
| Spin decay | ~0.001 per metre travelled (~4%/s), applied as a per-step factor |
| Clubs | Driver ~175 m carry, hybrid ~150, 7-iron ~130, wedge ~95 (partial to 10 m), putter |
| Bounce | Penner bounce with a fixed tilt: soft green mu 0.40, firm green mu 0.25 (both e = Penner e(v), tilt 15 deg - an 11 deg firm tilt never spun back); fairway e 0.22, mu 0.5, 16 deg; rough / sand / path tuned by feel (GolfSurfaces) |
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
