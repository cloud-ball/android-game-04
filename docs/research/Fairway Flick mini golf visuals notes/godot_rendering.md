# Godot 4.4-4.7 Mobile renderer: stylised 3D visuals at 60 fps on mid-range Android (portrait)

Context for the writer: the target scene has about 60 draw calls and GPU time of about 10.6 ms at 1080x2400 on an Adreno 642L. It uses one shadowed DirectionalLight3D, glow on and MSAA off. The 60 fps budget is 16.6 ms, so about 6 ms of GPU headroom remains. The device must also hold that rate under thermal throttling, which these sources do not quantify.

Mobile renderer feature matrix (official docs, 4.7 "stable"). This is the baseline for every section below:

| Feature | Mobile | Notes |
|---|---|---|
| SSAO / SSIL / SSR / SDFGI / VoxelGI / volumetric fog | Not supported | |
| LightmapGI | Supported | |
| ReflectionProbe | Supported, 8 per mesh | |
| Glow | Supported | |
| MSAA | Supported | |
| FXAA | Supported | |
| SMAA 1x | Supported | added in 4.5 |
| TAA / FSR2 | Not supported | |
| Omni/Spot lights | 8 per mesh, 256 per view | |
| Directional lights | 8 | |
| Directional PCSS | Not supported | |
| Decals | Supported | |
| Screen texture / depth texture | Supported | |
| Normal/roughness buffer | Not supported | |
| Tonemapping + adjustments | Supported | |
| Color buffer | RGB10A2 | RGBA16F if HDR 2D is on |
| Depth | 24-bit, reverse Z | |

Source: [Godot docs: Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)

---

## 1. Lighting: LightmapGI vs dynamic directional shadows, fake AO, probes on Mobile

### Takeaway
LightmapGI is fully supported on Mobile and is the cheapest way to get soft shadows, bounce light and AO on static course geometry. Two hybrids keep a real-time shadow for the moving ball. The first is a Static/"Dynamic" bake-mode split. The second, cleaner one is the shadowmask mode (Replace or Overlay), which keeps a short-distance real-time directional shadow. SSAO is not available on Mobile, so AO has to be baked: into lightmaps, AO textures or vertex colours, or faked with a decal or blob under the ball. Reflection probes work on Mobile (8 per mesh), and 4.6 made them cheaper by switching to octahedral maps.

### Cited Findings
**LightmapGI**
- The docs say baked lightmaps "work fine on low-end PCs and mobile devices" because they use almost no runtime resources. — [Godot docs: Using LightmapGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html)
- Light bake modes [same source]:
  - **Static** bakes both direct and indirect light. It gives "the best performance" and shadows that don't fade with distance, but the light can't change at runtime, and dynamic objects won't cast real-time shadows onto baked surfaces.
  - **Dynamic** (the default) bakes only indirect light. Direct light and shadows stay real-time.
  - **Disabled** makes the baker ignore the light.
- Shadowmask needs one DirectionalLight3D in Dynamic GI mode [same source]:
  - **Replace** gives real-time shadows within Shadow Max Distance and baked shadows beyond it.
  - **Overlay** keeps baked shadows everywhere and overlays real-time shadows nearby. It "can smear depending on texel density."
  - You can switch modes without rebaking.
- Directional lightmaps improve normal-mapped surfaces but are "more expensive to render," bake longer and produce larger files. — [same source](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html)
- Dynamic objects (such as the ball) get indirect light from light probes, not lightmaps. Probes are generated automatically (Gen Probes > Subdiv, default 8) or placed by hand with LightmapProbe nodes. — [same source]
- Lightmaps reserve UV2 and provide no reflections, so a ReflectionProbe or Sky is still needed. Texel Size defaults to 0.2; lower values give more detail and bigger files. At most 8 LightmapGI nodes render at once. — [same source]
- Denoisers: JNLM is built in (GPU compute). OIDN preserves more shadow detail but must be downloaded separately. Supersampling reduces noise and leaking. — [same source]
- 4.5 made lightmap baking and UV unwrapping possible on phones and tablets (editor-side only). — [Godot 4.5 release](https://godotengine.org/releases/4.5/)

**Dynamic DirectionalLight3D shadows**
- PSSM 4 splits is the default. An object spanning all 4 splits is drawn 5 times (4 shadow passes plus the main pass). 2-split and orthogonal modes are also available. — [Godot docs: 3D lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- "A lower value [of Max Distance] improves both shadow quality and performance." Blend Splits costs extra detail and performance. Tuning the first split adds detail near the camera. — [same source]
- Filter quality options are Soft Very Low, Soft Low (default), Soft Medium, Soft High and Soft Ultra. Shadow depth is 16-bit by default; 32-bit costs performance. Directional lights share one atlas. The doc gives no sample counts or mobile-specific numbers. — [same source]
- Changing 16/32-bit shadow precision at runtime causes pipeline-compile stutter. — [Godot docs: Reducing stutter from shader (pipeline) compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
- The Godot GPU optimisation page: "Post-processing and shadows add fragment cost... Always test." Shrink shadow maps and disable shadows on small or distant lights. — [Godot docs: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- A community XR forum post (Godot 4.3 era, anecdotal, unmeasured) advises avoiding shadows on mobile because they are "very expensive." — [Godot Forum: Performance considerations for standalone XR](https://forum.godotengine.org/t/performance-considerations-for-stand-alone-xr/52324)

**AO without SSAO**
- SSAO is unavailable on Mobile. — [Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
  - Note: the Environment page now says SSAO is "only available when using the Forward+ and Compatibility renderers, not Mobile." It may have been added to Compatibility recently. Either way, Mobile is excluded. — [Godot docs: Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)
- StandardMaterial3D's AO map affects ambient light only, not direct light, by default. The docs say "nothing beats the quality of a well-baked AO map" compared with SSAO. — [Godot docs: StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- Vertex colour can drive albedo ("Use as Albedo", with an "Is sRGB" toggle). This is the hook for vertex-colour AO multiplied into albedo, or read in a custom shader via `COLOR`. — [same source]
- 4.5 added a cheap "specular occlusion from ambient light" option (project setting), with comparison shots on Mobile. It reduces reflections in occluded crevices. No performance data was given. — [Godot 4.5 release](https://godotengine.org/releases/4.5/)
- Decals are supported on Mobile, so a ball contact-shadow blob can be a Decal with a soft radial texture. — [Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)

**ReflectionProbe on Mobile**
- Mobile allows "only 8 reflection probes ... on each individual Mesh resource" (Compatibility allows 2). — [Godot docs: Reflection probes](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/reflection_probes.html)
- Update mode **Once** (default) is "much faster" than **Always**. Avoid Enable Shadows on Always probes. Box projection has "a small performance cost." Ambient Mode can be Disabled, Environment or Constant Color. — [same source]
- Changing reflection-probe usage at runtime triggers pipeline compiles (stutter). Keep the probe present from scene load. — [Godot docs: pipeline compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
- 4.6 switched reflection and radiance probes to octahedral maps instead of cubemaps, "cheaper for the GPU to compute and lighter on memory," and more reliable across hardware. — [Godot 4.6 release](https://godotengine.org/releases/4.6/)

### Inferences
- A mini-golf course is almost entirely static. The best mix is a LightmapGI bake (indirect light plus baked AO from the bake) with the sun in Dynamic bake mode, kept for the ball's shadow:
  - Use shadowmask **Replace** with a very small Shadow Max Distance, covering only the visible hole.
  - Use **PSSM 2 splits or Orthogonal** instead of the default 4 splits. Per the docs' "drawn 5 times" note, this cuts shadow-pass draws.
  - Use Soft Very Low or Soft Low filtering.
  - Alternative: bake the sun as Static and give the ball a Decal or blob shadow. This drops the real-time shadow pass entirely and is probably the single biggest shadow saving.
- Portrait framing with a high, steady camera means the visible area is small and bounded, so a short directional Max Distance (about the hole's length) gives sharp shadows cheaply.
- Lightmaps plus vertex-colour AO cost almost nothing at runtime. They suit flat-coloured stylised assets better than texture AO maps, since there are no extra texture reads.
- Use one ReflectionProbe set to Update Once, with low intensity, for the ball's specular highlight and any glossy rails. Otherwise rely on the Sky for reflections.

### Gaps
- I found no measured ms cost for DirectionalLight3D shadows (per cascade, per filter quality) on Adreno 6xx or Mali-G57/G68 in Godot 4.x. The only figures are anecdotal.
- I found no documented runtime cost of LightmapGI sampling on Mobile beyond "almost no runtime resources." I also found no documentation of the bicubic lightmap sampling setting's mobile default.
- I did not verify whether ReflectionProbe "Once" probes are re-rendered when the octahedral path is used on Mobile.

---

## 2. Stylised shading in Godot shaders (toon/ramp, rim, half-Lambert, outlines, ball spec, felt, wood, water, grass)

### Takeaway
StandardMaterial3D already gives most stylised looks without custom shaders:
- Toon diffuse and Toon specular modes
- Lambert Wrap (half-Lambert-like)
- Rim with tint
- Per-Vertex shading ("can considerably increase rendering performance" on mobile)
- Grow-plus-Cull-Front next pass for inverted-hull outlines

Post-process outlines that read the depth or normal buffer are a poor fit for Mobile: there is no normal/roughness buffer, and depth reads cost bandwidth. Use inverted-hull or Grow outlines on hero objects only. Stylised water foam should avoid the depth texture and use procedural or vertex-colour edges. Grass should be shader-only on the green, or MultiMesh cards with alpha scissor at the edges, never alpha blend.

### Cited Findings
**Built-in material shading**
- Diffuse modes [Godot docs: StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html):
  - Burley is the default.
  - Lambert ignores roughness.
  - Lambert Wrap extends light past 90 degrees as roughness rises. The doc says it "works great for hair and simulating cheap subsurface scattering," which is effectively half-Lambert.
  - Toon gives a hard lighting cut, smoothed by roughness.
- Specular modes are SchlickGGX, Toon (a stylised blob sized by roughness) and Disabled. — [same source]
- Rim "actually takes light into account (no light means no rim)." Rim size follows roughness. Tint 0 uses the light colour, tint 1 the albedo; intermediate values "generally work best." — [same source]
- Per-Vertex shading: "On low-end or mobile devices, using per-vertex lighting can considerably increase rendering performance." Unshaded is the cheapest mode. — [same source]
- Custom spatial shaders can use `render_mode diffuse_toon, specular_toon` or a custom `light()` function for ramp lookups. The docs do not detail this; see Gaps.

**Outlines**
- Grow outline: add a next-pass material that is black, unshaded, Cull Front, with Grow. It is "commonly used to create cheap outlines" and needs smooth normals, since flat shading leaves gaps. — [same source](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- 4.5 added a Stencil "Outline" mode. Stencil-writing materials "are always drawn in the transparent pass," with the transparency limitations that implies. — [same source]
- Community: the inverted-hull material shader "works in mobile rendering" (commenter on godotshaders). — [godotshaders: The simplest outline shader (via material)](https://godotshaders.com/shader/the-simplest-outline-shader-via-material/)
- Post-process depth/normal outlines exist. — [godotshaders: Post-Process Outline (Depth/Normal)](https://godotshaders.com/?p=5028) and [High Quality Post Process Outline](https://godotshaders.com/?p=5145)
  - Mobile has no normal/roughness buffer, so normal-based edge detection can't use it. — [Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- An unanswered Godot 4.6 forum thread asks whether stencil outlines are efficient on mobile GPUs. I found no benchmark. — [Godot Forum: Stencil outline on mobile](https://forum.godotengine.org/t/how-does-stencil-outline-work-and-is-it-efficient-on-mobile-gpus/133096)

**Transparency (matters for grass, water, foam, UI-in-world)**
- Alpha blending is "significantly slower to render, especially if they overlap," and can't cast shadows. Alpha Scissor is faster, has no sorting issues and can cast shadows. Alpha Hash dithers. — [Godot docs: StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- Distance or proximity fade in Pixel Alpha mode forces the transparent pipeline. Object Dither is "even faster than Pixel Dither." — [same source]
- "Transparency is particularly expensive where multiple transparent objects overlap... Sometimes more complex opaque geometry runs faster than transparency." Also: "most Android devices do not support texture compression of textures with transparency." — [Godot docs: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)

**Water**
- Most Godot 4 "toon water" shaders, including one titled "No textures needed," still sample the depth texture for foam. — [godotshaders: Toon Style 3D Water](https://godotshaders.com/shader/toon-style-3d-water-shader-no-textures-needed/)
- Depth-based foam broke for some users in 4.3 because of the reverse-Z change. — [godotshaders: Stylized Water for Godot 4.x](https://godotshaders.com/shader/stylized-water-for-godot-4-x)
- A procedural, textureless water shader (foam generated procedurally, based on a Shadertoy design) avoids image textures. — [godotshaders: Wind-Waker-style water, no textures](https://godotshaders.com/shader/wind-waker-water-no-textures-needed/)
- The depth texture is available on Mobile. — [Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)

**Grass**
- MultiMesh "allow[s] many thousands of objects to be drawn at very little performance cost," ideal for grass. Automatic instancing is Forward+ only, not Mobile. Alpha-blended or depth-prepass materials are never auto-instanced. — [Godot docs: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- "Don't worry about vertex count on mobile," but avoid many vertices concentrated in a small screen area, which is bad for tilers. — [Godot docs: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)

### Inferences (implementable recipes, not sourced benchmarks)
These are synthesised from the documented features above. Validate each on the device.
- **Toon/ramp ground and props:**
  - Option A: StandardMaterial3D with Diffuse = Toon, Specular = Toon or Disabled, Rim about 0.3, rim tint 0.5.
  - Option B: a custom `light()` that computes `NdotL*0.5+0.5` (half-Lambert) and steps or samples a tiny 1D ramp texture (one texture read).
  - Hemispheric ambient: in a custom shader, mix sky and ground colours by `NORMAL.y` in world space. This is cheaper than relying on sky radiance and gives the "gradient sky" bounce look.
- **Gradient sky:** a ProceduralSkyMaterial or a 3-colour custom sky shader. Keep radiance size small, since it drives ambient and reflections.
- **Ball:**
  - Use a high-poly smooth sphere. Toon specular gives a crisp stylised highlight; SchlickGGX with low roughness plus a ReflectionProbe gives a glossy one.
  - Add Rim for silhouette pop against the green.
  - Use an inverted-hull outline only on the ball and the cup flag (a few hundred extra triangles, no fullscreen pass).
- **Felt/carpet green:**
  - Base: Lambert or Toon diffuse, Specular Disabled, high roughness.
  - Add Rim (light-aware) for the fuzzy fibre sheen at grazing angles.
  - Add low-amplitude world-space noise (procedural, or one tiling noise texture) in albedo for "nap."
  - No grass geometry on the putting surface.
- **Wood rails:** procedural grain in the fragment shader, e.g. sin of distance along a local axis perturbed by noise. Or one small tiling texture. Either costs a few ALU ops and fits within mobile fragment budgets, given the docs' "simplest possible shaders" advice.
- **Water hazards:** vertex sine waves in `vertex()`, plus foam from an authored vertex-colour mask or a UV2 distance field baked into the mesh at shorelines. This avoids `hint_depth_texture` and the reverse-Z pitfalls. Keep water opaque, or a single non-overlapping transparent layer.
- **Rough or decorative grass off the green:** MultiMesh low-poly opaque blades, or cards with Alpha Scissor (not Alpha), with wind sway in `vertex()`. Or a shader-only fake (darker tinted noise and vertex-colour variation on the ground mesh). Shells (N stacked transparent layers) multiply overdraw on a tiler, which conflicts with the documented transparency guidance. Avoid them.

### Gaps
- I found no measured ms cost of inverted-hull vs post-process vs stencil outlines on Godot Mobile and Android.
- I found no Godot-specific benchmark for shell grass on Android.
- I did not fetch Godot shading-language docs for the `light()` and `render_mode` toon specifics, so cite those separately if needed.

---

## 3. Post-processing on the Mobile renderer (glow, tonemapping, LUT, vignette, AA, render scale)

### Takeaway
On Mobile, all of these work: glow, all tonemappers (Linear, Reinhard, Filmic, ACES, AgX), brightness/contrast/saturation, and 1D/3D LUT colour correction. Glow was a severe performance problem before 4.6; 4.6 rewrote it to be 2-3.5x faster on phones. For AA:
- FXAA is the documented safe choice.
- SMAA 1x (4.5+) is slightly slower and sharper.
- 2x MSAA is "usable in some circumstances."
- TAA and FSR2 are unavailable.
- The docs list FSR1 as Forward+ only, so Mobile render scaling is bilinear.

A vignette is best folded into a custom shader rather than adding a fullscreen pass.

### Cited Findings
**Glow**
- Before 4.6, Mobile glow used fragment shaders instead of compute (because of weak mobile compute). — [GitHub issue #98531](https://github.com/godotengine/godot/issues/98531)
  - Measured on a Samsung A35 (Mali-G68 MP5) running 4.4.dev3: about 120 fps without glow vs about 37 fps with glow. Compatibility ran at about 120 fps with glow.
- Visibility fixes landed in PR #109994 (Aug 2025). The performance rewrite, [PR #110077](https://github.com/godotengine/godot/pull/110077), was merged for 4.6.
  - Technique: a single-pass downsample with an optimised kernel, then upsample-and-accumulate. The gather happens at low resolution, so the tonemap reads 1 sample instead of up to 7. Level 1 is now quarter resolution. Levels with strength 0 are skipped. A Mobile-specific tonemap shader uses specialisation constants.
  - Measured with default settings:

| Device | Resolution | Glow (before → after) | Tonemap (before → after) | Total speedup |
|---|---|---|---|---|
| Adreno 640 | 1080x2280 | 2.6 → 1.35 ms | 7.4 → 1.5 ms | 3.5x |
| Mali-G710 | 1080x2400 | 3.8 → 1.75 ms | 3.5 → 1.6 ms | 2.2x |
| Adreno 530 | 1080x1920 | 3.5 → 1.15 ms | 6.0 → 2.3 ms | 2.75x |

  - Side effect: level 1 now shows jaggies, especially with HDR 2D. The PR changed `glow_hdr_threshold`'s default to 0.0, which was later reverted to 1.0. — [PR #110077](https://github.com/godotengine/godot/pull/110077)
- 4.6: glow now blends before tonemapping, with Screen as the default blend mode, "with at least similar or outright better performance." — [Godot 4.6 release](https://godotengine.org/releases/4.6/)
- Glow Upscale Mode applies to Forward+ and Mobile. Mobile defaults to bilinear, not bicubic. — [Godot docs: Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)

**Tonemapping and colour**
- Linear, Reinhard, Filmic, ACES and AgX are listed with no renderer restriction.
  - Exception: with AgX on Mobile and HDR 2D disabled, the White value is ignored and forced to 2.0. — [Godot docs: Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)
- 4.6 exposes `agx_white` and `agx_contrast` as tunables. — [Godot 4.6 release](https://godotengine.org/releases/4.6/)
- Adjustments (brightness, contrast, saturation, 1D gradient colour correction, 3D LUT) have no renderer callout and run after tonemapping. Fog (depth, height, sun scatter) has no Mobile callout; it can band at high density. — [Godot docs: Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)
- Reflected Light = Disabled is suggested "to maximize performance on low-end devices." — [same source]
- Banding (4.6): material debanding is now available in 3D through the debanding project setting. HDR 2D keeps higher precision through the 3D pipeline. — [Godot 4.6 release](https://godotengine.org/releases/4.6/)
  - The Mobile colour buffer is RGB10A2 ("low precision") unless HDR 2D is on (RGBA16F). — [Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)

**Anti-aliasing** — [Godot docs: 3D antialiasing](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html)
- MSAA: medium cost. "2x MSAA may be usable in some circumstances, but higher MSAA levels are unlikely to run smoothly on mobile GPUs."
- FXAA: "faster to run than any other antialiasing technique"; "When targeting low-end platforms such as mobile... FXAA is usually the only viable option."
- SMAA 1x: supported on Mobile, "slightly slower than FXAA, but produces less blurriness."
- TAA and FSR2: Forward+ only.
- The screen-space roughness limiter (specular AA) is on by default on Mobile and "has a small performance impact," so consider disabling it if specular aliasing isn't an issue.
- Contrasting community view (anecdotal, Godot 4.3, XR): 2x MSAA is "practically free" on mobile tilers, but glow-type effects combined with MSAA can cost more than 30%. — [Godot Forum: standalone XR performance](https://forum.godotengine.org/t/performance-considerations-for-stand-alone-xr/52324)
- Arm/Vulkan guidance: MSAA on tilers is cheap only when samples stay in tile memory and are resolved on write-back.
  - A Mali-G76 Vulkan sample measured about 3% bandwidth impact with an on-tile resolve, vs about 5 GB/s extra with a separate resolve pass. — [Vulkan Samples: MSAA](https://docs.vulkan.org/samples/latest/samples/performance/msaa/README.html)
  - Storing multisampled data to DRAM is flagged as a key cost. — [Arm, Vulkanised 2025: Mobile best practices (PDF)](https://www.vulkan.org/user/pages/09.events/vulkanised-2025/T18-Pete-Harris-Arm-MobileBestPractices.pdf)
  - Post-process passes that need depth force the depth buffer to be stored instead of kept transient. — [Vulkan Samples: MSAA](https://docs.vulkan.org/samples/latest/samples/performance/msaa/README.html)
- Changing the MSAA level at runtime causes pipeline-compile stutter. — [Godot docs: pipeline compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)

**Render scale**
- Bilinear scaling works in all renderers. The resolution-scaling page lists FSR 1.0 and FSR 2.2 as "only available with the Forward+ renderer."
  - Scale applies per axis: 0.5 cuts pixels 4x. The docs call scaling "particularly important on mobile GPUs."
  - 2D and UI are not affected by `scaling_3d_scale`, so the HUD stays crisp.
  - Mipmap bias (Forward+ and Mobile) = `log2(min(scale,1)) + custom bias`, with -0.25 added for FXAA. — [Godot docs: Resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html)
- 4.7 adds nearest-neighbour 3D scaling for viewports, "roughly identical" in performance to bilinear. — [Godot 4.7 release](https://godotengine.org/releases/4.7/)
- In issue #98531 (old glow path), dropping 3D scale to 0.5 did not help glow-bound fps on a Mali-G68. — [GitHub issue #98531](https://github.com/godotengine/godot/issues/98531)

**Vignette and other fullscreen effects**
- The screen texture is available on Mobile. — [Godot docs: renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- "Tiled rendering can make certain techniques much more complicated and expensive... test shaders, viewport textures and post-processing carefully." — [Godot docs: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)

### Inferences
- On 4.6+ (including 4.7), keep glow but limit it:
  - Enable only 1-2 mid levels (for example levels 3-4). The PR skips levels at strength 0, and level 1 now aliases.
  - Keep HDR threshold at 1.0 and drive bloom from emissive accents (cup rim, flag, UI pickups).
  - Expect roughly 1.5-3 ms total (glow plus tonemap) at about 1080x2400, extrapolated from the Adreno 640 and Mali-G710 numbers. If the project was built on pre-4.6, upgrading alone may recover several ms.
- Tonemapping: AgX or Filmic for saturated stylised colours, with a 3D LUT (`adjustment_color_correction`) for the final grade. The LUT runs in the existing tonemap pass, so it is likely near-free; no measured number found. On Mobile without HDR 2D, AgX's white is fixed at 2.0.
- Vignette: avoid a separate `hint_screen_texture` fullscreen quad. A full-screen ColorRect with a radial-gradient texture and alpha in the 2D UI layer gives one blended layer and no screen-texture copy. Alternatively, bake darkening into the LUT (which can't be radial) or into ground vertex colours.
- AA on a portrait 1080x2400 screen (about 400+ ppi): FXAA or SMAA 1x for the cheapest result. 2x MSAA is worth a device A/B test because the scene has no depth-reading post-process. Avoid combining 4x MSAA with glow.
- Render scale for the 30 fps floor on low-end devices:
  - `scaling_3d_scale` 0.75-0.85 with bilinear, and FXAA off or compensated by mipmap bias.
  - The UI stays native. 0.75 renders about 56% of the pixels.
  - This is the strongest knob for fill-rate-bound phones.

### Gaps
- I found no Godot-specific measured ms cost on Adreno 6xx or Mali-G57 for MSAA 2x, FXAA, SMAA, LUT colour correction or a screen-texture vignette.
- Docs conflict, or my memory differs, on whether FSR1 runs on Mobile. The current resolution-scaling doc says Forward+ only. Verify by setting `scaling_3d_mode = FSR` on the device and checking whether it falls back to bilinear.

---

## 4. Performance numbers and best practices (shader baker, ubershaders, pipeline precompile, overdraw)

### Takeaway
Hard Godot-on-Android numbers are scarce. The best data is glow (issue #98531 and PR #110077). The main levers, in order:
1. Remove or limit real-time shadows (bake, short distance, fewer splits).
2. Keep glow on 4.6+ with few levels.
3. Avoid overlapping transparency.
4. Use FXAA or SMAA rather than MSAA 4x.
5. Use render scale on weaker devices.

Stutter, as opposed to fps, is handled by the 4.4+ ubershaders plus warm-up scenes. The 4.5+ shader baker mainly helps startup time; on Android Vulkan the gain is smaller than on D3D12 or Metal.

### Cited Findings
- The 4.5 Mobile renderer requests FP16 where supported, promising better performance, frame pacing and power use (no numbers). Motion vectors are now in Mobile. — [Godot 4.5 release](https://godotengine.org/releases/4.5/)
- 4.6 fixed crashes on "certain Mali and Adreno mobile GPUs." — [Godot 4.6 release](https://godotengine.org/releases/4.6/)
- 4.7 [Godot 4.7 release](https://godotengine.org/releases/4.7/):
  - "the Vulkan Mobile renderer matches or even outperforms our Compatibility renderer in a number of benchmarks."
  - Per-pass environment uniform buffers remove copy bottlenecks.
  - Perfetto is the default Android tracing tool.
  - AreaLight3D was added; Mobile support is not stated.
- Ubershaders (4.4+) [Godot docs: Reducing stutter from shader compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html):
  - Godot precompiles one pipeline and builds specialised variants in the background.
  - Debugger monitors show Canvas, Mesh, Surface, Draw and Specialization compilations.
  - Toggling MSAA level, reflection probes, lightmaps, 16/32-bit shadows and similar features at runtime causes "immediate stutters."
  - Recommendation: render a hidden warm-up scene with every feature at load, and attach hidden instances of runtime-spawned effects.
- Shader baker (4.5+) [same source](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html):
  - It bakes shader source to SPIR-V/DXIL/MIL in the PCK but "is not a replacement for pipeline precompilation."
  - The benefit is largest on D3D12 and Metal. It is disabled by default (export preset > Shader Baker > Enabled).
  - It adds a few MB and longer exports, and does not work with `--headless` exports.
  - From a Linux, macOS or Windows host it can export Vulkan shaders for Android.
  - The 4.5 release cites a 20x load-time reduction on the TPS demo, on Metal and D3D12. — [Godot 4.5 release](https://godotengine.org/releases/4.5/)
  - Known issue: repeated Android exports with the baker can fail; the workaround is deleting `.godot/export`. — reported in [Godot 4.5 coverage](https://blog.blips.fm/articles/godot-45-released-with-major-rendering-and-accessibility-updates) (secondary source)
- Fill rate and overdraw [Godot docs: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html):
  - On mobile, "use the simplest possible shaders you can reasonably afford."
  - Texture reads are expensive, including in power.
  - Test fill-rate limits by comparing a large window with a tiny one.
  - Variable rate shading can cut shading cost.
  - Particles: force vertex shading.
- Forward+ auto-instancing does not apply on Mobile; use MultiMesh for repeated props. Baked lighting is recommended for mobile. — [Godot docs: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)

### Inferences
- With 10.6 ms GPU now and the 4.6+ glow costing roughly 1.5-3 ms at this resolution, the remaining large cost is likely the shadow pass plus main-pass fragment shading at 2.6 MP. Measure each by toggling on the device (Perfetto or Android GPU Inspector):
  1. Shadows off
  2. Glow off
  3. `scaling_3d_scale` 0.75
- If shadows cost about 2 ms or more, the switch to lightmaps, a shadowmask or a blob shadow pays for any added visual effects.
- Enable the shader baker for Android release exports to cut first-launch compile time. Its gain on Vulkan is smaller than on D3D12/Metal. It doesn't work with `--headless` exports, which affects the CLAUDE.md headless export command. Plan to export from the editor or a non-headless CLI run.
- Decide MSAA, probe and lightmap use per game at load, never mid-round, to avoid pipeline stutter. Add a warm-up frame in the SceneRouter loading step.

### Gaps
- I found no published Godot 4.x Adreno 642L or Mali-G57 frame-time numbers for shadows, MSAA or fullscreen shaders. Only glow is measured.
- I could not confirm whether AreaLight3D works on Mobile.

---

## 5. Practical recipes from Godot demos and shipped mobile games

### Takeaway
I found no well-documented Godot shipped-mobile-game breakdowns with stylised-visual settings. The usable community material is godotshaders.com recipes (toon water, outlines) plus official docs. Treat them as starting points and port the ideas, checking each for depth-texture or screen-texture use, which costs extra on Mobile.

### Cited Findings
- Toon water (depth-based foam) and its reverse-Z breakage in 4.3. — [godotshaders: Toon Style 3D Water](https://godotshaders.com/shader/toon-style-3d-water-shader-no-textures-needed/); [Stylized Water for Godot 4.x](https://godotshaders.com/shader/stylized-water-for-godot-4-x)
- Procedural textureless water. — [godotshaders: Wind-Waker-style water](https://godotshaders.com/shader/wind-waker-water-no-textures-needed/)
- A material-based inverted-hull outline, reported working on Mobile. — [godotshaders: Simplest outline shader](https://godotshaders.com/shader/the-simplest-outline-shader-via-material/)
- Community mobile-optimisation guides (slicker.me, gtstu.com) are third-party. Some claims didn't match official docs (for example, a made-up project-setting key), so they were excluded as unreliable. — [slicker.me field guide](https://slicker.me/godot/mobile-optimization.html) (not relied upon)
- A dev.to post on shipping a Godot 4 game to cheap Android phones concerns 2D shadow draw-call overhead, which doesn't apply to 3D. — [DEV Community](https://dev.to/orlalalala_0d2542b48051ed/shipping-a-godot-4-game-to-cheap-android-phones-what-actually-fixed-my-performance-2ofd)

### Inferences
Suggested per-scene Environment and settings preset for Fairway Flick on 4.7 Mobile. Synthesised from the sources above; validate on the Adreno 642L.
- **Lighting:**
  - LightmapGI with sun bake mode Dynamic and shadowmask Replace, Shadow Max Distance about the hole length, PSSM 2 splits (or Orthogonal), Soft Low.
  - Alternatively, sun Static plus a Decal blob shadow under the ball.
  - Ambient from a 3-colour procedural sky; Reflected Light from one Update-Once probe, or Sky.
- **Materials:**
  - Toon or Lambert-Wrap diffuse; Toon specular on the ball only; Rim on the green and ball.
  - Vertex-colour AO on rails and obstacles.
  - Opaque everything; Alpha Scissor only where cut-outs are needed.
- **Post:**
  - Glow levels 3-4 only, HDR threshold 1.0, Screen blend.
  - AgX or Filmic tonemap with a 3D LUT grade.
  - FXAA (or SMAA 1x, or MSAA 2x after an A/B test).
  - Debanding on.
  - Vignette as a UI-layer gradient.
- **Scaling:** `scaling_3d_scale` 1.0 on mid-range. A quality setting drops to 0.75-0.8 and disables real-time shadows for the 30 fps floor tier.
- **Build:** shader baker on for Android release; a warm-up scene covering all materials and probes; no feature toggles mid-round.

### Gaps
- I found no post-mortems of shipped stylised Godot 4 mobile 3D games with concrete settings or frame times.
- I found no Godot official stylised demo targeting the Mobile renderer with published Android numbers.
