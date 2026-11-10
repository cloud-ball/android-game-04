---
paths:
  - "games/snake/**"
---
- Pure grid logic in games/snake/logic/; renderer interpolates between ticks and never owns state.
- 2-deep swipe buffer; tick rate from data (start 7 Hz).
- CPU rival: A* to orb + flood-fill safety check; never choose a move flood-fill marks as a trap (tested).
