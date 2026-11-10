---
paths:
  - "games/golf/**"
---
- Flight: RK4 at 240 Hz. Ball 42.67 mm / 45.93 g. Cd 0.27 -> 0.32 above spin ratio 0.1; Cl = 0.54*S^0.4 clamped 0.25;
  spin decay 4%/s; wind = constant offset in the relative velocity.
- Landing hands off to RigidBody3D with continuous_cd = true, or the custom roll model on greens.
- Force sleep below a velocity threshold on slopes; swept raycast for terrain hits at high speed.
