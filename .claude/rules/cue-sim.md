---
paths:
  - "shared/cue_sim/**"
  - "games/pool/**"
  - "games/carrom/**"
---
- Solver is deterministic: fixed 1/240 s substeps, swept-circle time-of-impact, process collisions in time order.
- Pool defaults: mu_slide 0.2, mu_roll 0.012, e_ball 0.93, mu_ball 0.055, e_cushion 0.85. Carrom: disc mode, no rolling
  phase, mu_k 0.1, e_disc 0.8, e_rail 0.65, striker mass 2.7x coin.
- Any change must keep tests/golden_break_test.gd passing or update the golden file with a written justification.
- AI shot search calls the same solver headlessly; budget 150 ms spread across frames.
