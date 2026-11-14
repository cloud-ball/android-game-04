# Physics "feel" benchmarks for Cue Club: real-world reference values, what our solver measures, and a self-test protocol

Notation: **LIT** = a value from published or real-world sources (cited inline). **MEASURED** = a number we got by running our own solver (`shared/cue_sim`, at commit b66a1be, default `CueParams`) headless with Godot 4.7.2, using scratch SceneTree scripts (`godot --headless --path . --script <script>.gd`). The scripts are in the session scratchpad, not in the repo, and every MEASURED bullet describes what its script did. Unless a bullet says otherwise, a measurement uses the live 1/240 s substep and the real 7-ft table (1.981 x 0.991 m). Some tests use a 30 m x 30 m table so that a second cushion cannot get in the way. That table is built from the same `CueParams`, with only `table_w`/`table_l` changed. Speed conversions: 1 mph = 0.447 m/s.

## Break: balls pocketed, spread, scratch rate, break speeds, and what our solver produces at 8-12 m/s

### Takeaway
Real top pros break at about 11-13 m/s and pocket at least one ball on roughly 46-85% of 8-ball breaks. On 7-ft bar tables the figure is about 80%, with about 0.7-0.8 balls per break across all breaks. They scratch on about 2-8% of breaks. Our solver pockets far fewer: a ball drops on only 3-25% of breaks at 8-10 m/s (about 0.03-0.3 balls per break), and on 40-62% at 11-12 m/s. Breaks will probably feel "dead" to anyone who doesn't hit at full power. This is the biggest gap from real play that we measured.

### Cited Findings
- LIT: "Typical top pro break speeds are in the 25-30 mph range" (11.2-13.4 m/s). Dr. Dave gives a phone-free timing formula: mph = (distance - 2.25 in) / 17.6 / time — [Dr. Dave: How fast do pros hit break shots](https://drdavepoolinfo.com/?p=1895)
- LIT: Dr. Dave's speed scale: soft touch <1 mph (<0.45 m/s); slow 1-2 mph (0.45-0.89 m/s); medium 2-4 mph (0.89-1.9 m/s); fast 4-7 mph (1.9-3.2 m/s); power shot 7-10 mph (3.2-4.5 m/s); powerful break 25-30 mph (11-13 m/s); "ridiculously powerful" break 35 mph (16 m/s) — [Dr. Dave: typical ball speeds](https://drdavepoolinfo.com/faq/speed/typical/)
- LIT (secondhand): IBM researcher George Onoda's 1990s taped measurements of pros gave 22-26 mph (average 24 mph, about 10.7 m/s) for men and about 18-22 mph for women. Amateur forum posters report 17-19 mph (7.6-8.5 m/s). These come from forum reposts and anecdotes, not a primary paper — [AZB "Break Speed" thread](https://forums.azbilliards.com/goto/post?id=5729563); [AZB "Break Speed DISCUSSION"](https://forums.azbilliards.com/goto/post?id=3674705)
- LIT: Dr. Dave's 2016 study covered 169 games of top men pros on bar tables (7-ft), from semi-finals and finals of the 2014-2016 US Bar Table, US Open 8-Ball, Chinook Winds and Wyoming Open events. 118 games (70%) used a 1st-ball power break and 51 (30%) a 2nd-ball break; a racking template was used in 62%. Results: a ball was made on the break about 80% of the time (2nd-ball break 82.4%; with template 78.1%, without 85.9%). Scratch rate was 7.6% on a 1st-ball power break and 2.0% on a 2nd-ball break. The 8 was made on 0.8% of 1st-ball breaks and 5.9% of 2nd-ball breaks. The breaker won 58.5% / 60.8%, and break-and-run rates were 51.7% / 56.9% — [Billiards Digest Aug 2016, "8-Ball Break Stats"](https://drdavepoolinfo.com/bd_articles/2016/aug16.pdf)
- LIT: Pro tournament stats compiled by AtLarge on AZB, by event. 8-ball "made ball on break" ranges from 37% (2017 World Pool Series) to 78% (2024 US Open). 2026 World 8-Ball Championship: 46% made, 50% breaker won, 25% break-and-run. 9-ball made-ball ranges from 34% (2013 Mosconi Cup) to 93% (2022 UK Open); 10-ball from 41% to 79%. Across 5,521 9-ball games, breakers won 55.8% — [Dr. Dave: Break Statistics](https://drdavepoolinfo.com/faq/break/stats/)
- LIT: At the 2024 World 8-Ball Championship the average was 0.8 balls per break across all breaks and 1.5 on successful breaks (2022 and 2026: 0.8 and 0.7). The 8-ball went down on the break 0.5% of the time in 2026 (1/205) and 2.0% in 2022 (5/244) — [AZB: Break Stats 2024 World 8-Ball](https://forums.azbilliards.com/threads/break-stats-2024-world-8-ball-championship-september-2024.568232/); [2026](https://forums.azbilliards.com/threads/break-stats-2026-world-8-ball-championship-april-2026.586135/); [2022](https://forums.azbilliards.com/threads/break-stats-2022-world-8-ball-championship-november-2022.548386/). These numbers come from a search summary of the threads; the sample is about 14-19 matches per event.
- LIT (secondhand): one AZB post cites 20 years of Accu-Stats records showing that 30-40% of 8-ball and 9-ball breaks came up dry — [AZB: Average on breaks](https://forums.azbilliards.com/threads/average-on-breaks.19527/)
- MEASURED, break sweep. Rack: `PoolRack.setup(sim, 1000+seed)`, the game's own rack with 0-0.2 mm seeded jitter. Cue ball on the head spot; stun strike (no tip offset) straight at the apex ball; 60 seeds per speed, run to rest. "Head half" means balls finishing with y < 0. "Touching pairs" means object-ball pairs closer than 2R + 2 mm, a measure of clusters left.

  | v (m/s) | mean balls pocketed | P(>=1) | P(>=2) | P(8 on break) | P(scratch) | object balls to a cushion | balls in head half | touching pairs | time to rest (s) |
  |---|---|---|---|---|---|---|---|---|---|
  | 6 | 0.02 | 2% | 0% | 0% | 0% | 4.9 | 1.1 | 4.8 | 6.1 |
  | 8 | 0.03 | 3% | 0% | 0% | 0% | 5.0 | 2.0 | 3.1 | 6.3 |
  | 9 | 0.18 | 18% | 0% | 0% | 0% | 5.0 | 2.3 | 2.5 | 6.6 |
  | 10 | 0.03 | 3% | 0% | 0% | 0% | 5.3 | 2.8 | 1.6 | 6.6 |
  | 11 | 0.42 | 40% | 2% | 0% | 5.0% | 5.9 | 1.2 | 1.2 | 7.2 |
  | 12 | 0.82 | 53% | 25% | 0% | 15.0% | 5.8 | 1.0 | 1.0 | 7.2 |

  With slight draw (tip -0.2R), 12 m/s gives 1.20 balls per break, 75% making at least one, and 1.7% scratches. At 8-10 m/s it is still 3-20%. A "side-rail break" (cue ball 12 cm off the side rail on the head string, aimed at the apex centre) pocketed 0-15% at 6-12 m/s and was often illegal below 11 m/s: only about 2.1 balls reached a cushion, against the WPA requirement of 4.
- MEASURED, sensitivity (40 seeds, centre stun break; one parameter changed at a time; mean balls pocketed / P(>=1) at 9 and 12 m/s):

  | variant | 9 m/s | 12 m/s |
  |---|---|---|
  | default | 0.28 / 25% | 0.85 / 62% |
  | e_ball 0.96 | 0.30 / 25% | 0.30 / 23% |
  | e_cushion 0.95 | 0.05 / 5% | 0.53 / 42% |
  | jitter = 0 (perfect rack) | **0.00 / 0%** | **0.00 / 0%** |
  | jitter 0.5 mm | 0.10 / 10% | 0.53 / 42% |
  | mu_roll 0.010 | 0.28 / 28% | 0.82 / 68% |
  | mu_ball 0.02 | 0.30 / 28% | 1.25 / 68% |

  With 40 seeds the 95% interval on a proportion is about ±15 points, so most of these differences are noise. The perfect-rack result is the exception: with zero jitter, 80 breaks pocketed nothing.

### Inferences
- At "strong amateur" speeds (8-10 m/s, the 17-22 mph range above) our break pockets a ball about 3-25% of the time. Pros on 7-ft tables manage about 80%, and amateurs probably land somewhere in between (amateur data is a gap). Even at 12 m/s (27 mph, pro speed) we get 53-62%, below the 7-ft pro figure. A casual player who doesn't max the power meter will see mostly dry breaks.
- Because a perfectly symmetric rack never pockets, the outcome in our solver depends heavily on how the energy splits through a nearly symmetric, perfectly rigid rack. Real racks have gaps, ball-size tolerance, and cloth and ball "squish". Candidate causes to investigate: a jitter distribution that is too small or too uniform, a perfectly head-on apex hit, the simultaneous-collision ordering inside the event solver, and the strict pocket capture circles. Anyone tuning this should use the `physics-tune` skill and sweep jitter, the cue-ball lateral aim error, and the pocket capture radius against the "P(>=1) at 9-10 m/s" metric.
- Scratch rates at 11-12 m/s (5-15% for stun) bracket the 7.6% pro 1st-ball figure, which is plausible. The 8 never went down in 360 centre breaks, against 0.5-6% in real play.
- The break leaves about 1-5 touching pairs and 1-3 balls in the head half. These have no direct literature comparison (see Gaps), but the low head-half counts suggest the spread is a bit compact.

### Gaps
- I found no published amateur break statistics (balls per break or dry-break % for league players). All the hard data covers pros.
- I found no quantitative literature on rack spread, such as the area covered, balls crossing the head string, or clusters left.
- We don't know how the in-game power meter maps to m/s. If 100% power is 12 m/s, a typical "hard" casual break might be 8-10 m/s, which is the worst range above.

## Rolling distance, table lengths, and time to stop

### Takeaway
Our friction constants sit inside Dr. Dave's published ranges. However, the WPA rail-speed test ("at least 4-4.5 table lengths" from the head spot with a firm centre-ball stroke) needs about 6 m/s in Cue Club, which is above Dr. Dave's "power shot" range. At 4.5 m/s, the top of that range, we get only 3.4 lengths. The table plays somewhat slow or dead. Most of the shortfall comes from the cushions, not the cloth.

### Cited Findings
- LIT: WPA rail test: "with the cue ball on the head spot, shot through the foot spot with center-ball English, a level cue, and a firm stroke, the ball must travel a minimum of 4 to 4 1/2 lengths of the table without jumping." The same spec sets cushion nose height at 63.5% (+1%) of the ball diameter (62.5-64.5%). Balls are 2.25 in (57.15 mm) and 5.5-6 oz (156-170 g) — [WPA Tournament Table & Equipment Specifications (poolroom.com)](https://www.poolroom.com/tournament-table-equipment-specifications/)
- LIT: Dr. Dave's typical values: ball-cloth sliding friction 0.15-0.4 (typical 0.2); rolling resistance 0.005-0.015; spin deceleration 5-15 rad/s^2; ball-ball COR 0.92-0.98; ball-ball friction 0.03-0.08; ball-rail COR 0.6-0.9 — [Dr. Dave: approximate physical properties](https://drdavepoolinfo.com/?p=2349)
- LIT: pooltool defaults: rolling friction u_r = 0.01, sliding u_s = 0.2, cushion e_c = 0.85, "taken from or based off" Dr. Dave's physical-properties page, with the caveat that "nothing here is well-researched or perfect" — [pooltool BallParams source](https://pooltool.readthedocs.io/en/latest/_modules/pooltool/objects/ball/params.html)
- MEASURED: our parameters are mu_slide 0.2, mu_roll 0.012, spin decel 10.9 rad/s^2, e_ball 0.93, mu_ball 0.055 and e_cushion 0.85, all inside Dr. Dave's ranges. Cushion contact sin(theta) = 0.27 corresponds to a nose height of 1.27R = 63.5% of the diameter, exactly the WPA nominal.
- MEASURED, rolling test. One ball starts 1 mm off the head rail and is struck straight down the long axis (no pocket on that line). Path length is integrated every substep until rest. "Lengths" = path / 1.981 m. Results as v: lengths (time to rest):

  | v (m/s) | centre hit (slides first) | natural roll from the start (tip +0.4R) |
  |---|---|---|
  | 0.5 | 0.29 (3.1 s) | 0.54 (4.3 s) |
  | 1.0 | 1.03 (5.1 s) | 1.35 (5.8 s) |
  | 2.0 | 2.01 (6.4 s) | 2.41 (6.9 s) |
  | 3.0 | 2.60 (7.2 s) | 3.11 (7.1 s) |
  | 4.0 | 3.11 (7.0 s) | 3.61 (7.8 s) |
  | 5.0 | 3.81 (8.1 s) | 4.10 (7.4 s) |
  | 6.0 | 4.12 (7.4 s) | 4.67 (8.3 s) |
- MEASURED, lag. A centre-ball lag from the head rail that comes back to about 3 cm short of the head rail after one foot-rail bounce needs v0 = 1.85 m/s (4.1 mph, the medium/fast boundary) and takes 7.1 s. With natural roll it needs 1.36 m/s, also about 7.2 s. Rolling exactly one table length (natural roll, rail to rail with no bounce) needs 0.67 m/s and takes 5.7 s.
- MEASURED, WPA test sensitivity. Ball on the head spot, centre hit straight through the foot spot; lengths travelled:

  | mu_roll | e_cushion | 3.0 m/s | 4.0 | 4.5 | 5.0 | 6.0 |
  |---|---|---|---|---|---|---|
  | **0.012** | **0.85** (current) | 2.39 | 3.03 | 3.36 | 3.66 | 3.94 |
  | 0.012 | 0.90 | 2.66 | 3.31 | 3.70 | 3.89 | 4.42 |
  | 0.012 | 0.95 | 2.78 | 3.66 | 3.93 | 4.23 | 4.85 |
  | 0.010 | 0.90 | 2.76 | 3.51 | 3.80 | 4.02 | 4.62 |
  | 0.010 | 0.95 | 2.90 | 3.77 | 4.08 | 4.42 | 4.99 |
  | 0.008 | 0.95 | 3.08 | 3.92 | 4.30 | 4.65 | 5.20 |

### Inferences
- The WPA test doesn't specify "firm" in m/s. If we read it as the top of Dr. Dave's power-shot range (4.5 m/s), the current table gives 3.4 lengths and misses the 4.0 floor. Raising e_cushion to about 0.95, or using e_cushion 0.95 with mu_roll 0.010, gets 3.9-4.1 lengths at 4.5 m/s. Both parameters stay inside the published ranges (e_c 0.6-0.9 per Dr. Dave, 0.98 per Mathavan). Retuning cushions affects breaks too: e_cushion 0.95 lowered the pocketing rate in the break sensitivity test, though within noise.
- Each straight-in cushion hit by a rolling ball returns it at only 0.55 of its speed once it is rolling again (about 30% of its kinetic energy; see the cushion section). Together with the 5/7 speed loss when a centre-hit ball starts to roll, this is the main reason long shots die early.
- Times to rest of 6-8 s for medium-to-power shots seem plausible for 7-ft play, but I found no literature value to check them against (see Gaps).

### Gaps
- Dr. Dave's TP B.6 relates speed to "table lengths of travel", but I couldn't retrieve its numbers (the PDF host returned 403 or binary). I have no literature value for lag time or for distance at a given launch speed.
- I found no cloth "speed" standard (a Stimpmeter equivalent) for pool. WPA specifies only the cloth's composition (at least 85% worsted wool).

## Cushion behaviour: rebound speed vs incoming speed, english, "dead cushion"

### Takeaway
On a rolling ball, the Han-model cushion in our solver gives an effective normal COR of 0.76-0.81. That is inside Dr. Dave's 0.6-0.9 range but below Mathavan's measured 0.98. The ratio is the same at every speed from 0.5 to 5 m/s, and the rebound angles are too. Real cushions behave differently at speed, so fast and slow banks in Cue Club follow the same geometry. Running english visibly widens and speeds up the rebound; reverse english barely narrows it.

### Cited Findings
- LIT: Mathavan, Jackson & Parkin (2010) give ball-cushion COR 0.98 and sliding friction 0.14 between ball and cushion. The rigid-cushion assumption holds only up to about 2.5 m/s normal velocity. Their model resolves slip at the cushion and table contacts together — [Mathavan et al., Proc. IMechE C 224 (2010), via Loughborough repository](https://dspace.lboro.ac.uk/2134/15087)
- LIT: ball-rail COR 0.6-0.9 — [Dr. Dave: physical properties](https://drdavepoolinfo.com/?p=2349). pooltool's Han-2005 default is e_c = 0.85 — [pooltool source](https://pooltool.readthedocs.io/en/latest/_modules/pooltool/objects/ball/params.html)
- LIT (developer blog, qualitative): most games "treat cushion bounces as simple angle reflections". On a real table, running side "comes off shallower", check side "kicks wider", and backspin changes the rebound angle — [tailuge: Why most pool games feel wrong](https://billiards.tailuge.workers.dev/blog1.html)
- MEASURED, cushion test on the 30 m table. A naturally rolling ball (w = v/R, optionally with side spin R*wz/v = s) is placed touching the rail. The solver's own `_cushion()` impulse is applied, then the ball runs until it rolls again. "Angle" is measured from the rail perpendicular. Results with no english, identical at 0.5, 1, 2, 3 and 5 m/s:

  | incidence | speed out/in (immediate) | normal COR (effective) | angle out, immediate | angle out once rolling | rolling speed / v_in |
  |---|---|---|---|---|---|
  | 0 deg | 0.811 | 0.811 | 0 | 0 | 0.548 |
  | 30 deg | 0.773 | 0.798 | 26.6 | 39.5 | 0.566 |
  | 45 deg | 0.766 | 0.783 | 43.7 | 59.5 | 0.633 |
  | 60 deg | 0.808 | 0.763 | 61.8 | 75.1 | 0.751 |
- MEASURED, english (also speed-independent). The + sign is the side spin that turned out to widen the rebound (running english for this approach):
  - 30 deg incidence, final rolling angle: s = -1: 37.3; -0.5: 37.5; 0: 39.5; +0.5: 44.3; +1: 51.4. Running english at full side adds 12 deg; reverse removes only 2 deg. Speed retained: 0.44 (reverse) to 0.74 (running).
  - 45 deg incidence: s = -1: 62.7; 0: 59.5; +1: 61.9. Once the follow curve has played out, side spin barely changes the final angle (immediate angles range 41.9-51.7).
  - 0 deg (straight in): s = ±0.5 gives ±12.3 deg; s = ±1 gives ±22.0 deg.

### Inferences
- A rolling ball sent straight into a rail comes back at about 55% of its speed once it rolls again. That matches the "rolls unnatural distances" complaint (see the complaints section) and the WPA-test shortfall above.
- Because Han's impulse is linear in velocity, every angle and ratio scales exactly with speed. Real players expect angles to change with speed: hard shots go into the cushion and come off differently. Mathavan's 2.5 m/s validity limit is the published hint that behaviour changes above that speed. One fix to consider is a speed-dependent e_cushion (lower e at high normal speed) or a Mathavan-style model, but there is a determinism and cost budget to respect.
- The asymmetry between running english (+12 deg) and reverse english (-2 deg) at 30 deg may read as "reverse english does nothing". Compare it against a real diamond-system reference before tuning.

### Gaps
- I found no published table of rebound angle against speed and english for real pool cushions. Bob Jewett and Dr. Dave have high-speed video of this, but I couldn't retrieve numeric values.
- The Mathavan COR (0.98) uses a different model decomposition from Han's e. The two numbers are not directly comparable.

## Cut shots: throw, 90-degree / 30-degree rules, aim tolerance

### Takeaway
Our solver gets cue-ball direction right: the 30-degree rule for rolling balls and a near-90-degree split for stun shots both hold. Object-ball throw is off. It is a constant 3.15 deg for any cut of about 20 deg or more, whatever the speed or roll. Real throw depends strongly on speed (slow stun about 5 deg, fast about 1-1.7 deg) and is roughly 3-4 times smaller with a rolling cue ball (about 1 deg at medium speed).

### Cited Findings
- LIT: Alciatore TP A.14 friction model: mu(v_rel) = 9.951e-3 + 0.108 exp(-1.088 v_rel), fitted to Marlow's data. Reference speeds: slow 1 mph = 0.447 m/s, medium 3 mph = 1.341 m/s, fast 7 mph = 3.129 m/s. The throw angle is atan[min(mu v cos(phi) / v_rel, 1/7) (v sin(phi) - R wz) / (v cos(phi))], where v_rel includes the follow/draw term R wx cos(phi). Stated conclusions: "slower speed results in more collision-induced throw"; "throw is independent of speed at small cut angles", "largest in the half-ball hit range (30-degree)", and larger for slower speeds at bigger cuts. For sidespin: maximum throw comes "at about 50% sidespin for a slow shot. After a point, more sidespin does not create more throw" — [Dr. Dave TP A.14](https://drdavepoolinfo.com/technical_proofs/new/TP_A-14.pdf)
- LIT: a 30 deg stun shot throws about 4.1 deg; the same cut with draw or follow throws about 0.9 deg — [Dr. Dave throw articles (search summary of billiards.colostate.edu)](https://billiards.colostate.edu/bd_articles/2006/sept06.pdf)
- LIT, computed by me from the TP A.14 equation above (no ball-cushion effects):

  | cut | slow stun | medium stun | fast stun | slow roll | medium roll | fast roll |
  |---|---|---|---|---|---|---|
  | 5 | 0.72 | 0.72 | 0.72 | 0.38 | 0.18 | 0.07 |
  | 10 | 1.44 | 1.44 | 1.44 | 0.76 | 0.35 | 0.13 |
  | 20 | 2.98 | 2.98 | 2.50 | 1.50 | 0.69 | 0.27 |
  | 30 | 4.72 | 3.55 | 1.70 | 2.19 | 1.00 | 0.39 |
  | 40 | 5.08 | 2.99 | 1.26 | 2.81 | 1.29 | 0.50 |
  | 60 | 4.62 | 2.32 | 0.89 | 3.78 | 1.74 | 0.67 |
- LIT: 90-degree rule: the cue ball leaves along the tangent line only for a stun shot. "The greater the friction and inelasticity, the more the 90 deg angle is reduced." 30-degree rule: for a rolling cue ball, cuts between a 3/4-ball hit (14 deg) and a 1/4-ball hit (49 deg) deflect the cue ball "very close to 30 deg". The maximum for natural roll is 33.7 deg, at a 28.1 deg cut — [Dr. Dave: 30-degree rule](https://drdavepoolinfo.com/FAQ/30-90-rules/30-degree-rule/); [Dr. Dave: how conditions affect the 90/30 rules](https://www.engr.colostate.edu/~dga/pool/30-90-rules/conditions/)
- MEASURED, cut test on the 30 m table. The object ball is at the origin with its target line along +y. The cue ball starts 0.5 mm short of the ghost-ball position, moving at cut angle phi, either stun (w = 0) or rolling (w = v/R). Throw = angle of the object ball's velocity right after impact (`first_hit_v`) from +y. Cue-ball deflection = final rolling direction against its incoming line. Results were identical at 0.45, 1.34, 3.13 and 6 m/s:

  | cut | throw (stun and roll) | stun: CB-OB split right after impact | rolling: final CB deflection |
  |---|---|---|---|
  | 5 | 0.74 | 64.2 | 9.2 |
  | 10 | 1.50 | 75.5 | 17.0 |
  | 20 | 3.08 | 80.5 | 26.4 |
  | 30 | 3.15 | 83.0 | **30.1** |
  | 40 | 3.15 | 84.3 | 28.8 |
  | 50 | 3.15 | 85.1 | 24.9 |
  | 60 | 3.15 | 85.7 | 19.6 |
- MEASURED, spin-induced throw on a straight-in stun shot: side ratio R*wz/v = 0.25 gives 2.12 deg; 0.5 or 1.0 gives 3.15 deg (the cap), at every speed tested.
- MEASURED, pocket tolerance as aim tolerance (from the pocket section): a straight-in corner shot accepts a 72-75 mm band of ball-centre lines, ±36 mm. From 0.6 m that is about ±3.4 deg of object-ball direction; from 1.5 m about ±1.4 deg.

### Inferences
- Small cuts (5-15 deg) match TP A.14 within 0.1 deg, and medium-speed stun at 30 deg (3.15 vs 3.55) is close. Our solver under-throws slow stun cuts at 30-60 deg by 1.5-2 deg. It over-throws fast cuts at 40-60 deg by 2-2.3 deg, and over-throws rolling-ball cuts by about 2-3 deg at medium and fast speed. Most game shots arrive rolling, so Cue Club object balls will often go about 2 deg "thick" compared with a real table. At 1.5 m from the pocket that is enough to miss a corner pocket whose tolerance is ±1.4 deg. If the aim guideline is drawn from the solver's own `first_hit_v`, players see the throw, which hides the error but teaches the wrong habit.
- There are two root causes, both visible in `_ball_ball`. First, mu_ball is a constant 0.055 instead of the speed-dependent mu(v_rel). Second, the slip vector ignores the vertical-plane term R wx cos(phi), which in a real collision takes the friction "budget" away from the tangential direction. Adding both would match TP A.14 by construction. The added exp() call can be avoided with a small lookup table so the solver stays trig-free and deterministic.
- The cue-ball direction rules hold. The rolling deflection peaks at 30.1 deg (a little under the ideal 33.7 deg because e = 0.93 and throw take some away, which Dr. Dave says is expected). Stun splits of 80-86 deg for 20-60 deg cuts are below 90 deg, as Dr. Dave predicts for real friction and inelasticity. At 5-10 deg the split drops to 64-76 deg because of e < 1. That is physically right, but players may notice a nearly full stun hit drifting forward.

### Gaps
- I couldn't extract the exact plotted maxima from TP A.24 or TP A.28 (throw with follow/draw at each speed); the PDFs returned 403. The table above is my own evaluation of the TP A.14 equation.
- I found no experimental throw data at break-like speeds above 3 m/s.

## Draw / follow / stun distances

### Takeaway
I found no published table of draw-back distances. Our solver follows the standard sliding/rolling model, so draw is strong at speed and fades over distance as it does on a real table. A maximum-draw shot (0.5R) at 2 m/s from 30 cm comes back 0.9 m; at 3 m/s it comes back 3.3 m, which is 1.7 table lengths on an unbounded table. Slow draw over long distances turns into stun or follow, which matches real experience.

### Cited Findings
- LIT: only a stun shot sends the cue ball along the tangent line. With a cut angle, the more speed the cue ball has, the longer it stays on the tangent line before the draw "takes" — [Dr. Dave TP A.4 / TP B.8-B.9 (search summary)](https://billiards.colostate.edu/technical_proofs/new/TP_B-3.pdf)
- LIT: maximum throw and spin effects are tied to tip offset, and more than about 50% side spin gives no extra throw — [Dr. Dave TP A.14](https://drdavepoolinfo.com/technical_proofs/new/TP_A-14.pdf). Cue-tip friction is about 0.6 — [Dr. Dave: physical properties](https://drdavepoolinfo.com/?p=2349)
- MEASURED, solver strike model: R*w = 2.5 (b/R) v for a level cue, with the tip offset b clamped to 0.5R. A maximum draw or follow therefore gives a spin/speed ratio of R*w/v = 1.25 (`CueSim.strike`).
- MEASURED, draw test on the 30 m table. Straight full hit with a centre-to-centre gap of d + 2R. The object ball is removed right after impact so it can't interfere. The value is the cue ball's signed travel from the contact point to rest (+ follow, - draw back), in metres. The v = 0.5 column is left out because the cue ball often never reached the object ball.

  | tip | d (m) | 1.0 m/s | 2.0 | 3.0 | 4.0 | 6.0 |
  |---|---|---|---|---|---|---|
  | -0.5 (max draw) | 0.15 | -0.03 | -1.40 | -3.87 | -7.34 | -14.16 |
  | -0.5 | 0.30 | +0.05 | -0.89 | -3.30 | -6.75 | -14.35 |
  | -0.5 | 0.60 | +0.02 | -0.13 | -2.24 | -5.62 | -14.73 |
  | -0.5 | 0.90 | (did not reach) | +0.22 | -1.31 | -4.55 | -14.33 |
  | -0.3 | 0.30 | +0.10 | -0.11 | -0.82 | -1.92 | -5.12 |
  | -0.2 | 0.30 | +0.13 | 0.00 | -0.20 | -0.61 | -1.83 |
  | 0 (centre) | 0.30 | +0.20 | +0.33 | +0.21 | +0.18 | +0.20 |
  | 0 | 0.90 | +0.14 | +0.85 | +1.27 | +0.80 | +0.57 |
  | +0.2 | 0.30 | +0.30 | +1.27 | +1.86 | +2.70 | +5.20 |
  | +0.4 (natural roll) | 0.30 | +0.40 | +1.71 | +3.88 | +6.92 | +14.84 |
  | +0.5 (max follow) | 0.30 | +0.47 | +1.98 | +4.64 | +9.19 | +12.69 |

### Inferences
- Follow on a rolling ball runs at about (2/7)^2 of the energy of a rolling ball of the original speed. +0.4R at 2 m/s follows 1.7 m, and the distance barely depends on d, which matches the "2/7 rule" behaviour of a natural-roll full hit. This is derived from the standard model, which is also what our solver uses; it is not an independent check.
- Max draw at 1 m/s stops dead within 15 cm and turns into slight follow from 30 cm or more. On a real cloth a slow draw also dies quickly, so this is qualitatively right. But the solver has no squirt, swerve or miscue (by design), so tip -0.5 is always "perfect". Players may find extreme draw too easy and too strong at 3+ m/s: 3.3 m back from 30 cm at a "fast" 3 m/s is 1.7 table lengths. Compare this against a real-table filmed test before shipping (see the protocol).
- Centre-ball "stun" leaves the cue ball drifting 0.1-0.3 m forward at short d because e_ball = 0.93 keeps 3.5% of the normal speed and the residual topspin then grows it. Players who expect stun shots to stop dead may notice this. It is realistic for e = 0.93.

### Gaps
- I found no published measured draw-back distances (metres back against speed, tip offset and distance) for real pool equipment. Dr. Dave's draw TPs (B.8, B.9) are theoretical, and I couldn't retrieve their numbers.
- I found no data on the practical maximum spin/speed ratio amateurs reach. The 0.5R miscue limit is the theoretical bound, and real players often hit 0.3-0.4R, but that last point is from general knowledge, not cited.

## Pocket difficulty: mouth width, facing angle, "fairness", casual pocket sizes

### Takeaway
Cue Club's pockets sit at the WPA tournament maximum (corner 11.8 cm against a 11.43-11.75 cm spec; side 13.0 cm against 12.7-13.02 cm), so they are tight, pro-style pockets on a 7-ft table. Measured tolerance follows Dr. Dave's qualitative findings: corners are much larger at slow speed and shallow angles, and the side pocket's effective size falls steeply with angle. Fast balls are rejected only slightly more than slow ones, though, so speed is not punished as it is on a real table. I found no hard evidence on mobile games' pocket sizes.

### Cited Findings
- LIT: WPA pocket mouths: corner 4.5-4.625 in (11.43-11.75 cm), side 5-5.125 in (12.7-13.02 cm). Facing ("horizontal cut") angle: corner 142 deg (+1), side 104 deg (+1). Vertical pocket angle 12-15 deg; shelf depth corner 1-2.25 in, side 0-0.375 in — [WPA specs (poolroom.com)](https://www.poolroom.com/tournament-table-equipment-specifications/)
- LIT: "Pocket size is the most important attribute affecting pocket difficulty". Dr. Dave's Table Difficulty Factor is TDF = TSF x PSF x PAF x PLF (table size x pocket size x pocket angle x shelf), with 1 meaning standard. Making pockets smaller "does more to limit pocket cheating than cause misses" for good players — [Dr. Dave: TDF](https://drdavepoolinfo.com/faq/table/tdf/). Forum figures cite a table size factor of about 0.85 for a 7-ft table against 1.0 for 9-ft; one poster argued that a 5 in "bucket" against a 4.5 in "tight" pocket should move PSF from 1.0 to 0.85. These are secondhand and disputed — [AZB TDF thread](https://forums.azbilliards.com/goto/post?id=4232462); [AZB 7 vs 9 ft](https://forums.azbilliards.com/goto/post?id=5076286)
- LIT: a pocket's effective size, "especially a corner pocket, is much larger at slower speed". At shallow angles a slow ball can glance off the rail in front of the pocket and still drop. At fast speed the aiming centre moves away from the cushion on the facing. The slow-shot target centre shifts by up to about 0.6 in for a corner and 0.3 in for a side pocket. On many bar boxes the corners are larger than the sides, and pockets are sometimes "shimmed" smaller to make a table play tougher — [Dr. Dave: pocket size and centre](https://drdavepoolinfo.com/FAQ/pocket/size-and-center/)
- LIT: the side pocket's effective target size drops sharply as the angle increases. Corners are smaller than sides at most angles but more favourable at shallow angles to the rails (roughly 40 deg or less) — [Dr. Dave TP 3.5 / 3.6 (search summary)](https://billiards.colostate.edu/technical_proofs/TP_3-5.pdf)
- MEASURED, pocket window test on the real table. A single naturally rolling ball (tip +0.4R) is launched from 0.6 m before the mouth centre at a given approach angle (0 = straight down the pocket centreline; for corners, 45 = parallel to the long rail). Parallel aim lines are swept in 0.5 mm steps, and the result is the width of the largest contiguous band that pockets in the intended pocket. Geometric reference: mouth minus ball diameter = 61 mm (corner) and 73 mm (side).

  | pocket, approach | 0.6 m/s | 1.5 m/s | 3.0 m/s | 6.0 m/s |
  |---|---|---|---|---|
  | corner 0 deg | 75.5 mm | 72.5 | 71.5 | 71.5 |
  | corner 15 deg | 110.5 | 70.0 | 68.0 | 68.0 |
  | corner 30 deg | 125.5 | 123.5 | 93.0 | 86.5 |
  | corner 40 deg | 97.0 | 95.0 | 94.5 | 94.5 |
  | corner 45 deg (along rail) | 42.0 | 40.0 | 40.0 | 39.5 |
  | side 0 deg | 87.5 | 84.5 | 83.5 | 83.5 |
  | side 15 deg | 83.0 | 80.0 | 79.5 | 79.0 |
  | side 30 deg | 71.0 | 68.5 | 68.0 | 68.0 |
  | side 45 deg | 52.0 | 50.0 | 50.0 | 49.5 |
  | side 60 deg | 23.0 | 20.0 | 19.5 | n/a |

  For the corner at 15-40 deg, the windows include lines that "cheat" in off the long-rail cushion in front of the pocket. The along-rail case is limited by the rail: only lines on the table side count.

### Inferences
- Qualitatively we match Dr. Dave: corner tolerance at slow speed and shallow angles is larger (110-125 mm), and side tolerance shrinks steeply from 84 mm at 0 deg to 20 mm at 60 deg. Straight-in tolerance exceeds the bare geometric gap by 10-15 mm because the facings funnel balls in.
- Speed changes tolerance by only about 3-5% outside the corner 15-30 deg cases. Real pockets reject fast balls through facing rattles and the back of the pocket, but our capture circle accepts any ball whose centre crosses it. Casual players won't mind, but experienced players will feel that "slamming balls in" works too well. A capture rule that depends on speed, or a back-of-pocket rebound, would address this.
- For a casual mobile audience, pro-maximum pockets on a 7-ft table are a deliberate difficulty choice. The table-size factor (about 0.85 for 7-ft) makes the game easier; tight pockets push the other way. If players find the game hard, an "Easy" pocket mode at about 12.7 cm corners (5 in, "bucket" bar-box size) has some real-world precedent. That figure comes from forum discussion and is not a standard.

### Gaps
- I found no measurement of pocket size in popular mobile pool games, and no player research on whether casual games use oversized pockets. Visually they appear large, but that is unverified, so I make no claim.
- I couldn't get Dr. Dave's numeric effective-target-size tables (TP 3.5/3.6, Pool Shot Analyzer) or Jewett's 2013 measured pocket-size articles, so there are no inch values to compare our millimetre widths against directly.
- Standard bar-box (coin-op 7-ft) pocket dimensions: no authoritative source found.

## Known "fake physics" complaints about mobile and casual pool games, and their causes

### Takeaway
The recurring complaints are cushions that reflect like a mirror and ignore spin, side spin that does "nothing, too much, or something unpredictable", missing or wrong throw, balls that roll unnatural distances or come off cushions strangely, and floaty, elastic collisions. Cue Club already models spin on the cushions and some throw. Our measured weak spots map onto these complaints: speed-invariant cushions, wrong throw scaling, a dead-ish rail, and weak breaks.

### Cited Findings
- LIT: "Most games treat cushion bounces as simple angle reflections"; side spin seems to "do nothing, or too much, or something completely unpredictable"; throw and spin transfer between balls "get ignored entirely" — [tailuge blog: Why most pool games feel wrong](https://billiards.tailuge.workers.dev/blog1.html)
- LIT: in lesser games "balls come off cushions strangely and roll unnatural distances at unconvincing speeds" (review of Virtual Pool HD, contrasting it with weaker games) — [PocketGamer: Virtual Pool HD review](https://www.pocketgamer.com/virtual-pool-hd/review/)
- LIT: one mobile pool game's review cites "iffy physics" and says "the ball physics just aren't accurate enough" — [PocketGamer: 8ball review](https://www.pocketgamer.com/8ball/review/)
- LIT: a pool-forum review of a carom app calls it close to real but says "there is still some physics wrong… especially what spin ball comes from rail" — [AZB: Chalkysticks app review](https://forums.azbilliards.com/goto/post?id=8177976)
- LIT: a developer asks why "pool balls don't lose velocity on impact with each other", the typical floaty, elastic result of a general-purpose physics engine — [Unity discussions](https://discussions.unity.com/t/pool-balls-dont-lose-velocity-on-impact-with-each-other/937044)
- LIT: Virtual Pool and Shooter's Pool are the usual community benchmarks for realism (search summary of the reviews above) — [PocketGamer: Virtual Pool HD review](https://www.pocketgamer.com/virtual-pool-hd/review/)

### Inferences
- How the complaints map to Cue Club, with evidence from the sections above:
  - "Mirror cushions": not an issue. Han's model changes angles with roll and english by up to 12-22 deg.
  - "Unnatural roll distance": partly. A rolling ball keeps only 55% of its speed off a straight-in rail, and the WPA test reaches 3.4 lengths where 4+ is the spec.
  - "Spin off the rail is wrong": possible. The effect doesn't change with speed, and reverse english is weak.
  - "Throw ignored": not ignored, but scaled wrongly (constant 3.15 deg).
  - "Floaty collisions": not an issue. e = 0.93 and friction are applied.
  - "Breaks are boring": a likely complaint given the 3-25% pocket rate at 8-10 m/s.
- The complaints themselves come mostly from review prose. No source quantifies how often players notice each issue.

### Gaps
- I didn't retrieve any Reddit or r/billiards threads, and found no app-store review mining on physics complaints for the biggest mobile pool titles. There is no frequency data on which complaint matters most.
- I found no documentation of the physics models any commercial mobile pool game uses.

## A concrete self-test protocol for Cue Club (measurable tests with target ranges)

### Takeaway
Below are 18 headless, deterministic tests. Each has a literature-anchored target and its current measured status. Five fail or warn today on core feel: the break pocket rate, the WPA rail test, throw scaling, cushion speed-invariance, and fast-ball pocket rejection. All 18 can become gdUnit4 tests that build a `CueSim`, place balls, set state, and run to rest, as the scratch scripts did.

### Cited Findings
- All targets cite the LIT sources above, and all "current" values are the MEASURED results above. Where literature gives only a qualitative statement, the threshold is a proposal and is marked "(proposed)".

| # | Test (setup) | Metric | Target (source) | Current | Status |
|---|---|---|---|---|---|
| 1 | Parameter audit | e_ball, mu_ball, mu_slide, mu_roll, spin decel, e_cushion, nose height | inside 0.92-0.98 / 0.03-0.08 / 0.15-0.4 / 0.005-0.015 / 5-15 rad/s^2 / 0.6-0.9 ([Dr. Dave](https://drdavepoolinfo.com/?p=2349)); nose 62.5-64.5% of diameter ([WPA](https://www.poolroom.com/tournament-table-equipment-specifications/)) | 0.93 / 0.055 / 0.2 / 0.012 / 10.9 / 0.85 / 63.5% | PASS |
| 2 | WPA rail test: head spot, centre ball through foot spot | table lengths travelled at 4.5 m/s (top of "power shot") | >= 4.0 ([WPA](https://www.poolroom.com/tournament-table-equipment-specifications/); speed reading proposed from [Dr. Dave speeds](https://drdavepoolinfo.com/faq/speed/typical/)) | 3.36 (4.0 needs about 6 m/s) | FAIL |
| 3 | Lag: centre hit from head rail, one bounce, stop at head rail | launch speed; time | speed in the medium-fast band 0.9-3.2 m/s ([Dr. Dave](https://drdavepoolinfo.com/faq/speed/typical/)); time: record only | 1.85 m/s; 7.1 s | PASS (time has no literature value) |
| 4 | Slide-to-roll: centre hit at v | rolling speed after transition; slide distance | 5/7 v; 12 v^2 / (49 mu_s g) (standard model; [TP A.4 family](https://billiards.colostate.edu/technical_proofs/new/TP_B-3.pdf)) | matches the closed form (built into the solver) | PASS (regression guard) |
| 5 | Straight-in rolling ball into rail | immediate rebound ratio | 0.6-0.9 ([Dr. Dave](https://drdavepoolinfo.com/?p=2349)) | 0.81 | PASS |
| 6 | Same, after it rolls again | rolling speed / v_in | >= 0.6 (proposed, to fix the "dead rail" in #2) | 0.55 | WARN |
| 7 | Rolling ball at 45 deg into rail at 1 vs 4 m/s | change in final angle with speed | non-zero; fast shots behave differently above about 2.5 m/s normal speed ([Mathavan 2010](https://dspace.lboro.ac.uk/2134/15087)); size: proposed >= 3 deg | 0.0 deg (speed-invariant) | WARN |
| 8 | English at 30 deg incidence, side ±1 | final-angle shift, running vs reverse | both visible, >= 5 deg each way (proposed; [tailuge](https://billiards.tailuge.workers.dev/blog1.html) qualitative) | +11.9 / -2.2 deg | WARN |
| 9 | 90-degree rule: stun cut 20-60 deg | CB-OB split right after impact | slightly under 90 deg, about 80-90 ([Dr. Dave](https://www.engr.colostate.edu/~dga/pool/30-90-rules/conditions/)) | 80.5-85.7 | PASS |
| 10 | 30-degree rule: rolling cut 14-49 deg | final CB deflection | about 27-34 deg, peak <= 33.7 near a 28 deg cut ([Dr. Dave](https://drdavepoolinfo.com/FAQ/30-90-rules/30-degree-rule/)) | 26.4-30.1, peak 30.1 at 30 deg | PASS |
| 11 | Collision-induced throw, stun, 30 deg cut at 0.45 / 1.34 / 3.13 m/s | OB throw | within ±0.75 deg of 4.7 / 3.6 / 1.7 ([TP A.14](https://drdavepoolinfo.com/technical_proofs/new/TP_A-14.pdf) model) | 3.15 / 3.15 / 3.15 | FAIL (slow and fast) |
| 12 | Collision-induced throw, rolling CB, 30 deg at 1.34 m/s | OB throw | about 1.0 deg ±0.5 (TP A.14; "about 0.9 deg" in [Dr. Dave](https://billiards.colostate.edu/bd_articles/2006/sept06.pdf)) | 3.15 | FAIL |
| 13 | Small-cut throw, 5-10 deg, any speed | OB throw | 0.72-1.44 deg ([TP A.14](https://drdavepoolinfo.com/technical_proofs/new/TP_A-14.pdf)) | 0.74-1.50 | PASS |
| 14 | Spin-induced throw, straight-in, side 0.25/0.5/1.0 | throw; saturation | saturates at about 50% side for a slow shot and falls at higher speed ([TP A.14](https://drdavepoolinfo.com/technical_proofs/new/TP_A-14.pdf)) | 2.1 / 3.15 / 3.15, no speed dependence | WARN |
| 15 | Draw / follow table (full hit, d = 0.15-0.9 m, tip ±0.2-0.5, v 1-6) | signed travel after contact | draw fades with distance and at low speed; follow at about (2/7)^2 energy (standard model). Absolute targets: film a real table (proposed) | see draw section (e.g. -0.89 m at 2 m/s, d = 0.3, tip -0.5) | RECORD (needs a real-table reference) |
| 16 | Pocket windows (corner 0/15/30/45 deg, side 0/30/45/60 deg at 0.6-6 m/s) | effective band | corner slow and shallow > corner fast; side shrinking steeply with angle; corner 0 deg > 61 mm geometric ([Dr. Dave](https://drdavepoolinfo.com/FAQ/pocket/size-and-center/)) | all three hold | PASS |
| 17 | Fast-ball rejection: side 0 deg and corner 0 deg at 6 vs 0.6 m/s | width ratio fast/slow | clearly < 1, proposed <= 0.85 ([Dr. Dave](https://drdavepoolinfo.com/FAQ/pocket/size-and-center/): aim centre shifts and effective size shrinks with speed) | 0.95 / 0.95 | WARN |
| 18 | Break: centre stun break, 100+ rack seeds, at 9-10 m/s and 12 m/s | P(>=1 pocketed); balls/break; P(scratch); P(8 on break); legal-break rate | at 12 m/s: P(>=1) about 50-85% and balls/break about 0.7-1.5 (pros: [Dr. Dave stats](https://drdavepoolinfo.com/faq/break/stats/), [BD 2016](https://drdavepoolinfo.com/bd_articles/2016/aug16.pdf), AZB trackers); scratch 2-8%; 8 on break 0.5-6%; at 9-10 m/s P(>=1) >= 40% (proposed, amateur); legal (>=1 pocketed or >=4 balls to a rail) >= 95% | 12 m/s: 53% / 0.82 / 15% / 0%; 9-10 m/s: 3-18%; legal 100% | FAIL at 9-10 m/s; WARN at 12 m/s |

Supporting metrics to log alongside test 18 (no literature target): time to rest (currently 6-7 s), balls in the head half (1-3), touching pairs left (1-5), cue-ball distance from the centre (0.1-0.7 m), and the perfect-rack check (currently 0 balls pocketed, which should not be the case).

### Inferences
- Suggested order of work (my judgment from the measurements, not from a source):
  1. Break pocketing (#18), because it is the first shot of every rack.
  2. Rail liveliness (#2 and #6): try e_cushion around 0.92-0.95 and mu_roll 0.010, and re-check #18 after.
  3. Throw scaling (#11, #12, #14): make mu_ball depend on v_rel and add the R wx cos(phi) slip term.
  4. Speed-dependent cushion and pocket behaviour (#7, #17).
- Every test is deterministic (seeded rack, fixed 1/240 s substep), so the targets can be exact regression bounds. Tests 2, 11 and 18 should be re-run on the phone as well as the desktop. The golden-break hash already covers bit-exactness, but not feel.
- The CLAUDE.md definition of done requires tests to stay green. Tests 2, 11, 12 and 18 would fail today, so add them as expected-fail or "tracking" tests until the solver is retuned.

### Gaps
- Draw distances (#15), lag time (#3) and the rebound-angle-vs-speed size (#7) have no published numeric reference. The best way to get one is to film a real 7-ft table with a phone and a measuring tape.
- No amateur break dataset exists to set the 9-10 m/s target, so the 40% threshold in #18 is a proposal.
