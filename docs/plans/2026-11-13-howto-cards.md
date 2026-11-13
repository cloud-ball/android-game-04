# Animated how-to cards (both games)

Source: docs/research/How to play tutorial videos.md (user chose "animated cards for both games").

## What ships (phase 1)
- A deck replaces GameShell's static 4-row how-to panel: one card per verb, each a looping demo
  drawn live with `_draw` on a stylised mini-board, an original fingertip glyph, a 1-line title and a
  short sub-line. Header: HOW TO PLAY + Skip. Footer: progress dots, Back, Next -> PLAY on the last card.
- Serpent Grid: Swipe to turn · Edges wrap around · Make the CPU crash (vs only).
- Stack Drop: Tap to rotate · Drag to move · Flick down to drop · Tap HOLD to keep ·
  Clear rows, send garbage (vs only).
- Each demo loops 3 times then freezes on its result frame with a Replay chip; tap the stage to
  pause/resume. Cards advance only by buttons (no swipe paging - players copy the gestures).
- PLAY on the last card closes the deck and starts the match (first-launch flow).
- Settings: new "Reduce motion" toggle; with it on, cards show today's static icons (posters).

## Files
- shared/ui/gesture_timeline.gd (pure, tested): glyph pose over a loop (enter 250, anticipate 120,
  action per gesture, hold, exit 200, rest 800 ms; ripple 75/225/150 ms; drag 60 ms move + 100 ms dwell
  per column; flick 120 ms; swipe 200 ms).
- shared/ui/howto_deck.gd: the deck Control (layout, loop/pause/replay, glyph drawing, dots).
- shared/ui/game_shell.gd: uses the deck; howto config becomes a list of card dictionaries.
- games/snake/scenes/snake_howto.gd, games/blocks/scenes/blocks_howto.gd: card lists + demo drawing.
- snake_hud.gd / blocks_hud.gd: configure() with the new cards.
- core/SettingsService.gd, shared/ui/settings_sheet.gd, shared/ui/icon_glyph.gd: Reduce motion.
- core/Boot.gd: --howto=<card> --howto-ms=<t> for screenshots of a card at a fixed time.
- tests: gesture timeline, deck (mode filtering, 3-loop stop, skip/play signals, reduce motion).

## Later (not in this change)
First-match hints (phase 2), "try it" inside cards (phase 3), How to play in the pause menu.
