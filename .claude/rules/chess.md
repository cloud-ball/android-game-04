---
paths:
  - "games/chess/**"
---
- Do NOT add Stockfish or any GPL code. Engine is our own negamax alpha-beta in games/chess/logic/engine.gd.
- perft(start, 4) must equal 197281; keep tests/perft_test.gd green.
- Search runs on a WorkerThreadPool task with a time budget; UI never blocks.
