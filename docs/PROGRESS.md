# Pocket Arena 8 — progress log

Newest first. Claude appends: date · what changed · how to try it on a phone · open questions.

## 2026-11-11 · Weaker CPU + turn hints (user feedback)
- New ai_blunder knob (CPU sometimes skips the flood-fill look-ahead; never picks a blocked cell): Easy 15%,
  Medium 8%, Hard 2%. Hunt 0 / 0.05 / 0.3, wander 0.5 / 0.3 / 0.1. CPU win vs steady bot: 20% / 30% / 41%
  (was 40 / 49 / 52). Rule file .claude/rules/snake.md updated to allow blunders.
- Turn hint: a small › rides just in front of the head pointing at the newest buffered turn (0.42 s);
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
