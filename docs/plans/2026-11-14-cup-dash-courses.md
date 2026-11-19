# Cup Dash: courses, holes and progression (2026-11-14)

Supersedes the single-nine scope of docs/plans/2026-11-14-cup-dash.md (its steps 1-3 are done:
scaffold, flight, HoleData + swept contact). Source: docs/research/Cup Dash courses and maps.md
(+ notes), on top of docs/research/Cup Dash golf game design.md. Branch: `cup-dash`.
The game stays `enabled = false` until the launch gate (step 11); each course also has its own
`enabled` flag.

## What the game is
A full golf game, not a flick demo: themed 9-hole courses ("maps") with real holes, played against
named CPU rivals.

| | 1 Meadow Run | 2 Saltwind Links | 3 Red Mesa | 4 Ember Lagoon | Bonus Summit Shorts |
|---|---|---|---|---|---|
| Theme | Parkland | Coastal links | Canyon desert | Volcanic tropical | Alpine, all par 3 |
| Variety axis | Width, forgiving greens | Wind, ground game | Elevation, carries, blind shots | Water, precision | Altitude, elevation |
| Par / length | 35 / ~2,270 m | 34 / ~2,365 m | 35 / ~2,545 m | 35 / ~2,490 m | 27 / ~1,250 m |
| Wind | 0-3 m/s | 3-7 m/s | 2-5 m/s | 3-8 m/s | 1-6 m/s |
| Greens | Stimp 8-9, 28-36 m | Stimp 10, firm | Stimp 10 | Stimp 11, 16-22 m | Stimp 11 |
| Signature (hole 6) | Hilltop par 3 over a pond | Cliff-edge Cape past a beacon | Drive over a rock arch | Island green, waterfall | Cliff-to-cliff par 3 (hole 9) |

Hole-by-hole skeletons (archetype, par, length) are in the research report's course line-up table.
Course names are working titles: `ip-checker` before release.

**Length scale (revised):** real-metre physics with templates scaled by 0.85 against a scratch
driver - par 3 90-185 m, drivable par 4 190-215 m, par 4 255-330 m, par 5 370-480 m. (Replaces
the earlier par-32 executive nine.)

**Progression:** win 2 of 3 rival legs (holes 1-3, 4-6, 7-9) or finish the nine to open the next
course (Course 2 within ~10 minutes). Stars from measured CPU averages, per-hole medals, Pro tees
at 3 stars, mirrored layouts for beating a rival, bonus course after Course 2, a 36-hole
championship after Course 4. Modes per course: 3-hole match legs, 9-hole round, score attack, one
themed skill challenge. Daily Three (date-seeded) and weekly rule events. Coins buy cosmetics only.
Save after every hole.

## Pipeline (fits the existing code)
- `GolfParams` + `SurfaceTable` (bounce / roll per surface) + `CoursePreset` (wind, Stimp,
  firmness, air density; the steepest restable grade is derived from Stimp: 9.8% at 8 -> 7.1% at 11).
- `HoleSpec` (centre-line spline, widths, elevation keys, green spec, stamped bunkers / water /
  OB, 2-3 tees, pins, scatter zones) -> static `HoleBaker.bake(spec, preset) -> HoleData`
  (deterministic, golden-hashed). `ArchetypeLib` proposes specs from archetype templates; holes are
  then hand-tuned.
- Validation in two stages: fast structural checks on every baked hole in the test suite; a cheap
  validator golfer (Monte Carlo) for playability and ratings. The full CPU planner only rates holes
  in a separate pass (running it on every combination would take ~35 h).
- Rendering: chunked terrain with coarser far chunks, one terrain shader fed by the surface grid,
  per-theme kit of ~15 meshes on one palette material, MultiMesh per species per chunk, gradient
  sky + fog + backdrop ring + one landmark. ~100-150k triangles mid-range, <= 100 draw calls.

## Build order (steps 1-3 done)
| # | Deliverable | Gate |
|---|---|---|
| 4 | Bounce, roll, rest, cup, water / OB; SurfaceTable + CoursePreset | Bounce, spin-back, Stimp, rest-on-slope at Stimp 8 / 10 / 11, cup tests |
| 5 | `--bench=golf` on the test phone | us per substep, ms per rollout; 240 vs 120 Hz |
| 6 | HoleSpec + HoleBaker + structural validator; one greybox hole baked from a spec with chunked terrain, shader, ball, camera, pull-and-release swing, landing marker | Bake benchmarked; structural checks; screenshots |
| 7 | Putting, slope grid, wind HUD, how-to cards | Feel playtest on the phone |
| 8 | CPU (putting, planner, tiers) + validator golfer + rating harness | ~70/50/30 % wins; rating CSV |
| 9 | Course 1 Meadow Run: 9 holes, theme kit 1, seeded tees / pins / wind | Validator green; Easy-CPU +4..+6; hours per hole measured |
| 10 | Modes, legs, rivals, stars, save schema 2 + migrate, daily, accessibility, quality tiers | 60 fps mid-range / 30 floor; ip-checker + physics-reviewer |
| 11 | Course 2 Saltwind Links. **Launch gate**: enable the game with Courses 1-2 | Ratings order Courses 1 < 2 |
| 12 | Courses 3-4 (Red Mesa, Ember Lagoon) | Same + difficulty spread |
| 13 | Summit Shorts, mirrored / Pro tees, night + autumn palettes, weekly events, championship | Pack size and VRAM within budget |

Courses 3-4 ship at launch only if step 9 shows about half a day or less per finished hole;
otherwise they follow as free updates.

## Open questions
- Release exports are `--headless` (shader baker skipped). Decide before the next store build.
- Rough / sand / path turf constants and player swing dispersion are unmeasured - tune by self-play.
