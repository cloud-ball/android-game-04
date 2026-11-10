---
name: physics-tune
description: Sweep physics parameters headlessly for one game, write a CSV and screenshots, and recommend values that meet the target metrics.
---
# /physics-tune <game>
1. Read the game's rules file for the current constants and target metrics.
2. Write or reuse tools/sweep_<game>.gd that runs the simulation headless over a parameter grid with a fixed seed.
3. Save results to docs/tuning/<game>-<date>.csv and capture 3 screenshots of representative runs.
4. Summarise which values meet the targets (e.g. stop shot within 1 cm; carry within 3%) and propose a change to the
   data/rules file. Ask before applying.
