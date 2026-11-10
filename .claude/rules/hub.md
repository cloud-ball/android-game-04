---
paths:
  - "core/**"
  - "hub/**"
---
- Autoloads: GameRegistry, SceneRouter, SaveService, SettingsService, AudioService, InputKit, CameraKit, Economy,
  Achievements, Ads, IAP, Analytics, Rng. Ads/IAP/Analytics are interfaces with no-op stubs in debug and tests.
- GameRegistry reads games/*/manifest.tres (id, display_name, scene, min_save_version, enabled, unlock_cost).
  Adding a game = a folder + manifest; no hub code changes.
- SaveService: one user://save.json {schema, profile, economy, games:{<id>:{schema,...}}}. Each game owns only its
  namespace with its own schema + migrate(from, to). Unknown game keys are preserved, never deleted.
  Write temp file -> atomic rename -> keep one rolling backup.
- SceneRouter loads with ResourceLoader.load_threaded_request() behind a loading screen and frees the previous game.
- Hub must be <= 2 taps from launch to gameplay.
