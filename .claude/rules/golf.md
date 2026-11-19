---
paths:
  - "games/golf/**"
---
- Fairway Flick is ARCADE MINI-GOLF (re-based 2026-11-15, docs/plans/2026-11-15-fairway-flick-minigolf.md):
  walled 20-60 m holes, slingshot shot, Rush races vs CPU. Original name / art / courses only.
- One custom deterministic solver from strike to rest (roll, bounce, walls, bumpers, hops, cup) in pure GDScript under
  games/golf/logic/. No Jolt bodies for gameplay (no determinism guarantee; CPU rollouts must clone state cheaply).
  Research: docs/research/Fairway Flick golf game design.md (2026-11-14; replaces the old Cd-step / Cl-clamp /
  Jolt hand-off plan).
- Ball 42.67 mm / 45.93 g, rho 1.225. Cd = 0.225 + 0.275 * crisis(Re) + 0.18 * (1 - e^-3S^2), crisis = the research logistic (centre Re 8e4)
  tabulated every 5e3;
  Cl = 1.99S - 3.255S^2 to S 0.25 then linear slope 0.3625, no clamp (GolfParams). Spin decay ~0.001 per metre.
- Flight RK4: live 4 x 1/240 s substeps per 60 Hz tick; CPU planner may use 1/60 s flight, 1/120 s roll.
- No pow / exp / sin / cos in the solver hot path: polynomials, tables or precomputed per-step factors
  (cross-device determinism). State in PackedFloat64Array.
- Wind (mini golf, coastal world): a constant per-hole horizontal push on a ball on the ground (spec "wind",
  clamped to MiniBaker.WIND_MAX 0.12 m/s^2; a rolling ball feels 5/7 of it, below the static hold so a resting
  ball never creeps). Airborne hops ignore it. (The old full-golf flight wind is unused.)
- Roll: green decel a = v0^2 / (2 * Stimp) with v0 1.83 m/s (Stimp 10 -> ~0.6 m/s^2); slope pull is (5/7) g sin(theta).
  Rest: speed < 0.03 m/s for 0.25 s and pull (5/7 x (slope + wind) + cup pull) < 1.1 x rolling decel. Cup: offset-dependent capture speed
  (1.31 m/s centred free fall, rim assist to 1.63 m/s).
- Terrain contact: swept test against the hole heightfield at every grid-cell crossing (70 m/s ball must never end
  below the surface).
- Carry tests: within +-5% (driver to 7-iron) and +-8% (wedges) of the research table, plus apex, landing angle,
  symmetry, wind and timestep-invariance tests and a golden-shot hash. Any physics change keeps them green or
  regenerates the golden file with a written justification.
