# Cup Dash: Hole Archetypes, Multi-Course Variety and Difficulty Ramp

Scope: a catalogue of hole archetypes (geometry, numbers, the strategic question each asks), plus how to assemble ~4 courses x 9 holes (36 holes) with a difficulty curve, for an ORIGINAL mobile golf game that uses real-metre physics (driver ~175 m carry, 7-iron ~130 m, wedge ~95 m). This builds on `docs/research/Cup Dash golf game design notes/hole_design.md`, which already covers par/USGA length bands, penal/strategic/heroic schools, the Golf Course Wiki risk/reward taxonomy, green slope limits (2-3% cup zones, 4% "significant" threshold), real green area (~510 m²), modular pipelines and readability. None of that is repeated here. Research date: 2026-11-14.

Unit and scaling conventions (my own, used throughout):
- 1 yd = 0.9144 m.
- The USGA rating model assumes a scratch golfer carries the driver ~225 yd (206 m) and a bogey golfer ~180 yd (165 m) ([GOLF.com: how a hole is rated](https://golf.com/?p=15450386)). The game's 175 m driver carry is therefore about 0.85x scratch and about 1.06x bogey. Where I convert a real-world template yardage into a game length I multiply by **k = 0.85** and mark it "(game, k=0.85)". These are design starting points, not sourced numbers.
- Template holes were designed 1908-1930 for hickory and early rubber-core balls, so their yardages are already "short" by modern standards. Scaling them by 0.85 against a modern scratch player is a deliberate simplification.
- Note: the earlier notes proposed a compressed ~0.45x world. This brief fixes real-metre physics with a 175 m driver, so the lengths below replace that compressed ladder.

---

## 1. Classic hole templates and archetypes: shape, lengths, hazards, decision, game translation

### Takeaway
The Macdonald/Raynor "template" holes are generic, reusable design ideas (not copyrighted course copies). Each one is built around one clear question: angle in (Redan), which level to land on (Biarritz, Double Plateau), how much to bite off (Cape), whether to trust a blind shot (Alps), whether to hold a small target (Short, Eden, island). Combined with modern archetypes (drivable par 4, reachable par 5, split fairway, forced carry, elevated or downhill par 3), they give well over 20 distinct building blocks. That is enough for 36 holes if each course uses each archetype at most once.

### Cited Findings

**Origin and nature of templates**
- In 1901 C.B. Macdonald began building an "ideal" course from the best features of British links holes. He first used these "ideal holes" (templates) at the National Golf Links of America (NGLA), and Seth Raynor kept using templates in his own 1920s designs. — [GOLF.com: What are template holes](https://golf.com/travel/what-are-template-holes-important-golf-design/); [Golf Digest via search summary](https://www.golfdigest.com/story/coore-crenshaw-favorite-golf-hole-template)
- GOLF.com lists about 22 templates: Short, Punchbowl, Redan, Alps, Leven, Double Plateau, Long, Cape, Narrows, Valley, Bottle, Maiden, Biarritz, Hog's Back, Eden, Plateau, Dogleg, Lion's Mouth, Knoll, Road, Lido, Sahara. Common Raynor features include "squared greens and bunkers well below the surface of the green". — [GOLF.com: What are template holes](https://golf.com/travel/what-are-template-holes-important-golf-design/)
- Template originals and one-line definitions (Evalu18): Sahara (big carry over an immense bunker, then a run-up to the green); Alps (blind approach over hidden bunkers to a punchbowl green, which must be carried, not run in); Redan (green falls away with a large bunker guarding the direct line); Short (short hole to an elevated green where missing is severely punished); Road (dogleg with a hazard at the apex that must be carried, a severe pot bunker near the green, a road hugging one side); Bottle (fairway narrows sharply into a neck); Long (three-shot hole with multiple routes); Cape (tee shot bites off as much as you dare, green near the water); Leven (diagonal hazard across the fairway, green hidden from the tee, taking on the hazard buys a view); Eden (par 3, elevated wind-exposed green, severe front bunkers, trouble behind); Dell (blind tee shot to a fully hidden green); Postage Stamp (very small green in shifting wind); Littlestone (dogleg left, three shots the safe way or cut the corner to an alternate fairway and reach in two). — [Evalu18: Template Holes](https://evalu18.com/template-holes/)

**Redan (par 3)**
- Typically 180-230 yd (examples run from 160 to 255 yd). The green is angled about 45 degrees away from the player, right to left (the Reverse Redan mirrors it). A deep bunker guards the low (left) side, and the green slopes heavily toward that bunker and front to back. The defining feature is a raised "kicker" shoulder on the high side that feeds balls toward the middle and back. Safe miss: long and left, leaving an uphill chip. Bad miss: short and right, leaving a pitch over the shoulder running downhill. Some versions are designed for a low running shot. — [The Fried Egg: Redan template](https://thefriedegg.com/redan-template-hole/)

**Biarritz (par 3)**
- A long carry to a very deep green split by a swale into two plateaux. The swale is traditionally about 1-1.5 m deep (Links Magazine says 3-5 ft), though nothing official specifies it. Length is 210-240 yd per Links Magazine and The Fried Egg, or 180-240 yd per Top 100. The green can run 60-80+ yd deep. The original was the "Chasm" hole at Biarritz Le Phare, and the first US copy was at Piping Rock. — [Top 100: B is for Biarritz](https://www.top100golfcourses.com/news-item/b-is-for-biarritz-template-holes); [Links Magazine: best Biarritz holes](https://www.linksmagazine.com/12-of-the-best-biarritz-holes-in-the-u-s/); [The Fried Egg: Biarritz](https://thefriedegg.com/biarritz-template-hole/) (figures via search summary)

**Short (par 3)**
- About 129-135 yd (Brancaster No. 4 is 129 yd, Streamsong Black No. 15 is 133 yd) to a green that is wide rather than long and usually one of the largest and toughest greens on the course. It is surrounded by hazards (moat bunkers, a sleeper wall, fully ringed sand). It often has "thumbprint" depressions or a central hump, so a two-putt from the wrong side is hard. The tee shot is the key shot, and stretching a Short with longer tees "all but wip[es] out the template's intent". — [Top 100: S is for Short](https://www.top100golfcourses.com/news-item/s-is-for-short-template-holes)
- A Short is "a shorter par-3 almost always with heavy bunkering or a harsh penalty for missing the green". — [GOLF.com](https://golf.com/travel/what-are-template-holes-important-golf-design/)

**Eden (par 3)**
- Named for the estuary behind the St Andrews original. Typically a par 3 with a signature bunker behind the green. Examples are 149 yd (Chicago GC No. 13), 179 yd (Camargo No. 5) and ~196 yd (Shoreacres No. 8). A greenside bunker at Camargo is about 20 ft deep. — [Top 100: E is for Eden](https://www.top100golfcourses.com/news/e-is-for-eden-template-holes); [The Fried Egg: Eden](https://thefriedegg.com/eden-template-hole/) (via search summary)

**Cape (par 4, sometimes par 5)**
- Usually a par 4 from the low 300s to mid 400s yd. Examples: 325, 350, 351, 374, 393, 425, 430, 433 yd, plus one 575 yd par 5. The tee shot crosses a diagonal hazard, and the fairway often kicks toward the hazard. The green is surrounded on three sides by water or bunkers. "The ultimate risk/reward design": cutting off more hazard leaves a shorter approach and a better angle. Macdonald's original NGLA Cape was a 305 yd dogleg right with water on three sides of the green. He later lengthened it because of worry that it would become drivable. — [The Fried Egg: Cape template](https://thefriedegg.com/cape-template-hole/)

**Road (long par 4 / short par 5)**
- The tee shot goes over an obstacle at the dogleg corner (the original drives over buildings). The green is narrow and angled front-right to back-left, with a deep pot bunker in front and a road immediately behind. Taking the bold line gives the best approach angle, and the safe line left leaves almost no chance of running the ball past the pot bunker. Examples: 478 yd (NGLA variant, short par 5) and a 348 yd Road-style hole. Core principle: a Road hole "must offer some incentive for trying to reach the green, and punishment for those who stumble". — [Top 100: R is for Road](https://www.top100golfcourses.com/news-item/r-is-for-road-template-holes)

**Double Plateau (par 4, sometimes long par 3)**
- The green has three pinnable levels: two raised plateaus at different heights (e.g. front-left and back-right) plus a lower ground-level platform. One example has a 3 ft swale. The hole is rarely doglegged. The pin decides which side of the fairway is best, and landing on the wrong level makes a two-putt hard. The "Principal's Nose" bunker sits about 70 yd short of the green and blocks both the sightline and the ground game. Examples: 365 yd, 427 yd and 450+ yd par 4s, and a 225 yd par 3. "A true Par 5 cannot be a proper Double Plateau." — [Top 100: D is for Double Plateau](https://www.top100golfcourses.com/news-item/d-is-for-double-plateau-template-holes); [GOLF.com: Double Plateau](https://golf.com/travel/double-plateau-hole-golf-architecture/) (via search summary)

**Alps, Punchbowl, Knoll (from the same Top 100 article)**
- Alps: a blind second shot over a "mountain" that hides the green, with a "Sahara" bunker in front of the green. The original (Prestwick) has a punchbowl green. Interpretations use a diagonal fairway with a long cross-bunker, or a humped bunker that only partly blocks the view. — [Top 100: D is for Double Plateau](https://www.top100golfcourses.com/news-item/d-is-for-double-plateau-template-holes)
- Punchbowl: a hollow green that gathers approaches, sometimes with internal collection areas or a dividing spine. Originally chosen for drainage rather than strategy. Used on par 3s, par 4s and par 5s (e.g. a 510 yd par 5). — [same](https://www.top100golfcourses.com/news-item/d-is-for-double-plateau-template-holes)
- Knoll / horseshoe: a "thumbprint" green with the low part in front and a raised horseshoe wrapping around the back. — [same](https://www.top100golfcourses.com/news-item/d-is-for-double-plateau-template-holes)

**Island green (penal par 3)**
- The best-known modern example plays 137 yd to a green about 78 ft (23.8 m) long and about 3,912 sq ft (363 m²). Commonly cited figures say 100,000-120,000 balls are retrieved per year in public play (estimates vary). Tournament play averages about 49 balls in the water per year. — [GOLF.com: 15 numbers island green](https://golf.com/travel/15-numbers-know-island-green-17th-hole/); [Golf Monthly: balls in the water](https://golfmonthly.com/tour/how-many-balls-go-into-the-water-at-the-17th-at-tpc-sawgrass) (figures via search summary; sources disagree on annual totals)

**Drivable / short par 4**
- Risk and reward are the defining purpose. Lengths are quoted as 260-300 yd (men) or 250-350 yd. Water or OB is usually present, and the pin position drives the decision. Hidden fairway bunkers can make even an iron off the tee risky (e.g. a 314 yd hole). A 332 yd drivable hole is the only par 4 aced in PGA Tour history. One rule of thumb (USGA article, via search summary) is that a drivable hole works when about 60% of players go for it. — [Global Golf Post: In praise of the short par 4](https://www.globalgolfpost.com/featured/in-praise-of-the-short-par-4/); [GOLF.com: Weiskopf on drivable par 4s](https://golf.com/news/tom-weiskopf-reveals-risks-rewards-drivable-par-4/); [Golf Digest: 15 best drivable par 4s](https://www.golfdigest.com/story/the-15-best-drivable-par-4s-in-golf); [USGA: drivable par 4s and match play](https://www.usga.org/content/usga/home-page/championships/2016/u-s--amateur-four-ball/articles/drivable-par-4s-add-intrigue-to-match-play-strategy.html); [The Left Rough](https://theleftrough.com/how-to-play-a-short-par-4/); [Golfers Authority](https://golfersauthority.com/short-par-4-reviews/)

### Inferences

**Archetype catalogue scaled for Cup Dash.** Game lengths use k=0.85 from the sourced yardages unless marked "design". Green sizes are my proposals, scaled to approach club (see Q5). "Question" is the single decision the hole must make readable.

| # | Archetype | Par | Game length (m) | Key geometry (game) | Hazards | The question it asks | Game translation notes |
|---|---|---|---|---|---|---|---|
| 1 | Redan | 3 | 140-175 (k=0.85 of 180-230 yd) | Green ~32x18 m angled 45° away; tilt 3-4% front-high to back-low toward the deep side; kicker bank on the high side, 6-10% | Deep bunker along the low side; optional short bunker | Fly it at the flag over the bunker, or land it on the kicker and let it feed? | The ground game must actually work: tune green/fringe friction so a ball landing on the bank rolls 8-15 m. Mirror it for a "Reverse" variant on another course. |
| 2 | Biarritz | 3 | 160-185 (k=0.85 of 210-240 yd) | Green 45-60 m deep x 20 m wide; front and back plateaus at equal height; swale 1-1.5 m deep (keep real depth) | Side bunkers along both flanks | Which plateau is the pin on, and can you carry, or run through, the swale? | Pin in front, back or in the swale gives three very different holes from one mesh. Good for "same hole, new pin" daily variety. |
| 3 | Short | 3 | 90-110 (k=0.85 of 129-135 yd) | Wide, shallow green ~30x18 m with 1-2 thumbprint dips or a central hump | Ringed by sand or a wall/moat; only one safe miss | Hit the right section of a big green; a miss anywhere is costly | A wedge hole after a long hole. A hump means a "two-putt from the wrong side is a win" moment. |
| 4 | Eden | 3 | 115-155 (k=0.85 of 149-197 yd) | Elevated green ~25x16 m sloping back to front 3% | Deep pot bunkers front and side; "trouble behind" (water/estuary or OB) | Hold the green: short finds sand, long finds the hazard | Exposed to wind: put it on a course with strong wind and show wind strength clearly. |
| 5 | Island / peninsula green | 3 | 95-115 (k=0.85 of 137 yd) | Island ~20-24 m long, ~300-360 m² (real example 363 m²); keep the shape non-square and not a copy | Water all round (island) or on three sides (peninsula, offers a bail-out) | Pure execution and nerve; peninsula adds a "bail to the land side" option | The penal "drama" hole. Peninsula on easier courses, full island only on hard ones. Use a drop zone so a miss costs +1, not a reload loop. |
| 6 | Downhill / elevated-tee par 3 | 3 | 110-170 to the green (plays shorter) | Tee 15-30 m above the green; green 25 m | Water or bunkers in front | Pick the right club for a "plays-like" distance | Needs a "plays like" readout. Real-metre physics with a long hang time makes the elevation visible and fun. |
| 7 | Uphill / blind par 3 (Dell-like) | 3 | 100-140 | Green hidden behind a dune or rock; aim marker on the ridge | Hidden bunkers | Trust the marker and commit | Use only on advanced courses. Always show the green in the flyover and on the minimap so it is "blind" in camera only. |
| 8 | Punchbowl | 3 / 4 / 5 | Any (often 4: 260-320) | Green in a hollow 1.5-3 m below its rim; rims feed balls in | Few; the bowl forgives | Is it a "fun" hole where approaches gather? | The fun release hole after a penal hole. Approaches that land on the rim roll to the green. |
| 9 | Cape | 4 | 255-335 (k=0.85 of 325-433 yd) | Dogleg 30-45° around a diagonal water or sand body; fairway kicks toward the hazard | Diagonal carry hazard; green bunkered or watered on three sides | How much hazard do you bite off for a shorter, better-angled approach? | The signature risk/reward par 4. Show carry distances along 2-3 lines in the aim UI. |
| 10 | Road | 4 (long) / 5 (short) | 270-370 (k=0.85 of 318-437 m) | Dogleg with an obstacle at the corner (building, rock arch, ruins) to drive over; narrow angled green | Deep pot bunker front-centre; hard surface or OB just behind the green | Take the bold corner line for the angle, or accept a near-impossible approach past the pot bunker | The "obstacle to drive over" can be a themed landmark: memorable and original. |
| 11 | Double Plateau | 4 | 285-350 (k=0.85 of 365-450 yd) | Green ~40x25 m, two raised plateaus at opposite corners plus a low centre; tiers 0.6-1 m | Principal's-Nose-style cross bunker ~55 m short of the green (k=0.85 of 70 yd) | Which side of the fairway opens the pin's plateau? | The pin moves the ideal landing zone left or right. Great for daily pin rotation. |
| 12 | Alps (blind approach) | 4 | 260-320 | Big mound 40-80 m short of the green hides the green from the fairway | Cross bunker in front of the green (Sahara) | Commit to a blind approach to a gathering green | Pair with a punchbowl green so a blind shot is not too cruel. |
| 13 | Leven (diagonal cross-hazard) | 4 | 240-300 | Diagonal hazard across the landing zone; the green is visible only from the far side | Diagonal bunker or burn | Carry more hazard to gain a view and angle | The "strategic forethought" archetype. |
| 14 | Bottle / Narrows | 4 | 260-320 | Fairway pinches to 15-20 m at 160-190 m from the tee, wide before and after | Bunkers or water forming the neck | Lay up short of the neck, or thread it | Exploits driver vs 3-wood vs iron choice off the tee. |
| 15 | Drivable par 4 | 4 | 190-215 (design: within driver carry+roll; k=0.85 of 260-350 yd gives 200-270) | Green 20-25 m, guarded on the direct line; wide lay-up area at 120-150 m | Water/OB or a deep bunker on the direct line | Go for it (eagle/birdie or double) or lay up to a full wedge | Target a ~60% go-for-it rate in playtests. Make the lay-up angle worse, not just shorter. |
| 16 | Dogleg left / right | 4 | 260-330 | Corner at 170-190 m (game driver landing); bend 30-60° | Bunker or trees at the corner (continuous risk) | Cut the corner or play to the outside | Alternate left and right across a course. With hook/slice control, it rewards shaping. |
| 17 | Split fairway | 4 / 5 | 280-340 (par 4) | Two fairways split by a hazard spine; upper/riskier fairway gives a shorter or open approach | Central bunkers or rough spine | Which fairway, given today's pin? | Ties to pin rotation: one side is better for front pins, the other for back pins. |
| 18 | Forced carry (heroic tee) | 4 | 240-320 | Water/ravine 110-160 m carry from the tee on the direct line; longer angled bail-out | Water/chasm | Carry the chasm or take the long way round | Every forced carry needs a wedge-range bail-out (see the playability validator in the earlier notes). |
| 19 | Reachable par 5 (risk/reward) | 5 | 380-420 (design: 2 strong shots, about drive 190 + wood 175 plus roll or downhill) | Second-shot landing on a green guarded by water in front | Water crossing short of the green; lay-up area at 80-100 m | Go for it in two over water, or lay up to wedge range | Classic heroic hole. Matches the Littlestone idea (cut the corner to reach in two). |
| 20 | Three-shot par 5 (Long) | 5 | 430-480 | Multiple routes; a cross-hazard at ~2nd-shot landing | Cross bunkers, water on one side | Choose a route, then set up the best wedge angle | Use sparingly on mobile (long hole = long session). One per course at most. |
| 21 | Horseshoe / Knoll green | 3 / 4 | Any | Low front, raised horseshoe wrapping the back; pin on the horseshoe | Bunkers outside the horseshoe | Land short and feed, or fly to the ridge | Visually distinctive green "skin" for mid courses. |
| 22 | Sahara (big carry then run) | 4 | 230-280 | Huge waste bunker crossing from the tee; run-up green open in front | Waste area | Commit to the carry to get the run-in | Good desert or canyon theme opener. |

- **Mirror and reuse:** Redan/Reverse Redan, dogleg L/R and Cape left/right let one archetype appear twice in 36 holes without feeling repeated, as long as they sit on different courses with different themes and pins.
- **Originality:** templates are generic concepts and safe to adapt. Do not reproduce a specific famous hole's exact length, outline or landmarks (e.g. avoid a square island green at exactly 125 m with a single walkway, or a "drive over the hotel" corner). Use themed landmarks of our own.

### Gaps
- No primary source (e.g. Daley's *Classic Golf Hole Design*, Doak's *Anatomy of a Golf Course*) was directly readable; template numbers come from Top 100 Golf Courses, The Fried Egg and Evalu18 secondary write-ups. I found no sourced swale/tier heights for Redan kicker banks, Double Plateau tiers or Punchbowl depth beyond the 1-1.5 m Biarritz swale and a 3 ft swale on one Double Plateau. The tier, slope and bank values in the table are proposals.
- The Fried Egg Biarritz/Eden pages and the Valley, Lion's Mouth and Hog's Back templates were not fetched; their definitions are not included.
- No sourced numbers on dogleg angles or corner distances; those are design proposals tied to the game's driver landing.

---

## 2. How architects create variety within a round

### Takeaway
Variety comes from changing four things hole to hole: length (testing every club), direction (relative to the wind), shot shape (left-to-right vs right-to-left), and green complexes (size, contour, elevation, bunkering). The rhythm alternates tension and release. A balanced scorecard is not required, and similar holes should be separated rather than placed back to back.

### Cited Findings
- Doak: "The round ... should have a rhythm and a flow, with holes that vary in length, difficulty and direction." Holes all running the same way "simplify the round". Triangulating three holes means the wind affects each one differently. — [GOLF.com: What is course routing](https://golf.com/travel/what-is-course-routing-architecture/); [GOLF.com: Course Rater Confidential on routing](https://golf.com/travel/what-makes-golf-course-routing-difficult-important/) (via search summary)
- Architects try to vary wind on par 3s, short and long par 4s and par 5s, with "some of each 'going to each point on the compass'". "If we always put long holes downwind, and short holes into the wind, they would perhaps play to similar lengths." — [GolfClubAtlas forum: routing essay (Cybergolf)](https://golfclubatlas.com/forum/index.php/topic,31217.0.html) (via search summary)
- Length variety should test the full bag: short par 3 = wedges; long par 3 = long irons, hybrids or woods; short par 5 = "a player's appetite for risk"; long par 5 = angles and strategy. Avoid "too many back-to-back-to-back 350- to 400-yard par 4s". Example par 3 set on one course: 215, 170, 130 and 190 yd, each testing a different part of the bag. — [The Fried Egg: GCA 101 Part 2, routing](https://thefriedegg.com/golf-course-architecture-101-part-2-routing-variety-naturalness/)
- No forced scorecard balance: "A great routing will never force a par 4 to be par 5 just for the sake of the scorecard". Example: one nine with 1 par 3 and 1 par 5, the other with 4 par 3s and 3 par 5s, including back-to-back par 3s. Fairways should favour different shot shapes. "Every green complex should offer a fresh look, feel, and set of strategic questions" (size, contour, elevation, bunkers). Stories need "sequences of tension and release, thrills and lulls". — [The Fried Egg: GCA 101 Part 2](https://thefriedegg.com/golf-course-architecture-101-part-2-routing-variety-naturalness/)
- Consecutive par 3s or par 5s are a convention, not a rule. Example: a well-regarded course runs 5-3-5-3-5-3 from holes 9-14. — [GolfPass: 10 design rules meant to be broken](https://www.golfpass.com/travel-advisor/articles/10-golf-course-design-rules-meant-to-be-broken)
- Template-based courses were themselves variety engines: Raynor courses typically open with a run of different templates, e.g. Yale "starts with a litany of template holes before reaching the Short fifth". — [Links Magazine: Template holes](https://linksmagazine.com/?p=40752) (via search summary)

### Inferences
- **Per-course variety checklist (9 holes):** 1) at least 3 different par 3 lengths covering wedge, mid-iron and wood; 2) no two consecutive holes within 20 m of each other at the same par; 3) at least 3 of 4 wind-relative headings used (in a game, wind is chosen per hole, so "direction" means the hole axis relative to the course's prevailing wind, which keeps wind consistent and learnable within a course); 4) dogleg left and dogleg right both present; 5) each green uses a different archetype green (Redan tilt, Biarritz swale, punchbowl, plateau, horseshoe, island, flat-fast); 6) at most 2 penal holes and never consecutive; 7) one "release" hole (punchbowl, wide downhill par 3, drivable par 4 with a forgiving lay-up) after each penal or long hole.
- **Rhythm template for a 9 (par 34-36):** gentle opener (wide par 4) -> short par 3 -> strategic par 4 -> reachable par 5 -> release par 4 -> signature par 3 -> drivable par 4 -> long/tough par 4 or Biarritz -> climactic finisher (Cape or reachable par 5 over water). Holes 6 and 9 are the "memorable" slots.
- **Across 4 courses:** give each course a dominant variety axis so the courses differ from each other, not just hole to hole within a course: Course 1 = width and forgiving greens; Course 2 = wind and ground game (Redan, Biarritz, links bumps); Course 3 = elevation and blind shots (Alps, downhill par 3s, punchbowls, forced carries); Course 4 = water and penal precision (Cape, island, peninsula, reachable par 5 over water).

### Gaps
- Doak's own text (*Anatomy of a Golf Course*) was not accessible. His views appear here only as quoted by GOLF.com. No quantitative rule (e.g. % of holes per wind direction) was found in architecture sources.

---

## 3. Estimating hole difficulty and ramping difficulty across courses

### Takeaway
USGA Course Rating rates every hole twice, for a scratch and a bogey golfer, using effective playing length plus ten 0-10 obstacle factors judged at each player's landing zones. Slope comes from the gap between the two ratings. A game can copy this structure: score each hole's effective length plus obstacle severity in the game golfer's landing zone, and check it empirically with CPU self-play at two skill levels. Commercial games ramp difficulty mostly through tiered course order (beginner -> expert), narrower targets, harder greens and stronger wind.

### Cited Findings
- Rating assumptions: scratch carries the driver ~225 yd + 25 yd roll and second shots ~200 + 20 yd, reaching a 470 yd hole in two. Bogey carries ~180 + 20 yd and seconds ~150 + 20 yd, reaching 370 yd in two. Effective length is adjusted for turf firmness, prevailing wind, doglegs, forced carries/lay-ups and elevation. Raters ask, e.g., "how wide is the landing area 200 yards off the tee" and "is there water 250 yards out", because placement relative to each golfer's target matters as much as severity. — [GOLF.com: How a golf hole is rated](https://golf.com/?p=15450386)
- Landing zones are evaluated at ~200 yd (bogey) and ~250 yd (scratch) off the tee, then again toward the green. Hazards inside those zones weigh most. — [MGA: What is Slope?](https://mgagolf.org/node/608); [National Club Golfer: course rating explained](https://www.nationalclubgolfer.com/whs/golf-course-rating-explanation/)
- The ten obstacle factors, each 0-10 for scratch and bogey: topography, fairway, green target, recoverability and rough, bunkers, crossing obstacles (OB/extreme rough), lateral obstacles, trees, green surface, psychological. Green target is driven mainly by green size vs approach length. A USGA example contrasts a 210 yd approach to a 32 yd-diameter green with the same shot to a 19 yd green, which rates much higher. The psychological factor rises with the number and size of above-average ratings in other factors. — [TXGA: Understanding Course Rating](https://txga.org/understanding-course-rating/); [SCGA: Course Obstacles](https://www.scga.org/courses/course-rating/obstacles); [FSGA: Course Rating Obstacles](https://fsga.org/sections/content/Course-Rating-Obstacles/353) (via search summary)
- Course Rating = scratch yardage rating + scratch obstacle stroke value; Bogey Rating = bogey yardage rating + bogey obstacle stroke value. Slope Rating = 5.381 x (Bogey Rating - Course Rating) for men, 4.24 x (...) for women; 113 is the standard slope. Forced carries make a course disproportionately harder for bogey golfers because they hit shorter. — [USGA Rules of Handicapping, Appendix G](https://www.usga.org/content/usga/home-page/handicapping/roh/Content/rules/Appendix%20G%20Golf%20Course%20CourseRatingSlopeRating.htm); [USGA: What exactly are Course Rating and Slope Rating (2025)](https://www.usga.org/content/usga/home-page/articles/2025/11/what-exactly-are-course-rating-slope-rating.html) (via search summary)
- Strategic design (hazards near the ideal line rather than across all routes) is more playable for high handicappers while still challenging low handicappers. — [GOLF.com: 3 schools](https://golf.com/travel/3-schools-golf-course-architecture/) (already in the earlier notes; restated here only because it explains why slope rises with forced carries)
- Game precedent for tiered ramps: Wii Sports Golf groups its nine holes into three difficulty tiers of 3 holes (beginner, intermediate, expert). — [StrategyWiki: Wii Sports/Golf](https://StrategyWiki.org/wiki/Wii_Sports/Golf) (via search summary)
- A review of a long-running arcade golf series notes that one entry "pushes the nuances of its course design" hardest in its last course, a finale-style ramp. — [Birth by Drip: Hot Shots Golf World Invitational review](https://birthbydrip.neocities.org/reviews/hot_shots_golf_wi) (low-authority source, via search summary)

### Inferences
- **Game hole difficulty score (proposal, mirrors the USGA structure):**
  `D = L_eff / L_ref + sum_i w_i * F_i` where `L_eff` = length adjusted for elevation (e.g. +/-1 m per 1 m of height difference, to be tuned with the physics), wind (per course preset), dogleg distance and forced lay-ups; and `F_i` (0-10) are scored at the game golfer's landing zones (driver at ~175-190 m, then the approach):
  - Fairway: landing-zone width vs driver lateral dispersion (e.g. 0 if width >= 4 sigma, 10 if <= 1.5 sigma).
  - Green target: green effective diameter vs approach length (USGA logic: the same 210 yd shot rates much harder to a 19 yd green than to a 32 yd one).
  - Crossing / lateral hazards: carry required as a fraction of club carry, and distance from the landing centre to the hazard edge in sigmas.
  - Bunkers and rough: recovery difficulty from the game's lie penalties.
  - Green surface: max cup-zone slope, tier count, speed.
  - Topography: blind shots and stance/elevation.
  - Psychological: +1-2 when 3+ other factors >= 6 (copying the USGA concept).
- **Empirical rating (recommended, cheap with the existing CPU):** run the CPU at two skill presets ("casual" ~ bogey dispersion, "expert" ~ scratch dispersion) for N=200 seeded rounds per hole headlessly (pure logic + core/Rng.gd). Record mean strokes. "Rating" = expert mean, "slope" = casual mean - expert mean. Holes whose casual-expert gap is large are "forced-carry style" (bad for beginners). Holes where both personas score near par are "release" holes. This gives a data-driven difficulty curve for all 36 holes and catches unfair holes. The `ai-opponent` and `physics-tune` skills already produce self-play stats.
- **Ramp levers across 4 courses (proposed bands, tie to measured dispersion):**

| Lever | Course 1 (Beginner) | Course 2 (Intermediate) | Course 3 (Advanced) | Course 4 (Expert) |
|---|---|---|---|---|
| Par (9 holes) | 35 | 34-35 | 35-36 | 35-36 |
| Total length | ~2,200-2,300 m | ~2,300-2,450 m | ~2,450-2,650 m | ~2,400-2,650 m (difficulty from precision, not length) |
| Landing-zone width | 40-50 m | 32-40 m | 26-32 m | 20-26 m |
| Approach green diameter | 28-36 m | 24-30 m | 20-26 m | 16-22 m (island ~20) |
| Max cup-zone slope | 1.5% | 2% | 2.5% | 3% (never above) |
| Green tiers/swales | 0-1 | 1 | 1-2 (Biarritz, Double Plateau) | 2 + false fronts |
| Forced carries | none from the main tee (always a bail-out) | 1 short (<= 110 m) | 2, with bail-outs | 3+, some all-or-nothing (island) |
| Penal holes | 0 | 1 (peninsula) | 1-2 | 2 (never consecutive) |
| Blind shots | 0 | 0 | 1-2 (Alps/Dell, with a marker) | 1 |
| Wind (course preset) | 0-3 m/s | 2-6 m/s (links) | 2-5 m/s plus elevation | 3-8 m/s, gusts |
| Target CPU-casual average over par | +4 to +6 | +6 to +9 | +8 to +12 | +10 to +15 |

  These bands are my proposals and must be retuned once the game's real shot dispersion and lie penalties are fixed.
- **Within-course curve:** follow the 3-tier idea inside each 9 (holes 1-3 easier, 4-6 medium, 7-9 hardest) but keep a release hole in slot 5 or 7, and make the finisher spectacular rather than simply the hardest.
- **Unlock gating:** unlock Course N+1 by finishing Course N (any score) to avoid hard walls. Offer per-course stars (par, -2, -4) for mastery so beginners progress and experts have targets.

### Gaps
- The numeric USGA lookup tables (landing-zone width -> fairway rating, green diameter/approach -> green-target rating, obstacle stroke-value weights) were not accessible; the Course Rating System Manual copies found online did not render. The weighting in the proposed formula is therefore unsourced.
- The "Slope ranges 55-155" figure is widely repeated but I did not verify it in a fetched source.
- No published difficulty-tuning data or postmortems from commercial golf games were found; tier counts come from wiki/review summaries.

---

## 4. Fun factors specific to games: signature holes, spectacle, trick shots, short holes, memorability

### Takeaway
Memorable holes in real golf are the ones that pose a clear, dramatic choice with a visible consequence: island greens, drivable par 4s, a reachable par 5 over water, a Cape tee shot. Games add spectacle (landmarks, elevation, waterfalls) and benefit from short holes that resolve quickly. Sources on game-specific fun are thin; the strongest evidence is real-golf drama (the island green's huge ball-loss numbers, the drivable par 4 "go for it" rate) plus reviews praising risk/reward and verticality.

### Cited Findings
- A few penal holes add drama, but too many become boring. — [GOLF.com: 3 schools](https://golf.com/travel/3-schools-golf-course-architecture/) (in the earlier notes; restated for the signature-hole rule)
- The island green is one of golf's most famous holes despite being the shortest on its course (137 yd), largely because of its all-or-nothing water carry; commonly cited estimates put ball losses at ~100,000-120,000 per year. — [GOLF.com: 15 numbers](https://golf.com/travel/15-numbers-know-island-green-17th-hole/); [CBS Sports: what to know about the island green (2026)](https://www.cbssports.com/golf/news/tpc-sawgrass-17th-hole-island-green) (via search summary)
- Drivable par 4s create intrigue because they force a choice. The best ones are those where "nearly everyone goes for it" (players' view), and a USGA article cites ~60% going for the green as a sign of success. The only par 4 ace in PGA Tour history came on a 332 yd drivable hole, a "highlight" moment such holes make possible. — [Links Magazine: Tour pros' favorite drivable par 4s](https://linksmagazine.com/?p=89845); [USGA: drivable par 4s](https://www.usga.org/content/usga/home-page/championships/2016/u-s--amateur-four-ball/articles/drivable-par-4s-add-intrigue-to-match-play-strategy.html); [GOLF.com: Weiskopf](https://golf.com/news/tom-weiskopf-reveals-risks-rewards-drivable-par-4/) (via search summary)
- Template designers used dramatic backdrops or elevation changes to enhance the look of their Short holes. — [Links Magazine: Template holes](https://linksmagazine.com/?p=40752) (via search summary)
- Game reviews: *Cursed to Golf* is praised for balancing risk and reward through "varied level design", verticality and small self-contained ledge challenges. — [GameSpot: Cursed to Golf review](https://Gamespot.com/reviews/cursed-to-golf-review-an-ace-in-the-hole/1900-6417942/) (via search summary)
- A short par 3 with a big carry is treated as a fresh design opportunity: designers fit "a 135-yard hole into a route" to create Short templates. — [Top 100: S is for Short](https://www.top100golfcourses.com/news-item/s-is-for-short-template-holes)

### Inferences
- **One signature hole per course**, in slot 6 or 9, built on spectacle the theme can uniquely provide:
  - Course 1 (meadow/parkland): a downhill par 3 over a pond from a hilltop tee with a windmill or barn landmark. A "fun" hole, not penal.
  - Course 2 (coastal links/cliffs): a Cape par 4 along a cliff edge with a lighthouse-like landmark, or a Biarritz played into the sea wind.
  - Course 3 (canyon/desert mesas): a Road-style par 4 driving over a rock arch, or a par 3 from mesa to mesa across a chasm (forced carry with a lower bail-out mesa).
  - Course 4 (volcanic lagoon/tropical): an island par 3 with a waterfall backdrop, plus a reachable par 5 finisher over a lagoon.
- **Trick-shot opportunities** (optional, never required): a kicker bank (Redan), a punchbowl rim, a firm downslope that adds 30-60 m of roll ("discrete reward without risk" in the earlier notes' taxonomy), a cart-path/stone bridge skip, a ricochet off rock walls in the canyon course. Award a small cosmetic bonus or achievement for these instead of making them optimal.
- **Short exciting holes for mobile sessions:** par 3s and drivable par 4s resolve in 2-4 shots. Make 3-4 of each 9 one of these so a 9-hole round fits ~6-8 minutes (pace estimate from the earlier notes). A "Quick 3" mode (three signature/short holes) can reuse the same content.
- **What players remember** (inference from the above): a visible landmark, a single dramatic choice, and a result they could see coming (ball in flight over water). Design the flyover and camera to frame the signature hazard, and replay "hero shots" (holes-in-one, eagles on drivable par 4s, 2-in-2 over water) as auto-replays.
- **Keep penal holes short:** the island-green archetype works partly because it is the shortest hole. Penal plus long equals frustration on a touch screen.

### Gaps
- I found no GDC talk, postmortem or player-research data on which golf-game holes players remember or replay, and no design write-up from commercial mobile golf games on signature holes. Everything game-specific in this section beyond the cited reviews is inference.

---

## 5. Scaled numbers for a real-metre mobile game (driver ~175 m, 7-iron ~130 m, wedge ~95 m)

### Takeaway
Scaling the USGA par bands and the template yardages by k≈0.85 (game driver vs scratch driver carry) gives par 3s of ~90-185 m, par 4s of ~190-370 m (drivable at ~190-215 m) and par 5s of ~380-480 m, with "reach in two" at ~365 m (scratch-equivalent) or ~340 m (bogey-equivalent). Green size should follow approach length, not hole length: ~18-24 m across for wedge approaches, ~24-30 m for mid irons, ~30-36 m for long approaches, shrinking by about 15-25% on harder courses.

### Cited Findings
- USGA par length bands (men): par 3 < 260 yd, par 4 240-490 yd, par 5 450-710 yd. — [Wikipedia: Par (golf)](https://en.wikipedia.org/wiki/Par_(golf)) (also in the earlier notes)
- Reach-in-two benchmarks: scratch 470 yd (430 m), bogey 370 yd (338 m). Scratch carry 225 yd (206 m) + 25 yd roll; bogey carry 180 yd (165 m) + 20 yd roll. — [GOLF.com: How a golf hole is rated](https://golf.com/?p=15450386)
- Green-target example: a 210 yd (192 m) approach to a 32 yd (29 m) green vs a 19 yd (17 m) green; the smaller green rates much harder. — [TXGA: Understanding Course Rating](https://txga.org/understanding-course-rating/) (via search summary)
- Real island green: ~23.8 m long, ~363 m², at 137 yd (125 m). Biarritz green 60-80 yd (55-73 m) deep, swale 1-1.5 m. Short template green "wide rather than long". — [GOLF.com: 15 numbers](https://golf.com/travel/15-numbers-know-island-green-17th-hole/); [Top 100: Biarritz](https://www.top100golfcourses.com/news-item/b-is-for-biarritz-template-holes); [Top 100: Short](https://www.top100golfcourses.com/news-item/s-is-for-short-template-holes)
- Average real green ~5,500 sq ft (~510 m²); range ~3,500-9,000 sq ft. — earlier notes ([USGA: Brookline small greens](https://www.usga.org/content/usga/home-page/articles/2022/06/brookline-small-greens-maintain-play.html))

### Inferences
- **Par bands for Cup Dash (USGA bands x 0.9144 x 0.85, then narrowed for mobile pacing):**

| Par | Scaled USGA band (m) | Recommended game range (m) | Notes |
|---|---|---|---|
| 3 | < 202 | 90-185 | Wedge (90-105), short iron (110-135), mid iron (135-160), wood (160-185, Biarritz/long Redan) |
| 4 (drivable) | from 186 | 190-215 | Must be within good-shot driver carry + roll (~175 + 15-40 m) |
| 4 (standard) | 186-381 | 255-330 | Driver (~190 m total) + 7-iron/wedge approach (65-140 m) |
| 4 (long) | up to 381 | 330-370 | Driver + long iron/wood; use rarely, max 1 per course |
| 5 (reachable) | from 350 | 370-420 | Two excellent shots (driver + wood, ~190 + ~175 m), often needing downhill/firm turf; water in front for heroics |
| 5 (three-shot) | 350-552 | 430-480 | Max 1 per course on mobile; never on Course 1 |

- **Design landing zones at the game golfer's driver total (~185-195 m on flat fairway), not the USGA 250/200 yd.** Corners of doglegs, Principal's Nose bunkers, neck pinches (Bottle) and Cape diagonals should be placed relative to 175 m carry and 190 m total, with a "bold line" that needs ~165-175 m of carry and a "safe line" needing ~120-140 m.
- **Green sizes by archetype (game, effective diameter or W x D):**

| Archetype | Green (m) | Area (approx. m²) |
|---|---|---|
| Short (wedge) | 30 W x 18 D | ~420 |
| Island / peninsula | 22-24 x 16-18 | ~300-360 |
| Redan | 32 x 18 angled 45° | ~450 |
| Eden | 25 x 16 | ~310 |
| Biarritz | 20 W x 45-60 D | ~900-1,200 (largest on the course) |
| Double Plateau | 40 x 25 | ~780 |
| Punchbowl | 25-30 diameter, inside a bowl 40 m across | ~490-700 |
| Drivable par 4 | 20-25 diameter, narrow front | ~310-490 |
| Standard par 4 (7-iron in) | 24-30 diameter | ~450-700 |
| Reachable par 5 (wood in) | 28-34 x 22-26, shallow behind water | ~500-700 |
| Three-shot par 5 (wedge in) | 18-24 diameter, heavily contoured | ~250-450 |

  Shrink by 15-25% on Course 4 and grow by 15-25% on Course 1 (see the ramp table in Q3).
- **Example 36-hole skeleton (proposal; lengths in m; P=penal, S=strategic, H=heroic, F=fun/release):**
  - **Course 1, beginner "meadow" (par 35, ~2,270 m):** 1 wide par 4 280 (F) · 2 Short par 3 100 (S) · 3 dogleg-right par 4 290 (S) · 4 reachable par 5 390, no water, cross bunkers (H-lite) · 5 punchbowl par 4 260 (F) · 6 SIGNATURE downhill par 3 140 over a pond with a bail-out (F/H) · 7 drivable par 4 200 with a wide lay-up (H) · 8 split-fairway par 4 310 (S) · 9 dogleg-left par 4 300 to a gentle plateau green (S). (2 par 3s + 6 par 4s + 1 par 5 = par 35.)
  - **Course 2, intermediate "coastal links" (par 34, ~2,370 m):** 1 Sahara par 4 250 · 2 Redan par 3 150 · 3 Leven par 4 290 · 4 Bottle par 4 300 · 5 three-shot par 5 440 with a links ground game · 6 SIGNATURE cliff Cape par 4 310 · 7 Eden par 3 130 into the wind · 8 Double Plateau par 4 320 · 9 peninsula par 3 175 or Biarritz 175 finisher. (3 par 3s + 5 par 4s + 1 par 5 = par 34; turn hole 9 into a Cape-style par 4 for par 35.)
  - **Course 3, advanced "canyon/mesa" (par 35, ~2,545 m):** 1 forced-carry par 4 270 with a bail-out · 2 downhill par 3 165 · 3 Alps par 4 300 to a punchbowl · 4 Reverse Redan par 3 160 · 5 reachable par 5 400 down a canyon (H) · 6 SIGNATURE Road-style par 4 330 driving over a rock arch · 7 blind (Dell-like) par 3 120 with a marker · 8 dogleg-left par 4 340 around a ravine · 9 three-shot par 5 460 with a split route. (3 par 3s + 4 par 4s + 2 par 5s = par 35.)
  - **Course 4, expert "volcanic lagoon" (par 35, ~2,490 m):** 1 Cape par 4 300 · 2 Biarritz par 3 180 · 3 Bottle par 4 320 with water forming the neck · 4 drivable par 4 205 to an island-ish green (H) · 5 punchbowl par 4 280 (F, release) · 6 SIGNATURE island par 3 105 with a waterfall backdrop (P) · 7 long par 4 360 with a lateral lagoon (S) · 8 Double Plateau par 4 330 with false fronts · 9 reachable par 5 410 over a lagoon (H). (2 par 3s + 6 par 4s + 1 par 5 = par 35. Shorter than Course 3 on purpose: harder through narrower targets, smaller greens and more water, per the earlier notes' principle of adding difficulty with hazards rather than length.)
  - Across the 36 holes: each core template appears 1-2 times, mirrored or re-themed when repeated, and each course has 1 signature hole, 1-2 release holes and an escalating number of forced carries (0/1/2/3+).
- **Readability check:** hole lengths of 300-480 m will not fit a single portrait overview at a usable scale. Plan a tee-to-green flyover plus an aim camera that frames the current landing zone. This links to the readability notes in the earlier file.

### Gaps
- The game's actual shot dispersion, roll on fairway/green and lie penalties are not yet fixed, so landing-zone widths and green diameters cannot yet be derived from "N x sigma". All widths, diameters, pars and course totals above are proposals for tuning via headless CPU self-play.
- The k=0.85 scaling against a scratch player is a judgement call. If playtests show the target player is closer to "bogey" (~165 m carry), scale template lengths by ~1.0 against bogey numbers instead (lengths would grow by ~5-10%).
