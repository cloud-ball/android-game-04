# What makes a vs-CPU pool/snooker opponent feel fair, human and fun (researched 2026-11-13)

Scope note: this file covers how the CPU *feels*. The compute budget, noise model and self-play harness are already in `docs/research/Cue Club pool game design.md` (CPU section, lines ~187-225). This file does not repeat them and cites them only where they are needed. Current CPU baseline being judged: `games/pool/logic/pool_cpu.gd`. It shoots straight-ins only, with Gaussian aim σ 1.4°/0.7°/0.32° and speed noise 14/9/5%. Easy and Medium pick at random from their top 4 and top 2 shots. It has no position play, safeties or banks, and takes about 0.9 s to think plus 0.8 s of visible aiming.

Source quality overall: the most useful primary sources are Mick West's 2009 essay (he wrote a shipped snooker AI), AI Factory's 2008 pool-tutor note (shipped mobile/PC pool AI), and the Stanford and Alberta computational-billiards papers. Player-complaint evidence is anecdotal: Steam threads, store reviews and press reviews, roughly 2012-2019. I found **no** published win-rate targets, think-time targets or self-play metric targets from any commercial pool game. All numeric targets below are therefore marked as inferences.

---

## 1. Player complaints and praise about pool/snooker CPUs

### Takeaway
Raw accuracy is not the most common complaint. Players object to behaviour that reveals the machine: impossible or exotic shots taken routinely, misses that always leave the human safe, misses that never happen on certain pocket types, and lucky leaves that read as deliberate. Players praise opponents with believable, varied styles and misses that still give them a chance.

### Cited Findings
**"Too perfect" / exotic shot selection**
- Mick West (Game Developer, 18 Mar 2009) on his first shipped game, *Steve Davis World Snooker* (about 1989). The AI "just picked the highest value ball that could be potted, and then potted it". It could "perfectly pot any ball off two cushions" and "would almost always get a perfect break of 147". Cushion pots were later restricted to escaping snookers. — [West 2009](https://www.gamedeveloper.com/programming/intelligent-mistakes-how-to-incorporate-stupidity-into-your-ai-code)
- AI Factory (Rollason & Orme, July 2008): a perfect-aim engine "potting on the break and choosing four-ball pots" looked unrealistic. Adding random error alone was not enough, because the engine "still chose difficult shots and then missed them", which looked incomprehensible. Their fix was to model percentage play and penalise shots humans find hard to judge, such as multi-rail shots, which the engine otherwise treats as easy. — [AI Factory pool tutor newsletter, 2008](https://aifactory.co.uk/newsletter/2008_01_pool_tutor.htm)
- *Virtual Pool 4* Steam thread (28-29 Nov 2018). The OP said "the AI can play impossible shots multiple times if they are behind", which players read as rubber-banding or cheating. Another poster said "No player in the real world, no matter how good, would take on the type of shots the AI does". A third said "the AI becomes way to hard to compete against" at higher ranking. — [Steam: Virtual Pool 4 discussion](https://steamcommunity.com/app/336150/discussions/0/1742227264189864867)
- Mobile store reviews (snippets surfaced by search; the exact listing for each quote is not individually verified): a Pro Pool reviewer said the top level "never misses a double or a plant… bordering on ridiculous". A snooker app reviewer complained the computer gets out of every tight snooker "every single time". A *Pro Snooker & Pool* reviewer said the top level "almost never misses, but also rarely runs more than a couple balls before needing to play defensive". — [Pro Pool 2024 (App Store AU)](https://apps.apple.com/au/app/pro-pool-2024/id556429076); [Pro Snooker & Pool 2024+ (appshunter)](https://appshunter.io/ios/app/1586517737); [App Store listing id556429085](https://apps.apple.com/app/id556429085)
- *Pool Nation* (2012-13) reviews said the AI level "is quite close to perfection" and that the single-player tour "is let down by the AI which doesn't give you a chance". The game had no AI difficulty setting; difficulty came only through the player's aim-assist. — reviews surfaced via search: [SelectButton](https://selectbutton.com/reviews/pool-nation-review), [Gamereactor](https://msn.gamereactor.eu/pool-nation-review/), [TheSixthAxis](https://www.thesixthaxis.com/2013/05/22/pool-nation-review-psn/) (which quote comes from which review was not verified line by line)

**"Cheating" luck and scripted-looking misses**
- West's client said Easy was "too good" even after its aim was made worse, because "the computer always seemed to be leaving the white ball in a convenient position". In fact the cue ball's final position was never computed and was effectively random, and it "quite often ended up in a pocket". Because the CPU could pot from anywhere, "all positions are equally advantageous", so random leaves looked like positional skill. His lesson: "Random outcomes that happen to favor the computer are perceived as being intentional." — [West 2009](https://www.gamedeveloper.com/programming/intelligent-mistakes-how-to-incorporate-stupidity-into-your-ai-code)
- *Virtual Pool 4* thread: "If they miss it usally goes bounces round the table and goes in another pocker". Players blame the AI for fluked pots. — [Steam VP4](https://steamcommunity.com/app/336150/discussions/0/1742227264189864867)
- *Snooker 19* Steam thread (28-29 Apr 2019): when the AI misses it leaves the cue ball safe "99 percent of the time", which was called "so scripted". The AI's misses were "always one of the corner pockets", and it never seemed to miss middle-pocket shots ("more variation here" was requested). Some misses looked like a novice's, "with balls going everywhere at pace!" — [Steam: Snooker 19 discussion](https://steamcommunity.com/app/887800/discussions/0/1678064284160398975)

**Erratic or "dumb" play**
- *Pure Pool* (VooFoo, 2014) reviews describe the AI as erratic ("send a ball flying off the table one shot, then drain 4 in a row the next"; "might miss an easy lay-up but then sink three deep balls in a row"). They also called it "hard, very hard, even on the easiest setting", with a steep difficulty spike, "increasingly superhuman" late-game AI, and "very slow in making decisions". The three levels were Amateur, Pro and Master. — reviews surfaced via search, line-by-line attribution not verified: [Pure XBox](https://purexbox.com/reviews/xbox-one/pure_pool), [We Got This Covered](https://wegotthiscovered.com/?p=368501), [OSFTW](https://www.osftw.com/reviews/761/pure-pool), [Cubed3](https://www.cubed3.com/review/6380/1/pure-pool-nintendo-switch.html)
- *Pool Nation*: a Gamereactor reviewer found themselves "winning too easily, one time after an AI player missed for no good reason". In contrast, SelectButton enjoyed an AI miss on the 8-ball as "an amazing upset" that gave a chance at redemption. — [Gamereactor](https://msn.gamereactor.eu/pool-nation-review/); [SelectButton](https://selectbutton.com/reviews/pool-nation-review)
- Mobile reviews in both directions: "Computer misses too many easy shots" and "totally irrational and sloppy shots". — search snippets from App Store listings, e.g. [id942349245](https://apps.apple.com/app/id942349245) (attribution not verified per quote)

**Slow turns**
- *Pure Pool*: the AI was "very slow in making decisions" (see review links above). itch.io players of small pool games said "the bot turn felt a little bit slow" and "the bot took forever to take his turn". — [itch.io post](https://itch.io/post/3305461); [itch.io post](https://itch.io/post/6274367); [MOTS 8-ball comments](https://tommulgrew.itch.io/mots-8-ball-pool/comments)

**Praise: styles and personalities**
- AI Factory cites a GameSpot review of their *Friday Night 3D Pool*, which praised play "equivalent to human play" with a range of believable opponent styles. — [AI Factory 2008](https://aifactory.co.uk/newsletter/2008_01_pool_tutor.htm)
- *Snooker 19* players asked for per-player styles: "Robinson's long potting, O'Sullivan's speed, and Ebdon's slow play" (named real pros, so this is not usable directly). — [Steam Snooker 19](https://steamcommunity.com/app/887800/discussions/0/1678064284160398975)
- *Pure Pool*'s "DNA" system records a player's behaviour and skill so others can play AI copies of their style. Reviewers called it a notable feature. *Pool Nation* was criticised for "no real differing styles between AI opponents". — Pure Pool and Pool Nation review links above

### Inferences
- Against these complaints, the current Cue Club CPU is safe on "exotic shots", because it only takes straight-ins. It is exposed to West's "lucky leave" problem: it has no position play, so cue-ball rest is random, and random good leaves will be read as skill. That may partly explain why the user felt it was too strong even after σ was raised.
- "Misses always leave the human safe" and "misses always on corner pockets" are both signatures of a single, unvaried miss mechanism. Cue Club's Gaussian aim noise varies naturally. If deliberate misses are added, they should not have one fixed outcome type.
- Random choice among the top 4 shots (Easy) can pick a visibly worse shot when an easy one exists. That produces AI Factory's "chose difficult shots and then missed them" look. Pick weighting should favour shots that look sensible to a human.

### Gaps
- No systematic dataset (review mining, survey) of pool-AI complaints. All of the above is anecdotal, 2008-2019.
- No primary review text was retrievable for Pure Pool or Pool Nation (403 or not fetched). Quotes come via search summaries.

---

## 2. Techniques to make the CPU feel human

### Takeaway
The best-documented technique is West's "intelligent mistakes": the AI computes its best play at full strength and then *chooses* a plausible error, ideally one that gives the human a good next shot. Pure random noise produces both robotic hits and lucky leaves that look intentional. AI Factory adds a second rule: pick shots a human would pick (percentage play, penalise multi-rail shots), then miss them, never the reverse.

### Cited Findings
- West's central argument: crippling an AI's computation yields blunders no human would make. Instead, run it at full strength and have it make deliberate, plausible mistakes. His pool recommendation is that the AI "should deliberately fail to pot the ball" and "ensure that the cue ball ends up in a place where the player can make a good shot". He calls this calculated throwing to keep the game entertaining. The poker analogue (*World Series of Poker*): weak AIs fold more to big raises and call more with weak hands, probabilistically, while "still performing its full set of millions of calculations". The chess analogue (*Fritz*): the AI sets up a position the human can exploit for about a one-pawn advantage, then resumes playing to win. — [West 2009](https://www.gamedeveloper.com/programming/intelligent-mistakes-how-to-incorporate-stupidity-into-your-ai-code) (also run as a 2008/2009 Gamasutra bonus feature: [Gamasutra/Game Developer](https://www.gamedeveloper.com/game-platforms/bonus-feature-intelligent-mistakes-key-to-believable-ai))
- Players anthropomorphise AI opponents and assume planning behind outcomes (West). This works for you with visible "thinking" and against you with lucky leaves. — [West 2009](https://www.gamedeveloper.com/programming/intelligent-mistakes-how-to-incorporate-stupidity-into-your-ai-code)
- AI Factory: "the AI must imitate human limitations to feel like a human opponent". Their method rates the "easiness" of each pot and switches to a safety search when a pot is too hard. It penalises shot types humans misjudge (multi-rail) rather than relying on noise. Their tutor also "balances the game by deliberately missing when ahead and potting when behind". — [AI Factory 2008](https://aifactory.co.uk/newsletter/2008_01_pool_tutor.htm)
- A forum developer reports that a snooker client called the AI "too good" and that lowering accuracy did not fix it. Common advice is to add noise to the cue angle and let the physics produce misses, plus an easiness check that falls back to safety. — [gamedev.net pool AI thread](https://gamedev.net/forums/topic/625601-poolbilliard-ai-new/4944968/); [isegoria "The AI's Too Good"](https://www.isegoria.net/?p=3481)
- Distinct styles are requested and praised. Examples: a long potter, a fast player, a slow and careful player (Snooker 19 thread), and behaviour-cloned "DNA" opponents (Pure Pool). — [Steam Snooker 19](https://steamcommunity.com/app/887800/discussions/0/1678064284160398975); Pure Pool reviews above
- On estimating a human's execution noise from observed shots (useful for auto-suggesting a level): see Archibald & Nieves-Rivera, as already cited in the design doc. — [JAIR 2024](https://jair.org/index.php/jair/article/download/15326/27033/39091)
- Players enjoy computer opponents less than human ones. A 2026 meta-analysis of 20 studies (9 with baseline comparisons) found a "medium-to-large" pooled penalty for computer-opponent conditions, and suggests that perceiving the opponent as artificial may itself reduce the experience. Moderators were not reported in the abstract. (Caution: the arXiv ID 2607.x looks inconsistent with the stated 22 May 2026 submission date. Verify before quoting.) — [Ito, arXiv 2607.24749 (IEEE CoG 2026)](https://arxiv.org/abs/2607.24749)

### Inferences (concrete techniques for Cue Club, mapped to evidence)
- **Mistake menu instead of bigger σ.** Keep σ moderate. Each level then draws from weighted, *plausible* error types:
  1. Thin or thick cut miss on a hard cut. This is the most human error (rattles, near misses).
  2. Speed error: under-hit that leaves the ball in the jaws, or over-hit that loses position.
  3. Position error: the pot goes in, but the cue ball ends with a long or blocked next shot.
  4. Shot-choice error: on Easy only, a slightly harder ball than the obvious one. Never an exotic shot.
  5. A "West miss" that leaves the human a makeable shot.
  
  Source basis: West (deliberate miss plus a good leave), AI Factory (percentage play), Snooker 19 (vary miss locations).
- **Never fluke-looking.** On Easy/Medium, reject a candidate whose noiseless *miss* outcome pockets another ball or snookers the human. This is cheap with the planned solver rollouts. Counting CPU flukes in self-play gives a "luck" metric (section 6).
- **Never deliberately lose on the 8** (scratching or fouling it). Deliberate misses on the 8 should only be short or thin, which keeps the "upset" chance SelectButton enjoyed without a cheap loss. (The design doc already says not to scratch deliberately on the 8.)
- **Visible thinking.** Look at two or three candidate balls (cue swings toward each), then settle, then do a short pre-shot waggle. Anthropomorphism (West) means visible deliberation reads as intent. Spend this time on the most "human" moments: long pauses before hard shots and quick taps on easy ones. Real players differ in pace (the Snooker 19 styles).
- **Personalities as parameter presets, not new code.** Example: "Steady" (low σ, never plays exotic shots, safety-happy); "Shot-maker" (low cut-angle penalty, higher speed σ, never plays safe); "Grinder" (slower, more safeties, weak long pots). Original names only (CLAUDE.md golden rule).

### Gaps
- No published measurements of *which* mistake types players rate as most human. The ordering above is a design inference.
- West's article gives no numbers (how often to throw, how it was tuned).

---

## 3. Difficulty design: number of levels, expected win rates, rubber-banding, adaptive difficulty

### Takeaway
Commercial pool games mostly ship 3 levels (e.g. Pure Pool's Amateur/Pro/Master), and the common failure is that even the lowest level is too strong for newcomers, with a steep jump between levels. No commercial win-rate targets are published. Academic work finds that objective balance (win, draw or lose) does *not* reliably change enjoyment. Visible rubber-banding is widely resented, and hidden adjustment is the accepted practice when adjustment is used at all.

### Cited Findings
- *Pure Pool* had three AI levels (Amateur, Pro, Master). Reviews said even the easiest was "hard, very hard" and that difficulty spiked steeply. *Pool Nation* had no AI levels; difficulty came via player aim-assist. — Pure Pool and Pool Nation review links in section 1
- West's chess example (Fritz) and AI Factory's tutor ("deliberately missing when ahead and potting when behind") are shipped examples of state-based throttling, i.e. rubber-banding, in board and cue games. — [West 2009](https://www.gamedeveloper.com/programming/intelligent-mistakes-how-to-incorporate-stupidity-into-your-ai-code); [AI Factory 2008](https://aifactory.co.uk/newsletter/2008_01_pool_tutor.htm)
- Rubber-banding is "easily noticed by the player" and "can feel unfair that the computer doesn't have to follow the same rules". DDA "should be invisible – the player should never feel it happening". Rubber-banding is "not necessarily inherently bad" but is often "used too aggressively". Letting players choose opponent toughness is recommended. One example given is a sports AI team that gets better the further ahead the player is. — [Compton, Game Developer, 15 Jul 2019](https://gamedeveloper.com/design/more-than-meets-the-eye-the-secrets-of-dynamic-difficulty-adjustment)
- The *Virtual Pool 4* complaint "impossible shots… if they are behind" shows a player detecting, or believing in, catch-up behaviour and calling it unfair. — [Steam VP4](https://steamcommunity.com/app/336150/discussions/0/1742227264189864867)
- Cutting, Deterding et al. ran pre-registered studies with an MCTS AI tuned to win, draw or lose (n≈309-311). Participants did *not* notice the manipulation, and the draw condition was perceived as most balanced. However, "different ratios had no significant impact on enjoyment or engagement", and the predicted inverted-U was not found. The authors suggest appraisals, novelty and progress may matter more. — [Royal Society Open Science 2023 (PMC)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9890114/); [CHI PLAY 2023 version (AMiner)](https://www.aminer.org/pub/65254f11939a5f4082cce8f7/objective-difficulty-skill-balance-impacts-perceived-balance-but-not-behaviour-a-test)
- DDA built on heuristic parameter tuning "often turns out to be very noticeable, e.g. as 'rubber-banding'". Players preferred episodes driven by a player-behaviour model over classic difficulty management (MMORPG, 171 participants, 4 weeks). — [Newcastle OpenLab: Enemy Within](https://openlab.ncl.ac.uk/research/enemy-within-long-term-motivation-effects-of-deep-player-behavior-models-for-dynamic-difficulty-adjustment)
- In a racing game field experiment, introducing AI opponents produced "discouragement effects", with reduced engagement and performance that varied by skill and motivation. — [MIS Quarterly vol 50 iss 3](https://aisel.aisnet.org/misq/vol50/iss3/10)
- In computational pool, raw execution skill dominates strategy: a top planner with noise above about 2.5× tournament level loses to a naive shot-finder with perfect execution. Noise is therefore the natural difficulty dial. — [Archibald, Altman & Shoham, AAMAS 2010](https://ifaamas.csc.liv.ac.uk/Proceedings/aamas2010/pdf/01%20Full%20Papers/22_05_FP_0677.pdf) (as summarised in the design doc; not re-read here)

### Inferences (tuning targets, all unsourced proposals)
- **Levels:** 3 visible levels (Easy/Medium/Hard), plus an optional unlockable 4th, matching the genre norm and the design doc. Make the *gap* between levels smaller than Pure Pool's. Each level should beat the one below about 65-75%, as the design doc proposes.
- **Win-rate targets for a first-time casual mobile player** (the user already asked for a weaker CPU, so err low):
  - Easy: the human wins about 65-75% of first games, and should be able to win the very first game without understanding position play.
  - Medium: about 45-55% for a player with an hour or so of practice.
  - Hard: about 25-35% for that player. Hard should still lose regularly to sloppy safeties, because it has no superhuman shots.
  
  Cutting & Deterding suggest exact balance matters less than feeling the opponent is beatable and seeing progress, so a generous Easy is low-risk.
- **Rubber-banding:** do not use visible shot-making catch-up. Never let the CPU take harder shots when behind (the VP4 complaint). If used at all, keep it hidden and small: adjust *mistake frequency* (e.g. one extra "West miss" per rack on Easy when the human trails by 3 or more balls), never the shot choice. Turn it off on Hard. This aligns with the design doc's ±15% σ cap. A per-level toggle or "Relaxed" mode is more honest than hidden DDA.
- **Adaptive suggestion instead of adaptive AI.** After 3 straight wins or losses at a level, *suggest* moving up or down (player-chosen, per Compton).

### Gaps
- No published win-rate targets from any shipped pool or sports game.
- The 2019 UTS study on MCTS-DDA win/loss ratios ("Challenging AI…") could not be retrieved (repository offline): [UTS OPUS](https://opus.lib.uts.edu.au/handle/10453/134533).
- Hagelbäck & Johansson (CIG 2009) on RTS dynamic difficulty: abstract not retrieved. — [researchr listing](https://researchr.org/publication/HagelbackJ09-1)

---

## 4. How long a CPU turn should take

### Takeaway
Slow AI turns are a recurring named complaint (Pure Pool, small itch.io pool games), but no source gives a target duration. A real cue player's pre-shot routine (walk around, line up, a few practice strokes) is the natural model. The design doc proposes 1-3 s of visible think. The current 0.9 s + 0.8 s ≈ 1.7 s is already in the acceptable band.

### Cited Findings
- *Pure Pool*: AI "very slow in making decisions" (2014 reviews; see section 1).
- itch.io players: "the bot turn felt a little bit slow"; "the bot took forever to take his turn". — [itch.io](https://itch.io/post/3305461); [itch.io](https://itch.io/post/6274367)
- A gamedev.net commenter suggests running the AI's physics search fast and only animating the chosen shot, so search cost never becomes waiting time. — [gamedev.net pool AI thread](https://gamedev.net/forums/topic/625601-poolbilliard-ai-new/4944968/)
- In the Iagno (GNOME Othello) bug discussion, developers argued against fixed artificial delays as a fix for perceived AI speed problems. — [GNOME bugzilla 736932](https://bugzilla.gnome.org/show_bug.cgi?id=736932)
- The design doc already budgets 1-3 s of hidden compute behind camera and aim animation, with 1.5-3 s visible think on Easy/Medium and 1-2.5 s on Hard. — `docs/research/Cue Club pool game design.md` (CPU table)

### Inferences
- **Target total CPU pre-shot time:** 1.2-2.5 s typical, with a hard ceiling of about 3.5 s even for the hardest decisions. Ball travel time comes on top of that. The rack-length budget comes from shots per rack × (think + roll). Easy's high miss rate means *more CPU visits per rack*, so slow Easy turns hurt most.
- **Scale think time with shot difficulty, not difficulty level:** about 0.6-1.0 s on a tap-in and 2-3 s on a long cut or safety. This reads as human and keeps easy sequences brisk.
- **Let the player tap to skip** the CPU's aim animation (but not the shot). Long matches against Easy produce many CPU visits.
- If search ever exceeds the visible routine on a slow phone, extend the animation (extra waggle, camera glide) rather than freezing. Log 95th-percentile decision time on the test phone (already in the design doc's metric list).

### Gaps
- No usability study or commercial spec for AI turn length in turn-based sports games was found.

---

## 5. CPU breaks and safeties by level

### Takeaway
Computational-pool winners precompute the break and favour *keeping the turn* over spreading balls. Safeties pay off most against inaccurate opponents, i.e. casual humans, so a safety-heavy CPU can feel oppressive. Players dislike safeties that are always perfect, and they dislike misses that always leave them safe. Safety strength should therefore scale steeply with level, and Easy should not play deliberate safeties at all.

### Cited Findings
- CueCard (2008 Computer Olympiad winner) used a precomputed break from an offline search. Breaks exist that keep the turn 97% of the time but spread no balls, while full-spread breaks succeed at best about 60%. CueCard's break kept the turn 92% of the time and "often spreads out many of the balls". Spreading balls while losing the turn "leaves the opponent in a very good position". The break accounted for about 10% of CueCard's wins. — [Archibald, Altman & Shoham, IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- CueCard sampled each shot variant 20-100 times depending on game stage; PickPocket's 15 samples "were not enough". CueCard won the 2008 tournament 64 of 78 games and a later 636-game match 492-144. A version limited to about 120 s/game still won about 42% against the 600 s version, and the 20-CPU cluster was not essential (45%). — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf). Implication: more thinking buys little.
- CueCard considers the opponent only for "last-resort" shots, under 1% of shots. In 8-ball between strong agents, safety is rarely chosen. — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf)
- PickPocket (Smith, Univ. of Alberta) won the 2005 and 2006 Computer Olympiad 8-ball events and took silver in 2008. It uses Monte-Carlo search over shot candidates; per the design doc's reading, it triggers safety search only when the best offensive shot's success probability is below about 65%. — [Smith, AAAI 2006](https://cdn.aaai.org/AAAI/2006/AAAI06-156.pdf); [ICGA tournament listing](https://www.game-ai-forum.org/icga-tournaments/program.php?id=244); [Smith, *Artificial Intelligence* vol 321](https://datalearner.com:8443/academic/journal-papers/0004-3702/volumes-and-issues/321/paper-detail/68497)
- Player complaints about safety: the AI's misses leave the human safe "99 percent of the time" ("scripted"); the AI pots balls the human thought were safe (Snooker 19). The computer gets out of every snooker "every single time" (mobile snooker review). — [Steam Snooker 19](https://steamcommunity.com/app/887800/discussions/0/1678064284160398975); [App Store id556429085](https://apps.apple.com/app/id556429085) (attribution via search snippet)
- AI Factory: when a pot is too hard, search for a safety. Safety targets need both an object-ball and a cue-ball target area. — [AI Factory 2008](https://aifactory.co.uk/newsletter/2008_01_pool_tutor.htm)

### Inferences (per-level behaviour proposal)
| Level | Break | Safeties | Escapes / kicks |
|---|---|---|---|
| Easy | Same precomputed break as the others, with extra speed and cue-placement noise. Keep-turn rate about 55-70% (roughly the human's own). | None deliberate. With no makeable shot, it "has a go" at the easiest pot (a human beginner's behaviour). | Plain aim at the nearest legal ball, often fouls (about 40-60% hit rate). |
| Medium | Keep-turn about 70-80%. | Only when best P(pot) is under about 25-30%. Safety quality is noisy: about half leave a makeable shot. | Single-rail kicks, about 60-70% legal hit. |
| Hard | Keep-turn about 85-90%. Do not exceed CueCard's 92%, which is tournament-optimal and would feel robotic. | Below about 50-55% P(pot), but cap at about 1-2 deliberate safeties per rack so it never becomes a grind. | Two-rail allowed. Escape success below 90%, avoiding the "every single time" complaint. |

- The current CPU's apex break at a fixed 11 m/s is the same every time, so the outcome depends only on noise. Precomputing 2-3 breaks (the design doc) and picking at random per rack also adds visual variety.
- With no safeties at all today, a CPU with no shot "goes for it". That is actually human-like on Easy. The missing piece is that misses should sometimes leave the human an easy chance and sometimes not, with no single pattern.

### Gaps
- No data on the keep-turn rate of casual human breaks in a digital game. The per-level break numbers are proposals to validate in self-play.
- PickPocket's full paper text could not be extracted here (PDF encoding). Its 65% safety threshold is taken from the design doc's earlier reading.

---

## 6. Self-play metrics and target values per level

### Takeaway
No source publishes per-level pot-percentage or balls-per-visit targets for commercial pool CPUs. The academic convention is win % over hundreds of games with SD ≈ 1/(2√N). For "feel", the right metrics are human-legible: pot %, balls per visit, run-outs, scratches, flukes, safeties per rack and turn time, compared against what casual and amateur humans do. One rough analytic check shows the current CPU's σ values are very weak on anything but short, straight shots.

### Cited Findings
- CueCard's analysis reports win % with SD from match play, using hundreds of games per comparison. The design doc proposes 400 games per pairing (SD 2.5%) with paired seeds. — [IJCAI 2009](https://www.ijcai.org/Proceedings/09/Papers/231.pdf); design doc §"Self-play measures difficulty"
- Mobile reviewer reference point: a top-level CPU that "almost never misses, but also rarely runs more than a couple balls before needing to play defensive" was considered a reasonable top level (Pro Snooker & Pool). — [appshunter listing](https://appshunter.io/ios/app/1586517737) (via search snippet)
- *Virtual Pool 4* poster's illustrative tuning (explicitly "only an example"): a "hard" AI misses about 20% and the top AI about 10%. — [Steam VP4](https://steamcommunity.com/app/336150/discussions/0/1742227264189864867)

### Analytic check of the current CPU (own calculation; unvalidated formula)
Using the design doc's tolerance formula, `tol ≈ atan(w_eff/2/d1) / (1 + d2/(2R·cosα))` and `P = erf(tol/(σ√2))`, with w_eff = 7.75 cm and R = 2.86 cm (standard ball; Cue Club's enlarged balls would change this). Aim noise only; speed noise ignored.

| Shot | tol | P @ σ1.4 (Easy now) | P @ σ0.7 (Med now) | P @ σ0.32 (Hard now) | P @ σ0.6 / 0.26 / 0.12 (design doc) |
|---|---|---|---|---|---|
| Short straight (d1 = d2 = 0.4 m) | 0.69° | 0.38 | 0.68 | 0.97 | 0.75 / 0.99 / 1.0 |
| Short 45° cut (0.4 / 0.5 m) | 0.41° | 0.23 | 0.45 | 0.80 | 0.51 / 0.89 / 1.0 |
| Medium 30° cut (0.8 / 0.8 m) | 0.16° | 0.09 | 0.18 | 0.39 | 0.21 / 0.47 / 0.82 |
| Long straight (1.4 / 0.6 m) | 0.14° | 0.08 | 0.16 | 0.33 | 0.18 / 0.40 / 0.75 |

### Inferences
- The current Easy (σ 1.4°) pots under 40% even on short straight shots and about 10% on medium ones. Medium (0.7°) is roughly what the design doc meant for Easy. If the formula holds, the CPU should already be weak. If the user still felt it was too strong, the likely causes are: (a) the enlarged balls and pockets make tolerances wider than this table assumes; (b) lucky leaves from random cue-ball rest (West's effect); (c) ball in hand always setting up a straight shot; or (d) a human who is also missing a lot. Measure before reducing accuracy further. Very high σ also lengthens racks and makes misses look random and robotic.
- **Proposed self-play targets for a casual mobile audience** (CPU vs Greedy-σ reference agents as in the design doc; all to be validated):

| Metric | Easy | Medium | Hard |
|---|---|---|---|
| Pot % on attempted pots | 35-45% | 50-60% | 70-80% |
| Balls per visit (mean, visits that pot ≥0 counted) | 0.5-0.8 | 1.0-1.5 | 2.0-3.0 |
| Max run in a typical rack | 1-3 | 3-4 | 5-7 |
| Run-outs (clears group + 8 in one visit) per game | ~0% (≤1 in 50) | ≤5% | 10-20%. Not higher, per the "rarely runs more than a couple balls" praise. |
| Scratch rate per shot | 5-8% | 3-5% | 1-3% |
| CPU fluke rate (unintended ball potted, or human snookered after a miss) | ≤3% of misses; reject candidates whose noiseless miss flukes | ≤5% | natural |
| Deliberate safeties per rack | 0 | 0-1 | 1-2 |
| Misses leaving human a makeable shot | ≥60% | 40-60% | 20-40%. Not near 0% (the "scripted" complaint). |
| Miss distribution | Track miss rate by pocket type (corner vs side) and cut band; no bucket should be ~0% | same | same |
| Decision + aim time | 1.2-2.5 s mean, p95 ≤ 3.5 s on phone | same | same |
| Rack length vs average human | ≤ 6 min | 4-6 min | 3-5 min |
| Win % vs Greedy-σ0.6 ("casual human") | 35-45% | 55-65% | 80-90% |

- Also log *break keep-turn %* per level (targets in section 5) and *safety-success %* (opponent fails to pot next shot).

### Gaps
- No published human baseline for casual mobile pool players' pot % or balls per visit. The Greedy-σ reference agents are a stand-in. A short playtest log, with pot % from 3-5 real players on the test phone, would anchor the targets.
- The pot-probability formula is the design doc author's own and needs validation against solver pot rates, especially with Cue Club's enlarged balls.
