# Pocket Arena 8 — progress log

Newest first. Claude appends: date · what changed · how to try it on a phone · open questions.

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
