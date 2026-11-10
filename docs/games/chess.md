# Chess 3D — Chess vs CPU (Phase 1)

Folder: games/chess/ · rules: .claude/rules/chess.md · build estimate: 2–3 weeks · risk: Low physics · licence care
Guide pages: docs/design/PocketArena8_Build_Guide.pdf pp. 13-14. Visual target: docs/refs/chess/keyframe_1..3.png (+ clip.mp4).

## Physics approach
No physics. Bitboard or 0x88 move generator in GDScript (castling, en passant, promotion, threefold repetition, 50-move rule).

## Tuning starting points
| Parameter | Value |
|---|---|
| Validation | perft node counts — perft(start, 4) = 197,281 |
| Engine | negamax alpha-beta, iterative deepening, quiescence, MVV-LVA ordering, transposition table, piece-square tables |
| Expected depth | 3–4 in GDScript within a time budget; move search to a C++ GDExtension later if needed |
| Easy | depth 1, random among top-4 within 150 cp |
| Medium | depth 3 |
| Hard | depth 4–5 + quiescence |

## Rules and modes
Full FIDE rules. Do NOT embed Stockfish: it is GPLv3 (you must ship the licence and full source), and the FSF has said Apple's App Store terms conflict with the GPL. It only works if the whole app is open-sourced under the GPL. Write your own engine; check the licence of any engine you consider.

## CPU opponent
Your own negamax alpha-beta engine; difficulty via depth/time limits plus random choice among the top-k moves within an evaluation margin.

## Controls
Tap a piece then a destination, or drag; legal-move dots; last-move highlight.

## Camera
3D board at ~50° with swipe-orbit, plus a top-down toggle.

## Tests to write first
- perft from the start position and standard test positions.
- Mate-in-1 / mate-in-2 puzzles solved at Medium.
- Engine never returns an illegal move (fuzz 10k random positions).

## Pitfalls
Slow GDScript search on low-end phones — run the search on a thread and cap by time, not depth.

## Scope cut if behind
Ship without the 3D orbit (fixed camera) and with two difficulty levels.

## The 10-second moment (what the concept clip shows)
Tap the knight (legal-move dots appear), drag it to c7 — CHECK, a fork on king and rook. The CPU 'thinks' (depth 3), steps the king away, and the knight leaps to a8; the rook flies off the board — 'ROOK WON', eval +4.8.

## Open questions
_(fill in during planning)_
