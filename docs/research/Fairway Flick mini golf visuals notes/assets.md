# Free, commercially usable 3D asset packs for Fairway Flick (stylised mini-golf) and how to use them in Godot 4

Research date: 2026-11-15. Licences were checked on the primary pages. For four Kenney kits (Minigolf, Nature, Pirate, Holiday) I also downloaded the official zips and read the bundled License.txt. I then measured the GLB files with a small glTF parser (bounding boxes, triangle counts, materials, textures). Figures marked "measured" come from those downloads (kept in the session scratchpad, not in the repo). They are first-hand, so they carry no web citation; the download page is cited instead.

Project context checked in the repo: `project.godot` already has `renderer/rendering_method="mobile"` and `textures/vram_compression/import_etc2_astc=true`. Holes are baked by `games/golf/logic/mini_baker.gd` with `tile := 3.0` (m). `ASSETS.md` has the columns File | Source URL | Author | Licence | Credit needed?.

## 1. Kenney Minigolf Kit and related Kenney kits: contents, scale, licence

### Takeaway
The Kenney Minigolf Kit is CC0 v3.1, with 125 assets in GLB, FBX and OBJ. The modules are 1 × 1 unit (some are 2×2), and every piece shares one 512×512 colormap texture. Each course mesh has its rails baked in. The kit has no sand or water tiles. Kenney's Nature, Pirate, Holiday and Space kits are also CC0, so together they cover all five themes. Attribution is never required.

### Cited Findings
**Licence (Kenney, all kits)**
- Kenney's support page says the assets are "public domain licensed (CC0)", "Attribution is not required", and "You're free to use them, even in commercial projects." — [Kenney Support](https://kenney.nl/support)
- Minigolf Kit page: licence "Creative Commons CC0". The og:description reads "Download this package (125 assets) for free, CC0 licensed!" Updates: 3.1 "Additional models", 3.0 "Color map, color variations", 1.0 "Released in 2022" (dated 04/12/2022). Tags: golf, course, level. — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- The bundled License.txt (measured) reads: "Minigolf Kit (3.1) … Creation date: 05-03-2025 … License: (Creative Commons Zero, CC0) … You can use this content for personal, educational, and commercial purposes. Support by crediting 'Kenney' or 'www.kenney.nl' (this is not a requirement)". — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)

**Minigolf Kit contents (measured from the 3.1 zip)**
- Folders: `Models/GLB format` (125 .glb files plus `Textures/colormap.png`), `Models/FBX format`, `Models/OBJ format`, `Models/Textures/variation-a.png` and `variation-b.png` (alternative colour maps), and `Previews/` (64 px PNG per model). — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- Full piece list, grouped:
  - **Course tiles (1×1):** straight, side, corner, inner-corner, end, start, open, block, block-borders (1×0.5), gap, crest, wall-left, wall-right, walls-to-open, split, split-start, split-t, split-walls-to-open, square-corner-a, round-corner-a/b/c, skew-corner, narrow-block, narrow-round, narrow-square, obstacle-block, obstacle-diamond, obstacle-triangle, bump, bump-walls, bump-down, bump-down-walls, hill-corner, hill-round, hill-square, tunnel-narrow, tunnel-wide, tunnel-double, castle, windmill.
  - **Cups:** hole-round, hole-square, hole-open.
  - **Ramps:** ramp, ramp-low (0.25 high), ramp-medium (0.40), ramp-high (0.65), ramp-sharp, ramp-square, ramp-side, ramp-large and ramp-large-side (both 1×2).
  - **Large 2×2 corners:** round-large-corner(-open), skew-large-corner(-open).
  - **Spline track pieces:** two profiles, "default" (flat with rails) and "concave" (a U-channel). Each profile has 23 pieces: straight, curve, corner-small/large (± ramp), looping, straight-bend(-large), bump-up/down, hill-beginning/end/complete(-half), skew-left/right(-side), cap-front/back. Sizes run up to 4 units long, and the looping is 4 units high.
  - **Raised-course supports:** support(-low)(-bottom), supports(-low)(-bottom).
  - **Props:** structure-windmill, structure-gate, structure-gates, structure-gate-wide, structure-gate-building; flag-red/green/blue and flag-large-red/green/blue (about 1.02 units tall); ball-red/green/blue (0.07 diameter, 572 tris); club-red/green/blue (1.05 long). — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- Grid and dimensions (measured):
  - Module footprint is 1.00 × 1.00, centred on the origin (min −0.5, max +0.5), with the floor bottom at y = 0.
  - On a `straight` piece the playing surface top sits at y = 0.063 and the rail top at y = 0.147. The rails are 0.10 thick at x = ±0.4…±0.5, which leaves a 0.80-wide fairway.
  - Large pieces are 2×2. Spline pieces begin at the origin and extend along +Z, unlike the centred 1×1 modules. — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- Mesh structure (measured):
  - Each piece is one node and one mesh, with the rails baked into the same mesh as the green. There are no separate rail meshes. The preview and sample sheets show the same thing: orange rails moulded onto green tiles.
  - The exceptions are `windmill` and `structure-windmill`, which have 2 nodes and 2 meshes (the blades are separate, so they can spin).
  - Every GLB uses a single material, `colormap`, which references an external `Textures/colormap.png` (512×512, indexed PNG). The textures are not embedded, so the Textures folder must sit next to the GLBs.
  - Meshes have UVs and normals but no vertex colours. — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- Polycount (measured): course tiles run 12–368 triangles. `straight` is 28, `open` 12, `corner` 24, `hole-round` 148, `ramp` 368, `windmill` 282, and spline pieces 140–428. — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- The colormap is a palette of swatch and gradient columns (cream, greens, yellows, oranges, reds, blues, purples, greys, browns). `variation-a.png` and `variation-b.png` are drop-in recoloured palettes, which matches the 3.0 update note "Color map, color variations". — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)

**Related Kenney kits (all show "Creative Commons CC0" on the page)**
- Nature Kit: 330 assets, 1.0 released 2020. The bundled License.txt reads "Nature Kit (2.1) … CC0" (measured). — [Kenney Nature Kit](https://kenney.nl/assets/nature-kit)
  - Contents (measured): trees (default/oak/fat/thin/tall/cone/plateau/blocks/simple/small/detailed, each in normal, `_dark` and `_fall` variants), 6 palms, ~20 pines, cactus_short/tall, rocks, stones, cliff blocks (including waterfall and cave), fences, flowers (purple/red/yellow), mushrooms, lilies, crops, tents, campfire, statues (column, obelisk, head, ring), bridges, logs, stumps, paths, river rocks.
  - Formats: DAE, FBX, GLTF (as .glb), OBJ, STL.
  - Material approach (measured): no textures at all. It uses 23 named flat-colour materials (grass, dirt, stone, leafsGreen, leafsDark, woodBark, water…). Files average 2.1 materials (up to 6). Triangles: median 76, max 720 (crops_wheatStageA).
  - Scale (measured): roughly 1 unit = 1 tile. tree_default is 1.71 tall, tree_palmTall 1.36, cactus_tall 0.75, cliff_block 1×1×1.
- Pirate Kit: 70 assets. 2.0 "Completely remade", 2.1 "Added fortress walls". — [Kenney Pirate Kit](https://kenney.nl/assets/pirate-kit)
  - Contents (measured): palm-straight/bend(-detailed), rocks-a/b/c, rocks-sand-a/b/c, patch-sand(-foliage), patch-grass(-foliage), grass, docks and platforms, ships, a wreck, towers, castle walls, barrels, crates, chest, cannon.
  - Material (measured): one shared 512×512 colormap.
  - Scale (measured) is larger than Minigolf or Nature: palm-straight is 4.21 tall, patch-sand 7.7 × 6.0.
- Holiday Kit: 100 assets, 2.0 "Completely remade". — [Kenney Holiday Kit](https://kenney.nl/assets/holiday-kit)
  - Contents (measured): snow trees (tree-snow-a/b/c), log-cabin modular walls and roofs (including snow roofs), rocks-large/medium/small, snow-pile, snow-flat, snow-bunker, snowman, sleds, lanterns, benches, a toy train and rails, plus seasonal decorations.
  - Material (measured): one shared colormap. Scale: cabin-wall 1×1, tree-snow-a 1.92 tall.
- Other Kenney kits marked "Creative Commons CC0" on their pages, with asset counts from og:description:
  - [Space Kit](https://kenney.nl/assets/space-kit): 150, released 2020.
  - [Platformer Kit](https://kenney.nl/assets/platformer-kit): 150, v4.1.
  - [Castle Kit](https://kenney.nl/assets/castle-kit): 75, v2.0.
  - [Fantasy Town Kit](https://kenney.nl/assets/fantasy-town-kit): 160, v2.0.
  - [Tower Defense Kit](https://kenney.nl/assets/tower-defense-kit): 160, v2.1.
  - [City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban): 40, v2.0.
  - [Survival Kit](https://kenney.nl/assets/survival-kit): 80, v2.0.
  - [Car Kit](https://kenney.nl/assets/car-kit): 45, v3.1.
  - [Graveyard Kit](https://kenney.nl/assets/graveyard-kit): 90, v5.0.
  - [Marble Kit](https://kenney.nl/assets/marble-kit): 160, v2.0.
  - [Coaster Kit](https://kenney.nl/assets/coaster-kit): 180, released 2024.
  - [Food Kit](https://kenney.nl/assets/food-kit): 200.
  - [Furniture Kit](https://kenney.nl/assets/furniture-kit): 140.

### Inferences
- Theme coverage from Kenney CC0 alone:
  - **Meadow/garden:** Nature Kit (trees, flowers, fences, mushrooms, statues) plus the Minigolf windmill and castle.
  - **Beach/coastal:** Pirate Kit (palms, sand patches, sand rocks, docks, wrecks) plus Nature Kit palms.
  - **Desert canyon:** Nature Kit cactus, cliff blocks and rock_tall. Statue_obelisk and column work as landmarks.
  - **Volcanic tropical:** Nature Kit palms and dark rock or cliff pieces. There is no lava or volcano model. Build that ourselves, for example a recoloured cliff stack with an emissive lava material.
  - **Alpine:** Nature Kit pines and Holiday Kit snow trees, log cabins, snow piles and rocks. Avoid the overtly festive items so the theme stays seasonless.
- Each kit uses its own scale. Minigolf and Nature are about 1 unit per tile, while Pirate is about 4× larger. Normalise per kit with a per-folder import scale (see section 4), never by eye per instance.
- Kenney's own preview and sample sheets carry the Kenney logo and CC0 badge. They are reference only and should not ship.

### Gaps
- The Minigolf Kit web page does not list pieces or state the grid size. The list and dimensions above come from the downloaded 3.1 zip.
- I did not download the Space, Platformer, Fantasy Town or other kits, so their material approach and scale are unverified. They are probably colormap-based where the page lists a 2.0+ "remade" version, but that is not checked.

## 2. Quaternius, KayKit, Poly Haven, ambientCG, Poly Pizza, OpenGameArt: licences, styles, and whether they mix

### Takeaway
Quaternius, KayKit's free tiers, Poly Haven and ambientCG are all CC0 per their primary pages. Poly Pizza and OpenGameArt mix licences per asset (Poly Pizza is mostly CC-BY), so only use their items that are individually marked CC0 and record them. In style terms, Kenney (flat palette atlas), KayKit (gradient atlas, low-poly) and Quaternius's simple packs sit close together. Quaternius's Stylized Nature MegaKit is a richer, painterly look and is harder to mix.

### Cited Findings
**Quaternius**
- The FAQ says "All models are under the CC0 License", usable "for free without the need for attribution in commercial, educational, and personal projects". The FAQ names .blend and FBX. It says most packs use an "Atlas Texture" (a single image of coloured squares) and some use individual materials. — [Quaternius FAQ](https://quaternius.com/faq.html)
- Relevant packs listed on the site: Ultimate Stylized Nature Pack, Ultimate Nature Pack, Stylized Nature MegaKit, Simple Nature Pack, Texture Fantasy Nature Pack, Stylized Tree Pack, Ultimate Crops Pack, Ultimate Buildings Pack, Buildings Pack, Simple Buildings Pack, Modular Medieval Building Pack, Medieval Village Pack, Farm Buildings Pack. — [Quaternius](https://quaternius.com/)
- Stylized Nature MegaKit:
  - CC0, 116 unique models (40 trees, 35 plants and flowers, 27 rocks, plus grass and bushes). Formats: FBX, OBJ, glTF.
  - Tiers: the free "Standard" tier is about 60–70% of the pack. "Pro" adds the remaining 30–40%. "Source" adds .blend files and ready-made Unreal, Unity (URP) and Godot shaders (wind grass, stylised leaves).
  - Style: textured and "Ghibli-inspired". — [Quaternius Stylized Nature MegaKit](https://quaternius.com/packs/stylizednaturemegakit.html)
- Ultimate Nature Pack: CC0, 150 models, FBX, OBJ and Blend, marked "not textured" (material colours), free direct download. — [Quaternius Ultimate Nature Pack](https://quaternius.com/packs/ultimatenature.html)

**KayKit (Kay Lousberg)**
- Packs listed include Forest Nature Pack, Platformer Pack, Holiday Bits, Block Bits, Prototype Bits, City Builder Bits, Resource Bits, Medieval Hexagon, Furniture Bits and Space Base Bits. — [Kay Lousberg game assets](https://kaylousberg.com/game-assets)
- KayKit Forest Nature Pack:
  - Licence is "Creative Commons Zero v1.0 Universal … Free for personal and commercial use, no attribution required."
  - Free tier: 100+ models of trees, rocks, bushes and grass. Extra ($9.99+): about double the content, modular terrain, and 8 colour variants per model. Source ($14.99+): .blend files.
  - Formats: FBX, glTF, OBJ.
  - Texturing: "one shared 1024x1024 gradient atlas", which "can be downsampled to 128x128". Godot is named as a compatible engine. — [KayKit Forest Nature Pack](https://kaylousberg.itch.io/kaykit-forest)
- KayKit Platformer Pack:
  - CC0, "no attribution required". The author asks that unmodified copies not be resold.
  - Free tier: 120+ models (floors, walls, ramps, barriers, platforms, pipes, railings, signage, flags, hoops, goals, a ball, a finish line). Bumpers and traps are in the paid Extra tier.
  - Uses the same gradient-atlas approach. Formats: FBX, glTF, OBJ.
  - The page describes the pack as designed for a wide range of games including mobile. — [KayKit Platformer Pack](https://kaylousberg.itch.io/kaykit-platformer)

**Poly Haven (textures, HDRIs, models)**
- Assets are CC0 with no attribution required, and commercial use and redistribution are allowed. Logos, avatars, renders and site text are excluded from CC0. The Terms forbid "Web scraping or data mining without express permission." — [Poly Haven License](https://polyhaven.com/license)

**ambientCG (PBR materials, HDRIs)**
- "All ambientCG assets are provided under the Creative Commons CC0 1.0 Universal License." Credit is optional, commercial use is allowed, and raw files may be included in a video game. — [ambientCG License](https://docs.ambientcg.com/license/)

**Poly Pizza**
- The homepage and Terms do not state a site-wide licence. The Terms say "you agree to adhere to the terms of the Creative Commons license that applies at the time of download". The Terms also forbid using site content for AI training. — [Poly Pizza Terms](https://poly.pizza/docs/tos), [Poly Pizza](https://poly.pizza/)
- Secondary sources say Poly Pizza is mostly CC-BY (including the archived Google Poly models) with some CC0 (for example Kenney and Quaternius re-uploads), and that the licence is shown per model. — [Cinevva guide (secondary)](https://app.cinevva.com/guides/free-3d-model-sites); Google Poly's old help page says CC-BY requires attribution — [Google Poly help](https://support.google.com/poly/answer/7418679?hl=en)

**OpenGameArt**
- The FAQ page returned HTTP 403 to my fetch, so I could not verify OpenGameArt's licence list from the primary page.

### Inferences
- **Safest source set for a credit-free, CC0-only ASSETS.md:** Kenney, Quaternius, KayKit free tiers, Poly Haven and ambientCG. If a model is wanted from Poly Pizza, download the original from the author's own site instead (most of its CC0 content is Kenney or Quaternius re-uploads). That way the licence is verified at source.
- **Style mixing:**
  - Kenney Minigolf, Pirate and Holiday kits all use a tiny palette atlas with soft vertical gradients, and Kenney's Nature Kit uses flat named materials. Both read as clean, low-poly and toy-like.
  - KayKit's gradient atlas is very close in spirit (rounded, chunky, saturated). Quaternius's simple and ultimate packs (flat colours) also fit.
  - The Stylized Nature MegaKit (textured, painterly) will look different next to Kenney tiles unless every asset gets a shared toon or stylised shader. Treat it as a separate visual direction.
- Poly Haven and ambientCG are best used sparingly in this style: for example one low-resolution HDRI for sky and ambient light, or tiling noise textures for sand, water or lava detail. Full PBR photo textures will clash with flat low-poly geometry.

### Gaps
- I did not fetch the individual Quaternius pages for Ultimate Stylized Nature, Simple Nature or Buildings, so their exact counts and formats are unverified. The Ultimate Nature page lists FBX, OBJ and Blend only, with no glTF. Blender (or Godot's FBX importer) would be needed to convert.
- I did not verify which KayKit packs other than Forest and Platformer have free tiers.
- No primary Poly Pizza licence-policy page was found. OpenGameArt's FAQ was blocked (403).

## 3. Can Kenney Minigolf pieces replace or decorate our procedural 3 m tiles? Collision approach

### Takeaway
Yes, as visual-only meshes, by scaling the 1-unit modules ×3 to our 3 m grid. The mapping is direct for straight, corner, ramp, gap, cup and tee. Bumpers, sand and water need our own procedural meshes, or Kenney `open` or `block` floors with a recoloured material. Because the rails are baked into each tile, our wall segments must match Kenney's rail line (0.1 unit inset, so 0.3 m after scaling), or we keep our own procedural rails. Collision stays in our height grid and wall segments. Imported meshes get no collision.

### Cited Findings
- Each Minigolf piece is one mesh with rails included. Rails occupy x = ±0.4…0.5 on a 1-unit tile (0.10 thick), the floor top is at y = 0.063, and the rail top is at y = 0.147 (measured). — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- At ×3 scale: tile 3.0 m, rail 0.30 m thick, fairway 2.40 m wide, floor top 0.19 m, rail 0.25 m above the floor. ramp-low, ramp-medium and ramp-high rise 0.75 m, 1.2 m and 1.95 m over 3 m. The Kenney ball would be 0.21 m across, so keep our own ball (calculated from the measured sizes above). — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- Our baker uses `tile := 3.0` (repo: `games/golf/logic/mini_baker.gd:114`). The ball logic uses `hole.wall_height` and `hole.cup_r` (`games/golf/logic/golf_ball.gd`), so rail height and cup radius are data we control.
- Godot import hints: `-col`, `-convcol`, `-colonly` and `-convcolonly` create collision from mesh names. `-noimp` skips a node. `-occ` and `-occonly` create occluders. Suffixes may use `-`, `$` or `_` and are case-insensitive. — [Godot: Node type customization using name suffixes](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html)

### Inferences
- **Mapping from our tile kinds to Kenney pieces:**
  - straight → `straight`
  - corner → `corner`, `inner-corner`, `round-corner-a/b/c` or `square-corner-a`
  - ramp → `ramp-low`, `ramp-medium` or `ramp-high` (pick by our rise), or `ramp-sharp` for a kicker
  - gap/jump → `gap`
  - cup → `hole-round`
  - tee → `start`
  - dead end → `end`
  - wide/open areas → `open` (no rails) or `side`
  - landmarks → `windmill` (animate its blade node), `castle`, `tunnel-*`, `structure-gate*`
  - elevated holes → `supports*` and `support*` columns under raised tiles
  - Kenney has no bumper, sand or water pieces. Build these procedurally, or use `obstacle-block` / `obstacle-diamond` / `obstacle-triangle` as static blockers. For sand and water, use `open` with a material override, or our own mesh.
- **Risk:** Kenney's ramps and hills are fixed shapes. If our height grid uses different rise and run values, the visual surface will not match the physics surface, and the ball will float or sink. Two options:
  - (a) choose our ramp rises to match Kenney's (0.25, 0.40 or 0.65 units × 3), or
  - (b) keep the green and ramp surfaces procedural (generated from the height grid, so they are guaranteed to match) and use Kenney pieces only for rails, cups, flags, windmills and props.
  
  Option (b) is the lower-risk "decorate" path. Option (a) is the "replace" path, and it needs a test that samples the Kenney mesh height against the height grid.
- **Rail mismatch:** if our wall segments sit on the tile edge (x = ±1.5 m) rather than at Kenney's inner rail face (±1.2 m), the ball will visually pass into the rail. Either move the wall segments inwards by 0.3 m (plus ball radius) when a Kenney tile is used, or drop Kenney rails by using `open` plus our own rail meshes.
- Do not add `-col` suffixes or collision shapes: CLAUDE.md says our physics is height grid plus wall segments. Imported scenes should stay pure MeshInstance3D so they never interact with Jolt.
- Kenney's spline track pieces (loops, banked curves) are 4 units long and start at the origin. They do not fit a 3 m tile grid cleanly. Use them only as set-dressing or for special holes.

### Gaps
- I did not test-import the kit into this Godot 4.7 project, so I did not confirm visually how the ×3 rail thickness reads from our high camera. A `/shot` capture after import would settle this.
- Exact cup radius in the Kenney `hole-round` mesh was not measured; this is needed to match `hole.cup_r`.

## 4. Importing into Godot 4: glTF/GLB, atlas materials, MultiMesh, LOD, ETC2/ASTC, draw calls

### Takeaway
Import the GLBs with the Textures folder alongside, and set the colormap PNG to VRAM Compressed with mipmaps. Our project already enables ETC2/ASTC import. Share one StandardMaterial3D per atlas across all pieces. Use MultiMeshInstance3D, split by area, for repeated scenery (trees, flowers, rocks, fence posts). Mesh LOD is generated automatically for glTF and is cheap to leave on. Each kit's per-folder scale should be baked in through import settings.

### Cited Findings
- **Import options (Meshes section):** `Generate LODs`, `Create Shadow Meshes` (welds vertices to cut shadow bandwidth), `Ensure Tangents`, and `Light Baking` (Static Lightmaps generates UV2).
- **Root options:** `Root Type`, `Root Name`, and `Apply Root Scale`. When Apply Root Scale is enabled, Root Scale is baked into meshes and the root stays at (1,1,1).
- **Customisation:** per-object options live in the Advanced Import Settings dialog. An `Import Script` with `_post_import(scene)` can post-process scenes.
- **Embedded textures (glTF/FBX):** `Embedded Texture Handling` offers Discard All Textures, Extract Textures, Embed as Basis Universal, and Embed as Uncompressed.
- Source for all of the above: [Godot: Import configuration](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)
- **Texture import:**
  - `Compress > Mode` options: Lossless, Lossy, VRAM Compressed, VRAM Uncompressed, Basis Universal. VRAM Compressed is the 3D default and cuts size by about 4–6×.
  - With `High Quality` off, mobile uses ETC2. With it on, mobile uses ASTC (Forward+ and Mobile renderers only).
  - Basis Universal gives smaller files at lower quality.
  - Mipmaps are recommended in 3D and cost about 33% more memory. VRAM Compressed is not advised for low-resolution 2D textures. — [Godot: Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)
- **Mesh LOD:**
  - Generated automatically on import for glTF, .blend, Collada and FBX (not OBJ unless imported as a Scene), using meshoptimizer.
  - Works on MeshInstance3D and MultiMeshInstance3D.
  - Global threshold is `Rendering > Mesh LOD > LOD Change > Threshold Pixels` (default 1 px), or `mesh_lod_threshold` on a viewport at runtime. Each node also has `LOD Bias`.
  - In a MultiMesh, every instance shares one LOD level, chosen from the AABB point nearest the camera. Split distant instances into separate MultiMeshInstance3D nodes.
  - Visibility ranges (HLOD) are the manual alternative. — [Godot: Mesh level of detail](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html)
- **MultiMesh:**
  - Draws many copies of one mesh as one draw primitive.
  - It is culled all-or-nothing, so split it by world area.
  - Set `transform_format` before `instance_count`. Use `visible_instance_count` to show fewer instances.
  - Per-instance data reaches the shader via `INSTANCE_CUSTOM` and `INSTANCE_ID`. — [Godot: Optimization using MultiMeshes](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)
- **Kenney material setups (measured):** Minigolf, Pirate and Holiday GLBs each have exactly one material (`colormap`) pointing at an external PNG. Nature Kit GLBs have 1–6 untextured flat-colour materials, drawn from 23 names shared across the kit. — [Kenney Nature Kit](https://kenney.nl/assets/nature-kit)
- **KayKit:** one 1024² gradient atlas, which can be downsampled to 128². — [KayKit Forest Nature Pack](https://kaylousberg.itch.io/kaykit-forest)

### Inferences
- **Draw calls:** in Godot every mesh surface is one draw (per pass). A whole Kenney Minigolf hole uses one material. Two ways to keep it cheap:
  - For roughly 20–60 tiles, merge each hole's tiles into a single ArrayMesh at build time. The baker already knows the tile list, so it can append the tile meshes with transforms. That gives one draw call per hole.
  - Alternatively, use one MultiMeshInstance3D per distinct piece type.
  
  Either way there are no per-frame allocations, which fits the CLAUDE.md "no new per-frame allocations in _physics_process" rule.
- **Nature Kit:** with an average of 2.1 materials per file, a tree is about 2 draws. Use the import step's material extraction (Advanced Import Settings) so all files reference the same 23 `.tres` materials, and use MultiMesh for scatter. Alternatively, bake the flat colours into a small palette texture so Nature Kit matches the single-atlas kits.
- **Atlas texture compression:**
  - Small palette atlases (512² Kenney, 1024²→128² KayKit) are mostly flat colour plus gentle gradients, so ETC2 block artefacts can bleed between swatches at mip levels. Two options: set the atlas to `Lossless` or `VRAM Uncompressed` (512² RGBA is only about 1 MB), or keep VRAM Compressed with `High Quality` (ASTC) and check on device.
  - Also set texture filtering to nearest or linear without mipmaps, or keep UV islands well inside swatches, to avoid colour bleeding.
  - This is an inference from how the atlases are built. It is not a documented Kenney or Godot recommendation, so verify it with a screenshot.
- **Scale:** put each kit in its own folder and use an import preset with `Apply Root Scale` enabled. For Minigolf use Root Scale 3.0 so 1 unit becomes a 3 m tile. Nature Kit is about 3.0 as well; Pirate is about 0.75–1.0. This keeps instance transforms at unit scale.
- **Textures:** keep `Embedded Texture Handling` irrelevant by importing Kenney's external colormap once and sharing it. All Minigolf GLBs reference the same relative path.
- **Animation:** the windmill blade is a separate node, so it can be spun in `_process`. Per CLAUDE.md, any node moved in `_process` in a physics-interpolated project needs care: it is visual-only, but check the interpolation mode.

### Gaps
- I could not fetch the exact ProjectSettings descriptions for `rendering/textures/vram_compression/import_etc2_astc` (the page was too large to read). The repo already sets it to true.
- I did not benchmark draw calls on the test phone.

## 5. Style consistency: recolouring to one palette and mixing low-poly packs

### Takeaway
Because Kenney's colour-mapped kits and KayKit sample all colour from one small atlas, recolouring means editing or swapping a single PNG per kit. Kenney ships two alternative atlases (variation-a and variation-b) for Minigolf. Per-theme recolours (desert, volcanic, alpine) are then just per-theme atlas PNGs or material overrides. Flat-material kits (Kenney Nature, Quaternius Ultimate Nature) are recoloured by overriding their named materials.

### Cited Findings
- The Minigolf colormap is a palette of colour columns, each a swatch with a subtle vertical gradient. The kit includes `variation-a.png` and `variation-b.png` (512² each) as alternative colourings (measured; the 3.0 changelog says "Color map, color variations"). — [Kenney Minigolf Kit](https://kenney.nl/assets/minigolf-kit)
- KayKit uses one shared gradient atlas, and the paid Extra tier adds 8 colour variations per model. — [KayKit Forest Nature Pack](https://kaylousberg.itch.io/kaykit-forest)
- Quaternius packs use either an atlas of coloured squares or individual materials, "which makes color variations easier". — [Quaternius FAQ](https://quaternius.com/faq.html)
- The Nature Kit's 23 shared material names (grass, dirt, dirtDark, stone, stoneDark, leafsGreen, leafsDark, leafsFall, woodBark, wood, water, colorRed…) were measured from the GLBs. — [Kenney Nature Kit](https://kenney.nl/assets/nature-kit)

### Inferences
- **Recommended pipeline:**
  - (1) Define one project palette per theme, roughly 12–16 colours: fairway green, rail colour, sand, water, rock, foliage ×2, wood, accent ×2, and so on.
  - (2) For colormap kits, author `colormap_<theme>.png` by repainting the swatch columns, then assign it with a material override at load. The mesh UVs stay unchanged.
  - (3) For flat-material kits, map the 23 Nature Kit material names to palette entries in a small `.tres` material library per theme.
  - (4) Use the same lighting rig, sky or HDRI, fog and outline/toon settings across all props, so sources look unified.
- **Mixing rules:**
  - Stay within flat or gradient low-poly sources (Kenney, KayKit, Quaternius simple and ultimate).
  - Match silhouette chunkiness (bevelled, rounded edges).
  - Normalise scale per kit.
  - Avoid mixing in photo PBR textures or the painterly MegaKit unless every asset moves to that look.
- **Originality (CLAUDE.md golden rule):** generic CC0 kit pieces such as windmills, castles and palms are generic genre props, not imitations of a specific commercial game. Still, run the `ip-checker` agent over the asset names and screenshots, and do not ship the Kenney preview sheets (they carry the Kenney logo).
- **ASSETS.md row example:** `games/golf/assets/kenney_minigolf/straight.glb | https://kenney.nl/assets/minigolf-kit | Kenney (kenney.nl) | CC0 1.0 | No (optional credit "Kenney")`. One row per file is required by the repo's ASSETS.md header. A folder-level row would need the ip-checker or asset-wrangler rules to accept globs, which is unverified.

### Gaps
- Recolouring has not been tried in-engine. No screenshot evidence yet of how a desert or volcanic repaint of the Minigolf atlas looks.
- No primary source was found on blending Kenney with KayKit specifically. The compatibility judgement above is my own, based on the measured material approaches and the vendors' descriptions.
