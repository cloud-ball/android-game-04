# Project: Pocket Arena 8 — 3D mini-game hub (Godot 4.7.x, GDScript, Jolt)

## Golden rules
- Every game is an ORIGINAL design described by mechanics/genre. Never name, copy, or imitate a
  specific commercial game's name, logo, UI layout, art, or music. Display names live in games/*/manifest.tres.
- Mobile first: 60 fps target on mid-range, 30 fps floor on low-end Android; touch only.
- Game logic lives in pure GDScript classes (no Node dependencies) under games/<id>/logic/ and is unit tested.
- Simulation uses fixed timesteps and seeded Rng (core/Rng.gd). Never call randf() directly.
  Never scale physics by render delta.
- One game loaded at a time via SceneRouter. Games talk to the hub only through core/ autoloads.
- Save data: only write to SaveService.games[<id>]; bump that game's schema + add migrate() for any change.

## Commands
- Import:      godot --headless --path . --import
- Unit tests:  ./addons/gdUnit4/runtest.sh --godot_binary "$GODOT" --headless --ignoreHeadlessMode -a res://tests -a res://games
- Run a game:  godot --path . -- --game=<id>
- Screenshot:  godot --path . -- --game=<id> --shot=user://shots/<id>.png --quit-after 300   (xvfb-run on Linux CI)
- Export:      godot --headless --export-release "Android" build/app.aab

## Structure
core/ autoload services · hub/ launcher, shop, settings · shared/cue_sim deterministic disc/ball solver ·
shared/{aim_ui,power_meter,ai_common} · games/<id>/{logic,scenes,assets,tests} · ids: pool carrom golf penalty snake blocks chess drive

## Definition of done (every task)
1. Tests added/updated and green headless. 2. No new warnings in debug output.
3. Screenshot captured for visual changes and inspected. 4. No new per-frame allocations in _physics_process.
5. docs/PROGRESS.md updated (what changed, how to try it on a phone).

## Workflow
- Plan mode for any task touching >3 files or a new game; write the plan to docs/plans/<date>-<topic>.md.
- Small commits; one game per branch. Unfinished games stay behind enabled=false in manifest.tres.
- Design sources: docs/GDD.md (hub) and docs/games/<id>.md (per game). Visual targets: docs/refs/<id>/*.png
  (docs/refs/*/prototype.html are throwaway three.js mocks — never port their code).
