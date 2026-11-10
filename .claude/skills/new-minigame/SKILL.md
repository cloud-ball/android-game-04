---
name: new-minigame
description: Scaffold a new mini-game folder (manifest, logic, scene, tests, rules stub, save namespace) behind a disabled feature flag.
---
# /new-minigame <id>
1. Read CLAUDE.md, docs/GDD.md and docs/games/<id>.md.
2. Create games/<id>/{logic,scenes,assets,tests} and games/<id>/manifest.tres (id, display_name from the doc, scene path,
   min_save_version=1, enabled=false, unlock_cost).
3. Add a pure logic class with one passing smoke test; add a scene that boots and renders a placeholder.
4. Add the save namespace { "schema": 1 } with a migrate() stub and a test that an old save without this key loads.
5. If .claude/rules/<id>.md is missing, create a stub with the paths: filter.
6. Run the unit tests headless, then capture /shot <id>. Update docs/PROGRESS.md.
