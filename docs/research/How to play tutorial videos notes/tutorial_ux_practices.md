# How-to-Play Tutorial UX in Casual/Puzzle Mobile Games: Video Loops vs Live In-Engine Demos vs Interactive First Play

Scope: evidence and conventions for teaching controls and rules in casual/puzzle/arcade mobile games, applied to Pocket Arena 8's "Serpent Grid" (swipe to turn, wrap edges, eat orbs, make the CPU crash) and "Stack Drop" (tap rotate, drag move, flick hard-drop, HOLD / two-finger tap, clear rows to send garbage). Today's baseline is a static 4-row icon + title + subtitle panel. Research date: 2026-11-13. Source dates are noted inline. Mechanics and genre conventions only. No specific commercial product's look is described or recommended.

## 1. Evidence on tutorial formats (passive video/animation vs interactive "learn by doing" vs text): effects on retention, completion, skip rates

### Takeaway
The best controlled evidence (Andersen et al., CHI 2012, n > 45,000) says tutorials barely matter for simple, genre-typical games, which players learn by experimenting. They pay off only for complex or unconventional games, and there, teaching in context beats an up-front manual. When some help is warranted, interactive help comes out best and video a close second, with text and no help trailing (Kao, FDG 2020, n = 1,646). Up-front "deck of cards" instruction screens did not improve task success in apps (NN/g 2020). There is no published, rigorous mobile-game dataset that ties tutorial skip rate to D1 retention. Industry numbers are vendor anecdotes.

### Cited Findings
**Andersen et al. 2012, "The Impact of Tutorials on Games of Varying Complexity" (CHI 2012, pp. 59-68)**
- Multivariate A/B test, 8 tutorial conditions, 3 games (Refraction: a puzzle game. Hello Worlds: a platformer. Foldit: complex and unconventional), over 45,000 players. The conditions varied presence, context-sensitivity, freedom (blocking vs non-blocking) and on-demand help — [Andersen et al. 2012 PDF](https://grail.cs.washington.edu/projects/game-abtesting/chi2012/chi2012.pdf); [project page](https://grail.cs.washington.edu/projects/game-abtesting/chi2012/)
- Foldit (complex): context-sensitive tutorials gave 75% more levels and 29% longer play than no tutorial. Context-insensitive (up-front manual) tutorials gave 25% more levels and 12% longer play. No significant effect on return rate — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- Refraction (simple puzzle): no significant effect of tutorials. Hello Worlds: no effect on levels or time, and 3.5% *fewer* players returned with context-sensitive tutorials than with none — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- Context-sensitive vs up-front manual: in Foldit, 40% more levels and 16% longer play. No effect in Refraction. In Hello Worlds, return rate was about 2% lower with context-sensitive tutorials — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- Restricting freedom (blocking "stencil" steps that force the target action) gave no meaningful improvement in any game. The authors suggest that "forcing the player to perform a series of actions may not be effective" and that players may dislike having their freedom restricted — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- On-demand help button (with no other tutorial): Foldit played about 12% longer. Refraction players completed 12% fewer levels and played 15% less time. Hello Worlds players returned about 3% less often. Only 31% of Refraction players with the button ever used it — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- Authors' conclusion: "players seem to learn more from exploring than from reading text". Design early levels to maximize experimentation. Tutorials "may not be worth the investment" for games whose mechanics are discoverable by experimentation. Test tutorial implementations, because they "can harm player retention unexpectedly" — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- Caveat: these were 2012 browser/Flash casual games, not touch-first mobile. The results are about *text* tutorials. Video/animated demos were not tested — [Andersen et al. 2012](https://grail.cs.washington.edu/projects/game-abtesting/chi2012/chi2012.pdf)

**Kao 2020, "Exploring Help Facilities in Game-Making Software" (FDG '20)**
- n = 1,646 participants, randomly assigned to 6 conditions: Text Help, Interactive Help, Intelligent Agent Help, Video Help, All Help, No Help. "Interactive Help has a greater positive impact on time spent, controls learnability, learning motivation, total editor activity, and game level quality. Video Help is a close second" — [Kao 2020](https://people.csail.mit.edu/dkao/pdf/kao2020fdg.pdf)
- Interactive and Video both produced longer time spent than the other 4 conditions (p < .05, d = 0.27-0.46). Interactive produced more actions than Text (d = 0.23) and No Help (d = 0.33). No Help gave the lowest time, actions and controls learnability — [Kao 2020](https://people.csail.mit.edu/dkao/pdf/kao2020fdg.pdf)
- Notably, "All Help" (every format offered at once) did *not* beat a single good format. It sat among the lower groups on time spent — [Kao 2020](https://people.csail.mit.edu/dkao/pdf/kao2020fdg.pdf)
- The video there was 4 min 27 s, voiced, with a scrubber, closeable and minimizable. That is far longer than suits a mobile casual game. The domain is a PC level editor, so it is more complex than a casual game — [Kao 2020](https://people.csail.mit.edu/dkao/pdf/kao2020fdg.pdf)
- Kao's systematic review of 85 game-making tools found text help in 89.4%, official video in about half, and interactive tutorials in only 20.0% — [Kao 2020](https://people.csail.mit.edu/dkao/pdf/kao2020fdg.pdf)

**NN/g on up-front instruction screens (apps, not games)**
- "Mobile Tutorials: Wasted Effort or Efficiency Boost?" (Kendrick, NN/g, 2020-03-08) ran 70 participants, 35 read a deck-of-cards tutorial and 35 skipped it, across 4 iOS apps. Task success was 91% for readers vs 94% for skippers (n.s., p = 0.443). Perceived ease was 4.92 vs 5.49 on a 1-7 scale, significant (p = 0.047), so readers found tasks *harder*. Time was 93.49 s vs 85.17 s (n.s.). The same "overly complicated" effect was seen with coach marks / instructional overlays. NN/g recommends contextual/interactive help over up-front cards — [NN/g 2020](https://www.nngroup.com/articles/mobile-tutorials/)
- "Mobile-App Onboarding" (Kendrick, NN/g, 2020-06-21): instructions are warranted when workflows are unique or non-standard, "or the experience is expected, as in mobile gaming". Prefer contextual tips at first encounter. Keep it short, one concept per card, minimize cards, make it skippable with a highly visible Skip. "Instructional onboarding should not be used to supplement poor design" — [NN/g 2020](https://www.nngroup.com/articles/mobile-app-onboarding/)

**Small studies on passive vs interactive instruction (non-game, lower weight)**
- In a Rubik's-cube learning study (Catrambone, Georgia Tech), an interactive tutorial *hindered* learning on simple spatial tasks (Exp. 1) but beat a passive tutorial when difficulty rose (Exp. 2). This is reported via search snippet. I did not read the full paper — [core.ac.uk record](https://core.ac.uk/download/77947156.pdf)
- Video vs text software tutorials (PeerJ preprint, 42 students): text users finished faster, video users applied the content faster, final performance was about the same, and learners preferred video for new content. Also via search snippet — [PeerJ preprint](https://peerj.com/preprints/2413v1.pdf)

**Industry/vendor numbers (anecdotal, mobile F2P)**
- Supersonic (Berkovich, 2025-03-03): one title had 60% churn *during* the tutorial, caused by jumping too quickly between mechanics. Up to 1 minute of unguided play at the start caused confusion and churn. Removing 1 step or 1 click "can noticeably affect retention" in A/B tests. Recommendations: show the core mechanic immediately, introduce mechanics and UI gradually (one loop at a time), use tap-finger icons and arrows, keep early play guided — [Supersonic 2025](https://supersonic.com/learn/blog/optimizing-ftue/)
- devtodev / Game Developer (Matveev, 2017-01-10, sponsored): one game had 75% tutorial pass and another 40% (no skip option, high churn during the tutorial). The cited "optimal" pass rate is 70-80%. The biggest drop-offs came at step 1→2 and step 15→16. Fixing hidden loading steps inside a 120-step tutorial raised D1 retention by 10%. The author quotes about 30% as the average mobile D1 — [Game Developer 2017](https://www.gamedeveloper.com/business/how-to-optimize-the-tutorial-for-your-game)
- PlaytestCloud case study (vendor marketing): iterative playtesting raised one studio's tutorial pass rate to 90% with improved D1. No effect sizes given — [PlaytestCloud Nitro Games](https://start.playtestcloud.com/case-studies/nitro-games)
- A search for published data tying skip rate to D1/D7 found only illustrative thresholds (e.g., an analytics template asking whether skippers have D7 < 18% vs completers > 25%). These are hypotheses, not measurements — [Bruin template](https://getbruin.com/use-cases/mobile-gaming/midcore-tutorial-skip-rate-impact-on-d7/)

### Inferences
- Serpent Grid is simple and genre-typical, close to Andersen's "Refraction/Hello Worlds" case. Heavy tutorialisation is unlikely to move retention, and a forced or blocking tutorial could hurt it. A very short, optional demo plus learning by playing fits the evidence best.
- Stack Drop has more verbs (tap, drag-step, flick, HOLD, two-finger tap) plus a non-obvious rule (rows send garbage to the CPU). It sits between the two cases. The gesture *mapping* is the unconventional part, so that is where in-context teaching has the most value.
- Kao's "All Help < single good format" result argues against stacking a video carousel, coach marks and a help button all at once. Pick one primary channel, with an optional replay.
- Video/animation is a defensible second-best to interactive, and far better than text-only. Moving from the static icon panel to animated demos is supported. Making the first match itself teach (interactive) is the strongest option where feasible.
- Andersen's help-button harm result is a caution that a prominent "How to play" button during play may cost something. Keep it available but low-key (pause menu / start overlay), not a persistent in-game "?" badge.

### Gaps
- No rigorous study compares *looping animated demo* vs *interactive first play* in mobile casual games specifically. Nothing found with D1/D7 outcomes.
- No public dataset of tutorial skip rates for short-session puzzle/arcade games.
- I could not read NN/g's separate coach-mark/overlay article (404 on fetch), so its specific findings are not captured.

## 2. Genre conventions in mobile puzzle/arcade games for teaching gestures (mechanics-level, generic)

### Takeaway
The dominant convention is to teach *one verb at a time, by doing it*. A stylised hand or finger icon animates the gesture over the real play area, often with a dotted path or arrow, and waits until the player performs it. Mechanics and UI elements are introduced only when first needed. The cited sources support this pattern generically. The specific visual treatment is a design choice and should be original.

### Cited Findings
- Visual guidance via "tap-finger icons and arrows". Keep the goal always clear. Introduce each new button only when its mechanic appears. One loop at a time — [Supersonic 2025](https://supersonic.com/learn/blog/optimizing-ftue/)
- Show the core mechanic immediately, let players experiment right away, and pair early wins with celebration feedback — [Supersonic 2025](https://supersonic.com/learn/blog/optimizing-ftue/)
- Contextual tips are described as best suited to casual and hyper-casual games (minimal disruption). One-tap hybrid-casual games benefit from shorter, faster tutorials. Create scenarios where players must use the mechanic rather than being told. These come from secondary blog aggregations, via search summary — [Udonis blog](https://www.blog.udonis.co/mobile-marketing/mobile-games/mobile-game-tutorial); [Adrian Crook](https://adriancrook.com/?p=8055)
- For complex hand/gesture interactions, teach one or two gestures at a time (VR hand-tracking guidance, but transferable to multi-gesture touch) — [Meta hands onboarding](https://developers.meta.com/horizon/design/hands-onboarding-best-practices/)
- Design-community consensus (GDC 2012 talk summarised in search results): blend teaching into play so players "can't tell where the tutorial ends and the game begins". Avoid tutorial text not immediately relevant to the current action. A GDC Vault design talk, "This is a Talk About Tutorials, Press 'A' to Skip" (Berbece), centres on tutorials players don't notice as tutorials. I saw only the session metadata, not the content — [GDC Vault session](https://www.gdcvault.com/play/1023845/contactUs); [Game Developer: No More Tutorials](https://www.gamedeveloper.com/audio/no-more-tutorials-how-to-convey-information-through-design-repost-)
- ThinkyCon 2025 talk: research comparing three onboarding approaches in a puzzle game (pop-up tutorial vs showcasing mechanics vs encouraging tinkering), plus interviews with 25 puzzle developers. Only the abstract was available, with no results — [ThinkyCon 2025](https://thinkygames.com/events/thinkycon/2025/talks/playful-puzzle-mechanics/)
- Andersen: forcing actions ("stencils") did not help. Context-sensitive delivery helps only where tutorials help at all — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)

### Inferences
Generic conventions, mapped to the two games. These are my synthesis, not sourced:
- **Swipe-to-turn (Serpent Grid):** an animated hand swipes in a direction, and the snake turns at the same moment, so the cause-effect link is visible within about 0.3 s. Show "anywhere on screen" by starting the swipe away from the snake. **Wrap edges:** show the head exiting one edge and re-entering the opposite edge with a brief highlight on both edges. A rule like this is much clearer animated than in text. **Win condition:** show the CPU snake hitting the player's body, with a big "+1" or crash burst.
- **Falling-block verbs (Stack Drop):** demonstrate each gesture in isolation over a real board with one piece. Tap → rotate. Drag → column-by-column step, with a ghost/landing indicator moving. Quick downward flick → instant drop with a trail. HOLD → piece swaps into the hold slot (point at the actual HOLD button, which is real UI). **Garbage rule:** a row clears, then an arrow or particles fly to the CPU's well and grey rows rise there. Like wrap edges, this is a "relationship" that is far more legible in motion.
- Prefer an *in-engine* replay over pre-rendered video. It shares the real board's look, scales crisply on every DPI, respects theme/skin, localises without re-rendering, costs near-zero APK size, and stays in sync if visuals change. It can also be driven by a deterministic scripted input sequence through the same pure logic classes, which fits the project's seeded-Rng, fixed-timestep architecture.
- Avoid adopting any particular commercial game's hand-icon art, colours or panel layout. The "pointing hand + path" idea is a generic convention, and the art should be original.

### Gaps
- No quantitative source on hand-pointer vs arrow vs highlight effectiveness.
- No source on whether showing "swipe anywhere" vs "swipe on the snake" changes error rates.

## 3. Pacing: clip length, number of steps, looping, auto-advance, caption length, skip/replay placement, and when to show

### Takeaway
Evidence points to *few* steps (minimize cards, one concept each), very short text, an always-visible Skip, and replayable instructions. Exact second counts are mostly practitioner convention, not research. A sensible target, inferred: 3-5 steps per game, each a 2-4 s gesture loop, a caption of about 2-6 words, and a whole tour under about 20 s. Show it at first launch of each game (skippable), then teach in context during the first match, with replay from the start overlay/pause menu.

### Cited Findings
- One concept per card. Minimize the number of cards. Keep to the minimum users need. Make instructions optional with a highly visible Skip — [NN/g onboarding 2020](https://www.nngroup.com/articles/mobile-app-onboarding/)
- Removing even 1 step or 1 click measurably affected retention in A/B tests. Jumping too fast between mechanics caused 60% in-tutorial churn in one title. Too much unguided time (up to 1 min) also caused churn, which argues for brief guidance up front rather than none — [Supersonic 2025](https://supersonic.com/learn/blog/optimizing-ftue/)
- Drop-off concentrates at the very first transition (step 1→2). A no-skip tutorial had a 40% pass rate vs 70-80% "optimal" — [Game Developer 2017](https://www.gamedeveloper.com/business/how-to-optimize-the-tutorial-for-your-game)
- "Allow all narrative and instructions to be replayed" (Advanced). "Indicate / allow reminder of controls during gameplay" (Intermediate). "Include interactive tutorials" (Basic). "Include a means of practicing without failure, such as a practice level or sandbox mode" (Intermediate) — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Moving content that starts automatically, lasts more than 5 s, and is shown alongside other content needs a pause/stop/hide mechanism (WCAG 2.2 SC 2.2.2). Exceptions: content started by the user's direct action, or motion essential to the activity — [W3C WCAG 2.2 Understanding 2.2.2](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)
- Context-sensitive (just-in-time) teaching beat an up-front manual where tutorials mattered (Foldit +16% time, +40% levels) — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- Material 3 motion duration scale for UI transitions: short 50-200 ms, medium 250-400 ms, long 450-600 ms, extra-long 700-1000 ms. These come from secondary sources. The official page did not render on fetch — [Flutter M3 motion template](https://flutter.googlesource.com/mirrors/flutter/+/0a6947049b89e7cd9b4ff899ad464ec7365f620e/dev/tools/gen_defaults/lib/motion_template.dart); [bevy_material_ui tokens](https://docs.rs/crate/bevy_material_ui/latest/source/src/tokens.rs)
- Captions should be paced to a suitable words-per-minute for the audience, with a larger minimum default size for subtitles because they are on screen briefly — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/); [Xbox Accessibility Guidelines](https://learn.microsoft.com/en-us/gaming/accessibility/guidelines)

### Inferences
Proposed spec, my synthesis grounded in the above:
- **Steps:** Serpent Grid 3-4 (swipe to turn · wrap edges · eat orbs to grow · make the CPU crash). Stack Drop 4-5 (tap rotate · drag move · flick drop · HOLD · clear rows → garbage). This matches the existing 4-row panel's content, so the change is about *format*, not adding content.
- **Clip length:** about 2-4 s per gesture loop (gesture ~0.4-0.6 s, result ~0.5-1 s, hold the end state ~0.5-1 s, ~0.3 s reset/fade). Each loop should replay 1-2 times before an auto-advance, giving ~4-6 s per step. A full auto-advancing tour then lands at ~15-25 s, under the point where attention drops off.
- **Auto-advance:** yes, with step dots and tap/swipe to go forward/back. Pause auto-advance when the user touches. Always show a Skip / "Play" button (≥48 dp) from the first frame. Because a carousel that auto-advances >5 s counts as auto-starting motion, WCAG 2.2.2 implies a pause affordance (tap-and-hold to pause, or a pause icon). This applies unless the tour was explicitly opened by the user tapping "How to play", which the exception covers.
- **Captions:** a verb-first title of 1-3 words ("Swipe to turn", "Flick to drop") plus an optional ≤8-word subtitle. Never put essential info in text alone (the animation carries it).
- **When to show:** (1) first launch of each game, as a skippable tour or ideally as an inline demo in the start overlay. (2) The first match teaches in context: a ghost hand appears only if the player hasn't performed the verb within N seconds, or at the first moment the verb matters (e.g., the first time the snake nears an edge, the first time HOLD would help). (3) Replay from the "How to play" button and the pause menu. (4) Don't repeat once the player has demonstrated each verb, and track that per verb in SaveService.games[<id>].
- **Tour vs contextual hints:** given Andersen's finding that up-front instruction barely helps simple games, keep the first-launch tour *very* short (or a single looping preview) and let contextual hints do the heavy lifting.

### Gaps
- No primary research gives an optimal per-step demo duration in seconds for game tutorials. The numbers above are inferred.
- No source quantifies auto-advance vs manual-advance completion rates in games.

## 4. Placement: inside the start overlay vs full-screen carousel vs "ghost hand" over the real board during the first match

### Takeaway
Evidence favours in-context, learn-by-doing teaching (the ghost hand over the real board) for anything a simple game needs taught. A full-screen up-front carousel is the weakest format per NN/g and Andersen. A short looping in-engine demo embedded in the start overlay is a good middle ground: it is ambient, skippable by simply pressing Play, and doubles as the "video" the user wants. The recommended combination is a start-overlay looping demo plus first-match contextual ghost-hand nudges, with the full-screen tour kept only as an on-demand replay.

### Cited Findings
- Deck-of-cards (full-screen carousel) tutorials did not improve task success and made tasks feel harder (5.49 → 4.92 ease) — [NN/g 2020](https://www.nngroup.com/articles/mobile-tutorials/)
- Prefer contextual tips at the user's first encounter with a feature, and keep them unobtrusive — [NN/g onboarding 2020](https://www.nngroup.com/articles/mobile-app-onboarding/)
- Context-sensitive beats context-insensitive where tutorials help. Blocking/forcing steps didn't help — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- Interactive help ranked first and video a close second for controls learnability and motivation. Offering everything at once ("All Help") did not add value — [Kao 2020](https://people.csail.mit.edu/dkao/pdf/kao2020fdg.pdf)
- Guided, linear early play with tap-finger icons reduced confusion vs unguided opening play — [Supersonic 2025](https://supersonic.com/learn/blog/optimizing-ftue/)
- Provide a means of practising without failure — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)

### Inferences
Pros and cons (synthesis):
- **Looping demo in the start overlay**
  - Pros: zero extra taps. The player sees it while deciding to press Play. It is non-blocking (matches Andersen's "freedom" finding), cheap to build in-engine (a scripted mini-board using the real logic and renderer), and naturally replayable.
  - Cons: easy to ignore. It is small on a portrait phone if the overlay also holds difficulty/mode buttons. Space limits it to 1-2 verbs at a time, so cycle through steps with dots.
- **Full-screen carousel (tour)**
  - Pros: big, clear, fits the "beautiful how-to videos" ask, and works as a reference.
  - Cons: up-front and out of context, the weakest evidence-backed format. It adds a gate before play, and drop-off concentrates at the first transitions. Best kept as the "How to play" button target, not a forced first-launch gate. If shown at first launch, Skip must be prominent.
- **Ghost hand over the real board in the first match**
  - Pros: in context. Teaches at the moment of need. Learn-by-doing (strongest per Kao). Can verify the player did the gesture. Good for Stack Drop's multi-gesture set and the garbage rule (show it when the first row clears).
  - Cons: needs game-state hooks (pause or slow-time while hinting, or a gentle first-match CPU). Risks feeling patronising if it repeats, so show each hint only until performed once. Forcing a wait for the gesture (blocking) didn't help in Andersen, so prefer non-blocking hints with a slowed/gentle opening, or a short "practice" mode.
- **Practice-without-failure option:** a "Practice" toggle in which the CPU doesn't attack (Stack Drop) or crashes are forgiven (Serpent Grid) satisfies the accessibility guideline and gives a safe sandbox.
- **Video files vs in-engine:** pre-rendered MP4/WebM loops add APK size and need re-rendering per language, theme or visual change. In-engine demos stay pixel-consistent with the real board. Godot's VideoStreamPlayer supports Ogg Theora natively. That is general platform knowledge and not verified in this research.

### Gaps
- No A/B data comparing these three placements in a mobile game.
- No source measured the "patronising" penalty of ghost-hand hints for experienced players.

## 5. Accessibility and localisation: reduced motion, captions, contrast, audio-off play, readable text, icon-first design

### Takeaway
Instructions must not rely on text alone or sound alone. Animation should carry the meaning, with a short caption and an icon as backup. Respect the OS "Remove animations" setting with a static fallback (end-frame poster plus caption, essentially today's panel). Use ≥4.5:1 text contrast, scalable text, and ≥48 dp touch targets for Skip, Next and Replay. Keep text very short for localisation.

### Cited Findings
- "Ensure no essential information (especially instructions) is conveyed by text alone, reinforce with visuals and/or speech" (Intermediate). "Ensure no essential information is conveyed by sounds alone" (Basic). "Use simple clear language" (Basic). "Use an easily readable default font size" (Basic). "Provide high contrast between text/UI and background" (Basic). "Avoid flickering images and repetitive patterns" (Basic). "Provide an option to turn off / hide background movement" (Intermediate). "Avoid any sudden unexpected movement" (Advanced). "Ensure subtitles/captions are or can be turned on before any sound is played" (Intermediate). "Allow the font size to be adjusted" (Advanced) — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Xbox Accessibility Guidelines: XAG 101 text display, XAG 104 subtitles/captions (larger minimum default size for captions), XAG 117 visual distractions and motion (camera shake, parallax, motion-blur opt-outs). Version 3.2 is dated 2023-06-08 — [Xbox Accessibility Guidelines](https://learn.microsoft.com/en-us/gaming/accessibility/guidelines)
- Android: touch targets at least 48 × 48 dp. Text contrast at least 4.5:1 for text smaller than 18 pt (or bold smaller than 14 pt), and 3:1 for larger text. Use sp units for text so system font scaling works — [Android Developers: Make apps more accessible](https://developer.android.com/guide/topics/ui/accessibility/apps)
- An oft-cited "12 sp minimum" text size came from a third-party guide only. It is not verified in official Material docs — [BrowserStack guide](https://browserstack.wpengine.com/guide/android-accessibility-guidelines)
- Android's "Remove animations" accessibility toggle sets the animator duration scale to 0. Apps commonly read `Settings.Global.ANIMATOR_DURATION_SCALE` (default 1.0) and treat 0 as reduced motion. One report says the toggle didn't always register through a framework API, so test on device. Sources disagree on whether the toggle arrived in Android 9 or 13 — [Eevis Panula, DEV](https://dev.to/eevajonnapanula/android-animations-and-reduced-motion-2em2); [React Native issue](https://lightrun.com/answers/facebook-react-native-android-remove-animations-setting-isnt-reflected-when-using-accessibilityinfo)
- Web/game practice: read the OS reduced-motion preference, store it as the game's default motion setting, and let players override it in game settings — [Game accessibility search summary: abratabia](https://www.abratabia.com/game-accessibility/visual-accessibility.php)
- WCAG 2.2.2: auto-starting motion longer than 5 s, shown alongside other content, needs pause/stop/hide — [W3C](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html)

### Inferences
- **Reduced motion:** on "Remove animations" (or an in-game "Reduce motion" setting defaulting from the OS), show each step as a static key frame with motion arrows (like the existing icon panel). Alternatively play at ≤1 loop, without auto-advance, with no camera moves or screen flashes. The current static panel thus becomes the accessible fallback rather than being discarded. Godot doesn't expose this setting directly, so reading it would need a small Android plugin/JNI call. That is unverified here and should be checked.
- **Audio-off:** most mobile casual play is muted, so design demos to be fully understandable silent. SFX are optional reinforcement only, and there is no voice-over.
- **Captions/localisation:** 1-3 word, verb-first titles ("Swipe to turn"). Allow ~30-40% text expansion for languages like German (a general localisation rule of thumb, not sourced here). Avoid text baked into textures or video. Use the gesture icon plus animation as the primary carrier.
- **Contrast in demos:** draw the ghost hand with an outline or shadow so it reads on both light and dark board areas. Never use colour alone to distinguish the player from the CPU snake (also use shape or pattern).
- **Flicker:** avoid strobing highlights on row clears in demos (stay under 3 flashes/s, per WCAG 2.3.1 general knowledge, not fetched here).
- **Touch targets:** Skip / Next / Replay ≥48 dp, placed away from the gesture demo area so players don't accidentally skip when trying to mimic a swipe.

### Gaps
- Godot 4.7 APIs for reading the Android animator scale were not researched.
- No source gives a games-specific minimum text size for portrait phones. The Xbox 28 px @1080p figure surfaced only via a secondary blog and isn't mobile.

## 6. Common mistakes (text walls, unskippable tutorials, too many steps, etc.)

### Takeaway
The recurring failures are front-loading instruction out of context, offering no Skip, cramming many mechanics too fast, forcing scripted actions, adding hidden friction (loads) inside the tutorial, and piling on multiple help channels. Each has at least anecdotal or experimental support.

### Cited Findings
- **Up-front cards don't help:** no task-success gain, and they lower perceived ease — [NN/g 2020](https://www.nngroup.com/articles/mobile-tutorials/)
- **Using instruction to patch poor UX:** "Instructional onboarding should not be used to supplement poor design" — [NN/g onboarding 2020](https://www.nngroup.com/articles/mobile-app-onboarding/)
- **No skip:** the no-skip tutorial had a 40% pass rate vs 70-80% "optimal" — [Game Developer 2017](https://www.gamedeveloper.com/business/how-to-optimize-the-tutorial-for-your-game)
- **Hidden friction:** loading steps inside a 120-step tutorial drove quits, and fixing them gave +10% D1 — [Game Developer 2017](https://www.gamedeveloper.com/business/how-to-optimize-the-tutorial-for-your-game)
- **Too many mechanics too fast:** 60% tutorial churn in one case. Too long unguided is also bad — [Supersonic 2025](https://supersonic.com/learn/blog/optimizing-ftue/)
- **Forcing actions (blocking stencils):** no benefit, possibly resented — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- **Tutorials in simple games can backfire:** −3.5% return in Hello Worlds with context-sensitive tutorials. A help button cut Refraction play time 15% — [Andersen et al. 2012](https://grail.cs.washington.edu/wp-content/uploads/2015/08/andersen2012tio.pdf)
- **Everything-at-once help:** "All Help" didn't beat a single interactive or video format — [Kao 2020](https://people.csail.mit.edu/dkao/pdf/kao2020fdg.pdf)
- **Text-only instructions:** conveying instructions by text alone is an accessibility failure — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- **Not measuring:** instrument per-step funnels (pass, skip, quit), segment by device/version, and recheck after every update — [Game Developer 2017](https://www.gamedeveloper.com/business/how-to-optimize-the-tutorial-for-your-game); [devtodev FTUE metrics 2020](https://www.devtodev.com/resources/articles/main-metrics-ftue)

### Inferences
- Pocket Arena 8 is offline, with no analytics backend implied. Local, privacy-safe counters in SaveService (tour shown/skipped/completed, per-verb first-performed timestamps, first-match result) would let playtests on the test phone answer "did they learn the gesture?" without telemetry.
- Specific risks for these games: (a) Stack Drop's drag-steps-one-column-per-short-step behaviour is unconventional. If the demo doesn't show the step timing, players may think drag is broken, so the demo should visibly show discrete column steps. (b) The two-finger-tap HOLD shortcut is undiscoverable, so mention it as a secondary tip after the HOLD button, not as a primary step. (c) Serpent Grid's wrap edges contradict the classic genre expectation of deadly walls. That is the single rule most worth animating.
- Don't stack a tour, an overlay demo, ghost hands *and* a help button all in the first session. Per Kao, pick a primary channel (overlay demo + contextual first-match hints), with the full tour available on demand.

### Gaps
- No public data on how often players use a "How to play" replay button in casual mobile games (Andersen's 31% help-button usage is the closest proxy, from 2012 browser games).
