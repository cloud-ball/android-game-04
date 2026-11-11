# Stack Drop plan (2026-11-11)

Original falling-block puzzle (see docs/games/blocks.md, .claude/rules/blocks.md). Stays behind
`enabled = false` in games/blocks/manifest.tres until playable and verified on the phone.

## Design decisions
- Tower: 9 wide x 18 visible rows (+2 hidden spawn rows). Glass "crystal tower" with gem-shaded,
  lit cubes (amethyst, sapphire, emerald, topaz, ruby, aquamarine, rose quartz) — not flat colours.
- Shards A-G (A = long 4, B = square, C = tee, D/E = skews, F/G = hooks). Names never use the
  trademarked words. SRS-style rotation + wall kicks (5 tests; separate long-shard table) in
  games/blocks/data/kicks.json.
- 7-bag randomizer on our own seeded integer RNG (state copies with the board -> bit-exact replays).
- Gravity: rows/s = 1.0 + 0.55 * (level - 1), capped 20. Lock delay 0.5 s, move-reset cap 15.
- Scoring 100/300/500/800 x level; level up every 10 lines. Soft drop +1/row, hard drop +2/row.
- Garbage (vs CPU): clears of 2/3/4 lines send 1/2/4 rows, applied when the receiver next locks;
  each garbage row has one gap. Top-out = lose.
- Modes: vs CPU race (first to top out loses) and Solo score attack. Easy/Medium/Hard = gravity
  start + CPU think time + CPU placement noise.

## Code layout
- logic/shard_data.gd   shapes per rotation, kick tables loaded from data/kicks.json
- logic/stack_state.gd  StackState (board, piece, bag, rng, hold, queue, score...) + duplicate()
- logic/stack_logic.gd  static reduce(state, action) -> new state; actions are dictionaries
- logic/stack_ai.gd     placement search (all rotations x columns, + hold) with a classic heuristic
- scenes/               3D tower view, HUD/overlays, controller (physics interpolation OFF)

## Steps (each ends green headless; device check at the end)
1. Logic + tests: bag, kicks (data + behaviour), movement, gravity, lock delay/resets, clears,
   scoring, hold, garbage, top-out, bit-exact replay.
2. 3D view + touch controls (tap rotate, drag move, swipe-down hard drop, 2-finger tap hold) + HUD.
3. CPU rival + garbage exchange + modes/difficulty + results/saves/coins/daily challenges.
4. Polish (clear shatter, banners, music variant), perf check on the Vivo, enable in manifest.
