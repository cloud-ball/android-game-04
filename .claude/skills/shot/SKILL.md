---
name: shot
description: Capture screenshots of a game from three camera presets so Claude can inspect the 3D output.
---
# /shot <game>
Run: godot --path . -- --game=<game> --shot=user://shots/<game>_%d.png --shot-presets=3 --quit-after 300
(use xvfb-run on Linux). Open each PNG and check: framing on a 9:16 phone, readable HUD, nothing under the notch,
lighting/shadows, z-fighting, consistent palette with docs/refs/<game>/.
