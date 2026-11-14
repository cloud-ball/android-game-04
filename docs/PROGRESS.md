# Pocket Arena 8 — progress log

Newest first. Claude appends: date · what changed · how to try it on a phone · open questions.

## 2026-11-14 · Cue Club: ball trays, best of 3, end-of-match stats
- Plan: docs/plans/2026-11-14-cue-club-tray-series.md (research priority 10 + race-to-2 frames).
- Ball trays in the top bar: each player's 7 group balls + the 8; bright = still to pot, dimmed =
  potted, the 8 gets a gold ring once it is the target. A potted ball flies from its pocket to its
  slot (open-table pots fly to the shooter's name and fade).
- Best of 3: second mode on the start screen ("Single rack" / "Best of 3"). Breaks alternate by
  frame; a banner between frames shows the winner, score and who breaks next; frame pips by each
  group. Coins and the daily challenge count once per match; a best-of-3 win pays double.
- End card: potted, best run (consecutive potting shots), pot rate, CPU potted, wins (+ frame score).
- New pure PoolSeries (games/pool/logic/pool_series.gd) with tests; save schema 1 -> 2 adds "mode"
  (migrate keeps everything; tested). 188 tests green.
- Try it: start screen -> Best of 3 -> PLAY; watch the trays fill as balls drop.

## 2026-11-14 · Cue Club: bigger balls (6-ft table), cleaner pockets, softer foul, fuller how-to
- Table: 7-ft -> 6-ft bar table (0.838 x 1.676 m). The phone fits the table to its width, so every
  ball draws ~16% bigger; physics constants unchanged (golden break regenerated with justification).
- Break: the shorter table made centre-ball breaks scratch into the side pockets (29% at 85% power).
  The break now starts with a light follow preset (PoolAim.BREAK_TOP 0.15, visible on the spin
  button, changeable); CPU breaks the same way. 200 breaks: 54% pot a ball, 12% scratch at 85%;
  66% / 9% at full power (7-ft was 34% / 12% and 48% / 22%).
- Pockets: rails and wood are drawn low, so a ball resting in the jaws draws over the hole instead of
  only its numbered top showing through; a potted ball darkens as it sinks.
- Foul: a soft low two-note tone (sines, slow attack/release) instead of the noise burst; lighter buzz.
- How to play: clearer control text (fine-aim edge, power bar side, spin button) and three rule
  cards: Solids or stripes, Call the 8, Fouls give ball in hand (try-it drag).
- CPU self-play on the 6-ft table (20 games each): easy 20% / 35%, medium 40%, hard 65% / 70% -
  ladder intact, easy and medium a little softer than on 7-ft.
- Try it: install the debug APK; open How to play from the pause menu; break a few racks.

## 2026-11-14 · Cue Club: wooden knock sounds, no more twirling balls
- Sounds: ball, cushion, cue and pocket sounds are now filtered-noise knocks with a short low body
  (core/AudioService.gd `_knocks`) instead of ringing sine partials, which sounded like glass. Gains
  set below clipping (checked offline with a Python replica of the generator).
- Physics: spin about the vertical axis now decays at 22 rad/s^2 (was 10.9) and twice that once the
  ball has stopped, so a stopped ball no longer twirls in place for seconds after side spin or a cut
  (~0.7 s at most, was ~2.8 s). Golden break regenerated with the justification in the file.
- Try it: install the debug APK, play a few cuts with side spin and a break; listen to the clacks.

## 2026-11-14 · Cue Club vs similar games: research + first fixes
- Research: docs/research/Cue Club versus mobile pool games.md (+ notes): features, physics feel
  (measured), polish, CPU fairness. Verdict: not shippable yet; blockers were dry breaks, unmeasured
  CPU, the Easy/Medium snap blocking thin cuts, and silent cushions / flat sounds.
- Physics retune (golden break regenerated with justification): mu_roll 0.012 -> 0.010, e_cushion
  0.85 -> 0.95 (WPA rail test 3.4 -> 4.16 table lengths), casual pockets 12.7 / 14.0 cm. Break power
  13 * p^1.2 (85% of the bar = 10.7 m/s, was ~9). Breaks that pot a ball: 3-25% -> 46% at 85% power,
  58% at full; scratches 8-15%.
- Aim snap (Easy/Medium) now locks onto pocket lines (ghost-ball aims), not ball centres.
- Sound: the solver logs impact speed per event; clicks / cushion thuds / pocket drops scale with it
  (quiet touches skipped). New synthesized impacts (damped partials + transient) replace the UI blips;
  cushions finally make a sound. Seeded RNG for pitch variation.
- Next: the simulation-based CPU with measured difficulty (blocker 2).

## 2026-11-13 · Cue Club: point-to-aim
- Turning the cue from the side was hard with the dial-style sweep (a sideways drag beside the ball
  barely rotates it). Now the cue points from the white ball at the finger: touch a ball to aim at
  it, drag to adjust; FINE strip for small corrections; finger within 7 cm of the white is ignored.
  Easy / Medium lock onto a legal ball's centre when within 0.6 / 0.3 deg. How-to card updated.
- Verified on the Vivo; test added (181).

## 2026-11-13 · Cue Club feedback 2: weaker CPU, bigger balls, smooth lines, pocket drops
- CPU weaker: Gaussian aim sigma 0.6/0.26/0.12 -> 1.4/0.7/0.32 deg, speed noise up; Easy / Medium pick
  among their best 4 / 2 shots instead of always the best.
- Bigger balls (+~9%): top bar 120 -> 108, bottom band 200 -> 150 (+ gesture inset), wood 5 -> 4 cm,
  camera pitch 8 -> 5 deg, no extra height margin.
- Smoother aim lines: 2x MSAA in Cue Club only, soft dash ends and edges, and the drawn aim eases
  towards the finger (shots still use the exact aim).
- Pocketing: a captured ball rolls on into the hole and sinks over 0.32 s with its shadow fading,
  instead of vanishing.

## 2026-11-13 · Cue Club feedback: bigger balls, natural rolling, pocket gaps
- Bigger table/balls (~20 dp): thinner drawn rails, wood to the screen edges, shorter top bar, camera
  fitted to the height left between the HUD bands too, pitch 12 -> 8 deg.
- Rolling looked artificial: numbers were upright labels that never turned while stripes rolled.
  Numbers are now printed on two opposite sides and roll with the ball; an upright label fades in
  only once the ball has stopped (readability at rest). Pattern fade starts later at speed.
- Black gaps beside pockets: the cloth now runs under the cushions to the wood; pocket holes sit in
  the jaws and stay inside the table.

## 2026-11-13 · Cue Club step 3: playable table (branch cue-club; enabled on this branch)
- games/pool/scenes: PoolView (22 deg KEEP_WIDTH camera pitched 12 deg, table long axis vertical;
  one MultiMesh + one unshaded shader for all 16 balls - stripes / cue markers roll in object space,
  numbers are an upright camera-facing disc; painted cloth / cushions / wood / pockets / sights, no
  real lights; blob shadows; visual-only spin with a per-tick clamp; aim line, ghost ball, object and
  cue rays, cue stick), PoolControls (power bar v = 8 p^2 m/s, 12 on the break; fine-aim strip
  0.03 deg/dp; spin button + big spin panel with presets), PoolHud (GameShell: players, groups by
  name + number chips, pause, message line), PoolHowto (drag to aim, pull to shoot, spin), PoolGame.
- games/pool/logic: PoolAim (angular sweep around the cue ball, 60 ms lift-off filter, guideline from
  the real solver incl. throw; cue ray = direction after the spin takes hold), PoolCpu (basic: clear
  straight-in shots with Gaussian aim noise 0.6 / 0.26 / 0.12 deg; ball in hand sets up a straight
  shot; breaks at the apex) - the simulation-based CPU is step 4.
- Ball in hand by dragging the white ball (kitchen line on the break); call the 8's pocket by tapping
  a pocket; hold a finger down while balls roll to fast-forward. Sounds: clack, cue, pocket.
- Daily challenges: "Win a game of pool", "Beat the CPU on Medium".
- 180 tests. Desktop: bot vs CPU plays whole racks. Phone pass: pending (phone not connected).

## 2026-11-13 · Cue Club step 2: Casual 8 rules engine (branch cue-club, not playable yet)
- games/pool/logic: PoolState (plain data), PoolShot (built from the solver's event log), PoolRules
  (one pure apply_shot in the researched order: fouls -> break -> 8-ball -> respots -> foul -> open
  table -> assigned -> stalemate), PoolMatch (solver + rules in step: strike / settle, respots, ball in
  hand, cue-ball return, re-rack), PoolRack.spot (foot spot, then along the long string).
- Rules: only the 8's pocket is called; ball in hand anywhere after every foul (break too); 8 on the
  break re-spotted; table open after the break; groups to the first legal pot (first-hit group wins a
  mixed pot; "take what you make"); "group cleared" snapshotted at shot start (last ball + 8 = loss);
  loss reasons: 8 off table > early 8 > 8 with a foul > wrong pocket; no-rail foul; 24 shots without a
  pot re-rack; strict break and scratch-on-8-loses as Pro flags.
- Solver: balls frozen to a cushion at the strike don't count as new rail contacts (WPA 2.7).
- 41 new tests (the research's 40 fixtures + random full games through the solver). 174 total.

## 2026-11-13 · Cue Club step 1: deterministic pool physics (branch cue-club, not playable yet)
- Research: docs/research/Cue Club pool game design.md (+ notes): physics, portrait UX, Casual 8 rules,
  CPU, rendering. pool.md and .claude/rules/cue-sim.md updated with its 15 corrections (rolling
  deceleration is mu_roll*g, not 5/7 of it; 7-ft table; CPU budget 1-3 s, not 150 ms; ...).
  Plan: docs/plans/2026-11-13-cue-club.md.
- shared/cue_sim: CueParams, CueTable (7-ft, rails + angled pocket facings + jaw points + capture
  circles), CueSim (closed-form sliding / rolling / spinning phases, 1/240 s substeps with swept
  time-of-impact events in time order, ball-ball impulse with capped friction (throw), Han 2005
  cushions from pooltool's corrected source, cue strike with tip offset; 64-bit packed state, no trig in
  the hot path). Clusters: slow contacts are inelastic, creeping contacts stop, 64-event cap with an
  energy-safe fallback; no overlaps in random breaks. games/pool/logic/pool_rack.gd (seeded jitter).
- 15 new tests (stun 5/7, draw-back 2/7, mu_roll*g, 90/30-degree rules, throw + gearing english, energy,
  overlaps, stop shot, pockets, rails + english, render-rate independence, golden break).
- Benchmark (Boot --bench=cue) on the Vivo (Adreno 642L): golden break hash IDENTICAL to desktop
  (433143a3...) -> bit-exact cross-platform, one golden file is enough. Live: 144 us/substep (worst
  case ~0.6 ms per 60 Hz frame during a break). AI planning (1/120 s): ~122 ms per break, ~4 ms per
  typical mid-game shot -> ~100 rollouts in ~0.4 s on one core; the research's 35-130 ms guess was
  pessimistic. Desktop: 77 us/substep, 113 ms per break.
- Debug builds read one-shot dev args from user://dev_args.txt (adb can't pass args to the game
  activity): adb shell run-as com.cloud198.pocketarena8 sh -c 'echo --bench=cue > files/dev_args.txt'

## 2026-11-13 · Bigger Serpent Grid pause button
- Serpent Grid's pause was a small 96 px "II" text button. Both games now share UiKit.pause_button():
  a 112 px dark disc with drawn bars in a 144 px touch area (Serpent Grid: top-right under the score
  bar). Verified on the Vivo: visible and opens the pause menu.

## 2026-11-13 · How-to phase 2+3: practice hints, "Try it", How to play in the pause menu
- Pause menu has "How to play"; from there the last card says GOT IT and returns to the menu.
- "Try it": after a demo plays once, "Your turn - try it!" appears; doing the gesture on the demo
  (tap / drag / flick / swipe / HOLD chip or two fingers) shows "✓ Nice!" and replays the board's
  reaction without the finger. Pause moved to a small corner button on the demo.
- First-match practice hints: a looping finger + caption over the real board, never blocking play,
  until the move is done (max twice per match). Stack Drop: Tap to rotate (after 2 shards), Drag to
  move (3), Flick down to drop (5), Tap HOLD (8). Serpent Grid: swipe hint 4 s after GO if no turn;
  "Edges wrap around - keep going!" ~1 s before the first edge.
- Saves: "learned" moves (Stack Drop schema 2, Serpent Grid schema 3); players who had already played
  are migrated as knowing the moves (Serpent Grid still teaches wrap edges). SaveService now copies
  container defaults (const dictionaries are read-only).
- 118 tests; soak runs clean. Phone: Try it (tap, drag, flick), pause -> How to play -> GOT IT,
  wrap hint in a real Serpent Grid match. Dev: --practice forces hints on.
- Try it: open a game -> How to play -> wait one loop -> do the move on the demo. Pause -> How to play.

## 2026-11-13 · Animated how-to cards (both games)
- Research: docs/research/How to play tutorial videos.md (+ notes). Live drawn demos instead of
  video files: 0 bytes of APK, crisp at any DPI, always match the current rules and art.
  Plan: docs/plans/2026-11-13-howto-cards.md.
- shared/ui/howto_deck.gd replaces the static 4-row panel: one verb per card, a ~3 s looping demo on a
  stylised mini-board with an original fingertip glyph (GestureTimeline: Android ripple 75/225/150 ms,
  swipe 200 ms, drag 60+100 ms per column, flick 120 ms). Loops 3 times, then rests on the result with
  Replay; tap the demo to pause. Skip at the top, Back / Next, PLAY on the last card starts the match.
  Cards change only by buttons (players copy the gestures in the demo).
- Serpent Grid: Swipe to turn · Edges wrap around · Make the CPU crash (vs only).
- Stack Drop: Tap to rotate · Drag to move · Flick down to drop · Tap HOLD to keep ·
  Clear rows, send garbage (vs only; the garbage rule was never taught before).
- Settings: new "Reduce motion" toggle -> cards show the old icons as still pictures.
- Android back closes the cards. Dev: --howto=<card> --howto-ms=<t> freezes a card for screenshots.
- 108 tests (timeline phases, ripple timing, drag steps, 3-loop stop + replay, pause, Next/PLAY/Skip,
  reduce motion, Solo filtering, caption length). Verified on the Vivo: all 8 cards, PLAY, Reduce motion.
- Try it: open either game -> How to play. Settings -> Reduce motion to see the still version.

## 2026-11-13 · Thorough QA pass (Stack Drop 12 x 24 + Serpent Grid)
- Headless: 96 tests; rules fuzz 150 seeds; soak runs of both games x vs/solo x 3 difficulties at 8x
  speed (no errors); layouts at 16:9, 19.5:9, 20:9, 21:9 and 2:3 (no overlaps or cut-offs).
- Phone (Vivo): hub -> Stack Drop -> how-to -> play (tap rotate, drag 2 columns, flick drop, HOLD once
  per shard, back = pause/resume) -> top-out -> results -> play again -> pause -> restart / back to hub ->
  Serpent Grid play. No errors in logcat; load 166 ms + 431 ms warm-up.
- Fixed: Serpent Grid - a snake moving into the tail cell of a snake that crashed on the same tick
  overlapped it on the final frame; it now crashes too (draw). Found by the fuzzer, test added.
- Fixed: Stack Drop start screen showed the old difficulty's level behind the panel (GameShell now emits
  difficulty_changed); Solo left an empty CPU column in the top band (layout is now mode-aware, test).
- CPU retuned for the 12 x 24 board with new tools/stack_selfplay.gd (difficulty table moved to
  games/blocks/logic/stack_difficulty.gd). vs an "average" simulated player: Easy was 0% -> 27%
  (it barely cleared lines), Medium 75% -> 53%, Hard unchanged (100%; 35% vs a strong player).
- Note: the QA match on the phone used the real save (one extra Stack Drop loss, +2 coins).

## 2026-11-12 · Stack Drop: slower falling speed until level 25
- User: blocks come too fast. Gravity was 1 + 0.55/level (L10 5.95 rows/s, L25 14.2). Now 1 + 0.2/level up
  to level 25 (L2 1.2, L10 2.8, L25 5.8 rows/s), then +0.7/level after 25, capped at 20. Test added.
- Try it: play Stack Drop past a few levels; it should stay calm for much longer.

## 2026-11-12 · Stack Drop: 12 x 24 tower (blocks smaller again)
- User asked for still smaller blocks. Board 10 x 20 -> 12 x 24 visible (W 12, H 26 incl. 2 hidden rows);
  spawn column now derived from the width so shards still start mid-board.
- Vivo: cell 91 -> 76 canvas units (35 -> 29 dp, ~4.7 mm); tower unchanged at ~84% of the width.
  Drag stays 36 dp per column, so moving shards feels the same.
- 93 tests green, fuzz 0 violations over 30 seeds. Lines need 12 cells now, so matches run longer and the
  CPU clears more slowly - check on the phone whether its speeds need retuning.
- Try it: open Stack Drop -> 12 columns, 24 rows.

## 2026-11-12 · Stack Drop: 10 x 20 tower (smaller blocks, more of them)
- User: keep the big tower but make the blocks smaller with more of them. Board 9 x 18 -> 10 x 20 visible
  (StackState.W 10, H 22 incl. 2 hidden rows). BoardLayout takes COLS/ROWS from StackState, so the
  well, posts and pedestal follow automatically.
- Vivo: cell 100 -> 91 canvas units (39 -> 35 dp); tower still ~84% of the width and ~75% of the height.
- 93 tests green, fuzz 0 violations over 30 seeds. CPU speeds unchanged (it may clear a little slower on
  the wider board - check on the phone).
- Try it: open Stack Drop -> 10 columns, 20 rows.

## 2026-11-12 · Stack Drop: much bigger tower (HOLD moved up beside NEXT)
- User: tower still too small. Plan: docs/plans/2026-11-12-stack-drop-bigger-tower.md.
- HOLD left the bottom band and sits in the top band beside NEXT (row 2: CPU | HOLD | NEXT); the bottom
  band is now just the pedestal. Side gutter 92 -> 72, pedestal 10.4 -> 9.8 cells, max cell 38 -> 42 dp.
- Vivo: cell 92 -> 100 canvas units (36 -> 39 dp), tower 77% -> 84% of the width, ~75% of the height.
- NEXT previews are sized to fit the strip; start hint shows in the upper-middle of the empty well.
- Two-finger tap still holds. Layout tests updated (4 phone shapes, 48 dp targets, no overlaps).
- Try it: open Stack Drop -> tower fills most of the screen; tap HOLD (top left, under CPU's right).

## 2026-11-12 · Bigger Stack Drop tower, bigger "Back to hub"
- Tower cells 88 -> 92 canvas units on the Vivo (34 -> 36 dp); tower 73% -> 77% of the width. Space came
  from tighter HUD bands (side gutter 130 -> 92, pedestal band 140 -> 108, HOLD 168 -> 150, NEXT 130 -> 120).
  Cell size is also capped so the pedestal always fits inside the side margins (21:9 phones).
- Pause hit area trimmed to stop at the NEXT strip (still >= 48 dp on a 360 dp phone).
- Shared menus (both games): "Back to hub" and "How to play" are full-size white buttons (38-40 px text,
  ~110 px tall) instead of small grey ones.
- Try it: open Stack Drop -> the tower is wider; pause -> "Back to hub" matches the other buttons.

## 2026-11-12 · QA pass fixes (Stack Drop + hub + Serpent Grid)
- QA: tools/qa_fuzz.gd (rules invariant fuzzer) + Boot --time-scale soak runs found the bugs below.
- Stack Drop rules: shards can no longer rotate/kick into the hidden rows above the tower; a lock that
  leaves any cell above the top, or garbage that lifts blocks above the top, now ends the game instead of
  leaving invisible blocks. 3 new tests; fuzz: 0 violations over 40 seeds.
- Stack Drop HUD: held shard stays bright after using HOLD (was too dim); the start hint sits beside HOLD
  instead of over the bottom rows.
- Loading screen: game title, spinner and "Loading..." stay up until the new scene has drawn 3 frames
  (first-use shader compile happens behind it). Vivo: ~180 ms load + ~450-560 ms warm-up.
- Hub: Android back no longer quits at once - first press shows a centred "Press back again to exit"
  toast, a second press within 2 s exits (back closes Settings first if it is open).
- Serpent Grid now uses the shared GameShell overlays (same start / how-to / pause / results as Stack Drop);
  its HUD lost ~250 duplicated lines. Larger HUD text (36-38 px labels, 36 px start stats on both games).
- Not fixable: "Vulkan surface lost" in logcat when the app goes to the background is Android/driver noise.
- 93 headless tests, lint clean. Verified on the Vivo: hub back/toast, loading screen, Serpent Grid
  start / how-to / play / pause, Stack Drop start / play / HOLD / hint.
- Try it: open the app, press back once (toast) then twice (exit); open Stack Drop, press HOLD and
  check the held shard is easy to see; open Serpent Grid -> How to play.

## 2026-11-12 · Stack Drop board redesign (researched)
- Research: docs/research/Stack Drop board redesign.md (+ notes). Cell 88 canvas units (~34 dp, 5.6 mm),
  well ~73% of width; orthographic camera pitched 9 deg; 0.55-deep gem slabs; pedestal sized to the margins;
  HUD moved off the well (top band read-only, HOLD bottom-left); lightness-ladder palette + glyph per shard.
- games/blocks/logic/board_layout.gd: pure layout (cell size + every HUD rect from canvas size, safe area,
  density); 8 tests over 20:9, 19.5:9, 21:9 and 16:9 (no overlaps, nothing in the gesture keep-out,
  48 dp tap targets on a 360 dp phone).
- Shards now spawn in the top visible rows (hidden rows are rotation headroom only).
- Drag step is physical (36 dp per column), gestures ignored on HOLD/pause, screen edges and the
  gesture area. Vivo: phone density 480 -> 420 dp wide. Verified on the phone; 60 fps (bot vs Hard).

## 2026-11-12 · Stack Drop tested on the Vivo
- Full pass on the phone: hub card -> how-to -> start -> tap rotate, drag move, flick drop, HOLD box,
  garbage rows from the CPU, top-out -> TOWER FULL results. No errors in logcat; 60 fps.
- CPU was too strong (Medium cleared 27 lines in 50 s). Now: Easy 2.4 s/shard (top 5, noisy),
  Medium 1.7 s (top 3), Hard 1.15 s (best) -> Medium ~11 lines in 50 s.
- First open of Stack Drop takes ~5 s (one-time shader compile); later opens are fast.
- Bigger tower (user request): near full width/height; NEXT, HOLD and CPU are slim see-through panels over
  the outer top columns; pause moved into the score bar; 30° lens, gentler sway.

## 2026-11-11 · Stack Drop step 2: playable (branch stack-drop)
- 3D crystal tower (games/blocks/scenes/blocks_view.gd): gem shader with facet edges, outlined ghost,
  glass back pane with grid, posts, hex base, clear flash + crystal shatter, garbage bar, slow sway.
- Touch gestures (StackGestures, tested): tap rotate, drag move per cell, slow drag soft drop, flick hard
  drop, two-finger tap hold; HOLD box is tappable; desktop keys with DAS/ARR.
- shared/ui/game_shell.gd: reusable start / how-to / countdown / banner / pause+settings / results
  overlays (Stack Drop uses it; Serpent Grid still has its own HUD - migrate later).
- vs CPU race with garbage exchange (+ cancelling) and Solo score attack; Easy/Medium/Hard.
- Daily challenges now rotate only over enabled games; 3 Stack Drop challenges added.
- Dev: Boot --game opens games even while their manifest is disabled. Stack Drop enabled on this branch.
- 81 headless tests.

## 2026-11-11 · Stack Drop step 1: rules + CPU search (branch stack-drop, not yet playable)
- games/blocks/logic: ShardData (shards A-G, kick tables from data/kicks.json), StackState,
  StackLogic.reduce(state, action) (moves, kicks, gravity, lock delay + 15 resets, clears/scoring/levels,
  hold, 3-preview, ghost, garbage with cancel, top-out), StackAI (rotation x column search + heuristic).
- 25 new tests (73 total). Export presets now include games/*/data/*.json (kick table ships in the APK).
- Plan: docs/plans/2026-11-11-stack-drop.md. Next: 3D crystal tower + touch controls + HUD.

## 2026-11-11 · Weaker CPU + turn hints (user feedback)
- New ai_blunder knob (CPU sometimes skips the flood-fill look-ahead; never picks a blocked cell): Easy 15%,
  Medium 8%, Hard 2%. Hunt 0 / 0.05 / 0.3, wander 0.5 / 0.3 / 0.1. CPU win vs steady bot: 20% / 30% / 41%
  (was 40 / 49 / 52). Rule file .claude/rules/snake.md updated to allow blunders.
- Turn hint: a glowing white › (0.9 cell, pops in) rides in front of the head + brief head glint (0.6 s);
  tiny haptic tick on each accepted swipe. 48 headless tests.

## 2026-11-11 · Polished settings UI (user feedback: too small)
- shared/ui: IconGlyph (drawn icons), ToggleSwitch (large animated switch), SettingsSheet (bottom sheet:
  Music / Sound effects / Vibration rows with icons + hints, About card, Done). Whole rows are tap targets.
- Hub header: coin pill + round gear button. Pause menu gains Settings (same sheet). Android back closes it.
- Bug found while testing: controls given "full rect" after entering the tree keep a 0x0 size -> use
  set_anchors_and_offsets_preset / UiKit.center(). 46 headless tests; verified on the Vivo.

## 2026-11-11 · Wrap-around edges (user request)
- SnakeConfig.wrap (on for all levels): leaving an edge re-enters on the opposite side; only tails crash.
- AI pathing/flood/cut-off/head-avoid are wrap-aware; view slides wrapped segments in from outside the edge.
- How-to step 4 is now "Edges wrap around". 43 headless tests. Matches ~50% longer; 59-61 fps on the Vivo.
- Fixed: physics interpolation smeared the snake scene's first frames (giant boxes) -> OFF for this game.

## 2026-11-11 · Space backdrop + AI speed-up
- New games/snake/scenes/snake_backdrop.gd: twinkling drifting stars, noise nebula clouds, shooting stars,
  rising sparks; see-through board; grid ripples on eat/crash; pulsing board edge.
- Found with `--fps` on the phone: AI ticks took 70-195 ms (stutter). Flood fills now stop once the answer is
  known and use packed arrays -> solid 59-61 fps on the Vivo (Hard, bot vs CPU), GPU ~9 ms, ~33 draw calls.
- Boot `--fps` prints fps, process time, GPU time and draw calls to the log.

## 2026-11-11 · Bigger board, slower snakes, easier Medium (user feedback)
- Camera 78° / 26° lens; tall screens get extra rows (12x22 on 20:9, 12x18 on 16:9): board ~46% -> ~70% of screen.
- Speeds lowered: Easy 4.5->7, Medium 5.5->8.5, Hard 6.5->10 tiles/s. Medium hunts 15% (was 30%), wanders more.
- 37 headless tests.

## 2026-11-10 · Serpent Grid polish (all 5 items)
- Music: original synth loops (hub + game mixes) rendered on a worker thread, cached in user://; Music toggle.
- Solo score-attack mode (vs CPU / Solo selector), solo best + NEW BEST, save schema 2 with migration.
- Visuals: joined snake bodies, heads with eyes facing the move direction, orb sparkles.
- First-launch HOW TO PLAY screen (drawn illustrations), reachable again from the start panel.
- AI tuning via tools/snake_selfplay.gd: fixed head-on draw bug (93% of Easy/Medium bot matches were draws),
  all levels avoid head-on, new hunt (cut-off) knob; Easy slower (5.5 tiles/s). CPU win vs bot: 39/41/55%.
- 35 headless tests; verified on the Vivo (first launch, how-to, vs CPU, Solo, music cache).
- Try it: install build/pocket-arena-8-debug.apk (already on the test phone, data cleared for a fresh first run).

## 2026-11-10 · Serpent Grid ready for closed testing (branch serpent-grid-v1)
- Godot 4.7.2 project, core services (Rng, SaveService, Settings, Audio, Economy, GameRegistry, SceneRouter, Boot args),
  hub with 8 manifest-driven cards (only Serpent Grid enabled), daily challenge, coins.
- Serpent Grid: pure logic + CPU rival (BFS to orb + flood-fill trap check) + neon 3D view + HUD. 30 headless tests.
- Verified on a Vivo V2250 (Android 15): hub → game → swipes → crash/result → rematch.
- Release: Gradle AAB (minSdk 24, targetSdk 36), scripts/make_upload_key.sh + scripts/build_release.sh,
  store assets + listing + privacy policy in docs/store/, CI workflow (not yet run on GitHub).
- Try it on a phone: `godot --headless --path . --export-debug "Android APK" build/pa8.apk && adb install -r build/pa8.apk`.
- Dev shortcuts: `godot --path . -- --game=snake --bot --difficulty=hard` (bot runs never touch the save).
- Open: gdUnit4 is 6.2.3 (guide said v7, which doesn't exist); tests need --headless --ignoreHeadlessMode.

## Week 0
- Project created from the starter kit.

## 2026-11-10 · Kickoff
- Kit copied into repo (CLAUDE.md, .claude/, docs/, ASSETS.md); guide at docs/design/; keyframes in docs/refs/<id>/.
- Toolchain checked: Godot 4.7.2 + templates, Android SDK, JDK 17, Xcode OK; missing gdtoolkit, poppler; $GODOT unset.
- Week-1 plan: docs/plans/week-1.md. Nothing to try on a phone yet.
