---
paths:
  - "games/drive/**"
---
- Vehicle constants live in games/drive/data/vehicle.tres: mass 1200, COM -0.3, stiffness 50, damping 3/4,
  friction_slip 3.0, max_steer 0.6 reduced with speed.
- Missions are data (games/drive/data/missions/*.tres): type, start pose, target pose + tolerances (10 deg, 0.4 m), cones.
- Traffic: Path3D lanes + gap controller; pooled cars, despawn behind camera. Thick colliders on barriers.
