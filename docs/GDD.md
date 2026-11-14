# Pocket Arena 8 — Game Design Document (hub, v0.1)

> One mobile app (iOS + Android), eight ORIGINAL 3D mini-games, all played solo or against the computer, shipped in three phases.

Source: docs/design/PocketArena8_Build_Guide.pdf. Visual targets: docs/refs/<id>/*.png and docs/refs/hub/*.png.

## Player promise
Two taps from launch to a match; 60–180-second sessions; one soft currency and cosmetics that carry across games; daily challenges rotating across games. Offline, no servers.

## Games
| Phase | Name | Folder | Genre | Build |
|---|---|---|---|---|
| 1 | Break & Bank | games/pool | 8-ball pool vs CPU | 4–5 weeks |
| 1 | Stack Drop | games/blocks | Original falling-block puzzle vs CPU | 1.5–2 weeks |
| 1 | Chess 3D | games/chess | Chess vs CPU | 2–3 weeks |
| 1 | Serpent Grid | games/snake | Snake vs CPU | ~1 week |
| 2 | Carrom Corner | games/carrom | Carrom vs CPU | 2.5–3 weeks (after pool) |
| 2 | Top Corner | games/penalty | Penalty shootout vs CPU | 2–3 weeks |
| 3 | Fairway Flick | games/golf | Golf vs CPU | 4–5 weeks |
| 3 | Park & Pass | games/drive | Original city driving & parking missions | 5–7 weeks |

## Architecture (see .claude/rules/hub.md)
Godot 4.7.x + GDScript + Jolt. Autoloads in core/: GameRegistry, SceneRouter, SaveService, SettingsService, AudioService, InputKit, CameraKit, Economy, Achievements, Ads, IAP, Analytics, Rng. One game loaded at a time. Each game: games/<id>/{logic,scenes,assets,tests} + manifest.tres. Shared deterministic ball/disc solver in shared/cue_sim (pool + carrom + their AI).

## Economy and monetization
Coins earned in every game; cosmetics: cue, striker, ball trail, car paint, chess set, block material. Free with ads + one-time Remove Ads ($2.99–4.99) + rewarded ads (coin doubling, retries) + cosmetic IAP. Interstitials capped (≥ 3 min apart, never mid-match). No loot boxes, no energy timers.

## Budgets
App < 150 MB, each game's assets < 25 MB. Low-end Android: < 100 draw calls, < 150k triangles, 1 directional light, baked/blob shadows, < 150 MB textures, 30 fps floor (60 target on mid-range).

## Legal naming (original names, art, UI, music)
| Inspiration | Our name | Avoid |
|---|---|---|
| Tetris | Stack Drop (Block Cascade, Crystal Tower) | High: trademark + trade dress (brightly coloured blocks, tall rectangular playfield); Tetris Holding v. Xio (D.N.J. 2012) found infringement on look-and-feel |
| 8 Ball Pool (Miniclip) | Break & Bank (was Cue Club - an existing pool series, renamed 2026-11-14; alt. Corner Pocket 3D) | Medium: '8 BALL POOL' is a registered EU/UK mark; the '8 POOL' flame logo is registered in the US |
| Dr. Driving (SUD Inc.) | Park & Pass (City Driver Academy, Lane Master) | Medium: the 'Dr.' series is SUD's brand identity across many titles |
| Carrom, chess, snake, golf, penalties | Carrom Corner, Chess 3D, Serpent Grid, Fairway Flick, Top Corner | Low: generic names |

## Phase 1 roadmap (~12 weeks)
| Week | Deliverable |
|---|---|
| 1 | Godot 4.7 project; CLAUDE.md, rules, skills, hooks, MCP; CI (headless tests + Android debug export). Create the Play Console account and start recruiting 15–20 testers. |
| 2 | Hub shell: GameRegistry, SceneRouter, SaveService v1 with migrations, Settings, Audio, InputKit, CameraKit. |
| 3 | Serpent Grid (logic, 3D render, CPU rival). |
| 4–5 | Stack Drop (reducer, kicks, bag, 3D tower, DAS/ARR, CPU rival). |
| 6–7 | Chess 3D (movegen + perft, engine, difficulty, 3D board). |
| 8–10 | shared/cue_sim + tests → Break & Bank table, rules, touch UI, CPU. Start the Play closed test at week 10 with a pool-less build so the 14-day clock overlaps development. |
| 11 | Economy (coins, cosmetic skins), rewarded ads + interstitial cap, remove-ads IAP, achievements; perf pass on a low-end Android phone. |
| 12 | Closed test continues; TestFlight beta; store assets; submit v1.0. |

Phase 2 (~6 weeks): Carrom Corner + Top Corner + daily challenges (v1.1). Phase 3 (~10 weeks): Fairway Flick + Park & Pass (v1.2).
