# Animated how-to-play demos in Godot 4.7 (Android): technical routes and production pipelines

Scope: Pocket Arena 8 (Godot 4.7.2, GDScript, Mobile renderer, Android min API 24, portrait 1080-wide canvas_items stretch;
test phone Vivo V2250 / Adreno 642L). Games in scope: blocks (Stack Drop, `StackLogic.reduce`) and snake (`SnakeLogic`, fixed ticks).
Current how-to panel: `shared/ui/game_shell.gd::_build_howto()` builds rows of 150x150 `Control`s whose `draw` signal calls a
per-step `Callable` (static drawn icons) plus title/subtitle labels.

Local measurements in this file were made on 2026-11-13 with Godot 4.7.2.stable.official.ed1daf0bf (macOS, Metal, Forward Mobile, M1 Pro)
against this repo at commit 08da76d. Commands are given so they can be re-run. They are cited as "Local measurement".

---

## 1. VideoStreamPlayer + Ogg Theora in Godot 4.x (4.3 to 4.7)

### Takeaway
Theora (.ogv, optional Vorbis audio) is still the only core video codec in Godot 4.7; it is CPU-decoded, so on Android it works but costs CPU
per frame, and the docs say to stay at 720p-or-less and 30 fps-or-less on mobile. A burst of fixes landed in 4.4 to 4.5 (frame timing,
YUV 4:2:2/4:4:4 conversion, seeking/length), which makes 4.3-era Android horror stories mostly outdated; small looping muted clips
(540-720 px square, 30 fps or less) are the realistic sweet spot.

### Cited Findings
- 4.7 docs: "The only supported format in core is Ogg Theora" (+ optional Ogg Vorbis audio); extensions may add formats; H.264/H.265 can't be
  in core because of software patents; AV1 is royalty-free but "slow to decode on the CPU" and hardware decoding isn't widely available;
  WebM was supported in 3.x and **removed in 4.0** — [Playing videos (4.7 stable)](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- 4.7 docs: decoding is done on the CPU (GPUs have no Theora hardware acceleration). Desktop CPUs can decode 1440p @ 60 fps or more, but
  "low-end mobile CPUs will likely struggle with high-resolution videos". Recommendation: mobile/web at **720p max, preferably 30 fps or lower**;
  desktop 1080p max, preferably 30 fps — [Playing videos (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- 4.7 docs, looping: enable **Loop** on VideoStreamPlayer; a non-zero **Video Delay Compensation** can cause missed frames at each loop, so set it to 0 —
  [Playing videos (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- 4.7 docs, limitations: no streaming from URL; only mono/stereo audio (surround is down-mixed). The page does not document alpha in video;
  its only transparency route is a chroma-key shader that removes a key colour — [Playing videos (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- 4.7 docs, ffmpeg recipe (verbatim): `ffmpeg -i input.mp4 -q:v 6 -q:a 6 -g:v 64 output.ogv`; scaled: `ffmpeg -i input.mp4 -vf "scale=-1:720" -q:v 6 -q:a 6 -g:v 64 output.ogv`.
  `-q:v` 1-10 (6 = compromise, 5 for 1440p/4K); `-q:a` -1..10 (higher costs more decoder CPU); default GOP 12 is "too low", 64-512 compresses best;
  GOP above a power of two (e.g. 65 vs 64) can nearly double seek time; use recent ffmpeg builds (older releases have Ogg/Theora muxer bugs).
  The page gives **no bitrate or file-size numbers** — [Playing videos (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- Bug: in 4.3.stable, Theora frames were shown at the wrong times (frames held/frozen, banding); workaround was keyframe interval 1 at a big
  size cost ("takes away a lot of the compression benefits"). Closed 2025-02-17 by PR #101958, milestone **4.4** —
  [godot#101837](https://github.com/godotengine/godot/issues/101837)
- PR #101958 ("Fix Theora video issues", berarma) reworked the decoded-frame path and calls the 4:4:4/4:2:2/4:2:0 converters directly; a follow-up
  PR #102859 "Theora: Fix YUV422/444 to RGB conversion"; a May 2025 commit "Full Theora video support in VideoStreamPlayer" implemented
  `set_stream_position` and `get_stream_length` (seeking). Seen on a third-party mirror, not verified on github.com —
  [mirror commit 032cec5](https://remotebranch.eu/Stowage/godot/commit/032cec51a7faa92d0574a1b78b53536f04c02ad7);
  [mirror commit b9bebf7](https://remotebranch.eu/Stowage/godot/commit/b9bebf708197e17ea94b7fc91f5251e082f6235f)
- Older/unfixed reports (treat as historical): VideoPlayer looping left a black frame / stutter between loops (Godot 2/3 era) —
  [godot#6179](https://github.com/godotengine/godot/issues/6179); 2021 forum thread "Playing a video on Android - mission impossible?" (WebM, Godot 3 —
  **outdated, pre-4.0**) — [forum](https://forum.godotengine.org/t/playing-a-video-on-android-mission-impossible/11720); 4.3 macOS report of a frame-time
  micro-stutter whenever a VideoStreamPlayer is instantiated or a new stream loaded, no fix confirmed —
  [forum](https://forum.godotengine.org/t/optimized-video-workflow-for-macos-stuttering-on-video-stream-player-initialization/133611)
- GodotFest 2025 talk (Nils Zweiling, 2025-11-11) still describes core playback as "constrained by the outdated Ogg/Theora codec": lower
  compression efficiency, no hardware decoding/zero-copy, streams not usable directly as textures —
  [From Theora to AV1 (media.ccc.de)](https://app.media.ccc.de/v/godotfest2025-from-theora-to-av1-transforming-video-workflows-in-godot-4)
- **Other codecs via GDExtension (none in core as of 4.7):**
  - "Video Toolkit for Godot" (VTG): open-source GDExtension aiming at AV1 software decoding baseline, avoids libffmpeg; "early development",
    prototype only (Nov 2025) — [talk page](https://app.media.ccc.de/v/godotfest2025-from-theora-to-av1-transforming-video-workflows-in-godot-4)
  - GDE GoZen (Voylin, FFmpeg-based, paid on itch, source on Codeberg): "works with Linux, Windows, Android and MacOS"; no iOS/Web; arm32 Android
    planned; latest build "made with 4.6 in mind"; download zip listed at **148 MB**; AV1 support being disabled in next update; no numeric perf claims —
    [itch.io page](https://voylin.itch.io/gde-gozen-video-playback-addon-for-godot)
  - gd-hwvideo: FFmpeg-based, hardware backends VideoToolbox/VAAPI + software, Godot 4.5+; no Android/MediaCodec backend mentioned —
    [codeberg](https://codeberg.org/gllm/gd-hwvideo) (via search snippet)
  - elly_videoplayer: FFmpeg wrapper GDExtension, README says no hardware acceleration — [github](https://github.com/Elly2018/elly_videoplayer)
- **Local measurement (Movie Maker OGV, Godot 4.7.2 default writer settings, video quality 0.75):** 432x864, 30 fps, 12 s (360 frames), real bot
  gameplay incl. audio track: blocks = **1,168,972 B (~0.78 Mbit/s)**, snake = **2,035,490 B (~1.36 Mbit/s)**. Command:
  `godot --path . --write-movie <out>.ogv --fixed-fps 30 --resolution 540x1200 --quit-after 360 -- --game=<id> --bot --autostart --mode=solo --seed=7`

### Inferences
- Size estimate for a demo clip (scaling the local bitrates by pixel area, which is crude; Theora bitrate is not linear in area and
  stylised flat-colour content compresses well): a 6 s 540x540 30 fps clip ≈ 0.45 MB (blocks-like) to 0.8 MB (snake-like); 720x720 ≈ 0.6 to 1.1 MB.
  Dropping the audio track, lowering to 24 fps, using `-q:v 5` and GOP 64-128 should push these lower. Two games x 1 clip each ≈ 1-2 MB of AAB;
  8 games ≈ 4-8 MB. Note .ogv is already compressed, so the APK zip layer won't shrink it further.
- Runtime memory: the video texture is one RGBA frame (540x540x4 ≈ 1.2 MB; 720x720 ≈ 2.1 MB) plus decoder buffers (a few YUV frames); small.
  The main cost is CPU: one Theora decode + CPU YUV→RGB + texture upload per video frame on the main/decoder thread. At 540x540@30 this is
  very likely fine on an Adreno 642L-class SoC (Snapdragon 778G), but there are **no published Android benchmarks** — measure with `--fps` on the V2250.
- Avoid alpha video: Theora has no alpha; design the demo with an opaque background matching the panel, or use a chroma-key shader (adds edge fringing).
- Theora module ships in the default Android export template, so using it adds no code size; conversely a custom template that disables
  `module_theora` could save a bit if video is not used (not measured).
- A 4.3-era bug (#101837) means: **do not test on 4.3 builds**; the project is on 4.7.2, which includes the 4.4/4.5 fixes.

### Gaps
- No primary-source Android benchmark (decode ms/frame, CPU %, battery) for Theora in Godot 4.4-4.7 found. Needs on-device measurement.
- Could not verify on github.com the exact PR numbers/versions of the seeking commit and the OGV MovieWriter commit (seen on a mirror only).
- Did not obtain the ffmpeg libtheora option table (page truncated); exact `-q:v` 0-10 → libtheora quality 0-63 mapping not confirmed.
- No confirmed 4.7 report of Android-specific Theora bugs (searched GitHub/forum; only pre-4.4 or non-Android results).

---

## 2. Godot Movie Maker mode → .ogv production pipeline

### Takeaway
Movie Maker (`--write-movie`) renders non-real-time at a fixed fps with perfect pacing, and since 4.5 it can write **.ogv directly**
(editor builds only), which plays as-is in VideoStreamPlayer. Combined with Boot's existing `--game --bot --autostart --seed`, this repo can
already produce a deterministic demo clip in about 5 seconds of wall time per game with zero new code; cropping to a square needs either ffmpeg
or a dedicated demo scene.

### Cited Findings
- Enable via editor "movie reel" button, `movie_file` metadata on the root, or CLI: `godot --path <proj> --write-movie output.avi`;
  `--resolution 1280x720`, `--fixed-fps 30`, `--quit-after N` (frames); `--write-movie`/`--fixed-fps` also work in exported projects —
  [Creating movies (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html)
- Output writers in 4.7: **OGV (recommended)** Theora+Vorbis, *recording editor-only*, playback in editor and export builds, no transparency;
  **AVI** MJPEG + PCM, 4 GB cap, no transparency; **PNG sequence** + WAV, transparency if root viewport `transparent_bg` (Rendering > Transparent Background);
  custom MovieWriter via GDExtension — [Creating movies (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html)
- OGV writer settings: Video Quality 0.01-1.0 (recommended 0.75-0.9), Audio Quality -0.1-1.0 (0.3-0.5), four Encoding Speed levels
  (fastest ≈ AVI speed but compresses better), Keyframe Interval; Mix Rate must be divisible by fps to avoid audio drift —
  [Creating movies (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html); [Créer des films (4.5)](https://docs.godotengine.org/fr/4.5/tutorials/animation/creating_movies.html)
- OGV MovieWriter commit "Add Ogg Theora support to MovieWriter" dated 2025-06-10, present in the 4.5.1-stable tree (mirror) → available from **4.5** —
  [4.5.1 tree, servers/movie_writer (mirror)](https://remotebranch.eu/Stowage/godot/src/tag/4.5.1-stable/servers/movie_writer)
- Recording is non-real-time: output always has perfect frame pacing; you can render above target fps and blend (`tmix`) for motion blur —
  [Creating movies (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html)
- Output size = window size for `disabled`/`canvas_items` stretch; window size is clamped to display; the **`movie` feature tag** can apply
  window/viewport overrides only while recording; stop cleanly via window close or `get_tree().quit()` (Ctrl+C/F8 can corrupt AVI/WAV) —
  [Creating movies (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html)
- The docs do **not** describe capturing only a SubViewport or a region; whole root viewport only —
  [Creating movies (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html)
- Docs' ffmpeg post-processing examples (target MP4/WebM, but same filters apply): PNG+WAV → `ffmpeg -r 60 -i input%08d.png -i input.wav -crf 15 output.mp4`;
  cut `-ss 00:00:12.10 -t 00:00:05.20`; resize `-vf "scale=-1:1080"`; fps `-r 30`; motion blur `-vf "tmix=frames=4, fps=60"`; combine filters into one pass
  to avoid repeated lossy encodes — [Creating movies (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html)
- **Local measurement:** requesting `--resolution 540x1200` produced **432x864** because project.godot sets `window/size/window_width_override=432`,
  `window_height_override=864`. 360 frames OGV recorded in ~5.4 s wall (240% real-time), encode avg 2.5-2.9 ms/frame; PNG sequence of 120 frames
  = **6.4 MB (~53 KB/frame)** + WAV, encode 9.7 ms/frame. Godot printed "3 ObjectDB instances were leaked at exit" (pre-existing warning, unrelated).
  Frame 100 of the PNG run showed live gameplay with the "GO" countdown overlay and HUD (HOLD/NEXT) — i.e. the full game UI is captured.

### Inferences
- Concrete pipeline A (zero new engine code, full-screen capture then crop):
  1. `godot --path . --write-movie /tmp/demo/f.png --fixed-fps 30 --quit-after 330 -- --game=blocks --bot --autostart --mode=solo --seed=<curated>`
     (add `window/size/window_width_override.movie=1080` / `window_height_override.movie=1920` in project.godot, or a `--resolution` the display can hold, to get crisp 1080-wide frames).
  2. `ffmpeg -framerate 30 -start_number 60 -i /tmp/demo/f%08d.png -vf "crop=720:720:180:500,scale=540:540:flags=lanczos,fps=24" -an -c:v libtheora -q:v 6 -g:v 64 games/blocks/assets/howto.ogv`
     (skip countdown frames via `-start_number`, crop to the well, drop audio).
  3. Optionally make the loop seamless: pick a seed/segment that starts and ends on an empty or similar board, or crossfade the last 0.3 s with `xfade`.
- Pipeline B (cleaner): a dedicated `demo.tscn` per game that hides HUD/overlays, renders only the board at the demo aspect, and is driven by a
  scripted action list; recorded straight to .ogv with `--write-movie games/<id>/assets/howto.ogv` (OGV writer, no ffmpeg needed). Set
  `editor/movie_writer/video_quality` ~0.6-0.75 and keyframe interval 64 in a `.movie`-tagged override.
- Movie Maker needs an editor build and a display (macOS fine; Linux CI needs xvfb-run, as the existing screenshot command already assumes).
- Caveat: callouts/finger sprites/text in the clip must be localised per language; burned-in text multiplies clip count. Prefer text in the panel, not the video.

### Gaps
- Exact `.movie` feature-tag syntax for window overrides was not tested here.
- Not measured: OGV file size at Movie Maker video_quality 0.5/0.6 vs 0.75, or with audio disabled (ffmpeg not installed on this machine).

---

## 3. Live in-engine demos (SubViewport replay) vs stylised 2D drawn demos

### Takeaway
Because rules are pure and deterministic, a live demo can replay a curated (seed, action list) through the real logic and render it with the
real view inside a small SubViewport (or a cheaper stylised 2D `_draw` board in the existing 150x150 icon slots). This costs no APK size,
always matches current visuals and rules, and scales by resolution — but it adds a second render pass on the GPU and is the most code;
there are no published mobile numbers for SubViewport cost, so it must be profiled on the V2250.

### Cited Findings
- SubViewport API (4.7): `size` (default 512x512, must be ≥2 px), `size_2d_override`, `render_target_update_mode` = UPDATE_DISABLED / UPDATE_ONCE /
  **UPDATE_WHEN_VISIBLE (default)** / UPDATE_WHEN_PARENT_VISIBLE / UPDATE_ALWAYS; `render_target_clear_mode` ALWAYS/NEVER/ONCE —
  [SubViewport (4.7)](https://docs.godotengine.org/en/stable/classes/class_subviewport.html)
- Viewport base-class properties relevant here (`own_world_3d`, `transparent_bg`, `msaa_3d`, `scaling_3d_scale`, `use_hdr_2d`) exist in the Godot 4
  Viewport API; this session did not re-fetch their doc text — [Viewport class](https://docs.godotengine.org/en/stable/classes/class_viewport.html)
- Repo: both views already render via a Camera3D + MultiMesh (`games/blocks/scenes/blocks_view.gd` `_locked: MultiMesh`;
  `games/snake/scenes/snake_view.gd` `_snake_mm: Array[MultiMesh]`, `camera.keep_aspect = KEEP_WIDTH`); blocks AI exposes
  `StackAI.choose(...)` and `StackAI.actions_for(state, plan) -> Array[Dictionary]`; snake AI `SnakeAI.choose(...)` — local repo
  (`games/blocks/logic/stack_ai.gd`, `games/snake/logic/snake_ai.gd`)
- Repo: project uses `physics/common/physics_ticks_per_second=60`, `physics_interpolation=true`, Mobile renderer; CLAUDE.md requires
  `physics_interpolation_mode = OFF` on roots of games that move nodes in `_process` (snake, blocks) — `project.godot`, `CLAUDE.md`

### Inferences
- Implementation sketch (live 3D): `SubViewportContainer(stretch=true)` → `SubViewport(size 540x540, own_world_3d=true, transparent_bg=false,
  msaa_3d=disabled, render_target_update_mode=WHEN_PARENT_VISIBLE)` → instance of the game's view node. A `DemoPlayer` (pure GDScript, no Node deps
  for the stepping part) holds `{seed, actions:[{tick, action}], loop_ticks}`; on each fixed tick it applies due actions via `StackLogic.reduce`
  (or `SnakeLogic` step) and pushes the state to the view; at `loop_ticks` it resets from seed. `own_world_3d` is needed so the demo's
  lights/environment/camera don't collide with anything else; set `physics_interpolation_mode = OFF` on the demo root (CLAUDE.md rule).
- Cost model: a 540x540 RGBA8 colour target ≈ 1.2 MB VRAM (+ depth); the Mobile renderer does a full extra render pass setup per viewport
  per frame. With MultiMesh boards (a few hundred instances), GPU cost should be small vs the main game, but the how-to panel is shown when the main
  game is paused under it, so it is a second scene rendering on top of a (paused but still drawn) 3D game. Rendering the demo at 30 Hz (toggle
  `render_target_update_mode` every other frame or run the demo tick at 15/30 Hz) halves the cost. One live demo at a time is the safe budget;
  four simultaneous 3D SubViewports (one per how-to row) is not advisable without profiling.
- Cheaper live variant: stylised 2D demos in the existing 150x150 (or a larger 600x600) `Control._draw` slot, driven by the same logic state
  (draw cells as rounded rects, snake as polyline) and `queue_redraw()` on each demo tick. Zero extra viewport, ~0 VRAM, reuses `howto_steps`
  draw-callable architecture; add a finger/tap glyph animated with a Tween to show the input. Probably the best effort/value for 4-row panels;
  a single larger 3D SubViewport is better for a "watch a 6 s round" hero demo.
- Live demos have zero APK cost, no decode stutter, perfect resolution scaling, automatic re-skin when art changes, and can be localised trivially
  (text is separate). Downsides: most code; demo can silently break when rules change (see section 6); first-frame latency includes view setup
  (blocks/snake `[load]` printed 122 ms load + 81 ms to first frames for the whole game in the local run).

### Gaps
- No published benchmark of SubViewport 3D cost on Godot 4.x Mobile renderer / Adreno found; needs on-device profiling (`--fps`, Android GPU Inspector).
- Unverified whether `UPDATE_WHEN_PARENT_VISIBLE` correctly pauses rendering when the GameShell overlay hides (should, per docs; test).

---

## 4. Sprite sheets / AnimatedTexture / GIF-APNG / Lottie

### Takeaway
AnimatedTexture is **deprecated** in 4.7 ("does not work properly"); use AnimatedSprite2D/SpriteFrames or a shader on an atlas instead. Lottie
has **no core support in Godot 4.4-4.7**: the ThorVG-based Lottie importer PR (#91580) is still open and bakes to SpriteFrames anyway, and the one
community runtime plugin reportedly fails on Android. Full-frame sprite sheets are memory-hungry for 5-8 s demos, so they suit only tiny icon loops.

### Cited Findings
- AnimatedTexture (4.7 docs): deprecated — "This class does not work properly in current versions and may be removed in the future. There is currently
  no equivalent workaround"; "not efficient for the modern renderers"; MAX_FRAMES = 256; for more frames use AnimationPlayer or AnimatedSprite2D —
  [AnimatedTexture (4.7)](https://docs.godotengine.org/en/stable/classes/class_animatedtexture.html)
- Lottie importer PR #91580: uses ThorVG to pre-render Lottie into frames; originally a sprite-sheet CompressedTexture, since 2025-09-04 imports as
  **SpriteFrames** for AnimatedSprite2D; "editor only feature and doesn't implement real time rendering"; status **open**, milestone "4.x";
  dotLottie support removed; Calinou noted baked frames aren't crisp when zoomed and 60 fps would use a lot of memory —
  [godot#91580](https://github.com/godotengine/godot/pull/91580)
- ThorVG is Godot's vector renderer (SVG import) and treats Lottie as first-class (LottieAnimation API) — but Godot only uses the SVG part —
  [LottieFiles blog on ThorVG](https://lottiefiles.com/blog/working-with-lottie-animations/introducing-thorvg-powerful-graphic-library-for-lottie-animations)
- Community "Kyooz/Lottie-godot" GDExtension: a Godot 4.5.1 forum user reports it works on desktop but not after embedding in a native Android app —
  [Godot forum: How to support Lottie animations](https://forum.godotengine.org/t/how-to-support-lottie-animations-in-godot/129644)
- Old godot-extended-libraries/lottie repo last updated ~2021 (Godot 3 era — **outdated**) — [relatedrepos](https://relatedrepos.com/gh/godot-extended-libraries/lottie)
- GIF/APNG/animated-WebP loaders exist as community addons (Godot-GIF, Godot Animated Image) — [Godot store: godot-animated-image](https://store.godotengine.org/asset/yyc/godot-animated-image/)
- Historical Android workaround: users converting a clip into a sprite sheet for AnimatedSprite when video failed on mobile (pre-4.4 context) —
  [forum thread (archive)](https://forum.godotengine.org/t/playing-a-video-on-android-mission-impossible/11720)

### Inferences
- Memory math for a full-frame sprite sheet demo: 540x540 RGBA8 = 1.17 MB/frame uncompressed. 6 s @ 30 fps = 180 frames ≈ **210 MB** VRAM (unusable);
  @ 12 fps = 72 frames ≈ 84 MB. With ETC2 RGB (4 bpp) ≈ 146 KB/frame → 180 frames ≈ 26 MB, 72 frames ≈ 10.5 MB, plus similar APK size.
  Compared with ~0.5-1 MB of Theora, sprite sheets lose badly for anything longer than ~1-2 s; acceptable only for 150x150 icon loops
  (150x150x4 ≈ 88 KB/frame; 24 frames ≈ 2 MB uncompressed).
- Lottie route would need an After Effects/Lottie authoring step and a non-maintained runtime; not worth it when the games can draw themselves.
- Recommended replacement for AnimatedTexture in a `Control` slot: `TextureRect` + atlas + a tiny shader (frame index uniform) or an
  AnimatedSprite2D inside the control.

### Gaps
- No maintained, Android-verified Godot 4 Lottie runtime found. Did not check Kyooz/Lottie-godot repository itself (only forum report).

---

## 5. Size and performance budgets (per approach)

### Takeaway
Ranked by APK cost: live demo (0) < stylised 2D (0) < Theora (~0.5-1 MB per 6 s clip) < sprite sheet (10-30 MB per clip, compressed) <
FFmpeg GDExtension (tens of MB of native libs). Ranked by runtime cost: stylised 2D < Theora small clip ≈ live 3D SubViewport (CPU vs GPU) < sprite sheet (RAM).

### Cited Findings
- Theora decoding is CPU-only; mobile guidance 720p/30 fps max — [Playing videos (4.7)](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- Local Theora bitrates (432x864, 30 fps, 0.75 quality, with audio): 0.78 Mbit/s (blocks) and 1.36 Mbit/s (snake) — Local measurement (section 1 command)
- PNG master frames: ~53 KB/frame at 432x864 — Local measurement (section 2)
- GDE GoZen download zip ~148 MB (all platforms) — [itch.io](https://voylin.itch.io/gde-gozen-video-playback-addon-for-godot)
- Possible VideoStreamPlayer instantiation micro-stutter (4.3, macOS) — [forum](https://forum.godotengine.org/t/optimized-video-workflow-for-macos-stuttering-on-video-stream-player-initialization/133611)

### Inferences (summary table; numbers are estimates unless marked measured)

| Route | AAB/APK add | Runtime RAM/VRAM | CPU/GPU per frame | First-frame latency | Effort |
|---|---|---|---|---|---|
| Theora .ogv 540x540, 6 s, 24-30 fps, no audio | ~0.4-0.8 MB/clip (from measured bitrates) | ~1-2 MB texture + decoder | CPU decode + YUV→RGB each video frame; GPU trivial | load stream + first keyframe; possible hitch on instantiate → preload when start screen opens | Low code; pipeline step per game; re-record on art/rule change |
| Live 3D SubViewport replay | 0 | ~1.2 MB colour + depth target @540², scene nodes | extra Mobile-renderer pass (GPU); logic tick negligible | build view scene (tens of ms) | Medium-high; reuses views/logic; needs tests |
| Stylised 2D `_draw` replay in how-to icons | 0 | ~0 | canvas draw calls only | ~0 | Medium; fits existing `howto_steps` callables |
| Sprite sheet / SpriteFrames | ~10-26 MB per 6 s clip (ETC2) | same as APK size, resident | trivial | texture upload of whole sheet | Low code, poor scaling |
| Lottie | n/a (no maintained Android runtime) | — | — | — | High risk |
| FFmpeg/AV1 GDExtension | tens of MB native libs (GoZen zip 148 MB, all platforms) | decoder | software decode (AV1 slow on CPU per docs) | — | High; licence/ABI per Godot version |

- Battery: CPU video decode and an extra GPU pass both only run while the how-to panel is visible (a few seconds per session), so battery impact
  is negligible either way; ensure the demo stops (`stop()` / `UPDATE_DISABLED`) when hidden.

### Gaps
- No measured on-device numbers (decode ms, GPU ms, thermal) for any route on the V2250; all runtime costs above are estimates.

---

## 6. Determinism pitfalls when replaying a recorded action list

### Takeaway
A (seed, tick-stamped action list) replays bit-exactly only while rules, RNG consumption order, tick rate and piece/kick tables are unchanged; any
balance or rules change (e.g. the recent "gentler gravity until level 25", 12x24 tower resize, kick table edits) can silently desync a scripted demo.
Guard it with golden-replay unit tests and prefer regenerating demos from the AI rather than hand-storing raw inputs.

### Cited Findings
- Repo rules: simulation uses fixed timesteps and seeded `core/Rng.gd`, never `randf()`; logic is pure GDScript under `games/<id>/logic/` and unit tested;
  save schema bumps require `migrate()` — `CLAUDE.md` (local)
- Recent commits changed exactly the inputs a replay depends on: "Stack Drop: gentler gravity until level 25" (2422c84), "12 x 24 tower" (633be40),
  "10 x 20 tower" (b81ca16), "CPU retune" (08da76d) — local `git log`
- Blocks logic data files (`shard_data.gd` loads a kick table via `_load_kicks()`), and AI planning returns explicit actions via
  `StackAI.actions_for(state, plan)` — local repo

### Inferences
- Pitfalls: (1) gravity/lock-delay or level-curve changes shift *when* pieces land → later actions apply to a different board; (2) board size changes
  invalidate column indices; (3) any extra RNG draw (new feature consuming the xorshift) changes every subsequent piece; (4) float accumulation
  if any rule uses floats with different op order; (5) tick-rate change (60 Hz) rescales tick-stamped scripts; (6) Godot version changes are only
  a risk if logic uses engine float math whose results change (pure int logic is immune).
- Guards: store demos as `games/<id>/data/howto_demo.tres` with `{logic_version, seed, actions, expected_hash, expected_end_summary}`; add a gdUnit
  test that replays it headless and asserts the final state hash (and key checkpoints, e.g. "line clear happened at tick N"). Give each logic class a
  `RULES_VERSION` const bumped on any rules change; the test fails when versions differ, forcing regeneration.
- More robust script format: record *intent* rather than raw inputs — e.g. for blocks a list of placements `{kind, rot, col, hold}` replayed through
  `StackAI.actions_for` at runtime, and for snake a short list of target cells/turn points, or simply "AI with fixed seed + difficulty" plus a
  checkpoint assertion. Intent scripts survive gravity/timing changes; only geometry changes break them.
- For pre-rendered video, add a CI check that re-renders the demo (Movie Maker) and compares a few frames or a state hash at the same ticks; at minimum,
  write the logic version/commit into the clip's filename/metadata so stale videos are visible in review.
- Curating demos: search seeds headlessly for a 6-8 s window that shows the target mechanic (e.g. a 2+ line clear, a hold swap, snake eating 3 orbs and
  turning), and that starts/ends on a similar state for a clean loop; the physics-tune style headless sweep fits this.

### Gaps
- No external sources consulted specifically on replay determinism in Godot (relied on repo rules and general reasoning); not verified whether
  `StackLogic`/`SnakeLogic` use any float math.
