# Cue Club: rendering a 3D pool table and balls beautifully but cheaply in Godot 4.7 (Mobile renderer, Android)

Scope note: all Godot doc citations below are from the **Godot 4.7 stable** docs (checked 2026-11-13). No Godot 3.x material is used. Non-Godot shader references (getlazarus WebGL pool, Mesa/OpenGL "toy ball") are engine-agnostic GLSL techniques; the ideas port to Godot spatial shaders, but the code itself does not. Repo context used: `project.godot` has `rendering_method="mobile"` and `physics/common/physics_interpolation=true`; house style in `games/blocks/scenes/blocks_view.gd` is MultiMesh + inline `unshaded` spatial shaders with lighting faked in the shader, a linear tonemap, glow with `glow_hdr_threshold = 1.15`, a 2D gradient background on a CanvasLayer, and a radial-alpha quad for the contact shadow. Visual refs `docs/refs/pool/keyframe_1..3.png` show a teal cloth with a brighter centre, wooden rails with small white sight dots, black pocket half-discs, a slight 3/4 perspective (the far rail is narrower), a thin 3D cue, a white dashed aim line ending in a ghost-ball circle, and balls about 20 px across in a 540 px wide mock (about 40 px on the 1080 canvas).

## 1. Ball rendering: numbers and stripes, UV layout, mesh resolution, shading model, anti-aliasing

### Takeaway
Use **one shared ball shader on one MultiMesh**. Choose the pattern from the ball's *object-space unit position* rather than mesh UVs: stripe = `abs(p.y) > band` gives white caps, and the number disc is a planar projection of `p.xy` on the ±z hemispheres, sampled from a 4x4 digit atlas indexed by `INSTANCE_CUSTOM`. This avoids pole and seam distortion and needs no per-ball textures. Shade it in the shader (house style) with a fixed lamp direction, a tight specular plus a fake environment reflection and Fresnel, rather than relying on StandardMaterial3D clearcoat and scene lights. For edges, the Godot docs point to FXAA as the safe mobile default and say MSAA 2x "may be usable"; device measurement is needed.

### Cited Findings
- A known billiard-ball fragment shader takes a point on the unit sphere plus a ball number. It makes balls 9–15 striped when `abs(point.y) > 0.55`, with a `smoothstep(0.55, 0.56, d)` edge to white. Stripes reuse the solid colours via `colorData[int(mod(number, 8))]` — [getlazarus "Rendering my balls in a fragment shader"](https://www.getlazarus.org/pool/balls/)
- The same shader draws the number where `abs(point.x) < 0.28 && abs(point.y) < 0.28` on the rotated point's xy plane. It flips x when `point.z < 0` so back-side numbers are not mirrored. A white disc sits at `d < 0.4` with a smoothstep to the ball colour. Digits come from a **4x4 atlas of numbers 1–16** addressed as `tex/4`, column `mod(n,4)*0.25`, row `n/4*0.25`. An `edge = 0.0033` guard returns white near cell borders to hide atlas seams — [getlazarus](https://www.getlazarus.org/pool/balls/)
- In that shader, orientation is applied by rotating the *normal/position vector* used for pattern lookup (`vec4(n, 0.)` times rotation matrices). Lighting uses the unrotated normal, so lights stay fixed while the pattern spins — [getlazarus](https://www.getlazarus.org/pool/balls/)
- Its lighting is a distant key light `clamp(dot(light, n), 0.1, 1.)` (0.1 acts as ambient), a back/rim light `pow(clamp(rim,0,1),3)`, and an optional Phong-style specular `pow(spec, 30.) * 0.9`. Edge AA uses narrow manual `smoothstep` ramps because "fragment shaders do not smooth edges on their own" — [getlazarus](https://www.getlazarus.org/pool/balls/)
- The classic OpenGL "toy ball" shader also shades a sphere with a procedural stripe and star from the analytic normal. Its band test compares the absolute component of the normalised surface point against a width and smooths the edge with `smoothstep` — [Mesa CH11-toyball.frag](https://nxr.netbsd.org/xref/xsrc/external/mit/mesa-demos/dist/src/glsl/CH11-toyball.frag); [OpenGL Programming Guide ch. 8](https://www.oreilly.com/library/view/opengl-programming-guide/9780132748445/ch08lev2sec2.html)
- StandardMaterial3D **clearcoat** "adds a secondary transparent coat pass… a smaller specular blob layered on top"; the docs give no cost figure. Specular modes are SchlickGGX, Toon and Disabled. Diffuse modes are Burley (default), Lambert, Lambert Wrap and Toon. **Per-vertex shading** "can considerably increase rendering performance" on low-end or mobile, and **Unshaded** is suggested for maximum performance — [Godot 4.7 Standard Material 3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- Minimum internal reflectivity is 0.04. Leave Specular at 0.5 because it is not energy-conserving. Roughness 0 is a mirror and 1 is fully blurred — [Godot 4.7 Standard Material 3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- AA on the Mobile renderer: **MSAA available (Medium cost)**, **FXAA available (Very Low cost)**, **SMAA 1x available (Low)**, **TAA not available**. The docs say: "for low-end platforms such as mobile… FXAA is usually the only viable option". 2x MSAA "may be usable in some circumstances", and higher levels are "unlikely to run smoothly on mobile GPUs" — [Godot 4.7 3D antialiasing](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html)
- MSAA does little against specular aliasing. The **screen-space roughness limiter** (Low cost) reduces it and is enabled by default on Forward+ and Mobile — [Godot 4.7 3D antialiasing](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html)
- Tile-based GPUs: changing per-pixel settings such as MSAA changes tile size, because the driver fits as many pixels per tile as on-chip memory allows — [Meta: Loads, Stores, Passes and Advanced GPU Pipelines](https://developers.meta.com/horizon/blog/loads-stores-passes-and-advanced-gpu-pipelines/). MSAA can be close to free when resolved in tile memory, "just don't go overboard with the sample count" — [Medium: MSAA for almost free on tile-based hardware](https://medium.com/p/21794c479cb9). Adreno tile memory (GMEM) is about 1 MB on Adreno 540/650 and about 2 MB on Adreno 740 (from search-result summaries of Qualcomm material; the primary Qualcomm pages now redirect and could not be fetched) — [Qualcomm Adreno tiling (redirected)](https://developer.qualcomm.com/sites/default/files/docs/adreno-gpu/snapdragon-game-toolkit/gdg/gpu/best_practices_tiling.html)
- A Godot PR on Compatibility-renderer MSAA cites ARM guidance against writing MSAA data out to a texture on mobile — [godot PR #83976](https://github.com/godotengine/godot/pull/83976). An issue reports Vulkan synchronization validation errors "especially with MSAA enabled" (not clearly a performance issue) — [godot issue #81060](https://github.com/godotengine/godot/issues/81060)

### Inferences
- **Pattern from object space, not UVs.** In `vertex()` pass `lp = normalize(VERTEX)` as a varying (the same pattern blocks_view uses with `lp = VERTEX`). In `fragment()`, renormalise and branch:
  - cue ball: plain white, optionally with a small red spot or none (original design).
  - solid: colour everywhere except the number disc.
  - stripe: colour where `abs(lp.y) < 0.55`, white caps elsewhere, with `smoothstep(0.55-w, 0.55+w, …)` where `w = fwidth(lp.y)` for resolution-independent AA. This beats the fixed 0.01 ramp in the getlazarus version.
  - number disc: on the hemisphere `sign(lp.z)`, `d = length(lp.xy)`; white where `d < 0.40`, digit from `atlas_uv = (vec2(lp.x * sign(lp.z), -lp.y) / 0.56 + 0.5)`, mapped into cell `ball_id`.
  
  Because the lookup uses the normalised position, there are no poles, no seams and no UV stretching. SphereMesh UVs are never read. Planar projection inside a disc of radius 0.4 (about 24° of arc) has under 10% stretch at the rim, which is invisible at ball size.
- **Atlas:** one 512x512 (4x4 cells of 128 px) RGBA or single-channel texture holding digits 1–15 (one cell spare). Import it with mipmaps and VRAM-compressed (ETC2/ASTC on Android). The digit is only about 10–14 screen px tall at gameplay zoom, so 128 px per cell is ample even for a close-up stroke cam. Store the ball id in `INSTANCE_CUSTOM.r` (as blocks_view does with `glyph / 8.0`) and the base colour via `set_instance_color` (remember `srgb_to_linear()`, as blocks_view notes). Digits must be the game's own font or glyph art (original-visuals rule).
- **Mesh resolution:** at about 40 canvas px (about 47 device px) ball diameter in the overview, a sphere's silhouette error with N radial segments is `r·(1−cos(π/N))`. That is 0.2 px at N=24 and 0.09 px at N=32 for r ≈ 24 px. **Use 32 radial segments x 16 rings** (about 560 vertices; 16 balls ≈ 9k vertices total) so the low stroke cam (balls maybe 150–250 px) still looks round. 24x12 is enough if the stroke cam never gets that close. Set it via `SphereMesh.radial_segments/rings` on the MultiMesh's mesh. These are Godot SphereMesh properties; the defaults (64x32) are heavier than needed.
- **Shading model recommendation (consistent with house style):** `render_mode unshaded` and compute:
  1. Lambert-wrap diffuse from a fixed overhead-lamp direction (world-space uniform, slightly toward the camera so the lit side faces the player), floored at about 0.25 ambient.
  2. A tight Blinn-Phong or GGX highlight (exponent about 60–120) from the same lamp, at the same screen-relative spot on every ball. That consistency is the strongest "pool ball" cue.
  3. A fake environment reflection: sample a tiny painted 128x64 lat-long or matcap texture (a dark room with one bright rectangular lamp shape) with the **view-space reflection vector**, weighted by Schlick Fresnel `0.04 + 0.96·(1−N·V)^5`, giving the varnished-resin look without a ReflectionProbe.
  4. Rim darkening toward the silhouette, which helps separation from the cloth.
  
  Normals must use the **unrotated** world normal while the pattern uses the rotated local position. With a MultiMesh this happens automatically: `NORMAL`/`VIEW` in view space are unrotated for lighting, while `VERTEX` before transform is in the ball's rotated local frame.
- The StandardMaterial3D alternative (albedo texture + clearcoat + roughness about 0.1 + a Sky or ReflectionProbe) is physically nicer but needs real lights and an environment, gives less control over the exact palette, and costs a lighting pass. The repo already chose unshaded with a linear tonemap for exact colours.
- **AA plan:** default **MSAA 2x** on the 3D viewport, with a settings toggle to **FXAA**, then measure on the Adreno 642L. Ball silhouettes against a flat teal cloth are the main aliasing source, and MSAA fixes geometry edges without blurring the digits. FXAA would soften digits. Shader-internal edges (stripe, number disc, dashed aim line) get AA from `fwidth`/`smoothstep`, which needs neither MSAA nor FXAA. Keep the roughness limiter on.
- A sphere impostor (camera-facing quad with analytic sphere normal and `discard` or alpha edge, as in getlazarus) would give perfectly round, self-antialiased silhouettes with 4 vertices per ball. But alpha edges need back-to-front sorting or alpha-to-coverage, and writing `DEPTH` defeats early-Z. Not worth it for 16 balls; keep real sphere meshes.

### Gaps
- No primary Qualcomm number for MSAA 2x/4x cost on Adreno 6xx was retrievable: the Qualcomm developer pages and the "Anti-Aliasing with Adreno" app note now redirect to an index or empty shell. Measure on the test phone (frame time with MSAA off/2x/4x, FXAA) using Godot's monitors or Snapdragon Profiler.
- No source gave a clearcoat cost figure for the Mobile renderer.
- No published Godot-specific billiard ball shader was found. The technique sources are WebGL and desktop GLSL.

## 2. Ball orientation from angular velocity

### Takeaway
Keep a **visual-only orientation per ball** (a `Basis` or `Quaternion`) owned by the renderer, never fed back into the solver. Integrate it with the solver's angular velocity, ideally once per fixed solver step with the step's dt, using `q = Quaternion(ω̂, |ω|·dt) * q` (world-frame ω, so pre-multiply), and normalise after each update. Because the solver moves the nodes itself, follow the project rule: `physics_interpolation_mode = OFF` on the game root, and interpolate (lerp position, slerp orientation) yourself using `Engine.get_physics_interpolation_fraction()` if rendering runs between ticks.

### Cited Findings
- Godot physics interpolation renders objects between the previous and current physics transforms (including rotation). It is available from `Engine.get_physics_interpolation_fraction()`, shows objects one to two ticks in the past (adding slight latency), and the tick rate defaults to 60/s — [Godot 4.7 physics interpolation introduction](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html)
- "The most fundamental requirement for physics interpolation" is to move objects and run game logic in `_physics_process`, not `_process`. Setting transforms of interpolated objects outside the tick causes jitter that "may not be visible on your machine, but it will occur for some players." Teleports should set the transform and then call `reset_physics_interpolation()`; otherwise "the worst that will happen is seeing a streaking motion for a frame or so" — [Godot 4.7 using physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html)
- For testing, temporarily set the physics tick rate to a low value such as 10 TPS to expose interpolation problems — [Godot 4.7 using physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html)
- Project rule (repo CLAUDE.md): physics interpolation is ON project-wide; a game that moves nodes itself in `_process` (cue_sim renderers included) must set `physics_interpolation_mode = OFF` on its root, or the first frames and teleports render smeared (seen on device 2026-11-11) — `/Users/sandeep/Documents/GitHub/android-game-04/CLAUDE.md`
- The getlazarus reference applies orientation only to the pattern-lookup vector, not to lighting, which confirms that orientation can be purely visual — [getlazarus](https://www.getlazarus.org/pool/balls/)

### Inferences
- **Integration (no allocations):** for each ball, with `w: Vector3` (rad/s, world frame) and `dt` (solver step):
  ```gdscript
  var a := w.length() * dt
  if a > 1e-6:
      _q[i] = (Quaternion(w / w.length(), a) * _q[i]).normalized()
  ```
  `Quaternion` is a value type in GDScript (no heap allocation). Store orientations in a `PackedVector4Array` or a typed `Array[Quaternion]` preallocated for 16 balls. Write `Transform3D(Basis(_q[i]) * radius_scale, pos)` into the MultiMesh with `set_instance_transform`. Normalising every update costs nothing and prevents drift; a Basis would need `orthonormalized()`, which is costlier, so prefer Quaternion as the state and convert once.
- **Sync with deterministic physics:** do not feed orientation back. Integrate it in the same fixed-step loop that advances cue_sim (or in the renderer, replaying the solver's per-step ω). Replays then reproduce the same visual spin. Renderer-side integration with render delta is acceptable only because orientation is cosmetic. It would drift between devices, which matters only if replays or shared clips should look identical.
- **Rolling check:** for pure rolling on a table whose plane is XZ with Y up, `ω = up.cross(v) / R`. Verify the sign in a unit test, because a ball that rolls backwards visually is the most common bug. Spin about the vertical axis (side spin) is just the y-component of ω, with no special case.
- **Temporal aliasing (wagon-wheel):** a 57 mm ball at 4 m/s rolls at ω = v/R ≈ 140 rad/s. That is 2.3 rad per frame at 60 fps and 4.7 rad (more than π) at the 30 fps floor, so the number or stripe can appear to spin backwards or strobe. Mitigations: (a) clamp the *visual* angle per rendered frame to about 1.2 rad while keeping the accumulated direction correct, and/or (b) pass speed in `INSTANCE_CUSTOM.g` and fade stripe and digit contrast toward the average colour above about 1.5 rad per frame, as a cheap "motion blur". Physics is unaffected. (The 57.15 mm / 2.25 in ball diameter is the standard size and is not cited here.)
- **Interpolation choice:** either (A) step cue_sim in `_physics_process` at 60 TPS (internal substeps allowed) and write transforms there, leaving interpolation ON so Godot interpolates for free. Then call `reset_physics_interpolation()` when a pocketed ball is moved to the tray or the cue ball is re-spotted. Godot's slerp will alias at more than π per tick (see above), so clamp anyway. Or (B), the project-rule path: root `physics_interpolation_mode = OFF`, keep prev/curr pos+quat per ball, and in `_process` render `lerp`/`slerp` by `Engine.get_physics_interpolation_fraction()`. (B) matches CLAUDE.md and the existing snake/blocks practice. Recommend (B).

### Gaps
- The "Using physics interpolation" page does not document `physics_interpolation_mode` values or advanced/custom interpolation. The "Advanced physics interpolation" page was not fetched.
- No source was found on perceptual thresholds for rotation strobing. The 1.2 rad per frame figure is a heuristic to tune on device.

## 3. Table: cloth, rails, pockets, sights, lighting and shadows

### Takeaway
Build the table from **3–5 draw calls**: cloth plane, cushions+rails+wood (one mesh, one shader, vertex colours or a material ID per region), pockets, and a sights MultiMesh (or sights drawn in the rail shader). Fake the overhead-lamp look in the shaders: radial "pool of light" falloff on the cloth, a darker vignette toward the rails, and specular on the varnished wood. Use **blob/contact shadows** (one MultiMesh of soft quads under the balls) instead of DirectionalLight shadows. LightmapGI is supported on Mobile but is unnecessary for a single static table lit by a lamp you can paint into the shader.

### Cited Findings
- On the Mobile renderer: LightmapGI **Yes**; ReflectionProbe **Yes, 8 per mesh**; Decals **Yes**; SSAO, SSR, SSIL, SDFGI, VoxelGI and volumetric fog **No**; Glow **Yes**; depth/height fog **Yes**; PCSS for Omni/Spot **Yes**, for Directional **No** — [Godot 4.7 renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Mobile renderer lighting is "Forward single-pass". Colour precision is "RGB10A2. Medium dynamic range, low precision" (RGBA16F only if HDR 2D is enabled). Depth is 24-bit reverse-Z. Cost is "Medium base cost, and medium scaling cost" — [Godot 4.7 renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Realtime lighting and shadows (especially with multiple lights) "may simply be too much for lower power mobile devices"; consider baked lighting, especially on mobile. Static bake mode skips real-time lighting on baked meshes. A suggested balance is keeping DirectionalLight3D Dynamic and setting most omni/spot lights to Static — [Godot 4.7 optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Directional shadows: a single orthogonal map, or PSSM with 2 or 4 splits (default 4). "An object spanning all four splits is drawn five times" (four shadow passes plus the scene pass). Set shadow **Max Distance** for quality and performance. Default filter is **Soft Low**. Shadow depth defaults to **16-bit**, which "performs better with little visible difference". Positional shadow atlas defaults to 4096, and the docs suggest 2048 for low-end GPUs — [Godot 4.7 lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Decals: cost depends mainly on **screen coverage**, then count ("a few large decals that cover up most of the screen will be more expensive… than many small decals"). Keep the projection length (Extents Y) short. On Mobile, "only 8 decals can apply to each individual Mesh resource". Decals cannot use custom shaders. **Blob shadows** are named as a decal use case "useful on mobile", and as cheap ambient occlusion where SSAO is too costly — [Godot 4.7 using decals](https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html)
- StandardMaterial3D supports triplanar mapping (object or world space) and an anisotropy specular effect for brushed metal/hair (not texture-filter anisotropy) — [Godot 4.7 Standard Material 3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- The house style already draws a contact shadow as a quad with `ALPHA = strength * (1 - smoothstep(0.15, 1.0, r))` (unshaded, `blend_mix`, `depth_draw_never`) — `/Users/sandeep/Documents/GitHub/android-game-04/games/blocks/scenes/blocks_view.gd` (SHADOW_SHADER)

### Inferences
- **Cloth shader** (unshaded, 1 draw):
  - `base = teal` (match keyframes).
  - `lamp = mix(0.78, 1.10, 1 - smoothstep(0.0, 1.0, length((world.xz - lamp_xz) / lamp_radius)))` for the brighter centre seen in the refs; one or two lamp centres for a long table.
  - Vignette darkening of about 10–15% within 4–6 cm of the cushion line (fake AO).
  - Fine fibre noise: a pre-baked 256x256 tileable grey noise PNG (mipmapped, VRAM-compressed), repeated about every 10–15 cm, at ±3–4% amplitude so it does not shimmer. Mipmaps plus low amplitude keep it from aliasing at a distance.
  - **Nap:** a ±2–3% brightness term from `dot(view_dir_xz, nap_dir)`, with nap running head to foot, so the cloth subtly changes tone as the stroke cam orbits.
  
  Avoid generating `NoiseTexture2D` at runtime (generation cost on load); bake it to a PNG.
- **Rails/cushions/wood** as one mesh (a few hundred vertices) with a "SOLID_SHADER"-style unshaded material. Use vertex colour or a UV2 region ID to select cloth-cushion vs wood vs pocket liner. Wood gets a procedural grain (stretched 1D noise or a 256 px grain strip) plus a Blinn highlight from the lamp for varnish. Cushion tops take the cloth colour at about 0.85 brightness.
- **Pockets:** draw pocket mouths as black, slightly soft-edged discs or half-discs on the cloth plane (one MultiMesh of 6 quads, or geometry baked into the cloth mesh with a radial gradient), plus a dark liner in the rail mesh, as in the keyframes. For balls dropping in, animate the ball's y below the cloth and clip it in the ball shader: `discard` when `world.y < cloth_y` and the fragment is inside the pocket radius. Alternatively scale/fade over 0.2–0.3 s. Real holes in the cloth mesh are unnecessary.
- **Sights/diamonds:** 18 small inlays. Cheapest is an SDF in the rail shader at known positions (0 extra draw calls). The next option is a MultiMesh of 18 quads (1 draw). Keep them original: small dots or lozenges in a mother-of-pearl colour, as in the refs.
- **Shadows:** a MultiMesh of 16 soft quads (`depth_draw_never`, `blend_mix`) placed at each ball's xz with y = cloth + 0.5 mm. Offset each about 0.15R away from the nearest lamp centre and stretch it slightly along that direction for a believable overhead-lamp look. Add a smaller, darker core (contact AO) at the touch point. Fade the shadow when a ball leaves the cloth (jump or pocket). Cost is 1 draw call and tiny overdraw. Using Decal nodes instead would cost screen-coverage fill and hits the Mobile **8 decals per mesh** limit: 16 balls on one cloth mesh would exceed it. **Do not use Decals for ball shadows.**
- **If real shadows are ever wanted:** one DirectionalLight3D, `directional_shadow_mode = ORTHOGONAL` (one pass), Max Distance about 4–5 m, Soft Low, 16-bit. Casters are the ball MultiMesh only (cast_shadow off for table and cue), so it adds about 1 extra draw in the shadow pass plus PCF sampling on every lit cloth pixel. Measure before committing; blob shadows look better at this scale anyway.
- **Baked lighting:** LightmapGI would need lights, UV2 unwraps and a bake step for a scene whose look is fully art-directable in about 20 lines of shader. Skip it. Paint the lamp falloff and AO in shaders or vertex colours.
- **Glow:** a gentle glow on ball highlights and the lamp reflection only. RGB10A2 gives limited HDR headroom, so keep the house `glow_hdr_threshold ≈ 1.1–1.2` and highlight peaks around 1.3–1.6.
- **Background:** reuse the house BG_CANVAS gradient: dark warm room colours, with a radial vignette layer.

### Gaps
- No primary source gave a measured cost for one DirectionalLight with shadows on Adreno 6xx in Godot 4.7.
- No Godot-specific cloth or billiard-table shader reference was found. The cloth recipe is an inference.

## 4. Camera: portrait overview, low stroke camera, transitions, orthographic option

### Takeaway
With the table's long axis vertical on a 20:9 portrait screen, use `keep_aspect = KEEP_WIDTH` (which the Godot docs name as best for portrait) and a **long lens**: about 20–24° horizontal FOV. A slight pitch (about 8–15° off straight down) gives the 3/4 look in the refs while keeping sphere distortion at the table ends around 5%. Use exponential-damped transitions to a low behind-the-cue stroke cam with no roll. Orthographic, as blocks uses, is a valid fallback for the aim view.

### Cited Findings
- `Camera3D.keep_aspect`: "KEEP_WIDTH: This is usually the best option for projects running in portrait mode"; KEEP_HEIGHT is for landscape. `fov` is in degrees, and "since keep_aspect locks one axis, fov sets the other axis' field of view angle" (wording as rendered by the fetch tool, see Gaps). Orthogonal `size` is "the diameter of the width or height, depending on keep_aspect" — [Godot 4.7 Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)
- The house blocks view uses `PROJECTION_ORTHOGONAL`, `KEEP_WIDTH`, `camera.size = canvas.x / cell` (1 world unit = 1 cell), a 9° pitch, a ±1.5° slow sway and an exponential smoothing factor `1 - exp(-delta * 28)` — `/Users/sandeep/Documents/GitHub/android-game-04/games/blocks/scenes/blocks_view.gd`

### Inferences
- **Screen fit math** (9 ft table, play field 2.54 x 1.27 m, rails about 0.12 m each, outer about 2.78 x 1.51 m). The outer aspect 1.84 is below the screen's 2800/1260 = 2.22, so the table fits by width. That leaves about (2.22 − 1.84)/2.22 ≈ 17% of screen height (about 410 canvas px at 1080 x 2400) for the HUD bars, which matches the keyframes. If cue_sim uses a smaller table, the same method applies.
- **FOV:** under KEEP_WIDTH, `fov` acts horizontally. This is engine behaviour; verify in-editor because the class-ref sentence is ambiguous. Horizontal 22° with table width 1.51 m filling about 92% of width gives distance `d = (1.51/0.92/2) / tan(11°) ≈ 4.2 m`. The vertical half-angle across the table is then about `atan(tan(11°)·1.84/0.92·…)` ≈ 18–19°. A sphere at that angle renders about `1/cos(19°) ≈ 1.06` times elongated, which is acceptable. At horizontal 35° the ends stretch about 12–14% and balls visibly egg out. **Range 18–26° horizontal.**
- **Pitch:** tilt about 10–15° from vertical toward the player (camera south of centre looking north). The far rail then looks slightly narrower, as in keyframe 1 and 3, and the near pockets stay readable. Keep the table centred: compute the camera position from the pitch so the table's projected centre lands at the layout's table rect centre, the same approach as `BlocksView.camera_transform`.
- **Stroke cam (optional "line up" mode):** eye about 0.25–0.35 m above the cloth, 0.6–0.9 m behind the cue ball along the aim line, pitched 12–20° down, horizontal FOV about 40–50° (portrait means wide vertical coverage). Look at a point about 0.4–0.6 m beyond the cue ball along the aim line so the object ball and target pocket stay in frame. Never roll; world up stays up.
- **Transitions:** blend position and look-target separately with critically damped exponential smoothing (`k ≈ 6–10 s⁻¹`, settles in about 0.4–0.6 s). Do not lerp Transform3D directly: lerp eye and target vectors and rebuild with `looking_at`. Also lerp FOV. Avoid camera motion while balls are moving after the shot unless it is slow (about 1.5 s easing) and user-enabled. Snap, rather than ease, when the user switches views repeatedly in under 0.3 s.
- **Motion-sickness heuristics (uncited):** no roll, no camera shake on routine shots (keep blocks-style shake for breaks or pots only, small amplitude), no FOV pumping, and a settings toggle "auto camera off" that stays on the overview.
- **Orthographic option:** ortho gives zero sphere distortion and exact screen-space aim lines (easy to reason about), but loses depth cues and the 3/4 feel. Godot cannot blend projection modes. To transition from ortho to perspective, fake ortho with a very long lens (horizontal FOV about 5–8° at distance about 15–20 m) and dolly-zoom to the stroke cam. Since `far` must cover that distance, keep `near` at about 0.5–1 m to preserve depth precision (24-bit reverse-Z is fine at these ranges).

### Gaps
- The fetched Camera3D wording about which axis `fov` applies to under KEEP_WIDTH was ambiguous ("fov sets the other axis"). Confirm in the editor with a test scene before locking numbers.
- No authoritative source on camera-motion comfort thresholds for mobile games was found.

## 5. Cue stick and aim guideline (dashed line, ghost ball): 3D vs 2D overlay

### Takeaway
Render the cue, aim line and ghost ball **in 3D**: correct under perspective and when the camera moves, occluded properly by rails, and cheap (about 3 draw calls). Build them from **preallocated meshes moved by transform plus shader uniforms**, never `ImmediateMesh` or per-frame `ArrayMesh` rebuilds, to keep `_physics_process` and `_process` allocation-free.

### Cited Findings
- Transparent objects must render back-to-front and cannot be sorted by material, "so use as few as possible". If only part of an object is transparent, make that part a separate surface — [Godot 4.7 optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- The house style already has a ghost-piece shader: unshaded, `blend_mix`, `depth_draw_never`, mostly transparent interior with bright edges (`ALPHA = 0.08 + 0.75 * edge`) — `/Users/sandeep/Documents/GitHub/android-game-04/games/blocks/scenes/blocks_view.gd` (GHOST_SHADER)
- Decals suit fading gameplay marks but cannot use custom shaders, and Mobile allows only 8 per mesh — [Godot 4.7 using decals](https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html)

### Inferences
- **Aim line:** one `QuadMesh` (unit length, 1 cm wide) lying on the cloth at `y = cloth + 1 mm`, transformed each frame to start at the cue ball and end at the ghost-ball position. Set the length via `scale.x` and pass `length_m` as a shader uniform (or instance uniform). Dashes come from `fract(UV.x * length_m / dash_period)` with `fwidth` AA. A world-space dash period (about 3 cm on, 2 cm off) foreshortens naturally in the stroke cam. Use unshaded white at about 0.8 alpha, `depth_draw_never`. A second short quad shows the object ball's predicted direction. A third quad shows the cue ball's deflection: the tangent line, shortened or hidden on harder difficulty settings, since aim assistance is a design choice.
  - Screen-space thickness is optional: widen the quad in the vertex shader by camera distance so the line stays about 3–4 px wide in both cameras.
- **Ghost ball:** a second MultiMesh instance or one extra MeshInstance3D with the same SphereMesh and a ghost shader (rim-only alpha, like GHOST_SHADER, with Fresnel `pow(1-N·V, 2)`). Alternatively, a flat ring quad on the cloth (keyframe 1 shows a thin circle). The flat ring is cheaper and never z-fights the object ball.
- **Cue:** a tapered `CylinderMesh` (top radius about 6.5 mm, bottom about 14 mm, length about 1.45 m, **12 radial segments, 1 ring**, about 30 vertices) with an unshaded or lit shader giving a light wood shaft, a dark butt wrap, a white ferrule and a blue chalk tip. Use bands along local y, with no textures. Place it along the aim direction, elevated by the solver's cue elevation, with its tip offset from the cue ball by the pull-back amount (power meter). Set `cast_shadow` off. When the low stroke cam puts the cue between camera and balls, fade the cue's butt with a distance-to-camera alpha, or simply keep the stroke-cam eye above the cue line.
- **2D overlay alternative:** a Line2D or `_draw()` between `camera.unproject_position()` endpoints works and gives constant pixel width. But dashes do not foreshorten, rails do not occlude the line, and it must be recomputed whenever the camera moves. It is fine for the ortho overview only. Keep spin, power and HUD controls in 2D (as in the keyframes), and keep everything spatial in 3D.

### Gaps
- No source on aim-line readability metrics (minimum px width, contrast) on mobile was found. Validate with screenshots per the repo's definition of done.

## 6. Performance budgets, Mobile renderer limits, physics interpolation

### Takeaway
The whole scene can fit in **about 10–15 opaque/transparent 3D draw calls and under 20k vertices**: balls 1, shadows 1, cloth 1, rails 1, pockets 1, sights 0–1, cue 1, aim 2–3, ghost 1. On the Mobile renderer, MultiMesh matters because automatic instancing is Forward+ only. The real cost driver on a 1260x2800 Adreno 642L is **fill rate**: full-screen cloth, transparent quads, MSAA and post-processing. Budget for that with a 3D resolution scale and few transparent layers.

### Cited Findings
- Automatic instancing of identical MeshInstance3D nodes "is only implemented in the Forward+ renderer, not Mobile or Compatibility". Use **MultiMesh**, which can draw "many thousands of objects at very little performance cost" — [Godot 4.7 optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Mobile light limits: **8 OmniLights and 8 SpotLights per mesh, 256 of each per view; up to 8 DirectionalLights**. These "cannot currently be changed" — [Godot 4.7 lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html); [Godot 4.7 renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- The positional shadow atlas defaults to 4096 with 4+4+16+64 = 88 shadowed-light slots; 2048 is suggested for low-end GPUs — [Godot 4.7 lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- The optimizing page gives **no numeric draw-call or vertex budgets** and no tile-based GPU guidance — [Godot 4.7 optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Qualcomm guidance (via search summaries of the Snapdragon Game Developer Guide): clear or invalidate framebuffer attachments so the GPU does not load tile data from system memory; use fewer render passes because each load/store round-trips through system memory; sort opaque draws front-to-back where possible — [Qualcomm Adreno best practices (redirected)](https://developer.qualcomm.com/sites/default/files/docs/adreno-gpu/snapdragon-game-toolkit/gdg/gpu/best_practices.html); [Vulkanised 2026 Qualcomm talk](https://vulkan.org/user/pages/09.events/vulkanised-2026/1645-Srihari-Alla-Qualcomm.pptx.pdf)
- Google worked with the Godot team on Android Vulkan fixes merged into Godot 4, e.g. replacing large push constants with uniform buffers and adding pre-rotation support — [Android Developers: Godot Engine Vulkan optimization for Android](https://developer.android.com/stories/games/godot-vulkan)
- Physics interpolation rules (from section 2): move in `_physics_process`, `reset_physics_interpolation()` on teleports — [Godot 4.7 using physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html). Repo rule: renderers that move nodes in `_process` set the root `physics_interpolation_mode = OFF` — `CLAUDE.md`

### Inferences
- **Fill-rate budget:** 1260 x 2800 = 3.53 Mpx per layer, so 212 Mpx/s at 60 fps for one opaque layer. Cloth plus rails cover about 80% of the screen once. Keep transparent overlap small: the shadows are 16 small quads, the aim line is thin, and the HUD panels are CanvasItems. Set `rendering/scaling_3d/scale` to about 0.8 on low-end devices (a quality toggle) while 2D UI stays native. (Godot 4's 3D scaling affects only the 3D buffer; verify on device.)
- **Suggested budget table** (for an Adreno 6xx mid-range target; uncited heuristics, verify with the Godot monitor `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` and Snapdragon Profiler):
  - 3D draw calls: under 20 (planned about 12).
  - Vertices: under 30k (planned: balls 9k, table about 2k, cue 30, quads trivial).
  - Real lights: 0. Shadow maps: 0.
  - Transparent 3D layers per pixel: at most 2.
  - Post: glow (low intensity) + MSAA 2x *or* FXAA.
  - Textures: one 512² digit atlas, a 256² cloth noise, a 128x64 env strip and a 256 px wood strip, all VRAM-compressed and mipmapped.
- **No per-frame allocations:** preallocate MultiMesh `instance_count = 16` once and only call `set_instance_transform/color/custom_data`. Store orientations in a preallocated array. Do not build strings or Arrays in render (blocks_view builds a `key` string per frame. Avoid copying that pattern). Use `material.set_shader_parameter` sparingly; per-ball data goes through instance custom data.
- **Shader compile hitches:** first-use pipeline compilation can stutter on Android. Render every Cue Club material once behind the loading screen (e.g. one frame with all balls, the ghost, the aim line and the cue visible). Godot 4.4+ added pipeline precompilation and ubershaders to reduce this (from memory, not verified in this session).
- **Thermals:** a game that sits idle between shots (aiming) can drop to an on-demand cadence. Keep 60 fps while balls move or the camera animates, and consider `Engine.max_fps = 30` while the aim UI is idle. This is a product decision; it halves GPU time while aiming.

### Gaps
- No authoritative numeric draw-call, vertex or fill-rate budgets for Adreno 642L or 6xx in Godot 4.7 were found. The Qualcomm developer guide pages now redirect to a landing page.
- No Godot issue was found that specifically measures Mobile-renderer MSAA cost on Adreno.

## 7. Godot-specific features: Decal cost, ReflectionProbe, SSAO/SSR on Mobile, ShaderMaterial tips

### Takeaway
On the Mobile renderer: **SSAO, SSR, SSIL, SDFGI, VoxelGI, TAA and volumetric fog are unavailable**. Decals and ReflectionProbes work but have per-mesh caps of 8, and decals cost by screen coverage. A single `UPDATE_ONCE` ReflectionProbe is affordable, but a painted environment strip sampled in the ball shader gives a more controllable result at lower cost. Use ShaderMaterials (as in the house style) with instance data via MultiMesh.

### Cited Findings
- Mobile renderer availability: SSAO No, SSR No, SSIL No, SDFGI No, VoxelGI No, LightmapGI Yes, ReflectionProbe Yes (8/mesh), Decals Yes, MSAA Yes, FXAA Yes, TAA No, Glow Yes, volumetric fog No — [Godot 4.7 renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- ReflectionProbe: **Update Mode Once** (default) re-renders only when moved and "is much faster". **Always** re-renders everything around it every frame (far more expensive). Keep **Enable Shadows** off in Always mode. Use **Cull Mask** to exclude small objects (also avoids self-reflection). Box Projection adds a small cost and suits box-shaped rooms. Interior mode stops sky ambient. Mobile allows **8 probes per mesh** (Compatibility 2) — [Godot 4.7 reflection probes](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/reflection_probes.html)
- Decals: cost scales with screen coverage, Mobile allows 8 per mesh, there are no custom shaders, and the texture filter is a project setting (Linear Mipmaps Anisotropic is the highest quality and slowest) — [Godot 4.7 using decals](https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html)
- Subsurface scattering is Forward+ only; per-vertex and unshaded shading are the recommended low-end paths — [Godot 4.7 Standard Material 3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- Mobile renderer HDR precision is RGB10A2 (medium dynamic range, low precision) — [Godot 4.7 renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)

### Inferences
- **ReflectionProbe for balls?** One probe (Update Once, Interior on, cull mask = table + room, not balls) above the table would give lit balls real reflections of the rails and lamp. But it only matters if balls use a lit StandardMaterial3D. With the recommended unshaded custom shader, a hand-painted 128x64 environment strip (dark room, rectangular lamp, faint rail band) sampled by the reflection vector is cheaper, fully original and art-directable. Skip the probe.
- **Ball-on-ball reflections and SSR** are not possible on Mobile. Fake "contact" with the blob shadow and a slight darkening of the ball's lower hemisphere (`ALBEDO *= mix(0.75, 1.0, smoothstep(-0.6, 0.2, world_normal.y))`), which reads as ambient occlusion from the cloth. That replaces SSAO.
- **ShaderMaterial tips:**
  - Share one Shader resource across materials and use instance data rather than material duplicates (MultiMesh color + custom data, as blocks_view does).
  - Keep `render_mode unshaded` for exact palette control with the linear tonemap.
  - Prefer `fwidth`-based AA for procedural edges.
  - Mark per-ball colour `source_color` or convert with `srgb_to_linear()` before `set_instance_color`.
  - Avoid `discard` on large surfaces (it hurts early-Z/HSR on tilers); restrict it to the pocket-drop case on balls.
  - Avoid `DEPTH` writes.
  - Keep transparent materials `depth_draw_never` and small.
  - Precompute anything uniform-only (lamp direction, env rotation) on the CPU rather than per fragment. The getlazarus shader recomputes three rotation matrices per pixel, which is unnecessary when the MultiMesh transform already carries orientation.
- **Do not port `docs/refs/pool/prototype.html` code** (repo rule). The keyframes are visual targets only.

### Gaps
- No source quantified decal or ReflectionProbe GPU cost on Adreno in Godot 4.7.
- Whether Godot 4.7's Mobile renderer uses subpasses or tile-memory-friendly MSAA resolve on Vulkan was not confirmed by any fetched doc. The renderers page does not discuss tiling.
