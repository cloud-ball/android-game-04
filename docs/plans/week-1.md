# Week 1 plan — project skeleton, tooling, CI

Roadmap week 1 (guide p. 28): Godot 4.7 project; CLAUDE.md, rules, skills, hooks, MCP; CI (headless tests +
Android debug export). Off-repo: create the Play Console account and start recruiting 15–20 testers.

No game code this week. Every step ends with a headless check that a script or CI can repeat.

## 0. Toolchain status (checked 2026-11-10 on this Mac)

| Tool | Status | Action |
|---|---|---|
| Godot | 4.7.2.stable at /opt/homebrew/bin/godot (+ /Applications/Godot.app) | `export GODOT=/opt/homebrew/bin/godot` in ~/.zshrc (hooks/tests read `$GODOT`) |
| Export templates | 4.7.2.stable installed (android + ios present) | none |
| JDK 17 | /Library/Java/JavaVirtualMachines/jdk-17.0.5.jdk | `java` on PATH is Android Studio's JBR 21 → point Godot's `export/android/java_sdk_path` at JDK 17 |
| Android SDK | ~/Library/Android/sdk (platforms 34, 36; build-tools 34.0.0, 36.1.0; ndk; platform-tools) | set `export/android/android_sdk_path`; confirm build-tools version Godot 4.7 Gradle build wants |
| Xcode | 26.4.1 | iOS export later (week 12 / TestFlight) |
| jq, node/npx, git | present | none |
| gdtoolkit (gdformat/gdlint) | **missing** | `pipx install "gdtoolkit==4.*"` (or `pip install`) — hooks silently skip lint until installed |
| poppler | **missing** | `brew install poppler` (lets Claude read the PDF in page ranges) |

## 1. Godot project + settings (≤ 3 files → no separate plan needed)

- `project.godot` with: Jolt Physics, 60 physics ticks, physics interpolation on, Mobile renderer
  (Compatibility fallback for GLES3), ETC2/ASTC import, portrait 1080×1920 stretch `canvas_items`/`expand`,
  app name "Pocket Arena 8".
- Empty folder layout from CLAUDE.md: `core/ hub/ shared/{cue_sim,aim_ui,power_meter,ai_common} games/ tests/`
  (`.gdkeep` files so git tracks them).
- Placeholder `hub/hub.tscn` as main scene (a label — real hub is week 2).

**Verify:** `$GODOT --headless --path . --import` exits 0 with no errors;
`$GODOT --headless --path . --quit-after 5` boots the main scene; grep `project.godot` for each setting.

## 2. gdUnit4 + smoke test

- Vendor a pinned gdUnit4 release compatible with 4.7 into `addons/gdUnit4/`, enable the plugin.
- `tests/smoke_test.gd`: asserts the project boots and `ProjectSettings` has Jolt + 60 ticks + Mobile renderer
  (guards against accidental settings regressions).

**Verify:** `./addons/gdUnit4/runtest.sh --godot_binary "$GODOT" -a res://tests` → 1 passing, exit 0.
Then deliberately fail it once to confirm the Stop hook (`.claude/hooks/test_gate.sh`) blocks with exit 2,
and revert. If the runner's flags differ from CLAUDE.md, fix CLAUDE.md.

## 3. Launcher args stub (needed by /shot and CI from week 2)

- `core/Boot.gd` autoload parsing `--game=<id>`, `--shot=<path>`, `--quit-after=<frames>` from
  `OS.get_cmdline_user_args()`; `--shot` saves `get_viewport().get_texture().get_image()` to PNG.

**Verify:** `$GODOT --path . -- --shot=user://shots/boot.png --quit-after 60` writes a PNG (non-headless,
since headless has no renderer); Claude opens it.

## 4. Android debug export

- `export_presets.cfg` with an "Android" preset: Gradle build, arm64-v8a (+ armeabi-v7a), min SDK 24,
  target SDK per Play's current requirement, package `<bundle id — see open questions>`, portrait,
  debug keystore (`~/.android/debug.keystore`, generate with keytool if absent). No secrets in the repo.
- Install the Android build template (`res://android/`, gitignored build output).

**Verify:** `$GODOT --headless --path . --export-debug "Android" build/pocket-arena-8-debug.apk` exits 0;
`adb install -r` on a connected phone (or emulator) and `adb logcat -s godot` shows the boot line.

## 5. CI (GitHub Actions, remote is GitHub)

- `.github/workflows/ci.yml`: on push/PR → set up Godot 4.7.2 + templates, `--import`, run gdUnit4 headless
  (gdUnit4-action), then Android debug export with JDK 17 and upload the APK as an artifact.
- Cache `.godot/imported` and Gradle.

**Verify locally first:** run the same commands in a clean clone (`git clone . /tmp/pa8 && cd /tmp/pa8 && …`).
CI runs only after you push — I won't push without asking.

## 6. Claude Code wiring

- Kit already copied: CLAUDE.md, `.claude/{rules,skills,agents,hooks,settings.json}`, docs, refs (keyframes in
  `docs/refs/<id>/keyframe_{1,2,3}.png`; .mp4 clips intentionally not committed).
- Optional: Godot MCP (`claude mcp add godot -e GODOT_PATH="$GODOT" -- npx @coding-solo/godot-mcp`); copy
  `.mcp.json.example` → `.mcp.json` only if you want it shared in the repo.
- `.gitignore` additions: `android/build/`, `addons/gdUnit4/reports/`, `*.apk`, `*.aab`, `.mcp.json` (if kept local).

**Verify:** start a fresh session and confirm `/new-minigame`, `/shot` etc. are listed and hub.md rule loads when
touching `core/`.

## 7. Off-repo (you)

- Google Play Console personal account ($25) → start recruiting 15–20 testers now; the 14-day/12-tester closed test
  begins ~week 10.
- Apple Developer account ($99/yr) can wait until ~week 11.

## Done when

Tests green headless locally and in CI · debug APK installs and boots on a phone · CLAUDE.md commands all verified ·
docs/PROGRESS.md updated · one commit per numbered step on a `week-1-setup` branch.
