---
paths:
  - "games/blocks/**"
---
- Original falling-block puzzle "Facetfall" (renamed from Stack Drop 2026-11-17: name taken on Play, look-alike risk): 12x24 crystal tower (was 9x18, then 10x20; user asked twice for smaller blocks, more of them, 2026-11-12), emerald-cut gem pieces in a jewel palette unlike the classic colours (BlocksView.GEM_COLORS, GemArt), no grid in the well, our own audio. Never go back to flat bright squares.
- Never use the words Tetris/tetromino in code, comments, UI or assets. Pieces are "shards" A-G.
- Core is reduce(state, action) with a seeded 7-bag; replays must be bit-exact.
- SRS-style kick tables live in data, with one test per kick case.
