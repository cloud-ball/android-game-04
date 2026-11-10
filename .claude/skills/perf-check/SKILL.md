---
name: perf-check
description: Export a release build, run the benchmark scene on a connected Android device and report frame time, draw calls and memory against budget.
disable-model-invocation: true
---
# /perf-check
1. ./addons/gdUnit4/runtest.sh first; stop on failure.
2. Export release AAB/APK; adb install; launch the benchmark scene with --bench and capture the log.
3. Report against budget: 60 fps mid-range / 30 fps floor; < 100 draw calls; < 150k visible triangles;
   texture memory < 150 MB; one directional light; no real-time GI.
4. List the top 3 offenders and propose fixes.
