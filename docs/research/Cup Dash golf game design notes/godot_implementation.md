# Implementing a 3D golf game in Godot 4.5-4.7 (GDScript, Jolt available) at 60 fps on mid-range Android, portrait

Context: the project ("Playjar") already runs Godot with `rendering_method="mobile"`, Jolt as the 3D engine, `physics_ticks_per_second=60` and `physics_interpolation=true` (project.godot, checked 2026-11-14). It has a deterministic custom pool solver (shared/cue_sim, 1/240 s substeps, PackedFloat64Array state). The golf design doc (docs/games/golf.md) already proposes "custom RK4 integrator at 240 Hz for drag and Magnus lift; hand off to a Jolt RigidBody3D (CCD on) or a custom roll model on landing", "nine compact holes built from modular tiles", and a CPU that grid-searches simulated shots.

Note on sources: Godot's official docs and release pages were reachable. The Terrain3D docs pages returned HTTP 404 when fetched directly (several URLs), so Terrain3D facts come from search-result summaries of its docs. Wherever a recommendation is my own engineering reasoning, it is under "Inferences".

## 1. Terrain: representation, collision, fast height/normal/surface sampling, mobile cost

### Takeaway
For a deterministic custom ball solver, the simplest robust choice is a project-owned heightfield: a regular grid of heights plus a surface-type (splat) grid stored in a per-hole Resource. The ball solver samples it directly in GDScript, and the same data builds a chunked ArrayMesh for rendering. Terrain3D does run on Android with the Mobile renderer, but its own docs call mobile "experimental at best" and the Compatibility renderer can't render its albedo. Its height queries also wouldn't be part of your deterministic, unit-testable logic layer. Jolt's HeightMapShape3D only matters if you hand the ball to a Jolt RigidBody3D, which this note recommends against (section 2).

### Cited Findings
- Terrain3D on Android: its docs say Android is reported to work as of Terrain3D 0.9.1 on Godot 4.2. Textures must be imported as PNG/TGA (not DDS) and ETC2/ASTC VRAM compression enabled. The docs call all mobile platforms "experimental at best" and the reports are dated and unofficial. — [Terrain3D docs: Mobile & Web Support (search summary; direct fetch returned 404)](https://terrain3d.readthedocs.io/en/latest/docs/mobile_web.html)
- Terrain3D on the Compatibility renderer and WebGL: "not fully supported". The mesh builds but the shader fails because Godot doesn't fully support Texture2DArrays in Compatibility. Some arrays work, albedo does not. — [Terrain3D docs: Mobile & Web Support (search summary)](https://terrain3d.readthedocs.io/en/latest/docs/mobile_web.html)
- Terrain3D is free and open source. — [GameFromScratch: Terrain3D – A New Terrain Engine for Godot](https://gamefromscratch.com/terrain3d-a-new-terrain-engine-for-godot/)
- Jolt and HeightMapShape3D: Jolt's *active edge detection* marks heightmap and concave-mesh triangle edges as active or inactive by the angle to the neighbouring triangle. Collisions with inactive edges use the triangle normal instead, which suppresses "ghost bumps" on internal edges. The threshold is `physics/jolt_physics_3d/collisions/active_edge_threshold`. *Enhanced internal edge removal* (`simulation/use_enhanced_internal_edge_removal`, with separate toggles for queries and motion queries) adds runtime contact-point checks. Neither fixes ghost collisions between two different bodies, so a terrain split into several bodies or tiles can still produce bumps at the seams. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- Jolt: frozen kinematic RigidBody3Ds don't report contacts with static or kinematic bodies by default, and the docs flag this as relevant for complex concave or heightmap geometry. Opt in with `simulation/generate_all_kinematic_contacts`. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- Jolt ray casts: `face_index` is always -1 unless `Physics > Jolt Physics 3D > Queries > Enable Ray Cast Face Index` is on, which costs about 25% more memory for ConcavePolygonShape3D. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- General Godot advice: frame drops when objects touch are often caused by an overly complex collision shape. — [Godot 4.7 docs: Troubleshooting physics issues](https://docs.godotengine.org/en/4.7/tutorials/physics/troubleshooting_physics_issues.html)
- No open-source Godot 4 golf project combining ball physics with heightmap terrain turned up. swiftroot/s6 is a heightmap terrain experiment with a collision component, not a golf game. — [github.com/swiftroot/s6](https://github.com/swiftroot/s6)
- Existing design intent: "Nine compact holes built from modular tiles". — docs/games/golf.md (local)

### Inferences
- **Recommended data model (my design):** a `HoleData` Resource (pure data, no Node) holding:
  - `heights: PackedFloat32Array` (or Float64 if the bit-exact hash must cover terrain math; see section 2) on a regular grid, for example 1.0 m cells for the fairway and rough region and 0.25-0.5 m cells for a separate green patch. A 1 m grid over a 60 x 320 m par-4 corridor is about 19k samples (about 77 kB as float32), so memory is trivial.
  - `surface: PackedByteArray`, one byte per cell (0 = OOB, 1 = tee, 2 = fairway, 3 = rough, 4 = sand, 5 = green, 6 = water, 7 = fringe).
  - Origin, cell size, cup/tee/pin positions, and tree positions and radii.
- **Height sampling:** the ball solver's height function should match how the render mesh is triangulated, or the ball will visibly float or sink on coarse cells. Use per-triangle barycentric interpolation (split each cell along a fixed diagonal, matching your ArrayMesh index order) rather than true bilinear interpolation. The normal is then the constant triangle normal, or use bilinear with an analytic gradient if the mesh is also generated with matching smoothing. A sketch for the triangle version:
  - `ix = floor((x-ox)/c)`, `fx = (x-ox)/c - ix` (same for z)
  - Read 4 corners from the flat array: `i = iz*w + ix`
  - If `fx + fz <= 1` use triangle (h00, h10, h01), else (h11, h01, h10)
  - Height and the analytic gradient (`dh/dx`, `dh/dz`) give the normal `n = normalize(-dh/dx, 1, -dh/dz)`
  - This is about 20-30 GDScript ops per call, with no allocations if you return values via member fields instead of a new Vector3 per call. That respects the project rule against per-frame allocations in `_physics_process`.
- **Surface lookup:** nearest-cell byte read from `surface`, used for roll friction, bounce restitution and lie. Paint the visuals from the same grid (upload it as an `Image.FORMAT_R8` texture with nearest filtering, or a smoothed RGBA splat) so "what you see is what the ball feels".
- **Render mesh:** generate chunked ArrayMeshes (for example 32x32-cell chunks) from the same heights at load time, using `SurfaceTool` or raw arrays. 9 holes x a handful of chunks is a few dozen draw calls at most, and only one hole is visible at a time. The mesh needs no collision unless you want Jolt ray casts (the camera can use the heightfield instead; see section 4).
- **Modular tiles vs heightmap:** tiles (GridMap or hand-placed meshes) are faster to author but make the ball's ground query a mesh-intersection problem. A trimesh in GDScript is slow, which would push you onto Jolt shape queries and give up determinism. A hybrid keeps the tile-based authoring the design doc wants: author holes from tiles in the editor (or procedurally), then bake their height and surface into the HoleData grid offline with an editor tool script. The runtime only knows the grid.
- **Terrain3D or HTerrain:** worth it only for large open terrain with texture painting and LOD. For 9 compact holes viewed one at a time, a GDExtension dependency (Terrain3D is C++) is extra Android build risk, and its "experimental" mobile status contradicts the "mobile first" rule.
- **Greens:** use a finer separate grid (0.25 m) so breaks are smooth, then sample the green grid when inside its bounds and the coarse grid elsewhere. The cup is an analytic feature handled in the solver, not a hole in the heightfield.

### Gaps
- Couldn't retrieve Terrain3D's data-API docs (height/normal/control queries, region sizes) or current mobile test results. Every docs URL fetched returned 404, so its query cost from GDScript is unverified.
- Didn't research HTerrain (Zylann) for Godot 4.5+ mobile status.
- No measured draw-call or memory numbers for Terrain3D on Mali or Adreno.

## 2. Ball simulation: custom deterministic integrator vs Jolt RigidBody3D; tunnelling, rest, cup, GDScript throughput

### Takeaway
Use a fully custom, fixed-step ball solver for flight, bounce, roll, cup and trees, as a pure GDScript class in games/golf/logic/, following the cue_sim pattern. Godot's Jolt docs make no determinism guarantees and expose only basic CCD knobs. The project's own solver is proven bit-exact between desktop and an Adreno 642L phone, and benchmarked on that phone at 144 µs per 1/240 s substep for a full 16-ball table. A single golf ball is far cheaper, so live simulation costs well under 1 ms per frame, and on the order of 50-100 AI rollouts fit in about 0.5 s if you use a coarser planning step. This throughput is an estimate that needs a `--bench=golf` measurement.

### Cited Findings
- Godot's "Using Jolt Physics" page doesn't discuss determinism at all. The only threading note is that "Run On Separate Thread" is "experimental" and "has not been tested very thoroughly". — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- Jolt CCD settings: `continuous_cd/movement_threshold` became `simulation/continuous_cd_movement_threshold` and `continuous_cd/max_penetration` became `simulation/continuous_cd_max_penetration`, and both changed from percentages to fractions. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- Jolt sleep settings: `simulation/allow_sleep`, `simulation/sleep_velocity_threshold`, `simulation/sleep_time_threshold`. The page gives no default values. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- Other Jolt behaviours: Baumgarte stabilisation is applied to position only (`Baumgarte Stabilization Factor`). Contact impulses are estimates. Jolt shrinks shapes before applying the collision margin. The solver settings are now `simulation/position_steps` and `simulation/velocity_steps`. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- Godot's tunnelling advice: enable Continuous CD on the RigidBody, which "can sometimes" fix it. Failing that, thicken static colliders or enlarge the fast object's shape according to its speed. — [Godot 4.7 docs: Troubleshooting physics issues](https://docs.godotengine.org/en/4.7/tutorials/physics/troubleshooting_physics_issues.html)
- Jolt became built in with Godot 4.4, where the release page still labelled it "experimental" and opt-in. — [Godot 4.4 release page](https://godotengine.org/releases/4.4/). It is the default 3D engine for new projects in later versions. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html); [Cinevva: Godot 4.6 released](https://app.cinevva.com/news/2026-02-27-godot-4-6-released.html)
- **Project benchmark (local evidence, docs/PROGRESS.md):** CueSim on a Vivo phone (Adreno 642L) produced a golden-break hash identical to desktop ("bit-exact cross-platform"). Live cost was 144 µs per substep (worst case about 0.6 ms per 60 Hz frame during a break). AI planning at 1/120 s took about 122 ms per break and about 4 ms per typical mid-game shot, so about 100 rollouts take about 0.4 s on one core. Desktop: 77 µs per substep.
- Reference golf-physics library: **OpenFairWay** (MIT, C# core, Godot 4.5+ with .NET 9) uses "aerodynamic drag and Magnus lift from wind-tunnel polynomial fits". It has a spin-dependent coefficient of restitution and tangential retention bounce model (citing Penner), kinetic and rolling friction, grass viscosity and a "critical angle" for ground interaction, and "check up" for high-spin shots. It ships Fairway/FairwaySoft/Rough/Firm surface presets, plus `SurfaceZone` overrides. Its quick-start values are kinetic friction 0.30, rolling friction 0.030, grass viscosity 0.001 and critical angle 0.25. It has a headless `PhysicsAdapter` with no scene tree and works in SI units. — [github.com/digitalhand/openfairway](https://github.com/digitalhand/openfairway); [Godot Asset Library: OpenFairWay](https://godotengine.org/asset-library/asset/4770)
- Existing tuning targets (local, docs/games/golf.md):
  - Ball: 42.67 mm, 45.93 g
  - Cd about 0.27 rising to about 0.32 when the spin ratio exceeds 0.1
  - Cl about 0.54·S^0.4, clamped at 0.25
  - Spin decays about 4% per second
  - Green roll deceleration 0.6-0.9 m/s² plus g·sin(slope)
  - Cup capture when speed is under about 1.3 m/s with the ball centre over the cup

### Inferences
- **Why not Jolt for the ball:**
  1. Godot documents no determinism guarantee for Jolt, and the AI rollouts, replays and unit tests need repeatable results.
  2. AI rollouts would have to run through a live physics space. You can't cheaply clone a Jolt world state from GDScript for hundreds of what-if shots.
  3. Rolling realism (grass drag, check-up, critical-angle bounce) isn't a rigid-body contact model anyway, so you'd override most of Jolt's response.
  4. A hand-off from the custom flight model to a RigidBody3D creates a discontinuity at landing and splits the code into two code paths.

  Jolt remains useful for non-gameplay decoration (falling flags, debris), if any.
- **Integrator structure (follows the cue_sim pattern):**
  - State is a few floats in member variables (px, py, pz, vx, vy, vz, wx, wy, wz) or a PackedFloat64Array.
  - Phases form a state machine: FLIGHT → BOUNCE (impulse) → ROLL/SLIDE → REST, plus CUP and WATER/OOB.
  - FLIGHT: RK4 at 1/240 s for drag plus Magnus plus wind, as golf.md says. RK4 means 4 force evaluations per step. Semi-implicit Euler at 240 Hz would probably match to within the ±3% carry tolerance at a quarter of the cost. Measure both in the carry-distance test and keep RK4 only if it's needed.
  - ROLL: a closed-form or semi-implicit Euler model on the surface tangent plane, with gravity component g·(n × (n × ŷ)), rolling deceleration μ_r·g per surface type, and grass viscosity.
  - Wind is a velocity offset in the drag term, per golf.md.
- **Live cost:** 60 Hz physics ticks × 4 substeps of 1/240 s means a single ball plus heightfield sample is roughly 10-30 µs per substep on an Adreno 642L-class phone (scaled from the 144 µs/substep 16-ball pool solver, which also does pairwise collisions). That's about 0.1 ms per frame, negligible. This estimate is unmeasured; add a `GolfBench` modelled on cue_bench.gd.
- **AI rollouts:** a drive is about 6-7 s of flight plus 3-10 s of roll. At 1/240 s that's about 2-4k substeps, or roughly 40-100 ms per shot by the estimate above. Practical options:
  1. Plan with RK4 at 1/60 s for flight, since RK4 tolerates coarse steps, and 1/120 s for roll. That is about 4-8x fewer steps, so roughly 5-20 ms per rollout and about 25-100 rollouts in 0.5 s.
  2. Cache a per-club carry table (launch speed/angle/spin to carry and apex) so the grid search only fully simulates the top candidates.
  3. Spread rollouts across frames (a budget of N per frame) or use a WorkerThreadPool task. The logic is pure RefCounted and touches no nodes, so this is thread-safe.

  These figures are extrapolations and must be benchmarked on the test phone and on a Mali-G57-class low-end device.
- **Determinism:**
  - GDScript `float` is 64-bit, and PackedFloat64Array preserves it. PackedFloat32Array rounds on store, so if heights are stored as float32, the rounding is deterministic but the same file must be used on every platform. That's fine as long as heights are loaded from the Resource, not regenerated from libm-dependent noise.
  - Risk: transcendental functions (`pow` for Cl = 0.54·S^0.4, `exp` for spin decay, `sin`/`cos`) come from the platform's libm and are not guaranteed bit-identical across Android bionic and desktop. cue_sim's identical hash shows its particular code path was identical, but the golf model adds `pow`.
  - Mitigation: replace `pow(S, 0.4)` with a polynomial or lookup-table fit, and replace per-step `exp` decay with a precomputed per-step multiplier (spin *= k, where k = 0.96^(1/240) is computed once). Then add a golden-shot hash test like cue_bench.
- **Tunnelling at 70 m/s:** at 1/240 s the ball moves 0.29 m per substep, about 14 ball radii. With a heightfield there is no "thin wall", so tunnelling means stepping past a ridge or into terrain between samples.
  - Swept test (my design): each substep, compute the clearance g(t) = p_y - r - h(p_x, p_z) at the start and end of the segment. If the segment spans more than one cell, also check at each cell-boundary crossing (2D DDA along the xz path, at most about 2 checks per substep at 1 m cells). On a sign change, bisect 6-8 times to find the contact time, apply the bounce at that point with the triangle normal, and integrate the remainder of the substep.
  - This is deterministic and cheap. It also handles landing on steep faces, which a one-sample-per-step check gets wrong.
  - Trees: model each as a vertical cylinder (trunk) plus a sphere or cone canopy (a soft "leaf" drag zone with a random-but-seeded deflection from core/Rng), with an analytic segment-vs-cylinder test.
- **Resting on slopes:** with a custom solver, use an explicit rule instead of Jolt sleep.
  - The ball stops if speed < v_rest (about 0.02-0.05 m/s) AND the tangential gravity component g·sinθ < μ_static·g·cosθ for the current surface. Fringe and green slopes under about 2-3° hold, while steeper slopes keep rolling.
  - Add a minimum-time-below-threshold (for example 0.25 s) to avoid stopping at the apex of a back-roll.
  - This gives the "ball comes to rest on slopes" unit test a precise definition.
- **Cup model:** treat the cup as a 108 mm-diameter disc (official size; verify against the rules doc) at the pin position, analytically.
  - If the ball centre passes within cup_r of the cup centre during a substep (a segment-vs-circle test, not a point test, to avoid fast balls skipping over), and the speed is under the capture threshold (about 1.3 m/s per golf.md), it drops.
  - At higher speed, do a lip interaction: deflect the velocity by the rim-contact normal and reduce speed by a percentage, giving a lip-out or a "horseshoe".
  - The flagstick can be ignored or handled as a thin cylinder.
- **Physics interpolation for the ball:** set the ball's Node3D transform only in `_physics_process` (after the solver's 4 substeps). Godot's interpolation then smooths it at any display rate. When teleporting (new shot from a drop, next hole), call `reset_physics_interpolation()` on the ball after setting the position, or it will streak. That's the same issue CLAUDE.md records from device testing on 2026-11-11.

### Gaps
- No published measurements of GDScript float-heavy throughput on Snapdragon 6/7 Gen-class or Mali-G57/G68 devices. The only hard number is the project's own Adreno 642L CueSim benchmark.
- No source confirmed whether Godot builds Jolt with its cross-platform-deterministic option, or Jolt's CCD behaviour against HeightMapShape3D at 70 m/s. I found no Godot-specific reports.
- Didn't verify OpenFairWay's integration method or timestep (the README doesn't say). Its C#/.NET dependency makes it reference material only for this GDScript project. Per project rules, describe its approach and don't port its code.

## 3. Rendering on mobile: renderer choice, grass and stripes, trees, sky, shadows, AA, trail, slope grid, water, budgets

### Takeaway
Stay on the **Mobile (Vulkan) renderer**, which the project already uses. Godot 4.7 states it "matches or even outperforms" Compatibility in a number of benchmarks, and only Forward+ and Mobile get ubershaders, pipeline precompilation and the 4.5 shader baker. Draw grass, stripes, green and fringe in one terrain shader driven by the surface grid rather than geometry. Use MultiMesh low-poly trees, a single directional light with a short shadow distance (or blob shadows only), a procedural sky with fog, and a cheap unlit water shader with no screen or depth reads. Pick the MSAA level once at startup.

### Cited Findings
- Godot 4.7 release: "the Vulkan Mobile renderer matches or even outperforms our Compatibility renderer in a number of benchmarks". 4.7 also adds Vulkan subsampled images (foveated rendering, XR), per-pass environment uniform pools, nearest-neighbour filtering for 3D resolution scaling, and Perfetto as the default Android tracing tool. — [Godot 4.7 release page](https://godotengine.org/releases/4.7/)
- Godot 4.7 was released in June 2026 (Phoronix dated it 18 June 2026). — [Phoronix](https://phoronix.com/news/godot-4.7-released); [GamingOnLinux](https://www.gamingonlinux.com/2026/06/godot-engine-4-7-is-out-bringing-a-new-asset-store-hdr-support-steam-frame-support/)
- The Mobile renderer is a forward, single-pass-lighting renderer optimised for mobile GPUs. Mixing subpasses and normal passes carries a notable penalty on tile-based GPUs. The first pass can draw multiple lights without shadows plus up to one DirectionalLight3D with shadows. — [Godot docs: Internal rendering architecture](https://docs.godotengine.org/en/4.5/engine_details/architecture/internal_rendering_architecture.html)
- Arm and Godot found the Mobile renderer stored both MSAA and resolve attachments back to main memory, which is very costly on tile-based Mali. A test scene (one cube, 2x native resolution, 4x MSAA) ran at 50 fps on a Pixel 8 Pro. The fix (PR #98670, which derives load/store ops from the render graph, tested on 4.4-dev5) made it V-sync locked, with GPU utilisation at 26% and external writes down about 300x. — [Arm Community blog, Clay John, 11 June 2025](https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/optimizing-3d-scenes-in-godot-on-arm-gpus)
- Godot's docs on AA (via search summary): MSAA only smooths geometry edges, not texture or alpha edges unless alpha antialiasing is enabled on the material, and its cost is moderate. FXAA smooths everything but blurs, especially below 1440p. TAA costs more and ghosts in fast motion. — [Godot docs: 3D antialiasing (search summary)](https://docs.godotengine.org/en/4.5/tutorials/3d/3d_antialiasing.html)
- Pipeline compilation: changing the **MSAA level** across viewports causes stutters because only one level is tracked. Set it in project settings, render the features you use (MSAA level, shadow depth precision, motion vectors for TAA/FSR2, and so on) once early, and only change them from settings screens followed by a loading screen. — [Godot 4.7 docs: Reducing stutter from shader (pipeline) compilations](https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html)
- Godot 4.4: shortening dynamic shadow range with shadowmasks "provides very important optimization, especially for mobile applications". 4.4 also added automatic fallback to Compatibility when a device lacks Vulkan, and Swappy frame pacing on Android, which "works automatically after upgrading". — [Godot 4.4 release page](https://godotengine.org/releases/4.4/)
- MultiMesh has per-instance interpolation controls: `reset_instance_physics_interpolation` and `set_buffer_interpolated`. — [Godot 4.7 docs: Advanced physics interpolation](https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/advanced_physics_interpolation.html)
- Draw-call budget: the only figure found, "under 100 draw calls per frame" for mid-range devices, comes from an unverified third-party site that contradicts official docs elsewhere (it calls the Mobile renderer "clustered"). Treat it as a heuristic only. — [slicker.me: Godot mobile optimization](https://slicker.me/godot/mobile-optimization.html)
- Godot 4.6 included glow optimisations for the Mobile renderer. — [Godot 4.6 first-look (mirror of Godot blog)](https://d34kmbgkaszffl.cloudfront.net/blog/godot-4-6-a-first-look-at-what-s-coming-next)
- Android has more than 12,000 device models, and GPU driver diversity is a major stability issue. Foundation contractors fixed Vulkan API usage and added workarounds for broken drivers, which cut two shipped games' crash rates from about 4% to under 1%. — [Godot blog: Mobile update April 2026](https://godotengine.org/article/godot-mobile-update-apr-2026/)

### Inferences (recommended rendering recipe; verify each on the test phone with the `shot` skill and Perfetto)
- **Resolution:** portrait 1080x2400 phones push about 2.6 MP. Use `rendering/scaling_3d/scale` of about 0.75-0.8 (bilinear, or FSR1 if it measures cheap) with the UI at native resolution. Fragment cost is the main mobile bottleneck, per the Arm finding.
- **AA:** start with MSAA 2x set once in project settings (geometry edges like tree silhouettes, pin and horizon), no TAA. With the 4.4+ load/store fix MSAA resolve stays on-tile. If the GPU-bound frame is over budget, switch to FXAA. Any toggle belongs in the settings screen plus a reload, never mid-play.
- **Terrain shader (one material for the whole hole):**
  - Sample the R8 surface texture (nearest) and blend per-surface colour plus a tiling detail noise texture (one ASTC-compressed texture, in a Texture2DArray or atlas).
  - **Mowing stripes:** compute `stripe = step(0.5, fract(dot(world_xz, mow_dir)/stripe_width))` and modulate fairway brightness ±6-10%. Greens use a finer stripe or checker. This costs no geometry.
  - **Fringe:** a smoothstep on distance to the green edge (bake a distance field channel into the surface texture).
  - Fake grass "fuzz" via a noise-driven normal or brightness. No real grass blades except perhaps a small MultiMesh tuft ring around the tee and green, behind a quality setting.
  - Unshaded or vertex-lit is an option for the far field. Toon-ish albedo with a single directional light matches the keyframe style better than PBR detail.
- **Slope-grid overlay (green read):** a second pass, or a uniform-toggled branch in the green shader. Draw lines at a fixed world xz spacing (0.5 m) displaced onto the surface, and colour or animate dots flowing along the fall line using the gradient. Bake the gradient into an RG texture from HoleData so the shader doesn't derive it from screen-space derivatives, which alias on mobile. Only enable it in green-read mode.
- **Trees:** 2-3 low-poly tree meshes (150-400 tris each) in one MultiMeshInstance3D per mesh type per hole, giving 2-6 draw calls for hundreds of trees. Use a `visibility_range` on a billboard or imposter MultiMesh for distant rows if counts get large. Static trees should have physics interpolation off.
- **Sky and fog:** ProceduralSkyMaterial (or a gradient sky shader) with radiance size small or "update once", plus distance fog that hides the far edge of the hole. Avoid volumetric fog (Forward+ only) and SSAO/SSR/SSIL, which need normal-roughness buffers and extra passes the pipeline docs list as features that must be pre-detected.
- **Shadows:**
  - Option A (cheapest): no shadow maps. Use a blob shadow under the ball, a quad or Decal projected to the terrain height from HoleData, which also helps depth perception in flight. Tree shadows can be baked into terrain vertex colour or the surface texture at hole-build time.
  - Option B: one DirectionalLight3D with shadows, 1-2 PSSM splits, `max_distance` of about 40-60 m around the camera, and a 2048 atlas.
  - Start with A and add B as a "high" quality tier.
- **Ball trail:** a ring buffer of the last N (for example 48) interpolated ball positions sampled in `_process`, rendered as a camera-facing ribbon. Two implementation choices:
  1. A preallocated ArrayMesh or ImmediateMesh rebuilt in `_process`. That's acceptable since the allocation rule targets `_physics_process`, but ImmediateMesh rebuilds still allocate driver buffers each frame.
  2. Better: a fixed-topology strip mesh whose vertices are positioned in the vertex shader from a small float texture or uniform array of points, giving zero CPU mesh rebuilds.

  Use an unshaded additive or alpha material with fade by age.
- **Water:** unshaded or simple-lit plane, scrolling normal or UV noise, vertex-colour shoreline fade baked from HoleData distance. Do not use `hint_screen_texture` or `hint_depth_texture` (refraction or depth fade). Those force extra copies and leave the tile, which is the class of cost the Arm blog identified.
- **Budget targets for a mid-range Adreno 6xx/7xx or Mali-G57/G68 at 60 fps (my working targets, not sourced):**
  - At most about 100 draw calls
  - At most about 150-250k visible triangles
  - 1 directional light
  - 0-1 shadow map
  - No post-processing except tonemap and maybe cheap glow
  - Total frame budget 16.6 ms, with the GPU under about 10 ms at 0.75-0.8 render scale

  Profile with Perfetto (the default in 4.7) and Arm Performance Studio or Snapdragon Profiler.
- **Renderer fallback:** keep Mobile as primary. 4.4+ auto-falls back to Compatibility on non-Vulkan devices, so every custom shader must compile under GLES3. Avoid Texture2DArray for albedo if you want the fallback to look right (the same limitation Terrain3D hits), or accept degraded visuals on that tier.

### Gaps
- No authoritative, Godot-specific draw-call or triangle budgets for Mali-G57/G68 or Snapdragon 6/7-series. The only numeric guide found is unverified.
- No sources specific to blob shadows or decals on the Mobile renderer, or to ImmediateMesh cost on mobile.
- Didn't fetch the full Godot AA doc page directly; the AA facts come from a search summary of the official docs.

## 4. Camera: smooth follow, interpolation, terrain collision, transitions, portrait FOV

### Takeaway
Run the camera rig in `_process` with its own physics interpolation turned **off** and `top_level = true`, following the ball's `get_global_transform_interpolated()`. That's the pattern Godot's 4.7 docs prescribe for cameras. Keep the camera above terrain by sampling the HoleData heightfield rather than using SpringArm3D, which needs physics colliders the terrain may not have. Use frame-rate-independent exponential damping and scripted Tweens between the aim, flight, landing and green-read cameras.

### Cited Findings
- Cameras: manual handling usually gives smoother results than automatic interpolation. Move the camera in `_process()` following an interpolated target, and keep it in global space (own branch or `top_level = true`) to avoid feedback with a moving parent. — [Godot 4.7 docs: Advanced physics interpolation](https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/advanced_physics_interpolation.html)
- `get_global_transform_interpolated()` returns where the target will be rendered when called in `_process()`. Using `get_global_transform()` makes the camera jump each physics tick. Use it sparingly (cameras), and keep gameplay logic on the physics transform in `_physics_process`. The docs' example camera sets its own `physics_interpolation_mode` to OFF in `_ready()` and smooths toward the target in `_process` using `min(delta, 1.0)`. — [Godot 4.7 docs: Advanced physics interpolation](https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/advanced_physics_interpolation.html)
- `physics_interpolation_mode` is inherited by children. A child set to Off still moves with an interpolated parent, because only its local transform is uninterpolated. — [Godot 4.7 docs: Advanced physics interpolation](https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/advanced_physics_interpolation.html)
- Godot 4.4 added 3D physics interpolation, noting mobile games can lower their tick rate without losing smoothness. — [Godot 4.4 release page](https://godotengine.org/releases/4.4/)
- Project rule: nodes moved in `_process` need interpolation OFF, or teleports and first frames smear (seen on device 2026-11-11). — CLAUDE.md (local)

### Inferences
- **Rig layout:** `GolfCamera` (Node3D, top_level, interpolation OFF) containing a Camera3D, driven by a small state machine: AIM → LAUNCH_FOLLOW → LANDING → ROLL_FOLLOW → GREEN_READ → CUP_CELEBRATE.
  - Each state computes a desired (position, look_target, fov).
  - The rig damps toward it with `t = 1.0 - exp(-k * delta)`, which is frame-rate independent unlike `lerp(a, b, k)`. Use k of about 6-10 for position and higher for the look target.
- **Aim camera:** behind the ball along the aim line, about 2.5-3.5 m back and 1.2-1.6 m up, pitched down so the ball sits in the lower third of the portrait screen and the target line runs up the screen. Portrait is well suited to golf, since the shot travels "up" the tall axis.
- **Launch follow:** lag-follow the interpolated ball with a look-ahead. Partway through flight, blend the look target toward the predicted landing point. The solver can predict the landing point by running the flight-only phase ahead at shot start, a cheap deterministic preview that also enables the landing-zone marker.
- **Terrain clearance:** after computing the desired camera position, clamp `cam.y >= HoleData.height_at(cam.x, cam.z) + 1.0`. Also sample 2-3 points along the camera-to-ball segment and raise the camera if any is occluded by terrain. Trees can be ignored, or faded via a shader distance check. No SpringArm3D is needed. SpringArm3D relies on physics shape casts, which would require collision on the terrain mesh.
- **Teleports:** on hole change or a cut to a new state, call `reset_physics_interpolation()` on any interpolated node that jumped, and snap the camera's damped state.
- **Portrait FOV:** Camera3D's default `keep_aspect` is KEEP_HEIGHT, so `fov` is vertical and portrait screens get a very narrow horizontal view. For portrait golf, set `keep_aspect = KEEP_WIDTH` and choose a horizontal FOV of about 55-65° (aim) and 45-55° (flight follow), or keep KEEP_HEIGHT with a vertical FOV of about 70-80°. Verify the property semantics in the Camera3D class reference before relying on this. Test on both 19.5:9 and 20:9 phones, and on a 4:3 tablet as a sanity check.
- **Cinematics:** use Tween on the rig's target and fov rather than AnimationPlayer, so shots stay data-driven. Never let a cinematic move the ball; it is a view-only layer.

### Gaps
- No Godot-specific community write-ups on golf camera design were found. The camera framing numbers above are my starting values, to be tuned against docs/refs/golf/keyframe_*.png.
- Didn't fetch the Camera3D class reference to confirm `keep_aspect` default and semantics in 4.7.

## 5. Content pipeline: authoring 9 holes, hole data as resources, seeded generation

### Takeaway
Store each hole as a `HoleData` Resource (.tres or .res) with heights, surface grid, tee/pin/hazard and tree data. Generate meshes and MultiMeshes at load. Author either with an editor tool (Path3D splines for fairway centrelines and green outlines, rasterised into the grids, plus hand-sculpted bumps) or from modular tiles baked to the grid. Seeded procedural variation must use core/Rng, never `randf()`.

### Cited Findings
- No open-source Godot 4 golf project with a heightmap content pipeline was found. The closest are OpenFairWay (physics only, with `SurfaceZone` areas overriding surface type locally, for example tall grass or cart paths) and plink (a top-down minigolf game on Godot 4.7 with a Rust GDExtension and courses in code). — [github.com/digitalhand/openfairway](https://github.com/digitalhand/openfairway); [github.com/fisherrjd/plink](https://github.com/fisherrjd/plink)
- Pipeline precompilation only happens when the RenderingServer sees a shader, mesh or feature at load time. Something first loaded mid-game compiles when it appears, and mesh loads mid-game can stutter unless done on a background thread. — [Godot 4.7 docs: Reducing stutter from shader (pipeline) compilations](https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html)
- The project rule says unfinished games stay behind `enabled=false` in manifest.tres (golf currently has `enabled = false`, `scene = ""`), and save data changes require a schema bump plus migrate(). — CLAUDE.md, games/golf/manifest.tres (local)

### Inferences
- **Authoring tool (EditorScript or `@tool` scene) per hole:**
  - A `Path3D` for the fairway centreline, with width curves sampled along it.
  - Closed `Path3D`s or polygons for the green, bunkers and water.
  - Tee and pin markers.
  - A low-frequency height base (a few hand-placed "hill" Gaussians, or a painted 16-bit PNG).
  - A **Bake** button rasterises everything into `heights` and `surface`, writes the green slope texture, computes distance fields for fringe and shoreline, scatters trees with a seeded Rng outside the fairway, and saves `holes/hole_01.tres`.
  - The runtime never touches Path3D, so it stays fast and deterministic.
- **Blender route:** sculpt the terrain in Blender, export a 16-bit heightmap PNG and a surface-ID PNG, then import them in the bake tool. Don't import a glTF terrain mesh as the gameplay surface, because the solver needs the grid.
- **Modular tiles:** tiles could be authored as small HoleData fragments (for example 20x20 m tee box, fairway straight, dogleg, green A/B/C) and stitched at bake time. This matches golf.md's "modular tiles" while keeping one grid at runtime. Seeded variation (pin position, tree scatter, wind) can be picked per round from core/Rng with the seed stored in the save.
- **Loading:** build each hole's meshes and MultiMeshes during a loading or transition screen, render one frame with all materials visible (terrain, water, trail, ball, flag, slope-grid overlay) behind the transition so pipelines are created up front, then reveal. Keep all 9 HoleData resources small (about 100-300 kB each) and load the next one on a background thread while the current hole's score card shows.
- **Tests (pure logic):** HoleData sampling (height and normal at known points), a swept-ground test (a 70 m/s ball never ends below the terrain), carry per club within ±3%, rest-on-slope, and a cup capture or lip-out table. A golden-shot hash shared between desktop and phone, like cue_bench.

### Gaps
- No community reports were found on Godot golf-course authoring workflows (Path3D-to-terrain rasterisers, Blender heightmap round-trips), so the pipeline above is a design proposal.
- No data on load times for generating chunked ArrayMeshes from about 20-80k-sample grids on Android. This needs measuring.

## 6. Known pitfalls and community tips (Godot 4.4-4.7 specifics)

### Takeaway
The big Godot-version pitfalls for this game are shader and pipeline stutter (largely solved on Mobile by 4.4 ubershaders plus the 4.5 shader baker, with caveats), MSAA or feature toggles mid-game, physics-interpolation smearing on teleports, and Android driver diversity. One project-specific catch: the shader baker does **not** run for `--headless` exports, and the project's documented export command is headless.

### Cited Findings
- Ubershaders and pipeline precompilation (4.4+) apply only to Forward+ and Mobile. Compatibility must use the legacy approach of showing every material for at least one frame during loading. — [Godot 4.7 docs: pipeline compilations](https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html)
- Compilations in the "Draw" monitor category should never happen with ubershaders (report them as bugs). "Surface" spikes mean a feature wasn't enabled ahead of time. "Specialization" is background work that can lower framerate if many happen per frame. 2D/Canvas shaders are not precompiled. — [Godot 4.7 docs: pipeline compilations](https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html)
- **Shader baker (4.5+):** enable per export preset (Shader Baker > Enabled). It bundles compiled intermediate shaders (SPIR-V on Android) into the PCK, mainly shortening first-launch time. It costs a few MB and longer exports, and doesn't replace pipeline precompilation, since final pipelines are driver-specific. Android is Vulkan only. It is **not supported** for Compatibility, the Compatibility fallback, web, **or exports run with `--headless`**. — [Godot 4.7 docs: pipeline compilations](https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html); [Godot 4.5 release page](https://godotengine.org/releases/4.5)
- Mid-game effects (for example particles spawned by script) should have a hidden instance present from load so their pipelines precompile. — [Godot 4.7 docs: pipeline compilations](https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html)
- `get_global_transform_interpolated()` should be used sparingly (cameras), not throughout gameplay code, for performance and correctness reasons. — [Godot 4.7 docs: Advanced physics interpolation](https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/advanced_physics_interpolation.html)
- Jolt-specific: project settings moved from `physics/jolt_3d` to `physics/jolt_physics_3d`. The joint nodes from the old extension aren't in the built-in module. "Run on separate thread" is experimental. — [Godot 4.7 docs: Using Jolt Physics](https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html)
- Android tooling: native debug symbols (4.5), instrumented on-device tests and device mirroring in the editor (4.6), and Perfetto tracing. — [Godot blog: Mobile update April 2026](https://godotengine.org/article/godot-mobile-update-apr-2026/); [Godot 4.7 release page](https://godotengine.org/releases/4.7/)
- Swappy frame pacing is automatic on Android since 4.4. — [Godot 4.4 release page](https://godotengine.org/releases/4.4/)
- Other Godot-golf write-ups found but not deeply reviewed: a "Battle for Ball Physics" devlog (itch.io) and the Packt *Godot 4 Game Development Projects* minigolf chapter, which uses RigidBody3D (fine for minigolf, not for a deterministic full-golf solver). — [offgridgecko devlog](https://offgridgecko.itch.io/bink/devlog/577117/the-battle-for-ball-physics); [Packt minigolf chapter](https://packtpub.com/en-at/product/godot-4-game-development-projects-9781804610404/chapter/chapter-5-3d-minigolf-dive-into-3d-by-building-a-minigolf-course-5/section/making-the-ball-ch05lvl1sec51)

### Inferences
- **Export command:** CLAUDE.md's `godot --headless --export-release "Android" build/app.aab` will silently skip the shader baker per the 4.7 docs. Either export release builds non-headless (with xvfb-run on Linux CI), or accept slower first launch. Measure first-launch time on the test phone both ways.
- **Ball interpolation:** set the ball transform in `_physics_process` only, so interpolation stays ON for the ball. Turn interpolation OFF for the camera rig, the trail, the aim arrow and the UI-attached 3D markers, all of which are updated in `_process`. Call `reset_physics_interpolation()` after every reposition (new lie, drop, next hole).
- **Physics tick:** keep `physics_ticks_per_second=60` project-wide and run 4 solver substeps per tick for 240 Hz. Don't raise the global tick rate for golf, since that would also run Jolt for other nodes and cost CPU. Don't scale anything by render delta (project rule).
- **No per-frame allocations:** in the solver, avoid creating Vector3s and Arrays per substep, using scalar members as cue_sim does. In the renderer, preallocate trail buffers and MultiMesh buffers.
- **Determinism tests:** a golden-shot hash on desktop vs phone in CI and in the `--bench=golf` path. Replace `pow` and `exp` in the hot loop with tables or polynomials to avoid libm drift (see section 2).
- **Low-end floor (30 fps):** quality tiers should drop render scale to about 0.6, disable MSAA and the shadow map, reduce tree density and disable the trail's soft fade. The solver cost is unaffected because it is fixed-step and independent of render rate.

### Gaps
- No public, measured reports of shader-baker first-launch savings on Android specifically. The docs say the benefit is largest on D3D12 and Metal.
- No Godot forum or Reddit threads specific to golf-on-mobile performance were found within this research budget.
