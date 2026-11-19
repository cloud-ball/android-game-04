# Pocket Arena 8 — progress log

Newest first. Claude appends: date · what changed · how to try it on a phone · open questions.

## 2026-11-19 · Full test pass (all four games) and security check
- Unit tests: 272 green. QA fuzz (tools/qa_fuzz.gd, now also Break & Bank shots, Fairway Flick
  shots on every hole and Rush rule sequences): 40 seeds, no invariant violations (a pool ball
  resting in a side pocket's jaws is allowed: the check now knows the pocket mouths).
- Soak (desktop, bot, 7200 frames at 4x speed per mode): Serpent Grid vs / solo, Facetfall,
  Break & Bank, golf Rush, golf Tour - no script errors; node and object counts flat.
- Phone (Vivo V2250, wireless adb), bot runs with --fps (now also nodes / objects / memory):
  hub 60 fps; Serpent Grid 59; Break & Bank 60; golf Rush / Tour 58 (one hitch per hole change);
  Facetfall 60 without the bot (54 with it). No errors in the device log.
- Fixed: Facetfall fell to 44 fps (min 30) on the phone after the gem redesign - each 2D gem was
  ~11 polygon draw calls (603 per frame). GemArt now sends a gem as one triangle array, and whole
  sets (CPU mini-board, previews, hub icon) as one batch: 603 -> 37 draws, hub 209 -> 100.
- Real touch on the phone: golf Rush shots by finger drag, rivals play alongside, hole card;
  Android back returns to the hub; home + relaunch resumes the same process; Settings and the
  licence page open and scroll. The licence page is now fully opaque.
- Security: no network APIs, sockets or external processes; INTERNET permission off (VIBRATE
  only); allowBackup=false, game activity not exported; dev args file read only in debug builds;
  tests / tools / gdUnit4 excluded from exports; no keys or passwords in git; CI uses a throwaway
  debug key. Hardened: wrong-typed save values fall back to defaults (no crash on a damaged save).

## 2026-11-19 · Fairway Flick Rush (steps E1-E4): CPU golfers, rules, race on screen, tuning
- E1 GolfCpu: shot search with the real solver (route fan + straight at the cup, refine the best 3,
  risk check of the best 4 played +-3 deg / +-7 % off), tiered aim / speed error. GolfCpuThink runs
  it on ONE background lane: GDScript object calls serialise across threads (measured: 60 rollouts
  994 ms serial vs 1282 ms as a group task), so parallel rollouts do not help. Tee searches shared.
- E2 RushMatch (pure, 8 tests): first in wins, same-tick order, water, par+3 cap, 3-hole match,
  tie-break by strokes, draws.
- E3 Rush on screen: three CPU golfers (Mira, Otis, Kai) as ghost balls with name tags, stepped in
  lockstep with your ball; left status strip; hole / match cards with Play again. `--mode=tour`
  keeps solo play; `--bot` plays your ball with the Hard CPU.
- E4 tuning (tools/golf_selfplay.gd + golf_selfplay_report.py; 60 plays per hole per golfer; the
  baseline is a human proxy: same planner, 2 deg / 6 % error, 2.3-3.8 s per shot):

  | tier | CPU wins vs baseline (target) | you win a Rush match vs 3 of them |
  |---|---|---|
  | Easy | 21.8 % (25) | 70.7 % |
  | Medium | 45.9 % (50) | 27.3 % |
  | Hard | 68.4 % (70) | 6.3 % |

  First run had Easy winning 58 %: CPUs thought 0.6-1.9 s per shot, and in Rush speed wins; now
  every tier paces like a human (Easy 2.8-4.4 s, Medium 2.3-3.8 s, Hard 2.1-3.4 s).
- Saves: wrong-typed values fall back to defaults (all games, settings, coins).

## 2026-11-19 · The app is now "Playjar" (package com.cloud198.playjar) with a new jar icon
- The user chose Playjar ("a jar full of little games") over Octorival and other checked names (no
  "rival" in the name). Checked on Google Play, the App Store, Steam, itch.io and the web: no exact
  match (nearest: JarPlay, a J2ME emulator; CookieJar). Package id com.cloud198.playjar (nothing
  uploaded yet). Hub title PLAYJAR ("JAR" in gold).
- New original icon: a glass jar with a gold lid holding a snake, a cut gem and a blue billiard
  ball (no black 8-ball). Sources docs/store/src/icon_*.svg + icon.svg; PNGs rendered with headless
  Chrome. Found and fixed while checking the bundle: the Android 13+ themed (monochrome) icon was
  still Godot's default logo; it is now a jar silhouette (assets/icons/adaptive_mono_432.png).
- Store screenshot 01, the feature graphic, listing, privacy policy, tester invite, checklist, CI
  artifact and the upload key's default file (~/.android-keys/playjar-upload.jks) renamed.
- 192 tests green; release bundle verified (id, app name, all four launcher icons).

## 2026-11-17 · Package id is now com.cloud198.octorival
- Changed before the first upload (Play never allows a change afterwards), so the store URL matches
  the app's name. Dev args on a device: `adb shell run-as com.cloud198.octorival sh -c '...'`.
  A phone or emulator with the old debug build keeps it as a separate app; uninstall it.

## 2026-11-17 · Open-source licence page; second originality check passed
- Second ip-checker pass: the old Facetfall (Stack Drop) look-alike blocker is resolved; no shard
  keeps its shape's classic colour, no grid, no new blockers.
- Settings → About → "Open-source licences": a scrollable page with Godot's MIT licence and every
  bundled component's copyright and licence, built from the engine's own data
  (shared/ui/licenses_view.gd; tested). Godot's licence requires these notices to ship.
  `--licenses` dev switch opens it over the hub for screenshots.
- Leftover old names cleaned up: export file names, CI artifact, upload key default file name
  (~/.android-keys/octorival-upload.jks), the Facetfall scene's root node, GDD / starter prompts /
  blocks design doc (the old flat-squares concept images are marked superseded). ASSETS.md now also
  lists the store source captures and the design references.

## 2026-11-17 · Renamed: app "Octorival", block game "Facetfall" with its own gem look
- Why: the pre-release originality check flagged the block game's look (flat, classic-coloured
  squares in a dark gridded well, seen head-on) as too close to the classic falling-block game,
  whose owner has won look-alike cases; "Stack Drop" is also already a Play app's title, and
  "Pocket Arena" is close to two existing games. New names were checked on Google Play, the App
  Store, Steam, itch.io and the web: "Octorival" (octo = eight games, each a rival) and
  "Facetfall" (gem facets that fall) had no matches. Package id unchanged.
- Facetfall look: emerald-cut gems (octagon outline, table facet, four lit bevels, sparkle, the
  shard's glyph etched on the table); a jewel palette where no shard keeps its shape's classic
  colour (garnet, sapphire, emerald, amethyst, rose quartz, topaz, aquamarine; L* 33-87, every step
  >= 7); the well is tinted crystal glass with soft reflections and no grid; the tower turns a
  little more (sway 1.5 -> 4 deg). GemArt (shared/ui) draws the same cut gem in the HUD previews,
  the CPU mini-board, the how-to cards and the hub icon; the how-to well lost its grid too.
- Hub title OCTORIVAL ("OCTO" in gold), card "Facetfall · Gem tower race"; Settings shows
  "Octorival · v0.2.0". Desktop user data now lives under app_userdata/Octorival (Android is by
  package id, unaffected).
- All tests green. Try it: open Facetfall from the hub.

## 2026-11-17 · Break & Bank: ball colours shown as designed
- Godot converts Color shader parameters to linear by itself; pool_view.gd converted them again,
  so every ball rendered darker than its palette: the 1-ball looked orange like the 5, the 4 navy
  instead of purple, the 6 almost black. Removed the extra conversion (found while fixing the same
  bug in Fairway Flick). Before/after checked on a seeded bot match; balls are now clearly
  distinct. Try it: any Break & Bank match.
## 2026-11-17 · Fairway Flick: no more freeze on the first drag (shader warm-up)
- The first drag of each session froze ~2.3 s while the renderer compiled the aim guide, power
  ring, trail and effect shaders. FxWarmup (scenes/fx_warmup.gd) now draws every late-appearing
  effect once during the first hole's intro - same materials and vertex formats, but sub-pixel or
  1% opaque - for 4 frames, then frees the copies. Covers: guide/trail material, aim ring, puff,
  splash, confetti and spark particles, the power meter's lines/arcs/numerals, and the big score
  and star text.
- Measured on the emulator, cold shader cache each run (A/B via the new `--nowarm` dev switch):
  first drag without warm-up: worst frame 2266 ms (4 fps); with warm-up: worst 12.8 ms, 60 fps.
- The intro now advances at most 1/30 s per frame, so the warm-up hitch can't skip the fly-in.
- Emulator notes: give it `-memory 4096` (2 GB swaps and drops everything to ~10 fps); a cold start
  with an empty shader cache takes ~50 s on its OpenGL translator.
- 254 tests green.

## 2026-11-17 · Fairway Flick: emulator check, release-hitch fix
- No phone available, so the Pixel 3a emulator (API 36) was used. Its Vulkan bridge can't present
  frames on this Mac (black screen, "Couldn't present to Vulkan queue"), with host or SwiftShader
  GPUs; started with `-gpu host -feature -Vulkan` Godot falls back to OpenGL (Compatibility) and
  runs. Colours there look paler than on a phone (different renderer); fps on a Mac GPU says
  nothing about a mid-range phone, but it does show stalls.
- Findings: 60 fps on all three holes; the course, windmill, kit props, fence and flowers all
  render. Two kinds of stall:
  - The look-ahead that times slow motion ran the whole shot in the release frame (up to 45 ms on
    the Mac). Fixed: ShotForecast runs it at most 40 substeps per tick (10x real time) over the
    next frames; tested to give the exact same answer. Release is now smooth.
  - The very first drag of a session stalls ~2 s while the renderer compiles the guide / power
    ring / trail materials (a second drag is smooth). Fix planned: warm-up during the intro
    (visual step 8).
  - The `--bot` test mode's shot search takes 1-2 s per shot; dev-only, left as is.
- Emulator recipe: `emulator -avd Pixel_3a_API_36_extension_level_17_arm64-v8a -gpu host
  -feature -Vulkan -no-snapshot-save`; shots by `adb shell input motionevent DOWN/MOVE/UP`
  (a plain `input swipe` was not seen as a drag).
- 254 tests green.

## 2026-11-17 · Fairway Flick mini-golf: ambient life + a colour bug fixed (visual step 6)
- Plan: docs/plans/2026-11-15-fairway-flick-ambient.md.
- Wind: leaves, bushes, grass and flowers sway (one shared foliage shader; KitBatch now stores a
  per-vertex sway weight, 0 at a prop's base, so trunks, rocks, logs, pots, fences and mushrooms
  stay put). The gust travels across the world instead of everything moving in step.
- Slow cloud shadows drift across course and lawn (terrain shader, at most 13% darker).
- The flag cloth ripples. Five butterflies loop over spots beside the rails; four birds circle
  high around the windmill (one MultiMesh each, wings flapped in the shader, transforms updated
  with value types only).
- Reduce motion (Settings): no critters, no sway, no flag ripple, clouds frozen.
- Colour bug found and fixed: Godot already converts Color shader parameters to linear, and the
  terrain (and the new shaders) converted them again, so the lawn and carpet rendered much darker
  and duller than their palette since the start. Proven with a render test of four quads. The
  meadow was re-tuned for the true colours (lawn 0.28/0.46/0.20, carpet 0.14/0.58/0.26, exposure
  1.18 -> 1.05, saturation 1.15 -> 1.1): brighter and sunnier, carpet a rich green.
  Note: Break & Bank's ball shader has the same double conversion (pool_view.gd `colors`), left
  alone on this branch.
- KitBatch builds were briefly empty (packed arrays read from a Dictionary are copies); a new test
  checks a batch holds every placed copy.
- 253 tests green. Phone: build installed; the fps check is pending (wireless adb dropped).

## 2026-11-15 · Fairway Flick mini-golf: CC0 kit dressing (visual step 5)
- 18 models from Kenney's Nature Kit 2.1 (CC0, licence file kept beside them) in
  games/golf/assets/kenney_nature/, 200 KB, no textures; one ASSETS.md row per file. Preview
  sheets and logos are not shipped.
- Every prop is recoloured onto the world palette: GolfTheme.kit_color maps the kit's material
  names to our colours; a test checks every shipped material is mapped, no prop is as bright as the
  ball, and fence wood stays darker than the rails.
- KitBatch merges every placed prop into one mesh per colour: a hundred flowers cost the same draw
  calls as one. Small pieces (flowers, grass, mushrooms) cast no shadows.
- Ring 2: kit oaks, broadleaf trees and two pines replace the procedural cones and balls (same
  placement rules: clear of play, of the landmark's view and of the course's shade).
- Ring 1: kit bushes, stones, grass tufts and three-flower clusters along the rails.
- New: a low park fence around the lawn (skipped in front of the landmark and next to play), and
  up to four small scenes beside the play view per hole: a log pile with stumps, a mushroom patch,
  flower planters, a rock garden.
- Phone: 60 fps, GPU ~11.5 ms, 61-73 draw calls (slightly fewer than before, thanks to batching).
- 248 tests green. Try it: the test phone opens straight into golf.

## 2026-11-15 · Fairway Flick mini-golf: landmark and framing (visual step 4)
- Plan: docs/plans/2026-11-15-fairway-flick-landmark.md. The play camera never saw the old windmill
  (70 m out, 35 m aside), big trees blocked the course near the camera, and the top of the frame was
  empty.
- MiniFraming (pure, tested): the landmark goes straight ahead of the tee view, 30 m past the far
  end of the course, 3 m to the side away from the cup; trees stay 6 m from play, off the knoll, out
  of the tee's line of sight to the landmark, and never where their shadow would fall on the course.
  The tee view moved from golf_game into MiniBaker.flow_dir (same behaviour).
- New original landmark: a tapered stone windmill-tower on a grassy knoll with a balcony, door,
  window, pointed roof and lattice sails facing the tee (merged meshes, 5 draw calls).
- Mid skyline: wooded hills 90-160 m out (2 draw calls); fog raised so the backdrop recedes.
- Lawn to the horizon: GolfTerrain adds four apron strips around the baked grid with the same
  material (a first try with a big plane under the grid covered the course's pits - caught in
  screenshots before shipping).
- Intro: opens on the landmark over the whole course, holds 0.8 s, then glides to the aim view.
- Ring 1: low stones join the bushes and flowers beside the rails.
- Dev: `--hole=<n>` starts on a given hole (screenshots, phone checks).
- Phone (Adreno 642L): 60 fps on all three holes, GPU 11-12 ms, 64-78 draw calls (gate <= 100).
- 247 tests green. Try it: the test phone opens straight into golf; watch the intro, then aim.

## 2026-11-15 · Fairway Flick mini-golf: visual upgrade steps 0-3 (research-led)
- Research: docs/research/Fairway Flick mini golf visuals.md (+ notes): art direction, Godot Mobile
  rendering, CC0 kits, juice and UI. Key finding: order (a value ladder, a sense of place, polish),
  not more assets.
- Step 0: `--gfx=noshadow,noglow` dev switches (GolfScenery.gfx_flags). Phone (Adreno 642L, all
  views at 60 fps): baseline GPU 10.9 ms / 53 draws; noglow 12.5; noshadow 12.2 / 29 draws; both off
  14.2. GPU ms rises when work is removed - the phone drops its GPU clock at lower load - so per-
  feature cost cannot be isolated this way; the full look holds 60 fps.
- Step 1: GolfTheme (pure data) with a tested value ladder - lawn < carpet < rails < ball; flowers
  saturated and never white; yellow flag; dark cup with a white rim and an emissive glow ring; the
  ball is shaded (wrap diffuse, toon highlight, rim, slight emission) with a thin dark outline.
- Step 2: one merged bevelled rail mesh per hole (light wood sides, cream top and bevels, smooth
  beside ramps - no more stair-steps; one draw call), wrap lighting and a fibre sheen on the carpet,
  shadow range 45 -> 28 m, Filmic with a little exposure and saturation, glow only above 1.0 on two
  mid levels.
- Step 3: eased power (speed = max x pull^1.3, finer putts), a light haptic tick each 10% of pull,
  camera kick on release, sparks + ball squash + pitch/volume-varied clacks on hard rail hits (none
  under 0.3 m/s), a speed trail (20-point ring buffer), the HUD fades to 35% while aiming, a timed
  hole-out (cup sound and haptic, flag wiggle, confetti only for birdie or better, the score word
  pops in, stars one by one), shake only on a hole-in-one, everything off with reduce_motion.
  Slow motion around great hole-outs via PresentationClock: it only changes how many fixed substeps
  run per tick; a test proves the shot ends bit-identical.
- golf_game.gd split: course dressing moved to scenes/mini_dressing.gd (file-length limit).
- 243 tests green. Try it: the test phone opens straight into golf.

## 2026-11-15 · Fairway Flick mini-golf: fixed the par-3 freeze and the bad bouncing
- Phone feedback: on the par 3s the screen got stuck and the bouncing looked bad.
- Cause 1: going over the top of the Step Up ramp, a hop started from the ground height before the
  step; the flat top is higher, so the ball began inside the floor, "landed" at once and bounced ~70
  times in place. Now a hop starts above the ground where the ball is, and a contact with a ball
  already moving away from the surface is not a landing.
- Cause 2: a ball stopping just inside the cup's pull zone was kept awake forever (the game waited
  up to 40 s). The pull now acts like a shallow dip added to the slope, under the same static hold:
  too weak to move the ball means it rests; within ~18 cm it rolls in (pull 1.6 m/s^2).
- Sweep of 864 shots per hole: every shot rests within ~12 s, at most 10 bounces.
- 3 regression tests (shot sweep on every hole, ramp crest, near-cup rest). 240 tests green.

## 2026-11-15 · Fairway Flick mini-golf: richer look, steady camera, easier cup (branch fairway-flick)
- Phone feedback: graphics too basic; the camera swung around; near a wall the ball was hidden and
  hard to hole.
- Camera: an angled view from behind and above (~50 deg down) that turns only while aiming and glides
  after the rolling ball without rotating; a MAP button gives a top-down view of the whole hole.
- Cup: arcade size (75 mm radius vs regulation 54) and a gentle pull on slow balls within 35 cm
  (HoleData.cup_r / cup_pull; real-golf holes keep 54 mm and no pull), glowing ring, white rim.
- Look: sun shadows (45 m), glow, carpet fibre noise and brushed bands, rail shading on the carpet
  (baked into vertex colour), grass tones on the lawn, grain in sand, two-tone wooden rails with a
  light cap, flower beds and bushes along the rails, a ring under the ball while aiming, confetti on
  a hole-out.
- Phone: 60 fps, 56 draw calls, GPU 10.6 ms, no errors. 237 tests green.

## 2026-11-15 · Fairway Flick mini-golf step D: playable on the phone (branch fairway-flick)
- golf_game.gd is now the mini-golf screen: World 1's three holes in a row, solo. Slingshot shot:
  press anywhere, drag back, release - opposite direction, power = drag length, % ring at the finger,
  a dotted guide of the real path (same solver, up to two wall bounces); drag back under 30 px to
  cancel. The camera stays frozen while dragging (stable aim), sits low behind the ball, follows it
  after the shot; hole fly-over with a hole card. Default aim follows the flow field around corners.
- Course look: solid rails along every wall (stepped beside ramps), red-and-white bumpers, flag with
  a white cup rim, lawn, trees and the windmill around the course. Penalties: water +1 (drop), out /
  fallen into a gap +1 (replay); out of strokes at par + 4.
- Phone: 60 fps, 23 draw calls, no errors. 237 tests green.
- Try it: the test phone opens straight into golf (dev_args `--game=golf`).

## 2026-11-15 · Fairway Flick mini-golf step C: holes from tile maps (branch fairway-flick)
- MiniBaker (games/golf/logic/mini_baker.gd): a hole is a small text map of 3 m tiles (G green, T tee,
  H cup, B bumper, S sand, W water, ^ v < > ramps, . nothing) plus an optional level map. It bakes a
  10 cm height grid + surfaces, walls on every floor / nothing edge and where heights do not meet
  (merged into long rails, 20 cm thick), bumpers, tee and cup. A ramp whose high side faces nothing
  is a jump: lip and landing edge stay open; falling short drops the ball out of bounds.
- Flow field (tile distance to the cup, jumps included) for the CPU and the solvability check.
- Three World-1 holes: Corner (par 2, L-lane), Step Up (par 3, ramp to a raised green, sand,
  bumper), The Leap (par 3, jump over a gap).
- Tests (6): deterministic bakes, ramp heights / open top, jump cleared fast and missed slow, random
  shots never leave the walls, flow reaches every tee, a scripted golfer holes every hole in par + 2.
- Fix found on the way: tile-edge heights now take the highest touching floor (a jump lip had dipped
  into the pit).
- Try it: logic only.

## 2026-11-15 · Fairway Flick re-based as arcade mini-golf; walls, bumpers, hops (branch fairway-flick)
- User decision after the first long hole: the game is arcade MINI-golf (genre like the popular
  mobile mini-golf battlers - short walled holes, slingshot shot, Rush race where every ball plays at
  once), with an original name, art and courses. Plan: docs/plans/2026-11-15-fairway-flick-minigolf.md
  (supersedes the long-course plan); design doc and golf rules re-scoped.
- Physics (step B): HoleData walls (segments) and bumpers (circles); GolfBall rolls into them with a
  swept circle-vs-segment / circle test, up to four contacts per substep in time order (normal x0.8,
  sideways x0.9); flying balls bounce off walls below wall height; a rolling ball hops off ledges and
  ramp lips (ground drops away by > 0.5 m/s in a step) into the flight model and lands with the
  existing bounce. Golden mini-golf shot (walls, bumper, ledge).
- Tests (7 new): wall bounce angle and speed, 14 m/s never passes a wall (live and planner steps),
  many bounces stay in the box, bumper head-on / glancing, ledge hop, gentle ramp stays grounded,
  a bank shot off a wall can drop. 231 tests green.
- Uncommitted before this: the relative-drag aiming for the long hole (superseded by the slingshot).
- Try it: logic only; the phone still has the long-hole build.

## 2026-11-15 · Fairway Flick: one-tap swing, landing camera, scenery (branch fairway-flick)
- Phone feedback on the first hole: pulling down was uncomfortable, the swing too, never reached the
  green, the game looked generic, the ball's landing / water / out of bounds read badly.
- Controls (user's choice): aim + one tap. Drag the marker; power is solved automatically on the real
  solver (wind, lie, slopes) so a perfect shot lands on it - a white dot previews where. A needle sweeps
  the accuracy bar; tap the lower screen: centre = PERFECT, off-centre hooks / slices and comes up short.
  Putts work the same way (pace solved with the cup ignored).
- Ball: keeps a readable size at any distance, casts a shadow (height cue); the camera chases it up,
  then watches the predicted landing spot side-on (exact - same solver) so bounces read; grass / sand
  puffs per bounce, a splash for water, clear water / out-of-bounds banners.
- Look: GolfScenery - procedural sky, ring of hills, a windmill landmark that turns, water surfaces with
  ripples, conifers + round trees; hole fly-over with a hole card at the start (tap to skip).
- Phone: 60 fps, 59 draw calls, GPU 10.9 ms, no errors. 223 tests green.
- Try it: test phone opens straight into the hole (dev_args `--game=golf`).

## 2026-11-15 · Fairway Flick step 6: first playable hole (branch fairway-flick)
- Holes are data: games/golf/data/holes/meadow_03.json ("The Bend", par 4, ~290 m dogleg right with a
  corner bunker, pond, two greenside bunkers, mounds, a back-to-front green, 3 pins). HoleBaker turns a
  spec into HoleData (deterministic: + - * / sqrt only; packed shapes with bounding boxes; rounded
  fairway ends; 1.25 s on desktop - a bake cache comes later).
- GolfTerrain draws it: chunked 1 m meshes with the physics triangle split, one terrain shader fed by
  an R8 surface texture (mowing stripes on fairway and green), seeded low-poly trees out of bounds.
- GolfClubs: Driver 192 / Hybrid 150 / 7-iron 115 / Wedge 87 / Sand W 56 m full carry (measured on
  the solver), lie penalties (rough, sand), power-for-distance, putt speed helper.
- golf_game.gd plays the hole: drag on the course to place the landing marker (club auto-picked,
  clubbing up from bad lies), press below and pull down to swing (gold tick = power for the marker,
  sideways drift = hook / slice, overpower doubles it), putter on the green, stroke count, water drop
  +1, out of bounds +1 (replay), pick-up at triple bogey, par / birdie banner, next pin.
- Structural checks per hole (tee flat, pins on restable green with fringe around, landing width) and
  club-ladder tests. 223 tests green.
- Try it: hidden from the hub; on the test phone use dev_args `--game=golf`.

## 2026-11-14 · Fairway Flick step 5: phone benchmark (branch fairway-flick)
- `--bench=golf` (GolfBench; Boot passes the name). Golden fixtures moved into GolfBench so the phone
  prints the same hashes the tests check.
- Test phone (Adreno 642L, release-like debug build): golden flight and golden ball hashes identical to
  desktop (bit-exact). 25.5 us per substep at 1/240 (live: 4 substeps = ~0.1 ms per frame); a full shot
  to rest costs 49 / 25 / 13 ms at 1/240 / 1/120 / 1/60; a putt 17 ms at 1/120. Desktop: ~2.3x faster.
- Decision: live play stays at 1/240; the CPU plans at 1/60 (carry within 1 cm of 1/240), so ~75 full
  rollouts per second of thinking - enough for the shortlist + noise samples in the plan.
- Try it: `adb shell run-as com.cloud198.pocketarena8 sh -c 'echo --bench=golf > files/dev_args.txt'`.

## 2026-11-14 · Fairway Flick step 4: bounce, roll, cup, water, out of bounds (branch fairway-flick)
- GolfBall (games/golf/logic/golf_ball.gd): one shot from strike to rest - flight, Penner bounces with
  a per-surface tilt (GolfSurfaces), a skid phase where friction turns backspin into roll (so wedges
  check or spin back), rolling with per-surface deceleration and (5/7) g down slopes, rest with a
  green-speed-derived static hold, cup capture by speed and sideways offset (1.31 m/s centred, 1.63
  with the rim; lip-outs deflect and slow), water and out of bounds with a last safe point.
- CoursePreset (green speed, firm/soft greens and fairways, altitude, wind range) and GolfSurfaces
  (bounce / roll per surface); GolfParams.apply_preset scales air density and Reynolds together.
- Checked against the research: Stimpmeter roll within 0.2%; Haake's green bounce 4.2 m/s out with
  topspin (Penner's model 4.3, measured 5.1); tour driver 274 yd carry + 17 yd roll; on a firm green a
  9-iron holds at 809 rad/s and pulls back 0.6 / 2.1 m at 1000 / 1200 (Penner: 1.1 / 4.7 - about half,
  tune by feel); balls rest on greens below 10.8% / 8.6% / 7.9% at Stimp 8 / 10 / 11.
- Corrections found on the way: the notes' 11 deg firm-green tilt never spun the ball back (now 15,
  Penner's); their cup example "5 cm off at 0.5 m/s drops" contradicts their own formula (limit ~0.37).
- 9 new tests incl. a golden full shot (games/golf/data/golden_ball.json). 220 tests green.
- Try it: logic only.

## 2026-11-14 · Fairway Flick: full-game scope - courses, holes, progression (branch fairway-flick)
- Feedback: the preview is "just a flick"; the game must be real golf with holes and different maps.
- Research: docs/research/Fairway Flick courses and maps.md (+ notes): course structure and unlocks in
  well-rated golf games, themes and art direction, 22 hole archetypes and a difficulty ramp, a
  spec -> bake -> validate pipeline.
- New plan: docs/plans/2026-11-14-fairway-flick-courses.md - four themed 9-hole courses (parkland,
  coastal links, canyon desert, volcanic tropical) + an all-par-3 alpine bonus, named CPU rivals,
  3-hole legs to unlock courses, stars, championship, daily; holes authored as specs and baked to
  HoleData with automatic playability checks. Launch with Courses 1-2.
- Try it: nothing new on the phone (the flight preview is unchanged).

## 2026-11-14 · Fairway Flick: flight preview on the phone (branch fairway-flick)
- The golf placeholder is now a flight preview: a flat practice hole with a green at 150 m, distance
  markers, Driver / 7-iron / Wedge (average-amateur launches), seeded wind per shot. Tap the course
  to hit; tap left / right of centre to curve. Real solver (GolfFlight.step_over, 4 x 1/240 s per
  tick, allocation-free) with a trail ribbon and a chase camera; shows carry, apex, lie and distance
  to the flag. No bounce / roll / swing yet (steps 4 and 6).
- Try it: hidden from the hub. On the test phone files/dev_args.txt holds --game=golf, so the app
  opens straight into the preview (remove the file to get the hub back).

## 2026-11-14 · Fairway Flick step 3: hole terrain + exact ground contact (branch fairway-flick)
- games/golf/logic/hole_data.gd: per-hole vertex height grid + one surface type per cell (tee,
  fairway, rough, fringe, green, sand, water, path, out). Height / slope / normal follow the render
  triangles (each cell split on the same diagonal), so the ball never floats or sinks.
- Swept contact: the ground under a step is piecewise linear, so the first touch is solved exactly
  per triangle piece (64-bit). GolfFlight.fly_over(hole) flies over terrain to the first contact;
  leaving the grid = out of bounds.
- Tests (7): planes reproduced exactly, continuity across edges, surface lookup, exact contact, a
  70 m/s ball cannot pass through a ridge 0.13 m thick (a step is 0.29 m), 30 random launches over
  rolling ground land within 5 cm of a 20x finer step and never below the surface, flat-hole
  landing matches flat flight. 211 tests green.
- Try it: logic only (see the flight preview entry above for something to tap).

## 2026-11-14 · Fairway Flick step 2: ball flight (branch fairway-flick)
- games/golf/logic/golf_flight.gd: RK4 flight with Re-dependent drag (tabulated drag-crisis
  logistic), unclamped lift, Magnus via a fixed spin axis (tilt = curve), spin decay per metre and a
  height-profiled wind (tabulated power law, 10 m reference). Hot path is + - * / sqrt only.
- Validated against launch-monitor data (9 tests): tour carries driver 274 / 3W 260 / 5i 206 /
  7i 175 / PW 134 yd vs 282 / 249 / 199 / 176 / 142 (within 5%, PW within 8%); LPGA carry, apex and
  landing angle within 5% / 3 yd / 4 deg; 10 mph wind on a tour 7-iron -22.8 / +14.6 yd (published
  -19 / +14.6 - wind grows with height here); 10 deg tilt curves a 5-iron 21 yd; 1/60 s planning
  step within 1 cm of the 1/240 s live step; golden shot (games/golf/data/golden_shot.json).
- Try it: nothing to see yet (logic only). 204 tests green.

## 2026-11-14 · Fairway Flick step 1: research, plan, scaffold (branch fairway-flick)
- Research: docs/research/Fairway Flick golf game design.md (+ notes): ball physics, phone controls and
  camera, 9-hole design, CPU golfer, Godot/Android implementation.
- Plan: docs/plans/2026-11-14-fairway-flick.md (10 gated steps). Key decisions: one custom deterministic
  solver strike-to-rest (no Jolt hand-off), real-metre physics on a short par-32 course, pull-and-release
  swing with timing, expected-strokes CPU with real-handicap error, Mobile renderer.
- Corrected the old assumptions in docs/games/golf.md and .claude/rules/golf.md: smooth Re-dependent drag
  (the 0.27 -> 0.32 step carried drives ~12% short), unclamped polynomial lift (the 0.25 clamp flattened
  irons), (5/7) g slope pull on greens, offset-dependent cup capture, carry tolerance +-5% / +-8%.
- Scaffold: games/golf/{logic,scenes,assets,tests}; GolfParams (ball constants, Cd/Cl curves without
  pow/exp); placeholder scene; save namespace schema 1 + migrate stub; 4 tests (195 green). The manifest
  points at the scene but stays enabled = false (hub shows SOON).
- Try it: nothing on the phone yet (dev only: `godot --path . -- --game=golf`).
- Open: release exports are --headless, which skips the shader baker (slower first launch) - decide before
  the next store build.

## 2026-11-14 · Break & Bank: smarter CPU (shot checking, 8-ball bug fixed)
- Bug: on the 8 the planner simulated shots without calling a pocket, and the rules reject an
  uncalled 8 - so the CPU could not see a scratch on the 8 or the 8 in the wrong pocket. Rollouts
  now call the plan's pocket, as the game does. Hard's games lost on its own 8 mistakes: 9 -> 4
  of 30.
- Robustness: medium / hard replay their best 3 / 4 plans with their own typical error (aim
  +-0.8 sigma, speed +-1 sigma; shots at the 8 get 10 variations) and drop shots that only work
  when struck perfectly. Medium scratches: 17% -> 9.5% of shots; hard 8.5% -> 6.6%.
- When nothing can be potted, medium and hard play the safest legal hit instead of a blind one.
- Easy deliberately keeps the old careless play (no shot check, blind fallback) so it stays
  beatable.
- Ladder (self-play): easy 32% / 40% (40 games), medium 40%, hard 60% / 80% (20 games).
  Thinking time on desktop: easy ~25 ms, medium ~280 ms, hard ~480 ms (x3-4 on the phone).
- The 9 s rollout cap is fine: 159 sampled planner shots all stopped within 7.9 s.
- Tests: 2 new planner tests on the 8 (191 green).
- Try it: play Medium or Hard; the CPU should give away far fewer ball-in-hand scratches.

## 2026-11-14 · Pool renamed to Break & Bank; pre-release checks; merged to main
- Rename: "Cue Club" is an existing commercial pool/snooker series (Bulldog Interactive; Cue Club 2 is
  on Steam), so the game ships as **Break & Bank** (GDD fallback; web search found no game by that
  name - not a formal trademark search). Display name, HUD title, scene node, code comments and
  design docs updated; research files keep their original titles.
- IP check: nothing else blocks. Follow-ups: decide the pooltool attribution (credits/NOTICE entry
  or reword the cushion-model comment); register the hub icon PNGs in ASSETS.md; describe pool
  generically in the store listing.
- Physics review: no blockers. Fixed: integer-division warning in the sound loop, stale "7-ft"
  comment, new test that breaks at 9 and 13 m/s never hit the 64-event fallback. Follow-ups:
  planner rollouts stop at 9 s while slow balls still roll (raise the cap or penalise unfinished
  rollouts); the creep branch nudges the lower-index ball rather than the approaching one; cache
  spin_decel_still; allocation-free state copy for PoolAim.predict; fast-forward renders only the
  last of 4 steps.
- Try it: the hub card and start screen now read "Break & Bank".

## 2026-11-14 · Cue Club: ball trays, best of 3, end-of-match stats
- Plan: docs/plans/2026-11-14-cue-club-tray-series.md (research priority 10 + race-to-2 frames).
- Ball trays in the top bar: each player's 7 group balls + the 8; bright = still to pot, dimmed =
  potted, the 8 gets a gold ring once it is the target. A potted ball's slot pulses as it dims
  (a fly-in from the pocket was tried first and dropped: it pulled the eye off the table).
- Best of 3: second mode on the start screen ("Single rack" / "Best of 3"). Breaks alternate by
  frame; a banner between frames shows the winner, score and who breaks next; frame pips by each
  group. Coins and the daily challenge count once per match; a best-of-3 win pays double.
- End card: potted, best run (consecutive potting shots), pot rate, CPU potted, wins (+ frame score).
- New pure PoolSeries (games/pool/logic/pool_series.gd) with tests; save schema 1 -> 2 adds "mode"
  (migrate keeps everything; tested). 188 tests green.
- Try it: start screen -> Best of 3 -> PLAY; watch the trays fill as balls drop.

## 2026-11-14 · Cue Club: bigger balls (6-ft table), cleaner pockets, softer foul, fuller how-to
- Table: 7-ft -> 6-ft bar table (0.838 x 1.676 m). The phone fits the table to its width, so every
  ball draws ~16% bigger; physics constants unchanged (golden break regenerated with justification).
- Break: the shorter table made centre-ball breaks scratch into the side pockets (29% at 85% power).
  The break now starts with a light follow preset (PoolAim.BREAK_TOP 0.15, visible on the spin
  button, changeable); CPU breaks the same way. 200 breaks: 54% pot a ball, 12% scratch at 85%;
  66% / 9% at full power (7-ft was 34% / 12% and 48% / 22%).
- Pockets: rails and wood are drawn low, so a ball resting in the jaws draws over the hole instead of
  only its numbered top showing through; a potted ball darkens as it sinks.
- Foul: a soft low two-note tone (sines, slow attack/release) instead of the noise burst; lighter buzz.
- How to play: clearer control text (fine-aim edge, power bar side, spin button) and three rule
  cards: Solids or stripes, Call the 8, Fouls give ball in hand (try-it drag).
- CPU self-play on the 6-ft table (20 games each): easy 20% / 35%, medium 40%, hard 65% / 70% -
  ladder intact, easy and medium a little softer than on 7-ft.
- Try it: install the debug APK; open How to play from the pause menu; break a few racks.

## 2026-11-14 · Cue Club: wooden knock sounds, no more twirling balls
- Sounds: ball, cushion, cue and pocket sounds are now filtered-noise knocks with a short low body
  (core/AudioService.gd `_knocks`) instead of ringing sine partials, which sounded like glass. Gains
  set below clipping (checked offline with a Python replica of the generator).
- Physics: spin about the vertical axis now decays at 22 rad/s^2 (was 10.9) and twice that once the
  ball has stopped, so a stopped ball no longer twirls in place for seconds after side spin or a cut
  (~0.7 s at most, was ~2.8 s). Golden break regenerated with the justification in the file.
- Try it: install the debug APK, play a few cuts with side spin and a break; listen to the clacks.

## 2026-11-14 · Cue Club vs similar games: research + first fixes
- Research: docs/research/Cue Club versus mobile pool games.md (+ notes): features, physics feel
  (measured), polish, CPU fairness. Verdict: not shippable yet; blockers were dry breaks, unmeasured
  CPU, the Easy/Medium snap blocking thin cuts, and silent cushions / flat sounds.
- Physics retune (golden break regenerated with justification): mu_roll 0.012 -> 0.010, e_cushion
  0.85 -> 0.95 (WPA rail test 3.4 -> 4.16 table lengths), casual pockets 12.7 / 14.0 cm. Break power
  13 * p^1.2 (85% of the bar = 10.7 m/s, was ~9). Breaks that pot a ball: 3-25% -> 46% at 85% power,
  58% at full; scratches 8-15%.
- Aim snap (Easy/Medium) now locks onto pocket lines (ghost-ball aims), not ball centres.
- Sound: the solver logs impact speed per event; clicks / cushion thuds / pocket drops scale with it
  (quiet touches skipped). New synthesized impacts (damped partials + transient) replace the UI blips;
  cushions finally make a sound. Seeded RNG for pitch variation.
- Next: the simulation-based CPU with measured difficulty (blocker 2).

## 2026-11-13 · Cue Club: point-to-aim
- Turning the cue from the side was hard with the dial-style sweep (a sideways drag beside the ball
  barely rotates it). Now the cue points from the white ball at the finger: touch a ball to aim at
  it, drag to adjust; FINE strip for small corrections; finger within 7 cm of the white is ignored.
  Easy / Medium lock onto a legal ball's centre when within 0.6 / 0.3 deg. How-to card updated.
- Verified on the Vivo; test added (181).

## 2026-11-13 · Cue Club feedback 2: weaker CPU, bigger balls, smooth lines, pocket drops
- CPU weaker: Gaussian aim sigma 0.6/0.26/0.12 -> 1.4/0.7/0.32 deg, speed noise up; Easy / Medium pick
  among their best 4 / 2 shots instead of always the best.
- Bigger balls (+~9%): top bar 120 -> 108, bottom band 200 -> 150 (+ gesture inset), wood 5 -> 4 cm,
  camera pitch 8 -> 5 deg, no extra height margin.
- Smoother aim lines: 2x MSAA in Cue Club only, soft dash ends and edges, and the drawn aim eases
  towards the finger (shots still use the exact aim).
- Pocketing: a captured ball rolls on into the hole and sinks over 0.32 s with its shadow fading,
  instead of vanishing.

## 2026-11-13 · Cue Club feedback: bigger balls, natural rolling, pocket gaps
- Bigger table/balls (~20 dp): thinner drawn rails, wood to the screen edges, shorter top bar, camera
  fitted to the height left between the HUD bands too, pitch 12 -> 8 deg.
- Rolling looked artificial: numbers were upright labels that never turned while stripes rolled.
  Numbers are now printed on two opposite sides and roll with the ball; an upright label fades in
  only once the ball has stopped (readability at rest). Pattern fade starts later at speed.
- Black gaps beside pockets: the cloth now runs under the cushions to the wood; pocket holes sit in
  the jaws and stay inside the table.

## 2026-11-13 · Cue Club step 3: playable table (branch cue-club; enabled on this branch)
- games/pool/scenes: PoolView (22 deg KEEP_WIDTH camera pitched 12 deg, table long axis vertical;
  one MultiMesh + one unshaded shader for all 16 balls - stripes / cue markers roll in object space,
  numbers are an upright camera-facing disc; painted cloth / cushions / wood / pockets / sights, no
  real lights; blob shadows; visual-only spin with a per-tick clamp; aim line, ghost ball, object and
  cue rays, cue stick), PoolControls (power bar v = 8 p^2 m/s, 12 on the break; fine-aim strip
  0.03 deg/dp; spin button + big spin panel with presets), PoolHud (GameShell: players, groups by
  name + number chips, pause, message line), PoolHowto (drag to aim, pull to shoot, spin), PoolGame.
- games/pool/logic: PoolAim (angular sweep around the cue ball, 60 ms lift-off filter, guideline from
  the real solver incl. throw; cue ray = direction after the spin takes hold), PoolCpu (basic: clear
  straight-in shots with Gaussian aim noise 0.6 / 0.26 / 0.12 deg; ball in hand sets up a straight
  shot; breaks at the apex) - the simulation-based CPU is step 4.
- Ball in hand by dragging the white ball (kitchen line on the break); call the 8's pocket by tapping
  a pocket; hold a finger down while balls roll to fast-forward. Sounds: clack, cue, pocket.
- Daily challenges: "Win a game of pool", "Beat the CPU on Medium".
- 180 tests. Desktop: bot vs CPU plays whole racks. Phone pass: pending (phone not connected).

## 2026-11-13 · Cue Club step 2: Casual 8 rules engine (branch cue-club, not playable yet)
- games/pool/logic: PoolState (plain data), PoolShot (built from the solver's event log), PoolRules
  (one pure apply_shot in the researched order: fouls -> break -> 8-ball -> respots -> foul -> open
  table -> assigned -> stalemate), PoolMatch (solver + rules in step: strike / settle, respots, ball in
  hand, cue-ball return, re-rack), PoolRack.spot (foot spot, then along the long string).
- Rules: only the 8's pocket is called; ball in hand anywhere after every foul (break too); 8 on the
  break re-spotted; table open after the break; groups to the first legal pot (first-hit group wins a
  mixed pot; "take what you make"); "group cleared" snapshotted at shot start (last ball + 8 = loss);
  loss reasons: 8 off table > early 8 > 8 with a foul > wrong pocket; no-rail foul; 24 shots without a
  pot re-rack; strict break and scratch-on-8-loses as Pro flags.
- Solver: balls frozen to a cushion at the strike don't count as new rail contacts (WPA 2.7).
- 41 new tests (the research's 40 fixtures + random full games through the solver). 174 total.

## 2026-11-13 · Cue Club step 1: deterministic pool physics (branch cue-club, not playable yet)
- Research: docs/research/Cue Club pool game design.md (+ notes): physics, portrait UX, Casual 8 rules,
  CPU, rendering. pool.md and .claude/rules/cue-sim.md updated with its 15 corrections (rolling
  deceleration is mu_roll*g, not 5/7 of it; 7-ft table; CPU budget 1-3 s, not 150 ms; ...).
  Plan: docs/plans/2026-11-13-cue-club.md.
- shared/cue_sim: CueParams, CueTable (7-ft, rails + angled pocket facings + jaw points + capture
  circles), CueSim (closed-form sliding / rolling / spinning phases, 1/240 s substeps with swept
  time-of-impact events in time order, ball-ball impulse with capped friction (throw), Han 2005
  cushions from pooltool's corrected source, cue strike with tip offset; 64-bit packed state, no trig in
  the hot path). Clusters: slow contacts are inelastic, creeping contacts stop, 64-event cap with an
  energy-safe fallback; no overlaps in random breaks. games/pool/logic/pool_rack.gd (seeded jitter).
- 15 new tests (stun 5/7, draw-back 2/7, mu_roll*g, 90/30-degree rules, throw + gearing english, energy,
  overlaps, stop shot, pockets, rails + english, render-rate independence, golden break).
- Benchmark (Boot --bench=cue) on the Vivo (Adreno 642L): golden break hash IDENTICAL to desktop
  (433143a3...) -> bit-exact cross-platform, one golden file is enough. Live: 144 us/substep (worst
  case ~0.6 ms per 60 Hz frame during a break). AI planning (1/120 s): ~122 ms per break, ~4 ms per
  typical mid-game shot -> ~100 rollouts in ~0.4 s on one core; the research's 35-130 ms guess was
  pessimistic. Desktop: 77 us/substep, 113 ms per break.
- Debug builds read one-shot dev args from user://dev_args.txt (adb can't pass args to the game
  activity): adb shell run-as com.cloud198.pocketarena8 sh -c 'echo --bench=cue > files/dev_args.txt'

## 2026-11-13 · Bigger Serpent Grid pause button
- Serpent Grid's pause was a small 96 px "II" text button. Both games now share UiKit.pause_button():
  a 112 px dark disc with drawn bars in a 144 px touch area (Serpent Grid: top-right under the score
  bar). Verified on the Vivo: visible and opens the pause menu.

## 2026-11-13 · How-to phase 2+3: practice hints, "Try it", How to play in the pause menu
- Pause menu has "How to play"; from there the last card says GOT IT and returns to the menu.
- "Try it": after a demo plays once, "Your turn - try it!" appears; doing the gesture on the demo
  (tap / drag / flick / swipe / HOLD chip or two fingers) shows "✓ Nice!" and replays the board's
  reaction without the finger. Pause moved to a small corner button on the demo.
- First-match practice hints: a looping finger + caption over the real board, never blocking play,
  until the move is done (max twice per match). Stack Drop: Tap to rotate (after 2 shards), Drag to
  move (3), Flick down to drop (5), Tap HOLD (8). Serpent Grid: swipe hint 4 s after GO if no turn;
  "Edges wrap around - keep going!" ~1 s before the first edge.
- Saves: "learned" moves (Stack Drop schema 2, Serpent Grid schema 3); players who had already played
  are migrated as knowing the moves (Serpent Grid still teaches wrap edges). SaveService now copies
  container defaults (const dictionaries are read-only).
- 118 tests; soak runs clean. Phone: Try it (tap, drag, flick), pause -> How to play -> GOT IT,
  wrap hint in a real Serpent Grid match. Dev: --practice forces hints on.
- Try it: open a game -> How to play -> wait one loop -> do the move on the demo. Pause -> How to play.

## 2026-11-13 · Animated how-to cards (both games)
- Research: docs/research/How to play tutorial videos.md (+ notes). Live drawn demos instead of
  video files: 0 bytes of APK, crisp at any DPI, always match the current rules and art.
  Plan: docs/plans/2026-11-13-howto-cards.md.
- shared/ui/howto_deck.gd replaces the static 4-row panel: one verb per card, a ~3 s looping demo on a
  stylised mini-board with an original fingertip glyph (GestureTimeline: Android ripple 75/225/150 ms,
  swipe 200 ms, drag 60+100 ms per column, flick 120 ms). Loops 3 times, then rests on the result with
  Replay; tap the demo to pause. Skip at the top, Back / Next, PLAY on the last card starts the match.
  Cards change only by buttons (players copy the gestures in the demo).
- Serpent Grid: Swipe to turn · Edges wrap around · Make the CPU crash (vs only).
- Stack Drop: Tap to rotate · Drag to move · Flick down to drop · Tap HOLD to keep ·
  Clear rows, send garbage (vs only; the garbage rule was never taught before).
- Settings: new "Reduce motion" toggle -> cards show the old icons as still pictures.
- Android back closes the cards. Dev: --howto=<card> --howto-ms=<t> freezes a card for screenshots.
- 108 tests (timeline phases, ripple timing, drag steps, 3-loop stop + replay, pause, Next/PLAY/Skip,
  reduce motion, Solo filtering, caption length). Verified on the Vivo: all 8 cards, PLAY, Reduce motion.
- Try it: open either game -> How to play. Settings -> Reduce motion to see the still version.

## 2026-11-13 · Thorough QA pass (Stack Drop 12 x 24 + Serpent Grid)
- Headless: 96 tests; rules fuzz 150 seeds; soak runs of both games x vs/solo x 3 difficulties at 8x
  speed (no errors); layouts at 16:9, 19.5:9, 20:9, 21:9 and 2:3 (no overlaps or cut-offs).
- Phone (Vivo): hub -> Stack Drop -> how-to -> play (tap rotate, drag 2 columns, flick drop, HOLD once
  per shard, back = pause/resume) -> top-out -> results -> play again -> pause -> restart / back to hub ->
  Serpent Grid play. No errors in logcat; load 166 ms + 431 ms warm-up.
- Fixed: Serpent Grid - a snake moving into the tail cell of a snake that crashed on the same tick
  overlapped it on the final frame; it now crashes too (draw). Found by the fuzzer, test added.
- Fixed: Stack Drop start screen showed the old difficulty's level behind the panel (GameShell now emits
  difficulty_changed); Solo left an empty CPU column in the top band (layout is now mode-aware, test).
- CPU retuned for the 12 x 24 board with new tools/stack_selfplay.gd (difficulty table moved to
  games/blocks/logic/stack_difficulty.gd). vs an "average" simulated player: Easy was 0% -> 27%
  (it barely cleared lines), Medium 75% -> 53%, Hard unchanged (100%; 35% vs a strong player).
- Note: the QA match on the phone used the real save (one extra Stack Drop loss, +2 coins).

## 2026-11-12 · Stack Drop: slower falling speed until level 25
- User: blocks come too fast. Gravity was 1 + 0.55/level (L10 5.95 rows/s, L25 14.2). Now 1 + 0.2/level up
  to level 25 (L2 1.2, L10 2.8, L25 5.8 rows/s), then +0.7/level after 25, capped at 20. Test added.
- Try it: play Stack Drop past a few levels; it should stay calm for much longer.

## 2026-11-12 · Stack Drop: 12 x 24 tower (blocks smaller again)
- User asked for still smaller blocks. Board 10 x 20 -> 12 x 24 visible (W 12, H 26 incl. 2 hidden rows);
  spawn column now derived from the width so shards still start mid-board.
- Vivo: cell 91 -> 76 canvas units (35 -> 29 dp, ~4.7 mm); tower unchanged at ~84% of the width.
  Drag stays 36 dp per column, so moving shards feels the same.
- 93 tests green, fuzz 0 violations over 30 seeds. Lines need 12 cells now, so matches run longer and the
  CPU clears more slowly - check on the phone whether its speeds need retuning.
- Try it: open Stack Drop -> 12 columns, 24 rows.

## 2026-11-12 · Stack Drop: 10 x 20 tower (smaller blocks, more of them)
- User: keep the big tower but make the blocks smaller with more of them. Board 9 x 18 -> 10 x 20 visible
  (StackState.W 10, H 22 incl. 2 hidden rows). BoardLayout takes COLS/ROWS from StackState, so the
  well, posts and pedestal follow automatically.
- Vivo: cell 100 -> 91 canvas units (39 -> 35 dp); tower still ~84% of the width and ~75% of the height.
- 93 tests green, fuzz 0 violations over 30 seeds. CPU speeds unchanged (it may clear a little slower on
  the wider board - check on the phone).
- Try it: open Stack Drop -> 10 columns, 20 rows.

## 2026-11-12 · Stack Drop: much bigger tower (HOLD moved up beside NEXT)
- User: tower still too small. Plan: docs/plans/2026-11-12-stack-drop-bigger-tower.md.
- HOLD left the bottom band and sits in the top band beside NEXT (row 2: CPU | HOLD | NEXT); the bottom
  band is now just the pedestal. Side gutter 92 -> 72, pedestal 10.4 -> 9.8 cells, max cell 38 -> 42 dp.
- Vivo: cell 92 -> 100 canvas units (36 -> 39 dp), tower 77% -> 84% of the width, ~75% of the height.
- NEXT previews are sized to fit the strip; start hint shows in the upper-middle of the empty well.
- Two-finger tap still holds. Layout tests updated (4 phone shapes, 48 dp targets, no overlaps).
- Try it: open Stack Drop -> tower fills most of the screen; tap HOLD (top left, under CPU's right).

## 2026-11-12 · Bigger Stack Drop tower, bigger "Back to hub"
- Tower cells 88 -> 92 canvas units on the Vivo (34 -> 36 dp); tower 73% -> 77% of the width. Space came
  from tighter HUD bands (side gutter 130 -> 92, pedestal band 140 -> 108, HOLD 168 -> 150, NEXT 130 -> 120).
  Cell size is also capped so the pedestal always fits inside the side margins (21:9 phones).
- Pause hit area trimmed to stop at the NEXT strip (still >= 48 dp on a 360 dp phone).
- Shared menus (both games): "Back to hub" and "How to play" are full-size white buttons (38-40 px text,
  ~110 px tall) instead of small grey ones.
- Try it: open Stack Drop -> the tower is wider; pause -> "Back to hub" matches the other buttons.

## 2026-11-12 · QA pass fixes (Stack Drop + hub + Serpent Grid)
- QA: tools/qa_fuzz.gd (rules invariant fuzzer) + Boot --time-scale soak runs found the bugs below.
- Stack Drop rules: shards can no longer rotate/kick into the hidden rows above the tower; a lock that
  leaves any cell above the top, or garbage that lifts blocks above the top, now ends the game instead of
  leaving invisible blocks. 3 new tests; fuzz: 0 violations over 40 seeds.
- Stack Drop HUD: held shard stays bright after using HOLD (was too dim); the start hint sits beside HOLD
  instead of over the bottom rows.
- Loading screen: game title, spinner and "Loading..." stay up until the new scene has drawn 3 frames
  (first-use shader compile happens behind it). Vivo: ~180 ms load + ~450-560 ms warm-up.
- Hub: Android back no longer quits at once - first press shows a centred "Press back again to exit"
  toast, a second press within 2 s exits (back closes Settings first if it is open).
- Serpent Grid now uses the shared GameShell overlays (same start / how-to / pause / results as Stack Drop);
  its HUD lost ~250 duplicated lines. Larger HUD text (36-38 px labels, 36 px start stats on both games).
- Not fixable: "Vulkan surface lost" in logcat when the app goes to the background is Android/driver noise.
- 93 headless tests, lint clean. Verified on the Vivo: hub back/toast, loading screen, Serpent Grid
  start / how-to / play / pause, Stack Drop start / play / HOLD / hint.
- Try it: open the app, press back once (toast) then twice (exit); open Stack Drop, press HOLD and
  check the held shard is easy to see; open Serpent Grid -> How to play.

## 2026-11-12 · Stack Drop board redesign (researched)
- Research: docs/research/Stack Drop board redesign.md (+ notes). Cell 88 canvas units (~34 dp, 5.6 mm),
  well ~73% of width; orthographic camera pitched 9 deg; 0.55-deep gem slabs; pedestal sized to the margins;
  HUD moved off the well (top band read-only, HOLD bottom-left); lightness-ladder palette + glyph per shard.
- games/blocks/logic/board_layout.gd: pure layout (cell size + every HUD rect from canvas size, safe area,
  density); 8 tests over 20:9, 19.5:9, 21:9 and 16:9 (no overlaps, nothing in the gesture keep-out,
  48 dp tap targets on a 360 dp phone).
- Shards now spawn in the top visible rows (hidden rows are rotation headroom only).
- Drag step is physical (36 dp per column), gestures ignored on HOLD/pause, screen edges and the
  gesture area. Vivo: phone density 480 -> 420 dp wide. Verified on the phone; 60 fps (bot vs Hard).

## 2026-11-12 · Stack Drop tested on the Vivo
- Full pass on the phone: hub card -> how-to -> start -> tap rotate, drag move, flick drop, HOLD box,
  garbage rows from the CPU, top-out -> TOWER FULL results. No errors in logcat; 60 fps.
- CPU was too strong (Medium cleared 27 lines in 50 s). Now: Easy 2.4 s/shard (top 5, noisy),
  Medium 1.7 s (top 3), Hard 1.15 s (best) -> Medium ~11 lines in 50 s.
- First open of Stack Drop takes ~5 s (one-time shader compile); later opens are fast.
- Bigger tower (user request): near full width/height; NEXT, HOLD and CPU are slim see-through panels over
  the outer top columns; pause moved into the score bar; 30° lens, gentler sway.

## 2026-11-11 · Stack Drop step 2: playable (branch stack-drop)
- 3D crystal tower (games/blocks/scenes/blocks_view.gd): gem shader with facet edges, outlined ghost,
  glass back pane with grid, posts, hex base, clear flash + crystal shatter, garbage bar, slow sway.
- Touch gestures (StackGestures, tested): tap rotate, drag move per cell, slow drag soft drop, flick hard
  drop, two-finger tap hold; HOLD box is tappable; desktop keys with DAS/ARR.
- shared/ui/game_shell.gd: reusable start / how-to / countdown / banner / pause+settings / results
  overlays (Stack Drop uses it; Serpent Grid still has its own HUD - migrate later).
- vs CPU race with garbage exchange (+ cancelling) and Solo score attack; Easy/Medium/Hard.
- Daily challenges now rotate only over enabled games; 3 Stack Drop challenges added.
- Dev: Boot --game opens games even while their manifest is disabled. Stack Drop enabled on this branch.
- 81 headless tests.

## 2026-11-11 · Stack Drop step 1: rules + CPU search (branch stack-drop, not yet playable)
- games/blocks/logic: ShardData (shards A-G, kick tables from data/kicks.json), StackState,
  StackLogic.reduce(state, action) (moves, kicks, gravity, lock delay + 15 resets, clears/scoring/levels,
  hold, 3-preview, ghost, garbage with cancel, top-out), StackAI (rotation x column search + heuristic).
- 25 new tests (73 total). Export presets now include games/*/data/*.json (kick table ships in the APK).
- Plan: docs/plans/2026-11-11-stack-drop.md. Next: 3D crystal tower + touch controls + HUD.

## 2026-11-11 · Weaker CPU + turn hints (user feedback)
- New ai_blunder knob (CPU sometimes skips the flood-fill look-ahead; never picks a blocked cell): Easy 15%,
  Medium 8%, Hard 2%. Hunt 0 / 0.05 / 0.3, wander 0.5 / 0.3 / 0.1. CPU win vs steady bot: 20% / 30% / 41%
  (was 40 / 49 / 52). Rule file .claude/rules/snake.md updated to allow blunders.
- Turn hint: a glowing white › (0.9 cell, pops in) rides in front of the head + brief head glint (0.6 s);
  tiny haptic tick on each accepted swipe. 48 headless tests.

## 2026-11-11 · Polished settings UI (user feedback: too small)
- shared/ui: IconGlyph (drawn icons), ToggleSwitch (large animated switch), SettingsSheet (bottom sheet:
  Music / Sound effects / Vibration rows with icons + hints, About card, Done). Whole rows are tap targets.
- Hub header: coin pill + round gear button. Pause menu gains Settings (same sheet). Android back closes it.
- Bug found while testing: controls given "full rect" after entering the tree keep a 0x0 size -> use
  set_anchors_and_offsets_preset / UiKit.center(). 46 headless tests; verified on the Vivo.

## 2026-11-11 · Wrap-around edges (user request)
- SnakeConfig.wrap (on for all levels): leaving an edge re-enters on the opposite side; only tails crash.
- AI pathing/flood/cut-off/head-avoid are wrap-aware; view slides wrapped segments in from outside the edge.
- How-to step 4 is now "Edges wrap around". 43 headless tests. Matches ~50% longer; 59-61 fps on the Vivo.
- Fixed: physics interpolation smeared the snake scene's first frames (giant boxes) -> OFF for this game.

## 2026-11-11 · Space backdrop + AI speed-up
- New games/snake/scenes/snake_backdrop.gd: twinkling drifting stars, noise nebula clouds, shooting stars,
  rising sparks; see-through board; grid ripples on eat/crash; pulsing board edge.
- Found with `--fps` on the phone: AI ticks took 70-195 ms (stutter). Flood fills now stop once the answer is
  known and use packed arrays -> solid 59-61 fps on the Vivo (Hard, bot vs CPU), GPU ~9 ms, ~33 draw calls.
- Boot `--fps` prints fps, process time, GPU time and draw calls to the log.

## 2026-11-11 · Bigger board, slower snakes, easier Medium (user feedback)
- Camera 78° / 26° lens; tall screens get extra rows (12x22 on 20:9, 12x18 on 16:9): board ~46% -> ~70% of screen.
- Speeds lowered: Easy 4.5->7, Medium 5.5->8.5, Hard 6.5->10 tiles/s. Medium hunts 15% (was 30%), wanders more.
- 37 headless tests.

## 2026-11-10 · Serpent Grid polish (all 5 items)
- Music: original synth loops (hub + game mixes) rendered on a worker thread, cached in user://; Music toggle.
- Solo score-attack mode (vs CPU / Solo selector), solo best + NEW BEST, save schema 2 with migration.
- Visuals: joined snake bodies, heads with eyes facing the move direction, orb sparkles.
- First-launch HOW TO PLAY screen (drawn illustrations), reachable again from the start panel.
- AI tuning via tools/snake_selfplay.gd: fixed head-on draw bug (93% of Easy/Medium bot matches were draws),
  all levels avoid head-on, new hunt (cut-off) knob; Easy slower (5.5 tiles/s). CPU win vs bot: 39/41/55%.
- 35 headless tests; verified on the Vivo (first launch, how-to, vs CPU, Solo, music cache).
- Try it: install build/pocket-arena-8-debug.apk (already on the test phone, data cleared for a fresh first run).

## 2026-11-10 · Serpent Grid ready for closed testing (branch serpent-grid-v1)
- Godot 4.7.2 project, core services (Rng, SaveService, Settings, Audio, Economy, GameRegistry, SceneRouter, Boot args),
  hub with 8 manifest-driven cards (only Serpent Grid enabled), daily challenge, coins.
- Serpent Grid: pure logic + CPU rival (BFS to orb + flood-fill trap check) + neon 3D view + HUD. 30 headless tests.
- Verified on a Vivo V2250 (Android 15): hub → game → swipes → crash/result → rematch.
- Release: Gradle AAB (minSdk 24, targetSdk 36), scripts/make_upload_key.sh + scripts/build_release.sh,
  store assets + listing + privacy policy in docs/store/, CI workflow (not yet run on GitHub).
- Try it on a phone: `godot --headless --path . --export-debug "Android APK" build/pa8.apk && adb install -r build/pa8.apk`.
- Dev shortcuts: `godot --path . -- --game=snake --bot --difficulty=hard` (bot runs never touch the save).
- Open: gdUnit4 is 6.2.3 (guide said v7, which doesn't exist); tests need --headless --ignoreHeadlessMode.

## Week 0
- Project created from the starter kit.

## 2026-11-10 · Kickoff
- Kit copied into repo (CLAUDE.md, .claude/, docs/, ASSETS.md); guide at docs/design/; keyframes in docs/refs/<id>/.
- Toolchain checked: Godot 4.7.2 + templates, Android SDK, JDK 17, Xcode OK; missing gdtoolkit, poppler; $GODOT unset.
- Week-1 plan: docs/plans/week-1.md. Nothing to try on a phone yet.
