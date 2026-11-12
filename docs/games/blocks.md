# Stack Drop — Original falling-block puzzle vs CPU (Phase 1)

Folder: games/blocks/ · rules: .claude/rules/blocks.md · build estimate: 1.5–2 weeks · risk: Low physics · HIGH legal care
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 11-12. Visual target: docs/refs/blocks/keyframe_1..3.png (+ clip.mp4).

## Physics approach
No physics. A pure functional core reduce(state, action) with a seeded RNG, so any game replays bit-exactly.

## Tuning starting points
| Parameter | Value |
|---|---|
| Rotation | SRS-style wall-kick tables (5 tests per rotation; separate table for the long piece) |
| Randomizer | 7-bag: each of the 7 shards once per shuffled bag |
| Lock delay | 0.5 s with move-reset, capped at 15 resets |
| Assist | ghost piece, hold, 3-piece preview |
| Scoring | 100 / 300 / 500 / 800 × level; level up every 10 lines |
| Touch timing | DAS 170 ms, ARR 50 ms |

## Rules and modes
Original design — mechanics aren't protected, expression is: a 12-wide × 24-tall glass 'crystal tower' (originally 9 × 18; enlarged 2026-11-12 for smaller blocks), physically shaded gem materials instead of flat bright colours, pieces named shards A–G, your own music. Optional twist: the tower slowly rotates around a cylinder.

## CPU opponent
Side-by-side race. Classic placement heuristic (aggregate height, holes, bumpiness, lines cleared) evaluated over all rotations/columns; clears send garbage rows to the opponent.

## Controls
Tap = rotate, horizontal drag = move (DAS/ARR), swipe down = hard drop, two-finger tap = hold.

## Camera
Fixed, slightly tilted view of the tower with a slow orbit; CPU's tower as a mini-view.

## Tests to write first
- 7-bag never repeats a shard within a bag.
- Kick tables: every rotation test case from the spec.
- Replays: same seed + inputs → identical board hash.

## Pitfalls
Never use the 10×20 well with flat bright squares, the trademarked name or '-tris', or the classic folk melody associated with it.

## Scope cut if behind
Drop vs-CPU; ship score-attack only.

## The 10-second moment (what the concept clip shows)
A purple shard is dragged against the glass wall and rotated (WALL KICK), hard-dropped; a long sapphire shard drops into the gap and four rows flash and shatter into crystal fragments — 'QUAD CLEAR', +4 garbage rows hit the CPU's tower.

## Open questions
_(fill in during planning)_
