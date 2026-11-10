---
paths:
  - "games/blocks/**"
---
- Original falling-block puzzle "Stack Drop": 9x18 crystal tower, gem-shaded pieces, our own audio.
- Never use the words Tetris/tetromino in code, comments, UI or assets. Pieces are "shards" A-G.
- Core is reduce(state, action) with a seeded 7-bag; replays must be bit-exact.
- SRS-style kick tables live in data, with one test per kick case.
