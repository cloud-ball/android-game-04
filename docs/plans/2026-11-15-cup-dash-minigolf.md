# Cup Dash: arcade mini-golf re-base (2026-11-15)

Supersedes docs/plans/2026-11-14-cup-dash-courses.md. After playing the first long hole on the
phone the user asked for a game in the arcade mini-golf genre instead (reference named only as a
genre pointer: short cartoon holes with ramps, walls, bumpers, sand and water; slingshot shot; a
Rush race where every ball plays at once). Name, art, UI layout and courses stay ORIGINAL (CLAUDE.md).

## What the game is
- **Hole**: 20-60 m, walled, built from tiles: straights, bends, ramps, humps, bumpers, sand pits,
  water, gaps, tunnels, a moving gate later. Par 2-4. Played in 20-60 s.
- **Shot**: press on the ball, drag back (slingshot): direction = opposite the drag, power = drag
  length (0..1 -> 0..MAX_SPEED). A dotted guide shows the first few metres of the ball's actual path
  (simulated, including the first wall bounce; length shrinks with difficulty). Release to shoot;
  drag back under the dead zone to cancel. The ball rolls; it only flies off ramps and drops.
- **Camera**: low behind the ball, looking along the aim; it turns with the drag. Fly-over of the
  hole at the start. Chase while the ball moves; top-down nudge when close to the cup.
- **Rush** (first mode): you and 2-3 CPU rivals play the hole at the same time; balls do not
  collide (ghosts); first in the cup wins the hole; a Rush match is 3 holes, most hole wins takes it.
  Stroke cap per hole (par + 3 -> you are out of that hole). Rivals think for a visible 0.8-1.5 s.
- **Progression** (later steps): worlds = the four themes already researched (meadow, coastal,
  canyon, volcanic); win Rush matches to unlock the next world; stars for solo strokes under par.
- **Reuse**: GolfBall roll / bounce / slope / rest / cup, GolfFlight for airborne hops, HoleData grid
  + swept contact, HoleBaker (re-scoped), GolfScenery themes, GolfTerrain shader, --bench=golf.
  Dropped: clubs, long-course swing, the 290 m hole.

## Physics additions (deterministic, pure)
- `HoleData.walls`: segments (x0, z0, x1, z1, height) and `bumpers` (x, z, r). Rolling ball vs wall:
  swept circle-segment / circle-circle, e_wall 0.8, tangential keep 0.9 (tuned), processed in time
  order within a substep like cue_sim cushions. Walls also stop airborne balls below wall height.
- Ramps / humps / tilted greens come from the height grid (already supported). A ball that leaves
  the ground (vertical speed from a convex edge) switches to GolfFlight with zero lift until it
  lands (existing bounce model).
- MAX_SPEED ~ 14 m/s; rolling decel per surface as now (carpet green ~ Stimp 10 feel), sand 8.

## Steps (each gate must pass)
| # | Deliverable | Gate |
|---|---|---|
| A | This plan; docs/games/golf.md + .claude/rules/golf.md re-scoped | - |
| B | Walls + bumpers in HoleData / HoleBaker / GolfBall; hop-off-ramp hand-off; tests (wall bounce angle, corner, bumper, time ordering, golden) | Tests green; a ball never passes through a wall at MAX_SPEED |
| C | Tile-based `HoleSpec` v2 (grid of tiles with rotation) -> HoleBaker: walls along tile edges, ramps, sand, water, cup; 3 test holes | Structural checks: every hole solvable by a scripted shot sequence |
| D | Scene: slingshot control with simulated guide, low camera, cup / splash / bounce effects, hole fly-over; one hole on the phone | Phone playtest: direction and power feel right |
| E | Rush vs 2-3 CPU rivals: CPU shot search on a worker thread (angle x power, seeded noise per tier), ghost balls, hole win, 3-hole match, result card | Self-play win rates easy/medium/hard ~70/50/30 % |
| F | World 1 (meadow): 9 holes from the tile kit, theme dressing, validator | Validator green; every hole finishable in par by the Hard CPU |
| G | Hub integration: start screen (world + difficulty), save schema 2 + migrate, coins, how-to cards, enable in the manifest | 60 fps mid-range; ip-checker + physics-reviewer pass |
| H | Worlds 2-4, stars, daily | Same gates per world |

## Open questions
- Ball-ball collisions in Rush: off (ghosts) for v1; revisit if it feels empty.
- Wind: only in the coastal world, as a constant push on the rolling ball.
