---
name: release-android
description: Build a signed AAB and walk through the Play Console closed-testing upload.
disable-model-invocation: true
---
# /release-android
1. Run all tests headless; stop on failure.
2. Bump version code/name in export_presets.cfg.
3. godot --headless --export-release "Android" build/app.aab (keystore path/passwords from environment variables only).
4. Checklist: closed testing track; 12+ testers opted in for 14 continuous days before production (new personal accounts);
   content rating; data safety; privacy policy URL; ads declaration; target API level.
