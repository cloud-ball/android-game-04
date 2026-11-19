# Ship Cup Dash as four themed nines

Cup Dash should be four themed 9-hole courses (36 holes) plus a cheap all-par-3 bonus course, not one nine. Each course should have one dominant "variety axis": width, wind, elevation or water. Each should have one signature hole and a measured difficulty band, and the courses should be played mostly as three-hole legs against a named CPU rival. That shape matches what well-reviewed golf games ship: 9-hole courses and 1-, 3- or 9-hole rounds on mobile, staged courses added in free updates, unlocks earned by play, and rule-modifier events that stretch the same holes further. The new research changes three things in the current plan. First, holes get longer. Scaling real template-hole yardages to the game's 175 m driver gives par 34-36 nines of about 2.2-2.65 km, replacing the par-32, 1.8-2.0 km executive nine. Second, greens get bigger and vary more: about 18-36 m, a Biarritz green up to 60 m deep, and an island green of about 300-360 m² instead of 15 m. Third, the tile kit becomes a parametric `HoleSpec`, one spline-and-stamp text resource per hole. A static `HoleBaker` turns it into the existing `HoleData` grids, and a two-stage validator gates every tee, pin and wind combination. Visual variety is cheap if each theme is a physics preset plus about 15 meshes on one palette atlas, with a fixed brightness ladder for the surfaces so that play reads the same in every theme and for colour-blind players. The build order changes at step 6: the greybox hole is baked from a spec, and the old "nine holes from the kit" step becomes a full Course 1 vertical slice. Course 2 is the launch minimum, and Courses 3-4 and the bonus course follow as content drops. Whether all 36 holes ship at launch should depend on how long one hole takes to author, measured on Course 1.

## Nine-hole courses played three holes at a time are the mobile norm

Shipped golf games vary widely in how many courses they offer, but they agree on the size of a unit of play. A premium-style side-on mobile golf game shipped **20 courses of 9 holes** (about 180 holes), structured as 5 tours of 4 courses ([Common Sense Media](https://www.commonsensemedia.org/app-reviews/super-stickman-golf-3)). An Apple Arcade cartoon golf game offers rounds of **3, 6 or 9 holes** across its themed courses ([SuperPhillip Central](https://www.superphillipcentral.com/2021/04/clap-hanz-golf-ios-review.html)). The top PvP mobile golf game plays a **single hole** per match, which means players are "zipping through your rounds quickly" ([Pocket Gamer](https://www.pocketgamer.com/golf-clash/golf-clash-three-things-to-know-about-the-incredibly-popular-golf-game)). Eighteen holes is mainly a console format. A kart-style party golf game launched with **6 courses of 18 holes and grew to 11 in five months** of free updates. Two of the added courses were all par 3 (par 54) ([Super Mario Wiki](https://www.mariowiki.com/Mario_Golf:_Super_Rush)). Thin rosters get noticed: reviewers called a console arcade golf game's "only five courses out of the box" slim ([Press Start](https://press-start.com.au/reviews/playstation4-reviews/2017/08/29/everybodys-golf-review-old-friend-returns/)).

For a portrait hub game, that points to **9-hole courses, a 3-hole leg as the everyday session, and the full nine as the "round"**. The earlier research already estimated 11-16 minutes for a full nine against a CPU, and that estimate stays (`docs/research/Cup Dash golf game design.md`). A 3-hole leg runs about 3-5 minutes, which suits the hub's best-of-3 habit. Hole count also multiplies cheaply. One small open-source golf game built **an 18-hole course from only two terrain models** by moving tees and pins ([VGA Golf devlog part 2](https://fallahn.itch.io/vga-golf/devlog/349502/creating-your-own-courses-part-2)). A console course designer allows **up to 4 pin positions per hole** ([PGA TOUR 2K25 Course Designer](https://pgatour.2k.com/2k25/up-your-game/course-designer/)). Other games use mirrored courses and rule changes such as no wind or bunkers-as-out-of-bounds as event variety ([SuperPhillip Central](https://www.superphillipcentral.com/2021/04/clap-hanz-golf-ios-review.html)). Thirty-six authored holes with 3 tees and 4 validated pins each give 432 distinct tee-and-pin plays before mirroring or weather. Thirty-six holes is therefore enough content for this game. The risk is not too few holes but holes that feel alike, which the next two sections address.

## The new length scale stretches holes about 20% and revises the par-32 plan

The earlier report kept physics in real metres and made the course short "the way executive courses are". It proposed par 3s of 75-145 m, par 4s of 230-300 m, one 360-400 m par 5, par 32 and about 1.8-2.0 km per nine. The new archetype research anchors lengths differently. The USGA rating model assumes a scratch golfer carries the driver **about 225 yd (206 m) and a bogey golfer about 180 yd (165 m)** ([GOLF.com: how a hole is rated](https://golf.com/?p=15450386)). The game's 175 m driver is therefore about 0.85 of scratch. Multiplying the classic template-hole yardages by k = 0.85 keeps their design intent, such as a Redan that needs a mid-iron or a Cape whose corner sits at driver distance. The result is longer holes than the executive ladder.

| Hole class | Earlier plan (m) | Revised range (m) | What changed and why |
|---|---|---|---|
| Par 3 | 75-145 | **90-185** in four bands: wedge 90-105, short iron 110-135, mid iron 135-160, wood 160-185 | Long templates (Biarritz, long Redan) need wood-length par 3s. Short templates stop working below about 90 m |
| Drivable par 4 | (none) | **190-215** | Within a good driver's carry plus roll (about 175 + 15-40 m). Adds the risk/reward hole players remember |
| Standard par 4 | 230-300 | **255-330** | Driver (about 190 m total) plus a 65-140 m approach. Corners and cross-hazards sit at the driver landing zone |
| Long par 4 | (none) | 330-370, at most one per course | Driver plus long iron. Never on Course 1 |
| Reachable par 5 | 360-400 | **370-420** | Two excellent shots, usually helped downhill or by firm turf, with water in front for the heroic version |
| Three-shot par 5 | (none) | 430-480, at most one per course, never Course 1 | Expensive in session time, so rationed |
| Nine-hole par / length | 32 / 1.8-2.0 km | **34-36 / 2.2-2.65 km**. Bonus all-par-3 course: par 27 / about 1.25 km | Template fidelity and par-3 length variety need more par 4s |
| Green size | 18-30 m; island "small, about 15 m" | **18-36 m by approach club**. Biarritz 20 × 45-60 m. Island about 22-24 × 16-18 m (300-360 m²). 15-25% smaller on the hardest course, 15-25% bigger on the first | The best-known real island green is **about 363 m²** at 137 yd ([GOLF.com](https://golf.com/travel/15-numbers-know-island-green-17th-hole/)). A 15 m island would be harsher than the real thing |

The game's lengths are design inferences, not sourced numbers. The cited inputs are the template yardages and the USGA carry assumptions. The cost of the change is pacing. Going from par 32 to par 35 replaces two par 3s with par 4s, which adds roughly 3-5 strokes per golfer per nine. That is why the revised plan rations three-shot par 5s and makes the 3-hole leg, not the nine, the default session. If playtests show the target player is closer to bogey than scratch, the archetype notes suggest scaling against bogey numbers (k about 1.0 of bogey), which lengthens holes another 5-10%. Do not do that until the measured player dispersion supports it.

Fairway width should come from dispersion, not from taste. USGA-based charts put the width scratch golfers need to hit fairways regularly at **about 32 yd (29 m), and about 40 yd (37 m) for a 20-handicapper** ([Golf Course Industry](https://www.golfcourseindustry.com/article/design-concepts-debating-fairway-widths)). The earlier report's CPU tiers have tee-shot direction SDs of 8.1°, 6.4°, 5.4° and 4.0°. At a 185 m landing those give lateral SDs of about **26, 21, 17.5 and 13 m**. With a straight aim and no curve, a 45 m Course 1 landing zone holds about 61% of Easy, 72% of Medium and 80% of Hard tee shots. A 23 m Course 4 zone holds about 34%, 42%, 49% and 63% (Pro). That spread is what a difficulty ramp should produce, so the proposed width bands (40-50 m down to 20-26 m) are a sound starting point. Re-derive them once the player's swing-timing dispersion is tuned, because that number does not exist yet.

## Every course needs one variety axis, one signature hole and a measured rating

### Twenty-two templates supply the building blocks

The Macdonald/Raynor "template" holes are generic design ideas, not copies of specific courses. GOLF.com lists about 22 of them, from Redan and Biarritz to Cape, Road, Alps and Short ([GOLF.com: template holes](https://golf.com/travel/what-are-template-holes-important-golf-design/)). Each one asks one readable question. A Redan's green is angled about 45° away behind a deep bunker, with a "kicker" bank that feeds balls toward the middle ([The Fried Egg: Redan](https://thefriedegg.com/redan-template-hole/)). A Cape is "the ultimate risk/reward design": the tee shot cuts across a diagonal hazard, and every metre bitten off shortens and improves the approach ([The Fried Egg: Cape](https://thefriedegg.com/cape-template-hole/)). A Road hole "must offer some incentive for trying to reach the green, and punishment for those who stumble" ([Top 100: Road](https://www.top100golfcourses.com/news-item/r-is-for-road-template-holes)). A Biarritz splits a very deep green with a swale **about 1-1.5 m deep** ([Top 100: Biarritz](https://www.top100golfcourses.com/news-item/b-is-for-biarritz-template-holes)). Modern archetypes complete the set. A drivable par 4 is judged a success when **about 60% of players go for it** ([USGA](https://www.usga.org/content/usga/home-page/championships/2016/u-s--amateur-four-ball/articles/drivable-par-4s-add-intrigue-to-match-play-strategy.html)). The others are the reachable par 5 over water, the split fairway, the forced carry with a bail-out, and elevated or blind par 3s. Mirroring adds a second appearance without a repeat: Redan and Reverse Redan, Cape left and right, dogleg left and right. In 36 holes, each core template appears once or twice, and when it repeats it is mirrored or re-themed on a different course.

Two design rules carry over directly into the game. First, a template's intent breaks when its proportions change. Stretching a Short hole with longer tees "all but wip[es] out the template's intent" ([Top 100: Short](https://www.top100golfcourses.com/news-item/s-is-for-short-template-holes)). So the archetype library should fix each template's ratios and let only length vary within its band. Second, these ideas are free to use, but a famous hole's exact outline and landmark are not. Avoid a square island green with a single walkway, or a corner played over a hotel. Every signature hole should use a landmark of the game's own.

### Variety comes from rhythm within a course and from a single axis across courses

Architecture writing asks for holes that vary "in length, difficulty and direction" ([GOLF.com: routing](https://golf.com/travel/what-is-course-routing-architecture/)). Par 3s should test different parts of the bag. A routing should never force a par just to balance the scorecard, and a round needs "sequences of tension and release, thrills and lulls" ([The Fried Egg: GCA 101 part 2](https://thefriedegg.com/golf-course-architecture-101-part-2-routing-variety-naturalness/)). In a game, "direction" can be made learnable. Give each course a prevailing wind and orient each hole relative to it, instead of drawing a uniformly random wind direction per hole. The same heading then plays the same way every visit. The per-course checklist the baker validates is:

| Check | Rule |
|---|---|
| Par-3 lengths | At least two different bands per course (three from Course 2 on) |
| Consecutive holes | No two in a row of the same par within 20 m of each other |
| Wind headings | At least three of the four headings relative to the prevailing wind |
| Doglegs | Both dogleg directions present |
| Greens | A different green archetype on every hole |
| Penal holes | At most two, never back to back |
| Release holes | A release hole after every penal or long hole |
| Memorable slots | Slots 6 and 9 are signature or climax holes |

Across courses, give each one a dominant axis, so that the courses differ from one another and not just hole to hole. Course 1 varies width and forgiving greens. Course 2 varies wind and the ground game. Course 3 varies elevation, blind shots and carries. Course 4 varies water and precision. The best-reviewed console line-up works the same way. Each course has one signature hazard: wind with tornadoes, quicksand, rainstorms, blizzards, walls to bank shots off. The courses run from a rookie course to a finale full of hazards ([Super Mario Wiki](https://www.mariowiki.com/Mario_Golf:_Super_Rush)).

### Rate holes the USGA way, using the CPU as the golfers

USGA Course Rating rates every hole twice, for a scratch and a bogey golfer. Each rating combines effective playing length with ten obstacle factors scored 0-10 at each golfer's landing zones. Slope comes from the gap between the two ratings (5.381 × (Bogey − Course Rating) for men) ([USGA Appendix G](https://www.usga.org/content/usga/home-page/handicapping/roh/Content/rules/Appendix%20G%20Golf%20Course%20CourseRatingSlopeRating.htm)). Forced carries widen that gap because weaker golfers hit shorter ([GOLF.com](https://golf.com/?p=15450386)). Cup Dash already has the tools to measure this instead of estimating it. A "simulated golfer" model computes expected strokes from every grid point using **50-200 dispersion samples per point**. It found water costs a 5-handicap about 1 stroke and a greenside bunker about 0.5 ([Golf Course Wiki](https://golfcoursewiki.substack.com/p/i-spent-the-last-month-and-a-half)). The game's version is to run the Easy and Hard CPU profiles headlessly over seeded rounds. "Rating" is the Hard tier's stroke average and "slope" is the Easy minus Hard gap. A hole with a big gap is a forced-carry hole that punishes beginners. A hole where both tiers score near par is a release hole. The numbers go into the course's ramp checks and its star thresholds (see the progression section).

The ramp needs care at both ends. One mobile career golf game lost a review star because its **final course was too hard** ([App Store: Pixel Pro Golf](https://apps.apple.com/au/app/pixel-pro-golf/id1534171570)). A CPU that is too easy flattens the curve from the other side: one game's CPU often hit errant shots, and late tournaments didn't demand high scores ([SuperPhillip Central](https://www.superphillipcentral.com/2021/04/clap-hanz-golf-ios-review.html)). The plan below therefore makes Course 4 harder through precision rather than length (it is shorter than Course 3), makes the extra course a short-hole bonus rather than a harder finale, and keeps the fixed-profile, no-rubber-banding CPU from the earlier report.

## Themes are physics presets plus a fifteen-mesh visual kit

### Real course types already map onto the solver's levers

Real course types differ along exactly the axes the solver exposes. Links golf is shaped by wind and firm ground, where low shots "bounce for days", bunkers are deep and shots are often blind. Desert courses have "an abnormal amount of forced carries", and anything off the fairway is waste ground. Mountain courses test uphill, downhill and sidehill lies over ravines ([GolfPass](https://www.golfpass.com/travel-advisor/articles/most-difficult-golf-courses-to-play-links-heathland-parkland-mountain-desert)). Altitude adds carry: Titleist measured **about 1.2% more carry per 1,000 ft of elevation** ([Titleist](https://www.titleist.com/teamtitleist/gb/b/weblog/posts/the-effect-of-altitude-on-golf-ball-performance)). So a theme is a `CoursePreset` (wind range and prevailing direction, Stimp, fairway firmness, rough factor, air density) plus a visual kit. Surface IDs stay physics and never change meaning between themes. Desert hardpan is still `ROUGH` with desert tuning, and waste bunkers are `SAND` or `OUT`. The current nine-value `Surface` enum is therefore enough.

Two physics consequences follow, and neither appears in the notes. First, altitude should be done physically, by lowering `GolfParams.air_density` for the high-altitude course and calibrating it with a test against the 1.2%-per-1,000-ft figure, not with a carry multiplier. `re_per_speed` must scale with density too, because Reynolds number is proportional to ρ. Otherwise the drag-crisis curve shifts the wrong way. Second, green speed changes how steep a green can be. In the current roll model, a ball at rest stays put while (5/7)·g·sin θ is below the rolling deceleration a = v0²/(2·Stimp). The steepest grade a ball can rest on is then about **9.8% at Stimp 8, 7.9% at Stimp 10, 7.1% at Stimp 11 and 6.5% at Stimp 12**. The baker's "shoulder" and "shedding ramp" rules must be computed from each course's Stimp, not hard-coded at 8% and 9%. Otherwise a Course 4 shoulder designed to hold balls will shed them. The real-world pin-area guidance falls the same way, from about 3% down to **about 2.9% at Stimp 14** ([Golf Course Industry](https://www.golfcourseindustry.com/news/the-fine-line-of-fair-competition)).

### Brightness carries readability; hue carries mood

Golf depends on the green/grey/brown colour pairs that colour-vision-deficient players find hardest ([Smashing Magazine](https://smashingmagazine.com/2016/06/improving-ux-for-color-blind-users)). Orange balls can be **impossible to see against grass** for colour-blind players ([Colour Blind Awareness](https://www.colourblindawareness.org/colour-blindness/living-with-colour-vision-deficiency/sport/)). One disc-golf map solved the problem of grass and grey paths looking alike by drawing white dashed edge lines ([discgolf.com](https://discgolf.com/?p=95198)). The art direction should split into two layers. The **gameplay layer** is shared by every theme. It fixes one brightness step per surface, darkest to lightest: water (with a light foam rim), then trees and deep rough, rough, fairway, green, and sand lightest. It also adds a thin light outline at fairway and green edges, a white ball with a dark ring and a trail, and identical aim and landing UI colours. The **mood layer** belongs to each theme: sky gradient, fog colour, far terrain, tree and prop tint, sun angle. Choose the gameplay values in greyscale first, then check the autumn and desert palettes in a CVD simulator, since they put red and brown next to green. In portrait, the sky and backdrop fill much of the behind-the-ball view. A distinctive skyline silhouette (sea cliffs, mesas, a volcano, peaks) therefore does most of the "this is a different course" work, and art effort belongs there rather than on ground detail too small to see.

### One material, explicit MultiMesh, and about 15 meshes per theme

The Mobile renderer shapes the recipe. **Automatic instancing exists only in Forward+**, so repeated objects on Mobile must use MultiMesh explicitly, and alpha-blended materials are never instanced ([Godot 4.7: optimizing 3D](https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html)). The Mobile renderer supports depth and height fog, decals, glow and LightmapGI. It does not support volumetric fog, SSAO, SSR or SDFGI ([Godot 4.7: renderers](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)). Material changes are among the costliest rendering operations, and a palette atlas lets a whole prop set share **one material and one draw call** ([itch.io devlog](https://itch.io/devlog/73530/blazing-fast-rendering-with-a-single-material-per-scene.amp); [Dynamic Color Palette](https://fwdotcom.itch.io/dynamic-color-palette)).

Each theme therefore gets the following. The terrain uses the shared shader, which reads `HoleData.surface` as an R8 texture and takes per-theme colour uniforms, so the player sees exactly what the solver reads. Vegetation is 2-3 species and props are 3-6 rocks or props, at 100-600 triangles each, all on one 256-512 px palette atlas. They are drawn as one MultiMesh per species per 64 m area chunk, because MultiMesh culls all-or-nothing ([Godot: MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)). On top of that come one backdrop ring mesh, one hero landmark, a gradient sky, and fog in the horizon colour, which also hides LOD pops. Beyond about 15 unique meshes a theme gains memory cost, not identity. That figure is an estimate, since no shipped game publishes one. CC0 packs from Kenney ([Kenney support](https://www.kenney.nl/support)) and Quaternius ([Quaternius FAQ](https://quaternius.com/faq.html)) are legitimate starting points. Recolour them onto the game's own atlas so the courses look original and consistent, and record each one in ASSETS.md through the asset-wrangler workflow. Night, autumn and snow variants reuse the same height grid with a new palette, sky and light: the cheapest "new map" available.

Published budgets for mobile draw calls conflict. Arm suggests about 500 per frame ([Arm community](https://community.arm.com/support-forums/f/graphics-gaming-and-vr-forum/9238/draw-call-performance-on-the-mali-t880-mp12/30499)), while Unity's older guide says "a few hundred" ([Unity Manual](https://docs.unity3d.com/2017.3/Documentation/Manual/MobileOptimisation.html)). The plan's ceiling of 100 draw calls is conservative and stays. Triangles are the real constraint. A 320 m par 4 rendered 1:1 at the grid's 0.5 m cells is about 205,000 triangles: the whole budget for one hole. The earlier report's working target of 150-250k should drop to about **100-150k at 60 fps on mid-range and about 60k on the low-end tier** (unsourced, to be profiled). That requires chunked terrain with visibility-range HLOD, covered in the pipeline section.

## Unlock by playing, never by grinding or wagering

Reviews show what to avoid. A rank ladder held one reviewer on the **first course after about 15 hours** and was called "slightly too grindy" ([Well Played](https://www.well-played.com.au/everybodys-golf-review/); [Destructoid](https://vip-develop.destructoid.com/?p=204364)). A mini-golf battler that makes players replay the same courses to level up was flagged as frustrating and pay-to-win ([Common Sense Media](https://www.commonsensemedia.org/app-reviews/golf-battle)). Coin-entry wagers draw "gamble for coins" complaints and fit an offline game poorly. On the positive side, one game unlocks each course **either** through story progress **or** by finishing the previous course in free play ([Super Mario Wiki](https://www.mariowiki.com/Mario_Golf:_Super_Rush)). Beating a single CPU in match play recruits that golfer as a character, and Score Attack ranks of up to 5 points per course unlock cosmetics ([SuperPhillip Central](https://www.superphillipcentral.com/2021/04/clap-hanz-golf-ios-review.html)). Reviewers have also praised permanent unlocks earned by play ([TouchArcade](https://toucharcade.com/?p=198208)). One more lesson: prize money that buys stat gear becomes **worthless once the best gear is bought** ([App Store: Pixel Pro Golf](https://apps.apple.com/au/app/pixel-pro-golf/id1534171570)). The hub's GDD already rules out energy timers and loot boxes and spends coins on cosmetics such as ball trails, so Cup Dash should spend coins on looks and variants, never on distance or accuracy.

One gap matters here. None of the sources describes an offline daily challenge in golf; the dailies found depend on online leaderboards. The repo already has `core/daily_challenge.gd`, a UTC-day rotation across enabled games, so the golf daily plugs in as new entries rather than a new system. A local date-seeded "Daily Three" (three holes, with tee, pin and wind from `core/Rng.gd`, one scored attempt per day and a local streak) adapts the "one attempt per day" hook without a server. Rule-modifier weeks (storm wind, calm, mirrored, sand-is-out-of-bounds) come from the same seed by ISO week. They are the strongest "more from the same holes" lever in the evidence.

## A parametric spec, a static baker and a two-stage validator scale to 36 holes

Shipped course tools share one shape: a parametric description, a raster bake into a heightfield plus surface masks, non-destructive tweaks, then playtesting. The AAA example converted scans into heightfield maps and masks and edited them non-destructively, which "saved weeks" ([EA](https://www.ea.com/news/procedural-terrain-in-ea-sports-pga-tour)). The console designer builds holes from routing waypoints, splined or brushed surfaces, and stamped bunkers with depth, lip depth and lip steepness ([PGA TOUR 2K25](https://pgatour.2k.com/2k25/up-your-game/course-designer/)). Its auto-generated courses were judged "generally really badly designed" ([Game Rant](https://gamerant.com/pga-2k21-design-course-guide/)). That is the warning against shipping unconstrained generation. `HoleData` is already the raster end of this pipeline. What is missing is the layer above it.

This research revises the earlier report's "tiles in the editor" authoring layer. A `HoleSpec` text resource, a few kB per hole, describes:

| Spec part | Contents |
|---|---|
| Route | Centre-line route of 3-6 points, with stations along it (distance, left and right half-width, elevation, cross-slope) |
| Tees | 2-3 tee boxes |
| Green | A superellipse with base tilt, tiers and Gaussian bumps |
| Hazards | Bunker stamps, water polygons with declared drop zones |
| Extras | Mounds, paths, bounds, scatter zones, a seed |

It is diffable, reviewable and well suited to an AI assistant writing it. A static `HoleBaker` rasterises it deterministically:

| Bake stage | What it does |
|---|---|
| Surfaces | Signed-distance tests per cell, in a fixed priority order (OUT, ROUGH, FAIRWAY, PATH, FRINGE, GREEN, TEE, SAND, WATER), so overlapping shapes can never be ambiguous |
| Heights | Station elevation plus low-frequency seeded noise plus mounds. Greens, tees, bunkers and water blend in with smoothstep |
| Smoothing | 2-4 masked smoothing passes, then the exact green and tee surfaces are re-applied |
| Pins | Cup zones detected automatically, where the maximum gradient within 1.5 m is 3% or less. A green with fewer than 4 distinct pins is rejected |

The baker must be a class of **static functions**. Every script a `@tool` script calls must itself be `@tool`, except static methods, and static variables read from non-tool scripts return null ([Godot: running code in the editor](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html)). Static functions keep the baker pure, usable from the editor and testable headless, as CLAUDE.md requires. An archetype library (`cape()`, `redan()`, `biarritz()` and so on) proposes specs. It places stamps relative to landing stations (driver total about 190 m; bold line about 165-175 m of carry, safe line about 120-140 m), not at absolute coordinates. Two or three signature holes per course are written by hand. The remaining holes are generated, then edited.

The validator has to be cheap or it will not get run, and the obvious design is too slow. The full CPU planner takes about a second per shot on the phone (earlier report). Validating 3 tiers × 3 tees × 4 pins × 3 wind buckets × 64 plays × about 5 shots is about 35,000 planned shots per hole. Even at 0.1 s per shot on desktop, that is about an hour per hole and **about 35 hours for 36 holes** (an estimate). So split it in two. Stage one is structural checks on the baked grid, taking milliseconds per hole on every test run:

| Structural check | Rule |
|---|---|
| Determinism | Golden hash per hole |
| Tees | Flat (≤1%) and at least 4 × 3 m |
| Greens | A fringe ring all round. No cell steeper than the course's Stimp-derived at-rest grade unless tagged as a shedding ramp |
| Fairways | Landing-zone width at least the course minimum at each driver station |
| Traps | No basins deeper than 0.3 m outside green, sand and water |
| Carries | Every forced carry within the Easy tier's reliable carry, or with a fairway bail-out |
| Water | A drop zone for every water polygon |

Stage two is Monte Carlo playability with a "validator golfer": the tier dispersions with a lookup-table aim (pin, green centre, lay-up point) and no inner planning loop, at 32-64 plays per combination, tagged slow. The full planner runs only in a nightly or on-demand rating pass that writes the per-hole rating and slope CSV. Two numbers remain unmeasured and should become in-repo benchmarks recorded in `docs/PROGRESS.md`: GDScript bake time (estimated at low seconds per hole) and validator-golfer cost.

Memory and rendering numbers follow from the 0.5 m cell size the code uses. The earlier report's "1 m cells, 0.25 m on greens, 77 kB" was never implemented. An 80 × 320 m par 4 is 103,201 float heights (413 kB) plus 102 kB of surface bytes, about **0.5 MB per hole**, so 36 holes come to about 18-25 MB uncompressed in the pack. Only one hole is ever resident. Quantise heights to uint16 centimetres at bake time and dequantise identically on load: that halves the size and stays deterministic. It also avoids the solver change that mixed-resolution layers would need. Render the terrain as 32 × 32-cell chunks (2,048 triangles each) sharing one index buffer, with full resolution near the camera and the green and 2× or 4× decimated chunks beyond, switched by `visibility_range` HLOD. Normals come from analytic central differences so chunk seams match. Skip chunks that are fully OUT and hidden behind trees. Scatter is generated at bake time from the seeded Rng and stored in `HoleData`. The solver's tree cylinders and the rendered MultiMesh trees then come from the same list.

## Recommendations

### Course line-up

The four main courses ramp one axis each. The bonus course is an all-par-3 alpine nine, deliberately short and fun rather than the hardest. Lengths are tee-to-green design starting points for the middle tee, to be retuned by self-play. Schools: S = strategic, P = penal, H = heroic, F = fun or release.

| | 1 · Meadow Run (parkland) | 2 · Saltwind Links (coastal) | 3 · Red Mesa (canyon desert) | 4 · Ember Lagoon (volcanic tropical) | Bonus · Summit Shorts (alpine, all par 3) |
|---|---|---|---|---|---|
| Variety axis | Width, forgiving greens | Wind, ground game | Elevation, carries, blind shots | Water, precision | Plays-like distance, elevation |
| Par / length | 35 / about 2,270 m | 34 / about 2,365 m | 35 / about 2,545 m | 35 / about 2,490 m (shorter than 3 on purpose) | 27 / about 1,250 m |
| Wind (prevailing ± 45°) | 0-3 m/s | 3-7 m/s | 2-5 m/s | 3-8 m/s | 1-6 m/s, gusty between shots |
| Green speed | Stimp 8-9 | Stimp 10, firm | Stimp 10 | Stimp 11 | Stimp 11 |
| Fairway firmness | Soft, greens hold | Firm, long roll-out | Firm; off-fairway is waste | Soft, greens hold | Medium |
| Air density | Sea level | Sea level | Sea level | Sea level | Lowered to about 1,500 m altitude (calibrated by test) |
| Landing width | 40-50 m | 32-40 m | 26-32 m | 20-26 m | (par 3s) |
| Approach greens | 28-36 m | 24-30 m | 20-26 m | 16-22 m (island about 22) | 20-30 m |
| Max cup-zone slope | 1.5% | 2% | 2.5% | 3% | 2.5% |
| Forced carries from middle tee | 0 (always a bail-out) | 1 short (≤110 m) | 2, with bail-outs | 3 or more, one all-or-nothing | Several, all with bail-out platforms |
| Penal / blind holes | 0 / 0 | 1 / 0 | 1-2 / 1-2 (with aim marker) | 2 / 1 | 1 / 1 |
| Easy-CPU target over par | +4 to +6 | +6 to +9 | +8 to +12 | +10 to +15 | +3 to +6 |
| Skyline and landmark | Rolling hills; a wooden windmill-style tower | Sea cliffs; a striped beacon tower | Mesas; a natural rock arch | Smoking volcano; a waterfall | Snow peaks; a cable-car pylon |

The course names are working titles. They should be checked by `ip-checker` and finalised in `manifest.tres`-style data.

| # | Meadow Run | Saltwind Links | Red Mesa | Ember Lagoon | Summit Shorts |
|---|---|---|---|---|---|
| 1 | P4 280 wide opener (F) | P4 250 Sahara: carry the waste, run it up (S) | P4 270 forced carry with a long bail-out (H) | P4 300 Cape around the lagoon (H/S) | P3 95 wedge to a wide green (F) |
| 2 | P3 100 Short, hump in the green (S) | P3 150 Redan with a kicker bank (S) | P3 175 downhill from the rim, plays about 150 (F) | P3 180 Biarritz, swale pins (S) | P3 140 Redan (S) |
| 3 | P4 290 dogleg right, corner bunker (S) | P4 290 Leven diagonal burn (S) | P4 300 Alps blind approach to a punchbowl (S) | P4 320 Bottle with a water neck (S) | P3 175 downhill, plays about 150 (F) |
| 4 | P5 390 reachable, cross bunkers, no water (H-lite) | P4 300 Bottle pinch at 170 m (S) | P3 150 Reverse Redan (S) | P4 205 drivable to a near-island green (H) | P3 115 Short, ringed by sand (P) |
| 5 | P4 260 punchbowl (F) | P5 440 three-shot links, running approach (S) | P5 400 reachable down the canyon (H) | P4 280 punchbowl release (F) | P3 160 Biarritz on a shelf (S) |
| 6 | **Signature**: P3 140 hilltop tee over a pond, wide bail-out (F/H) | **Signature**: P4 310 cliff-edge Cape past the beacon (H) | **Signature**: P4 330 Road-style, drive over the rock arch (H) | **Signature**: P3 105 organic island green, waterfall backdrop (P) | P3 125 Dell-style blind, marker on the ridge (S) |
| 7 | P4 200 drivable, wide lay-up (H) | P3 130 Eden into the wind (P) | P3 120 blind Dell-style with marker (S) | P4 360 long, lagoon down one side (S) | P3 185 long Redan, wood (S) |
| 8 | P4 310 split fairway (S) | P4 320 Double Plateau (S) | P4 340 dogleg left round a ravine (S) | P4 330 Double Plateau with false fronts (S) | P3 105 punchbowl hollow (F) |
| 9 | P4 300 dogleg left to a gentle plateau (S) | P3 175 Biarritz home into the sea wind (S/H) | P5 460 three-shot, split route (S) | **Finisher**: P5 410 reachable over the lagoon (H) | **Signature**: P3 150 cliff-to-cliff carry with a lower bail-out ledge (H) |

Red Mesa's holes 2 and 4 were adjusted from the archetype notes' 165 m and 160 m to 175 m (downhill) and 150 m, so its par 3s span three bands. Meadow Run keeps only two par 3s on purpose, as the gentlest nine. Every course keeps at least one release hole straight after each penal or long hole.

### Progression and modes

| Element | Design |
|---|---|
| Course unlock (dual route) | Course N+1 opens when the player **wins 2 of the 3 rival legs** (holes 1-3, 4-6, 7-9) on Course N at any tier, **or** finishes any full nine there. Course 2 is therefore reachable in the first session, after about 10 minutes |
| Rival | Each course has an original named CPU rival with a style (steady, aggressive, bomber, precise), all built on the shared tier profiles. Beat the rival on Medium to unlock that course's mirrored layout. Beat all four on Hard to unlock the Pro tier |
| Stars (Score Attack, 9 holes solo) | Thresholds come from measured self-play, not par: 1★ beats the Easy-CPU mean, 2★ the Medium mean, 3★ the Hard mean (stored in `CourseSpec`, re-measured when holes change). This keeps difficulty consistent across courses automatically |
| Per-hole trophies | Par, birdie and eagle medals, plus ace flags and best score, on a trophy shelf per course |
| Pro tees | Back tees per course unlock at 3★ on that course |
| Bonus course | Opens after finishing Course 2 or earning 6★ in total. Optional, never required |
| Championship | Opens after Course 4: 36 holes across all four nines, played over saved sessions. Only the rival plays visibly. The rest of the "field" is sampled from per-hole score distributions measured in self-play, which costs nothing at run time |
| Modes per course | Match (3-hole legs or 9-hole match play vs the rival), Round (9-hole stroke play vs the rival plus the sampled field), Score Attack, and one skill challenge themed to the course: closest-to-pin on Meadow's signature hole, long drive on Saltwind, target landing on Red Mesa, a putting ladder on Ember Lagoon |
| Daily and weekly | Daily Three (date-seeded, from unlocked courses only, one scored attempt, local streak), registered in `core/daily_challenge.gd`. Weekly rule event (storm, calm, mirror, sand-is-out-of-bounds) seeded by ISO week |
| Coins | Earned per hole and per leg. Spent only on cosmetics (ball trails, flags, tee markers) and theme palette variants such as night and autumn. Never on stats. No wagers |
| Session safety | Save after every hole. A round or championship resumes at the next hole |
| Save | `SaveService.games["golf"]` moves to schema 2 with `migrate()` from 1. It stores per course: unlocked, legs won per tier, best nine, stars, Pro tees and mirror flags. It stores per hole: best score, medal, ace. It also stores the daily streak and the weekly-event best |

### Pipeline plan on the existing code

| Piece | Location | Role and fit with existing code |
|---|---|---|
| `GolfParams` (extend) | `logic/golf_params.gd` | Add a `SurfaceTable` (e, μ, β, roll deceleration per `HoleData.Surface`) and `apply_preset(CoursePreset)`. The preset scales `air_density` and `re_per_speed` together. Aero curves are unchanged |
| `CoursePreset` | `logic/course_preset.gd` | Pure resource: wind min/max, prevailing direction, direction jitter, Stimp, fairway firmness, rough factor, air density. Also `max_rest_grade()`, derived from Stimp for the baker and validator |
| `HoleSpec`, `GreenSpec`, `Stamp` | `logic/hole_spec.gd` | Authoring data saved as `.tres` in `data/specs/<course>/hole_<n>.tres` |
| `ArchetypeLib` | `logic/archetype_lib.gd` | Static functions that propose a `HoleSpec` from (archetype, par, length, mirror, theme, seed), placing stamps relative to landing stations |
| `HoleBaker` | `logic/hole_baker.gd` | Static `bake(spec, preset) -> HoleData`. Deterministic SDF rasterisation, masked smoothing, cup-zone detection, seeded scatter, uint16 height quantisation |
| `HoleData` (extend) | `logic/hole_data.gd` | Keep the grid, sampler and `sweep()` unchanged. Add `tees`/`pins` arrays, drop zones, a `trees` array (PackedVector4Array of x, y, z, radius) and `hole_id`. `tee`/`pin` stay as the active selection, so existing tests still pass |
| `HoleValidator` + `PlayabilitySim` | `logic/` | Structural checks (fast) and validator-golfer Monte Carlo (slow tag). Writes per-hole metrics to CSV, in the style of the `physics-tune` skill |
| `CourseSpec` | `data/courses/<id>.tres` | Display name, theme kit, preset, 9 spec references, par, star thresholds, per-course `enabled` flag (unfinished courses stay hidden, like games in `manifest.tres`) |
| `ThemeKit` | `scenes/themes/<id>.tres` | Scene-side: terrain uniforms, sky gradient, fog, palette row, vegetation and prop meshes, backdrop ring, landmark scene |
| `TerrainBuilder`, `ScatterRenderer` | `scenes/` | Chunked ArrayMesh with HLOD, R8 surface texture, MultiMesh per species per chunk |
| Bake tool and tests | `tools/bake_golf_holes.gd` (EditorScript) and `tests/` | Writes `data/holes/<course>/<n>.res` plus a PNG preview. A test rebakes every spec and compares golden hashes |
| Dev args | `golf_game.gd` | `--course=<id> --hole=<n> --tee=<k> --pin=<k>`, used with the `shot` skill for per-hole screenshots |

### Updated build order

Steps 1-3 are done (scaffold, flight, `HoleData` and swept contact). Under CLAUDE.md, this change touches more than three files, so it needs its own plan document (`docs/plans/2026-11-xx-cup-dash-courses.md`) before step 6.

| Step | Deliverable | Gate |
|---|---|---|
| 4 | Bounce, roll, rest, cup, water and OB state machine. `SurfaceTable` and `CoursePreset` in `GolfParams`, Stimp-derived rest grade | Earlier gates, plus rest-on-slope tests at Stimp 8, 10 and 11 matching the derived grades |
| 5 | `--bench=golf` on the test phone | µs per substep and ms per rollout measured. Choose 240 vs 120 Hz |
| 6 | **Revised:** `HoleSpec`, `HoleBaker`, structural validator and golden hashes. One greybox hole **baked from a spec**, chunked terrain and shader, ball, camera, swing, landing marker | Bake time benchmarked. Structural checks green. `shot` screenshots. No interpolation smear |
| 7 | Putting, slope grid, wind HUD (prevailing-wind aware), how-to cards | Feel playtest (still the mini-golf fallback) |
| 8 | CPU putting, then the full planner and tier profiles. **Added:** validator golfer and the rating/slope self-play harness | About 70/50/30% win rates. Rating CSV produced for the greybox hole |
| 9 | **Revised:** Course 1 Meadow Run vertical slice: `ArchetypeLib` for its archetypes, 9 specs, theme kit 1, Monte Carlo validator, seeded tees, pins and wind | Validator green for every tee × pin × wind combination. Easy-CPU +4 to +6. **Measure the hours per finished hole** |
| 10 | Modes, legs, rivals, stars, save schema 2 + `migrate()`, daily entry, accessibility, quality tiers, performance pass | 60 fps mid-range, 30 fps floor. `ip-checker` and `physics-reviewer` pass |
| 11 | Course 2 Saltwind Links (firm-turf preset, wind tuning, theme kit 2). **Launch gate:** enable the game in the manifest with Courses 1-2 | Validator and ramp checks. Courses 1-2 ordered correctly by rating |
| 12 | Courses 3-4 (Red Mesa, Ember Lagoon) behind per-course flags | Same, plus the per-course mean-difficulty spread check |
| 13 | Summit Shorts, mirrored and Pro-tee variants, night and autumn palettes, weekly events, championship | Validator rerun on mirrored holes. Pack size and VRAM within budget |

Whether Courses 3-4 ship at launch or as the first free update should depend on the hours per hole measured in step 9. If a finished, validated, screenshotted hole takes about half a day or less after Course 1, all four courses fit before launch. If not, ship two courses and follow the pattern of the best-reviewed games: courses added in free updates.

## Conclusion

Thirty-six holes is not a content problem but a validation problem. The parametric spec makes holes cheap to write. What makes them trustworthy is the deterministic solver: the same code that flies the ball also rates every hole, sets the star thresholds, simulates the championship field and catches unplayable pins. The decision that matters most is therefore not the theme list but splitting validation into fast structural checks and a cheap validator golfer, because the obvious design (run the real CPU on every combination) costs about 35 hours per full rebake and would quietly stop being run.

Two findings were not in either set of notes but follow from combining them with the code. Green speed is a design constraint, not a display setting: going from Stimp 10 to 11 cuts the steepest grade a ball can rest on from about 7.9% to 7.1%, so a green copied from Course 1 to Course 4 can become unplayable without any visible change. And altitude has to scale the Reynolds number along with air density, or the drag-crisis curve shifts the wrong way. Both are cheap to test and expensive to discover on a phone.
