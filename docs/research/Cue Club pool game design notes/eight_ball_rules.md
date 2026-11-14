# Eight-ball rules: official rule sets, casual simplifications, and a rules state-machine spec for Cue Club

Researched 2026-11-13. Primary text used: **WPA "Rules of Play", effective 2025-09-15** (44 pp., © WPA 2025), read in full from a mirror of the official PDF. Secondary: the BCA "World Standardized" 8-ball text (as reproduced in 2024), **International Eightball Rules Revision 2b (Jan 2023)**, the UK ruleset endorsed by WEPF/IEPF, read in full from the PDF, plus Wikipedia and Dr. Dave Alciatore's league-difference FAQ.

Source keys used below:
- **[WPA25]** WPA Rules of Play, eff. 2025-09-15 — https://www.hkbilliardsports.org.hk/wp-content/uploads/2026/03/2025.09.15-WPA-Rules-WPA-Regs-NP.pdf (a copy of the PDF that wpapool.com links from https://wpapool.com/rules-of-play/)
- **[BCA]** BCA Eight Ball Rules (World Standardized), as reproduced at https://tribilliards.com/information/official-8-ball-rules.html
- **[INTL23]** International Eightball Rules Rev 2b, Jan 2023 (endorsed by WEPF) — https://www.maltapoolassociation.net/wp-content/uploads/2023/05/International-Eightball-Rules-Revision-2b-Jan-2023-A4-booklet.pdf
- **[DRDAVE]** https://drdavepoolinfo.com/faq/rules/league-rule-differences/
- **[WIKI8]** https://en.wikipedia.org/wiki/Eight-ball · **[WIKIBB]** https://en.wikipedia.org/wiki/Blackball_(pool)

---

## Q1. Official WPA (and BCA) 8-ball rules: rack, break, open table, groups, calls, legal shot, fouls, ball in hand, three fouls, stalemate, loss conditions, combinations

### Takeaway
Under the current WPA text (eff. 2025-09-15), 8-ball is a call-shot game. The table stays open after the break, and the 8 on a legal break is neither a win nor a loss: it is spotted or the rack is re-broken. Every standard foul gives ball in hand anywhere. The three-foul rule does not apply. You lose only for these four 8-ball offences: potting the 8 with a foul, potting it before your group is cleared, potting it in an uncalled pocket, or driving it off the table. BCA World Standardized is nearly identical. It also makes potting the 8 on the same stroke as your last group ball a loss, and it re-spots balls that jump off the table.

### Cited Findings
**Edition / structure**
- The WPA document is titled "RULES OF PLAY (EFFECTIVE 2025-09-15)". 8-Ball is Section 4 (4.1–4.11). General rules are §1, definitions §2 and fouls §3. The general rules apply "except when contradicted by the rules of specific Disciplines." — [WPA25](https://www.hkbilliardsports.org.hk/wp-content/uploads/2026/03/2025.09.15-WPA-Rules-WPA-Regs-NP.pdf)
- The wpapool.com rules page also links a "Rules of Play" PDF whose filename is dated 2026-10-21. I could not read its text, so I could not check whether it changes §4. — [wpapool.com/rules-of-play](https://wpapool.com/rules-of-play/)

**Objective and rack**
- 8-Ball uses 15 numbered object balls. A player's group (1–7 or 9–15) "must all be off the table before he attempts to pocket the 8-ball to win. Shots are called." (§4 preamble) — [WPA25]
- Rack (§4.2): tight triangle with the apex ball on the Foot Spot. The 8 is "the first ball that is directly below the apex ball" (centre of the third row). One ball from each group sits on the two lower (back) corners. All other balls are placed "without purposeful or intentional pattern." — [WPA25]

**Break (§4.3)**
- (a) Cue ball in hand above the Head String (the "kitchen"). (b) No call, and no required first ball. (c) If the breaker pockets a ball and does not foul, he continues and the table stays open. — [WPA25]
- (d) **Legal-break requirement.** If no object ball is pocketed, at least **four object balls must be driven to one or more rails**. Otherwise the break is illegal, and the incoming player chooses: (1) accept the table, (2) re-rack and break, or (3) re-rack and have the offender break again. — [WPA25]. BCA is the same: "pocket a ball or drive at least four numbered balls to the rail". — [BCA](https://tribilliards.com/information/official-8-ball-rules.html)
- "Driven to a rail" (§2.7): a ball counts only if it was not touching that rail and then touches it. A ball frozen to a rail counts only if it leaves and returns. A pocketed ball, or one driven off the table, counts as driven to a rail. — [WPA25]
- (e) **8 on a legal break is not a foul.** The breaker chooses between (1) spotting the 8 and accepting the position, or (2) re-breaking. — [WPA25]. BCA: the breaker may ask for a re-rack or have the 8 spotted and keep shooting. — [BCA]
- (f) **8 pocketed on a foul break** (for example a scratch): the opponent chooses between (1) re-spotting the 8 and shooting with cue ball in hand above the Head String, or (2) re-breaking. — [WPA25]; same in [BCA] rule 3.
- (g) Any object ball driven off the table on the break is a foul. Those balls stay out of play, except the 8, which is spotted. The incoming player chooses between accepting the table and taking cue ball in hand above the Head String. — [WPA25]
- (h) Any other break foul, including a scratch: the incoming player chooses between accepting the table and taking cue ball in hand **above the Head String**. — [WPA25]. On a scratch on a legal break, BCA keeps pocketed balls down, calls the foul, leaves the table open, and gives cue ball in hand behind the headstring. That player cannot shoot an object ball behind the headstring unless the cue ball first crosses it. — [BCA]

**Open table and choosing groups**
- §4.4: before groups are set the table is "open", and **before each shot the shooter must call his intended ball**. Legally pocketing the called ball gives the shooter that group and the opponent the other. If he fails, the table stays open and play passes. On an open table any object ball may be struck first **except the 8**. Hitting the 8 first on an open table is a foul "unless a group has been completely pocketed". In that case the shooter "may temporarily claim that group, and thereby be shooting the 8-ball, possibly for a win." — [WPA25]
- BCA rule 5: groups are "not determined by the break even if balls are made from only one or both groups". They are set only when a player legally pockets a called ball after the break. Rule 4: hitting the 8 first on an open table is a foul, no balls are scored for the shooter, and pocketed balls stay down. — [BCA]

**Continuing play, calls, safeties, spotting**
- §4.5: the shooter stays at the table while balls from his group are legally pocketed, or until he wins by pocketing the 8. — [WPA25]
- §1.7 Standard Call Shot: the shooter indicates ball and pocket "if they are not obvious". "Details of the shot, such as cushions struck or other balls contacted or pocketed are irrelevant. Only one ball may be called on each shot." — [WPA25]
- §4.6: every shot except the break must be called. The called ball must come from the player's group until it is cleared, and then the 8 is the called ball. A "safety" call passes play after the shot, and "any object-ball pocketed on the safety remains pocketed". — [WPA25]
- §4.7: "If the 8-ball is pocketed or driven off the table on the break, it will be spotted or the balls will be re-racked … **No other object-ball is ever spotted.**" — [WPA25]
- BCA rule 8: a ball is illegally pocketed on a foul, when the called ball misses its designated pocket, or after a safety is called. Such balls stay pocketed. — [BCA]
- Spotting procedure (§1.5): place the ball on the Long String as close as possible to the Foot Spot, between the Foot Spot and the foot rail. If blocked, place it touching the interfering ball, but never touching the cue ball. If the whole line below the spot is blocked, place it above the Foot Spot. — [WPA25]

**Legal shot and fouls (§3, §4.9)**
- §3.2 Wrong ball first: the first ball contacted must be from the shooter's group, except on an open table. If a legal and an illegal ball are hit at about the same instant and the order cannot be told, "it will be assumed that the legal object-ball was struck first." — [WPA25]
- §3.3 No rail after contact: "If no ball is pocketed on a shot, the cue-ball must contact an object-ball, and after that contact at least one ball (cue-ball or any object-ball) must be driven to a rail." The same tie goes to the shooter if ball and cushion are hit at about the same instant. — [WPA25]. BCA rule 6 also allows the cue ball to bank off a rail before hitting the object ball. — [BCA]
- Standard fouls at 8-Ball (§4.9) include cue ball scratch or off the table (§3.1), wrong ball first (§3.2), no rail after contact (§3.3), no foot on floor (§3.4), ball driven off the table (§3.5), touched ball (§3.6), double hit / frozen balls (§3.7), push shot (§3.8), balls still moving (§3.9), bad cue ball placement and bad play from above the head string (§3.10–3.11), playing out of turn (§3.12), slow play (§3.14) and the rack-template foul (§3.15). — [WPA25]
- **Ball in hand after a standard foul (§4.9):** "play passes to his opponent. The cue-ball is in hand, and the incoming player may place it **anywhere on the playing surface**." Restriction to above the Head String applies only to break fouls (§1.6, §4.3). — [WPA25]. BCA rule 11: in hand anywhere, "behind the headstring only on the opening break". — [BCA]
- §3 preamble: "If several fouls occur on one shot, only the most serious one is enforced." — [WPA25]
- §2.17: a shot on which the cue ball is pocketed is a scratch. §2.2: if the cue ball touches an already pocketed ball, it counts as pocketed. — [WPA25]
- §2.6: a ball is "driven off the table" if it comes to rest anywhere other than the playing surface without being pocketed. A ball that rides the top of the rail and comes back, or drops into a pocket, is not off the table. — [WPA25]
- §3.7: a cue ball touching an object ball at the start may be shot "towards or partly into" that ball if it is a legal target, and moving it counts as contact. "Playing away from a frozen ball does not constitute having hit that ball." — [WPA25]
- §2.11: an unintentional miscue that makes the cue ball leave the cloth or jump a ball "is treated like a legal jump shot." — [WPA25]

**Three fouls, stalemate, loss**
- §3.13: three fouls in a row is a serious foul in general, but "**Some games such as 8-Ball do not include this rule.**" It is not on the §4.9 list for 8-ball. — [WPA25]. BCA rule 13: "Three consecutive fouls by one player in 8-ball is not a loss of game." — [BCA]
- Stalemate (§1.13 and §4.11): when the referee sees no progress, each player gets three more turns. If there is still no progress, the referee declares a stalemate and "the original breaker of the rack will break again." — [WPA25]. BCA rule 13 is narrower: after three turns each, if any attempt to pocket or move a ball would lose the game, re-rack with the same breaker. It applies only when two object balls and the 8 remain. — [BCA]
- **§4.8 Losing the rack.** The shooter loses if he: "(a) pockets the 8-ball and fouls, (b) pockets the 8-ball before his group is cleared, (c) pockets the 8-ball in an uncalled pocket, or (d) drives the 8-ball off the table. These do not apply to the break shot." §4.10 treats these as serious fouls with loss of the rack. — [WPA25]
- BCA rule 12 adds: losing if you pocket the 8 "on the same stroke as the last of his group of balls", or pocket it when it is not the legal object ball. A scratch or foul while shooting at the 8 "is not loss of game if the 8-ball is not pocketed or jumped from the table." — [BCA]

**Combinations, balls in the jaws, settling**
- BCA rule 7: combinations are allowed, but the 8 cannot be the first ball hit unless the table is open. BCA rule 4 also says a combination can never be used to legally pocket the 8. Read together, the two statements are in tension (noted in the source summary). — [BCA]
- WPA has no separate combination rule. The called ball just has to go in the called pocket, and "cushions struck or other balls contacted or pocketed are irrelevant" (§1.7). — [WPA25]
- §2.2 Ball pocketed: a ball counts as pocketed if it comes to rest below the playing surface or enters the ball return. A ball hanging in the jaws and held up by another ball counts as pocketed if removing the support would make it fall. A ball that stays apparently motionless at the edge for 5 seconds after the shot "is not considered pocketed if it later falls". An object ball that bounces out of a pocket back onto the cloth is not pocketed. — [WPA25]
- §1.8: a ball that settles into a pocket after it has stopped is put back. — [WPA25]

### Inferences
- WPA leaves several choices to a person ("option of …" in §4.3 d/e/f/g/h). A pure rules engine must either expose these as prompts or fix a default. Fixing defaults removes UI and is the main lever for simplifying a mobile game.
- Physical fouls (§3.4, §3.6–3.9, §3.12, §3.15) cannot happen in a simulated cue stroke and can be left out. The only fouls a simulator can produce are cue scratch, cue off table, no contact, wrong ball first, no rail after contact, and object ball off table, plus break-specific rules and the four 8-ball loss conditions.
- WPA and BCA disagree on whether off-table object balls are spotted (WPA: never, except the 8; BCA: re-spot in numerical order). An engine has to pick one.

### Gaps
- I could not read the wpapool.com PDF dated 2026-10-21. If it is a newer edition, §4 may have changed. Re-check before shipping.
- I did not find an official CSI/BCAPL 2025–26 rulebook text. CSI is covered only indirectly (Dr. Dave lists CSI/BCAPL break-scratch ball in hand anywhere; see Q2). The BCA text used is a 2024 third-party reproduction of "World Standardized" rules.

---

## Q2. Common bar/pub and league variants (US bar, APA, UK blackball / two-visit, "call the 8 only", "slop counts") and which are most intuitive

### Takeaway
Variants mostly differ on four things: the 8 on the break, scratching while shooting the 8, whether shots must be called, and the size of the foul penalty (ball in hand vs. UK "two visits"). UK governing bodies have themselves moved from the two-visit penalty to **one visit with ball in hand anywhere** (International Rules, 2022). That means mainstream rules on both sides of the Atlantic now agree on "foul = ball in hand anywhere", which is good evidence it is the most widely understood penalty.

### Cited Findings
- **APA (US amateur league):** sinking the 8 on the break wins, unless you also scratch, which loses. Scratching while shooting the 8 loses even if the 8 is missed. "Slop counts": shots need not be called, but the shooter must mark the pocket for the 8. If a player legally pockets balls of only one group on the break they "take what you make". Jumped object balls are not a foul and are spotted later. — [DRDAVE](https://drdavepoolinfo.com/faq/rules/league-rule-differences/)
- **CSI/BCAPL/USAPL:** a scratch on the break gives the opponent "ball in hand anywhere on the table" (WPA gives the kitchen only). — [DRDAVE]
- **VNEA:** jumping the 8 off the table on the break is loss of game. Jumped object balls are spotted and count as a foul. With the table open, a player may hit the 8 first in order to pocket an object ball. — [DRDAVE]
- A third-party summary of bar rules says the 8 on the break is often an automatic win in bars, versus spot or re-rack under BCA/WPA and win-unless-scratch under APA. — [inplaymagazine (search snippet)](https://inplaymagazine.com/?p=34493) (not read in full; low confidence)
- Wikipedia: amateur leagues "use their own rulesets which have slight differences from WPA rules and from each other", and house rules vary "from area to area but even from venue to venue". — [WIKI8](https://en.wikipedia.org/wiki/Eight-ball)
- **UK / blackball lineage** (red/yellow unnumbered balls, black on the foot spot, small rounded pockets). Rulesets over time:
  - BAPTO/UKPF (1976–2004): 2 visits plus a free shot, cue ball anywhere in the "D".
  - Old EPA (1978–1998): 2 visits plus a free shot, cue ball in baulk.
  - WEPF World Rules (1998–2022): 2 visits, no free shot, cue ball played from where it lies.
  - WPA blackball (2004–present): 1 free shot then 1 visit, cue ball in baulk.
  - **International Rules (2022–present): 1 visit, no free shot, cue ball anywhere on the table.**
  The WEPF became the IEPF in August 2024. Jump shots are illegal in all of these rulesets. — [WIKIBB](https://en.wikipedia.org/wiki/Blackball_(pool))
- [INTL23] 6e confirms that a standard foul gives "a cue ball in hand, which can be placed anywhere on the playing surface with one visit to the opponent." Other International Rules details:
  - Legal break (4f): **3 cumulative points**, 1 per ball potted (the 8 included) and 1 per unpotted ball that passes the centre-pocket line. An illegal break means a re-rack (4g).
  - 8 potted on the break (4i): always re-spotted. If it is the only ball potted, control passes to the opponent.
  - Groups (6a): "decided on the first ball legally potted". "Balls potted from the break are disregarded." If one ball of each group is potted in one shot, the player gets the group the cue ball struck first. "Groups are not decided on a foul shot."
  - Combinations (6c): balls from both groups may be potted in one shot. "Combination shots do not have to be called". The "on" ball must be struck first.
  - Loss of turn (6d): potting only the opponent's ball after striking your own first is loss of turn, not a foul. The cue ball is played from where it lies.
  - Loss of frame (6f): foul in the same shot the 8 is potted; potting the 8 while any own-group ball remains, "Including potting the last group ball and eight-ball in the same shot".
  - Stalemate (6g): re-rack, same breaker.
  - Off-table object balls (6l, 6m): re-spotted (8 first, then reds, then yellows).
  - Shot clock (6j): 45 s. — [INTL23](https://www.maltapoolassociation.net/wp-content/uploads/2023/05/International-Eightball-Rules-Revision-2b-Jan-2023-A4-booklet.pdf)
- Earlier WEPF "World Rules" text: "The incoming player is awarded two visits from:- a) Where the Cue Ball lies, OR … b) From Baulk." — [WEPF Full Rules PDF (search snippet)](https://ucdpoolandsnooker.yolasite.com/resources/WEPF%20Full%20Rules.pdf) (snippet only)

### Inferences
- **The UK two-visit rule is the least intuitive variant for casual players.** It needs a visit counter that carries over, sometimes a free-shot exception, and a "from where it lies or baulk" choice. Its own governing body dropped it in 2022 in favour of ball in hand anywhere with one visit. Recommend against it.
- **"Slop counts" plus "call the 8 only"** (the APA model) is the most intuitive calling scheme. It removes per-shot call UI but keeps a deliberate, readable final moment, and it stops fluke wins on the 8.
- **"8 on break = instant win" (bar rule)** is intuitive in a bar but bad against a CPU. A random break decides the match and wipes out the 2–5 minute session. The WPA and International rule of always re-spotting is the better fit when the engine picks the default.
- **"Scratch on the 8 = loss" (APA/bar)** is harsher than WPA/BCA, where it is only a foul unless the 8 drops. For a friendly game the WPA behaviour is more forgiving. The bar rule is still widely known, so it could be an optional "Pro" toggle.
- The International (UK 2022) group rule is easy for a machine to decide without calls: groups are set by the first legal pot after the break, and on a mixed pot the first-contacted group wins. It fits a no-call casual rule set well.

### Gaps
- I could not reach Dr. Dave's "bar rules" page (404 at /faq/rules/bar/). I found no authoritative survey of US bar-rule frequency. Statements about how common "8 on break wins" or "last pocket" are in bars rest on a single low-confidence snippet.
- I did not read current EPA "pub" or old-EPA rule texts directly (the EPA URL returned 404). UK blackball details come from Wikipedia.

---

## Q3. What casual mobile/online pool games commonly simplify (generic conventions)

### Takeaway
I found no authoritative, citable survey of mobile pool rule sets. Generic online guides show the usual simplified profile is WPA-like: ball in hand anywhere after any foul, the pocket called only for the 8, groups set by the first legal pot after the break, and the rail-after-contact rule kept. On scratching while shooting the 8, sources vary between "loss" and "just a foul".

### Cited Findings
- A generic online-billiards guide presents "Ball-in-Hand Anywhere" as the standard foul penalty, with a "kitchen" variant. It requires calling the pocket for the 8. It sets groups by "the first ball you legally pocket on a non-break shot". It keeps the rail rule ("Failing to drive any ball to a rail or pocket a ball after contact" is a foul). It states "scratching while shooting at the 8, is a loss". It notes that some house rules make the 8 on the break "an instant win or instant loss". It does not mention a turn timer or a three-foul rule. — [foony guide](https://foony.com/posts/mastering-8-ball-pool-online-billiards)
- Search-result summaries of general guides repeat the same pattern: the 8 pocket must be declared, and an 8 in the wrong pocket is an immediate loss. "Ball-in-hand anywhere" for all fouls, including a break scratch, is listed as a common house variant. — [billiardsforum (snippet)](https://www.billiardsforum.com/pool-rules/8-ball-rules), [bookgame.io (snippet)](https://bookgame.io/en/blog/8-ball-pool-key-rules-and-gameplay-guide) (snippets only)
- Official rules already include several of the "simplifications" credited to mobile games. WPA standard fouls give ball in hand anywhere (§4.9). WPA 8-ball has no three-foul rule (§3.13). Push-out is a 9-ball rule (§5.4), not part of 8-ball. — [WPA25]

### Inferences
- Many "mobile simplifications" are just official WPA rules with the human options fixed: ball in hand anywhere, no three-foul rule, no push-out. The real departures from WPA are four:
  1. No per-ball calls ("slop", keep only the 8 call).
  2. Fixed defaults instead of option prompts on illegal break / 8 on break / break fouls.
  3. Ball in hand anywhere even after a break foul.
  4. Usually no enforcement of the four-balls-to-rail break requirement, or an automatic "accept table" default.
- Physical-etiquette fouls (foot on floor, touched ball, double hit, push shot, balls still moving, out of turn) cannot happen in a simulated stroke and drop out naturally.
- A turn timer stands in for "slow play" (§3.14). Against a CPU it is optional; it matters mainly for human-vs-human.

### Gaps
- No primary source documents the exact rules of specific commercial mobile pool titles. By project policy we should not model on a named title anyway. This section is a genre-convention inference backed by generic guides only, not a measured survey.

---

## Q4. Edge cases a rules engine must handle

### Takeaway
Most edge cases come from the same few interactions: what happened in one shot (first contact, rails after contact, pocketed set, off-table set, cue fate) combined with three pieces of state (open/assigned table, whether the shooter's group was cleared *at the start of the shot*, and whether this is the break). Settle them with a fixed evaluation order: 8-ball outcome, then fouls, then group assignment, then turn continuation.

### Cited Findings (rule basis per edge case)
- **Both groups pocketed on an open table.** WPA: the called ball decides (§4.4). International: the group struck first decides, unless there was a foul, in which case the table stays open (6a(4)). — [WPA25]; [INTL23]
- **Balls pocketed only on the break (one group).** WPA, BCA and International keep the table open; groups are not set by the break. — [WPA25] §4.3(c); [BCA] rule 5; [INTL23] 4h/6a(2). APA "take what you make" assigns the group. — [DRDAVE]
- **Struck own group / open-table ball first, but only the other group went in.** International: loss of turn, not a foul, and on an open table the table stays open (6a(5)(d), 6d). WPA: the called ball was not pocketed, so play passes and the table stays open (§4.4). — [INTL23]; [WPA25]
- **8 pocketed together with a foul (including a scratch).** Loss, except on the break (WPA §4.8(a); BCA 12.1; INTL 6f(3)). On the break: the 8 is re-spotted and the opponent gets ball in hand in the kitchen, or re-breaks (WPA §4.3(f)). — [WPA25]; [BCA]; [INTL23]
- **8 pocketed on the same stroke as the shooter's last group ball.** Loss (BCA 12.2; INTL 6f(4)). WPA §4.8(b) says "before his group is cleared". Same-stroke is a loss under that wording when "cleared" is judged at shot start. — [BCA]; [INTL23]; [WPA25]
- **Cue ball and object ball both pocketed (non-8).** It is a foul. Pocketed object balls stay down (BCA rule 8; WPA §4.4/§4.9). Groups are not set on a foul shot (INTL 6a(6); WPA requires "legally pocket"). — [BCA]; [INTL23]; [WPA25]
- **Scratch while shooting at the 8, 8 not pocketed.** A foul only (WPA §4.8 lists none; BCA 12: "not loss of game if the 8-ball is not pocketed or jumped"). It is a loss under APA. — [BCA]; [DRDAVE]
- **8 off the table.** Loss outside the break (WPA §4.8(d); BCA 12.3). On the break it is spotted (WPA §4.3(g)). — [WPA25]; [BCA]
- **Object ball (non-8) off the table.** A foul under WPA (§3.5). WPA never spots it (§4.7). BCA re-spots jumped balls in numerical order (rule 9). International re-spots (6l/6m). — [WPA25]; [BCA]; [INTL23]
- **No ball contacted at all.** A foul under §3.3: "the cue-ball must contact an object-ball". — [WPA25]
- **8 hit first on an open table.** A foul, unless a group is already fully pocketed; the shooter may then "temporarily claim" that group and shoot the 8 (§4.4). — [WPA25]
- **Simultaneous first contact (legal + illegal) or ball/cushion tie.** Resolved in the shooter's favour (§3.2, §3.3). — [WPA25]
- **Ball frozen to a rail.** It does not count as "driven to a rail" unless it leaves and returns (§2.7). — [WPA25]
- **Ball in the jaws when the shot ends.** Not pocketed unless supported by another ball that, if removed, would let it fall (§2.2). A later fall after 5 s is not a pot and is restored (§1.8). — [WPA25]. International likewise replaces balls that drop after the shot is complete (6k(1)). — [INTL23]
- **Ball returns from a pocket onto the table.** Not pocketed (§2.2). — [WPA25]
- **Spotting with the spot blocked.** Use the Long String toward the foot rail. If blocked, place it touching the interfering ball, but not touching the cue ball. Use above the spot as the last resort (§1.5). — [WPA25]
- **Kitchen ball in hand with all legal balls in the kitchen.** The nearest legal ball may be spotted on request (§1.6), and §3.11 forbids hitting a kitchen ball without first crossing the head string. — [WPA25]
- **Stalemate.** Re-rack with the original breaker (WPA §4.11; INTL 6g). — [WPA25]; [INTL23]

### Inferences
- "Group cleared" has to be **captured at shot start** (a snapshot), not checked after the shot. Otherwise "last group ball + 8 on the same stroke" wrongly becomes a win.
- The open-table "group fully pocketed" exception (§4.4) is reachable in practice. For example, all solids could go down across break and open-table shots before anyone is assigned. Without the exception, the engine would deadlock or wrongly foul the shooter for hitting the 8.
- Choosing the casual "spot off-table object balls" rule (BCA/INTL), and not WPA's "stays out", avoids a strange win path where jumping your own balls off the table "clears" your group.
- The simulator must report *new* cushion contacts that begin after first contact (contact-begin events), not continuous contacts, so frozen balls do not satisfy the rail rule (§2.7).
- Jaw and settling rules are mostly moot in a deterministic simulator. Define "pocketed" as entering a pocket capture volume or dropping below the bed plane before the at-rest check. Define "at rest" by a fixed velocity threshold held for N ticks. No post-shot settling exists, because the simulation stops.

### Gaps
- No source settles whether an off-table 8 that comes back onto the table (for example after striking a light) counts. WPA §2.6 says it does count as off table. A simulator cannot produce this case, so it is moot.

---

## Q5. Recommended casual rule set for a 2–5 minute vs-CPU match, with a precise state-machine spec and unit-test list

### Takeaway
Use WPA 2025 as the base. Fix every human option to a single default. Drop per-ball calls (slop counts) but keep a pocket call for the 8. Use ball in hand anywhere after every foul, including break fouls. Set groups by the first legal pot after the break, with the first-contacted group deciding mixed pots (International 6a(4)). Re-spot off-table object balls. No three-foul rule, no safeties, no two-visit rule. Keep the 8 on the break as a re-spot, never a win or loss. Keep the rail-after-contact foul but show its reason clearly. Add a stalemate guard. Play one rack per match.

### Cited Findings (justifying sources)
- WPA ball in hand anywhere for standard fouls (§4.9), no three-foul rule for 8-ball (§3.13), 8 on a legal break is "not a foul" and is spotted or re-broken (§4.3(e)), stalemate re-rack with the same breaker (§4.11). — [WPA25]
- UK International Rules (2022–) moved to one visit with ball in hand anywhere, set groups by the first legal pot with the first-contacted group deciding mixed pots, do not require combination calls, and always re-spot an 8 potted on the break. — [INTL23]; [WIKIBB]
- APA-style "slop counts but mark the 8's pocket" is an established league convention. — [DRDAVE]
- BCA: a scratch while shooting at the 8 without pocketing it is not a loss. Pocketing the 8 with the last group ball is a loss. Jumped balls are re-spotted. — [BCA]
- The 45 s shot clock in International Rules gives a reference value for a turn timer. — [INTL23] 6j

### Recommended rule set "Casual 8" (each rule: decision, then reason)
| # | Rule | Source basis / reason |
|---|------|---------------------|
| R1 | Rack: 8 in the centre of row 3, one ball of each group on the two back corners, all others shuffled with the seeded `Rng`. | WPA §4.2. Determinism requires the seeded Rng. |
| R2 | Break: cue ball placed in the kitchen. Any first contact is allowed. **The 4-balls-to-rail requirement is not enforced.** A break that pockets nothing is not a foul; turn passes. | Removes WPA §4.3(d)'s three-way prompt. Simulated breaks at normal power almost always meet it anyway. Keep a `strict_break` flag for a Pro mode (auto default: opponent accepts the table). |
| R3 | Break, legal with balls pocketed: the shooter continues and **the table stays open**. | WPA §4.3(c), BCA 5, INTL 4h all agree. |
| R4 | 8 pocketed or off table on the break: **always re-spot the 8**. No foul: the breaker continues. Foul: the opponent gets ball in hand anywhere. Never a win or loss. | WPA §4.3(e)/(f)/(g) with options fixed. Avoids a random CPU-break win. INTL 4i also always re-spots. |
| R5 | Break foul (scratch, cue off table, object ball off table): opponent gets **ball in hand anywhere** (not kitchen), table open. Off-table object balls are re-spotted. | CSI/BCAPL use anywhere for break scratch [DRDAVE]. One placement mode only, so no §3.11 kitchen-crossing rule is needed. |
| R6 | No called shots except the 8. Before any shot on the 8, the shooter picks a pocket. UI default: the pocket nearest the projected object-ball line, editable. | APA "slop counts / mark the 8". WPA §4.8(c). Keeps the climactic moment readable and stops fluke wins. |
| R7 | Open table: any non-8 ball may be hit first. The 8 first is a foul, unless one group has 0 balls on the table at shot start (WPA §4.4 "temporary claim"; then the shooter is on the 8 with a call). | WPA §4.4. |
| R8 | Group assignment on a legal (no-foul) non-break open-table shot that pockets at least one non-8 ball: if the first-contacted ball's group has a ball in the pocketed set, assign that group; else assign the group of the pocketed balls. Never assign on a foul. | INTL 6a(4)/(6), plus APA "take what you make" for the hit-A-sink-B case (casual choice; the INTL rule would be loss of turn instead). |
| R9 | Assigned table: first contact must be own group, or the 8 once the group is cleared at shot start. | WPA §3.2 / §4.9. |
| R10 | Rail rule: if nothing is pocketed, after first contact at least one ball (cue or object) must begin a new cushion contact. Otherwise foul "No rail". | WPA §3.3 / §2.7. Kept to stop degenerate soft-tap safeties by the CPU. Show the reason clearly. Flag `rail_rule` (default on). |
| R11 | Fouls: cue pocketed, cue off table, no contact, wrong first contact, no rail, object ball off table. Any foul: turn passes and the opponent gets **ball in hand anywhere** (non-overlapping, inside the cushions). Pocketed object balls stay down. | WPA §4.9. INTL 6e is the same penalty. |
| R12 | Off-table object balls (non-8) are a foul and are **re-spotted** on the foot line per WPA §1.5 geometry. | BCA 9 / INTL 6l. Departs from WPA §4.7 so a group cannot be "cleared" by jumping balls off. |
| R13 | Own-group ball pocketed on a legal shot: continue. Only the opponent's balls pocketed: no foul, turn passes, and those balls stay down (credited to the opponent). | WPA §4.5. INTL 6d. |
| R14 | Loss (non-break): 8 off table; 8 pocketed while the shooter's group was not cleared at shot start (covers early 8 and last-ball-plus-8 on the same stroke); 8 pocketed on a foul shot (incl. scratch); 8 in a pocket other than the called one. | WPA §4.8. BCA 12.2. |
| R15 | Win: 8 pocketed in the called pocket, no foul, shooter's group cleared at shot start. | WPA §4. |
| R16 | Scratch on the 8 without pocketing it: ordinary foul, opponent gets ball in hand. Not a loss. | WPA §4.8 / BCA 12 (friendlier than APA). Flag `scratch_on_8_loses` for Pro mode. |
| R17 | No three-foul rule, no safety calls, no push-out, no two-visit penalty. | WPA §3.13. 8-ball has no push-out. The UK itself dropped two visits [WIKIBB]. |
| R18 | Stalemate guard: if `STALEMATE_SHOTS` (suggest 24) consecutive shots pass with no object ball pocketed, re-rack with the original breaker. | WPA §4.11 / INTL 6g, made machine-decidable. Also stops infinite loops in AI self-play tests. |
| R19 | Optional turn timer (suggest 45 s, matching INTL 6j). Expiry is a foul. Off by default vs CPU. | WPA §3.14 / INTL 6j. |
| R20 | Match = 1 rack. Human breaks first (or alternate in a "best of 3" mode). | Session length target. Design choice, no source. |

### State-machine specification (pure GDScript, no Node dependencies)

**Constants:** `CUE=0`, `EIGHT=8`, `SOLIDS={1..7}`, `STRIPES={9..15}`. Pockets are 0–5. `Group = NONE | SOLIDS | STRIPES`.

**State (`RulesState`, value object, cloneable):**
- `phase: BREAK | PLAY | GAME_OVER`
- `shooter: 0|1`, `breaker: 0|1`
- `group[2]: Group` (both NONE while the table is open). `table_open := group[0]==NONE`.
- `on_table: PackedByteArray[16]` (object-ball presence)
- `ball_in_hand: NONE | KITCHEN | ANYWHERE` (KITCHEN only for the opening break)
- `called_pocket: int` (−1 when no call is required or none has been made)
- `shots_without_pot: int`, `fouls: int[2]` (stats only)
- `winner: -1|0|1`, `end_reason: enum`

**Derived, snapshotted at shot start (`ShotContext`):**
- `cleared_at_start := table_open ? (count(SOLIDS on table)==0 or count(STRIPES on table)==0) : count(group[shooter] on table)==0`
- `on_eight := cleared_at_start`. If the table is open and a group is empty, `claimed_group` is that empty group (WPA §4.4 temporary claim).
- `requires_call := on_eight and phase==PLAY`

**Input from cue_sim (`ShotEvents`, produced deterministically):**
- `first_contact: int` (−1 = none). On an exact same-tick tie between a legal and an illegal ball, cue_sim/adapter reports the legal ball (WPA §3.2).
- `rail_after_contact: bool`: true if any ball started a *new* cushion contact at or after the first-contact tick (WPA §2.7, §3.3; a same-tick tie counts as after).
- `pocketed: Array[{ball, pocket, tick}]` (object balls and cue)
- `off_table: Array[int]` (object balls and cue)
- `break_rail_balls: int` (distinct object balls with new cushion contact; used only when `strict_break`)

**`apply_shot(state, events) -> ShotResult {fouls[], continue_turn, assigned_group, respots[], ball_in_hand, game_over, winner, reason}`**. Evaluate in this order:
1. `pots := pocketed objects except 8`. `eight_down := 8 in pocketed`. `eight_off := 8 in off_table`. `cue_lost := CUE in pocketed or CUE in off_table`.
2. **Fouls** (collect all; any one makes `foul=true`):
   - `cue_lost` → SCRATCH (or CUE_OFF_TABLE)
   - `first_contact == -1` → NO_CONTACT
   - Wrong first contact (not on the break):
     - open table and not on_eight: first_contact == 8 → WRONG_BALL
     - open table and on_eight: first_contact != 8 → WRONG_BALL
     - assigned and not on_eight: first_contact not in group[shooter] → WRONG_BALL
     - on_eight: first_contact != 8 → WRONG_BALL
   - not break and pots is empty and not eight_down and first_contact != −1 and not rail_after_contact → NO_RAIL
   - any object ball in off_table → OBJECT_OFF_TABLE
3. **Break branch** (`phase==BREAK`):
   - If eight_down or eight_off, re-spot the 8.
   - Re-spot off-table object balls.
   - If foul: switch shooter, `ball_in_hand=ANYWHERE`.
   - Else if pots is non-empty or eight_down: the same shooter continues.
   - Else (strict_break and break_rail_balls<4) → ILLEGAL_BREAK. Default handling: switch shooter, table accepted as is.
   - Else switch shooter.
   - The table stays open. Set `phase=PLAY`. Done.
4. **8-ball branch** (phase==PLAY and (eight_down or eight_off)) → GAME_OVER:
   - eight_off → LOSS(EIGHT_OFF_TABLE)
   - not cleared_at_start → LOSS(EARLY_EIGHT)
   - foul → LOSS(EIGHT_WITH_FOUL)
   - pocket != called_pocket → LOSS(WRONG_POCKET)
   - else WIN
   - Loss means the opponent wins. Check in this order so the reported reason is the most specific (WPA §3: only the most serious foul is enforced).
5. **Respot** off-table object balls (R12). Remove pocketed balls from `on_table`.
6. **Foul branch:** switch shooter, `ball_in_hand=ANYWHERE`. Groups unchanged (no assignment on a foul). Done.
7. **Open-table assignment** (legal shot, table open, pots non-empty) per R8. Set `group[shooter]` and `group[other]`. Continue the turn.
8. **Assigned table:** continue if any ball in pots is in group[shooter]; else switch shooter (cue ball stays where it lies).
9. **Stalemate counter:** reset if pots or eight_down, else +1. If it reaches STALEMATE_SHOTS → RERACK (same breaker, phase=BREAK).
10. Clear `called_pocket`. The next turn's ShotContext recomputes `requires_call`, and the UI must collect a call before the shot when it is true. If no call is given, reject the shot (do not foul).

**Invariants worth asserting in tests:**
- Exactly one of {continue, switch, game_over, rerack} per shot.
- `group[0] != group[1]` once assigned.
- Ball counts are conserved: `on_table` plus pocketed equals 15 at all times (re-spotted balls return).
- `apply_shot` is pure: the same state plus events gives the same result.
- No assignment on a foul or on the break.

### Suggested unit tests (GdUnit4, pure logic; each is a hand-built ShotEvents fixture)
Break:
1. Break pots a solid, no foul → same shooter, table open, phase PLAY.
2. Break pots one solid and one stripe → shooter continues, table open.
3. Break pots nothing (strict_break off) → switch, no foul, no ball in hand.
4. strict_break on: break pots nothing and 3 rail balls → ILLEGAL_BREAK. 4 rail balls → legal.
5. Break pots the 8 only, no foul → 8 re-spotted on the foot spot, breaker continues, no game over.
6. Break pots the 8 and scratches → 8 re-spotted, opponent gets ball in hand ANYWHERE, no game over.
7. Break scratch with a solid pocketed → foul, table open, solid stays down, opponent gets ball in hand.
8. Break drives a stripe off the table → foul, stripe re-spotted, ball in hand.
9. Break drives the 8 off the table → 8 spotted, foul, not a loss.
10. 8 re-spot with the foot spot occupied → placed on the Long String toward the foot rail, not touching the cue ball.

Open table:
11. Legal shot pots one stripe → shooter = STRIPES, opponent = SOLIDS, continue.
12. Hits a solid first and pots a solid and a stripe → SOLIDS (first-contact group).
13. Hits a solid first and pots only a stripe → STRIPES (take what you make), continue.
14. Hits the 8 first on an open table → foul WRONG_BALL, ball in hand, table stays open.
15. Pots a solid and scratches → foul, table stays open, solid stays down.
16. Misses everything → NO_CONTACT foul.
17. Contacts a ball, nothing pocketed, no new cushion contact → NO_RAIL foul.
18. Contacts a ball that was frozen to a rail and stays on it, no other cushion contact → NO_RAIL (frozen does not count).
19. Open table with all 7 solids already down → shooter may hit the 8 first (no foul) and requires_call is true. A legal 8 pot in the called pocket wins.

Assigned table:
20. Hits own group first and pots own ball → continue.
21. Hits own group first and pots only an opponent ball → switch, no foul, the ball stays down.
22. Hits an opponent ball first and pots own ball → WRONG_BALL foul, own ball stays down, ball in hand.
23. Same-tick tie between a legal and an illegal first contact (adapter reports the legal one) → legal.
24. Object ball off table on a normal shot → foul and re-spot. A group with that ball cannot count as cleared.
25. Cue ball off table → foul, ball in hand ANYWHERE.

8-ball:
26. Group cleared at start, legal pot of the 8 in the called pocket → WIN.
27. 8 in a different pocket than called → LOSS(WRONG_POCKET).
28. 8 pocketed and the cue ball scratched → LOSS(EIGHT_WITH_FOUL).
29. Last group ball and the 8 pocketed on the same stroke → LOSS(EARLY_EIGHT).
30. 8 pocketed early (own balls remain) via combination off own ball → LOSS(EARLY_EIGHT).
31. 8 pocketed by an opponent-ball-first shot (wrong ball) → LOSS(EIGHT_WITH_FOUL), or EARLY_EIGHT if not cleared (check reason priority).
32. Shooting at the 8, scratch, 8 not pocketed → plain foul, opponent gets ball in hand (scratch_on_8_loses off). Flag on → LOSS.
33. 8 driven off the table during play → LOSS(EIGHT_OFF_TABLE).
34. On the 8 with no call made → shot rejected or requires a call; the state is unchanged.
35. Pocketing the last own-group ball legally → continue; next ShotContext.on_eight is true and requires_call is true.

Meta:
36. 24 shots without a pot → RERACK, original breaker breaks.
37. The stalemate counter resets on any object-ball pot, including a pot on a foul shot.
38. Determinism: the same seed gives the same rack order. apply_shot does not mutate its input state.
39. Ball conservation invariant over a scripted 30-shot game.
40. No assignment can ever happen on the break or on a foul (property test over random event fixtures from the seeded Rng).

### Inferences
- Each fixed default removes a prompt dialog. These are the biggest time savers for a 2–5 minute session, because WPA §4.3 alone has up to five option prompts.
- Ball in hand anywhere after a foul strongly favours the incoming player. That makes fouls costly but simple. It is also the main way a weak human can catch up with a CPU that fouls on purpose at low difficulty. Pair it with an AI difficulty knob, not a rules change.
- Keeping the 8 call (R6) costs one tap per game per player and prevents the most frustrating casual outcome: losing or winning on an accidental 8 drop that would have been legal anyway.
- The rail rule (R10) is the most "invisible" rule to casual players. If playtests show confusion, the best fallback is to keep it for the CPU (so it cannot exploit soft safeties) and show an on-screen reason ("No ball hit a cushion") rather than removing it.

### Gaps
- **Match duration:** I found no source measuring how long a single casual 8-ball rack takes, on a table or in apps. The 2–5 minute target cannot be checked against data here. Measure it with AI-vs-AI self-play (shots per rack × average shot time).
- No source evaluates which casual rule variants players find most intuitive (playtest data). The recommendations above are reasoned from rule-body trends (the UK move to ball in hand anywhere, APA slop with an 8 call), not from user research.
- The WPA and BCA combination-shot wording conflicts (BCA rules 4 and 7). The casual set avoids the question by not requiring calls except for the 8, and by accepting the 8 into the called pocket by any path, as WPA §1.7 allows.
