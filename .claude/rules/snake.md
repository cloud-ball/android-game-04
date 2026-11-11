---
paths:
  - "games/snake/**"
---
- Pure grid logic in games/snake/logic/; renderer interpolates between ticks and never owns state.
- 2-deep swipe buffer; tick rate from data (start 7 Hz).
- CPU rival: A* to orb + flood-fill safety check; never choose a move flood-fill marks as a trap (tested),
  except on a difficulty's ai_blunder roll (15% Easy, 8% Medium, 2% Hard; user request 2026-11-11); a blunder never
  picks a blocked cell (tested). Tune strength with tools/snake_selfplay.gd.
