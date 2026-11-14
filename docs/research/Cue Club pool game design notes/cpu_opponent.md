# CPU opponent for 8-ball pool on mobile (Cue Club)

Research date: 2026-11-13. Primary sources: Smith, AAAI 2006 (PickPocket); Archibald, Altman & Shoham, IJCAI 2009 (CueCard) and AAMAS 2010 (skill vs strategy); Alciatore technical proofs (aim tolerance); pooltool docs and blog (simulation cost); Mick West, Game Developer 2009 (believable AI mistakes). Two numbers come from a local GDScript microbenchmark run for these notes (Godot 4.7.2, Apple M1 Pro). The script is at `/private/tmp/claude-501/-Users-sandeep-Documents-GitHub-android-game-04/dad7c57e-d1cc-4630-82fd-44fca928f646/scratchpad/gdbench/bench2.gd`. These notes describe published academic and engineering techniques only. They do not model any commercial pool game.

Units used by the computational pool literature: φ (aim) and θ (cue elevation) in degrees, V in m/s, and a/b (tip offset) in mm ([Archibald et al. AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)).

---

## 1. Computational pool research: PickPocket, CueCard, PoolFiz noise model

### Takeaway
Both tournament winners work the same way. They generate shots per (legal ball, pocket), mostly straight-ins. They vary speed and spin to get different follow-up positions. They simulate each candidate several times under Gaussian noise on the five shot parameters, and they score the resulting tables with a "number and quality of next shots" evaluation. The measured gains came from enough noisy samples per shot (about 30–50) and a strong precomputed break. Deeper lookahead added little: a second search level was worth about 5 percentage points, and spending the same time on more level-1 shots did as well.

### Cited Findings
**PickPocket (Univ. of Alberta; AAAI 2006, journal version Artificial Intelligence 171, 2007)**
- A shot has 5 continuous parameters: φ (aim), V (cue speed), θ (cue elevation), and a, b (tip offsets) — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Shot classes, in increasing difficulty: straight-in, bank (object ball off a rail), kick (cue ball off a rail first), and combination. "Difficulty increases with each additional collision." — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Straight-in generation: for every legal ball and every pocket, φ aims the object ball at the exact pocket centre. V comes from a precomputed table of minimum velocities. θ is set to the minimum feasible value, and a = b = 0. V, a and b are then varied discretely to produce more follow-up states, e.g. "V is increased in 1m/s increments up to the maximum 4.5m/s" — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Banks, kicks and combos are generated only if no straight-in shot exists — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- In about 90% of positions at least one straight-in shot existed. Safeties (played only when no straight-in existed in that experiment) were about 10% of all shots — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Search: "Probabilistic search" is expectimax in which a failed shot scores 0 and a successful one is expanded noiselessly, so it can go 4 ply. "Monte-Carlo search" perturbs each shot num_samples times with the noise model and averages the child values; it ran with num_samples = 15 at 2 ply. Both were set to decide within 60 s per shot. "Searches beyond 2-ply [are] intractable for reasonable values of num_samples." PickPocket "searches hundreds of nodes per second" — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Results (50 games per pairing, straight-in shots only): both search methods beat Greedy (take the easiest shot, no lookahead), and Monte-Carlo beat Probabilistic. In the extracted Table 1 the match scores read Greedy 13–37 Prob, Greedy 2–48 MC and Prob 12–38 MC. The PDF table did not extract cleanly, so which error model these scores belong to is uncertain. Straight-in success rose from Greedy to Prob to MC under both noise models: 55/53% to 62/64% to 68/74% under the noisier model, and 70–73% to 84–90% to 93–94% under the low-noise model. Because execution noise was the same for all, the higher rates came from better position play — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- "2-ply search performs better than 1-ply search." Each extra ply of probabilistic search gives diminishing returns, and so do more MC samples — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- PickPocket won the first computational 8-ball tournament (10th Computer Olympiad, 2005), scoring 200 points against 186, 178 and 173 in a round robin of 8-game matches — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf). It also won the 11th Olympiad — [ICGA via search summary of UAlberta thesis](https://era.library.ualberta.ca/items/e14c5fc4-4f9c-42f5-a947-8fd07ae5d1a6/download/af9ad439-9926-4af0-9c59-20be8ed14d3a)

**PoolFiz noise model**
- Execution error is zero-mean Gaussian noise added to each of the 5 parameters, with standard deviations {σφ, σθ, σV, σa, σb} — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- PickPocket's E_high = {0.185, 0.03, 0.085, 0.8, 0.8} models "a strong amateur, who can consistently pocket short, easy shots, but often misses longer shots." E_low = {0.0185, 0.003, 0.0085, 0.08, 0.08} models "a highly accurate professional" — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- The later ICGA noise model was σθ = 0.1°, σφ = 0.125°, σV = 0.075 m/s and σa = σb = 0.5 mm. "The specific level of noise was a much discussed topic prior to each tournament." — [Archibald et al. AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- PoolFiz is event-based: it solves for event times as roots of polynomials up to 4th order instead of using fixed time steps — [Leckie & Greenspan 2006 summary](https://www.springerprofessional.de/en/an-event-based-pool-physics-simulator/1276086)

**CueCard (Stanford; won the 2008 Olympiad; IJCAI 2009)**
- Pipeline:
  - Per (ball, pocket), generate directions φ with a minimum speed v0, covering straight-ins, multi-collision shots and "special shots designed to disperse clusters."
  - Generate discrete speeds from v0 to vMAX and keep those that pot noiselessly.
  - Randomise a, b and θ to create variants, and simulate each variant 25–100 times with noise.
  - Score with PickPocket's evaluation and keep the top 2 variants per (φ, v).
  - Cluster the outcome states, send the top 20 variants to a second search level, and choose the best.
  - Play a last-resort shot if the best value is below a threshold.
  
  [Archibald et al. IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Tournament: CueCard won 64 of 78 games, against 34 total wins for PickPocket. In a follow-up match CueCard beat PickPocket 492–144 — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Compute: a 20 dual-core EC2 cluster, plus a reimplemented physics engine that was 5.9× faster than PoolFiz, with a 600 s per-game limit. Yet the single-CPU tournament version still won 45% against the 20-machine version and 77% (±2%) against PickPocket. The cluster "was not essential." Forcing CueCard onto the slower PoolFiz (about 120 s-equivalent) dropped it to 42.4% (±2.68%) against the tournament version — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Samples per shot: below 30 samples, the reference version won 61% against the variant. Anything from 30 to 150 samples was indistinguishable, and performance declined as samples approached 300 because fewer shots got tried. "Minimum number of necessary samples ... somewhere between 30 and 50." A constant sample count did as well as a variable one — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Clustering: "Often, 50 states resulting from a single shot can be clustered into 5 or 10 states" before level-2 expansion — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Value of the second search level:
  - Level 2 changed the level-1 decision only 18.33% of the time.
  - Ignoring level 2 gave 45.23% (±2.0%) against the full version.
  - Spending the level-2 time on more level-1 shots gave 51.60% (±1.4%), statistically indistinguishable over 1,256 games.
  - Conclusion: "Look-ahead search and the variable number of shot samples had no effect."
  
  [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Late game: CueCard ran a noiseless search to the end of the game, weighting each shot by its success probability. It estimated the opponent's win chance with a Markov-chain model indexed by balls remaining per side, built from "thousands of self-played games" — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Opponent modelling appears only in last-resort shots (under 1% of shots): v_LR = v_CC − v_OPP — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Biggest contributors: "the break shot and increased number of samples," each of about the same magnitude — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)

**Optimization approach (Landry & Dussault, Univ. de Sherbrooke)**
- They frame shot selection as numerical optimization of the shot parameters to place the cue ball "almost anywhere," with one-shot lookahead and precomputed tables as starting points for the optimizer — [Landry & Dussault, J Intell Robot Syst 50:399–417, 2007](https://link.springer.com/doi/10.1007/s10846-007-9172-7). I could not access the full text.

### Inferences
- The proposed pipeline (enumerate pairs, ghost-ball aim, sample power/spin, simulate, score) is the same structure as PickPocket and CueCard, so the overall architecture is sound.
- The cut-down "MachineGunner" agent (section 6) and PickPocket's Greedy agent are useful ready-made baseline or "Easy" opponents.
- Because a second level added little in CueCard, the two-ply lookahead planned for Hard should be cheap: a heuristic evaluation of the resulting table (section 3) needs no extra simulations.

### Gaps
- I did not read the full PickPocket journal paper (Artificial Intelligence 171:1069–1091, 2007). Its ball-in-hand routine, break details and any timing figures are therefore missing. The AAAI paper says only that "PickPocket has additional routines" for these.
- The full text of Landry & Dussault was not accessible.

---

## 2. Shot difficulty heuristics, to prune candidates before simulating

### Takeaway
A straight-in shot's difficulty depends on four geometric parameters: cut angle α, object-ball-to-pocket distance d1, cue-to-ghost-ball distance d2, and the object ball's approach angle to the pocket β, with corner and side pockets treated separately. PickPocket stored these in a precomputed 30⁴ success-probability table. A cheaper option is a closed-form tolerance formula: the allowed aim error is the pocket's angular half-width divided by the error multiplier from cue to object ball. Run that against the CPU's own σφ and you get P(pot) with no simulation.

### Cited Findings
- Straight-in difficulty = f(cut angle α, OB–pocket distance d1, CB–OB distance d2, OB–pocket angle β), with α and d2 measured from the ghost ball. The function differs between corner and side pockets — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- PickPocket precomputes a 30×30×30×30 table over (α, d1, d2, β). Each cell holds the success rate from s = 200 noisy simulations, so it gives "accurate approximations of absolute probability values." Earlier fuzzy-logic and grey-logic systems gave only relative values — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- The table ignores blockers and the exact shot parameters. Banks, kicks and combos map to an equivalent straight-in shot times a discount factor — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Rule of thumb for effective pocket size: subtract about 2 in (a little under a ball diameter) from the point-to-point mouth width. A half-ball (30°) cut at 54 in has a cue-ball aim tolerance "less than 0.1 degree" — [Alciatore TP 3.4 (search summary; PDF returned 403)](https://billiards.colostate.edu/technical_proofs/TP_3-4.pdf)
- With an effective pocket size of 3.052 in, a 45° cut tolerates about 5.1° of object-ball angle error. Effective target size shrinks as the approach angle to the pocket grows, more so for side pockets. Slower shots see bigger effective pockets, and the pocket centre is not always the best aim point — [Alciatore TP A.2 / TP 3.5–3.8 (search summary)](https://billiards.colostate.edu/technical_proofs/new/TP_A-2.pdf)

### Inferences
- **Closed-form tolerance** (my derivation from ghost-ball geometry; check it against the solver). A cue-direction error δφ shifts the ghost ball sideways by about d2·δφ, which turns the line of centres by about d2·δφ/(2R·cos α). So:
  - δ_OB ≈ δφ · (1 + d2 / (2R cos α))
  - tol_φ ≈ atan(w_eff/2 / d1) / (1 + d2 / (2R cos α))
  - P(pot) ≈ erf(tol_φ / (σφ √2))
- Worked values, assuming w_eff = 3.052 in (from Alciatore) and R = 28.6 mm, ignoring throw and pocket-angle effects:

| Shot (d2, d1, cut) | Aim tolerance | P(pot) at σφ 0.06° | 0.125° | 0.185° | 0.3° | 0.6° | 1.0° | 2.5° |
|---|---|---|---|---|---|---|---|---|
| 0.3 m, 0.3 m, 0° | ±1.18° | 100% | 100% | 100% | 100% | 95% | 76% | 36% |
| 0.5 m, 0.5 m, 30° | ±0.40° | 100% | 100% | 97% | 82% | 49% | 31% | 13% |
| 1.0 m, 1.0 m, 0° | ±0.12° | 95% | 66% | 48% | 31% | 16% | 10% | 4% |
| 1.0 m, 1.0 m, 60° | ±0.06° | 70% | 38% | 26% | 16% | 8% | 5% | 2% |

  - Sanity check: σφ = 0.185° gives 48% on a 1 m + 1 m straight shot, which matches Smith's wording for E_high ("often misses longer shots").
- **Pruning recipe** (about 0.05 ms per candidate in GDScript, no simulation):
  1. For each legal ball and pocket, compute the ghost ball.
  2. Reject the candidate if the cut is over about 80°, the cue-to-ghost path is blocked (capsule test of width 2R against other balls), the ball-to-pocket path is blocked, or the pocket jaw is not visible.
  3. Compute P(pot) with the formula above, using a smaller w_eff for side pockets at steep approach angles.
  4. Keep the top K ≈ 6–10 candidates for simulation.
  
  Optionally replace the formula later with a PickPocket-style table filled offline by the headless solver. A 16⁴ table of bytes is 64 KB, small enough to ship as a resource.
- Banks, kicks and combos: generate them only when the best straight-in P(pot) is under about 0.3, and multiply by a fixed discount (e.g. 0.5 per extra collision; untuned guess). This mirrors PickPocket's fallback order.

### Gaps
- I could not fetch the Alciatore PDFs directly (HTTP 403), so the exact published equations are not quoted. The formula above is my own small-angle derivation and should be validated against simulated pot rates.
- No source gave PickPocket's actual discount factors for banks, kicks and combos.
- Throw (cut-induced object-ball deflection from ball–ball friction 0.05–0.06 in this solver) shifts the required aim by about 1–3°. Ghost-ball aim does not account for it, so the AI should correct aim using a noiseless simulation of the chosen shot (unsourced; standard practice).

---

## 3. Position play: evaluating cue-ball resting positions and sampling power/spin

### Takeaway
Use PickPocket's evaluation, which CueCard reused unchanged. At the resting position, list the next shots, take the top 3 distinct (ball, pocket) success probabilities, and combine them as 1.0·p1 + 0.33·p2 + 0.15·p3. Generate position variants by sweeping speed and tip offsets, then average the evaluation over noisy samples so shots with fragile position lose value.

### Cited Findings
- The dominant evaluation term is "the number and quality of the shots available," like a mobility term in chess. The value is d1·p1 + d2·p2 + … + dn·pn over the shots ranked by probability, with duplicates for the same (ball, pocket) removed. PickPocket uses n = 3, d1 = 1.0, d2 = 0.33 and d3 = 0.15, "set manually." The evaluation ranges from 0 to 1.48 — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Rationale for the discounts: three shots at 90/10/10% should be worth about the same as three at 70/70/70%. Equal weights would score the second nearly double — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- CueCard used the same evaluation: "a weighted sum of the success probability for the three best shots" — [Archibald et al. AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- Variant generation:
  - PickPocket varies V in 1 m/s steps up to 4.5 m/s and also varies a and b — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
  - CueCard uses discrete speeds from v0 to vMAX, then assigns a, b and θ randomly — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Greedy play (no position evaluation) lost 13–37 and 2–48 to the position-aware searches. Straight-in success rose with better position play although execution noise was unchanged — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- In a snooker AI with random cue-ball position and no positional play, playtesters still called it "too good." They read lucky leaves as intent — [Mick West, Game Developer, 2009](https://www.gamedeveloper.com/programming/intelligent-mistakes-how-to-incorporate-stupidity-into-your-ai-code)

### Inferences
- Make the evaluation 8-ball aware. Count only the CPU's group, and count the 8 only once the group is cleared. Penalise a scratch heavily (−1.0, roughly the opponent's ball-in-hand value). Add a small term for clusters left among the CPU's own balls (e.g. −0.1 per own ball with no makeable pocket). The 8-ball terms are unsourced but follow from the rules.
- Evaluate with the closed-form P(pot) from section 2 rather than simulating. That makes "two-ply" nearly free: a sim-free heuristic evaluation of each resulting table is effectively PickPocket's evaluation step.
- Power/spin grid per candidate (cheap, within budget): 3 speeds (soft just above v_min, medium, firm) × 3 tip positions (draw, centre, follow), plus optional left and right english for Hard only. That gives 9–15 variants. Use coarse-to-fine: run the grid noiselessly first, then spend noisy samples only on the top 2–3 variants.

### Gaps
- No source compared position evaluations quantitatively (e.g. 3-shot mobility against distance-to-ideal-zone). The PickPocket weights were hand-set, and Smith notes they "could benefit from tuning by machine learning."

---

## 4. Safety play: when to choose one and how to evaluate it

### Takeaway
Consider a safety only at the root, and only when the best offensive shot's estimated success falls below a threshold (PickPocket: 65%). Sample a wide spread of aim and speed with no spin. Evaluate each outcome from the opponent's side and pick the safety if the opponent's best value is low enough. CueCard's rule for fallback shots, v_CC − v_OPP, is a simple and general way to score safeties.

### Cited Findings
- Safety generation: sample many (φ, V) pairs with θ, a and b left at default. Sample each one i times, evaluate the result from the opponent's perspective, and average. Safeties are generated "only at the root" to limit cost — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Decision rule: if the best searched shot has success below t0, generate safeties, and play the best one if its opponent value is below t1. PickPocket uses t0 = 65% and t1 = 0.5 on the 0–1.48 scale — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Safeties "were effective under E_high, frequently returning the turn to the player" and "much less effective under E_low," because accurate opponents rarely have no shot — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- CueCard's last resort is fired when the best variant is below a threshold or nothing is feasible. It tries shots "in all directions" to find non-fouling shots, which surfaces double and triple kicks. It scores them as v_LR = v_CC − v_OPP and used them in under 1% of shots — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- "MachineGunner" chooses random directions, simulates a full-speed shot to check for legal contact, then tries speed variants with 50 noisy simulations each. It is a crude but robust shot finder — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)

### Inferences
- For mobile, cap the safety search at about 24 (φ, V) pairs:
  - 12 directions aimed at each legal ball's left and right edges.
  - 2 soft speeds, enough to reach a rail after contact so the shot is not a no-rail foul.
  - 1 noiseless simulation each, plus 4 noisy samples for the best 3.
- Score each safety as −(opponent evaluation) − (foul probability × ball-in-hand value).
- Scale the thresholds by difficulty: Easy never plays safe (casual players rarely do), Medium uses t0 ≈ 30%, Hard uses t0 ≈ 50–65%. Smith's finding implies safeties pay off most when the opponent (the human) is inaccurate, which is the typical mobile player.

### Gaps
- No source gave ball-in-hand placement algorithms. One reasonable approach: sample cue placements at 0.2–0.5 m behind the ghost ball of each top-P(pot) candidate with low cut angle, then evaluate as normal.

---

## 5. Break shot strategy for the CPU

### Takeaway
Do not search the break at runtime. Precompute one break (cue-ball placement plus shot parameters) offline with a headless sweep, tuned to keep the turn with high probability rather than to spread balls the most, then apply that difficulty's noise when it is played. For CueCard, the break alone was worth about 10% of wins.

### Cited Findings
- CueCard used "a precomputed break shot ... calculated via an extensive offline search over cue-ball locations and shot parameters." Some breaks keep the turn 97% of the time but spread nothing, while full-spread breaks were "at best ~60% successful." CueCard chose to weight keeping the turn and achieved a 92% keep-turn rate while "often" spreading many balls — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- Break ablation, CueCard against PickPocket:
  - Each with its own break: 77.4% (±2.0%).
  - Both with PickPocket's break: 65.4%.
  - Both with CueCard's break: 69.3%.
  - CueCard with its own break against CueCard with PickPocket's break: 70.1%.
  
  The break "accounted for around 10% of the wins" — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- "Break shots are typically generated offline and fine-tuned for a specific noise level" — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)

### Inferences
- Use the project's `physics-tune` skill to sweep cue placement (x across the head string) × V × spin (b) × small φ offsets. Measure keep-turn %, scratch %, and the mean evaluation of the resulting table for the breaker. Store 2–3 fixed breaks as constants.
- Apply per-difficulty noise at runtime so weaker CPUs break worse. Because the break is precomputed, it costs no thinking time.
- Match the player's break so it is not unfair: same rules, and the human gets the same power ceiling.

### Gaps
- Keep-turn rates depend on the solver's rack and restitution values. The CueCard figures (PoolFiz, 2008) will not transfer, so this needs to be measured with cue_sim.

---

## 6. Difficulty tuning: noise models, limited lookahead, deliberate mistakes, human feel, rubber-banding

### Takeaway
Execution noise is the main difficulty dial. Archibald et al. found raw skill outweighs strategy: a top planner with noise above 2.5× the tournament level loses to a naive agent with perfect execution. Use Gaussian σ on the aim angle (not a ± uniform bound) plus proportional speed noise. Use strategic depth as a second dial. Make misses look plausible rather than random, so a weak CPU does not leave lucky position the player reads as skill.

### Cited Findings
- Raw-skill experiment design:
  - About 20,000 games per agent.
  - Noise scaled 0–4.5× the ICGA model.
  - Time budgets of 20,000–120,000 simulations per game. At about 3 ms per simulation that is 1–6 minutes per game.
  
  [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- "A CueCard agent with particularly low raw skill (a noise level greater than 2.5) would be expected to lose to a MachineGunner agent with perfect raw skill" — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- Extra thinking time helps the strong planners most at noise ≈ 1.4× (CueCard) and ≈ 1.9× (SingleLevel). It helps the naive agents most at zero noise. "Superior strategic skill is most identifiable when agents have imperfect execution skill." — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- "OptimisticPlanner" plans deep but assumes noiseless outcomes. It would prefer zero noise against a weak opponent and maximum noise against better ones — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- Reference noise levels: E_low σφ = 0.0185° ("professional"), ICGA σφ = 0.125°, E_high σφ = 0.185° ("strong amateur"). σV is 0.0085, 0.075 and 0.085 m/s respectively. σa and σb are 0.08, 0.5 and 0.8 mm. σθ is 0.003, 0.1 and 0.03° — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf); [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- Mick West on believable AI mistakes:
  - A snooker AI made easier by "random angular deviation" still felt "too good," because random leaves that favour the CPU look intentional.
  - Recommended "intelligent mistakes": compute the best move, then sometimes take a plausible human error.
  - Weakening by cutting computation produces "incredibly stupid mistakes."
  - The goal is a player who feels they nearly beat a strong opponent.
  
  [West, Game Developer, Mar 2009](https://www.gamedeveloper.com/programming/intelligent-mistakes-how-to-incorporate-stupidity-into-your-ai-code)
- Indie forum and devlog practice: add aim error scaled by skill, make weaker AIs "aware of fewer advanced shots and combinations," and have them pick at random among easy shots — [GameDev.net thread](https://www.gamedev.net/forums/topic/173988-billiard-ai-how/?page=1) (forum opinion, low authority)

### Inferences
- **The noise in the current plan is miscalibrated.** By the section 2 table:
  - Easy ±2.5° pots only about 36% of 30 cm straight-ins and about 4% of 1 m + 1 m shots. That is near-random and will look broken.
  - Hard ±0.3°, if read as σ, is weaker than PickPocket's "strong amateur" (0.185°).
  
  Suggested starting σφ, to be confirmed by self-play (section 8):

| Level | σφ (aim) | σV | σ spin | Shot pool | Position play | Safeties | Think time |
|---|---|---|---|---|---|---|---|
| Easy | 0.5–0.7° | 8% of V | 0.25 R | straight-ins, top-3 by P(pot), pick weighted-random | none (centre ball, speed = 1.3·v_min) | never | 1.5–3 s |
| Medium | 0.22–0.30° | 5% | 0.15 R | straight-ins (+ banks if nothing else) | 3 speeds × 3 tips, noiseless | if best P < 30% | 1.5–3 s |
| Hard | 0.10–0.14° (≈ ICGA) | 3% | 0.08 R | + banks/kicks/combos as fallback | full grid + noisy robustness check (16 samples) | if best P < 55% | 1–2.5 s |
| (Expert/unlock) | 0.05–0.07° | 2% | 0.05 R | same as Hard | same + heuristic 2-ply | same | 1–2 s |

  Speed and spin noise are given as fractions because a mobile power bar maps to a percentage, not to m/s. That choice is my own; the ICGA model used absolute m/s.
- **Use σ, not uniform ±.** Draw from Gaussian Rng (core/Rng.gd), clamped at 3σ so rare wild misses do not look absurd.
- **Let the AI plan with its own noise.** Score candidates using P(pot) at that level's σ, so the CPU picks shots it can actually make. This is CueCard's robustness idea and the AAMAS finding that skill-aware agents beat skill-ignorant planners.
- **Intelligent mistakes on Easy and Medium:**
  - Occasionally (Easy about 20%, Medium about 8% of shots) pick the second- or third-best candidate.
  - Under-hit position (speed too soft) more often than aim error, which reads as human.
  - Never deliberately scratch on the 8.
  - Avoid making the CPU's lucky outcomes look skilful, e.g. do not let a random Easy shot leave perfect shape repeatedly.
- **Human feel:**
  - Think time scales with difficulty of the position (more candidates means a longer pan), with a floor of about 1 s and a cap of about 3 s.
  - Show the aim line wandering and settling. Draw that from the actual chosen φ plus decaying jitter, not new randomness.
  - Vary shot choice when two options score within about 5%.
- **Rubber-banding, pros:** it keeps casual matches close, matching West's "nearly beat a strong opponent" aim.
- **Rubber-banding, cons:** players notice and resent visible catch-up (unsourced general game-design consensus), and it undermines ranked or skill claims.
- **Rubber-banding recommendation:** at most a mild, hidden adjustment of ±15% on σφ, based on the ball-count gap. Disable it on Hard and above, and never let it change rules or physics. Mobile players also pick their own difficulty, which is the more honest lever.

### Gaps
- I found no published data on what human-perceived difficulty or fun corresponds to in σ terms. The table is a starting point derived from geometry and the computational-pool noise models.
- I found no peer-reviewed source on rubber-banding in pool games specifically.

---

## 7. Compute budget on a mobile phone in GDScript

### Takeaway
The plan's "Hard N=128 plus two-ply in about 150 ms" is not feasible in GDScript. A fixed-step 240 Hz simulation of one shot to rest is likely to cost tens of ms on the target phone. Realistically, plan for about 40–150 full simulations per turn, on a worker thread during 1–3 s of "thinking." Use heuristic pruning, early termination and coarse-to-fine sampling, and make lookahead heuristic rather than simulated.

### Cited Findings
- CueCard-era simulation cost: "an average simulation takes about 3 ms" in C/C++ on 2009–2010 hardware with an event-based engine — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf). Tournament agents had 600 s per game. CueCard's own allocation rule was CurrentShotTime = TimeLeft / (balls left + 3) — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- A typical shot has about 10–50 events, sometimes as few as 5. Each event step costs up to about 521 candidate event-time calculations (16 balls, 18 cushion segments, 6 pockets), so about 95% of event-based cost is computing event times. Discrete stepping needs about 30 µs steps for 0.3 mm accuracy at ball speeds up to 10 m/s. A hypothetical 10 s shot would then be about 30,000 steps — [pooltool algorithm blog, Kiefl 2020](https://ekiefl.github.io/2020/12/20/pooltool-alg)
- pooltool's evolution algorithm is JIT-compiled with Numba for speed. No formal throughput benchmark was published as of the issue thread — [pooltool GitHub issue #118](https://github.com/ekiefl/pooltool/issues/118); [JOSS paper](https://theoj.org/joss-papers/joss.07301/10.21105.joss.07301.pdf)
- **Local GDScript microbenchmark** (my measurement, Godot 4.7.2 headless, Apple M1 Pro; script at `/private/tmp/claude-501/-Users-sandeep-Documents-GitHub-android-game-04/dad7c57e-d1cc-4630-82fd-44fca928f646/scratchpad/gdbench/bench2.gd`). The toy substep has typed Vector2 math, linear friction, swept-circle quadratic tests of moving balls against all 16, and position integration. It has no spin, cushions or pockets.
  - All 16 balls moving, 240 Hz: 25 µs per substep, 60 ms per 10 s of simulated time.
  - 3 moving balls (moving-list loop), 240 Hz: 6.1 µs per substep, 14.7 ms per 10 s.
  - 1 moving ball, 240 Hz: 2.6 µs per substep, 6.3 ms per 10 s.
  - 3 moving balls at 120 Hz: 7.4 ms per 10 s. At 60 Hz: 3.7 ms per 10 s. Cost is linear in substeps.
  - A naive all-pairs loop that only skipped static–static pairs barely helped (21 µs per substep with 3 moving). Iterate a list of moving balls rather than all pairs.
- The project already runs AI on a worker thread (`WorkerThreadPool.add_task` in `games/blocks/scenes/blocks_game.gd`, lines 255–285) — local code

### Inferences
- **Estimating one full cue_sim simulation on the phone** (these factors are unsourced estimates):
  - The real solver adds sliding/rolling spin state, cushion and pocket tests, and time-of-impact sorting. Assume 3–5× the toy cost.
  - Phone cores at 2.4 GHz run interpreted GDScript slower than an M1 Pro. Assume 2–3× slower.
  - Result for a typical 4–8 s AI shot with 2–4 balls moving: roughly 6–9 ms (toy, desktop) × 6–15 ≈ **35–130 ms per simulation**.
  
  So one 150 ms budget is about 1–4 simulations, and N = 128 is about 5–15 s on one core. **Benchmark on the device as soon as shared/cue_sim exists.** Log µs per substep and substeps per shot with `Time.get_ticks_usec()`.
- **Budget levers, roughly in order of payoff:**
  1. **Prune without simulating** (section 2). This turns about 7 balls × 6 pockets = 42 pairs into K = 6–10 candidates.
  2. **Early termination.** Stop when the outcome is known: the target ball is pocketed or has clearly missed, and the cue ball is rolling with all other balls at rest. Then extrapolate the cue ball's rest point analytically (rolling distance = v²/(2·a_roll)) if nothing is in its path. Also stop at a scratch or wrong-ball-first foul. This likely cuts 50–80% of substeps for most shots (estimate).
  3. **AI-only coarser step.** Use 1/120 or 1/60 s for planning simulations, which is 2–4× cheaper. Swept collisions stay tunnel-free. Planning only has to be close, because execution noise dominates. Always run the real shot at 1/240 s; determinism comes from executing the chosen parameters in the real solver.
  4. **Coarse-to-fine sampling.** Pass 1: one noiseless simulation per (candidate × speed/spin variant), about 30–60 simulations. Pass 2: 6–16 noisy samples for the top 2–3 only, about 20–48 simulations. CueCard's 30–50 samples matter for tournament-level choices. On mobile, noisy re-sampling can be replaced by the analytic P(pot) at the CPU's σ for the pot outcome, with simulation used only for cue-ball position.
  5. **Parallelism.** Use `WorkerThreadPool.add_group_task` across 3 cores (the phone's big cores). Each task needs its own solver state, and results are reduced deterministically by candidate index so output does not depend on thread scheduling.
  6. **Heuristic two-ply.** Evaluate the resulting tables with the section 3 heuristic, which costs no simulations. CueCard showed simulated level 2 adds about 5% and equals spending the time on more level-1 shots.
  7. **Option of last resort:** a GDExtension (C++) solver core for the AI would be 20–50× faster, but it conflicts with the pure-GDScript logic rule and adds an Android build step.
- **Suggested per-turn budgets** (Easy, Medium, Hard): about 10, 40 and 100 simulations at a 1/120 s planning step, with 1–3 s of wall-clock thinking hidden behind the camera pan. Re-check the numbers once on-device timing exists.
- **No per-frame allocations:** pre-allocate solver state buffers (PackedVector2Array or PackedFloat64Array) per worker and reuse them across simulations. The "No new per-frame allocations" rule makes this mandatory.

### Gaps
- No published GDScript or mobile timing exists for a billiards solver. The phone multiplier (2–3×) and the solver-complexity multiplier (3–5×) are my estimates and must be measured.
- I did not measure how many substeps a typical pool shot takes to reach rest in this solver. That depends on the cushion restitution and rolling-friction tuning; the docs' 5/7·μr·g figure gives about 0.07 m/s² deceleration, so slow balls roll for many seconds. Measure the distribution with the physics-tune skill.

---

## 8. Measuring difficulty: self-play win rates against a baseline player model

### Takeaway
Measure each CPU level headlessly against fixed reference agents, using enough games for a ±2–3% standard error (about 300–600 games per pairing). Track win rate and the component metrics (pot %, run length, break-and-run %, fouls per game). The computational-pool literature used win-off-the-break and head-to-head win % with SD = 1/(2√N).

### Cited Findings
- CueCard's analysis reported win % ± SD with σ = 1/(2√N), plus hypothesis-test significance. The headline sample-count comparison used 1,256 games — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- "Win-off-the-break %" (the breaker wins without ever losing the turn) was used as a single-agent skill metric over about 20,000 games per agent. Each agent used the same break and could re-break until successful, so break variance was excluded — [AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf)
- PickPocket reported straight-in success (SIS) and safety success (SS: the opponent then fails to pot) per agent. These separate execution quality from position play — [Smith 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf)
- Execution skill can be estimated from observed play with Bayesian methods that jointly estimate decision-making and execution skill. Computational pool is the motivating domain — [Archibald & Nieves-Rivera, JAIR 80, 2024](https://jair.org/index.php/jair/article/download/15326/27033/39091)

### Inferences
- **Reference opponents** (headless, seeded):
  - "Greedy-σ" agents (take the highest-P(pot) shot, no position play) at σφ = 0.15°, 0.3° and 0.6° stand in for strong, average and casual human players.
  - Each CPU level plays each reference for 400 games with alternating breaks (SD = 2.5%).
  - Example targets (my proposal):
    - Easy beats casual about 50% and average about 30%.
    - Medium beats average about 55%.
    - Hard beats average about 80% and strong about 55%.
  - Also confirm the ordering Easy < Medium < Hard head-to-head, each step 65–75%.
- **Component metrics per level:** pot % on attempted shots, mean balls per visit, break-and-run %, scratch %, safeties per game, mean think time, and 95th-percentile CPU ms per decision on the device.
- **Statistical check:** at N = 400, two levels whose win rates differ by less than about 7 points are not reliably distinguishable (2 SD at 2.5% each, combined). Raise N for fine tuning, or use paired seeds (the same racks for both agents) to cut variance.
- **Live telemetry later:** log human pot % and CPU win % per level, and adjust σ server-free in a later patch. The JAIR 2024 approach could estimate a player's σ from their misses to auto-suggest a difficulty.
- This fits the project's `ai-opponent` skill ("report self-play win rates per difficulty"). Keep the seeded runs deterministic so results reproduce.

### Gaps
- There is no published mapping from these simulated reference agents to real mobile-player skill. Calibrate the "casual" σ against early playtest pot % (e.g. log human aim error relative to the ghost-ball line).
