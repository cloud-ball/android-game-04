# Stack Drop: bigger tower (HOLD moves to the top band)

User feedback (2026-11-12, twice): the tower is still too small. At 92 canvas units (36 dp) the cell is
boxed in by the bottom band (HOLD 150 + gap) and the side gutters, not by the phone.

## Change
- Top band, row 2 becomes `CPU | HOLD | NEXT` (HOLD moves from the bottom-left to beside NEXT).
  Row 2 height = max(120, 48 dp) so HOLD stays a 48 dp target on a 360 dp phone.
- Bottom band is now just the pedestal above the gesture keep-out.
- Side gutter 92 -> 66; garbage meter slimmer and closer to the well (24 wide, 36 from the edge).
- Pedestal span 10.4 -> 9.8 cells so it still fits inside the side margins at the larger cell.
- MAX_CELL_DP 38 -> 42.
- Expected on the Vivo (2400 canvas tall, 100 top inset): cell ~100 (39 dp), well ~84% of the width.
- Start hint moves to the middle of the (empty) well; it shows for ~3 s at the start of a match only.
- NEXT previews are laid out left to right after the caption (no longer centred over the spawn columns).
- Two-finger tap still holds, for players who don't want to reach the top.

## Files
games/blocks/logic/board_layout.gd, games/blocks/tests/board_layout_test.gd,
games/blocks/scenes/blocks_hud.gd, games/blocks/scenes/blocks_view.gd (pedestal radius), docs/PROGRESS.md.

## Check
Layout tests (no overlaps, inside canvas, above the gesture area, 48 dp targets, pedestal inside the
margins) on 4 phone shapes; screenshot on the Vivo.
