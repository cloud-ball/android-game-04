# What makes a mobile pool game feel polished and "premium": presentation, animation, camera, audio, haptics

Scope note: the reviews cited below cover named commercial games. They are evidence of what players and critics notice. All recommendations are generic mechanics and presentation techniques, not copies of any game's look, UI layout, art or music (per CLAUDE.md golden rules).

Codebase facts checked for this note (2026-11-13, branch `cue-club`):
- `core/AudioService.gd`: pool sounds are synthesized. `clack` = 18 ms of white noise through a strong one-pole low-pass (`lerpf(low, white, 0.25)`) with a squared decay. `cue` = 30 ms of the same noise. `pocket` = two sine-ish tones (196 Hz then 147 Hz). There are 8 round-robin voices at -6 dB. `buzz(ms)` calls `Input.vibrate_handheld(ms)` with no amplitude argument.
- `games/pool/scenes/pool_game.gd` `_sounds()`: BALL_HIT plays `clack` at random pitch 0.9 to 1.15 with constant volume. POCKET plays `pocket` and `buzz(15)`. **CUSHION events are logged by the sim but never sounded.** At most 3 sounds play per frame. The shot plays `cue` with pitch 0.8 + speed*0.04 and `buzz(8 + speed*1.5)`. A foul plays `crash` and `buzz(30)`.
- `shared/cue_sim/cue_sim.gd`: the event log stores triplets `(kind, a, b)` with no impact speed. That means there is currently no data to scale volume or haptics by how hard a collision was.
- `pool_game.gd:342` calls `randf_range()` directly for the clack pitch. This breaks the CLAUDE.md rule "Never call randf() directly". It only affects presentation, but it should go through a cosmetic `Rng` stream.

---

## 1. Shot feedback: strike animation, impact flashes, slow-motion, "nice shot" text, combos

### Takeaway
Critics single out short, rare, earned moments: slow motion on the winning or 8-ball shot, a visible cue strike with a chalk puff, and authentic contact sounds. They complain about feedback that fires on every shot or can't be skipped. For Cue Club, the biggest missing beat is the strike itself: the cue should visibly drive forward through the ball before the cue ball moves, rather than vanishing.

### Cited Findings
- A console pool game review (Switch, 2021) praises the end-of-game moment: the camera "zooms in on the winning hit of the game," and the cue strikes in slow motion "with chalk powder bursting into the air." — [Cubed3, Pure Pool (Switch) review, 21 May 2021](https://www.cubed3.com/review/6380/1/pure-pool-nintendo-switch.html)
- A 2026 review of a premium console pool game: "the slow-motion black shot makes me smile every time," and "I love how seamless the transition from cinematic to hands-on action is." — [MoviesGamesAndTech, Pure Pool Pro review, 12 Feb 2026](https://moviesgamesandtech.com/2026/02/12/review-pure-pool-pro)
- One review praised a slow-motion close-up on the final 8- or 9-ball shot but still wanted a true replay feature. — [WeGotThisCovered, Pure Pool review](https://wegotthiscovered.com/?p=368501) (search-snippet level; full page not fetched)
- Snooker app reviewers say "mandatory shot replays are also tiresome and just slow down gameplay." — [App Store, Snooker Stars listing/reviews](https://apps.apple.com/us/app/id1137235888) (search-snippet level)
- Another review: a "slow-motion camera that happens each time you take a shot can begin to get laborious after a while," though it "can be thankfully turned off in the game settings." — surfaced in search results for pool reviews; candidate sources [Thumbculture](https://www.thumbculture.co.uk/?p=10947) / [Cubed3 PS4](https://www.cubed3.com/games/reviews/playstation-4/pure-pool-3) (I did not verify which page the quote comes from; treat as indicative)
- A minimalist mobile pool game gets attention for a single squash-and-stretch cue: "The white ball elongates when you shoot it." The same writer found that slowing time while aiming made aiming harder ("Everything slows to a crawl as you drag to aim, making things a little harder than if time paused"). — [Adrian Hon, "Subpar Pool", Have You Played?, 28 Nov 2023](https://adrianhon.substack.com/p/subpar-pool)
- Game-feel ("juice") is defined as feedback that "doesn't actually change the game at all but makes it feel better… visual, auditory, or haptic." Developers report that juice animations "can get annoying in certain moments of the game when they trigger very often," and add skip/retry options for skilled players. — [itch.io dev discussion threads surfaced via search](https://itch.io/post/14894832); [Wayline, "hyper realism ruining game animation"](https://www.wayline.io/blog/hyper-realism-ruining-game-animation) (heavy animation "can make controls feel sluggish")
- Jan Willem Nijman (Vlambeer) gave "The Art of Screenshake" (INDIGO 2013), the reference talk on juice. Secondary write-ups note that strong shake works best when reserved for significant moments. A counter-talk (Folmer Kelly, GDC) argued that piling on juice can cost immersion. — [GameAnalytics juice article](https://gameanalytics.com/?p=3400); [Uni Bayreuth GxD-10 Game Feel slides (PDF)](https://medienwissenschaft.uni-bayreuth.de/wp-content/uploads/GxD-10-Game-Feel.pdf) (secondary sources; the talk itself was not fetched, and it predates the 2015 window)
- Accessibility guidance: "Avoid any sudden unexpected movement or events," and "Offer a means to bypass gameplay elements that aren't part of the core mechanic, via settings or in-game skip option." — [Game Accessibility Guidelines, full list](https://gameaccessibilityguidelines.com/full-list/)

### Inferences
- **Strike animation (high impact, low effort).** Replace "cue disappears on shot" with a roughly 60-100 ms forward stroke. Ease the cue from its pulled-back offset to about 1 cm past the contact point (ease-in, so it accelerates), then release the cue ball on the contact frame. Hold 1-2 frames, then ease the cue back and fade it out over about 150 ms. Stroke speed should scale with power so soft shots look soft. The sim can start on the same frame as contact. The animation is presentational only, so it adds latency only if you delay the sim (keep any delay under 80 ms, or have the sim start at contact).
- **Impact accent (low effort).** Add a tiny additive white flash or scale-pop at the cue-tip contact point, plus a chalk puff of about 6-10 pre-allocated particles in pale blue, only above about 60% power. Make the ball-ball contact flash very subtle or skip it. Real players read ball-ball contact from sound, not light.
- **Slow motion only on decisive pots (medium effort, high delight).** Use it for the game-winning 8-ball pot and maybe a break that pots 3 or more. Ramp `Engine.time_scale` or a render-time interpolation factor to about 0.3x over the last 0.4 s before the ball reaches the pocket, then snap back. Note the CLAUDE.md constraint: never scale physics by render delta. The safe way is to run the deterministic sim at its normal fixed rate, buffer states, and replay them slowly in the view. The sim already pre-computes shots via `predict`, so the view can render a slowed "replay" of known states. Make it skippable by tap and capped at about 1.5 s.
- **"Nice shot" text: sparing and tiered.** Show text only for genuinely notable events, such as a bank pot, a combination, 2 or more balls in one shot, a run of 3 or more consecutive pots, or clearing the group. Show it as small, fast (under 0.8 s) toast-style text near the pocket or table edge, not a full-width banner. The existing banners for fouls and groups are fine. Don't banner every pot.
- **Streak feedback.** A quiet visual run counter (e.g. pips beside the player name) plus a slightly rising pitch on the pocket sound per consecutive pot gives a sense of momentum without text. This is a common juice pattern. I found no pool-specific source for it.
- **Screen shake:** probably none for pool. Pool is a precision, calm game, and accessibility guidance warns against sudden movement. At most use a 1-2 px, 80 ms nudge on a very hard break.

### Gaps
- I found no published player study quantifying how often celebratory text becomes annoying in pool specifically. The evidence is review anecdotes.
- I couldn't fetch the original Vlambeer talk, and it predates 2015. The cited material is secondary.

---

## 2. Camera: stroke cam, aerial follow, pocket close-ups; motion sickness and skip

### Takeaway
Reviewers praise cinematic camera moves only when they are occasional (the final ball) and seamless. They complain when follow cameras lose the cue ball, focus on the wrong pocket on multi-ball shots, or force replays. Top-down 2D mobile pool is praised precisely because it "removes the need for any fiddly camera adjusting." For portrait touch play, Cue Club's fixed top-down camera is the right default. Add small, optional cinematic beats rather than a free 3D camera.

### Cited Findings
- A top-down presentation "removes the need for any fiddly camera adjusting," alongside a "very generous shot preview indicator." — [Pocket Gamer review (2008; outside window, included only as a long-standing baseline)](https://www.pocketgamer.com/midnight-pool-2/review/)
- A Switch pool review: "each pocketed ball offers a slow-motion replay and the camera follows each shot played; although this mechanic can quite often lose the path of the white ball." — surfaced via search for console pool reviews (exact page not verified; candidates [Thumbculture](https://www.thumbculture.co.uk/?p=10947), [Bonus Stage](https://www.bonusstage.co.uk/archives/122486))
- On PS4, one reviewer notes the camera will "just focus on the pocket the first ball" goes into when several balls are potted at once, rather than showing the whole shot. — [XtremePS3, Pure Pool PS4 review, 2014](https://www.xtremeps3.com/2014/07/31/pure-pool-ps4-review) (search snippet)
- A reviewer says the left stick controls "the camera behind the cue ball" (stroke/aim camera on console). — [Cubed3 2021](https://www.cubed3.com/review/6380/1/pure-pool-nintendo-switch.html)
- A mobile 3D billiards game's "aiming and camera controls are criticized for being slow and unresponsive." — [GameBrain, Billiards 3D: Moonshot 8 Ball](https://gamebrain.co/game/billiards-3d-moonshot-8-ball)
- Accessibility: "Avoid (or provide option to disable) any difference between controller movement and camera movement," "Provide an option to turn off / hide background movement," "If the game uses field of view… allow a means for it to be adjusted," and "Avoid any sudden unexpected movement or events." — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- "Seamless" transitions between cinematic and hands-on views are explicitly praised. — [MoviesGamesAndTech 2026](https://moviesgamesandtech.com/2026/02/12/review-pure-pool-pro)

### Inferences
- **Keep the fixed overhead camera as the play camera.** The portrait aspect fits a long table perfectly, and all touch aiming math stays 2D.
- **Optional low-cost camera beats, in priority order:**
  1. *Shot "breath":* during the shot, ease FOV in by about 3-5% toward the action centroid (or keep it fixed), and ease back when balls stop. Use critically damped smoothing with a time constant of about 0.25 s and never move during aiming. This is cheap and adds life with minimal sickness risk.
  2. *Decisive-pot close-up:* only for the game-winning 8-ball (and maybe the last ball of a group). Smoothly tilt and dolly to about 35-45° pitch toward the target pocket as the ball nears, combined with the slow motion from section 1, then cut or ease back. Tap to skip. A "Cinematic camera: On/Off" setting defaults to On for the final ball only.
  3. *Multi-ball pots:* if a close-up is used, frame the centroid of all balls that will drop, not the first one. This fixes a criticism seen in reviews. Because the sim is deterministic and pre-computable, the view knows the outcome ahead of time.
- **Avoid:** a camera that follows the cue ball every shot, mandatory replays, rotating the camera with the aim (in portrait this causes disorientation), and any roll.
- **Stroke camera (behind the cue ball at low height)** is the console convention for precise aiming. On a portrait phone it costs table overview, needs a second input mode, and reviewers flag slow camera controls. It's low priority, and if built at all it should be an optional "look along the cue" hold button.

### Gaps
- I found no mobile-specific motion-sickness data for pool cameras. The recommendations rest on general accessibility guidelines.
- I couldn't verify which reviews each search-snippet quote came from in two cases (marked above).

---

## 3. Ball/table visuals: reflections, specular, rolling, cloth, shadows, pockets, lighting, themes

### Takeaway
The most-repeated visual praise across pool reviews is light reflecting off glossy balls, lighting that "adds depth" and helps aiming, and balls that "roll and glide as if they were real." On a phone screen, readable ball numbers and colours matter more than environment detail. Cue Club's painted, unshaded approach can get most of the premium look by adding a convincing overhead-lamp reflection on the balls, contact shadows and pocket depth, without switching to real-time PBR lighting.

### Cited Findings
- "Lights reflectively bouncing off the balls" is part of the "beautiful" visuals, notable "for a title with a minimalist design"; the presentation is "crisp and clean." — [Cubed3 2021](https://www.cubed3.com/review/6380/1/pure-pool-nintendo-switch.html)
- "The lighting adds depth that makes lining up your shots much simpler"; "The balls roll and glide as if they were real"; screenshots show a pool hall under spotlights with tables in red, green and teal. — [MoviesGamesAndTech 2026](https://moviesgamesandtech.com/2026/02/12/review-pure-pool-pro)
- Reviewers of the earlier game in that series say the balls are "lovely and shiny reflecting the lighting of the room" and "the lighting engine manages to bring the table and its surrounding to life." — search snippets from [Entertainment Focus](https://entertainment-focus.com/?p=61059), [Softpedia](https://www.softpedia.com/reviews/games/pc/Pure-Pool-Review-453970.shtml)
- A 2D mobile pool game is praised for clear ball numbers: "clear, so you know exactly how many points you're going to get," plus "smooth and fluid" animations, "soothing" colours and customizable backgrounds (IAP). — [iMore, Pocket-Run Pool review, 25 May 2018](https://imore.com/pocket-run-pool-review-arcade-pool-makes-comeback)
- A minimalist mobile game uses "bleached-bright rasterised table graphics" that read as "very charming and distinctive". Polish does not require realism. — [Adrian Hon 2023](https://adrianhon.substack.com/p/subpar-pool)
- Some players felt patches made balls "feel a little lighter and less weighty". Perceived weight is a presentation-plus-physics property players notice. — [PlayStation Store listing, Pure Pool Pro](https://store.playstation.com/en-gb/concept/10013614) (user-review snippets)
- Godot 4.7 Mobile renderer: up to 8 ReflectionProbes per mesh. Docs recommend at most one `UPDATE_ALWAYS` probe per scene and `UPDATE_ONCE` otherwise, and note tile-based mobile GPUs and HDR bandwidth costs. — [Godot docs: Overview of renderers (4.7)](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html); [ReflectionProbe class](https://docs.godotengine.org/ko/4.x/classes/class_reflectionprobe.html)

### Inferences (prioritised for Cue Club's unshaded/painted pipeline)
1. **Lamp reflection on balls (high impact, low effort).** Replace or augment the single painted highlight with a *fixed in screen space* reflection of a rectangular overhead lamp: a soft rounded-rectangle highlight plus a faint secondary window-like strip. It must stay put while the ball's printed number rotates underneath. This is the cue that sells "glossy resin ball". Do it in the existing ball shader by sampling a tiny procedural "environment" from the view-space normal (a matcap-style lookup) rather than a ReflectionProbe. That keeps it unshaded and cheap on Mobile, and avoids HDR bandwidth.
2. **Contact shadow + soft blob (low effort).** Keep the blob shadow but add a tight, darker core directly under the ball (radius about 0.35R) so balls look seated on the cloth. Optionally offset the soft blob slightly away from the lamp position.
3. **Pocket depth (medium impact, low-medium effort).** Replace flat black discs with a radial gradient (dark edge to black centre) plus a thin leather/rubber liner ring on the near lip and a darker crescent where the rail overhangs. The existing 0.32 s sink should also darken and shrink the ball as it drops (it may already do so) and have the shadow disappear first.
4. **Rolling realism.** Printed numbers already roll with the ball, which matters most. Add slight motion stretch or a short fading trail only at very high speed (break shots) for 1-2 frames. Under about 1 m/s, nothing should smear. Physics interpolation is on, so make sure roll orientation is interpolated too, not just position, or fast balls stutter.
5. **Cloth.** A very low-contrast nap noise (1-2% luminance) and the existing radial lamp falloff are enough. Strong texture fights the aim line on small screens. A subtle worn path near the head-string or around pockets is a premium touch but low priority.
6. **Cushion definition.** A thin highlight line on the cushion nose and a darker inner shadow line helps players read bank angles. This is a legibility win rather than decoration.
7. **Table themes as unlocks (later).** Theme = cloth hue, rail wood/material, lamp colour temperature and ball set. These are all parameters in the existing shaders, so they're cheap to add and suit the hub/shop. Keep ball colours fixed per number for readability, and only vary their finish.
8. **Legibility rules for phones:** numbers on an upright, high-contrast label disc at rest (already done). Stripe balls need clearly white bands. Don't rely on colour alone to show the group (see section 6).

### Gaps
- I found no published measurement of which ball-rendering features most affect perceived quality on small screens. These are practitioner inferences.
- I have no Android benchmark numbers for a matcap vs ReflectionProbe ball shader on the Mobile renderer. Profile on the test phone.

---

## 4. Audio: what real pool sounds consist of; velocity-driven volume/pitch; ambience/music; samples vs synthesis

### Takeaway
In pool reviews, authentic ball-on-ball clack, cushion thud and pocket drop get more praise than any other single presentation element ("the best use of audio"). Cue Club's sounds are its weakest premium cue. Its clack is heavily low-passed noise (dull, not a crisp click), cushions are silent, and nothing scales with impact force. Recorded samples with velocity-mapped volume and filtering are the standard approach and are cheap.

### Cited Findings
- "The best use of audio is the sound of the balls as they hit each other, thud into the cushions and fall into the pockets." — search snippet from Pure Pool reviews ([Entertainment Focus](https://entertainment-focus.com/?p=61059) / [Softpedia](https://www.softpedia.com/reviews/games/pc/Pure-Pool-Review-453970.shtml)); the sound design "manages to deliver a bar-like experience."
- "The sound of the cue hitting the white ball and the noise of the balls gliding across the cloth were a joy to listen to." Note the rolling sound. — [MoviesGamesAndTech 2026](https://moviesgamesandtech.com/2026/02/12/review-pure-pool-pro)
- Mobile: effects are "fairly realistic, especially when two billiard balls clack together"; the verdict calls the audio "true-to-life"; music is "jazzy… a bit upbeat and quirky." — [iMore 2018](https://imore.com/pocket-run-pool-review-arcade-pool-makes-comeback)
- Ambience: "the murmurings in the background from the other patrons at the sports bar," with "funky jazz music that acts as a splendid and fitting underlay"; "low-fi beats" that don't distract from difficult shots. — [Cubed3 2021](https://www.cubed3.com/review/6380/1/pure-pool-nintendo-switch.html)
- A low-rated web pool game: "there's no music present, and the sound effects are barebones." — [Gamezebo, 8 Ball Multiplayer Pool review](https://www.gamezebo.com/reviews/8-ball-multiplayer-pool-review/)
- Physics of the click: ball-ball contact time is roughly 100-600 µs (Marlow), with Sorokin measuring 250-300 µs, and contact time shortens at higher speed. — [Dr. Dave Billiards FAQ, contact time](https://drdavepoolinfo.com/FAQ/ball/contact-time/). General acoustics: shorter, harder contact gives a brighter, higher-frequency sound. — [The Hardball Times, "The Crack of the Bat"](https://tht.fangraphs.com/the-crack-of-the-bat/) (baseball analogue)
- Commercial libraries split pool audio into categories: ball hits, break shots, pocket actions (including rattles), cue sticks, chalk, ball rolling, ball hitting table, racking. One pack was recorded at 24-bit/96 kHz with a stereo small-diaphragm pair. Libraries list soft and hard variants of pocket drops ("Ball comes in hard and falls into pocket", "Two balls slight rattle"). — [A Sound Effect, Vadi billiards pack](https://www.asoundeffect.com/?p=685740); [Shockwave-Sound LYN070](https://shockwave-sound.com/sound-effects/4986/lyn070-pool-sounds-set-1-pool-snooker-billiards) (61 sounds) and [LYN071](https://shockwave-sound.com/sound-effects/5053/lyn071-pool-sounds-set-2-pool-snooker-billiards) (76); [Unity Asset Store billiard SFX (100 sounds, $19.99)](https://assetstore.unity.com/packages/audio/sound-fx/foley/billiard-sound-effects-220821); [Gravity Sound billiard pack, itch.io ($9.99)](https://gravity-sound.itch.io/billiard-sound-effects); [Media Music Now pool category](https://mediamusicnow.co.uk/royalty-free-sound-effects/sports-games/billiards-pool-snooker/7)
- Anti-repetition practice: 3-5 (or 4-8) variations for frequently repeated sounds, round-robin or random-without-repeat selection, and small random pitch (about ±2 semitones max) and volume (about ±1.5 dB) offsets. One case study made "impact sounds change compared to the speed of the ball." — [CRIWARE AtomCraft randomization](https://blog.criware.com/index.php/2017/01/16/atomcrafts-randomization-features/); [Game Developer, "Sounds in Roundrick"](https://gamedeveloper.com/audio/sounds-in-roundrick); [A Sound Effect, procedural game sound design](https://www.asoundeffect.com/procedural-game-sound-design) (rules of thumb, not standards)

### Inferences (concrete for Cue Club)
1. **Log impact speed (prerequisite, low effort, must keep determinism).** Extend `CueSim._log` to carry a quantized relative normal speed (e.g. an int in mm/s) for BALL_HIT and CUSHION, as a 4th field or by packing into `b`. Add a unit test. This only appends ints to an existing PackedArray, so no new per-frame allocation.
2. **Map speed to sound (high impact, low effort).** Volume ≈ `linear_to_db(clamp(v/v_max, 0.05, 1)^0.6)`, which gives a soft compressive curve. Raise brightness and pitch slightly with speed (e.g. pitch 0.95 to 1.08), since faster impacts have shorter contact and sound brighter. Drop very soft taps under about -30 dB instead of playing them at full level, because uniform-volume clicks are a classic "cheap" tell.
3. **Sound the cushions.** CUSHION events are already logged. Use a low, short thud (about 80-200 Hz body, 40-80 ms) with volume by speed. This is a near-zero-cost gap fix.
4. **Fix the clack timbre.** A real click is a very short, bright transient with a tonal ring, not dull low-passed noise. If staying synthesized, use a 1-3 ms broadband transient plus 2-3 damped sine partials in roughly the 2-6 kHz range that decay in about 15-40 ms, with slight per-hit partial detune. This is a design estimate. I found no published spectrum, so tune by ear against a recording. **Recommended instead:** license a small CC0 or royalty-free sample set (4-6 ball-ball, 3 cushion, 3 pocket-drop variants including a rattle, 2-3 cue-tip, 1 break, optional rolling loop). Total under 300 KB as OGG. Samples beat synthesis for "premium" here, and the cost is low. Record licences in ASSETS.md per the asset-wrangler workflow.
5. **Pocket sound = drop + travel.** A soft "thock" on entry, then (optionally) a delayed muted roll down a return channel 0.3-0.8 s later. The current two-note sine "pocket" reads as a UI jingle, not a physical event. Keep a separate subtle UI chime only for a group being decided or a streak, if wanted.
6. **Rolling sound (medium effort).** Add one looping low-level cloth-roll noise whose volume tracks the sum of ball speeds, smoothed. Reviewers explicitly praised this sound. Use one shared player with no per-frame allocation, and only set `volume_db`.
7. **Polyphony on the break.** Rate-limiting to 3 sounds per frame is right. Prioritise the loudest impacts first, which needs the speed field, so the break sounds like a crack plus scatter rather than three random clicks.
8. **Cue strike** should be layered: a dull tip "tock" (leather tip and phenolic ball), then the ball-ball click if a break, with volume by power. Sync it to the strike animation's contact frame, not to button release.
9. **Ambience/music.** Reviews favour unobtrusive lounge/jazz/lo-fi underlay and quiet room tone that never competes with contact sounds. Duck music by about 3-6 dB during shots, and make music and SFX separate toggles (settings already split music and sound). Use original music only.
10. **Determinism rule:** replace `randf_range` in `_sounds()` with a cosmetic `Rng` instance (separate from the sim stream) to comply with CLAUDE.md.

### Gaps
- **I found no published frequency spectrum for billiard ball-ball impacts.** The 2-6 kHz partials figure above is a design estimate, not a cited fact. A JASA search or a home recording plus FFT would settle it.
- I found no source on how mobile pool games specifically scale volume by impact velocity. The practice is inferred from general game-audio sources and the Roundrick case study.

---

## 5. Haptics on Android for pool events

### Takeaway
Android's own guidance favours a few short, crisp, rich haptics tied to important events, synced with sound. It warns against "buzzy" long vibrations, says no haptics is better than buzzy ones, and calls for a toggle. Cue Club's `Input.vibrate_handheld(ms)` maps to the legacy one-shot vibrator API, which Android explicitly says to avoid for feedback. Durations should be about 10-20 ms with amplitude control, and frequent events like ball-ball clicks should get no haptics.

### Cited Findings
- "When it comes to haptic feedback on mobile devices, less is more. Too much vibration can be annoying and even numbing… may lead the user to quickly turn off all haptics." — [Android Developers, Haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- "Given the choice of buzzy haptics or no haptics for touch feedback, choose no haptics." — [same](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- "Correlate event importance and frequency with strength": very frequent events should be "very subtle"; you can create effects that "become stronger as the interaction reaches a target, for example gradually increasing the amplitude of a sequence of ticks with dragging." — [same](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- "We strongly recommend co-design of visual, audio, and haptic effects… a haptic feedback that is played out of sync… can be a bit unsettling… the user may perceive the haptic actuator to be broken." — [same](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- "Avoid legacy one-shot vibrations" (`createOneShot`, `Vibrator.vibrate(long)`). "A good keyclick haptic feedback signal should last between 10 to 20 milliseconds," and the actuator "may continue to ring for another 20 to 50 milliseconds." — [same](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- Composition primitives and target durations: CLICK (strong, crisp, about 12 ms), TICK (sharp, about 5 ms), LOW_TICK (softer, more body, about 12 ms), THUD ("knocking on hollow wood", about 300 ms), SPIN (150 ms), QUICK_RISE (150 ms), SLOW_RISE (500 ms), QUICK_FALL (100 ms). Primitives are scalable via `addPrimitive(id, scale, delay)`, and device support must be checked. — [AOSP, Implement constants and primitives](https://source.android.com/docs/core/interaction/haptics/haptics-constants-primitives); [Android Developers, Haptics APIs](https://developer.android.com/develop/ui/views/haptics/haptics-apis)
- Godot 4.x: `Input.vibrate_handheld(duration_ms := 500, amplitude := -1.0)`. On Android the amplitude is mapped to 1-255 via `CLAMP(int(amplitude*255),1,255)`, and the VIBRATE permission must be enabled in the export preset. Godot exposes no Composition primitives. — [Godot 4.7 Input class docs](https://docs.godotengine.org/en/4.7/classes/class_input.html); [Godot commit adding amplitude](https://remotebranch.eu/Stowage/godot/commit/789c6ebdfd72ec9141e04ef162471983e7fdee94)
- "Include toggle/slider for any haptics." — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)

### Inferences (Cue Club haptic map)
| Event | Now | Recommended (vibrate_handheld) | Ideal (Android plugin, primitives) |
|---|---|---|---|
| Ball-ball contacts | none | none (too frequent) | none |
| Cue strike | 8 + speed*1.5 ms, no amplitude | 12-18 ms, amplitude 0.3-1.0 by power, on the strike-animation contact frame | CLICK scaled by power |
| Pot (own ball) | 15 ms | 15 ms, amplitude 0.5 | LOW_TICK or CLICK at 0.6 |
| Cushion | none | none (or only very hard banks) | TICK at 0.2-0.4 |
| Foul | 30 ms | 25 ms at 0.6, or two 12 ms pulses 60 ms apart ("reject") | REJECT constant / QUICK_FALL |
| Win | none | three short pulses rising in amplitude | QUICK_RISE then CLICK |
| Power drag | none | none (too frequent with legacy API) | TICK every 10% of power, scale rising with power |
- Pass the `amplitude` argument everywhere (`AudioService.buzz(ms, amp)`). On devices without amplitude control it falls back gracefully. **Unverified:** whether Godot ignores amplitude cleanly on such devices. Test on the test phone.
- A small Android plugin (Kotlin, `VibrationEffect.Composition`, guarded by `areAllPrimitivesSupported`) is the route to genuinely "rich" haptics like the power-drag tick ramp. Medium effort, best done once at the core/ level for all games.
- Keep haptics in sync with audio and animation. Trigger them from the same contact event, not on touch release.

### Gaps
- I found no pool-game-specific review discussing haptics (one search result claimed a mobile pool game was credited for haptics, but the fetched article did not mention them).
- I didn't confirm Godot 4.7's Android implementation path (whether it calls `createOneShot` with amplitude). The commit snippet suggests it does.

---

## 6. UI polish: turn indicators, shot timers, potted-ball trays, end-of-rack summaries

### Takeaway
The cited sources say little about turn and tray UI. Reviews praise clear, generous aim guides that can be reduced or turned off, and readable numbers, and they criticise aim that shifts on finger lift. The well-established conventions (a remaining or potted-ball tray per player, a clear active-player highlight, an optional shot clock, quick restart) are table stakes. Their polish comes from animation timing and colour-independent coding.

### Cited Findings
- "Although the entry-level settings offer you a guide, this can be removed if you want a harder challenge," and "a reduction in visual aids make you better at the game." — [MoviesGamesAndTech 2026](https://moviesgamesandtech.com/2026/02/12/review-pure-pool-pro)
- On-screen guides make aiming easier "especially for newcomers," and touch controls are "quite easy to learn." — [Cubed3 2021](https://www.cubed3.com/review/6380/1/pure-pool-nintendo-switch.html)
- A con: the aim trajectory "can move slightly once you lift your finger, making hard shots even harder." Pros: a "non-intrusive text tutorial" and a dotted circle showing where the cue ball lands. — [iMore 2018](https://imore.com/pocket-run-pool-review-arcade-pool-makes-comeback)
- Aim "locked on" to the original target is praised, and full trajectory guides can make pool "too boring and predictable." — [Adrian Hon 2023](https://adrianhon.substack.com/p/subpar-pool)
- A low-rated game's ads obscure the content, and its physics "can feel kind of awkward". Clutter undermines perceived quality. — [148Apps, Infinite Pool review](https://www.148apps.com/reviews/infinite-pool-review)
- "Ensure no essential information is conveyed by a fixed colour alone"; "Provide captions or visuals for significant background sounds." — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Players want a skip option and instant replay. Mandatory replays are disliked. — [App Store Snooker Stars reviews (snippet)](https://apps.apple.com/us/app/id1137235888); [WeGotThisCovered](https://wegotthiscovered.com/?p=368501)

### Inferences
- **Turn indicator:** a player chip at the top with an avatar, a name and their group shown as *mini ball icons with stripe/solid shape*, not colour alone. The active side gets a glow plus a gentle 1.0 to 1.04 scale pulse when the turn changes (200 ms). Flash "Your turn" only when the turn passes to the human after a CPU visit.
- **Remaining-ball tray:** show each player's 7 group balls as small numbered icons. When a ball is potted, animate its icon (or a flying copy from the pocket position) into a "potted" state over about 300 ms (dimming or checkmark), synced with the pocket sound. This gives a satisfying, at-a-glance payoff for every pot. Pre-allocate the icons. Show an 8-ball slot that lights when the group is cleared.
- **Shot timer:** casual vs CPU play doesn't need one. If added later for online play, use a thin ring around the active player's chip that changes colour only in the last 5 s, with a soft tick sound and no haptics until the final 3 s.
- **Aim stability:** freeze the aim on touch-up (the cited con). Cue Club's point-to-aim plus snap should be checked for jitter on finger lift, for example by using the aim from 1-2 frames before release if finger velocity spikes.
- **Ball-in-hand:** show a hand or ghost cursor and a valid-placement highlight, plus a soft "lift and settle" animation on placement (scale up 5% while held, drop with a small shadow-tighten on release).
- **End-of-rack summary:** after the win/lose banner, show a compact card with shots taken, pot %, longest run, fouls, best shot (e.g. a bank or a multi-pot), and Rematch/Hub buttons. Count numbers up over about 0.5 s and allow an instant tap-through. A "replay winning shot" button can reuse the deterministic sim and the slow-mo view (section 1).
- **Banners:** keep the existing foul/group banners but make them non-blocking, under 1.2 s, and tappable to dismiss. Give foul text a short reason ("Cue ball potted"), which already exists.

### Gaps
- None of the fetched reviews describe potted-ball trays, turn indicators or end-of-rack screens in detail. The recommendations above are standard genre conventions inferred from general practice, not cited evidence.

---

## Priority summary (impact vs effort) for Cue Club

These are inferences drawn from the sections above. Effort is a rough estimate for this codebase.

| # | Change | Impact | Effort | Where |
|---|---|---|---|---|
| 1 | Log impact speed in the CueSim event log; drive SFX volume/pitch and haptic amplitude from it | High | Low | shared/cue_sim/cue_sim.gd, pool_game.gd `_sounds()` (+ unit test) |
| 2 | Cushion thud sound (events already logged) | High | Very low | pool_game.gd `_sounds()`, AudioService |
| 3 | Replace synthesized clack/pocket with a small licensed sample set (variations + round-robin) or a better transient-plus-partials synth | High | Low-Med | core/AudioService.gd, ASSETS.md |
| 4 | Cue strike animation (forward stroke, contact frame, tip flash/chalk puff above 60% power), with sound and haptic on the contact frame | High | Low | pool_view.gd |
| 5 | Lamp-shaped screen-space reflection on balls + contact shadow core + pocket liner/depth gradient | High | Low-Med | ball shader, table shader in pool_view.gd |
| 6 | Potted-ball tray with fly-in animation and colour-independent group icons | Med-High | Med | pool_hud.gd |
| 7 | Haptics: pass amplitude, 10-20 ms, none on ball-ball, a "reject" pattern for fouls; later an Android plugin for primitives | Med | Low (plugin: Med) | core/AudioService.gd |
| 8 | Slow-motion and pocket close-up on the decisive 8-ball pot only, tap-to-skip, settings toggle (render-side replay of deterministic states; never scale physics by delta) | Med-High (delight) | Med | pool_view.gd, pool_game.gd |
| 9 | Rolling cloth loop tied to total ball speed; music ducking during shots | Med | Low | AudioService, pool_game.gd |
| 10 | End-of-rack summary card with replay-winning-shot | Med | Med | pool_hud.gd |
| 11 | Sparing "nice shot" toasts (bank, combo, multi-pot, run of 3 or more) + streak pitch rise | Med | Low | pool_game.gd, pool_hud.gd |
| 12 | Table themes (cloth/rail/lamp/ball finish params) for the shop | Med (retention) | Med | shaders + hub/shop |
| 13 | Replace `randf_range` in `_sounds()` with a cosmetic Rng stream | Compliance | Very low | pool_game.gd:342 |
