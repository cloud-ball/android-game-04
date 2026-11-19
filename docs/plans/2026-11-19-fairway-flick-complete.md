# Fairway Flick: complete the game (2026-11-19)

Continues docs/plans/2026-11-15-fairway-flick-minigolf.md (steps A-D done, plus visual steps 0-6
and the warm-up). The user chose: **all four worlds before golf ships**, and the first Play upload
waits until golf is in. Name, art, courses and UI stay ORIGINAL (CLAUDE.md); reference games are
genre pointers only.

## The finished game
- **Worlds**: Meadow, Coastal, Canyon, Volcanic. 9 holes each (36), par 2-4, 20-60 m, built from
  the tile kit. Each world has its own GolfTheme (carpet hue, rails, sky, sun, landmark, kit
  dressing) and one signature twist:
  - Meadow: none (learn the game) - ramps, levels, bumpers, sand.
  - Coastal: wind - a constant, shown push on the rolling ball (changes per hole).
  - Canyon: big jumps and drops, more sand.
  - Volcanic: lava pits (a glowing water-type hazard: +1 stroke, back to the last spot).
- **Modes** (start screen: world + mode + difficulty):
  - **Rush** vs 3 CPU golfers: everyone plays the same hole at once as ghost balls (no
    collisions). First ball in the cup wins the hole. A match is 3 holes drawn from the world;
    most holes won takes the match, ties broken by fewest total strokes. Stroke cap par + 3 (out
    of that hole). CPUs "think" 0.8-1.5 s between shots, so being quick matters too.
  - **Tour**: play the world's 9 holes alone; strokes vs par; 1-3 stars per hole (par / birdie /
    hole-in-one-or-better-than-birdie) and a best total.
- **Progression**: Meadow open; win a Rush match (any difficulty) or finish the Tour in a world to
  open the next one. Coins for wins, birdies and stars (Economy). Daily challenges get golf goals.
- **Difficulty** (CPU golfers): Easy / Medium / Hard; target win rate of a decent player vs the
  field ~70 / 50 / 30 % (self-play proxy, see E).

## Steps (each gate must pass; commit per step)
| # | Deliverable | Gate |
|---|---|---|
| E1 | `GolfCpu` (pure): shot search over angle x power using the real solver at the planner step (1/120 s roll), seeded aim/power noise per tier, top-k choice on Easy; runs on WorkerThreadPool; HoleData read-only shared safely | Tests: finds a hole-in-one on a straight hole, never shoots into water when a safe shot exists, deterministic for a seed; phone-class budget <= 1 s per shot |
| E2 | `RushMatch` (pure): players, per-hole states, simultaneous play, stroke cap, hole winner, match winner + tiebreak | Tests for every rule; replay determinism |
| E3 | Scene: ghost balls (colours + name tags), CPU thinking, rival status strip (original design, not a top-bar avatar HUD), hole/match result cards, Rush flow over 3 holes | Screenshots; emulator playtest via scripted drags |
| E4 | Self-play: win rates per tier (ai-opponent skill), tune noise | ~70/50/30 % within +-10 |
| F | Meadow 9 holes + validator: every hole solvable within par by the Hard CPU, every shot sweep finishes (no chatter), landmark framing ok | Validator green; screenshots of all 9 |
| G | Hub integration: start screen (world, mode, difficulty) on the shared GameShell overlays, Tour mode + stars, save schema 2 + migrate(), coins, daily challenges, how-to cards (HowtoDeck), pause/quit, manifest enabled | Tests (save migrate, unlocks, stars); 60 fps on the emulator; ip-checker + physics-reviewer |
| H1 | Coastal: theme, landmark (lighthouse on a rock), wind mechanic (pure + tests), 9 holes | Validator + screenshots |
| H2 | Canyon: theme, landmark (natural arch), 9 holes | Validator + screenshots |
| H3 | Volcanic: theme, landmark (smoking cone, emissive lava), lava hazard, 9 holes | Validator + screenshots |
| H notes | Done 2026-11-19: one commit for all three worlds (shared theme / landmark / scenery code). Wind applies to a ball on the ground (max 0.12 m/s^2), not in the air; WIND dial in the HUD. Canyon "big jumps" launch from mesas two levels up. Switchback and Obsidian Zigzag are par 4. | Validator 36/36 |
| I | Release: merge to the release branch, store listing + screenshots with golf, version bump, IP check, build | Checklist green |

## Risks
- CPU planning cost in GDScript: coarse-to-fine search (~30-40 rollouts to rest at 1/120 s) on a
  worker thread; fall back to fewer candidates on Easy. Measure on the emulator; budget 1 s.
- 36 hand-made holes: the validator (Hard CPU in par, no stuck balls) keeps them honest.
- golf_game.gd is near the 1000-line limit: Rush UI and flow go in new files (rush_view.gd,
  golf_start.gd), not into golf_game.gd.
