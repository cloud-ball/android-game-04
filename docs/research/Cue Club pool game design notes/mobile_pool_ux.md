# Mobile pool UX conventions: touch controls, camera and readability on a portrait phone

Scope note: this covers generic genre conventions, ergonomics and platform/accessibility guidance for an original 8-ball vs CPU game ("Cue Club") on a portrait Android phone (test phone 1260x2800 px, 420 dp wide, 1080-wide canvas). Commercial titles appear only as citations showing that a convention exists. Nothing here recommends copying any title's look, layout, name or art. Public sources on this topic are thin: most are help pages, reviews and forum posts, not UX research. Many numeric parameters (degrees per dp, power curves, snap radii) are **not published anywhere I could find**. Those are listed under Gaps, with inferred starting values marked as inferences.

Device arithmetic used below (derived, not cited): 1 dp = 1/160 in. The test phone's 420 dp width is about 2.63 in (66.7 mm) of glass, at 3 px per dp. The 1080 canvas maps to 420 dp, so 1 canvas px is about 0.39 dp.

## Aiming: input model, sensitivity, fine aim, snapping, finger occlusion

### Takeaway
Two conventions dominate:
- **Coarse aim:** drag on the table to rotate the cue around the cue ball. Some titles instead drag the cue itself, or tap a point to aim at it.
- **Fine aim:** a separate high-resolution control, such as an on-screen wheel or slider, small-step buttons, or a "touch-and-hold, then drag" fine mode.

The best-documented failure is the aim being nudged when the finger lifts off. That makes a dedicated fine control and some form of lift-off protection the core requirements.

### Cited Findings
- A leading mobile 8-ball title's help centre says the mobile controls are "tap and drag the cue" or an "Aiming Wheel for more precision", with options under control settings. This confirms the coarse drag plus fine wheel convention. — [Miniclip support (via search snippet; page returned 403 to direct fetch)](https://support.miniclip.com/hc/en-us/articles/35451942766865-Basic-Controls-Improving-your-skills-8-Ball-Pool)
- A cross-platform 3D billiards game's touch help lists these controls: "Touch the screen and drag right/left to aim". "Touch and hold for a second then drag left/right to enable fine aim mode". "Drag starting on the cue ball to set spin". "Drag up/down starting on the cue to set shot power". Shots can also be fired by "quickly dragging the cue upward". This is a second convention: a hold-to-enter fine mode, plus gestures that depend on where the drag starts. — [FlyOrDie 3D Billiards help](https://www.flyordie.com/games/help/billiard/en/contents.html)
- A review of a top-down mobile pool game reports a lift-off problem. Its scheme of "tapping and dragging on the screen to line up your shot" "plays fairly well", but "you sometimes nudge the aiming line" when lifting the finger after lining up a shot. Soft buttons "letting you adjust the aim in small increments" correct this. (Review date not shown on the fetched page and possibly older than 2016.) — [Pocket Gamer review "Pool"](https://www.pocketgamer.com/pool/review/)
- One game's settings expose "power flick and touch sensitivity options" so players can tune the feel. — [search summary of mobile pool control pages](https://www.pocketgamer.com/wst-snooker-mobile/wst-snooker-mobile-tips-to-play-like-a-professional/) *(snippet-level; not verified on the page)*
- A general touch-controls design guide advises keeping the controlled object offset from the finger so it stays visible. — [Cursa: Touch Controls for Mobile Games](https://cursa.app/en/page/touch-controls-for-mobile-games-input-patterns-and-feedback) *(snippet-level)*
- A player describes touching *elsewhere* on the screen to adjust the aim line so the thumb doesn't hide the pocket. — [TouchArcade forum thread](https://toucharcade.com/community/threads/419969) *(snippet-level, anecdotal)*
- **Touch precision research:**
  - Users aim with visual features on the **top** of the finger, while sensors register the centre of the contact area. This parallax produces systematic offsets.
  - The traditional contact-area model has about **4 mm** error offset. A "projected centre" model has about **1.6 mm**.
  - Per-user corrections cut error by up to 60%.
  — [Holz & Baudisch, "Understanding Touch" (CHI 2011), project page](https://siplab.org/projects/Understanding_Touch)
- Holz & Baudisch (CHI 2010) found that their generalized perceived-input-point model explained 67% of the inaccuracy previously blamed on the "fat finger". A secondary summary cites 4.9 mm minimum button size for reliable input with projected-centre models. — [Understanding Touch summary page](https://christianholz.net/understanding_touch.html) / [Holz & Baudisch PDF mirror](https://datatalkturk.ifi.uzh.ch/papers/annotate/c6d707439b94974a5623cabb200767917297ae56.pdf) *(4.9 mm figure is snippet-level)*
- Vogel & Baudisch ("Shift", CHI 2007) attribute touch errors mainly to **occlusion** of the target by the finger and ambiguity about which part of the finger is the selection point. That work motivated offset callouts and indirect manipulation. — [Vogel & Baudisch CHI 2007 PDF](https://projects.csail.mit.edu/hci-reading/papers/chi2007-vogel.pdf) *(pre-2016, foundational)*
- Hoober's field data: touch accuracy varies from about **7 mm at screen centre** to about **11 mm at the top** and **12 mm at the bottom** (some summaries say 12 mm at corners). The top and bottom edges are much worse than the sides because of reach and lift-off. — [Smashing Magazine, Accessible Target Sizes Cheatsheet (2023)](https://smashingmagazine.com/2023/04/accessible-tap-target-sizes-rage-taps-clicks/); [UXmatters, Design for Fingers, Touch and People Pt 3 (2017)](https://www.uxmatters.com/mt/archives/2017/07/design-for-fingers-touch-and-people-part-3.php)
- Game Accessibility Guidelines items that apply here:
  - "Include an option to adjust the sensitivity of controls" (Motor, Basic).
  - "Make interactive elements that require accuracy … stationary" (Motor, Intermediate).
  - "Avoid / provide alternatives to requiring buttons to be held down" (Motor, Intermediate).
  This argues for a tap-step fine-aim alternative to a held hold-to-fine mode.
  — [Game Accessibility Guidelines, full list](https://gameaccessibilityguidelines.com/full-list/)

### Inferences
- **Rotation drag, not drag-the-cue.** The current plan (drag anywhere to rotate, plus a fine slider on the right edge) matches the dominant convention. Because the touch can be "anywhere", the thumb never has to cover the cue ball or target.
  - Map drag to rotation using the **angle swept around the cue ball's screen position** (angular drag), not raw horizontal delta. A finger far from the cue ball then gives finer control "for free", like a longer lever.
  - Optionally also apply a constant gain for drags near the cue ball.
- **Sensitivity starting points (inference, no published values found):**
  - Coarse aim: the angular-drag method gives 1:1 tracking (the cue points at the finger's bearing).
  - Fine slider: about **0.02–0.05° of cue rotation per dp** of slider travel.
  - A 300 dp slider stroke would then cover 6–15°. At 0.03°/dp, 1 dp is 0.03°, which is about 1.3 mm of ghost-ball displacement at 2.5 m shot distance. That is finer than the solver's meaningful precision, so useful.
  - Expose a sensitivity setting, per the accessibility guidelines.
- **Lift-off nudge mitigation:**
  - Ignore the last ~50–80 ms of motion before touch-up.
  - Or freeze aim when finger speed drops below a threshold for ~100 ms.
  - The fine slider then corrects any residual error. This directly targets the failure the review reports.
- **Fine slider placement.** The right edge suits right-handed thumb reach. Edge targets need ~11–12 mm (about 70–75 dp) of effective size per Hoober, so the slider's hit strip should be at least 72 dp wide even if drawn thinner. Add a left-handed mirror option.
- **Snapping/magnetism.** Not documented in public sources. A mild "sticky" zone on exact ghost-ball lines could act as an easy-mode assist, only for the centre-pocket line of the nearest legal ball, with roughly a 0.5° capture radius. Keep it off in harder modes so skill isn't removed.
- **Tap-to-aim** (tap a ball or point and the cue aims there) is a useful *coarse* accelerator. It suffers the 4–7 mm touch error (about 10–18 dp), so treat it as "aim near here, then fine-tune", not final aim.

### Gaps
- No published numeric aim-sensitivity values (°/dp) or fine-wheel resolutions for any mobile pool game were found. Help pages describe controls only qualitatively.
- No source on aim magnetism or snapping in pool games was found.
- The primary support page for the largest mobile 8-ball title returned 403, so its details are known only from search snippets.

## Guidelines: ghost ball, aim line length, object-ball path, cue-ball deflection

### Takeaway
The ghost ball is the standard real-world aiming concept, and on-screen guides visualise it: a cue-ball path, a ghost circle at contact, a short object-ball direction line and a cue-ball deflection line. Guideline length as a difficulty lever is a widely assumed genre convention, but I found no primary source documenting specific lengths. Accessibility guidance favours making long guides an available assist rather than removing them.

### Cited Findings
- The ghost ball is "the imaginary place the CB needs to be at OB contact to send the OB to the pocket". The cue ball is aimed at the ghost ball's centre, which sits against the object ball on the side away from the pocket. — [Dr. Dave aiming terminology](https://drdavepoolinfo.com/?p=537); [Billiards Digest Aug 2021 (Alciatore)](https://billiards.colostate.edu:443/bd_articles/2021/aug21.pdf)
- A legitimate training app markets a "ghost-ball visualizer". Third-party "long line" hacks that extend in-game guidelines are widespread, which shows players value guideline length highly. — [WPB: Pool Training & Drills (App Store)](https://apps.apple.com/app/id1591274006); [search results summary noting guideline-extension hacks](https://filehippo.com/android/download_pool-guideline-tool/) *(existence only)*
- A top-down mobile pool game exposes a setting for "whether your aiming direction line is on". This shows the guideline as a toggleable option. — [Pocket Gamer review "Pool"](https://www.pocketgamer.com/pool/review/)
- Game Accessibility Guidelines: "Ensure controls are as simple as possible, or provide a simpler alternative" (Motor, Basic), and "Include an option to adjust the game speed" (Basic). Assists are the guideline-sanctioned way to widen access. — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Cut-shot physics: with no spin, after a stun or sliding hit the cue ball leaves the collision at about 90° to the object-ball line (the 90° rule). A rolling cue ball deflects at about 30° for a range of cut angles (the 30° rule). These fix where a "cue-ball deflection line" should point. — [Dr. Dave aiming/terminology resources](https://drdavepoolinfo.com/?p=537) *(rules widely documented by Alciatore; I did not fetch the specific 90°/30° rule pages this session, so verify against his "90° rule" and "30° rule" pages before relying on the 30° value)*

### Inferences
- **Guideline set (inference):**
  1. Dotted cue-ball path from the cue ball to the first contact (or first cushion).
  2. Ghost-ball outline at contact.
  3. Object-ball direction ray from the contact normal.
  4. Short cue-ball deflection ray, about 90° to the object-ball ray for stun/no spin.
  Showing the spin-adjusted deflection (curving toward follow or draw) reveals position play. Make it an easy-mode feature or hide it on Hard.
- **Length by difficulty.** I found no cited numbers. Suggested starting values (inference, tune in playtests):
  - **Easy:** full cue path to contact plus a long object-ball ray (to the pocket or cushion) plus the cue-ball deflection ray. Optionally one cushion bounce.
  - **Medium:** cue path to contact, object-ball ray about 1/4 table width, deflection ray short.
  - **Hard:** cue path to contact plus ghost ball only, object-ball ray very short (about 2 ball diameters).
  - Keep "Long guidelines" as an accessibility toggle independent of CPU difficulty, so low-vision or low-dexterity players aren't locked out.
- **Don't encode trajectory solely by colour.** Use dash patterns and widths (for example, solid for the cue-ball path, dashed for the object-ball path), per the colour-alone guideline below.
- The ghost ball is the most important single guide in the genre and the touch-precision bottleneck. Make it at least 1 ball diameter (about 14–16 dp on screen) with a 1.5–2 dp outline that contrasts with the cloth at 3:1 or better (see Readability).

### Gaps
- No primary source documents how commercial mobile pool titles vary guideline length by league or mode. The common belief that guidelines shrink at higher tiers could not be verified (search returned only hack pages).
- No study on how guideline length affects pot rate or enjoyment was found.

## Power control: bar orientation, gestures, curve, cancel, max speeds

### Takeaway
Power is almost always a dedicated vertical bar or pull-back gesture at the side of the screen, released to shoot. Cancelling by returning to zero is the convention. Physical shot speeds range from about 0.5 m/s (soft) to about 3 m/s (fast). Breaks reach 11–13 m/s, with about 16 m/s as an extreme. That spread argues for a non-linear (eased) power curve so the soft range gets most of the bar's travel.

### Cited Findings
- Power set by "sliding back on a power-bar at the side of the screen". — [Pocket Gamer review "Pool"](https://www.pocketgamer.com/pool/review/)
- Alternative convention: "Drag up/down starting on the cue to set shot power". Power depends on how far the cue is drawn back, and shots can be fired by "quickly dragging the cue upward". — [FlyOrDie 3D Billiards help](https://www.flyordie.com/games/help/billiard/en/contents.html)
- Typical cue-ball speeds (Alciatore FAQ):
  - Slow: 1–2 mph (0.45–0.89 m/s)
  - Medium: 2–4 mph (0.89–1.9 m/s)
  - Fast: 4–7 mph (1.9–3.2 m/s)
  - Powerful break: 25–30 mph (11–13 m/s)
  - "Ridiculously powerful" break: about 35 mph (16 m/s)
  — [Dr. Dave FAQ: typical speeds](https://drdavepoolinfo.com/faq/speed/typical/)
- Alciatore's break-force proof uses about 30 mph as a "very fast" break. Video of 1986–87 tournaments measured pro breaks at 22–26 mph (average 24). — [Dr. Dave TP B-20](https://billiards.colostate.edu:443/technical_proofs/new/TP_B-20.pdf); [article attached in AZBilliards thread](https://forums.azbilliards.com/attachments/cue-speed-about-25mph-pdf.768252/) *(author unidentified)*
- Game Accessibility Guidelines: "Do not make precise timing essential to gameplay – offer alternatives" (Advanced). A held-and-release bar with no oscillation meets this; an auto-oscillating "timing" meter would not. — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Generic tip pages advise players to "fine tune power to avoid overshooting". This shows soft-shot control is a recognised skill axis. — [Pocket Gamer WST Snooker tips](https://www.pocketgamer.com/articles/083736/wst-snooker-mobile-tips-to-play-like-a-professional)

### Inferences
- **Max speed:**
  - Map 100% power on normal shots to about **7–8 m/s**, above "fast" (3.2 m/s) but below a power break.
  - Allow the break to reach about 11–12 m/s, either through a break-specific cap or the same curve's top end.
  - A max of about 16 m/s would put about 80% of useful shots in the bottom 20% of a linear bar.
- **Curve (inference).** Use an eased mapping like `v = vmax * p^γ` with γ ≈ 1.6–2.0.
  - With vmax = 8 m/s and γ = 2, a medium 1.5 m/s shot sits at about 43% of the bar instead of 19%.
  - Show the numeric percent or a speed tick beside the bar so the non-linearity is learnable.
- **Bar geometry.**
  - The test phone is about 933 dp tall, and the table area takes much of it. A **vertical bar about 280–360 dp long** gives roughly 1% power per 3–3.6 dp, about 2–2.4× the 7 mm (about 44 dp) centre touch error spread over 1% steps. That is adequate. Longer is better.
  - Draw it on the edge opposite the fine-aim slider, or share the right edge with a clear gap of at least 8 dp (Material spacing).
  - Make the bar's touch strip at least 48 dp wide, and 72 dp at the screen edge (see target sizes below).
- **Pull-back semantics.**
  - Pull **down**, away from the shot, to load power. Release fires.
  - Dragging back above the start point, or to under about 2%, cancels with no shot (a standard "return to zero to cancel").
  - Show a visible cancel affordance (for example, the bar empties and an "x" appears).
  - Lock aim while the power drag is active, so an off-axis power drag can't rotate the cue.
- **Lift-off.** Fire on release, but use the power value from about 50 ms before release so release jitter can't add or remove power.

### Gaps
- No published power-curve shapes or bar lengths from commercial mobile pool games were found.
- No HCI study of drag-to-power precision on phones was found.

## Spin (english): cue-ball inset, dot range, effect preview, presets

### Takeaway
Spin is conventionally a separate control: a cue-ball inset with a draggable tip-contact dot, or a drag that starts on the cue ball. Physics and the project's own rules clamp the offset to about 0.5 R. Spin is a valued feature: a review called its absence "far more disappointing" than other flaws.

### Cited Findings
- "Drag starting on the cue ball to set spin". Spin (top or bottom), cue elevation and zoom can also be set by dragging up/down on dedicated control icons. — [FlyOrDie 3D Billiards help](https://www.flyordie.com/games/help/billiard/en/contents.html)
- A reviewer called the "lack of an option to add spin to your shots" "far more disappointing", something "you'd think would be essential". — [Pocket Gamer review "Pool"](https://www.pocketgamer.com/pool/review/)
- Project physics note: clamp the cue tip offset to 0.5 R to avoid miscues. — local file `docs/games/pool.md` (project design doc)

### Inferences
- **Inset size.**
  - Draw the inset at about **96–120 dp** diameter when expanded. The usable dot area (0.5 R) is then about 48–60 dp across.
  - With about 7 mm (about 44 dp) touch error, a ~50 dp target area gives only about 3×3 distinguishable positions per finger placement. So:
    - Let a tap on the small inset **open an enlarged spin panel**, about 200–240 dp diameter, where 0.5 R spans 100–120 dp.
    - Move the dot by **relative drag**, with a gain of about 0.5 so the dot travels half as far as the finger, rather than absolute positioning.
  - That gives roughly 1–2% of R per dp, enough for fine follow and draw.
- **Mapping.** Map visually to the full ball face, but restrict dot travel to a circle of 0.5 R, drawn as a faint ring, so players see why the dot stops. Optionally use 0.4 R as the "safe" ring with a red tint between 0.4 and 0.5 R if a miscue model exists.
- **Presets.** One-tap chips for **Centre, Follow, Draw, Left, Right** (and maybe Stun). Each chip at least 48 dp. Keep text labels as well as arrows (colour-independent).
- **Showing the effect.** Bend the cue-ball deflection guide (see Guidelines) in easy modes. Show a small spin-direction glyph on the moving cue ball during the shot. Reset to centre after each shot (common expectation; verify in playtest).
- **Scope fallback.** The design doc permits shipping centre-ball only. The review evidence suggests spin is expected, so prioritise at least Follow/Draw/Centre presets if full 2D spin slips.

### Gaps
- No public documentation of commercial inset sizes, dot ranges or whether spin persists between shots was found.
- No usability study on spin-control layouts on phones was found.

## Ball-in-hand placement

### Takeaway
Ball-in-hand is generally done by dragging the cue ball, often from a dedicated "move cue ball" control. The legal area depends on the rule set: anywhere on the table after most fouls, and behind the head string after a break scratch in many rule sets. I found almost no public UX documentation, so the specifics below are mostly inference.

### Cited Findings
- A 3D billiards game lists a "Move cue ball" control icon among its touch controls, a distinct mode rather than an overloaded drag. — [FlyOrDie 3D Billiards help](https://www.flyordie.com/games/help/billiard/en/contents.html)
- Game Accessibility Guidelines: avoid requiring held buttons, and keep precision targets stationary. — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Finger occlusion is the main cause of touch error. Offset or indirect manipulation fixes it. — [Vogel & Baudisch CHI 2007](https://projects.csail.mit.edu/hci-reading/papers/chi2007-vogel.pdf)

### Inferences
- **Indirect drag.** Grab anywhere within about 48 dp of the cue ball (an enlarged hit area, since the ball itself is only about 15 dp). Then move it with **relative motion**: the ball moves with the finger delta, not under the finger. Alternatively, render it about 40–60 dp above the touch point so the thumb never hides it (the Shift-style offset).
- **Legal area.**
  - Tint the legal region: the whole bed after a foul, or the kitchen (head-string area) after a break scratch, depending on the chosen rule set.
  - Dim everything else.
  - Clamp the ball inside the region rather than rejecting the drop.
- **Collision avoidance.**
  - While dragging, slide the ghost cue ball along obstacles: project out of overlaps with other balls and cushions, minimum centre distance 2R plus a small epsilon.
  - If the finger position is illegal, show the nearest legal position in a solid colour and the finger's target as a red outline.
- **Confirm step.** Placement is committed only when the player starts aiming (or taps "Done"), so an accidental release doesn't lock a bad spot.
- Show an optional "aim from here" preview while placing, so players can place for a specific shot.

### Gaps
- No public UX writeups on ball-in-hand placement in mobile pool games were found.
- The rule detail (behind the head string after a break scratch versus anywhere) differs between rule sets (WPA vs league/bar rules). I did not fetch the WPA rule text this session. Verify against the current WPA 8-ball rules before finalising.

## Camera and table orientation on a portrait phone

### Takeaway
In portrait, the table's long axis is vertical. This is the only way to give 16 balls a readable on-screen size on a 420 dp wide phone. The default is a near top-down view, with optional or automatic lower 3D views during the stroke. Accessibility guidelines warn against sudden or unexpected camera movement and ask for options to reduce motion.

### Cited Findings
- Top-down perspectives are standard on mobile ("offers a top-down perspective", "crisp top-down 2D visuals"). — [Pocket Gamer review "Pool"](https://www.pocketgamer.com/pool/review/)
- 3D pool games offer a Top view toggle and a Zoom control via icon drags. — [FlyOrDie 3D Billiards help](https://www.flyordie.com/games/help/billiard/en/contents.html)
- Game Accessibility Guidelines on camera motion:
  - "Avoid (or provide option to disable) any difference between controller movement and camera movement" (Intermediate).
  - "Avoid any sudden unexpected movement or events" (Advanced).
  - "If the game uses field of view … set an appropriate default for the expected viewing environment" (Basic), and allow FOV adjustment (Intermediate).
  - "Provide an option to turn off / hide background movement" (Intermediate).
  — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Table dimensions: 9-ft playfield 2.54 × 1.27 m, ball 57.15 mm. — local `docs/games/pool.md`
- Visual target `docs/refs/pool/keyframe_1.png` shows the playfield long axis vertical, filling about 80–85% of screen width and about 80% of height. The spin inset sits at the left edge and the power bar at the right edge. — local file (viewed this session)

### Inferences
- **Orientation, worked numbers (derived).**
  - **Long axis vertical:** the playfield short side (1.27 m) spans about 85% of 420 dp, about 357 dp. Then 1 m is about 281 dp and a ball is about **16 dp, about 2.5 mm** physical. The long side is about 714 dp, which fits in the 933 dp height with room for a HUD.
  - **Long axis horizontal:** the 2.54 m side spans 357 dp, so a ball is about **8 dp, about 1.3 mm**. That is too small to read numbers (see Readability).
  - Vertical is the clear choice.
- **Fraction of screen.**
  - Target the playfield at about **85–90% of width** (rails can bleed to the edge) and about 75% of height. Reserve about 90–110 dp at the top for the HUD (turn and groups) and about 60–80 dp at the bottom for the hint and status line.
  - Overlay side controls on the rails and cloth margin rather than shrinking the table.
- **Default camera.**
  - Orthographic or near-orthographic top-down, with a slight tilt of about 5–15° and a long-lens (narrow FOV, about 20–30°) perspective to keep distortion low, for aiming.
  - Aiming should always happen in this view so touch-to-world mapping stays linear.
  - Because the shot direction rotates freely, **do not rotate the table to follow aim** in the default view. Keep the table fixed so drag directions stay stable (matches the "no difference between controller movement and camera movement" guideline).
- **Stroke camera (low behind the cue).**
  - Transition over about 0.4–0.6 s with ease-in-out, only *after* the shot is committed (release). Never during aiming or power drag, or the touch mapping changes under the finger.
  - Return to top-down within about 0.5 s of the last ball slowing, or follow the cue ball's last segment.
- **Follow cam and motion sickness.**
  - The fastest ball can change identity many times on a break, which makes the camera jumpy. Follow a **damped, weighted centroid** of moving balls (spring with a time constant of about 0.25–0.4 s), or simply stay top-down for breaks.
  - Clamp camera angular velocity to about 90–120°/s and avoid roll entirely.
  - Provide a "Reduce camera motion" setting that keeps top-down throughout. The guidelines above call for this.
- **Zoom.** Optional pinch zoom is about 1×–2× in top-down only. Because aim uses drag anywhere, pinch conflicts. Either use a two-finger gesture that is explicitly separate from one-finger aim, or a zoom button.

### Gaps
- No empirical data on motion sickness from follow cameras in mobile sports games was found. The recommendations rest on general accessibility guidance.
- No industry data on what fraction of the screen the table occupies in commercial portrait pool games was found. Only the project's own keyframe was measured.

## Readability: ball size, numbers, stripes vs solids, colour-blind access

### Takeaway
At about 16 dp (about 2.5 mm) per ball on the test phone, colour plus stripe pattern carries group identity, and numbers are marginal unless rendered as a camera-facing decal or enlarged label. Accessibility guidance requires that no essential information (group, 8-ball, turn) is conveyed by colour alone. Pool's own number and stripe system is a ready-made redundant encoding if it stays legible.

### Cited Findings
- In 8-ball, balls 1–7 are solids, 9–15 are stripes and the 8 belongs to neither. Balls are identified by number, colour and pattern, so a colour-blind player can follow the rules if numbers are readable. — [Wikipedia: Billiard ball (mirror)](https://kaweah.freedombox.rocks/kiwix/wikipedia_en_all_maxi_2023-10/Cue_Ball); [Britannica: eight ball](https://www.britannica.com/topic/eight-ball)
- Player requests in indie pool games ask for a colour-blind mode with "unique symbols on top", "different patterns on the balls", or "numbers to always be on top". One game added an "accessible" mode that displays numbers on balls. — [Combo Pool itch.io comments](https://nusan.itch.io/combo-pool/comments?after=59); [itch.io post](https://itch.io/post/11551393)
- No documented standard colour-blind palette or symbol set for pool balls exists in the sources found. — (same search; gap)
- Game Accessibility Guidelines:
  - "Ensure no essential information is conveyed by a fixed colour alone" (Vision, Basic).
  - "Provide high contrast between text/UI and background" (Basic).
  - "Use an easily readable default font size" (Basic).
  - "Allow the font size to be adjusted" (Advanced).
  — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- WCAG 2.x: 4.5:1 contrast for normal text (SC 1.4.3) and 3:1 for non-text UI components and graphical objects needed to understand content (SC 1.4.11). — [W3C Understanding SC 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html); [W3C Understanding SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) *(standard values; pages not re-fetched this session)*
- Visual reference keyframe_1: HUD group indicators use coloured dots only ("YOU · stripes" with coloured circles). — local file (viewed this session)

### Inferences
- **Numbers.**
  - At 16 dp the number disc on a real ball (about 1/3 of the diameter) would be about 5 dp, about 0.8 mm, which is illegible.
  - Option A: render numbers as a **billboarded label rotated to stay upright**, at about 55–60% of the ball diameter (about 9 dp; 1080-canvas about 23 px) in a white disc with black text. Plausible but tight. Test on device.
  - Option B: "Show numbers" toggle (default ON) that enlarges the disc.
  - Either way, the HUD rack of remaining balls should show numbers at at least 12–14 sp.
- **Stripes vs solids at small sizes.** A real stripe is a band around the equator with white caps. From top-down at about 16 dp the white caps show as white segments on two sides, which reads well if the stripe band is kept at about 50% of the diameter and the white has strong contrast with the cloth.
  - Avoid pure white balls on very light cloth.
  - Check that the cue ball (white) and stripe caps are distinguishable. Give the cue ball a subtle marker dot or ring.
- **Colour-blind redundancy.**
  - Groups: use stripe/solid pattern plus number plus a HUD label ("Stripes 9–15") rather than coloured dots alone.
  - The 8-ball is black. Ensure it is at least 3:1 against the cloth, adding an outline or rim light if the cloth is dark.
  - Optionally add an "accessible" mode with symbols or high-contrast group rings.
- **Cloth contrast.** Choose a cloth colour that keeps every ball colour (especially dark red, dark green, blue, purple and black) at 3:1 or better against it, or add a 1–1.5 dp dark/light outline (rim) around every ball.
- **Guide lines.** White or near-white guides at at least 3:1 against the cloth, 1.5–2 dp thick (about 4–5 canvas px).

### Gaps
- No empirical study of ball legibility versus on-screen size on phones was found. The 16 dp estimate is derived, and number legibility needs on-device testing.
- Measured contrast ratios for the keyframe palette were not computed this session.

## Feedback: haptics, sounds, shot-result text, turn indicators, shot clocks

### Takeaway
Android guidance is explicit: short, crisp ("clear") haptics tied to discrete events, platform constants over raw vibration, strength scaled to importance and a user toggle. The genre conventions for text call-outs and turn banners are visible in the project's own concept, but I found no published guidance on shot clocks in casual vs-CPU pool.

### Cited Findings
- Android haptics principles:
  - "less is more"; too much vibration can be "annoying and even numbing".
  - "Favor rich and clear haptics over buzzy haptics", "Be consistent", "Be mindful of frequency of use, and importance".
  - "Given the choice of buzzy haptics or no haptics for touch feedback, choose no haptics."
  - Use action-oriented `HapticFeedbackConstants` (which have platform fallbacks), then `VibrationEffect` predefined effects or composition primitives.
  - Avoid legacy one-shot vibrations.
  — [Android Developers: Haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- "A good keyclick haptic feedback signal should last between 10 to 20 milliseconds". The actuator may ring for another 20–50 ms afterwards. — [Android Developers: Haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- Frequent events (scrolling, moving a handle) should be "very subtle". More important events should be stronger. Effects can "become stronger as the interaction reaches a target", for example "gradually increasing the amplitude of a sequence of ticks with dragging". — [Android Developers: Haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- Co-design haptics with visuals and audio. Out-of-sync haptics feel "unsettling" or broken. — [Android Developers: Haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
- CONFIRM is expected to be "short and light". REJECT can be stronger. — [Android Developers: haptic feedback](https://developer.android.com/develop/ui/views/haptics/haptic-feedback). The API level for CONFIRM/REJECT is reported inconsistently (Android 8 per the AOSP UX foundation page vs Android 13 per third-party). — [AOSP UX foundation for haptics](https://source.android.com/docs/core/interaction/haptics/haptics-ux-foundation); [UI/UX Atlas](https://uiux-atlas.pages.dev/lessons/interaction-design/haptic-feedback-design) *(check the [HapticFeedbackConstants reference](https://d.android.com/reference/kotlin/android/view/HapticFeedbackConstants) for exact API levels)*
- Game Accessibility Guidelines:
  - "Include toggle/slider for any haptics" (Basic).
  - "Allow players to progress through text prompts at their own pace" (Basic).
  - "Include a cool-down period (post acceptance delay) of 0.5 seconds between inputs" (Advanced).
  - "Do not make precise timing essential" (Advanced).
  — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- Touch target sizing: Material/Android minimum 48 × 48 dp (about 9 mm), with 8 dp minimum spacing. The visible icon can be smaller than its hit area. — [Google Android Accessibility Help: Touch target size](https://support.google.com/accessibility/android/answer/7101858?hl=en)
- Region-specific sizes from Hoober's data: about 7 mm centre, 11 mm top, 12 mm bottom. — [Smashing Magazine cheatsheet](https://smashingmagazine.com/2023/04/accessible-tap-target-sizes-rage-taps-clicks/)

### Inferences
- **Haptic map (inference, following Android guidance).** Godot's `Input.vibrate_handheld(duration_ms, amplitude)` is a one-shot vibration, which Android guidance discourages for crisp feedback. Keep durations at 10–20 ms and amplitudes low, or call the platform constants through a small Android plugin if available.

  | Event | Effect |
  |---|---|
  | Aim drag | None, or very light tick every ~1° when using fine aim |
  | Power drag | Light ticks every 10%, rising in strength toward 100% |
  | Cue strike | One crisp pulse scaled to power, 10–20 ms |
  | Ball–ball contacts | None (too frequent on breaks) |
  | Pot | One short, firm pulse |
  | Foul or scratch | A "reject"-style double tick |
  | Win | Short rich pattern |

  Global toggle plus intensity slider in Settings.
- **Sound.** Cue-tip impact scaled by speed. Ball–ball clicks scaled by relative speed, rate-limited (cap at about 8 simultaneous voices and ignore contacts under about 0.05 m/s). Cushion thumps, pocket drop and rattle, and a soft UI tick for spin and preset changes.
- **Shot-result text.**
  - Brief, about 1.0–1.5 s, non-blocking banners for notable events (multi-pot, bank, draw or follow shot recognised, safety, foul reason).
  - Foul text must *explain* the foul ("Foul: no rail after contact"), since rule clarity matters more than praise for casual players.
  - Keep text at at least 16–18 sp and at least 4.5:1 contrast.
- **Turn indicator.** Persistent HUD highlight of the active player plus a 0.8–1.2 s centre banner ("Your turn" or "CPU's turn") at turn change. Shift the HUD group display from colour dots to number chips or a stripe/solid icon (colour-alone guideline).
- **Shot clock (inference).** In vs-CPU casual play, default **off**, or a generous optional 45–60 s timer with no penalty in practice. Timing pressure conflicts with "do not make precise timing essential" and adds nothing against a CPU. If a CPU "thinking" delay exists (the design doc budgets about 150 ms of compute behind a camera pan), keep the visible CPU turn short, about 1–2 s, so pacing doesn't drag.
- **Input lockout.** After release, ignore new touches on the table for about 0.3–0.5 s and during ball motion. Allow a tap to fast-forward ball motion as a convenience.

### Gaps
- No published data on haptic patterns used by mobile pool games was found.
- No sources on shot-clock conventions in casual vs-CPU pool games were found. Online PvP titles are known to use turn timers, but I found no citable documentation in this session.
- No studies on the effect of "great shot"-style praise text on retention in casual sports games were found.
