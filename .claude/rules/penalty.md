---
paths:
  - "games/penalty/**"
---
- Ball 0.22 m / 0.43 kg. Cd blends 0.45 -> 0.2 across 15-20 m/s. Magnus side coefficient 0.25 (x1.5 for fun).
- Keeper table (reaction ms / reach error m): Easy 320/0.5, Medium 220/0.3, Hard 150/0.15 + 30% early guess.
- After any contact the ball becomes a RigidBody3D; net panels are low-restitution StaticBody3D.
