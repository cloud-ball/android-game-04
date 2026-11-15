# Game Feel, Juice and UI Polish for a Portrait Mobile Arcade Mini-Golf Game (Fairway Flick, Godot 4.7 Mobile renderer)

Scope note: this file covers feedback and polish techniques, their timings, portrait HUD/UI patterns and mobile cost. The game is an original design. Commercial games appear only as sources. Most "game feel" numbers in circulation come from community guides and blog posts rather than primary sources. Each finding says which kind it is, and every number without a source is labelled as an inference (a starting value to tune) and kept under Inferences.

---

## 1. Shot feedback: aim/power UI, release feedback, trails, impacts

### Takeaway
The standard mobile golf control is pull-back-and-release with a dotted trajectory line and a power readout that fills as you drag. Players complain most when the power indicator does not match the real shot strength and when they cannot make small, fine putts. Release feedback should combine a crisp short haptic (10–20 ms; Android's CLICK primitive targets 12 ms), a short sound, a small camera kick, and optionally a hit-stop of about 50–100 ms. Screen shake should use a decaying "trauma" value driven by smooth noise, not random jitter.

### Cited Findings
**Aim / power UI**
- Common pattern: "tap and drag your finger back from the ball to set the power and direction". A dotted line projects the trajectory and a power meter fills as you drag. — [DEV Community, Golf Mini review](https://dev.to/games_news/golf-mini-review-a-hole-in-one-mobile-game-26ef)
- Store copy for another title describes the same loop: touch, drag back to aim and set power, let go to fire. — [RAWG, Shot Golf](https://rawg.io/games/shot-golf)
- A review complaint: the arrow indicator "isn't an accurate reflection of your swing power" even though it grows and shrinks with the chosen power. A mismatched power readout is a known pain point. — [148Apps, Vista Golf review](https://148apps.com/reviews/vista-golf-review)
- A player could not drag a small enough amount to avoid overshooting. They suggested a small circle you drag that shows the swing line and magnitude on the ball, i.e. a fine-control handle. — [itch.io comment thread](https://itch.io/post/5653558)
- When rotating or zooming the camera uses drag gestures similar to power control, the inputs conflict (OK Golf review). — [MacStories, OK Golf](https://www.macstories.net/reviews/take-to-the-course-with-ok-golf/)
- Some players expect click-and-drag to set both direction and power, and are confused by click-only power selection. — [rmkubik itch.io comments](https://rmkubik.itch.io/fruit-golf/comments)
- A pull-back "power shot" past a threshold that adds a timing element is praised as added depth. — [148Apps, OK Golf review](https://148apps.com/ok-golf/ok-golf-review)

**Screen shake / camera**
- Squirrel Eiserloh's GDC 2016 talk "Math for Game Programmers: Juicing Your Cameras With Math" (free on GDC Vault) is the main reference for trauma-based shake. — [GDC Vault](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing)
- The trauma model, as implemented in Bevy's example that follows the talk: shake depends on a trauma value in 0.0–1.0, more trauma means stronger shake, and trauma decays automatically over time. — [Bevy 2D screen shake example](https://bevy.org/examples/camera/2d-screen-shake/)
- Use continuous noise, not random values per frame. The talk also covers rotational shake, and recommends offering an option to disable shake because it makes some people nauseous. — [r/gamedev discussion of the talk](https://axebps-redlib.hf.space/r/gamedev/comments/7m6w0t/math_for_game_programmers_juicing_your_cameras) (secondary)
- Jan Willem Nijman (Vlambeer), "The Art of Screenshake" (Control Conference, Amsterdam, Nov 2013): about 30 small tweaks that turn a dull shooter into a satisfying one, including shaking the screen slightly opposite to the firing direction (a directional kick). — [Game Developer](https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games)
- A recreation of that talk breaks the steps out as animation, muzzle flash, impact effects, camera lerp, screenshake, player knockback, hit pause, recoil and permanence (smoke/debris). — [DK Liao recreation devlog](https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects)
- Martin Jonasson and Petri Purho's "Juice it or lose it" builds up a block-breaker by layering particles, screenshake, sound and tweened animation one at a time. — [gamejuice resource listing](https://gamejuice.pages.dev/resources/juice-it-or-lose-it) (secondary)
- Godot recipe for 3D/2D trauma shake (noise-driven offset plus rotation, trauma squared or cubed). — [KidsCanCode Godot recipe](https://kidscancode.org/godot_recipes/3.x/2d/screen_shake/)

**Hit-stop (freeze on impact)**
- Community guidance (not primary): light hits 30–50 ms, heavy 60–100 ms, critical 100–150 ms. One Japanese write-up found 0.05–0.1 s best in testing: shorter freezes go unnoticed, longer ones feel like stutter. — [uhiyama-lab Godot hitstop](https://uhiyama-lab.com/en/notes/godot/hit-feedback-hitstop/); [bugnet hit-pause guide](https://bugnet.io/blog/how-to-use-hit-pause-to-make-impacts-feel-powerful)
- Godot pitfall: if you set `Engine.time_scale` to 0.05 and restore it with a scaled timer, a 0.08 s stop actually takes 0.08/0.05 = 1.6 s of real time. Use the ignore-time-scale flag. Repeated hits can also compound (0.05 × 0.05 = 0.0025). — [uhiyama-lab Godot hitstop](https://uhiyama-lab.com/en/notes/godot/hit-feedback-hitstop/)
- Godot `Tween.set_ignore_time_scale(true)` makes "the tween ... ignore Engine.time_scale and update with the real, elapsed time". — [Godot Tween docs](https://docs.godotengine.org/en/stable/classes/class_tween.html)

**Haptics on release / impacts**
- Android AOSP primitive targets: CLICK 12 ms (limit <30 ms, ~2 G); TICK 5 ms (<20 ms, ~1 G); LOW_TICK 12 ms (~0.25 G); THUD 300 ms; SPIN 150 ms; QUICK_RISE 150 ms; SLOW_RISE 500 ms; QUICK_FALL 100 ms. — [AOSP haptics constants & primitives](https://source.android.com/docs/core/interaction/haptics/haptics-constants-primitives)
- Android design guidance: "less is more". A good keyclick haptic lasts 10–20 ms, but the actuator may ring for another 20–50 ms after the input ends. Avoid legacy one-shot vibrations (`createOneShot`, `vibrate(long)`) because they feel buzzy. "Given the choice of buzzy haptics or no haptics for touch feedback, choose no haptics." — [Android haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- Same source: match strength to how frequent and important an event is (frequent events very subtle). Effects can grow stronger as an interaction nears its target, e.g. "gradually increasing the amplitude of a sequence of ticks with dragging". Co-design haptics with visuals and audio, because out-of-sync haptics can make users think the actuator is broken. — [Android haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- Godot API: `Input.vibrate_handheld(duration_ms: int = 500, amplitude: float = -1.0)`. Amplitude is 0.0–1.0 and -1 uses the device default. Android needs the `VIBRATE` permission in the export preset, and device settings (DND, haptics off) can suppress it. — [Godot Input docs](https://docs.godotengine.org/en/stable/classes/class_input.html)

### Inferences
- **Drag-aim spec (synthesised starting values):** drag-back slingshot with a dead zone of about 12–16 dp so a tap does not fire. Power maps to drag distance with a gentle ease-in curve (e.g. power = d^1.3) so the first third of the drag gives fine putts, which addresses the "can't drag small enough" complaint. Cap the drag at roughly 35–40% of screen height in portrait so the thumb never leaves the screen. Show a numeric or segmented power readout tied exactly to launch speed, which addresses the "arrow doesn't match power" complaint.
- **Power colour ramp:** green → yellow → orange → red over 0–100%. Add a pulse or a subtle tick haptic (TICK-class, about 5 ms, low amplitude) every 10% step, and a stronger tick at max. This follows Android's "ticks that grow stronger toward the target" guidance. Throttle to about one tick per 60–80 ms during fast drags so the haptics don't turn buzzy.
- **Prediction line:** dotted line of 8–14 dots (or a world-space strip mesh with a scrolling dash UV) that fades in alpha and shrinks in size with distance. Show only the first bounce for an arcade challenge, or none at high difficulty. Dots should animate (scroll toward the aim direction at about 1–2 dots/s) so the line reads as "live". Pool the dot meshes or use one MultiMesh, never instancing per frame (the project's no per-frame allocations rule).
- **Release package (fires on the same frame):** (1) putter-tap SFX with ±1–2 semitone pitch variation scaled by power; (2) `vibrate_handheld(12–20, 0.4–0.8 scaled by power)`, kept ≤20 ms per Android guidance; (3) a camera kick of 0.05–0.15 m opposite to the shot direction, springing back over about 150–250 ms, which echoes Nijman's opposite-direction kick; (4) trauma += 0.1–0.3 only for full-power shots (no shake on soft putts); (5) optional micro hit-stop of 40–60 ms on max-power shots only.
- **Shake budget:** max translation about 0.15–0.3 m and roll about 1–2° at trauma = 1, with shake = trauma². Decay trauma at 1.5–2.5 per second. Provide a "Reduce motion / screen shake" toggle in settings (accessibility, supported by the talk discussion).
- **Determinism caveat (project-specific):** CLAUDE.md requires fixed-timestep, seeded simulation. Changing `Engine.time_scale` also scales the delta passed to `_physics_process`, so a global time-scale hit-stop or slow motion could change the sim's step size and break determinism or replays. Safer: freeze or slow the presentation layer (camera, VFX, render interpolation), or run fewer fixed sim steps per real second while keeping step size constant. This needs verifying against how the golf sim is stepped (send to the physics-reviewer agent).
- **Ball trail:** a ribbon trail (fixed ring buffer of about 16–24 points, rebuilt into a single ImmediateMesh/ArrayMesh, or GPUParticles3D trail mode). Width and alpha scale with speed and the trail fades to 0 below a speed threshold, so a resting ball has no trail. Use additive or unshaded alpha with a small footprint. A trail is a long thin transparent strip, so overdraw is low.
- **Wall/rail hit:** small burst of 6–12 spark/dust particles at the contact point, oriented along the wall normal, lifetime 0.2–0.35 s. Rail-clack SFX with volume ∝ impact speed and pitch ±2 semitones. A TICK/CLICK haptic only above a speed threshold. Squash the ball 10–15% along the normal for 60–90 ms. Skip all feedback below a minimum impact speed so a rolling ball against a rail doesn't machine-gun clacks.
- **Speed lines:** only for jumps/ramps or max-power shots. A few screen-space streak quads, or radial lines in the HUD layer, for 150–300 ms.

### Gaps
- No primary source (talk slides/transcript) gave Eiserloh's exact shake amplitudes. The numbers above are starting values, not quoted.
- No source quantifies an ideal dead zone or power curve for mobile golf drag-aim. Playtest on the test phone.
- Godot `vibrate_handheld` on Android appears to wrap a one-shot vibration (amplitude plus duration), which Android calls "legacy". I did not confirm whether Godot 4.7 exposes `VibrationEffect.Composition` primitives (CLICK/TICK/THUD). Access may need an Android plugin.

---

## 2. Hole-out moments: slow motion, camera push-in, confetti, popups, medals, stingers

### Takeaway
No authoritative source gives hole-out slow-motion durations. The established pattern is "cinematic slow motion" on the decisive moment (e.g. a fighting game slows down for the winning blow), with UI and audio on unscaled real time. Popups should enter in about 300 ms with ease-out or a small back overshoot, and exit faster (200–250 ms). Everything should be built with time-scale-independent tweens.

### Cited Findings
- Slow motion in games splits into "cinematic slow motion" (cutscenes, scripted moments, e.g. Street Fighter IV slows down after the winning blow so the player can watch it) and bullet time. — [SAGE / Games and Culture paper on slow motion](https://https-sage-cnpereading-com-443.webvpn1.xju.edu.cn/doi/10.1177/15554120221090974) (via proxy link; paper DOI 10.1177/15554120221090974)
- Implementation: scale delta for the world, but keep a separate unscaled clock so UI, the pause menu and sometimes audio run at real speed during slow motion. — [bugnet slow-motion guide](https://bugnet.io/blog/how-to-implement-slow-motion-and-time-scaling); [GameDev.net "Coding Slow Motion"](https://gamedev.net/tutorials/programming/general-and-gameplay-programming/coding-slow-motion-r5864)
- Popup timing: 200–300 ms suits a modal moving into view. Entering objects should take slightly longer than exiting ones, e.g. 300 ms to appear and 200–250 ms to disappear. NN/g also warns that popups are often problematic and shouldn't be overused. — [Nielsen Norman Group, Animation duration](https://nngroup.com/articles/animation-duration)
- Ease-out for entrances; avoid ease-in for UI because it "accelerates at the end, which feels sluggish". Ease-out-back overshoots slightly before settling and suits playful entries. Suggested overshoot ranges from about 1.02 scale (subtle) to 10–20% (playful). — [Impeccable motion-design reference](https://git.secluded.site/agent-skills/blob/main/vendor/impeccable/skill/reference/motion-design.md) (secondary, design-skill doc); [Val Head, How fast should UI animations be](https://valhead.com/?p=2978)
- Godot Tween options available for popups: TRANS_BACK ("backing out at ends"), TRANS_ELASTIC ("wiggling around the edges"), TRANS_SPRING ("like a spring towards the end"). Defaults are EASE_IN_OUT / TRANS_LINEAR. Tweens are "more light-weight than AnimationPlayer", start immediately, and must not be reused. Kill the previous tween before restarting. `bind_node` auto-kills a tween when its node is freed. — [Godot Tween docs](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- Nijman's list includes slow motion and "permanence" (debris/smoke that stays) as feel multipliers. — [DK Liao recreation](https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects); [GxD Game Feel slides (Uni Bayreuth)](https://medienwissenschaft.uni-bayreuth.de/wp-content/uploads/GxD-10-Game-Feel.pdf)
- Reduced-motion preferences should be respected. — [Impeccable motion-design reference](https://git.secluded.site/agent-skills/blob/main/vendor/impeccable/skill/reference/motion-design.md)

### Inferences
Starting values (unsourced, tune on device):
- **Near-cup slow motion trigger:** when the ball is predicted to drop (within about 1.5 ball radii of the cup with speed below capture speed), or for a long-distance hole-in-one candidate, ramp the presentation time scale 1.0 → 0.3 over 120 ms, hold 0.4–0.7 s of real time, then snap back to 1.0 over 150 ms as the ball drops. Use it rarely: only on hole-in-one, eagle-or-better, or putts over N metres. Using it on every tap-in kills the effect (the same scarcity logic as NN/g's popup warning). Never slow motion when the ball will miss, or players learn the tell. Optionally use it on near-misses as a "lip-out" tease, but only if the prediction is exact.
- **Camera push-in:** dolly 15–25% closer and lower the pitch by 5–10° toward the cup over 0.4–0.6 s, ease-in-out (TRANS_SINE/CUBIC), tween ignoring time scale. Return over 0.5 s or cut to the scorecard.
- **Cup drop sequence (about 1.2–1.8 s total before the next hole UI):** t=0 ball drops: cup-rattle SFX, a THUD-like haptic (Godot: one pulse of about 30–40 ms at amplitude 0.6, or two quick 15 ms pulses 60 ms apart), flag wiggle tween (rotation ±8° with TRANS_ELASTIC over 0.6 s). t≈0.1 s: confetti burst. t≈0.25 s: score word popup. t≈0.8–1.0 s: stars/medal reveal. t≈1.5 s: continue button fades in (but tap-to-skip is allowed from t≈0.4 s).
- **Confetti:** a single GPUParticles3D (or CPUParticles3D on the low tier) one-shot with explosiveness 0.9–1.0, 40–80 quads on mid-range and 20–30 on low-end, lifetime 1.2–2.0 s, gravity plus damping, random spin, 4–6 palette colours. Use an opaque or alpha-scissor material (not alpha blend) to avoid overdraw sorting cost. Ace/hole-in-one gets 2–3 staggered bursts or firework rockets (a 1-particle trail that sub-emits a 30-particle burst) 0.25 s apart.
- **Score word popup ("Birdie!", "Eagle!", "Hole in one!"; "Par"/"Bogey" get a quieter style):** scale 0 → 1.15 → 1.0 with TRANS_BACK EASE_OUT over 300–350 ms, plus slight rotation −6° → 0°. Hold 0.6–0.9 s. Exit with scale 1.0 → 1.1 and alpha → 0 over 200 ms (ease-in is fine for exits). Add a 1–2 frame white flash on the text outline or a shine sweep (a UV-offset shader on the label). Stagger letters by 30–40 ms for the big outcomes only. Colour-code by result (gold for an ace, warm for birdie/eagle, neutral for par).
- **Star/medal reveal:** stars pop one by one 150–250 ms apart, each scaling 0 → 1.25 → 1.0 (TRANS_BACK, about 250 ms) with a rising pitch ding (+2 semitones per star, the classic ascending-reward cue), a TICK haptic each, and an empty-star outline shown first so the player sees what they missed.
- **Stinger:** a 1.0–2.5 s musical sting per outcome tier (par: short 2-note; birdie: 3-note rising; ace: 4–6 s fanfare plus crowd cheer), ducking the music bed by about 6–10 dB during the sting.
- **Godot implementation:** all hole-out tweens use `set_ignore_time_scale(true)`, or better, don't touch `Engine.time_scale` at all and drive slow motion as a presentation-layer multiplier (see the determinism caveat in section 1).

### Gaps
- No primary or industry source found that gives measured slow-motion time scales or durations for sports/golf hole-outs. All values above are proposals.
- No playtest data on whether slow motion before a putt drops raises satisfaction or reads as "telegraphing".

---

## 3. Ambient life: vegetation sway, water, clouds, critters (cheap on mobile)

### Takeaway
Cheap ambient motion means vertex-shader animation with no texture reads (sine/cosine of world position plus TIME), masked by vertex colour so bases stay planted, on few materials and instanced meshes. The main mobile costs to avoid are overlapping transparency (fill rate), texture reads in shaders, and dense geometry concentrated in small screen areas.

### Cited Findings
- Godot official GPU optimisation: mobile GPUs are tile-based; "tile-based rendering struggles when there are small objects with a lot of geometry"; "avoid concentration of vertices in small parts of the screen". — [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- "Transparency is particularly expensive where multiple transparent objects overlap". Keep transparent areas "as small as possible". Fill rate is "especially on mobile ... very expensive". More complex opaque geometry can beat transparency tricks. — [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- "When targeting mobile devices, consider using the simplest possible shaders you can reasonably afford". Texture reads cost performance and power. Most Android devices lack VRAM compression for textures with transparency. — [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Fewer materials means faster rendering. Join static meshes offline (but batched meshes can't be culled individually). Smaller or distant lights can drop shadows with little visual loss. For particles, consider forcing vertex shading. — [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- A community "Simple wind sway" Godot 4 shader offsets vertices in `vertex()` with sin/cos of position plus TIME and no texture lookups. — [godotshaders Simple wind sway](https://godotshaders.com/shader/simple-wind-sway/)
- Official Godot tree tutorial scales leaf sway by a vertex colour channel (COLOR.r) so trunks and roots stay fixed and only the tips move. — [Godot docs, Making trees](https://docs.godotengine.org/en/4.1/tutorials/shaders/making_trees.html)
- Noise-texture-driven grass wind samples a texture in the vertex stage (heavier on mobile). Multi-layer wind-area shaders with masks add more cost. — [godotshaders Grass shader](https://godotshaders.com/shader/grass-shader/); [godotshaders Wind Area Effect](https://godotshaders.com/shader/wind-area-effect/)
- Godot 4.2+ treats CPUParticles as a "lower-end, simpler alternative" rather than a 1:1 fallback. A GPUParticles node can be converted to CPUParticles from the editor. — [GameFromScratch, Future of Godot Particles](https://gamefromscratch.com/the-future-of-godot-particles/); [bugnet](https://bugnet.io/blog/fix-godot-gpu-particles-not-rendering-mobile) (blog)
- Godot 4 porting note: replace `WORLD_MATRIX` with `MODEL_MATRIX` in older shaders. — [godotshaders comments](https://godotshaders.com/shader/pixel-art-wind-sway-meshinstance3d-godot-4-0/)

### Inferences
- **Vegetation:** one shared foliage ShaderMaterial. `VERTEX.x += sin(TIME*speed + world_pos.x*0.7 + world_pos.z*0.3) * amp * COLOR.r`, with amp 0.03–0.08 m for bushes and 0.1–0.2 m for tree crowns, speed 1.2–2.0 rad/s, and a second sine at 2.3× frequency and 0.3× amplitude for flutter. Draw via MultiMeshInstance3D. Use opaque or alpha-scissor leaves, never alpha blend. The cost is a few ALU ops per vertex, which suits tilers.
- **Water:** opaque (not transparent) water plane with two scrolling normal-like effects done in math (sin waves) or one small tiled texture. Fake depth with a vertex-colour gradient painted at edges, and add a foam line as a separate thin mesh strip. Use a fresnel tint for shimmer. Avoid screen-texture/depth refraction on the Mobile renderer. Add a splash (12–20 particles plus a ring decal quad that scales 0.2 → 1.5 m and fades over 0.5 s) for the water-hazard plop.
- **Clouds:** 2–4 large soft cloud shadows as a UV-scrolled multiply term in the ground shader (scroll 0.01–0.03 UV/s), or a few billboard cloud quads far behind the course on a skybox layer. A sky shader with scrolled cloud noise is one full-screen pass, so keep it cheap or bake to a panorama.
- **Animated props (windmill, spinning flags, bobbing buoys, rotating bumpers):** rotate in a vertex shader by TIME (zero CPU cost) or via an AnimationPlayer on the prop root. Obstacles that affect play must move in the deterministic sim, not by TIME in a shader. Pure decoration can use shader time.
- **Critters (birds, butterflies):** butterflies as 2-quad meshes with wings flapped in the vertex shader (rotate about the body axis by sin(TIME*12)). Paths follow a Lissajous curve in the shader or as a single tiny GPUParticles3D system (2–6 particles, long lifetime, turbulence). Birds can be a distant flock of 5–10 V-shaped quads on a looping path, spawning occasionally (every 20–40 s) so they register as life rather than noise.
- **Budget:** ambient FX should stay under about 10–15% of frame time on the low tier. Gate everything beyond vegetation sway behind a quality setting (Low: sway only; Medium: plus water shimmer and cloud shadows; High: plus critters and extra particles).
- Honour the project's physics-interpolation rule: decorative nodes moved in `_process` by script should be on a subtree with physics_interpolation_mode = OFF, or be shader-animated instead.

### Gaps
- No published mid-range Android benchmarks found for Godot 4.x vertex-sway foliage, GPU vs CPU particles, or water shaders. Profile on the project's test phone.
- Did not confirm Godot 4.7-specific Mobile-renderer changes to particle or transparency cost.

---

## 4. UI/HUD for portrait mini-golf: layout, typography, transitions, scorecards, safe area

### Takeaway
Use a thin top bar (hole / par / strokes, plus rival avatars and strokes in CPU races), keep the bottom thumb zone and the ball area clear during aiming, and size every touch target to at least 48×48 dp (Android) / 44×44 pt (iOS). Apply the Android safe-area insets with `DisplayServer.get_display_safe_area()`. Restraint and consistency (two fonts max, one button component, one panel style) separate "premium" from "cheap".

### Cited Findings
- Touch targets: Google/Material 48×48 dp minimum; Apple 44×44 pt; WCAG 2.2 AA 24×24 CSS px (SC 2.5.8), AAA 44×44 (SC 2.5.5). Spacing of about 8 dp between targets is commonly suggested (secondary sources; Apple spacing claim unverified). Padding can enlarge the hit area without changing the visual size. — [TetraLogical, Foundations: target size](https://tetralogical.com/blog/2022/12/20/foundations-target-size/); [Baseflow accessibility guidelines](https://baseflow.github.io/accessibility-guidelines/navigation/touch-targets.html); [OpenReplay](https://blog.openreplay.com/improving-tap-targets-mobile-ux/)
- Godot safe area: `DisplayServer.get_display_safe_area()` returns the unobscured `Rect2i` "where interactive controls should be rendered". `get_display_cutouts()` is currently implemented only on Android. Godot 3's `OS.get_window_safe_area()` is gone in Godot 4. — [Godot DisplayServer docs](https://docs.godotengine.org/de/4.x/classes/class_displayserver.html); [Godot forum, notch handling](https://forum.godotengine.org/t/simple-way-to-manage-the-notch-on-ios-and-android-mobile-devices/86971)
- Common pattern: compute margins as max(base margin, safe inset scaled to viewport) on a root MarginContainer, and recompute on `get_viewport().size_changed`. — [Godot forum, notch handling](https://forum.godotengine.org/t/simple-way-to-manage-the-notch-on-ios-and-android-mobile-devices/86971); [uhiyama-lab touch/safe area](https://uhiyama-lab.com/en/notes/godot/touch-input-mobile-safe-area/)
- Caveats: in edge-to-edge mode the safe area may report only the status bar and not the navigation bar height. One Pixel 7 user reported a "weirdly low" top safe value vs the notch. Test on hardware. — [r/godot thread](https://redlib.hackliberty.org/r/godot/comments/1ldmjky/finally_found_a_way_to_get_statusbar_and); [GameDev.tv community](https://community.gamedev.tv/t/weirdly-low-safe-area-top-on-google-pixel-7/239756)
- Premium vs cheap: coherence matters more than fidelity. Mixing styles, such as fonts "that belong to different games", breaks the illusion. Use max two fonts (display + body), a small UI palette of roles, one button component with explicit states, and one panel treatment. Generous margins and aligned grids signal intent. — [bugnet, UI design basics for indie developers](https://bugnet.io/blog/ui-design-basics-for-indie-developers); [bugnet, Avoid the asset-store look](https://bugnet.io/blog/how-to-avoid-the-asset-store-look)
- Small or decorative fonts and poor contrast "alienate users". — [Starloop Studios, mobile game UI](https://starloopstudios.com/crafting-intuitive-mobile-game-ui/)
- Popups are often problematic and shouldn't be overused. — [NN/g](https://nngroup.com/articles/animation-duration)
- Camera gestures that resemble the power drag cause input conflicts. — [MacStories, OK Golf](https://www.macstories.net/reviews/take-to-the-course-with-ok-golf/)

### Inferences
- **Portrait layout (top to bottom):**
  1. *Top bar* (inside the safe area, about 56–72 dp tall): left: pause button (48 dp); centre: "HOLE 3/9 · PAR 3" in small caps over a large stroke counter; right: map-view toggle (48 dp). In CPU races, a compact row of 2–4 circular avatars (32–40 dp) with stroke counts sits under the bar. The active player's avatar is ringed and pulses when it's their turn.
  2. *Play area*: unobstructed. The HUD fades to about 30–40% opacity (or slides out) during an active drag, and only the power readout near the ball/finger and the prediction line remain. Restore over 200 ms after release.
  3. *Bottom zone* (thumb reach): contextual buttons only when idle (e.g. camera recentre, emote). Leave at least 24 dp above the nav bar inset.
- **Power readout placement:** near the ball, offset from the finger so the thumb never covers it (e.g. an arc around the ball, or a vertical bar at the screen edge on the side opposite the thumb).
- **Typography:** one rounded, heavy display face for numbers and outcome words (tabular figures for stroke counters so digits don't jitter) and one clean sans for body. Bundle open-licence fonts (e.g. SIL OFL) and record licences in ASSETS.md. Minimum body size about 14–16 sp-equivalent at 1080×2400. Outcome words 48–72 sp with a 2–4 px outline or soft shadow in one consistent direction.
- **Buttons:** one StyleBoxFlat component: corner radius 12–16 dp, a 2–4 dp darker bottom "lip" for physicality. On press, scale to 0.94 and move the lip down over 60–80 ms, release with TRANS_BACK over 120–160 ms, plus a TICK haptic and a soft click SFX. Disabled state at 40% saturation, never just alpha.
- **Hole transitions (1.0–1.6 s total, skippable):** after the scorecard, wipe/iris or slide out (250–350 ms, ease-in), then a camera flyover of the next hole from a high angle down to the tee (0.8–1.2 s, ease-in-out) while the "HOLE 4 · PAR 2" title card drops in with TRANS_BACK (300 ms). Hide geometry loading behind the wipe.
- **Scorecard screen:** a grid with the player and CPU rivals as rows and holes as columns. Highlight the current hole column, colour-code cells (under par / par / over), and count up the running total with a quick tick SFX (about 40–60 ms per increment, capped at 0.8 s). Show the medal/stars for the round at the end, with "Next hole" as the primary action and "Retry" secondary.
- **Safe area implementation:** a root `MarginContainer` in the HUD scene that reads `DisplayServer.get_display_safe_area()` once on ready and on `size_changed`, converts to viewport units with `get_window().size` vs `get_viewport().get_visible_rect().size`, adds a fallback bottom inset of about 24–48 dp for gesture navigation, and is exposed as a `core/` helper so all 8 games share it.

### Gaps
- Could not access Game UI Database pages or specific breakdowns of commercial golf HUDs in this pass. The layout above is a synthesis.
- No primary Apple HIG / Material page fetched directly; touch-target numbers come from consistent secondary sources.

---

## 5. Audio for mini-golf: putter tap, rail clack, cup rattle, water plop, crowd

### Takeaway
Build each key moment from short layered one-shots with a few recorded variants. Randomise pitch by about ±2 semitones and volume by about ±1.5 dB per play, but keep "signature" sounds (cup drop, UI confirm) stable so they're recognisable. The cup drop is the most valued sound in golf and deserves the most layers.

### Cited Findings
- Pitch randomisation of about ±2 semitones plus about 1.5 dB volume variation is a common starting point. Wider swings sound comedic. A semitone is a ratio of 2^(1/12) ≈ 1.06. — [Game Developer, "The power of pitch shifting"](https://gamedeveloper.com/audio/the-power-of-pitch-shifting); [CRI AtomCraft randomisation](https://blog.criware.com/index.php/2017/01/16/atomcrafts-randomization-features/)
- Randomisation containers (pick a random sample from a pool each trigger) plus randomised pitch/volume/EQ/pan multiply a small sample set into many variants. — [CRI AtomCraft randomisation](https://blog.criware.com/index.php/2017/01/16/atomcrafts-randomization-features/)
- Some sounds need consistent repetition "to provide that safety of recognition". Don't randomise everything. — [A Sound Effect, game audio immersion](https://www.asoundeffect.com/game-audio-immersion/)
- Golf feel: the click of ball on putter face is crucial for feel, and the ball dropping into the cup is "a golfer's favourite noise". — [Golf Monthly, importance of sound in golf](https://www.golfmonthly.com/news/notice-board/importance-sound-golf-117784)
- Cup-drop character: "the hollow rattle of a ball dropping in and settling against the base of the flagstick". Library sounds arrive isolated so you build the moment layer by layer. — [Morphic golf SFX guide](https://morphic.com/resources/sounds/golf-swing-sound-effects)
- Library sources: Sound Ideas Golf (382 sounds incl. "Hit Putt in Cup", "Hit Cup Rattle", "Hit Flagstick"; $249) ([Sound Ideas](https://sound-ideas.com/Product/2441/Golf-Sound-Effects)); Motion Array ball-in-hole swirl set ([Motion Array](https://motionarray.com/sound-effects/golf-ball-drop-in-hole-1187694/)); BudgetPixel CC BY 4.0 cup drop, AI-generated, attribution required ([BudgetPixel](https://budgetpixel.com/sfx/golf-ball-cup-drop-e536da51)).
- Haptics should be co-designed and in sync with audio. — [Android haptics principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)

### Inferences
- **Event sound map (layers; variants; randomisation):**
  - *Putter tap:* transient click (wood/metal tick) + body "tok", with pitch and volume scaled by shot power (softer putts slightly higher and quieter). 4–6 variants, ±1.5 semitones.
  - *Ball roll:* a looped low-volume roll whose volume and pitch follow speed (0 at rest), with a different loop per surface (felt/turf, wood bridge, metal ramp, sand). Crossfade over 80–120 ms on a surface change.
  - *Rail/wall clack:* sharp wooden or rubber knock, volume ∝ impact normal speed, 4–6 variants, ±2 semitones, with a minimum interval of about 50 ms per ball so contacts don't double-trigger.
  - *Bumper:* a springy "boing" with a pitch rise. Can be more stylised (arcade).
  - *Cup rattle (signature):* layer 1 a rim tick if the ball clips the lip; layer 2 a hollow drop "plunk"; layer 3 a short rattle/settle tail (0.3–0.6 s); then the outcome stinger plus crowd. Keep layer 2 nearly fixed (±0.5 semitone) for recognition. Lip-outs get the rim tick plus a sympathetic "ohh" crowd sample.
  - *Water plop:* a splash plus a bubbly tail and a muted "aww" from the crowd. Penalty UI sound after 0.4 s.
  - *Crowd/cheer:* scale with outcome (polite clap for par, cheer for birdie, big roar plus whistles for an ace). 2–3 variants each. The ambience bed (birds, breeze) loops quietly at about -24 to -30 dBFS.
- **Mixing in Godot:** buses Master → {Music, SFX, UI, Ambience}. Duck Music by about 6–10 dB during stingers with a sidechain-like tween on bus volume. Use AudioStreamRandomizer (Godot 4 resource with random pitch/volume and a stream pool) for variants. Pre-create a small pool of AudioStreamPlayer3D/AudioStreamPlayer nodes (e.g. 8) to avoid per-frame allocation. Use OGG for loops and WAV for short transients (lower decode latency). Keep total SFX under a few MB.
- **Hole-out sync:** the cup-drop sound, the haptic and the confetti spawn must trigger on the same tick. Android audio latency varies by device, so consider firing the SFX 1–2 frames earlier than the visual on known high-latency devices.

### Gaps
- AudioStreamRandomizer was not verified in a fetched source for Godot 4.7, though it exists in Godot 4.x to my knowledge. Confirm in the class reference.
- No source found on measured Android audio latency for Godot 4.7 on mid-range devices.
- No mini-golf-specific sound-design postmortem found. The layering above is a synthesis.

---

## 6. Common mistakes that make mobile games look cheap

### Takeaway
"Cheap" comes mostly from inconsistency (mixed art and font styles, ad-hoc buttons), stiff or missing motion, buzzy haptics, unreadable small text, cluttered HUDs and overused popups. It does not come from low fidelity. Effects should support readability and the core loop, not paper over a weak one.

### Cited Findings
- Players forgive simple art if it's coherent. What breaks the spell is mixing, e.g. one photoreal asset in a stylised scene or fonts from different games. A modest consistent style reads as deliberate, while a patchwork of great assets reads as cheap. — [bugnet, How to avoid the asset-store look](https://bugnet.io/blog/how-to-avoid-the-asset-store-look)
- Restraint: at most two fonts, a small palette of UI roles, one button component with explicit states, one panel treatment. — [bugnet, UI design basics](https://bugnet.io/blog/ui-design-basics-for-indie-developers)
- Stiff animation is "a dead giveaway of a rushed product". Polish (shake, particles, tweened scales) can lift simple visuals, but no polish saves a flawed core loop. — [Wayline, indie visuals trap](https://www.wayline.io/blog/indie-visuals-trap-fake-done-survival); [Wayline, glow-up trap](https://www.wayline.io/blog/glow-up-trap-polished-ui-empty-game)
- Small or decorative fonts and poor contrast alienate users. — [Starloop Studios](https://starloopstudios.com/crafting-intuitive-mobile-game-ui/)
- Common mobile UX mistakes include tiny touch targets and UI placed where thumbs or notches cover it. — [GDevelop, 5 mobile UX mistakes](https://gdevelop.io/blog/mobile-ux-mistakes); [TetraLogical](https://tetralogical.com/blog/2022/12/20/foundations-target-size/)
- Buzzy, long vibrations are worse than none for touch feedback. — [Android haptics principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- Overlapping transparency and heavy shaders cost fill rate and battery on mobile. Frame drops themselves read as cheap. — [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Overused popups. — [NN/g](https://nngroup.com/articles/animation-duration)

### Inferences
Checklist for Fairway Flick:
1. Default Godot theme or font visible anywhere (a hallmark of unfinished work).
2. Linear tweens everywhere. Every UI move should have an ease, and nothing should "pop" without at least a 100–150 ms ease-out.
3. Identical sound on every hit (no variation) or a sound with no volume tied to impact speed.
4. Shake or confetti on every minor event, which wears out the reward. Scale effects to the outcome tier.
5. Mismatched icon styles (outline vs filled, different stroke weights) and mixed corner radii.
6. Pure-black drop shadows and over-saturated pure-RGB colours. Use tinted shadows and a curated palette.
7. Text below about 12 sp or white on light grass without an outline.
8. UI under the notch or gesture bar, or targets under 48 dp.
9. Hard cuts between holes without a transition, or long unskippable celebrations (>2 s without tap-to-skip).
10. Jank: first-frame hitches when spawning particles or shaders for the first time. Pre-warm particle systems and materials in the hole-load screen. Godot compiles shaders on first use, so render each VFX material once off-screen during loading (a project-level inference; verify with the Mobile renderer's ubershader/pipeline cache behaviour in 4.7).
11. Visual smearing on teleports/resets. Already noted in CLAUDE.md: set physics_interpolation_mode OFF for script-moved roots, or reset interpolation on ball respawn.

### Gaps
- Most "looks cheap" sources are blogs (bugnet, Wayline) rather than research or postmortems. Treat them as practitioner opinion.
- No mobile-specific studies found that link polish elements to retention or revenue.

---

## Performance-cost summary (mid-range Android, Godot Mobile renderer) — synthesis

| Technique | Relative cost | Main risk | Mitigation (sources: Godot GPU optimisation docs unless noted) |
|---|---|---|---|
| Camera shake / kick / push-in | ~0 | Motion sickness | Settings toggle ([talk discussion](https://axebps-redlib.hf.space/r/gamedev/comments/7m6w0t/math_for_game_programmers_juicing_your_cameras)) |
| Tween-driven UI popups | Very low | Reusing tweens; time-scale coupling | New tween per animation, kill old, `set_ignore_time_scale` ([Tween docs](https://docs.godotengine.org/en/stable/classes/class_tween.html)) |
| Haptics | ~0 CPU, battery | Buzzy feel on cheap actuators | ≤20 ms pulses, user toggle ([Android](https://developer.android.com/develop/ui/views/haptics/haptics-principles)) |
| Ball trail ribbon | Low | Alpha overdraw if wide | Thin, short, additive/unshaded |
| Impact sparks (6–12 particles) | Low | Overlapping alpha | Small quads, short life, vertex shading |
| Confetti (40–80 particles) | Low–medium | Large transparent quads overlapping | Alpha scissor/opaque, cap count per tier |
| Vertex-shader foliage sway | Low | Vertex density on tilers | No texture reads, MultiMesh, COLOR mask ([Making trees](https://docs.godotengine.org/en/4.1/tutorials/shaders/making_trees.html)) |
| Water shimmer | Low–medium | Screen/depth texture reads, transparency | Opaque water, math waves, edge foam strip |
| Full-screen post (bloom/glow, vignette) | Medium–high | Fill rate | Off or low on low tier |
| Overlapping transparent FX/UI | High | Fill rate | Minimise transparent area |

Inference: on low-end devices, the biggest wins are (a) no alpha-blended full-screen overlays during gameplay, (b) particle counts halved via a quality tier, and (c) glow off.
