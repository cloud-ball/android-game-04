# Make every Fairway Flick hole a place

Fairway Flick does not need more polygons to look like the best mobile mini-golf games. It needs four things it lacks today. The first is a strict brightness ladder, so the ball, cup and aim line are always the brightest things on screen. The second is one themed place per world with a landmark the portrait camera can actually see. The third is a cheaper, softer lighting and material pass. The fourth is a layer of "juice" (hit feedback, trails, a hole-out sequence) that runs on a presentation clock and never touches the solver. Reviewers praise simple, low-poly, cartoon courses when they read as coherent places and run smoothly, and they call crisp but generic courses "bland". That is the risk for the current procedural meadow. The test phone (Adreno 642L) renders 3D at its native 1260×2800, about 3.5 MP. That is roughly 40% more pixels than the resolutions behind the published Godot mobile benchmarks, so the 6 ms of headroom below the 16.6 ms frame is smaller than it looks. Glow, the real-time sun shadow and anti-aliasing will decide where that headroom goes, and each must be measured on the phone before anything is added. CC0 kits from Kenney, KayKit and Quaternius fit as set dressing around the course, recoloured onto Fairway Flick's own palette. They should not replace the procedural carpet and rails, because those are guaranteed to match the physics. The upgrade plan at the end runs from a near-free colour and value pass, through lighting, juice and landmarks, to CC0 dressing and an optional shadow re-architecture. Each step has an on-device performance gate.

## Reviewers reward themed places and punish generic felt

The genre's visual reputations split cleanly. Walkabout Mini Golf, the best-reviewed title, is praised because "every one of Walkabout's locales is a gorgeous place" ([UploadVR](https://www.uploadvr.com/walkabout-mini-golf-review/)). It is praised despite looking "low poly and simple" ([Gaming Age](https://gaming-age.com/?p=86544)). The original Wonderputt was called "a breathtakingly good-looking game" for whimsical hole-to-hole transformations, such as a snowy slope melting into a lily pond ([Pocket Gamer](https://www.pocketgamer.com/wonderputt/review/)). Criticism lands on sameness. A mobile battler's graphics are "bland but crisp and colourful" ([TapSmart](https://www.tapsmart.com/games/golf-battle-fast-paced-online-mini-golf/)). A party golf game is "far from special" visually ([Gaming.net](https://www.gaming.net/reviews/golf-with-your-friends-review-xbox-playstation-switch-pc)). A VR course set lacks distinctive landmarks, so its beach, desert and forest feel alike ([6DOF Reviews](https://www.6dofreviews.com/reviews/top-golf-with-pro-putt-review)). Wonderputt's sequel dissolves into "pastel slop" ([Backloggd](https://backloggd.com/reviews/everyone/year/liked/wonderputt-forever/)). A 2026 party golf game was praised as "artistically pleasing while being easy on both the eyes and the graphics card" ([Gaming Age](https://gaming-age.com/?p=113354)), which is exactly the brief for a mid-range phone.

The most useful primary source is Walkabout's art director, a former theme-park designer. His rules are concrete: "Starting with breathtaking vistas creates moments of wonder". Environments should answer "Where am I?". The course needs clear, simple rules that are never broken. The course should play like chapters, with small story moments scattered around it ([UploadVR, Carson](https://www.uploadvr.com/principles-of-course-design-in-walkabout-mini-golf/)). His team designs the place first and fits holes into it. It gives each world its own "shape language" for hole borders, which "took many iterations to get right" ([UploadVR, Hollywood course](https://www.uploadvr.com/walkabout-mini-golf-passport-hollywood-course/)). It keeps one consistent sun angle so even an inverted-gravity course reads as one space ([UploadVR, Upside Town](https://uploadvr.com/upside-town-walkabout-course-design/)).

Measured against that, today's Fairway Flick is a well-built playfield in a generic setting. GolfScenery places the windmill landmark 70 m beyond the cup and 35 m to the side. The play camera sits 5 m up and 4.2 m back, looking about 50° down at a point 2.2 m ahead of the ball. In portrait, that framing shows almost nothing but carpet and the first metre of lawn, so the landmark appears only in the 3-second intro and the MAP view. The hills ring sits 620-760 m away. The fix is framing as much as content. Put the landmark 15-40 m behind the cup so it lands in the top third of the frame during play. Make the intro fly-over open on it, as Carson's "establishing shot". Then give each world a distinct place rather than a recoloured lawn.

Originality is a hard constraint, and the notes name what to avoid. Do not use Walkabout's art-deco borders or its licensed-style themes, or Wonderputt's single morphing island. Avoid Golf Peaks' card-tile isometric presentation and What the Golf's flat gag style. Do not borrow the battler HUD with top-bar avatars and chest screens. The generic techniques (themed places, landmarks, a fly-in, a hole that "assembles" from popping tiles) are free to use. Fairway Flick's own rail profiles, cup and landmarks keep it original.

## A strict value ladder decides whether the ball reads

Most readability failures are brightness (value) failures, not hue failures. The cheapest audit is a greyscale screenshot taken in the busiest moment ([bugnet](https://bugnet.io/blog/readable-game-art-why-clarity-beats-detail)). DOTA 2's art team made the ground a narrow band of darker values and units the brightest elements. Their fix for a muddy scene was to "darken the background, brighten the walkable surfaces, and boost the character", because "if everything is drawing attention, nothing will" ([Game Developer, Angstadt](https://gamedeveloper.com/design/how-to-reduce-visual-confusion-in-your-game)). Golf adds a colour-blindness problem. Green/brown and green/grey pairs are the hardest for colour-vision-deficient players ([Smashing Magazine](https://smashingmagazine.com/2016/06/improving-ux-for-color-blind-users)), and orange balls can vanish on grass ([Colour Blind Awareness](https://www.colourblindawareness.org/colour-blindness/living-with-colour-vision-deficiency/sport/)). A disc-golf map solved grass-versus-path confusion with white dashed edge lines ([discgolf.com](https://discgolf.com/?p=95198)).

Converting the current colour constants to relative luminance shows where the scene breaks the ladder. The carpet, `(0.24, 0.66, 0.30)`, has a luminance of about 0.29. The lawn, `(0.30, 0.50, 0.20)`, sits at about 0.17 before its noise term. Both are good. But the rail body, `(0.55, 0.34, 0.18)`, comes out at about 0.13, darker than the lawn it should outline. Only the thin cream cap carries the edge. The flower palette includes near-white `(0.98, 0.97, 0.95)` blooms right beside the rails, the same value as the white ball. The ball itself is an unshaded white sphere, so it reads as a flat disc with no form. The cup glow is a translucent yellow disc, not a dark hole with a bright rim. None of these is expensive to fix.

The target ladder runs from darkest to brightest:

1. Off-course surroundings: lawn, water, foliage, cliffs. Narrow internal range.
2. The carpet: saturated mid-value, with brushed bands kept within about 5-8% of its value.
3. Rails: the top face lighter than the carpet, the inner face slightly darker, and a bevelled top edge that catches the sun.
4. Ball, cup ring, flag, aim guide and interactive hazards, as the brightest and most saturated things on screen.

The cup itself should be the darkest spot on the carpet, ringed in white. The ball should be shaded, with a light-aware rim and a thin outline. On pale worlds such as sand or snow it should switch to a saturated colour or a stronger outline.

The notes also propose one colour meaning per mechanic, used in every world and kept out of the decorative palette. This is convention rather than a sourced standard:

| Meaning | Colour | Shape cue |
|---|---|---|
| Danger / out of bounds | Red-orange | Stripes |
| Boost pads | Amber | Chevrons |
| Ice | Cyan | — |
| Sand / slow | Tan grain | Grain texture |
| Teleport | Magenta | — |

Pairing each colour with a shape (stripes for danger, chevrons for boost) keeps it legible for colour-blind players. In Rush, the rival ghost balls need distinct hues and rings that stay inside the top brightness tier.

Detail needs the same discipline, applied as three rings. Ring 0, the carpet, carries nothing but gameplay objects. Ring 1, a 0.5-2 m apron outside the rails, holds low props that frame the edge: planters, stones, lamps, flower beds, theme pieces. These are medium saturation and set below rail height so they never hide the ball. Ring 2 is the backdrop, with the landmark, trees, buildings and cliffs. It can be dense but sits lower in contrast, compressed toward the sky colour by fog. Each hole gets two to four small story vignettes in Rings 1 and 2. Walkabout's studio course is built from exactly such moments, such as lot cats and a peek into a soundstage ([UploadVR](https://www.uploadvr.com/walkabout-mini-golf-passport-hollywood-course/)).

The plan already names four worlds: meadow, coastal, canyon and volcanic. Each needs its own dominant carpet hue, so worlds are recognisable at a glance and avoid pastel sameness. The table below is a design proposal (no source gives palettes for a commercial mini-golf game); the landmarks are original suggestions.

| World | Carpet hue | Rail profile (one per world) | Sun and sky | Landmark (original) | CC0 dressing |
|---|---|---|---|---|---|
| Meadow | Grass green | Rounded painted wood, darker cap | Neutral-warm midday, 45°, light blue gradient | Hilltop windmill-tower, moved into frame | Kenney Nature (trees, fences, flowers, mushrooms) |
| Coastal | Teal | Rope and driftwood posts | Low golden-hour sun, peach-to-lavender sky, long shadows | Striped lighthouse on a rock | Kenney Pirate (palms, docks, sand rocks, crates) |
| Canyon | Terracotta | Chunky bevelled sandstone blocks | Hard warm light, haze, pale sky | Natural arch or toppled obelisk | Kenney Nature (cacti, cliff blocks, obelisk, columns) |
| Volcanic | Deep violet or charcoal-green | Basalt blocks with an emissive seam | Dusky orange sky, dark ground | Smoking cone with emissive lava | Nature palms and dark rock, custom lava shader |

## The Mobile renderer leaves about 6 ms, and glow and shadows decide where it goes

### What the Mobile renderer can and cannot do

Godot 4.7's Mobile renderer supports LightmapGI, decals, reflection probes (8 per mesh), glow, all tonemappers, 1D/3D LUT colour correction, MSAA, FXAA, SMAA 1x, and the screen and depth textures. It does not support SSAO, SSIL, SSR, SDFGI, VoxelGI, volumetric fog, TAA, FSR2 or a normal/roughness buffer ([Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)). Every premium-looking effect must therefore come from baking, material tricks, or the handful of supported passes. The colour buffer is RGB10A2 unless HDR 2D is on, and 4.6 added a debanding setting for 3D ([Godot 4.6](https://godotengine.org/releases/4.6/)). That matters for smooth sky gradients and soft carpet bands.

### Glow is the first suspect for GPU time

Glow on Mobile was a severe cost before 4.6. One report measured about 120 fps without glow against 37 fps with it on a Mali-G68 ([issue #98531](https://github.com/godotengine/godot/issues/98531)). The 4.6 rewrite cut glow plus tonemap from 10.0 ms to 2.85 ms on an Adreno 640 at 1080×2280, and from 7.3 ms to 3.35 ms on a Mali-G710 at 1080×2400 ([PR #110077](https://github.com/godotengine/godot/pull/110077)). Fairway Flick runs on 4.7, so it already has the fast path. But the phone renders about 43% more pixels than the Adreno 640 test. A linear pixel scaling (an extrapolation, not a measurement) puts glow plus tonemap at roughly 3-4 ms of today's 10.6 ms on a GPU of that class.

That estimate matters because the current glow does little visually. GolfScenery sets intensity 0.4 and bloom 0.05 with the default HDR threshold. Almost every material is below 1.0, so it adds a faint haze, not readable highlights. The right move is a device A/B. If glow costs more than about 1.5 ms, the options are:

- Turn it off and fake the few glows the game needs (cup ring, emissive rails at night, pickups) with unshaded additive halo meshes, the way the cup glow disc already works.
- Keep it but restrict it to one or two mid levels, skip levels set to strength 0, keep the threshold at 1.0 and set bloom to 0. Only emissive accents then bloom. Level 1 now aliases, so avoid it ([PR #110077](https://github.com/godotengine/godot/pull/110077)).

### The real-time sun shadow lights only static geometry

The sun uses an orthogonal shadow map out to 45 m. The ball does not cast into it; it has a blob disc. So every real-time shadow on screen today falls from static geometry: rails, trees, the windmill. The docs say a shorter max distance "improves both shadow quality and performance" ([Godot docs: lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)). The play camera sees perhaps 15-25 m of course, so 25-30 m is the first cheap win.

LightmapGI is Godot's cheapest route to soft shadows, bounce light and baked AO on Mobile ([Godot docs: LightmapGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html)). Walkabout bakes its final shadows too ([UploadVR](https://www.uploadvr.com/walkabout-mini-golf-passport-hollywood-course/)). But LightmapGI is a poor fit here, because Fairway Flick builds every hole at runtime from a JSON tile map. Lightmaps need an editor bake, UV2 and saved scenes.

A better fit is to bake the ground shadow at hole load. Ray-march the sun direction over the height grid, wall segments and prop footprints into an R8 texture at about 5-10 cm per texel, in the same way GolfTerrain already uploads its R8 surface map. Multiply that texture into the terrain shader, and turn the sun's real-time shadow off, or keep it only for a few moving obstacles. This is an original proposal, not a documented recipe. It is deterministic, costs one texture read per terrain fragment, and removes the shadow pass entirely. It is worth building only if the phone shows the shadow pass costs more than about 1.5 ms.

GolfTerrain already bakes rail-contact AO into vertex colours at 0.2 m resolution. Extending that to ramp sides, bumper bases and prop footprints is nearly free. Vertex colour is the documented hook for this ([Godot docs: StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)).

### Materials: built-in stylised modes cover most needs

StandardMaterial3D already offers most stylised looks ([Godot docs: StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)):

- **Toon diffuse and specular:** a hard light cut and a stylised highlight blob.
- **Lambert Wrap:** effectively half-Lambert, which softens the dark side of forms.
- **Rim:** light-aware, so there is no rim without light. Tint values between 0 and 1 "generally work best".
- **Per-vertex shading:** "can considerably increase rendering performance" on mobile.
- **Grow outline:** a Cull Front next-pass material that draws a cheap inverted-hull outline.

The terrain shader currently uses plain `diffuse_lambert`. A half-Lambert term plus a hemispheric ambient (mixing sky and ground colour by the world-space normal) gives the soft, sunny "toy diorama" look for a few ALU operations. A light-aware rim on the carpet suggests fibre sheen at grazing angles. Keep the brushed bands within the value ladder.

Rails are the biggest material upgrade per effort. Today they are boxes with a separate box cap, stepped every 0.5 m beside ramps. Replace them with one extruded, bevelled profile mesh per world, swept along the wall segments and following ramp slopes, and merged per hole into a single draw. That gives each world its own shape language. The bevel catches the sun as a free highlight, and the stair-step artefact beside ramps disappears.

The ball should get Toon specular and a rim, plus a Grow outline. An inverted-hull outline on the ball and flag only costs a few hundred triangles. It avoids a post-process outline, which on Mobile has no normal buffer and pays for depth reads ([Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)).

### Transparency is the cost to remove first

Alpha blending is "significantly slower to render, especially if they overlap". Alpha Scissor is faster and casts shadows. "Sometimes more complex opaque geometry runs faster than transparency" ([Godot docs: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)). Several things in the scene are alpha-blended today:

- the water shader (ALPHA 0.92 across the whole pond)
- the ball's shadow disc and aim ring
- the cup glow
- the guide strip

Water should become opaque, with these changes:

- Sine-wave vertex motion.
- A fresnel tint.
- A thin foam strip mesh at the shoreline.

Most Godot "toon water" shaders sample the depth texture for foam, and that broke with 4.3's reverse-Z change ([godotshaders](https://godotshaders.com/shader/stylized-water-for-godot-4-x)). The blob shadow and rings are small, so they can stay transparent. Confetti and sparks should use opaque or alpha-scissor quads, never overlapping alpha.

### Post-processing and anti-aliasing

The tonemap should be AgX or Filmic, with a per-world 3D LUT as the colour grade. 4.6 exposes AgX white and contrast. On Mobile without HDR 2D, AgX's white is fixed at 2.0 ([Godot docs: environment](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)). The LUT runs after tonemapping in the existing pass, so it is likely near-free, though no measured figure exists.

The project currently has no anti-aliasing. Thin cream rail caps on a 400+ ppi portrait screen will shimmer while the camera glides. FXAA is "usually the only viable option" on low-end mobile, and SMAA 1x is "slightly slower than FXAA, but produces less blurriness". 2x MSAA "may be usable in some circumstances" ([Godot docs: AA](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html)). On tilers, MSAA is cheap only when it resolves on-tile. One Vulkan sample measured about 3% bandwidth with an on-tile resolve, against about 5 GB/s extra with a separate resolve pass ([Vulkan Samples](https://docs.vulkan.org/samples/latest/samples/performance/msaa/README.html)). Since the scene has no depth-reading post effect, SMAA 1x and MSAA 2x both deserve a device A/B.

A vignette belongs in the 2D layer as a radial-gradient ColorRect, not as a screen-texture pass. For the 30 fps floor on low-end phones, `scaling_3d_scale` of 0.75-0.85 renders 56-72% of the pixels while the UI stays native. FSR1 is listed as Forward+ only, so Mobile scaling is bilinear ([Godot docs: resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html)).

### Stutter, not frame rate, is the hidden polish killer

Toggling MSAA level, reflection probes, lightmaps or shadow precision at runtime causes "immediate stutters". The docs recommend rendering every feature once in a hidden warm-up at load ([Godot docs: pipeline compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)). For Fairway Flick, that means:

- Decide quality settings when the game loads, never mid-hole.
- Draw the confetti, splash, spark and trail materials once, off-screen, during the hole intro.

The 4.5 shader baker cuts startup compiles, but it does not work with `--headless` exports, which is the project's documented export command. It needs an editor or non-headless export.

### What is affordable on this phone

The table below separates the one measured cost (glow) from inferences. Every row needs confirming with the device A/B described in the plan.

| Technique | Expected GPU cost on the Adreno 642L | Basis |
|---|---|---|
| Glow + tonemap (4.6+ path) | ~3-4 ms at 1260×2800, if it scales like the Adreno 640 result | Measured 2.85 ms at 1080×2280 ([PR #110077](https://github.com/godotengine/godot/pull/110077)), scaled by pixels |
| Orthogonal sun shadow, 45 m | Unknown; no published Adreno 6xx figure | Docs: shorter distance helps; measure by toggling |
| FXAA / SMAA 1x / MSAA 2x | Low / low-medium / medium, depends on resolve | [Godot AA docs](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html), [Vulkan Samples](https://docs.vulkan.org/samples/latest/samples/performance/msaa/README.html) |
| Half-Lambert, rim, hemispheric ambient, vertex AO | Near zero (ALU only, no texture reads) | [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html) |
| MultiMesh props and vertex-sway foliage (COLOR-masked) | Low | [Godot: optimizing 3D](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html), [Making trees](https://docs.godotengine.org/en/4.1/tutorials/shaders/making_trees.html) |
| Opaque water vs today's alpha water | Saves overdraw | [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html) |
| Ball trail, sparks, 40-80 confetti quads | Low (small, short-lived, scissor or opaque) | Inference |
| Render scale 0.75 (low tier) | Saves ~44% of 3D fragment work | [Godot docs: resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html) |

Draw calls are not the constraint. The scene uses 56 today, and Arm suggests about 500 as a mobile ceiling ([Arm community](https://community.arm.com/support-forums/f/graphics-gaming-and-vr-forum/9238/draw-call-performance-on-the-mali-t880-mp12/30499)). Still, a separate StandardMaterial3D for every `_mesh()` call is wasteful. "A scene with a single material will perform much better than one with multiple materials" ([itch.io devlog](https://itch.io/devlog/73530/blazing-fast-rendering-with-a-single-material-per-scene.amp)). Sharing one palette material across props keeps the earlier ≤100-call budget comfortable as dressing grows.

## Kenney and KayKit belong around the course, not under the ball

### Licences and kit contents

The licences are clean. Kenney's assets are CC0, "Attribution is not required", and "free to use them, even in commercial projects" ([Kenney support](https://kenney.nl/support)). Quaternius states "All models are under the CC0 License" ([Quaternius FAQ](https://quaternius.com/faq.html)). KayKit's free tiers are CC0 1.0 with no attribution required ([KayKit Forest](https://kaylousberg.itch.io/kaykit-forest)). Poly Haven and ambientCG are CC0 as well ([Poly Haven](https://polyhaven.com/license), [ambientCG](https://docs.ambientcg.com/license/)). Poly Pizza is different. Its licence applies per model and is mostly CC-BY ([Poly Pizza terms](https://poly.pizza/docs/tos)), so anything wanted from it should be downloaded from the original author's site and recorded there.

The Kenney Minigolf Kit 3.1 has 125 assets ([Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)). Measurements from the downloaded zip:

- Pieces are 1×1-unit modules with the rails baked into the same mesh as the floor.
- Every piece shares one 512×512 `colormap.png`, plus two alternative palettes.
- Triangle counts are 12-368 per tile.
- The windmill's blades are a separate node.
- There are no sand, water or bumper pieces.

Kenney's Nature Kit (330 assets, flat named materials, no textures), Pirate Kit (palms, docks, sand rocks) and Holiday Kit (snow trees, cabins) cover the other worlds ([Nature](https://kenney.nl/assets/nature-kit), [Pirate](https://kenney.nl/assets/pirate-kit), [Holiday](https://kenney.nl/assets/holiday-kit)). KayKit's Forest and Platformer packs use one gradient atlas that "can be downsampled to 128x128" ([KayKit Forest](https://kaylousberg.itch.io/kaykit-forest), [KayKit Platformer](https://kaylousberg.itch.io/kaykit-platformer)).

### Replacing the playfield costs more than it gains

Scaled ×3, a Minigolf tile matches the baker's 3 m grid:

- 2.4 m fairway between 0.30 m rails
- floor top at 0.19 m
- ramps rising 0.75, 1.2 or 1.95 m

But the rails sit 0.3 m inside the tile edge, while Fairway Flick's wall segments run along tile edges. The ramp shapes are also fixed and would not match the height grid. Using the tiles as the playfield would show a ball floating, sinking, or rolling "into" a rail, unless both the baker and the art changed together under a mesh-versus-grid test.

The lower-risk path is to keep the carpet and rails procedural, generated from the same grid the solver uses, and therefore always correct. Use CC0 pieces only for:

- flags and set pieces such as the windmill, castle, gates and tunnels
- supports under raised tiles
- Ring 1 and Ring 2 props

Imported scenes must stay pure MeshInstance3D. Do not use `-col` suffixes, because collision lives in HoleData, not Jolt ([Godot docs: name suffixes](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html)).

### Recolour everything onto Fairway Flick's own palette

Style coherence matters more than source quality. A patchwork of good assets reads as cheap, while a modest consistent style reads as deliberate ([bugnet](https://bugnet.io/blog/how-to-avoid-the-asset-store-look)). Kenney's minigolf pieces are also widely used, so shipping them in their stock colours invites that "asset-store look".

The pipeline that answers both problems:

1. Author a `colormap_<world>.png` per world by repainting the atlas swatch columns. Atlas kits then recolour by swapping one texture.
2. Map the Nature Kit's 23 shared material names to a per-world `.tres` library.
3. Stay within flat or gradient low-poly sources (Kenney, KayKit, Quaternius's simple packs). Leave out the painterly, textured Stylized Nature MegaKit ([Quaternius](https://quaternius.com/packs/stylizednaturemegakit.html)) unless every asset moves to that look.

### Import settings and draw-call discipline

- **Scale:** each kit gets its own folder and an import preset with Apply Root Scale: 3.0 for Minigolf and Nature, about 0.75-1.0 for the larger Pirate kit ([Godot docs: import configuration](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)).
- **Atlas texture:** set it to Lossless or ASTC High Quality, so ETC2 blocks do not bleed between palette swatches. A 512² RGBA atlas costs only about 1 MB ([Godot docs: importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)).
- **Repeated props:** draw them through explicit MultiMesh, because automatic instancing is Forward+ only. Split by area, since a MultiMesh culls all-or-nothing ([Godot docs: MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)).

### Bookkeeping: ASSETS.md and agents

Every shipped file needs its own ASSETS.md row, for example `games/golf/assets/kenney_nature/tree_oak.glb | https://kenney.nl/assets/nature-kit | Kenney | CC0 1.0 | No`. The project's asset-wrangler agent exists for exactly this import-and-record job, and the ip-checker should run over names and screenshots afterwards. Kenney's preview sheets carry its logo and must not ship.

The UI currently relies on the system sans-serif. A bundled open-licence (SIL OFL) rounded display face for numbers and outcome words would remove a "default font" tell. It needs the same ASSETS.md row.

## Juice belongs to the presentation clock, not the solver

### Shot release

Polish lifts simple visuals: "stiff animation is a dead giveaway of a rushed product" ([Wayline](https://www.wayline.io/blog/indie-visuals-trap-fake-done-survival)). The release moment should fire one package on a single frame:

- a putter-tap sound pitched by power
- a short haptic of no more than 20 ms
- a 0.05-0.15 m camera kick opposite the shot direction that springs back over about 200 ms

The kick echoes Vlambeer's "shake opposite to the firing direction" advice ([Game Developer](https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games)). Full-power shots can also add shake, built on the trauma model from the GDC talk "Juicing Your Cameras With Math": shake equals trauma squared, driven by smooth noise and decaying over time ([GDC Vault](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing)). SettingsService already has a `reduce_motion` flag, and shake and kicks must obey it.

### Aim and power feedback

Aim UI is where players complain most. One reviewer says an arrow "isn't an accurate reflection of your swing power" ([148Apps](https://148apps.com/reviews/vista-golf-review)). Another player could not drag a small enough amount for a fine putt ([itch.io](https://itch.io/post/5653558)). Two changes address this:

- Map power to drag distance with a gentle ease-in, roughly d^1.3, so the first third of the pull gives fine putts. The current mapping is linear.
- Add a light tick haptic every 10% of power, throttled to one every 60-80 ms. This follows Android's guidance that ticks can grow stronger as an interaction nears its target, and that "given the choice of buzzy haptics or no haptics… choose no haptics" ([Android haptics principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)).

Godot's `vibrate_handheld` wraps a one-shot vibration with duration and amplitude ([Godot Input](https://docs.godotengine.org/en/stable/classes/class_input.html)). That is the legacy path Android calls buzzy. Short pulses with lowered amplitude are the safe use until a plugin exposes the CLICK and TICK primitives (12 ms and 5 ms targets) ([AOSP haptics](https://source.android.com/docs/core/interaction/haptics/haptics-constants-primitives)).

### Hits, trail and audio variation

Rail hits should produce:

- 6-12 sparks along the wall normal
- a 10-15% squash of the ball for 60-90 ms
- a clack whose volume follows impact speed, randomised by about ±2 semitones and ±1.5 dB ([Game Developer](https://gamedeveloper.com/audio/the-power-of-pitch-shifting))

A minimum impact speed stops a rolling ball from machine-gunning clacks. Signature sounds such as the cup drop stay nearly fixed, so they are recognisable ([A Sound Effect](https://www.asoundeffect.com/game-audio-immersion/)). The cup drop is "a golfer's favourite noise" ([Golf Monthly](https://www.golfmonthly.com/news/notice-board/importance-sound-golf-117784)). A thin ribbon trail, about 16-24 points in a preallocated ring buffer, widens and brightens with speed and disappears at rest.

### The hole-out sequence

The hole-out should run as a timed sequence of about 1.2-1.8 s, skippable from about 0.4 s:

1. **0 s:** cup sound, a heavier haptic, and an elastic flag wiggle.
2. **0.1 s:** confetti.
3. **0.25 s:** the score word pops in.
4. **0.8 s:** stars reveal one by one, with a rising ding on each.

Entrances should take about 300 ms and exits 200-250 ms ([NN/g](https://nngroup.com/articles/animation-duration)), using TRANS_BACK ease-out tweens that ignore time scale ([Godot Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html)). Scale the effects to the outcome: par is quiet and a hole-in-one is loud. Shake or confetti on every minor event wears out the reward.

### Slow motion without touching the solver

The project's determinism rule decides how slow motion works, and the current code makes the safe design obvious. `_physics_process` advances the ball with four `GolfBall.substep()` calls per tick at a fixed `GolfFlight.SUBSTEP` of 1/240 s, and the delta argument never reaches the solver. Per the notes, `Engine.time_scale` scales the delta, not the tick count ([uhiyama-lab](https://uhiyama-lab.com/en/notes/godot/hit-feedback-hitstop/)). A global time scale would therefore not slow the ball at all. It would still stretch `_intro_t` and `_result_t`, and any Jolt bodies.

The correct design is a presentation clock. Advance a solver-time budget by `k × real dt`, with k ramping 1.0 → 0.3 → 1.0 around a predicted cup drop. Run whole 1/240 s substeps while the solver lags the budget, and interpolate the rendered ball between the last two substep states by the remainder. The trajectory stays bit-identical: same substeps, same order. Only their pacing against the wall clock changes.

Use it rarely: hole-in-one, eagle or better, or a long putt that the solver has already confirmed will drop. Never trigger it on a miss, or players learn the tell. The physics-reviewer agent should check the change. A golden-shot test should assert that a run with a slow-motion schedule ends in exactly the same state as one without.

### UI polish

UI polish follows the same restraint rule:

- **Typography and components:** at most two fonts, one button component with explicit states, one panel style ([bugnet](https://bugnet.io/blog/ui-design-basics-for-indie-developers)).
- **Touch targets:** at least 48 dp ([TetraLogical](https://tetralogical.com/blog/2022/12/20/foundations-target-size/)).
- **Safe area:** derived from `DisplayServer.get_display_safe_area()` ([Godot DisplayServer](https://docs.godotengine.org/de/4.x/classes/class_displayserver.html)). UiKit already exposes a `safe_top` helper.
- **During a drag:** fade the HUD to 30-40% opacity, so only the power ring and guide remain.
- **Between holes:** a short wipe, then the fly-over and the title card dropping in, so holes never hard-cut.

For Rush, show rivals as coloured ghost balls with matching rings in the world plus a compact side ladder. This avoids the battler-style top bar of avatars flagged as a copying risk.

## Prioritised upgrade plan

The order below ranks by visual gain per unit of effort, with measurement first because two of the largest decisions (glow and shadows) depend on numbers nobody has published for this GPU. Effort is an estimate: S is about a day, M two to three days, L about a week. Each row is its own small commit on the `fairway-flick` branch. Each ends with the Definition-of-done items: tests, no warnings, a screenshot, no `_physics_process` allocations, and a PROGRESS.md entry.

| # | Upgrade | Where it lands | Effort | Expected GPU effect | Gate |
|---|---|---|---|---|---|
| 0 | **Measure first.** Add a `--gfx=` dev arg next to the existing `--fps` (noshadow, noglow, scale=0.75, aa=fxaa\|smaa\|msaa2). Record the baseline and each delta at three views: aim on Step Up, MAP overview, hole-out confetti | core/Boot.gd, golf_scenery.gd | S | none | Per-feature ms table in PROGRESS.md |
| 1 | **Value and colour pass.** Move palettes into a pure-data `GolfTheme` (like CoursePreset): rail body lighter than the carpet, no white or near-white flowers, shaded ball with rim and Grow outline, dark cup with a bright white rim, flag in a world accent, colour-meaning table | games/golf/logic/golf_theme.gd, golf_terrain.gd COLS, golf_game.gd `_walls`/`_decor`/ball | S | ~0 | Greyscale screenshot: ball, cup and guide are the top three values on every hole |
| 2 | **Light, material and post pass.** Half-Lambert and hemispheric ambient in the terrain shader, carpet rim sheen, extruded bevelled rail profile merged per hole (fixes ramp stair-steps), sun 35-50° per world, shadow max distance 25-30 m, AgX or Filmic plus a LUT, debanding on, SMAA 1x or MSAA 2x by A/B, glow off or emissive-only by the row 0 numbers, opaque water with a foam strip | golf_terrain.gd, golf_scenery.gd, golf_game.gd `_walls`, project.godot | M | Likely net saving if glow drops; AA adds back some | GPU median ≤ 12 ms at all three views; no shimmer on rail caps |
| 3 | **Juice package.** Release kick, power ease-in curve and tick haptics, rail sparks and squash, speed trail (preallocated), hole-out timeline with popups and stars, trauma shake honouring `reduce_motion`, presentation-clock slow motion | golf_game.gd `_shoot`/`_effects`/`_process`/`_shot_over`, AudioService calls | M | Low | Golden shot identical with and without slow motion; physics-reviewer pass; no frame over 33 ms on the first hole-out |
| 4 | **Landmark and framing.** Landmark 15-40 m beyond the cup, in the top third of the play frame; the intro fly-over opens on it; per-world skyline ring; Ring 1 props and two to four vignettes per hole; optional tile pop-in "hole assembles" transition | golf_scenery.gd `_windmill`/`_hills`, golf_game.gd intro camera | M | Low (MultiMesh, one palette material) | Screenshot of the play view shows the landmark; draw calls ≤ 100 |
| 5 | **CC0 dressing.** Kenney Nature and Pirate, KayKit Forest for Rings 1-2, recoloured per world, Root Scale per kit, one shared atlas material, MultiMesh per area; one ASSETS.md row per file | games/golf/assets/<kit>/, golf_scenery.gd, ASSETS.md (asset-wrangler agent) | M | Low | ip-checker pass; texture memory under a few MB per world |
| 6 | **Ambient life.** COLOR-masked vertex sway on foliage, windmill blades turned in the vertex shader (pure decoration), scrolling cloud-shadow term in the terrain shader, occasional birds or butterflies on the High tier only | shared foliage shader, golf_terrain.gd | M | Low | Ambient effects under about 10-15% of frame time on the low tier |
| 7 | **Shadow re-architecture, only if row 0 shows the sun shadow costs about 1.5 ms or more.** Bake the ground shadow into an R8 texture at hole load (sun ray-march over the height grid, walls and prop footprints); turn the real-time sun shadow off | golf_terrain.gd (+ a pure helper in logic/ with a unit test) | M-L | Removes the shadow pass | Visual match against the row 2 screenshot; load-time increase under 150 ms |
| 8 | **Quality tiers and warm-up.** Low (scale 0.75, glow off, half particles, no critters), Medium, High; chosen at load; hidden warm-up of every VFX material in the intro; shader baker on a non-headless Android export | core/SettingsService.gd, golf_game.gd intro, export preset | M | Low tier frees ~40% of 3D fragment work | 30 fps floor on a low-end device at Low |
| 9 | **Worlds 2-4.** Coastal, canyon and volcanic kits per the table above, each with a carpet hue, rail profile, landmark, sky, LUT and colour-blind check | per plan step H | L each | Same budget | Same gates per world |

### Performance checks to run on the phone

Run every check on the Vivo V2250 (Adreno 642L, 1260×2800) with the existing `--fps` log. Use median and worst frame over 600 frames, never a single reading.

The **frame budget** keeps the median GPU time at or below about 12 ms at all three views. That is an inference that leaves room for thermal throttling inside the 16.6 ms frame. Draw calls stay at or below the earlier 100-call budget.

A **thermal soak** runs the existing bot (`Boot.bot`) through the three holes for 10 minutes. It passes if 60 fps holds and GPU time drifts by less than about 15%.

The **hitch check** watches the first hole-out, first splash, first slow motion and first hole load. No frame should exceed 33 ms, and the pipeline-compilation monitors should stay flat after the intro warm-up ([Godot docs: pipeline compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)). If the GPU number moves and the cause is unclear, use Perfetto, now Godot 4.7's default Android tracer ([Godot 4.7](https://godotengine.org/releases/4.7/)), to split shadow, opaque, glow and tonemap passes.

The **readability check** desaturates each hole's `--shot` screenshot and runs the coastal and canyon palettes through a colour-blindness simulator. The **determinism check** is a unit test asserting identical end states with and without the slow-motion schedule.

## Conclusion

The research reframes "make it look like the best mini-golf games" from an asset problem into a hierarchy problem. The current scene already has more visual ingredients than reviewers demand: shadows, glow, flowers, fibre noise, a landmark. What it lacks is order. Its darkest rail body undercuts the play edge, white flowers compete with the white ball, and the landmark sits where the portrait camera never looks. Putting that order right costs almost nothing. Two items in today's setup are probably costs without matching value: a near-invisible glow that may be one of the most expensive passes in the frame, and a real-time shadow cast only by static geometry. Measuring them first could pay for anti-aliasing, better materials and juice together.

The determinism rule turns out to help rather than constrain. The solver already runs fixed 1/240 s substeps that ignore frame delta, so slow motion, hit-stop and camera drama can all live on a presentation clock that paces substeps without changing them. The juice layer can therefore be as theatrical as the best games without endangering replays, ghosts or the CPU's shot search. Two things remain unknown and should be settled on the phone, not in research: the actual per-pass costs on the Adreno 642L, and whether Kenney-derived dressing still reads as Fairway Flick's own once it is recoloured.
