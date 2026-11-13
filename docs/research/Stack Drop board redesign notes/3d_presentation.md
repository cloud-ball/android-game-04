# 3D presentation of a vertical 2D-grid puzzle field on a portrait phone (Stack Drop, Godot 4.7 Mobile)

Scope: camera setup, framing and grounding, block rendering, Mobile-renderer performance, and Godot-specific
camera and environment controls for a 9x18 "crystal tower" of gem cubes. Facts carry inline sources. Numbers
I derived myself (geometry, dp maths) are listed under **Inferences** with the working shown so the writer can
check them. All recommendations are generic and are not modelled on any commercial game's look.

Baseline numbers used in the inferences:
- A 20:9 phone at 1080x2400 px and density 2.625 is about **411 x 914 dp**. Android dp = 1/160 inch
  ([SAP Fiori Android, dp](https://experience.sap.com/fiori-design-android/?p=22054)).
- The grid is 9 x 18, so its aspect is 1:2 (0.50). A 20:9 screen's aspect is 0.45, so the grid is
  **width-limited**: at full screen width each cell is about 411/9 = **45.7 dp** and the grid is about 822 dp tall.
  That leaves roughly 90 dp of 914 for the score bar, pedestal and margins. This explains the "huge chunky cubes
  / cut-off pedestal / cramped" report.

---

## Camera: FOV, pitch, long lens vs orthographic, acceptable perspective shrink

### Takeaway
How large a cube looks and which of its faces show depend only on where the camera sits relative to each cube,
not on the lens ([Wikipedia: perspective distortion, via search summary](https://wiki.krisyotam.com/content/wikipedia_en_all_nopic_2026-03/Perspective_distortion);
[PhotoShelter, mathematician on "lens compression"](https://blog.photoshelter.com/2018/06/a-mathematician-weighs-in-on-lens-compression/)).
At a 30° vertical FOV with a 7° pitch, the top rows are seen slightly from below and the bottom rows from about
22° above. That inconsistency is the main cause of the "chunky" look. Two fixes work:
- **Long lens:** vertical FOV about 12-18°, camera pulled back, pitch about 4-8°.
- **Orthographic with a fixed tilt:** pitch about 6-10°. Every cell gets an identical top-face sliver and verticals stay perfectly parallel.

### Cited Findings
- Focal length only changes field of view; the "flattening" of a long lens comes from standing farther away.
  Crops of images taken from the same position at different focal lengths show identical perspective —
  [Wikipedia: perspective distortion](https://wiki.krisyotam.com/content/wikipedia_en_all_nopic_2026-03/Perspective_distortion);
  [PhotoShelter](https://blog.photoshelter.com/2018/06/a-mathematician-weighs-in-on-lens-compression/);
  [scubageek, "compression is a myth" (PDF)](https://www.scubageek.com/articles/compression.pdf).
- Wikipedia splits the effect into "extension (wide-angle) distortion" and "compression (telephoto) distortion"
  — [Wikipedia](https://wiki.krisyotam.com/content/wikipedia_en_all_nopic_2026-03/Perspective_distortion).
- A focal length equal to the sensor diagonal (about 50 mm on 35 mm film) is the usual rule of thumb for a
  "natural" look. That is about 27° vertical FOV on full frame (my conversion) —
  [Wikipedia](https://wiki.krisyotam.com/content/wikipedia_en_all_nopic_2026-03/Perspective_distortion).
- Converging verticals appear whenever the lens is aimed away from the horizon. Architectural photographers keep
  the camera level and shift the lens instead ("rising front"), so verticals stay vertical —
  [Cambridge in Colour, tilt-shift lenses](https://www.cambridgeincolour.com/tutorials/tilt-shift.htm);
  [Maxwell Render, Shift Lens](https://nextlimitsupport.atlassian.net/wiki/spaces/maxwell/pages/22685267).
- "A slight bit of convergence is desirable": perfectly parallel verticals can look overdone or unrealistic —
  [Cambridge in Colour](https://www.cambridgeincolour.com/tutorials/tilt-shift.htm).
- In Godot's orthographic mode, objects keep the same on-screen size at any distance. Its docs say 3D games that
  "look 2D" often use this projection —
  [Godot Camera3D docs](https://docs.godotengine.org/en/stable/classes/class_camera3d.html).

### Inferences
Geometry is my own; check it against the screenshots.

- **A flat plane facing the camera has uniform cell size under perspective.** With 0° pitch, the front faces of
  all cells project at exactly the same size, whatever the FOV. Size differences between top and bottom come from
  pitch. Visible side, top and bottom faces come from the off-axis viewing angle multiplied by cube depth.
- **Top/bottom size ratio when pitched:** about (1 + t·sinθ) / (1 − t·sinθ), where t = tan(FOV/2) and the tower
  fills the frame.

  | Setup | Top rows larger than bottom rows by |
  |---|---|
  | FOV 30°, pitch 7° | about **6.8%** |
  | FOV 18°, pitch 7° | about 3.9% |
  | FOV 12°, pitch 7° | about 2.6% |
  | Orthographic (any pitch) | 0% |

  Below about 5% the shrink is hard to see. 5-10% reads as "a tower looming over you". It does not hurt
  readability, but it does make the field feel tilted.
- **Visible top face of a cube** is roughly cube depth × tan(angle of the view ray below horizontal). With depth
  0.94 cell:

  | Setup | Top rows | Bottom rows |
  |---|---|---|
  | FOV 30°, pitch 7° | ray 8° **upward**: underside shows, about 0.13 cell | about 0.94 × tan 22° ≈ **0.38 cell** of top face |
  | FOV 15°, pitch 7° | about 0 | about 0.94 × tan 14.5° ≈ 0.24 cell |
  | Ortho, pitch 8° | 0.94 × sin 8° ≈ 0.13 cell | 0.13 cell (same everywhere) |

  The 30° case reads as chunky and inconsistent. The orthographic case looks deliberate, like a diorama.
  The same reasoning applies sideways. At the outer columns, side faces show about depth × tan(horizontal
  half-angle): about 0.94 × 0.12 ≈ 0.11 cell at FOV 30° on a 9:20 screen, and about half that at FOV 15°.
- **Cheapest de-chunking lever: thinner cells.** Making the gem "slabs" 0.4-0.6 cell deep instead of 0.94
  shrinks every visible side or top face proportionally, with no camera change. Combined with a long lens, the
  depth still reads, through lighting and the bevel, without blocky sides.
- **Recommended options, in order:**
  - **(A) Long lens.** Perspective, vertical FOV 14-18°, pitch 5-8°, camera aimed at about 45% of the tower's
    height. Distance for a field plus pedestal about 22 units tall at FOV 16°: d ≈ 11 / tan 8° ≈ 78 units.
    Set `near` about d − 20 and `far` about d + 40 to keep depth precision. Godot warns that a low `near`
    reduces precision ([Camera3D docs](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)).
  - **(B) Orthographic.** Pitch 6-10°. Use it if a perfectly uniform grid is the priority. Lighting, a contact
    shadow, fog on the floor and a background gradient then provide the depth that perspective no longer gives.
  - **(C) Frustum (lens-shift) projection.** FOV about 18°, pitch 0-4°, with the vertical frustum offset used to
    place the tower in frame instead of pitching. This gives nearly parallel verticals with a slight, controllable
    convergence. Per Cambridge in Colour, a little convergence is fine.
- **Avoid FOV 25-35° with pushed-in framing for a 1:2 grid.** It maximises the inconsistency between top and
  bottom faces described above.

### Gaps
- I found no published puzzle-game camera spec (FOV or pitch) from a developer talk or article. The numbers above
  are derived geometry, not industry-sourced. Validate them with the project's `shot` skill at the three presets.
- I found no study giving a perceptual threshold for "acceptable" size variation across a grid. The 5% figure is
  a judgement call.

---

## Framing and grounding: pedestal, floor, contact shadow, vignette/fog, composition and margins

### Takeaway
The tower should not fill the screen. It should be shrunk so the whole object, including the pedestal and a
soft contact shadow, sits inside the frame with even breathing room, and its base ends clearly above the bottom
controls or HUD. Too little negative space feels cramped. Too much weakens the subject. A cut-off base reads as an
accident unless the crop is deliberate and generous.

### Cited Findings
- Negative space is the unoccupied area around the subject. Headroom is "a critical buffer of negative space that
  prevents the viewer's eye from feeling crowded at the top of the image" —
  [Brainbound, headroom guide](https://www.brainbound.blog/headroom-photography-composition-guide).
- On spacing: "Too little and there can be a cramped feeling; too much and the strength of the subject is reduced"
  — [Envato Tuts+, 10 rules for shot composition](https://photography.tutsplus.com/articles/10-rules-for-better-shot-composition-framing-in-photography-and-film--cms-108492).
- The rule of thirds is a placement guide, not a law ("not every composition benefits from this rule"), and the
  rule of space is "simply a guide" —
  [Lovart composition rules](https://www.lovart.ai/blog/05-better-design-composition-rules);
  [Digital Photography School, rule of space](https://digital-photography-school.com/?p=201715).
- The only numeric guide found was about two-thirds negative space for deliberate negative-space shots, and its
  source calls it "not a hard-and-fast rule" (search summary of
  [Adorama, negative space](https://www.adorama.com/alc/negative-space-in-photography/) and related guides).
  That suits a hero product shot, not a play field.
- Blob shadows are the standard cheap stand-in for real-time shadows on mobile. The classic version is a quad with
  a radial gradient placed just above the floor. One mobile developer used a 16x16 gradient on a quad with a
  multiply shader: "2 draw calls and few verts" —
  [Game Developer, fake shadows for mobile](https://gamedeveloper.com/design/implementing-fake-shadows-in-unity-for-mobiles);
  [PlayCanvas forum](https://forum.playcanvas.com/t/how-to-create-fake-shadow/36076);
  [Unity Learn, shadows](https://learn.unity.com/tutorial/shadows-3224).
- Real shadows are "computationally expensive to render" on mobile; faking them with textures or shaders is
  recommended — [Unity Learn, shadows](https://learn.unity.com/tutorial/shadows-3224).
- Godot 4 Mobile renderer supports depth and height fog, glow, adjustments, MSAA and decals. It does **not**
  support SSAO, SSIL, SSR, SDFGI, volumetric fog or PCSS on directional lights —
  [Godot renderers comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
- Godot's Environment has no vignette property; none is listed in the class reference —
  [Godot Environment docs](https://docs.godotengine.org/en/stable/classes/class_environment.html).
- Depth fog (`fog_mode = FOG_MODE_DEPTH`) uses `fog_depth_begin`/`fog_depth_end` (defaults 10/100) and a
  `fog_depth_curve`. `fog_density` sets the maximum intensity, and 1.0 fully hides the scene. `fog_sky_affect`
  (default 1.0) controls how much fog tints the sky. `fog_height`/`fog_height_density` add height fog, and a
  negative density makes fog increase upward —
  [Godot Environment docs](https://docs.godotengine.org/en/stable/classes/class_environment.html).

### Inferences
Composition targets, on a 411 x 914 dp frame:

- **Shrink the field to about 64-72% of screen height.**
  - Cell 34-36 dp gives a grid of about 306-324 dp wide (75-79% of width) by about 612-648 dp tall.
  - The remaining 266-300 dp covers the top bar (about 56-64 dp), headroom above the tower top (about 16-24 dp),
    the pedestal plus contact shadow (about 50-70 dp), and a gap above the bottom edge or controls (at least 24 dp,
    about 3% of height).
  - Side margins of 24-50 dp per side frame the posts and leave room for slim next/hold panels.
- **Keep the whole pedestal in frame.** A half-cut hex base reads as a framing error because the object's
  silhouette is otherwise complete. A deliberate crop needs a large, obviously intentional cut, roughly a third or
  more of the object. A 10-20% sliver lost at the frame edge looks like a mistake. This is composition judgement
  drawn from the "cramped vs weak" guidance above, not a sourced number.
- **Visual centre.** Put the tower's centre of mass slightly above the screen's geometric centre, about 45-48% from
  the top. The pedestal then has more space below it than the headroom above the tower, which reads as "standing"
  rather than "falling out of frame". The play area should not be pushed onto a thirds line: this is a centred,
  symmetric hero object.
- **Grounding stack, cheapest first:**
  1. One unlit quad under the pedestal with a radial gradient. Multiply or alpha blend, slightly larger than the
     hex footprint, about 40-60% opacity at the centre falling to 0 at about 1.3× the pedestal radius.
  2. Bake ambient occlusion into the pedestal mesh (vertex colours or a small texture) where it meets the floor and
     where the posts meet the pedestal.
  3. A floor plane that fades into the background colour with depth fog. Begin about 2 units behind the pedestal,
     end about 15-25 units, curve about 1.5-2. Also set `fog_sky_affect` low so a sky gradient stays visible.
     Alternatively, use a floor texture with a radial alpha falloff, which avoids fog tuning.
  4. Keep the floor plate visibly separate from the pedestal: a gap or step, the shadow, and a value contrast step.
     The "jammed" look comes from the plate and pedestal sharing a silhouette edge at nearly the same value.
- **Vignette in Godot 4:** draw a full-screen `TextureRect`/`ColorRect` on a CanvasLayer above the 3D scene, using a
  pre-made radial gradient texture (dark edges, about 15-25% strength). Do not use a screen-reading shader: a
  texture-only overlay avoids reading back the framebuffer on tile GPUs (see Performance).

### Gaps
- I found no article that measures pedestal or base margins in shipped mobile puzzle games, and no GDC talk on
  tabletop-style board framing. The margins above are derived from photo-composition guidance plus the dp budget.

---

## Block look at 25-45 dp: bevel, gap, edges, gem readability, colour-blind safety, shape cues

### Takeaway
At 25-45 dp a cell is only about 66-120 physical pixels on a 2.625× phone. Three things carry readability, in
priority order:
1. **Value (lightness) contrast** between piece types and against the back pane.
2. **A crisp, consistent outline or gap** separating cells.
3. **A per-type shape or glyph cue**, so colour is never the only signal.

Facet sparkle, fresnel and bloom are secondary and should be toned down. They wash hues towards white, and bloom
spreads one cell into its neighbours.

### Cited Findings
- "Wherever you can, use colour as a back-up for another means of communicating the information"; "always try to
  reduce colour reliance through additional signifiers first" (shapes, symbols, patterns). Offer deuteranopia,
  protanopia and tritanopia presets. Red/green difficulty affects about 8-10% of males. Designing for 100%
  severity covers the milder degrees. Listed examples include a dot-matching puzzle with a colour-blind mode and a
  puzzle game with integrated symbols —
  [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/).
- For two-way distinctions, orange vs blue works for the three most common colour-blindness types. Adding a
  contrast difference (light blue vs dark orange) helps edge cases. Test with simulators such as Colour Oracle or a
  realtime Android simulator —
  [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/).
- The Okabe-Ito palette, popularised by B. Wong in Nature Methods (2011), is #E69F00 orange, #56B4E9 sky blue,
  #009E73 bluish green, #F0E442 yellow, #0072B2 blue, #D55E00 vermillion, #CC79A7 reddish purple and #000000
  black — [NYU Siegal lab](https://siegal.bio.nyu.edu/color-palette/);
  [ggokabeito CRAN manual](https://anorien.csc.warwick.ac.uk/CRAN/web/packages/ggokabeito/ggokabeito.pdf).
- Grayscale screenshots are the cheap readability audit: "most readability failures are value failures." Also
  check art at actual game size and in motion, not zoomed in —
  [Bugnet, readable game art](https://bugnet.io/blog/readable-game-art-why-clarity-beats-detail);
  [Game Developer, reducing visual confusion](https://gamedeveloper.com/design/how-to-reduce-visual-confusion-in-your-game).
- A blur test ("if you can still read the game when blurred, you're good") and squint or thumbnail checks are
  common practice — [r/gamedev on contrast (mirror)](https://redlib.hbubli.cc/r/gamedev/comments/wgxfe1/why_contrast_in_game_art_is_so_important);
  [Icewyrm Games, reducing visual confusion](https://icewyrmgames.github.io/research/reducing-visual-confusion-in-your-game).
- At small sizes, "clarity beats intricacy," and distinct silhouettes stop elements being confused —
  [Bugnet, pixel art that reads](https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly).
- Tonemapper choice affects how bright gem colours survive, per the Godot docs:
  - ACES "desaturates bright values".
  - AgX "holds hue better in bright areas" but is the slowest.
  - Filmic gives better contrast than Reinhardt.
  - Linear clips.

  — [Godot Environment docs](https://docs.godotengine.org/en/stable/classes/class_environment.html).
- `glow_hdr_threshold` defaults to 1.0 and "may need to be below 1.0 for Mobile". `glow_bloom > 0` makes glow
  appear even in areas below the threshold — [Godot Environment docs](https://docs.godotengine.org/en/stable/classes/class_environment.html).
- A shading-only bevel is a production technique (Blender Bevel node, Redshift Round Corners). It changes shading,
  not silhouette. Godot community shaders fake bevels with normal smoothing —
  [Blender manual, Bevel node](https://docs.blender.org/manual/it/dev/render/shader_nodes/input/bevel.html);
  [Redshift Round Corners](https://help.maxon.net/c4d/2024/en-us/Content/_REDSHIFT_/html/Round+Corners.html);
  [godotshaders, Fake Bevel 2 passes](https://godotshaders.com/shader/fake-bevel-shader-2-passes/).
- Normal-only bevels break if the radius is too large or the camera too close, and they cannot round the
  silhouette — [Arnold round-edges tutorial](https://help.autodesk.com/cloudhelp/ENU/AR-3DSMax/files/arnold-3dsmax/ax-tutorials/ax-shading/arnold_for_3ds_max_ax_shading_ax_round_edges_shading_html.html);
  [Babylon.js forum, bevel cubes at render time](https://forum.babylonjs.com/t/approaches-for-bevel-rounded-corner-cubes-at-render-time/5771).
- The touch-target guidance is 48 x 48 dp with 8 dp spacing (about 9 mm per one source). This bounds input
  targets, not visual cells — [Google Android accessibility, touch target size](https://support.google.com/accessibility/android/answer/7101858?hl=en);
  [Material, applying density](https://material.io/design/layout/applying-density.html).
  Note: 48 dp is 0.3 inch, or 7.6 mm by the 160 dp/inch definition. The "about 9 mm" figure from the secondary
  source is loose.

### Inferences
The percentages here are derived design targets, not from a source.

- **Cell size budget.** The physical size of a cell is cell dp × 0.159 mm:

  | Cell size | Physical size | Pixels at 2.625× |
  |---|---|---|
  | 25 dp | 4.0 mm | 66 px |
  | 35 dp | 5.6 mm | 92 px |
  | 45 dp | 7.1 mm | 118 px |

  - At **35 dp or more**, bevel highlights and a facet sparkle read.
  - At **25-30 dp**, internal facet detail turns to noise, and only the silhouette, outline, value and one bold
    glyph survive.
  - Design for the smallest case.
  - Since play uses swipe and tap gestures rather than per-cell taps, cells may be below 48 dp.
- **Gap between cells:** about 4-8% of the cell (the current 0.94 scale is a 6% gap). Keep the gap at 3 px or more
  on screen: at 35 dp × 2.625, 6% is about 5.5 px, which is fine. Below about 3 px it shimmers or disappears under
  MSAA and texture filtering. Fill the gap with a dark back pane (near-black or deep navy) so it reads as an outline.
- **Bevel radius:** about 8-12% of the cell, giving a bevel of about 7-11 px at 35 dp. Bigger bevels make cubes look
  like rounded candy and less like crystal. Smaller ones vanish at 25 dp.
- **Edge highlight:** one bright rim on the top and left edges (the light-facing ones) and a slightly darker rim on
  the bottom and right is a stronger depth cue than all-round bright facet edges. All-round bright edges merge into
  a white grid, flatten value differences and look "over-lit".
- **Specular, fresnel and emission discipline:**
  - Cap specular so the brightest highlight on a gem covers about 10% of its face or less.
  - Keep emission so the front face stays at or below 1.0 in linear HDR; then bloom affects only intentional events
    such as line clears.
  - Keep `glow_hdr_threshold` above the resting gem brightness so glow is reserved for effects.
  - Prefer Filmic or AgX over ACES, to avoid desaturating the bright yellow and cyan gems.
- **Palette rule for 7 piece types:**
  - Space the colours on lightness, as well as hue, so each type keeps a distinct gray level (aim for about 8-12
    L* steps between nearest neighbours in the grayscale test).
  - Okabe-Ito hues are a good starting set (orange, sky blue, bluish green, yellow, blue, vermillion, reddish
    purple = 7). Restyle them as gems by adding a lighter top facet and darker base; the base hue stays original.
  - Verify with a deuteranopia/protanopia/tritanopia simulator and a grayscale screenshot.
- **Per-type shape cue:** give each piece type a distinct inset glyph or facet pattern on the front face. Examples:
  a dot, a ring, a diagonal, a cross, a chevron, a square, a diamond. Drive it from one small atlas texture indexed
  per instance (MultiMesh custom data). Keep it as a value change, about 15-25% darker or lighter than the face,
  not a new hue. At 25 dp a glyph about 40% of the cell is still legible.
- **Ghost or landing preview:** make it outline-only or low-alpha. Draw it as a separate small MultiMesh so blending
  stays confined to those 4 cells.

### Gaps
- I found no authoritative source giving bevel or gap percentages for puzzle tiles. The 80.lv gem-shader breakdowns
  suggested in the brief were not reached within the search budget.
- I found no study on minimum legible tile size for colour-and-glyph puzzle pieces on phones.

---

## Performance on the Godot 4 Mobile renderer

### Takeaway
162 cubes is trivial geometry. The risks are fill rate and draw calls:
- Large transparent glass panes overlapping the field.
- Screen-reading post effects.
- Bloom.
- One draw call per cell, because Godot's automatic instancing is Forward+ only.

Use one MultiMesh (or one per material) for the cells. Make the back pane opaque. Fake the contact shadow and AO
with a gradient quad and baked AO.

### Cited Findings
- Automatic instancing of MeshInstance3D nodes sharing a mesh and material "works only in Forward+".
  "Alpha-blended or depth pre-pass materials are never instanced this way" —
  [Godot, optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html).
- "MultiMesh allows the drawing of many thousands of objects at very little performance cost" —
  [Godot, optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html).
- More on MultiMesh, from [Godot, using MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html):
  - It is "a single draw primitive".
  - It has no per-instance culling: it is all or nothing.
  - Allocate the maximum instance count, then vary `visible_instance_count`.
  - Shaders can use `INSTANCE_ID` / `INSTANCE_CUSTOM` for per-instance logic.
- Transparent objects are drawn back to front and cannot be batched by material. "Use as few transparent objects as
  possible" — [Godot, optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html).
- More on fill rate and mobile shaders, from [Godot, GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html):
  - "Transparent objects are also particularly bad for fill rate"; "Transparency is particularly expensive where
    multiple transparent objects overlap". More complex opaque geometry can be faster than transparency.
  - On mobile, "don't worry about vertex count", but avoid "concentration of vertices in small parts of the
    screen"; tile renderers struggle with small, dense objects.
  - "Post-processing effects and shadows can also be expensive in terms of fragment shading activity."
  - "When targeting mobile devices, consider using the simplest possible shaders you can reasonably afford."
  - Fewer materials make rendering faster.
- SSAO is not available on Mobile (Forward+ and Compatibility only). Directional-light PCSS is unsupported on
  Mobile. Omni and spot lights are limited to 8 per mesh —
  [Godot renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html);
  [Godot Environment](https://docs.godotengine.org/en/stable/classes/class_environment.html).
- A quad blob shadow costs about 2 draw calls and a few vertices. One Unity asset author warned that projector-style
  shadows hurt mobile frame rates, so measure on device —
  [Game Developer](https://gamedeveloper.com/design/implementing-fake-shadows-in-unity-for-mobiles);
  [Unity discussions, Fast Shadows](https://discussions.unity.com/t/released-fast-shadows/486102.md).

### Inferences
- **Bevel method ranking for 162 cells on an Adreno 6xx:**
  1. **A real low-poly bevelled cube mesh** (one bevel segment, about 50-100 triangles) in a MultiMesh. That is
     about 16k triangles total. The silhouette is correct, shading is plain and it is the cheapest per pixel. This
     is the recommended option.
  2. **A shader bevel on a BoxMesh**: normals bent near edges using local position against the half-extents, or a
     rounded-box SDF gradient. Zero extra geometry, a few extra ALU ops per pixel, but the silhouette stays sharp.
  3. **Normal-mapped cube**: a texture fetch per pixel and filtering or mip artefacts at small sizes. No advantage
     over options 1 and 2 here.

  Avoid the two-pass screen-space bevel. It reads the framebuffer back, which is costly on tile GPUs.
- **Glass back pane:** draw it as an **opaque** dark panel with grid lines in its albedo or emission. Fake the
  "glass" with a subtle gradient and a fresnel rim on its frame only. A full-height transparent pane behind 162
  cells adds a blended layer over most of the screen. If some see-through effect is needed, keep the alpha region
  to the frame border.
- **MultiMesh per material:** one MultiMesh for locked cells, with per-instance colour plus custom data for glyph
  index and flash or clear state. A second, small one for the active piece and ghost. Update only changed instance
  transforms or colours on lock or clear, not every frame. Use preallocated arrays, in line with the project's "no
  per-frame allocations" rule.
- **Bloom:** if glow is enabled, keep `glow_intensity` low and the threshold above the resting gem brightness.
  Profile it on the Vivo or Adreno test phone. Glow is a multi-pass fragment cost, and the GPU guide flags
  post-processing as expensive.
- **Shadows:** consider turning off directional shadow casting for the cubes entirely. Cells against an opaque back
  pane gain little from real shadows, and the pedestal grounding comes from the fake shadow quad.

### Gaps
- I found no Adreno 6xx numbers for glow, transparency or MultiMesh cost in Godot 4.7 Mobile. Measure with Godot's
  profiler or on-device frame timing.
- The MultiMesh doc page says it may be outdated for 4.7. I did not verify the exact `use_colors` /
  `use_custom_data` property names on that page; they are in the MultiMesh class reference (not fetched).

---

## Godot-specific techniques: keep_aspect, orthographic size, frustum offset, h_offset/v_offset, fog and vignette

### Takeaway
On portrait phones the 1:2 grid is width-limited, so use `keep_aspect = KEEP_WIDTH`. Then FOV or ortho `size` locks
the horizontal extent, and the tower never clips on narrower (21:9) phones. Use:
- `PROJECTION_ORTHOGONAL` with `size` for a uniform grid, or
- `PROJECTION_FRUSTUM` with `frustum_offset` for a true lens shift (no tilt).

`h_offset`/`v_offset` are a different kind of offset, so do not treat them as lens shift. Fog is available on
Mobile. A vignette must be a custom overlay.

### Cited Findings
- `keep_aspect`, from [Godot Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html):
  - The default is `KEEP_HEIGHT`, "Hor+": vertical extent is locked and horizontal extent varies with aspect.
  - `KEEP_WIDTH`, "Vert-", locks the horizontal extent.
  - `fov` (default 75) sets the angle of the locked axis.
- `size` (default 1.0) is used in orthographic and frustum modes: "the camera's size in meters measured as the
  diameter of the width or height, depending on keep_aspect" —
  [Godot Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html).
- `frustum_offset` "can produce tilted frustum effects such as Y-shearing" and works only with
  `PROJECTION_FRUSTUM` — [Godot Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html).
- `h_offset`/`v_offset` (default 0) are described only as "the horizontal (X) / vertical (Y) offset of the camera
  viewport" — [Godot Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html).
- A forum answer says the "only way to set the principal point is with Camera3D.set_frustum()". It is used for
  per-eye VR cameras and is "akin to set_perspective(), but the space is sheared around the camera position" —
  [Godot forum, off-center projection](https://forum.godotengine.org/t/godot-4-is-it-possible-to-set-a-custom-principal-point-off-center-projection-for-camera3d/131725).
- Fog (exponential or depth), height fog and `fog_sky_affect` are all supported on Mobile. There is no vignette
  property in Environment. Adjustments (brightness, contrast, saturation, colour-correction LUT) apply after
  tonemapping — [Godot Environment](https://docs.godotengine.org/en/stable/classes/class_environment.html);
  [Godot renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

### Inferences
- **Fit-to-width recipe for perspective with `KEEP_WIDTH`:** the horizontal FOV is fixed. To frame a field
  W_world wide (posts included, plus side margin) at distance d, use `fov = 2·atan((W_world/2 + margin) / d)`.
  Vertical framing then grows on taller phones, and the extra space becomes headroom or floor rather than cropping
  the pedestal.
- **Equivalent with `KEEP_HEIGHT` (the current default):** a 21:9 phone gets a narrower horizontal view than 20:9,
  and the width-limited tower can clip at the sides. This is a likely contributor to the pushed-in, cramped
  framing.
- **Orthographic recipe:** with `KEEP_WIDTH`, set `size` to the world width to show, e.g. 9 cells + posts + 2×1.5
  margin ≈ 13 units. Keep the screen-space centre on the tower centre and pitch 6-10°.
- **Lens-shift recipe (`PROJECTION_FRUSTUM`):** use it to drop the subject lower or higher in frame without
  pitching. `size` and `frustum_offset` are in world units at the near plane, so to mimic FOV f use
  size ≈ 2·near·tan(f/2), and offset_y ≈ near·tan(desired shift angle). This is based on the docs' "size at near
  plane" behaviour; verify with a screenshot.
- **`h_offset`/`v_offset`:** I understand these to translate the camera along its local X/Y axes. They move the eye
  point rather than shear the lens, so they do change perspective slightly. That is acceptable for small nudges.
  Not verified in the fetched docs.
- **Background depth:** use a sky or gradient background with depth fog starting just behind the pedestal, so the
  floor dissolves into the background. Set `fog_sky_affect` to about 0-0.3 so the gradient stays visible. Add a
  CanvasLayer radial-gradient vignette at 15-25% strength.

### Gaps
- I could not confirm from the official docs whether `h_offset`/`v_offset` are a camera translation or a
  projection shift. The docs' one-line descriptions are ambiguous; check `Camera3D::get_camera_transform()` in the
  4.7 source or test with a screenshot.
- I did not confirm the exact units of `frustum_offset` and `size` in frustum mode (near-plane world units) from
  primary docs.
- I found no evidence that Godot 4.7 exposes a fully custom projection matrix, such as oblique orthographic, on
  Camera3D. If a uniform "ortho with sheared top faces" is wanted without pitch, it would need a vertex-shader shear.
