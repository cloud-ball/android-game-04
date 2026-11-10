# Serpent Grid — Snake vs CPU (Phase 1)

Folder: games/snake/ · rules: .claude/rules/snake.md · build estimate: ~1 week · risk: Low
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 15-16. Visual target: docs/refs/snake/keyframe_1..3.png (+ clip.mp4).

## Physics approach
No physics. Discrete grid logic (e.g., 12×18 or 20×20) rendered as 3D blocks on a floating board, smoothly interpolated between ticks.

## Tuning starting points
| Parameter | Value |
|---|---|
| Tick rate | starts ~7 Hz, rises with length |
| Input | swipe to turn, 2-deep input buffer so quick double swipes register |
| Camera | tilted ~55° |
| Optional mode | board wrapped around a cube |

## Rules and modes
Eat orbs to grow; hitting a wall, yourself or the rival ends a run. Vs-CPU: first to crash loses.

## CPU opponent
Rival snake: A* to the nearest orb, rejected if a flood-fill shows it would trap itself (safety check).

## Controls
Swipe anywhere to turn.

## Camera
Fixed tilted view of the whole board.

## Tests to write first
- Pure-logic tests: collision, growth, input buffer, wrap mode.
- AI never chooses a move that flood-fill marks as a trap.

## Pitfalls
Interpolating rendering at a different rate from logic ticks; dropped swipes without the buffer.

## Scope cut if behind
Score-attack only (no rival).

## The 10-second moment (what the concept clip shows)
A glowing green snake turns with swipes across a floating neon grid, eats two orbs and grows; the magenta CPU snake loops below, misjudges a turn and crashes into your tail — 'RIVAL CRASHED!'.

## Open questions
_(fill in during planning)_
