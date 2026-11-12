---
paths:
  - "games/blocks/**"
---
- Original falling-block puzzle "Stack Drop": 12x24 crystal tower (was 9x18, then 10x20; user asked twice for smaller blocks, more of them, 2026-11-12), gem-shaded pieces, our own audio.
- Never use the words Tetris/tetromino in code, comments, UI or assets. Pieces are "shards" A-G.
- Core is reduce(state, action) with a seeded 7-bag; replays must be bit-exact.
- SRS-style kick tables live in data, with one test per kick case.
