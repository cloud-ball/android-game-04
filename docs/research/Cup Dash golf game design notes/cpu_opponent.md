# CPU Golf Opponent for Cup Dash: Simulation-Planned Shots, Human-Looking Error, Difficulty Levels

Scope: a believable, fair CPU golfer for an original casual mobile golf game (Godot 4.7 GDScript, Android, offline). The CPU plans by simulation (club/power/aim/spin search toward target zones), executes with difficulty-scaled error, is deterministic given a seed, runs on a worker thread, and "thinks" visibly for about 1-2 s on a mid-range phone.

Source quality note: the strongest primary sources found are two Mark Broadie papers. (1) "Assessing Golfer Performance Using Golfmetrics" (Science and Golf V, 2008): about 40,000 shots from 130+ golfers, pros and amateurs, with dispersion by skill group. (2) "Assessing Golfer Performance on the PGA TOUR" (Interfaces 42(2), 2012): 8M+ ShotLink shots, with the full PGA TOUR expected-strokes table and a fitted putting model. I extracted both PDFs locally and quote the numbers directly. Amateur handicap stats from Arccos and Shot Scope mostly come through magazine summaries (Golf Monthly, MyGolfSpy, GolfWRX). Several of those pages were blocked (403) or truncated, so their numbers are secondary and sometimes conflict. I flag that where it happens.

---

## 1. Real shot dispersion by skill level (distance and direction error, proximity, FIR, GIR, putting)

### Takeaway
Broadie's Golfmetrics data gives what a CPU needs most: a normalized error model per skill group. It provides direction SD in degrees for tee shots, median "fractional remaining length" (FRL, miss distance as a fraction of shot length) for approach and short shots, the ratio of distance error to direction error, the putting distance with a 50% make rate, and a count of "awful" shots per round. Arccos and Shot Scope summaries fill in FIR, GIR, putts and proximity by handicap. Across skill levels the pattern is consistent. Better players are longer *and* straighter. Amateur short-game misses are about 3x longer than they are wide. The amateur scoring gap comes mostly from long-game error and a small number of disasters.

### Cited Findings

**Broadie Golfmetrics skill groups and normalized error (primary source)**
- Groups: Pro1 (PGA TOUR rounds 64-71), Pro2 (72-79), Am1 (low-handicap amateurs scoring 70-83), Am2 (mid-handicap, 84-97), Am3 (high-handicap, 98-120). Database: almost 40,000 shots, about 500 rounds, 130+ golfers, six courses, 2005-2007. — [Broadie 2008, Golfmetrics](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- Definitions. FRL = distance from endpoint to target divided by initial distance to target. Median FRL is the robust error measure. Direction error is the SD of the angle between the start-to-end line and the start-to-target line. Example: a +4° error finishes 14 yd right at 200 yd and 21 yd right at 300 yd. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- Table 1 (long tee shots, putting, sand), verbatim values. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)

  | Group | 50% one-putt distance (ft) | Avg 2-putt distance (ft) | Sand save % | Sand median FRL % | 75th-pct tee distance (yd) | Tee direction SD (deg) |
  |---|---|---|---|---|---|---|
  | Pro (64-79) | 8.2 | 30 | 50 | 16 | 297 | 4.0 |
  | Am1 (70-83) | 5.8 | 25 | 26 | 30 | 248 | 5.4 |
  | Am2 (84-97) | 5.1 | 19 | 17 | 40 | 237 | 6.4 |
  | Am3 (97-120) | 3.8 | 12 | 7 | 49 | 216 | 8.1 |

- Pros are "about twice as straight" as Am3 off the tee. Regression across individual golfers: σ(θ) = −0.0315·d0.75 + 13.2230 (degrees, with d0.75 = 75th-percentile long tee-shot distance in yards). — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- Table 2 (short game 20-60 yd and long game 100-150 yd), verbatim values. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)

  | Group | 20-60 yd % on green (Fwy / Rough) | 20-60 yd dist/dir error ratio (Fwy) | 20-60 yd median FRL % (Fwy / Rough) | 100-150 yd % on green (Fwy / Rough) | 100-150 yd median FRL % (Fwy / Rough) |
  |---|---|---|---|---|---|
  | Pro1 (64-71) | 96 / 87 | 1.5 | 7.3 / 12.9 | 85 / 63 | 5.4 / 11.1 |
  | Pro2 (72-79) | 95 / 80 | 1.6 | 9.4 / 15.3 | 77 / 46 | 5.8 / 12.8 |
  | Am1 (70-83) | 93 / 86 | 3.2 | 13.8 / 15.4 | 63 / 53 | 8.7 / 10.4 |
  | Am2 (84-97) | 81 / 72 | 3.3 | 16.9 / 21.0 | 46 / 34 | 12.0 / 13.5 |
  | Am3 (97-120) | 75 / 64 | 3.1 | 20.3 / 25.6 | 25 / 25 | 17.3 / 18.4 |

- Worked example: a Pro1 (Am1) fairway median FRL of 5.4% (8.7%) from 125 yd means half of the next shots start within 20 (33) ft of the hole. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- For amateurs, the 50% ellipses for short and sand shots are "about three times as long as they are wide", so distance errors dominate. For Am2, sand errors are about 2x rough errors (40% vs 21% median FRL). Tee shots in the 100-150 yd range have less distance error than fairway shots. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- Rough hurts pros more than amateurs: from 100-150 yd, the pro median FRL more than doubles from fairway to rough, while amateurs' rises by less than 20%. Broadie notes the pro data came largely from heavy-rough Westchester. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- **Disaster ("awful") shots**: shot value < −0.8 strokes (for example OB, most water balls, a 60-yd shot into a greenside bunker, a missed 2-ft putt). Per 18 holes, excluding putts: Pro1 0.1, Pro2 0.6, Am1 1.9, Am2 4.1, Am3 9.3 awful shots, out of 38.3 / 40.9 / 45.1 / 53.6 / 63.3 total non-putt shots. Regression: awful shots A = 0.24·S − 17.1 (S = score), so a 75-shooter has about 1 and a 95-shooter about 6. For Am1, about 4% of swings produce almost 70% of the shots lost to a scratch golfer. For Am2, fewer than 8% of swings produce over 35% of the shots lost. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- The long game (shots over 100 yd) is the biggest single contributor to the score gap. For Am1 to match Pro1 they would need to gain 2.2 (putting), 9.3 (long), 1.4 (short) and 0.7 (sand) strokes per round. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)

**Putting (primary and secondary)**
- PGA TOUR (2003-2010 ShotLink): golfers one-putt 50% of the time from 8 ft and average two putts from 33 ft. 3-putt probability stays under 10% until 40 ft. They average 0.55 three-putts per round. Amateur "90-golfers" one-putt 50% from 5 ft, average two putts from 19 ft, and three-putt about 2.3 times per round, four times as often as pros. From 16 ft the field averages 1.8 putts (about 20% one-putts, 80% two-putts). — [Broadie 2012, Interfaces](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)
- **Broadie's physical putting model** (Appendix A), which can be used directly as a CPU putting-error model. Direction error is normal with SD σθ. Roll distance is normal with mean d + t and SD σd·(d + t), where d is the distance to the hole in yards and t is the target distance past the hole. The putt holes if |θ| ≤ atan(r/d) (r = 2.125 in hole radius) and d ≤ roll ≤ d + h. Best fit for PGA TOUR: σθ = 1.46 (degrees), σd = 0.057, t = 1/2 yd (aim 1.5 ft past), h = 2/3 yd. (Symbols were partly garbled in my PDF text extraction. I confirmed the decoding by reproducing the paper's 8-ft 50% distance; see Inferences.) — [Broadie 2012](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)
- PGA TOUR make % by distance (GOLF.com, published July 2019, season not stated): 3 ft 99.4, 4 ft 91.43, 5 ft 80.72, 6 ft 70.21, 7 ft 60.6, 8 ft 52.86, 9 ft 46.38, 10 ft 41.25, 11-15 ft 30.1, 15-20 ft 18.3, 20-25 ft 12.47, 25+ ft 5.45. — [GOLF.com](https://golf.com/instruction/putting/pga-tour-putting-make-percentages-distance/)
- 2025 PGA TOUR: 99.57% made from inside 3 ft; about 12% from 20-25 ft. — [First Call Golf (2025-11-21)](https://www.firstcallgolf.com/industry-news/release/2025-11-21/the-thrill-of-draining-bombs-and-the-agony-of-short-misses) (search-snippet level, not fetched)
- Amateurs (Shot Scope, via Golf Monthly): putts per round 29.9 (scratch), 31.2 (10 hcp), 33.4 (20 hcp). 6-9 ft make rates 49% / 39% / 33%. — [Golf Monthly](https://www.golfmonthly.com/features/scratch-vs-10-vs-20-handicap-how-the-stats-compare) (figures from search summary; the page itself was truncated when fetched)
- "Average golfer" make rates: about 94% from 0-3 ft, 72% from 3-6 ft, 43% from 6-9 ft. — [GolfWRX](https://golfwrx.com/706333/what-does-the-average-golfer-look-like/) (search summary)
- 25-handicappers hole about 88% inside 3 ft. — [MyGolfSpy](https://mygolfspy.com/news-opinion/how-to-break-80-with-the-shot-scope-six/). 5-hcp golfers make 67% from 3-6 ft, 15-hcp 59%. — [MyGolfSpy](https://mygolfspy.com/news-opinion/the-key-to-lower-scores-the-putt-lengths-you-should-really-practice/) (search summary)
- Arccos: scratch averages 30.7 putts/round vs 34 for a 12-handicap. 3-putts are about 1.3/round for scratch and about 4 for a 20-handicap. — [Golf Monthly (Arccos)](https://www.golfmonthly.com/features/12-handicap-vs-scratch-how-do-the-stats-compare); [The Left Rough compilation](https://theleftrough.com/?p=18219)

**FIR / GIR / driving by handicap (secondary, Arccos and Shot Scope)**
- Arccos compilation: scratch FIR 51%, GIR 56%, drive 259 yd, 1.3 three-putts. 5 hcp FIR 49%, GIR 46%, 32.1 putts, drive 245 yd. "Mid/18" hcp FIR 42%, GIR 23%, 3.7 three-putts, drive 217 yd. 20+ hcp FIR 41%, GIR 20%, about 4 three-putts, drive 213 yd. From 150 yd (fairway), a 5-hcp gets 19% inside 20 ft and 6% inside 10 ft. — [The Left Rough (compiling Golf Monthly/Arccos articles, Jan 2024)](https://theleftrough.com/?p=18219). The compiler's own scratch scrambling figures conflict (39% vs 57%).
- Arccos GIR: scratch 56% (10.1/round), 12 hcp 31%, 10 hcp 36%, 15 hcp 27%. — [Golf Monthly](https://www.golfmonthly.com/features/12-handicap-vs-scratch-how-do-the-stats-compare); [Golf Monthly GIR](https://www.golfmonthly.com/features/how-many-greens-in-regulation-5-10-and-15-handicap-golfers). Another Shot Scope-based release gives scratch 55%, 5 hcp 38%, 10 hcp 30%. — [First Call Golf / Shot Scope (2025-12-10)](https://www.firstcallgolf.com/industry-news/release/2025-12-10/shot-scope-data-deep-dive-is-chasing-birdies-the-quickest-path-to-lower-scores). These sources conflict by a few percentage points.
- Fairways barely separate low handicaps: scratch about 50% vs 10 hcp about 48%. — [Golf Monthly](https://www.golfmonthly.com/features/scratch-golfer-vs-10-handicapper-statistical-deep-dive-comparison) (search summary)
- Club-golfer GIR by club (Shot Scope): 9-iron under 50%, 7-iron about 33%, 4-iron about 10%. PGA TOUR GIR / proximity: 100-125 yd 75.4% / 20 ft, 125-150 yd 69.3% / 23 ft, 150-175 yd about 64% / just under 30 ft. TOUR average GIR in 2023 was 66.3%. — [Golf Insider UK](https://golfinsideruk.com/approach-play-stats/)
- Miss direction: from 160 yd (TrackMan, average male amateur) most shots finished 40-100 ft *short*, and only a handful went long. — [Golf Insider UK](https://golfinsideruk.com/approach-play-stats/). From 150 yd, a 15-hcp's green misses are reported as 43% short vs 5% long. — search summary of Shot Scope coverage, not verified on a primary page (see [National Club Golfer](https://www.nationalclubgolfer.com/reviews/expectation-management-150-yard-golf-shot)).
- Proximity from 150 yd: scratch about 41 ft, 5 hcp about 58 ft. From 150-175 yd: 5 hcp 71 ft vs 15 hcp 106 ft. Green-hit rate from 150 yd: scratch 51%, 15 hcp 20%, 25 hcp 8%. From 75-99 yd: scratch about 34 ft, about +5-6 ft per handicap band, 20 hcp about 53 ft (Arccos). — [Golf Monthly proximity](https://golfmonthly.com/features/how-close-to-the-pin-do-amateur-golfers-hit-their-approach-shots); [Golf Insider UK](https://golfinsideruk.com/approach-play-stats/) (search summaries; bands differ between articles, so the numbers do not reconcile exactly)

### Inferences
- **Converting Broadie's median FRL to Gaussian sigmas** (my derivation). For a 2D normal with lateral SD σw and distance SD σl = r·σw, I measured the median radial miss by Monte Carlo (200k samples): 1.18·σw at r = 1, 1.47·σw at r = 1.5, 1.74·σw at r = 2, 2.30·σw at r = 3. So σw ≈ medianFRL·D / k(r), with k = 1.47 for pros (r ≈ 1.5) and 2.30 for amateurs (r ≈ 3) at short range. For 100-150 yd the ratio is not published. Assuming r ≈ 1.5 gives the per-group sigmas below, as fractions of shot length. Lateral angle = atan(σw/D). They sit just under the tee-shot direction SDs, which is consistent.

  | CPU tier (proxy group) | Tee dir SD | 100-150 yd lateral σ (≈deg) | 100-150 yd distance σ | 20-60 yd lateral / distance σ | Putting σθ / σd (fit, see §2) | Disaster shots per non-putt shot |
  |---|---|---|---|---|---|---|
  | Pro (Pro1) | 4.0° | 3.7% (2.1°) | 5.5% | 5.0% / 7.5% | 1.46° / 0.057 | ~0.3% (0.1/38.3) |
  | Hard (Am1, ~low single-digit) | 5.4° | 5.9% (3.4°) | 8.9% | 6.0% / 19% | ~1.6° / 0.11 | ~4% (1.9/45.1) |
  | Medium (Am2, ~15-20 hcp) | 6.4° | 8.2% (4.7°) | 12.3% | 7.3% / 24% | ~1.9° / 0.13 | ~8% (4.1/53.6) |
  | Easy (Am3, ~25-35 hcp) | 8.1° | 11.8% (6.7°) | 17.7% | 8.8% / 27% | ~2.0° / 0.20 | ~15% (9.3/63.3) |

- These numbers are a starting point for *realistic-looking* misses. The final difficulty must be tuned by self-play (§5), because the game's own physics, compact holes and wider greens change outcomes.
- Human feel comes from three features beyond plain Gaussian noise. (1) Distance error larger than direction error (r ≈ 1.5 pros, ≈ 3 amateurs at short range). (2) A short bias for weaker tiers, since amateurs miss short far more than long. (3) A fat tail: a small per-shot probability of a "mishit" (thin, fat, big push or pull, shank-like curve) whose rate scales with tier from the awful-shot data. Without the tail, a Gaussian CPU looks robotic: it never blows a hole up, then suddenly drops a shot by drifting slightly.
- For each skill group, rough should inflate error by roughly 1.1-1.3x for amateurs and about 2x for pros (Table 2), and sand by about 2x for amateurs.

### Gaps
- I found no public per-club distance and direction SD tables by handicap (for example "7-iron carry SD = X yd for a 15-hcp"). Arccos and Shot Scope publish proximity and GIR, not raw dispersion; TrackMan's amateur dispersion charts are images only.
- For 100-150 yd shots, Broadie gives the ellipses in a figure but no numeric distance/direction ratio. r ≈ 1.5 is my assumption.
- I could not fetch a primary Shot Scope or Arccos page with a clean 0/10/20/30-handicap table. Arccos and Shot Scope figures from different years conflict by about 3-6 percentage points on GIR. The MyGolfSpy "full chart" page returned 403.
- I found no 30-handicap-specific figures beyond Broadie's Am3 group (scores 98-120).

---

## 2. Strokes-gained expected-strokes tables as a CPU evaluation function

### Takeaway
Broadie's PGA TOUR baseline (Interfaces 2012, Table B.1) is the canonical expected-strokes-to-hole-out function E(distance, lie) for tee, fairway, rough, sand and recovery lies, plus a fitted putting function. It is the natural objective for the CPU: choose the candidate shot that minimizes E[strokes after the shot] + 1, averaged over its error distribution. Weaker tiers can use the same function (pro or scratch values still rank targets sensibly) or an amateur-shifted version.

### Cited Findings
- **Table B.1, PGA TOUR average strokes to hole out (distance in yards), 2003-2010, over 8 million shots** (verbatim). — [Broadie 2012, Interfaces Appendix B](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)

  | Yd | Tee | Fairway | Rough | Sand | Recovery |
  |---|---|---|---|---|---|
  | 10 | – | 2.18 | 2.34 | 2.43 | 3.45 |
  | 20 | – | 2.40 | 2.59 | 2.53 | 3.51 |
  | 30 | – | 2.52 | 2.70 | 2.66 | 3.57 |
  | 40 | – | 2.60 | 2.78 | 2.82 | 3.71 |
  | 50 | – | 2.66 | 2.87 | 2.92 | 3.79 |
  | 60 | – | 2.70 | 2.91 | 3.15 | 3.83 |
  | 70 | – | 2.72 | 2.93 | 3.21 | 3.84 |
  | 80 | – | 2.75 | 2.96 | 3.24 | 3.84 |
  | 90 | – | 2.77 | 2.99 | 3.24 | 3.82 |
  | 100 | 2.92 | 2.80 | 3.02 | 3.23 | 3.80 |
  | 120 | 2.99 | 2.85 | 3.08 | 3.21 | 3.78 |
  | 140 | 2.97 | 2.91 | 3.15 | 3.22 | 3.80 |
  | 160 | 2.99 | 2.98 | 3.23 | 3.28 | 3.81 |
  | 180 | 3.05 | 3.08 | 3.31 | 3.40 | 3.82 |
  | 200 | 3.12 | 3.19 | 3.42 | 3.55 | 3.87 |
  | 220 | 3.17 | 3.32 | 3.53 | 3.70 | 3.92 |
  | 240 | 3.25 | 3.45 | 3.64 | 3.84 | 3.97 |
  | 260 | 3.45 | 3.58 | 3.74 | 3.93 | 4.03 |
  | 280 | 3.65 | 3.69 | 3.83 | 4.00 | 4.10 |
  | 300 | 3.71 | 3.78 | 3.90 | 4.04 | 4.20 |
  | 320 | 3.79 | 3.84 | 3.95 | 4.12 | 4.31 |
  | 340 | 3.86 | 3.88 | 4.02 | 4.26 | 4.44 |
  | 360 | 3.92 | 3.95 | 4.11 | 4.41 | 4.56 |
  | 380 | 3.96 | 4.03 | 4.21 | 4.55 | 4.66 |
  | 400 | 3.99 | 4.11 | 4.30 | 4.69 | 4.75 |
  | 420 | 4.02 | 4.19 | 4.40 | 4.83 | 4.84 |
  | 440 | 4.08 | 4.27 | 4.49 | 4.97 | 4.94 |
  | 460 | 4.17 | 4.34 | 4.58 | 5.11 | 5.03 |
  | 480 | 4.28 | 4.42 | 4.68 | 5.25 | 5.13 |
  | 500 | 4.41 | 4.50 | 4.77 | 5.40 | 5.22 |
  | 520 | 4.54 | 4.58 | 4.87 | 5.54 | 5.32 |
  | 540 | 4.65 | 4.66 | 4.96 | 5.68 | 5.41 |
  | 560 | 4.74 | 4.74 | 5.06 | 5.82 | 5.51 |
  | 580 | 4.79 | 4.82 | 5.15 | 5.96 | 5.60 |
  | 600 | 4.82 | 4.89 | 5.25 | 6.10 | 5.70 |

- From 150-300 yd, recovery positions average about 0.6 strokes worse than fairway and 0.4 worse than rough. — [Broadie 2012](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)
- Strokes gained per shot = E(start) − E(end) − 1, with E = 0 when holed. OB or penalty is handled naturally: an OB shot is worth about −2 because the golfer is back at the same spot two strokes later. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- Scratch "fractional par" examples: a 140-yd par 3 = 3.2, a 200-yd par 3 = 3.5, a 14-ft putt = 1.8. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- A widely copied "simplified Broadie" teaching table gives noticeably different putting values (for example 5 ft = 1.15, 10 ft = 1.41, 20 ft = 1.67). These disagree with Broadie's own one-putt and 2-putt results (50% one-putt at 8 ft implies E(8 ft) ≈ 1.5; average 2.0 putts at 33 ft), so it should not be used. — [python-golf-analytics (secondary)](https://python-golf-analytics.pages.dev/lectures/Topic%2008%20-%20Intro%20to%20Strokes%20Gained/01%20-%20Intro%20to%20Strokes%20Gained.html), contradicted by [Broadie 2012](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)
- DataGolf notes that the rough and fairway baselines have roughly the same slope, so using the fairway curve for marginal-distance questions makes little difference. — [DataGolf](https://datagolf.com/how-much-is-10-yards-worth) (search summary)

### Inferences
- **Validated putting function.** I implemented Broadie's Appendix A model (σθ = 1.46°, σd = 0.057, t = 0.5 yd, h = 2/3 yd) and got one-putt probabilities of 3 ft 95%, 4 ft 87%, 5 ft 76%, 6 ft 66%, 8 ft 50%, 10 ft 39%, 15 ft 23%, 20 ft 15%, 25 ft 10%, 30 ft 7.5%, with the 50% point at 8.1 ft. That matches Broadie's stated 8 ft and is close to GOLF.com's TOUR table (5 ft 80.7%, 10 ft 41.3%, 20-25 ft 12.5%). The model is analytic (normal CDFs), so it is cheap enough to call thousands of times as the "green" part of E().
- **Amateur putting fits** (my fits to Broadie's 50% distances). Holding σθ ≈ 1.6-2.0° and raising σd to about 0.11 / 0.13 / 0.20 reproduces the 5.8 / 5.0 / 3.8 ft 50% points of Am1 / Am2 / Am3. However, this simple model *underpredicts* amateur 3-ft makes (it gives about 60-80% vs about 88-94% observed), because amateurs do not aim 1.5 ft past. For the CPU, give weaker tiers a smaller overshoot target (t), or add a separate green-reading error term, rather than only inflating σd. Calibrate against the 0-3 ft about 94% and 6-9 ft about 33-49% figures in §1.
- **Using E() for a game with compact, modular holes.** Real-golf yardages will not match Cup Dash's scaled holes. Rescale distance by the ratio of the game's par-4 length to a real par-4 (about 400 yd), or rebuild E() in-game by running the Pro-tier CPU many times on the generated holes offline and fitting E(d, lie) per lie (dynamic-programming style). The Broadie shape (concave in distance, with fixed lie penalties of about +0.2 rough, +0.3-0.5 sand, +0.6-0.9 recovery, +1 or +2 for water/OB) is the transferable part.
- Add game-specific lie penalties: water = +1 stroke and drop (E at drop point + 1), OB = stroke and distance (E(start) + 1), plus a "recovery" flag for tree-blocked lies, detected by a cheap raycast to the green.

### Gaps
- Broadie's book *Every Shot Counts* (2014) has amateur baselines (for example a 90-golfer table), but I could not access the table numbers online. Only the 90-golfer putting summary (50% at 5 ft, 2 putts at 19 ft) is citable here.
- No published expected-strokes table exists for mini or compact holes or for arcade physics. An in-game fit is required.

---

## 3. Shot-planning methods: target selection, grid search, Monte Carlo with noise, putting line search, sample counts, phone runtime

### Takeaway
The literature and practitioner analyses agree on three points. The best target is the one that minimizes expected strokes over the shot's dispersion pattern. That is not the pin and not "closest on average". It shifts away from hazards by an amount that grows with dispersion. For a phone, the practical design is a two-level search. Level 1 is a coarse deterministic grid of nominal shots (club x power x aim x spin) through the real flight model. Level 2 applies cheap Monte Carlo noise in landing space, with each sample scored by a lie map and E(). Common random numbers keep the comparison between candidates stable.

### Cited Findings
- Optimal target = argmin over targets of ∫ P(x | target)·SF(x) dx, where P is a normal shot distribution around the target (σ = 9.5 yd lateral in that example) and SF is Broadie strokes-from. For a pin tucked 5 yd from the left edge with a bunker, the optimum was 4.6 yd right of the pin, worth 0.06 strokes per shot over pin-hunting. In a simulated 143-player, 30-event season, cohorts aiming 3-5 yd right won 5-9 times vs once for pin-hunters (target 0) and 0 for 10 yd right, and made 247-279 cuts vs 161. — [Neil Summers, Optimal Target Strategy](https://neilsummers.github.io/golf/target-selection) (hobbyist analysis, code on GitHub; the table totals do not reconcile perfectly)
- Scott Fawcett-style example (180-yd fairway shot, Broadie values): aim at pin ≈ 2.01 expected strokes, green centre ≈ 2.03, optimized target ≈ 1.92. "The best target is not the one that minimizes expected distance from the hole." — [Elm Wealth](https://elmwealth.com/better-golfer-better-investor/) (search summary)
- Darden case "The 10th at Riviera": a bivariate-normal shot pattern around any target, plus a heat map of average strokes to complete the hole, framed as dynamic programming. — [Darden case](https://store.darden.virginia.edu/the-10th-at-riviera) (search summary)
- Patents on golf-shot simulation describe scoring dispersion-based final rest positions by expected strokes while sweeping target directions, typically within ±5° of the line to the target. — [USPTO 11285367](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/11285367); [USPTO 12109473](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/12109473) (search summary; patents, not peer-reviewed)
- Awful shots "could come from bad swings or from a strategy that is too risky, e.g., attempting shots with a low probability of success". In other words, decision quality is a separate skill axis from execution. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- Broadie's putting model is a simplification of Broadie and Bansal (2008), which models distance, direction *and green-reading* errors and "requires simulation to evaluate". — [Broadie 2012](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)
- Godot provides `WorkerThreadPool` for running tasks off the main thread and a seedable `RandomNumberGenerator` class (per-instance seed/state). Scene-tree access from threads is not thread-safe, so a worker must use pure data. — [Godot docs: WorkerThreadPool](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html); [RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html); [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html) (official docs; not re-fetched this session)

### Inferences (recommended algorithm for Cup Dash; my design, not from a source)
**Data the planner reads (pure GDScript, no Nodes):** a hole description (tee, pin, a lie raster at about 1 m cells: fairway/rough/sand/water/OB/green/trees, a height and slope grid for greens), wind vector, ball state, and the CPU tier profile. The project already requires logic in `games/golf/logic/` with no Node dependencies and seeded `core/Rng.gd`, which fits the worker-thread design.

**Step 0: club and spin pre-tables (offline or at hole load).** For each club x spin preset x power (for example 5 power steps), run the real RK4 flight model once with no wind to get carry, apex, descent angle and roll-out. Also record linear wind sensitivities (∂landing/∂headwind, ∂landing/∂crosswind). This removes most flight sims from the per-shot planner.

**Step 1: candidate generation (decision quality lives here).**
- Target zones: pin, green centre, the "fat side" points offset toward the safe side by about 0.5-1 σw of the tier, a layup point at the tier's favourite wedge distance, and a fairway centre and corner for tee shots. For each zone, pick clubs whose nominal carry plus roll fits. Aim correction for wind uses the sensitivity table, refined with 1-2 Newton iterations using the real sim.
- Coarse grid: about 3 clubs x 3 powers x 7 aim angles (±6° in 2° steps) x 2 spins ≈ 126 nominal candidates. Run the true flight and bounce sim only for the top 10-20 after a cheap table-based pre-score.

**Step 2: Monte Carlo scoring in landing space.** For each candidate, draw N noise samples from the tier's error model: lateral and distance Gaussians with ratio r, short bias, and a mishit mixture. Map each to a rest point (nominal rest + perturbation, or landing point + table roll on the sampled lie). Then score lie and E() from the raster: expected = mean(E(rest, lie) + penalty) + 1. **Use the same N noise vectors for every candidate** (common random numbers), so differences between candidates reflect the candidates and not the dice.

**Step 3: choose.** Hard and Pro tiers take the argmin. Lower tiers use a softmax over −expected/τ (higher τ = worse decisions, more pin-hunting) and/or evaluate with a *mis-estimated* dispersion: a weak CPU plans as if it were 30-50% straighter than it is, which is the classic amateur error. Then sample the *execution* noise once from the seeded RNG and play the real physics shot. The CPU never gets a different physics model.

**Sample counts.** If outcome SD ≈ 0.4-0.6 strokes for an approach, the standard error is 0.5/√N: N = 64 gives about 0.06, N = 256 about 0.03. Common random numbers shrink the error of the *difference* between nearby candidates much further. 64-128 samples per candidate on the shortlist, and 16-32 for the pre-score, should separate options that differ by 0.05 strokes or more. Smaller gaps do not matter for a casual game.

**Putting line search.** The green is a slope grid. Sweep the aim angle (for example 21 offsets across ±break estimate) x speed (target 0.3-0.6 m past) with a cheap 2D roll integrator at 60-120 Hz using the doc's green model (decel about 0.6-0.9 m/s² plus g·sin(slope)). Coarse to fine: 21x5 → best 3 → 9x5 local. Pick the line that maximizes P(hole) − λ·E(3-putt), or minimize E using Broadie's putting function on the leave. Then apply the tier's σθ / σd noise, plus a green-read error (a misread slope factor of ±10-30% by tier), to the chosen line.

**Runtime budget (to be measured on the test phone).** Per-op GDScript costs on ARM are not published reliably (gap). Rough estimate: a full 240 Hz RK4 flight (about 6 s, about 1,400 steps) plus roll could cost tens of ms in GDScript. That is why the plan runs the real sim only for the 10-20 shortlisted nominal shots (about 0.2-0.6 s) and applies noise in landing space (cheap lookups: 126 x 32 + 15 x 128 ≈ 6k samples at a few µs each, about 20-50 ms). Putting: about 150 roll sims x about 300-600 steps. Planning at 60-120 Hz instead of 240 Hz is acceptable for the planner, because the executed shot always uses the real integrator. Run it in a `WorkerThreadPool` task on immutable inputs. Keep the "thinking" presentation at a fixed 1.0-1.8 s regardless of how fast the compute finishes, so low-end phones feel the same and the computation never shows as stutter.

**Determinism.** Derive the CPU's RNG seed from (match seed, hole, stroke number), never from wall time. The planner's noise samples and the execution noise use separate RNG streams, so changing the planner's sample count does not change which execution error is drawn. That keeps replays and tests stable.

### Gaps
- I found no published runtime numbers for GDScript physics loops on mid-range Android. This must be benchmarked (the `physics-tune` skill could be used).
- I found no shipped-game write-up on sample counts for golf AI. The counts above are standard Monte Carlo error reasoning, not empirical game data.

---

## 4. Difficulty design: noise vs decision quality vs putting, avoiding noticeable rubber-banding, fairness, showing "thinking"

### Takeaway
Real data shows skill differs on several separate axes: execution dispersion, disaster rate, distance control vs direction, putting distance control, and strategy risk. A believable CPU scales each one independently per tier, in fixed profiles, with no hidden catch-up. Practitioner consensus is that players detect and resent rubber-banding. Fairness comes from identical physics, wind and rules, plus visible reasoning.

### Cited Findings
- Skill axes that differ by group (all quantified in §1): direction SD (4.0° → 8.1°), approach median FRL (5.4% → 17.3%), distance/direction ratio (1.5 pros vs about 3.2 amateurs on short shots), putting 50% distance (8.2 → 3.8 ft), sand save (50% → 7%), awful shots per round (0.1 → 9.3). — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- "For amateur golfers a significant contributor to high scores is inconsistency, i.e., a relatively small number of awful shots." — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)
- A Mario Golf: Super Rush guide says difficulty appears tied to opponents' clubs and that players otherwise rely on "the usual rubber-band AI". This is a fan observation, not a developer statement. — [GameRevolution](https://www.gamerevolution.com/guides/685698-mario-golf-super-rush-change-ai-difficulty-settings) (search summary)
- Practitioner views: players spot manipulation, and once they suspect it, trust and engagement drop. Rubber-banding "feels unfair in both directions". If used at all, adjustments should be small and only kick in when the gap is large, and a manual difficulty override is recommended. Wikipedia distinguishes dynamic difficulty adjustment from "cheating AI" that breaks the rules players are bound by. — [wayline.io](https://www.wayline.io/blog/dynamic-difficulty-adjustment-beyond-rubberbanding); [abratabia.com](https://abratabia.com/game-ai-npc/difficulty-balancing.php); [Wikipedia: Dynamic game difficulty balancing](https://en.wikipedia.org/wiki/Dynamic_game_difficulty_balancing) (design opinion, not controlled studies)
- A golf-game patent assigns difficulty values per lie and club pairing that change the human player's aim marker or cursor speed (difficulty via player controls). It does not describe CPU shot choice. — [USPTO 7297056](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7297056) (search summary)
- A golf-simulator product warns when a chosen difficulty or course does not suit a bot, for example targets beyond the bot's average driving distance. — [Awesome Golf docs: Bots](https://insights.awesome-golf.com/reference/game/bots)

### Inferences (design recommendations)
- **Fixed tier profiles, each a vector of independent knobs:** {σ_dir, σ_dist / r, short_bias, mishit_rate, rough/sand multipliers, putting σθ / σd / read_error, decision τ, dispersion self-estimate}. Suggested anchors: Easy ≈ Am3, Medium ≈ Am2, Hard ≈ Am1, with an optional unlockable Pro ≈ Pro1 (table in §1). Then scale all execution sigmas by one tuning multiplier per tier, found by self-play (§5).
- **What a weak CPU should look like:** frequent short misses, occasional big slices and fats (the mishit tail), bad lag putting (high σd) but mostly-made tap-ins, aggressive pin-hunting that sometimes finds sand. **What a strong CPU should look like:** conservative "fat side" targets, tight distance control, few disasters. Varying decision quality makes tiers feel different in style, not only in numbers.
- **No hidden rubber-banding.** If any adaptation is wanted, make it explicit and between matches. Options: auto-suggest the next tier after 3 wins, or a visible "handicap strokes" offer in match play. Mid-round adaptation in a 9-hole, 5-minute session would be both noticeable and statistically weak.
- **Fairness guarantees, all visible:** the CPU plays the same seeded wind (shown on the HUD), the same physics, lies, penalties and turn rules. It never sees future RNG draws. Its execution error is drawn *after* the plan is fixed. These properties also make the CPU unit-testable (a golden seed gives a golden shot).
- **Showing "thinking" (1-2 s).** Animate the aim reticle sweeping across 2-4 of the actual evaluated candidates. Show the club chosen and a short intent tag ("lay up", "fat side", "go for it"). On greens, show a quick top-down read with the slope grid and the chosen line. The final choice should visibly settle on the target the planner picked. Then cut to a normal swing. This tells the player the CPU makes choices, rather than "teleporting" good results. This is an inference; I found no published UX study on golf AI presentation.

### Gaps
- I found no controlled study of player perception of AI difficulty or rubber-banding specific to golf or turn-based sports games. The sources are practitioner blogs and wiki-level summaries. Hunicke (2005) "The Case for Dynamic Difficulty Adjustment in Games" is the canonical academic reference but was not reviewed here.
- I found no developer post-mortem describing how a shipped golf game (console or mobile) implements its CPU.

---

## 5. Match formats vs CPU in short sessions; handicap strokes; win-rate targets

### Takeaway
For a short mobile session, 9-hole match play (hole-by-hole) caps the damage from one blow-up hole and produces more lead changes and decisive moments than stroke play. Stroke play over 9 is simplest and matches the existing design doc ("stroke play vs a CPU rival"). The World Handicap System's singles match play allowance is 100% of the difference in Course Handicaps, so the lower player plays off zero. That gives a real-golf-grounded way to offer handicap strokes against a CPU. I found no published win-rate targets. 70/50/30% must be treated as a design choice and verified by self-play.

### Cited Findings
- WHS recommended allowance for individual match play is 100% of Course Handicap. After the allowance, the player with the lowest Playing Handicap plays off zero and the others receive the difference. Fourball match play uses 90%. — [Golf Monthly](https://www.golfmonthly.com/features/what-are-handicap-allowances-in-singles-golf); [USGA Handicap Allowances (detailed)](https://www.usga.org/content/dam/usga/pdf/Handicap-Allowances-detailed.pdf) (search summary)
- Some club commentators argue 100% in singles match play may undercut fairness in an already volatile format. — [National Club Golfer](https://www.nationalclubgolfer.com/whs/are-handicap-allowances-ruining-singles-match-play/) (opinion)
- Scale of differences to expect: in Broadie's data, total shot value per 18 holes relative to scratch was Pro1 +8.2, Pro2 +4.7, Am1 −3.2, Am2 −13.2, Am3 −25.9 (excluding putts). Adjacent tiers differ by about 8-13 strokes per 18 holes, so about 4-6 per 9 holes. — [Broadie 2008](https://business.columbia.edu/sites/default/files-efs/pubfiles/2851/broadie_wscg_v_200802.pdf)

### Inferences
- **Recommended default:** 9-hole stroke play (per the existing doc), with a "Match play" variant. In match play, a disastrous hole costs only that hole, which matters most for casual players. The CPU's planner can also switch to aggressive or safe targets based on match state (for example 1 down with 2 to play means higher τ toward aggressive zones). That makes the CPU feel human and is easy to show ("going for it!").
- **Handicap strokes vs CPU:** compute strokes = round(100% x (tier handicap − player handicap) x 9/18) and allocate them to the hardest holes first (stroke index). Show them as dots on the scorecard. The game would need a player handicap estimate, for example a rolling average of the player's last N 9-hole scores vs the Pro CPU's expected score. Stroke-index allocation follows standard handicap practice but was not verified from a primary page in this research.
- **Win-rate targets (design choice):** Easy about 70-75%, Medium about 50%, Hard about 25-35% player win rate *for a player of average skill in the target audience*. Tune them by self-play. Build a "player model" bot that applies the game's own swipe-input noise, sampled from playtest telemetry, with a simple aim policy. Run 1,000+ seeded 9-hole matches per tier headless and adjust each tier's single sigma multiplier until the targets hold (the project's `ai-opponent` skill exists for this). Also check that the tier gap is about 3-6 strokes per 9 holes, consistent with the real-golf scale above. With a 9-hole SD of roughly 3-4 strokes per side, that gives the intended win rates without making Easy look incompetent.
- **Ties:** stroke play ties need a rule (sudden-death playoff hole or a closest-to-pin shot). Match play halves holes. Best-of-3 is already used for Break & Bank in this project; a best-of-3 "nines" would not fit the 1-2 minute-per-hole budget.

### Gaps
- I found no public data on target win rates for casual-game AI difficulty tiers (golf or otherwise). 70/50/30 is unsourced and should be validated in playtests.
- No source compared stroke play vs match play engagement in mobile golf games.

---

## 6. Documented approaches from shipped golf games and academic work

### Takeaway
Shipped golf games almost never document their CPU internals. Public material is limited to fan observations (Mario Golf: Super Rush "rubber-band" AI), simulator documentation (Awesome Golf bots choose aim, then hit) and patents. The academic and quantitative foundation is Broadie's strokes-gained work (expected-strokes baseline plus a physical putting model) and expected-strokes target optimization (Summers, Fawcett / Elm Wealth, the Darden case), which is the method recommended here.

### Cited Findings
- Broadie's strokes-gained methodology was adopted by the PGA TOUR as "strokes gained-putting" in May 2011. Its putting benchmark combines a physical one-putt model, a logistic three-putt model and an average-putts function. — [Broadie 2012](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)
- The three-putt probability is fit with a logistic of a cubic in distance: p3(d) = 1/(1 + e^(a0 + a1·d + a2·d² + a3·d³)). It is combined with the one-putt model into average putts = p1 + 2(1 − p1 − p3) + 3·p3. — [Broadie 2012](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf) (coefficient values not given in the extracted text)
- Gelman and Nolan (2002) modelled putting with direction error only. Broadie generalized it to direction plus distance. Broadie and Bansal (2008) added green-reading error, and Holmes (1991) built a detailed physical hole-out model. Fearing et al. (2010) used a statistical one-putt model plus a gamma distribution for leave distance. — [Broadie 2012](https://business.columbia.edu/sites/default/files-efs/pubfiles/4996/assessing_golfer_performance.full.pdf)
- Awesome Golf: 15 named bots from "beginners to pros". On its turn a bot "chooses where to aim and hits". There are no exposed parameters. — [Awesome Golf docs](https://insights.awesome-golf.com/reference/game/bots)
- Mario Golf: Super Rush: fan-reported rubber-band AI and difficulty tied to club sets. — [GameRevolution](https://www.gamerevolution.com/guides/685698-mario-golf-super-rush-change-ai-difficulty-settings) (search summary)
- A 2025 empirical-Bayes analysis of PGA TOUR putting argues that putting skill is "nearly indistinguishable from noise" at the tour level, meaning year-to-year putting differences are mostly luck. — [arXiv 2506.21822](https://arxiv.org/html/2506.21822v1) (title and abstract-level only)
- A 2025 JQAS paper studies whether PGA TOUR shotmaking is "hitting it well or hitting it lucky" and reproduces Broadie's Table 5.2 expected strokes. — [De Gruyter JQAS 2025](https://www.degruyterbrill.com/document/doi/10.1515/jqas-2025-0046/pdf) (search snippet only)

### Inferences
- The arXiv finding supports giving even the Hard CPU visible putting variance. A CPU that drains everything inside 15 ft looks scripted. Real pros make only about 41% from 10 ft and about 12% from 20-25 ft.
- There is no prior art to copy, and the project's golden rules forbid imitating a commercial game, so the CPU's presentation (personality names, intent tags, thinking animation) should be original. The underlying technique (expected-strokes Monte Carlo) is generic, academic and safe to use.

### Gaps
- I found no GDC talk, Game Developer article or AI Game Programming Wisdom chapter specifically on golf AI in the searches run. A deeper library search (AI Game Programming Wisdom 1-4, Game AI Pro 1-3 tables of contents) may turn up a sports-AI chapter, but none was confirmed.
- I found no academic paper on Monte Carlo shot selection for *game* golf AI specifically. The closest works are real-golf strategy optimizations (Summers, Darden case, patents).
