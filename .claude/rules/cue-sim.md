---
paths:
  - "shared/cue_sim/**"
  - "games/pool/**"
  - "games/carrom/**"
---
- Solver is deterministic: fixed 1/240 s substeps, swept-circle time-of-impact, process collisions in time order.
- Pool defaults: mu_slide 0.2, mu_roll 0.010 (rolling decel = mu_roll * g, no 5/7), spin decel 10.9 rad/s^2,
  e_ball 0.93, mu_ball 0.055, e_cushion 0.95, mu_cushion 0.2, Han 2005 sin(theta) 0.27; 7-ft table, casual
  pockets 12.7 / 14.0 cm (tuned 2026-11-14 to pass the WPA rail test; see the comparison research). Carrom: disc mode, no rolling
  phase, mu_k 0.1, e_disc 0.8, e_rail 0.65, striker mass 2.7x coin.
- Any change must keep tests/golden_break_test.gd passing or update the golden file with a written justification.
- State in PackedFloat64Array (Vector2/3 are 32-bit); no sin/cos/exp in the hot path (cross-platform determinism).
- AI shot search calls the same solver headlessly on worker threads (1/120 s planning step allowed); budget
  1-3 s of visible thinking, not 150 ms (GDScript rollouts cost ~35-130 ms each on the phone; measure).
