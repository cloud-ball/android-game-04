# Compact Modular Hole Design for a 9-Hole Mobile Golf Course (Fairway Flick)

Scope: practical guidance and numbers for building 9 short, readable, varied holes from reusable modules (tee, fairway, rough, bunker, water, sloped green, trees/obstacles) for an ORIGINAL portrait Android game (Godot 4.7, offline vs CPU). Commercial games are named only as sources. Research date: 2026-11-14. Unit note: 1 yd = 0.9144 m (conversions below are mine).

---

## 1. How should hole lengths scale, and what shot count / par mix gives good pacing?

### Takeaway
Real par is "reach the green in regulation + 2 putts" with USGA bands of par 3 < 260 yd (~238 m), par 4 240-490 yd (~219-448 m), par 5 450-710 yd (~411-649 m). Short formats (executive, par-3, pitch-and-putt) shrink this to holes of 40-90 m (pitch-and-putt) or 90-165 m par 3s plus a few 255-320 m par 4s (executive), with par-3s dominating; a 9-hole executive scorecard is typically par ~29-32. No official numbers were found for how commercial mobile golf games scale distances, so a game should define its own compressed "club ladder" and derive hole lengths from it.

### Cited Findings
- Par is calculated assuming a proficient golfer reaches the green in a regulation number of strokes (based on average driving distance) and then takes two putts; holes are generally par 3-5. Effective length can be adjusted for altitude, significant uphill/downhill, or forced lay-ups before water. — [Wikipedia: Par (golf)](https://en.wikipedia.org/wiki/Par_(golf))
- USGA yardage guidelines (men / women): par 3 under 260 / under 220 yd; par 4 240-490 / 200-420 yd; par 5 450-710 / 370-600 yd; par 6 over 670 / over 570 yd. — [Wikipedia: Par (golf)](https://en.wikipedia.org/wiki/Par_(golf))
- Executive courses: an 18-hole executive course is roughly 3,500-5,000 yd (a 9-hole about half that) versus 6,000-7,200+ yd for regulation; par 3s dominate, with a few par 4s around 280-350 yd and par 3s of 100-180 yd, occasionally a very short par 5. — [CaddieHQ: What is an executive-length course](https://www.caddiehq.com/resources/what-is-an-executive-length-golf-course); [GolfLink: What is an Executive Course?](https://golflink.com/lifestyle/what-is-an-executive-course)
- Example scorecards: Executive Meadows is 9 holes, par 29, mostly par 3s; Holiday Park Executive (18 holes) is par 68. Executive scorecards range from ~70 to 300 yd for par 3s and up to ~400 yd for some par 4s. — [GolfPass: Executive Meadows](https://www.golfpass.com/courses/12564-executive-meadows-golf-course/scorecard-and-layout); [GolfPass: Holiday Park Executive](https://www.golfpass.com/courses/28539-holiday-park-golf-course-executive/scorecard-and-layout)
- Pitch and putt (international, FIPPA): hole maximum 90 m, 18-hole course maximum 1,200 m, maximum 3 clubs (one a putter). European figures of 40-90 m per hole are accepted for international competitions. — [FIPPA: International Pitch and Putt Defined](https://fippa.org/pages/pitch_and_putt); [FIPPA Rules 2014 (PDF)](https://fippa.org/uploads/news/files/Rules_FIPPA_2014.pdf); [Wikipedia: Pitch and putt](https://en.wikipedia.org/wiki/Pitch_and_putt)
- Conflicting national figure: Pitch and Putt Ireland's 2025 constitution sets a 70 m maximum tee-to-green and 1,000 m per 18 holes. — [Irish Pitch and Putt Union 2025 constitution (PDF)](https://www.irishpitchandputt.ie/media/2025-constitution.pdf)
- Real amateur distances (for a believable club ladder): average amateur 7-iron ~155 yd (~142 m) per Shot Scope 2026 data (scratch ~178 yd, 25-hcp ~132 yd); average male amateur driver ~224.7 yd (~205 m, Arccos); average amateur pitching wedge ~118 yd (~108 m). Sources disagree on carry vs total. — [Golf Monthly: 7-iron 2026](https://www.golfmonthly.com/features/average-amateur-golfer-distance-7-iron-2026); [Golf Monthly: pitching wedge 2026](https://www.golfmonthly.com/features/how-far-amateur-golfer-hit-pitching-wedge-2026); [National Club Golfer: club distances](https://www.nationalclubgolfer.com/golf-tips/long-game/golf-club-distances/)
- Mobile golf (Golf Clash, community-sourced, not official): club accuracy controls wind "ring" size; players build charts with min/mid/max distances per club. No official per-club distance data found. — [West Games: Golf Clash rings](https://west-games.com/golf-clash-how-to-use-the-rings/); [Clash Caddie app listing](https://apps.apple.com/us/app/id1388535114)

### Inferences
- Because par = regulation shots + 2 putts, the cleanest way to scale is to define the game's own club ladder first (e.g. 4-5 clubs), then set hole lengths as multiples of it. A compact game does not need real-world metres; it needs consistent ratios (driver ~1.45x the 7-iron, wedge ~0.75x the 7-iron, per the amateur averages above).
- Suggested "compressed" target (my proposal, not sourced): treat the world as real-scale but play a short format, or keep real club ratios and scale everything by ~0.4-0.5. Example ladder at ~0.45x: Driver ~90-95 m, Wood/Hybrid ~75 m, Iron ~62 m, Wedge ~45 m (full) with partial power down to ~10 m, Putter on green. Hole lengths: par 3 = 40-80 m (one iron/wedge), par 4 = 110-160 m (driver + wedge/iron), par 5 = 170-210 m (two good shots to reach = risk/reward). This roughly mirrors pitch-and-putt (40-90 m holes) for par 3s and executive par 4s scaled by ~0.45.
- Par mix for 9 holes, borrowed from executive courses: something like 4x par 3, 4x par 4, 1x par 5 (par 32), or 5x par 3 + 3x par 4 + 1x par 5 (par 31) for a shorter session. Executive Meadows' par 29 shows mostly-par-3 nines are standard.
- Shot pacing estimate: at par 31-32 a casual player at +1 per hole takes ~40 strokes per 9; at ~8-12 s per shot (aim + flight + settle), a 9-hole round is ~6-8 minutes of play. Keep par 4s to two full shots so no hole needs more than ~5 strokes for an average player.

### Gaps
- I found no official or developer-published numbers on how mobile/arcade golf games (e.g. Golf Clash, Golf Rival, Golf King) scale hole yardages or how many shots per match they target; only community wind charts exist. The shot/minute estimates above are my own.
- No published data on ideal casual-game round length for golf specifically.

---

## 2. Which architecture principles matter at small scale (strategic vs penal, risk/reward, landing zones, variety)?

### Takeaway
Use the three classic "schools": penal (miss = punished, e.g. island green), strategic (multiple routes, hazard near the ideal line buys a better angle), heroic (optional bold carry for a big reward). A compact course should be mostly strategic with 1-2 penal and 1-2 heroic holes, and should add difficulty through hazard placement and angles rather than length.

### Cited Findings
- Penal holes offer few options and punish a missed shot with no recovery; example is the island-green 17th at TPC Sawgrass. "A few penal holes add drama, but too many become boring." — [GOLF.com: 3 schools of golf course architecture](https://golf.com/travel/3-schools-golf-course-architecture/)
- Strategic holes give several ways to attack with no clear best route; the safe route is usually longer or worse for scoring. "The closer you are willing to come to this hazard without missing your target... the better angle of attack you will have for your next shot." Strategic holes are more playable for high handicappers but still challenge low handicappers. — [GOLF.com](https://golf.com/travel/3-schools-golf-course-architecture/)
- Heroic holes blend penal and strategic: an optional high-risk shot for bigger reward with severe miss penalty. "The further you are willing to carry the water, the shorter the yardage for your approach shot." — [GOLF.com](https://golf.com/travel/3-schools-golf-course-architecture/)
- Some writers (e.g. Tom Doak) treat it as two schools; most courses blend them; penal design came first, strategic arose partly in reaction. — [The Fried Egg: three schools](https://thefriedegg.com/three-schools-of-golf-course-design/); [Inside Golf: 3 schools explained](https://www.insidegolf.ca/read/9756-the-3-schools-of-golf-architecture,-explained)
- Risk/reward framework ("reducibility"): treat a par 4 as two par 3s by viewing the fairway landing zone as a "green". Plan backward from the pin (best approach area) to the tee; design forward from tee to green so later hazards do not move landing zones already set. A bunker on one side pulls the ideal landing zone toward the other side. Difficulty through hazards is preferred to adding length, which penalizes weaker players. — [Golf Course Wiki: Visualizing Risk & Reward](https://golfcoursewiki.substack.com/p/visualizing-risk-and-reward-on-the)
- Hazard taxonomy from the same source: discrete hazards (forced carry) = pass/fail choice; continuous hazards (tree line, OB along one side) scale risk with proximity. Categories: shot risk with no positional reward (side bunker) = penal; shot risk + discrete reward (forced carry) = heroic; shot risk + continuous reward (bunker at the dogleg turn) = strategic; positional reward with no shot risk (a tree that blocks the approach from one side) = "strategic forethought", rewards smart play without punishing beginners; discrete reward without risk (drop-off with big roll-out) = "fun holes", useful after a run of penal holes. — [Golf Course Wiki](https://golfcoursewiki.substack.com/p/visualizing-risk-and-reward-on-the)
- The Fried Egg / Inside Golf note Augusta No. 12 and No. 13 as frequently cited examples mixing schools (No. 13: going for the green in two on a par 5). — [GOLF.com](https://golf.com/travel/3-schools-golf-course-architecture/)

### Inferences
- Module mapping: a "landing zone" tile = a mini-green target for the tee shot; each par 4 should have exactly one clearly readable landing zone plus one optional aggressive line. Par 3s are one target.
- Variety plan for 9 holes (my proposal, using sourced categories): 1 straightforward opener (fun/wide), 1 dogleg with a bunker at the corner (strategic, continuous reward), 1 forced water carry with bail-out (heroic), 1 island/peninsula green par 3 (penal, the "drama" hole), 1 downhill/elevated-tee par 3 with roll-out (fun hole), 1 tree-guarded angle hole (strategic forethought, no shot risk), 1 reachable par 5 with a water carry to go for it in two (heroic), 1 tight par 4 with OB/water down one side (continuous hazard), 1 closer with a tiered green.
- Do not place a penal hole back-to-back with another penal hole; follow a penal hole with a "fun" hole (per Golf Course Wiki's suggestion).
- Prefer adding difficulty via angle/hazard placement and green slope, not by lengthening holes, which matters even more on a small phone screen where length = less readability.

### Gaps
- No quantitative guidance found on dogleg angles, landing zone widths, or bunker-to-landing-zone offsets in the architecture sources consulted. Fairway width numbers not found in this pass.

---

## 3. Green design: what slopes are fun vs unfair, tiers, how big?

### Takeaway
Modern guidance caps hole-location (cupping) slope at about 2-3% (USGA's commonly cited 3% max for regular courses), with flatter required as green speed rises; slopes above ~4% are where green-reading becomes "significant" (the USGA/R&A threshold for detailed contour maps). Average real greens are ~5,500 sq ft (~510 m²), ranging ~3,500-9,000 sq ft (~325-835 m²). Older classic greens used up to 4-8% slopes when greens were slower.

### Cited Findings
- USGA: hole locations that work at Stimpmeter 10 ft are often not appropriate at 11 ft because of putting-green slopes. — [USGA: Hole Location, Location, Location (2018)](https://usga.org/course-care/forethegolfer/2018/hole-location--location--location.html)
- USGA "architectural speed limit" concept: green speed must be matched to the slopes of the green. — [USGA: The Architectural Speed Limit for Putting Greens (2017)](https://www.usga.org/content/usga/home-page/course-care/forethegolfer/2017/the-architectural-speed-limit-for-putting-greens.html) (page returned 403 to my fetch; content per search summary only)
- Commonly cited maximum: 3% in cupping areas recommended by USGA for regular courses. Slope recommendations by speed from a 2008 USGA Green Section chart (Jerry Lemons, ASGCA) define "recommended", "marginal" (use caution) and "critical" (no hole locations) bands; one source gives 2.9% recommended and 3.85% highest marginal at Stimp 14. — [Golf Course Industry: green slopes](https://www.golfcourseindustry.com/article/green-slopes-golf); [Golf Course Industry: The fine line of fair competition](https://www.golfcourseindustry.com/news/the-fine-line-of-fair-competition) (search-summary figures; I could not load the full chart)
- Historic green slopes: 1920s-30s up to 8%; 1940s-50s 4-6%; 1960s-70s 3-4%; 1980s-90s 2-3% (3% the USGA max); c. 2000 architects/PGA Tour preferred 1.5-2.25 degrees. — [Golf News Stories Online: Green Slopes for Putting Part 1](https://golfnewsstoriesonline.com/news/all/golf_news/green_slopes_for_putting_part_1.html)
- USGA/R&A green-reading materials rule (2019): detailed contour mapping is only allowed where slope >= 4% (2.29 degrees) — i.e. 4% is treated as the threshold of a meaningful slope. — [GolfWRX: USGA will restrict green reading materials](https://www.golfwrx.com/523880/usga-will-restrict-green-reading-materials-beginning-in-2019); [Golf Digest: final rule interpretation](https://www.golfdigest.com/story/usga-randa-ease-back-on-limits-to-green-reading-materials-in-final-rule-interpretation-set-to-go-in-effect-jan-1)
- Construction tolerance: grade changes of about an inch can push a location over the desired maximum slope. — [Golf Course Industry: green slopes](https://www.golfcourseindustry.com/article/green-slopes-golf)
- Green sizes: USGA study average ~5,500 sq ft (other USGA references 5,600-5,700); Pebble Beach ~3,500 sq ft (smallest among recent US Open venues); Chambers Bay ~9,000 sq ft; Brookline restored average 4,388 sq ft after ~20% expansion. — [USGA: Brookline small greens](https://www.usga.org/content/usga/home-page/articles/2022/06/brookline-small-greens-maintain-play.html); [TGL: green size comparison](https://tglgolf.com/articles/2025/03/greenzone/tgl-green-size--how-it-compares?webview=1); [Pitchcare: Anatomy of a golf course - greens](https://www.pitchcare.com/blogs/news/anatomy-of-a-golf-course-greens)
- Stimpmeter test validity: three balls each direction must finish within 8 in (20 cm) of each other. — [Wikipedia: Stimpmeter](https://www.wikipedia.org/wiki/Stimpmeter)

### Inferences
- Game green slope bands (my proposal derived from the sourced thresholds): cup zones 0-2% (easy), 2-3% (medium, visible break), never >3% within ~1.5 m of a cup; non-cup "shoulders" and tier faces 4-8% to create break and funnels; >8% only for tier ramps or false fronts that reject short approaches. Make the game's green "speed" a tunable equivalent so a 3% slope produces a readable but not ball-runs-off break.
- Green size in game: real average ~510 m² (~ a 25 m diameter circle). On a compressed course, 12-20 m wide greens (110-310 m²) for par 3/4 approaches keep them proportional; island/penal greens can be ~10-12 m; par 5 greens bigger. Scale green size to the approach club's dispersion, not the hole's length.
- Tiers: a 2-tier green = two cupping plateaus at <= 2-3% joined by a ramp of ~6-10%. Placing the pin on the upper vs lower tier is a cheap way to vary difficulty on the same module.
- Show break visually (grid/arrows or moving particles) rather than relying on shading alone; the 4% contour threshold suggests showing "strong slope" markers only above ~4% so the display does not over-clutter gentle greens.

### Gaps
- Could not retrieve the full Lemons/USGA slope-vs-speed chart values (USGA page returned 403). No source on false-front design numbers. No published data on what green slopes "feel fun" in a video game specifically.

---

## 4. How do games and tools build courses from modules, splines, heightmaps, or procedural rules?

### Takeaway
AAA golf (EA SPORTS PGA Tour) builds terrain from heightfield maps plus material masks (splat-style) via Frostbite's procedural terrain tools, starting from LiDAR scans. Indie/AA titles have used procedural generation with layout rules (The Golf Club), grid-import tools (Total Pro Golf 2), diorama-style tile presentation (OK Golf), and must guarantee a playable route through hazards (MiniGolf Endless). A tile kit + per-hole parameters + seeded variation is consistent with these precedents.

### Cited Findings
- EA SPORTS PGA Tour: 28 courses scanned with LiDAR (drones, helicopters, planes); point-cloud vectors of fairways, roughs and greens are processed into heightfield maps and masks and imported into Frostbite. Raster "overlays" drive both height and material placement (rule-based mask switching, procedural noise for wet sand/dry grass). Bunker depth can now be adjusted live in-engine; terrain adjusts around placed objects (trees, stones) in real time. Tools used across seven EA titles. — [EA: Procedural terrain in EA SPORTS PGA Tour](https://www.ea.com/news/procedural-terrain-in-ea-sports-pga-tour)
- The Golf Club (HB Studios): unable to license famous courses, the developers prototyped in Unity's terrain editor and turned to procedural generation with rules for playable, realistic layouts; within a couple of months it produced "very playable, realistically laid out courses", later evolving into a course editor. — [Gamezebo: The Golf Club takes a swing at user created courses](https://www.gamezebo.com/upcoming/the-golf-club-takes-a-swing-at-user-created-courses/) (search snippet; full page 403)
- Course-creator software from the same lineage was later used by real architects to make virtual designs. — [Golf Course Architecture: course creator application](https://www.golfcoursearchitecture.net/content2/course-creator-application-helping-architects-make-virtual-designs-a-reality)
- Total Pro Golf 2 (Wolverine Studios) had a course designer that imported images into a grid to map where everything was, making new courses quick to release. — [Game Developer: Indie Postmortem Total Pro Golf 2](https://www.gamedeveloper.com/business/indie-postmortem-wolverine-studios-total-pro-golf-2)
- OK Golf presents each course as a set of low-poly dioramas, which reviewers said made every detail feel critical. — [MacStories: OK Golf review](https://www.macstories.net/reviews/take-to-the-course-with-ok-golf/)
- MiniGolf Endless MMO (Ludum Dare 33): procedurally placed water could make courses unplayable, so the developers added a guaranteed fairway path through hazards. — [ModDB: MiniGolf Endless MMO](https://www.moddb.com/games/minigolf-endless-mmo)
- Hobbyist procedural golf examples exist (procedurally generated islands; a standalone golf generator; Snap Shot Golf builds isometric holes from photos or random seeds — the latter only verified via an AI-generated summary page). — [itch.io: Procedurally Generated Golf](https://rhinohand.itch.io/procedurally-generated-golf); [itch.io: Golf Generator](https://fredhewitt.itch.io/golf-generator/donate); [engineered.at: Snap Shot Golf](https://engineered.at/articles/snap-shot-golf)

### Inferences
- Recommended pipeline for Fairway Flick (my proposal, consistent with the above): author each hole as data (a centreline spline/polyline from tee to green + width profile + list of module placements), rasterise into (a) a heightmap and (b) a surface-ID map (tee/fairway/rough/sand/water/green/OB) that the physics queries for friction/lie. Surface-ID map doubles as the splat mask for rendering and the minimap texture.
- Module kit size: ~6-8 base modules (tee box, fairway segment straight/curve, rough fill, bunker shapes x3, water body x2, green x3 shapes with slope presets, tree clusters x2) is enough for 9 distinct holes if each hole varies routing (straight/dogleg L/R), hazard role (penal/strategic/heroic), elevation (flat/uphill/downhill tee), and green preset/pin.
- Playability guarantee (lesson from MiniGolf Endless): a validator should check that a safe route exists from tee to green using only the shorter clubs, i.e. every forced carry has a bail-out or is within the wedge's reliable range; run it in unit tests for all 9 holes and every seed.
- Seeded daily variation: keep routing fixed and vary only safe parameters from the seed (pin position among authored cup zones, tee box among 2-3 positions, wind, maybe one optional bunker), using core/Rng.gd. This keeps holes recognisable while making daily challenges fresh and avoids generating unplayable layouts.

### Gaps
- No detailed public write-up found of a tile-kit-based golf course system or the specific rules The Golf Club's generator used. No GDC talk on golf course procedural generation found in this pass.

---

## 5. Hazard rules and pacing caps in casual golf

### Takeaway
Real golf supports a "Maximum Score" stroke-play format where a hole is capped at a committee-set limit (relative to par, a fixed number, or net double bogey); handicap scoring caps at net double bogey. Casual games commonly use water/OB penalties and lie penalties from rough/sand; a pick-up cap at double par or triple bogey is a reasonable pacing rule.

### Cited Findings
- Rules of Golf "Maximum Score" format: score per hole capped at a maximum set by the Committee (relative to par, a fixed number, or net double bogey); the player gets the maximum even if the actual score is higher. — [USGA: Maximum Score form of stroke play](https://rulesworkshops.usga.org/content/usga/home-page/rules-hub/rules-modernization/major-changes/maximum-score--form-of-stroke-play.html)
- World Handicap System: maximum hole score = net double bogey (double bogey + handicap strokes received); replaced Equitable Stroke Control in 2020. — [USGA: 3.1 Maximum Hole Score for Handicap Purposes](https://usga.org/content/usga/home-page/handicapping/roh/Content/rules/3%201%20Maximum%20Hole%20Score%20for%20Handicap%20Purposes.htm); [USGA Net Double Bogey summary (PDF)](https://www.usga.org/content/dam/usga/pdf/Net_Double_Bogey_Change_Summary_2020.pdf)
- Mobile casual golf (Golf Clash UX review): environmental factors include wind, obstacles, water hazards and surface friction differing by fairway, rough or sand; "rough and sand can undo a well-aimed shot". Watching the opponent's turn from the same camera acts as an organic tutorial. — [Game Developer: UX review Golfclash's swing to success](https://www.gamedeveloper.com/design/ux-review-golfclash-s-swing-to-success-)

### Inferences
- Suggested ruleset (my proposal): water = +1 stroke, drop at the point of entry on the near side (or replay from previous spot, player's choice); OB = +1 stroke, replay from previous spot (stroke-and-distance); sand = power cap ~60-70% and higher spin/scatter; rough = power cap ~80-85% and less spin. Pick up at double par (par 3 -> 6, par 4 -> 8) or triple bogey; triple bogey is tighter and better for a 6-8 minute round.
- With a CPU opponent, apply the same caps to the CPU to keep matches symmetrical and short.

### Gaps
- Did not retrieve the official Rule 17 (penalty areas) text in this pass; the "one penalty stroke + relief" description of water is from general knowledge and should be verified against the Rules of Golf. Found no official documentation of specific penalty values used by commercial mobile golf games (lie % penalties, etc.).

---

## 6. Readability on a portrait phone (overview, minimap, colour contrast, elevation)

### Takeaway
No published postmortem was found specifically on golf hole flyovers or portrait readability. General accessibility guidance is clear: never encode surfaces by colour alone, separate surfaces by brightness/value and texture/pattern (red-green deficiency affects ~8% of males), and test with a colour-blindness simulator.

### Cited Findings
- Game Accessibility Guidelines: ensure no essential information is conveyed by a fixed colour alone. — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/)
- Red-green deficiency is the most common form; critical elements should differ significantly in brightness, not just hue; pair colour with shape/texture/symbol; test with a simulator and offer a colour-blind mode as fallback. — [Indieklem: How to make game colors accessible](https://indieklem.substack.com/p/how-to-make-colors-games-accessible); [Pixel Palette Swap: high-contrast palettes](https://pixelpaletteswap.pages.dev/guides/accessibility-high-contrast-palettes.html); [Bugnet: colorblind-friendly game design](https://bugnet.io/blog/colorblind-friendly-game-design)
- Mobile golf controls pitfall: a reviewer reported often tapping to swing accidentally when trying to pan for a target. — [Pocket Gamer: Mini Golf Theme Park review](https://www.pocketgamer.com/mini-golf-theme-park-99-holes-smart-phone/review)
- Golf Clash UX: large bold fonts and clear calls to action aid readability; players can place a landing reticle near the target; both players see nearly the same camera angle. — [Game Developer: UX review Golfclash](https://www.gamedeveloper.com/design/ux-review-golfclash-s-swing-to-success-)
- Diorama-style compact course presentation (OK Golf) makes every detail feel deliberate. — [MacStories: OK Golf](https://www.macstories.net/reviews/take-to-the-course-with-ok-golf/)

### Inferences
- Portrait layout implies holes should run mostly "up the screen". A hole whose full length fits in one portrait overview with the green visible from the tee is the most readable; this argues for compact lengths and doglegs of moderate angle rather than holes that wrap sideways.
- Surface palette (value-separated, my proposal): tee/fairway mid-light green with mow stripes; rough darker, desaturated green with noisy texture; green brightest green with fine grid/stripe; sand pale beige/near-white (high value); water saturated blue with animated ripples; OB marked by white stakes/line pattern, not colour only. Check in protanopia/deuteranopia simulation that fairway/rough/green stay separable by luminance.
- Elevation: show via tee-to-landing "plays like" distance, shadowed contour lines or a side-profile strip, and a dashed shot arc that ends on the terrain; put break arrows/particles on the green.
- Flow per hole: 2-3 s auto flyover (tee -> green -> back) skippable by tap, then a top-down/oblique aim camera with a separate "pan/look" gesture zone distinct from the swing control to avoid the accidental-swing problem reported above.

### Gaps
- No GDC talk, postmortem or design article found on golf hole flyovers, minimaps or portrait-orientation golf readability. The flow above is inference, not sourced practice.
