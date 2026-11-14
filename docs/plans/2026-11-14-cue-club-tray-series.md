# Cue Club: ball tray + best of 3 (2026-11-14)

Source: docs/research/Cue Club versus mobile pool games.md, priority 10 (potted-ball tray with a
fly-in, end-of-rack card with stats) and "race-to-2/3 frames". The rematch already exists.

## What changes
1. **Tray (top bar).** Each player's row always shows the 7 balls of their group plus the 8.
   Still to pot = bright; potted = dimmed; the 8 is dim until it becomes the target (gold ring).
   A potted ball's slot pulses (expanding ring, 0.5 s) as it dims. (Built first as a fly-in from
   the pocket; dropped after phone feedback - it crossed the whole table mid-shot.)
2. **Best of 3.** A second mode on the start screen: "Single rack" / "Best of 3". Breaks alternate
   by frame. Between frames: a banner (frame winner, score, who breaks next), then the next rack.
   Frame pips next to each group label. Coins and daily challenge are reported once per match;
   a best-of-3 win pays double.
3. **End card.** Potted, best run (consecutive potting shots) and pot rate, plus frames for best
   of 3.

## Code
- `games/pool/logic/pool_series.gd` (new, pure): frames to win, frame score, breaker per frame,
  per-player shots / potting shots / balls / current and best run. Unit tested.
- `games/pool/scenes/pool_game.gd`: series flow, fly-in triggers from the solver's POCKET events,
  end card stats; save schema 1 -> 2 adds `mode` (migrate keeps everything else).
- `games/pool/scenes/pool_hud.gd`: tray drawing, pips, fly layer, modes.
- Tests: `games/pool/tests/pool_series_test.gd`, migrate test.

## Not in scope
Practice mode, stats screen, guide-length setting (later items in the research list).
