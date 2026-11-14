# Pocket Arena 8 — starter prompts for Claude Code

Run **one prompt per session**, in plan mode (Shift+Tab or `claude --permission-mode plan`) for anything touching more than 3 files; approve the plan, then let Claude implement.

Start every session after the first with:
```
Read CLAUDE.md and docs/PROGRESS.md, then continue with the next starter prompt in docs/STARTER_PROMPTS.md.
```

## 0. Kickoff (sent automatically by scripts/start_project.sh)
```
You're starting Pocket Arena 8: an original 3D mini-game hub for iOS and Android built in Godot 4.7 (GDScript, Jolt). Read CLAUDE.md and docs/GDD.md, and look at docs/refs/hub/keyframe_1.png, keyframe_2.png and docs/refs/pool/keyframe_2.png (visual targets; the docs/refs/*/prototype.html files are throwaway three.js mocks, so never port their code). The full guide is docs/design/PocketArena8_Build_Guide.pdf: engine settings p. 6, architecture pp. 7-8, Claude Code setup pp. 25-26, roadmap p. 28. Then: 1) check my toolchain (Godot 4.7 on PATH or $GODOT, export templates, JDK 17 + Android SDK, gdtoolkit, jq, poppler) and list what's missing with install commands; 2) ask me up to 8 questions about anything unclear, in one round; 3) write docs/plans/week-1.md for roadmap week 1, including how you will verify each step headlessly. Don't write game code yet.
```

## Phase 1 — hub

### Week 1 · project
```
Create the Godot 4.7 project in this folder per CLAUDE.md: project settings from the guide (Jolt, 60 Hz ticks + physics interpolation, Mobile renderer, ETC2/ASTC), the folder layout, gdUnit4 with one passing smoke test. Verify the test command and a headless Android debug export work; fix CLAUDE.md if any command differs.
```

### Week 2 · core services
```
Implement core/Rng.gd (seeded) and SaveService (namespaced games, per-game schema + migrate, unknown keys preserved, temp file + atomic rename + rolling backup) test-first, including a test that an old save without a new game's key still loads. Then SettingsService and AudioService.
```

### Week 2 · hub shell
```
Implement GameRegistry (reads games/*/manifest.tres), SceneRouter (threaded loading behind a loading screen, frees the previous game) and the hub launcher: game cards, coins, a daily-challenge card, 2 taps to play. Disabled games show 'coming soon'. Then /shot hub and compare with docs/refs/hub/*.png.
```

### Week 2 · input + cameras
```
Implement InputKit (drag-aim, pull-back power, swipe with 2-deep buffer, tap, pinch, two-finger orbit, Godot 4.7 VirtualJoystick) and CameraKit (top-down table, orbit-follow, fixed broadcast rigs) with a demo scene; add launcher args --game, --shot, --quit-after and a bot-mode autoload.
```

### Week 3 · Serpent Grid (games/snake) — details in docs/games/snake.md

1.
```
Read CLAUDE.md and .claude/rules/snake.md. Implement pure grid logic with tests (collision, growth, 2-deep input buffer).
```
2.
```
/new-minigame snake — 3D renderer with smooth tick interpolation and neon materials.
```
3.
```
Add swipe input via InputKit and the rival snake (A* + flood-fill safety) with tests.
```

### Weeks 4–5 · Stack Drop (games/blocks) — details in docs/games/blocks.md

1.
```
Read CLAUDE.md and .claude/rules/blocks.md. In plan mode, design the pure reducer: state, actions, SRS-style kicks, seeded 7-bag, lock delay. Tests first.
```
2.
```
Implement the reducer + tests for kicks, the bag and bit-exact replays.
```
3.
```
/new-minigame blocks — render the reducer as a 3D crystal tower (original look: 9×18, gem materials, shard names A–G).
```
4.
```
Add touch controls with DAS/ARR, hard drop, hold; capture /shot blocks and check readability on a small phone.
```
5.
```
Add the CPU rival (heuristic placer) with garbage rows; /ai-opponent blocks medium.
```

### Weeks 6–7 · Chess 3D (games/chess) — details in docs/games/chess.md

1.
```
Read CLAUDE.md and .claude/rules/chess.md. Plan the move generator and the perft test harness first.
```
2.
```
Implement the move generator until perft(start, 1..4) matches; add standard test positions.
```
3.
```
Implement negamax alpha-beta with iterative deepening, TT, quiescence and MVV-LVA; add mate-in-N tests.
```
4.
```
Add difficulty knobs (depth/time/top-k margin) and a threaded search with a time budget.
```
5.
```
/new-minigame chess — 3D board, lathe-turned pieces, tap/drag input, legal-move dots; /shot chess.
```

### Weeks 8–10 · Break & Bank (games/pool) — details in docs/games/pool.md

1.
```
Read CLAUDE.md and .claude/rules/cue-sim.md. In plan mode, design shared/cue_sim: a deterministic 2.5D ball solver with a sliding→rolling transition, swept-circle time-of-impact collisions, cushions and pocket capture. List the tests before any code.
```
2.
```
Implement the solver and its tests: golden-master break, stop shot, energy never increases, 10k random shots with no overlap. Run them headless.
```
3.
```
/new-minigame pool — then build a low-poly 3D table scene (original felt colour and rail style) that renders the solver state.
```
4.
```
Implement the 8-ball rules state machine with tests: open table, groups, fouls, ball-in-hand, 8-ball win/loss.
```
5.
```
Build the touch aim / power / spin UI on InputKit, then /shot pool and review the screenshots.
```
6.
```
/ai-opponent pool easy|medium|hard — report self-play win rates against the targets.
```
7.
```
/perf-check and fix any budget violations.
```

### Week 11 · economy + ads
```
Implement Economy (coins, cosmetic ownership/equip), Achievements, and Ads/IAP/Analytics adapters behind the existing interfaces (evaluate maintained Godot AdMob and billing plugins first; keep no-op stubs for tests). Rewarded ads for coin doubling/retries, interstitials capped (>= 3 min, never mid-match), Remove Ads IAP. Then /perf-check on a low-end Android phone.
```

### Week 12 · release
```
Use the ip-checker subagent on the whole repo, fix findings, then /store-assets-style screenshots via /shot for all 4 games and /release-android for the closed test.
```

## Phase 2

### v1.1 · Carrom Corner (games/carrom) — details in docs/games/carrom.md

1.
```
Read .claude/rules/cue-sim.md. Extend shared/cue_sim with disc mode (no rolling phase) + tests.
```
2.
```
/new-minigame carrom — board scene, coins, striker; rules engine (turns, queen/cover, fouls) with tests.
```
3.
```
Baseline striker placement + slingshot UI; then /ai-opponent carrom medium reusing the pool search.
```

### v1.1 · Top Corner (games/penalty) — details in docs/games/penalty.md

1.
```
Read .claude/rules/penalty.md. Implement the ball-flight integrator (drag-crisis blend + Magnus) with tests.
```
2.
```
Swipe-curve input fit from touch points with recorded fixtures.
```
3.
```
Keeper state machine with the difficulty table; /new-minigame penalty with stadium, goal, net.
```
4.
```
Alternating shoot/keep rounds + sudden death; /shot penalty.
```

## Phase 3

### v1.2 · Fairway Flick (games/golf) — details in docs/games/golf.md

1.
```
Read .claude/rules/golf.md. Implement the flight integrator with Cd/Cl vs spin ratio, wind, spin decay; tests first.
```
2.
```
Landing handoff to Jolt with CCD + green roll model with slope and cup capture.
```
3.
```
/new-minigame golf — 3 modular holes (Kenney/Quaternius-style kit), aim arrow, swing input, cameras; then 9 holes.
```
4.
```
CPU rival via simulated grid search; /physics-tune golf for carry distances.
```

### v1.2 · Park & Pass (games/drive) — details in docs/games/drive.md

1.
```
Read .claude/rules/drive.md. VehicleBody3D prototype with the tuning constants exposed in a resource; handling regression tests.
```
2.
```
Parking mission schema (JSON/resource) + detector with tests.
```
3.
```
Lane-spline traffic with a gap controller + light timers; 5-minute headless soak test.
```
4.
```
/new-minigame drive — 5 missions, chase + parking cams, wheel/pedals UI; evaluate a custom raycast car if handling feels floaty.
```

## Prompts you will reuse

- `/new-minigame <id>` · `/shot <id>` · `/physics-tune <id>` · `/ai-opponent <id> <difficulty>` · `/perf-check` · `/release-android`
- `Use the physics-reviewer subagent on this diff.` · `Use the ip-checker subagent before release.` · `Use the test-writer subagent for games/<id>/logic.`
- `Update CLAUDE.md so you don't make that mistake again.`
