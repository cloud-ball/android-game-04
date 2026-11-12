# Board Proportions and Touch Ergonomics for a Portrait Falling-Block Well (Stack Drop, 9x18, ~411 dp 20:9 phone)

Device math used throughout (computed, not sourced): test phone 1260x2800 px, 6.6 in diagonal, density 3.0625 (1260 px / 411 dp). That gives ~465 ppi, a screen of ~411 x 914 dp, ~68.8 x 152.9 mm physical, and **1 dp ~ 0.167 mm** on this device. Nominal Android dp is 1/160 in = 0.159 mm, so 48 dp is nominally ~7.6 mm. Google's "~9 mm" figure for 48 dp (below) is a rounded approximation.

## Q1. What share of screen width/height does the play well take in portrait mobile block-stacking and grid-puzzle games?

### Takeaway
I found no published survey or measured dataset of well-to-screen ratios for mobile falling-block games. That figure has to come from geometry and playtesting, not from a cited norm. The genre's standard well is 10 wide x 20 visible (a 1:2 aspect), with a hidden spawn buffer above. On a 20:9 phone, a 1:2 well is always width-limited: filled edge to edge it would be ~90% of screen height. So the real design choice is how much width to give up for side panels (next/hold) and margins.

### Cited Findings
- Most games in the genre use "a playfield 10 cells wide and between 16 and 24 cells tall," and most rule-standard games use "a visible height of 20 cells". So the convention is 10 wide x 20 visible, with a buffer zone above where pieces spawn (rows 21-22). Many games hide the whole buffer, and some show part of row 21. — [Tetris Wiki: Playfield](https://tetris.wiki/Playfield)
- Widths other than 10 do exist (8, 9, 11, 12, 14 and more). A 9-wide well is an established variant. — [Tetris Wiki: Playfield](https://tetris.wiki/Playfield)
- Generic mobile-game UI guidance: keep the top third for status readouts only (score, level), keep primary actions in the lower thumb arc, and leave the spot directly under the resting thumb empty during play. Puzzle games are named as a portrait-suited genre. — [h-idris: Mobile game UI design](https://h-idris.com/blog/mobile-game-ui-design.html)
- Tall aspect ratios "extend the vertical distance [the] thumb must travel to reach top UI elements". Suggested fixes are moving buttons lower or making them larger. — [Dibz: How do aspect ratios affect game UI on phones?](https://dibz.me/blog/how-do-aspect-ratios-affect-game-ui-on-phones-1269) (secondary blog; surfaced in search, not fetched in full)
- A designer's reference frame for portrait games is 390 x 844 pt/dp, which is close to a 20:9-class phone. — [h-idris](https://h-idris.com/blog/mobile-game-ui-design.html)

### Inferences
- The 9:18 well is exactly 1:2, so its height is twice its width. On a 411 x 914 dp screen:
  - At 100% width (45.7 dp cells), the well is 822 dp tall, which is 90% of the screen. Nothing fits above or below except the system bars. This is the "chunky" configuration that was reported.
  - At ~70-80% width, the well is ~63-71% of height. That leaves ~100-170 dp at the top (status bar plus HUD) and ~100-160 dp at the bottom (control/gesture strip plus system gesture inset).
- Genre pattern (generic): portrait falling-block layouts put a narrow column beside the well for next/hold previews, shown at reduced cell scale (often around 50-60% of a well cell). Alternatively the previews go in a strip above the well, with the score/level bar at the top. Previews in the side column cost width. A strip above costs height, and on 20:9 phones height is the cheaper resource.
- Working target for Stack Drop: **well width ~70-80% of screen width, well height ~63-71% of screen height**. This is an inference from the geometry and the safe-area budget below, not a cited industry average.

### Gaps
- I found no source that measures board-to-screen ratios across shipped mobile falling-block or grid-puzzle games. Game UI Database-style catalogs were not reachable in the time budget. If needed, measure 5-10 genre screenshots on a 20:9 device by hand (well width / screen width).
- I found no postmortem or GDC talk that gives a numeric well size for mobile falling-block games.

## Q2. Comfortable cell size (dp/mm) for readability and gesture control, versus touch-target minimums (48 dp / 44 pt / ~9 mm)

### Takeaway
Touch-target minimums (48 dp, 44 pt, 7-10 mm) are for things you tap, and falling-block cells are never tapped one by one. Pieces are moved by relative swipes and drags, so cell size is set by visual readability and by how drag distance maps to columns, not by tap accuracy. Cells of roughly 5-6.5 mm (30-38 dp on this phone) sit below the tap minimum on purpose, and that is fine. What must meet 48 dp+ (ideally 9-12 mm) is any on-screen button and the swipe/gesture regions.

### Cited Findings
- Android: make touch targets at least 48 x 48 dp, separated by 8 dp or more. Google says 48 dp is about 9 mm physically. A small 24 dp icon can still have a 48 dp target through padding. — [Google Android Accessibility Help: Touch target size](https://support.google.com/accessibility/android/answer/7101858?hl=en)
- Apple's minimum is 44 x 44 pt. A practitioner's in-game guidance: primary action during play is 48 dp minimum, but the author uses 64-80 dp with a generous invisible hit area. Icon buttons use a 48 dp visual with a 56 dp hit area. Spacing between targets is 8 dp minimum, and the author uses 12-16 dp ("Under 8 dp is a misfire waiting to happen"). A thumb is "roughly a centimetre wide". — [h-idris: Mobile game UI design](https://h-idris.com/blog/mobile-game-ui-design.html)
- Parhi, Karlson & Bederson (MobileHCI 2006): for one-handed thumb use, 9.2 mm targets are large enough for discrete taps and 9.6 mm for serial taps. The study varied target position because one-handed grip limits thumb reach. — [Microsoft Research summary](https://www.microsoft.com/en-us/research/?p=155150); [ACM DOI 10.1145/1152215.1152260](https://dx.doi.org/10.1145/1152215.1152260)
- Hoober: touch accuracy runs from about **7 mm at screen centre to 12 mm at the corners**. Make edge rows 9-10 mm tall. Under a one-handed grip while encumbered, far-corner accuracy drops to over 30 mm. Design about 20% larger than you otherwise would, and expect a "7 mm" element to render anywhere from 5 to 9 mm across devices. — [Hoober, UXmatters 2017, Design for Fingers, Touch, and People Pt 3](https://www.uxmatters.com/mt/archives/2017/07/design-for-fingers-touch-and-people-part-3.php)
- Studies Hoober summarizes in the same article:
  - Henze et al. 2011: error rates rise sharply below 15 mm and exceed 40% under 8 mm.
  - Park et al. 2008: 10 mm beats 7 mm, and 4 mm is "sort of a disaster".
  - Schildbach & Rukzio 2010: while walking, 6.74 mm buttons had error rates up to 23%, ~10 mm did much better, and 20 mm removed nearly all errors.
  - Lee & Zhai 2009: 10 mm buttons reached 98-99.4% accuracy.

  — [Hoober, UXmatters 2017](https://www.uxmatters.com/mt/archives/2017/07/design-for-fingers-touch-and-people-part-3.php) (secondary citations; I did not verify the originals)
- Henze, Rukzio & Boll 2011 ("100,000,000 Taps") was itself a mobile game: players touched circles that appeared, giving 120,626,225 touch events from 91,731 installs. Touch positions were systematically skewed, and a compensation function cut errors by 7.79%. — [Lancaster eprints](https://eprints.lancs.ac.uk/id/eprint/57576)
- Holz & Baudisch (CHI 2010): touch inaccuracy is largely systematic (the perceived-input-point model), not just the "fat finger". — [christianholz.net](https://www.christianholz.net/generalized_perceived_input_point_model)
- Swipe regions should be at least ~45 px tall and wide (web px, roughly 45 dp) so that neighbouring swipe zones don't trigger together. Swipes usually start near an edge and move diagonally toward the middle. — [Smashing Magazine: The Thumb Zone (2016)](https://www.smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users/)
- Genre control conventions (generic): swipe left/right to move, swipe down for soft drop, swipe up (or a fast flick down) for hard drop, tap to rotate, with on-screen buttons as an option. — [falling-blocks clone README](https://github.com/Clyde098/falling-blocks); [Falling Blocks app listing (two control modes: buttons or finger movement)](https://apps.apple.com/us/app/falling-blocks-puzzle-game/id1474442643)
- Known pain points in the genre:
  - Drag-to-move "often let[s] you down" because the piece tracks the finger. — [Gamezebo review](https://www.gamezebo.com/reviews/tetris-battle-drop-review-get-used-to-it/)
  - Players report "slow, clunky swipe controls" and ask for tap alternatives. — [TouchArcade thread](https://toucharcade.com/community/threads/puzzle-games-with-precise-controls.312950/)
  - Accidental swipe-up from the bottom edge when a tap was meant. — [itch.io comment](https://itch.io/post/12727791)
  - Button controls work but are "small and slightly awkward". — [SplitMetrics review page](https://splitmetrics.com/apps/tetris/id1491074310)

### Inferences
- Cells are visual units, not touch targets, so the 48 dp / 9 mm rule does not apply to them. The rules that do apply:
  - **Readability:** a 3D bevelled cell needs enough pixels for its edge highlight and gap to read. On a 465 ppi screen, even a 30 dp cell is ~92 px. Pixel count is not the limit; perceived chunkiness is.
  - **Drag mapping:** if horizontal drag moves one column per cell-width of finger travel, larger cells mean more finger travel per column. A 9-wide well at 42 dp needs ~63 mm of travel edge to edge, almost the whole 68.8 mm screen. At 34 dp it needs ~51 mm. The better fix is to decouple drag sensitivity from cell size: use a fixed physical step of ~5-7 mm per column, tunable in settings. This removes the main touch argument for big cells.
  - **Finger occlusion:** a ~10 mm thumb resting on the well hides 1.5-2 columns at 34-38 dp cells. That is one reason the convention is to gesture anywhere on screen, or in a zone below the well, rather than directly on the piece.
- A cell of ~5.5-6.5 mm (33-39 dp here) is comparable to a large body-text glyph block. It reads clearly at arm's length without the "chunky toy" look that cells of ~7.5 mm and up (45+ dp) give on a 69 mm-wide screen.
- Anything the player taps (pause, hold button, optional rotate/drop buttons) should still be 48 dp+ (8 mm on this phone), preferably 56-64 dp hit areas with 12-16 dp spacing. Put larger targets at edges and corners (Hoober's 9-12 mm).

### Gaps
- I found no HCI study that measures preferred visual cell size for falling-block games, and no study of drag-gain settings for grid movement on phones. Recommended values here are inferences.
- I could not extract the Parhi 2006 PDF text (binary only), so per-size error tables and position effects are not quoted.
- The original Henze 2011, Park 2008 and Lee & Zhai 2009 figures are quoted through Hoober and not verified against the originals.

## Q3. Cell-size options for a 9x18 well on a ~411 dp x ~914 dp 20:9 phone

### Takeaway
On the 411 x 914 dp test phone, 34-36 dp cells give a 306-324 dp wide (74-79%) by 612-648 dp tall (67-71%) well. That leaves ~87-105 dp of width for slim side panels and room above and below for the HUD and gesture strip. 42 dp cells (92% of width, 83% of height) reproduce the current "too chunky" look. Recommended starting point: **34 dp**, with 32 dp and 36 dp as the tuning range.

### Cited Findings
- Screen budget references:
  - Android status bar defaults to 24 dp on most devices. With a cutout, the portrait status bar must be at least as tall as the cutout ("the default of 48dp, or the height of the cutout, whichever is larger" in the AOSP overlay example). — [AOSP: Display cutouts](https://source.android.com/docs/core/display/display-cutouts)
  - AOSP once reduced the bottom gesture inset for full gesture navigation to a 32 dp height, alongside a 48 dp three-button navigation bar height. — [AOSP framework commit (mirror)](https://gitlab.e.foundation/e/os/android_frameworks_base/-/commit/b5e5bcb3ed8c3252041fc238b2cf15c4ba89d88f) (Android 10-era value; may have changed on newer OEM skins)

  See Q5 for detail.

### Inferences
All numbers below are computed for 411 x 914.3 dp, at 0.167 mm/dp.

| Cell (dp) | Cell (mm) | Well W x H (dp) | % screen W | % screen H | Well W x H (mm) | Width left for panels + margins (dp) |
|---|---|---|---|---|---|---|
| 26 | 4.35 | 234 x 468 | 56.9% | 51.2% | 39.1 x 78.3 | 177 |
| 30 | 5.02 | 270 x 540 | 65.7% | 59.1% | 45.1 x 90.3 | 141 |
| 32 | 5.35 | 288 x 576 | 70.1% | 63.0% | 48.2 x 96.3 | 123 |
| **34** | **5.69** | **306 x 612** | **74.5%** | **66.9%** | **51.2 x 102.3** | **105** |
| 36 | 6.02 | 324 x 648 | 78.8% | 70.9% | 54.2 x 108.3 | 87 |
| 38 | 6.35 | 342 x 684 | 83.2% | 74.8% | 57.2 x 114.4 | 69 |
| 42 | 7.02 | 378 x 756 | 92.0% | 82.7% | 63.2 x 126.4 | 33 |
| 45.7 (full width) | 7.64 | 411 x 822 | 100% | 89.9% | 68.8 x 137.6 | 0 |

- **Vertical budget at 34 dp** (914 dp total):
  - Status/cutout: ~40-50 dp.
  - Score/HUD bar: ~48-56 dp.
  - Optional next strip: ~0-40 dp.
  - Well: 612 dp.
  - Control/gesture zone: ~100-130 dp.
  - System gesture inset: ~24-32 dp.

  That adds up to ~830-920 dp, so it fits. At 36 dp it fits only if next/hold go in the side panels.
- **Horizontal budget at 34 dp:** 105 dp spare, i.e. 16 dp outer margin x 2 plus ~36 dp per side for slim panels. Next/hold previews at ~50-55% scale (17-19 dp mini-cells) give a 4-wide piece that is ~70-75 dp. That does not fit beside a 34 dp well unless the panels overlap the margins or the previews go above the well. With 32 dp cells, ~45 dp per side works for small 2-up previews.
- **3D caveat:** these sizes are on-screen projected sizes. With a perspective camera, set the FOV/distance so the well's front face projects to the target dp width, measured from a screenshot. An orthographic or low-FOV camera (~20-30 deg vertical) keeps far and near rows within a few percent of each other. A wide FOV makes bottom rows larger than top rows and adds back the "chunky" feel at the bottom.
- **For future devices:** compute cell = floor((screenWidth_dp - 2*16 - panels) / 9), clamp it to [30, 38] dp, then centre the well vertically in the remaining safe area. Do not size from height on 20:9+ phones.

### Gaps
- The 34 dp recommendation is a reasoned target, not a published standard. Confirm it with an on-device A/B at 32, 34 and 36 dp.

## Q4. Thumb-zone research: where should the board and controls/HUD sit vertically on a 20:9 phone?

### Takeaway
Put the board in the visual centre to upper-middle of the screen, where people look and touch most accurately. Put gesture and control areas in the bottom third, where one-handed thumbs naturally rest. Put status (score, level, lines) in the top band, which is hard to reach and so suits read-only information. Put pause in a top corner, small and slightly awkward to reach on purpose, so it isn't hit by accident.

### Cited Findings
- Hoober's field study (1,333 observations, 2012-13): 49% of people held the phone one-handed, 36% cradled it, and 15% used two hands. The right thumb was on screen 67% of the time and the left 33%. — [Scott Hurff, Game Developer: How to design for thumbs in the era of huge screens](https://gamedeveloper.com/design/how-to-design-for-thumbs-in-the-era-of-huge-screens); original: [Hoober, UXmatters 2013](https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php)
- About 75% of interactions are thumb-driven (Josh Clark). — [Smashing Magazine: The Thumb Zone](https://www.smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users/)
- Thumbs don't scale with screens. The comfortable zone stays about the same size while larger phones add unreachable area and force grip changes (pinkie support, "choking up"). Large phones should not be treated as scaled-up small phones. — [Hurff, Game Developer](https://gamedeveloper.com/design/how-to-design-for-thumbs-in-the-era-of-huge-screens)
- Hoober's later findings:
  - Users prefer to touch the centre whenever they can.
  - Touch is faster and more accurate near the centre, and screen position was the largest variable he found.
  - People look at the centre, so key content belongs mid-viewport.
  - Key actions go in the middle half to two-thirds of the screen. Secondary actions go along the top and bottom edges, kept sparse.
  - Curved screens and case lips block edge touches, so pad controls at the edges.

  — [Hoober, UXmatters 2017](https://www.uxmatters.com/mt/archives/2017/07/design-for-fingers-touch-and-people-part-3.php)
- Hoober has since called the popular green/yellow/red thumb-zone heat-map chart wrong (4ourth Mobile, 2022). It is a rough heuristic, not a measured map. — [Monterail](https://www.monterail.com/blog/thumb-friendly-navigation-word-oriented-design) (secondary; I did not find the original 2022 statement)
- Game-specific zoning:
  - The bottom third is the natural zone, the middle band is a stretch, and the top third is hard to reach and reserved for status.
  - Leave the area under the resting thumb empty.
  - Put pause in a top corner, small and slightly awkward.
  - About one player in ten is left-handed, so mirror or centre controls.

  — [h-idris](https://h-idris.com/blog/mobile-game-ui-design.html)

### Inferences
Suggested vertical stack for Stack Drop at 34 dp cells on 914 dp:
- 0-~45 dp: system status/cutout. Leave it empty, or show a dimmed background only.
- ~45-100 dp: score/level/lines bar, with pause in a top corner (48 dp+ hit area).
- ~100-712 dp: well (612 dp), centred horizontally with slim next/hold panels. The well's centre sits at ~44% of screen height, just above the middle, which matches the look-and-touch-centre findings.
- ~712-880 dp: gesture-capture zone / optional buttons (~170 dp, ~28 mm). This is the bottom-third thumb zone. Swipes should also be accepted over the well itself, but the zone below the well gives a thumb a place to rest without hiding the stack.
- ~880-914 dp: system gesture inset. Don't start game gestures here; a swipe up from this region triggers Home.

Because people hold the phone one-handed about half the time, hard-drop-by-upward-swipe that starts near the bottom edge clashes with the system home gesture (see the itch.io pain point in Q2). Prefer flick-down for hard drop, or start upward swipes above the inset.

### Gaps
- I found no reach data specific to 20:9 or 6.5-6.8 in phones from 2020-2026. The main reach studies (Hoober 2013, Hurff 2014) predate tall phones, and the zone boundaries above are extrapolated.

## Q5. Safe areas and margins on Android (cutouts, gesture navigation) for a game HUD

### Takeaway
Read insets at runtime, never hardcode them. As budgeting figures: top ~24-50 dp (status bar or cutout, whichever is taller), bottom ~24-48 dp (32 dp gesture area on stock gesture nav, 48 dp with three-button nav), sides ~0 dp for layout but ~16 dp visual margin. Keep drags that start at the edges away from the left/right back-gesture strips.

### Cited Findings
- Status bar: AOSP defaults to 24 dp on most devices. In portrait with a cutout, the status bar should be at least the cutout height. Apps should use WindowInsetsCompat rather than hardcoded heights. Rendering into the cutout is recommended for immersive content including games, and for apps targeting SDK 35 on Android 15, SHORT_EDGES cutout mode is treated as ALWAYS. — [AOSP: Display cutouts](https://source.android.com/docs/core/display/display-cutouts); [Android Developers Blog: Supporting display cutouts](https://android-developers.googleblog.com/2018/07/supporting-display-cutouts-on-edge-to.html)
- Edge-to-edge is the default from Android 15 (API 35). On Android 10+, system gesture insets cover a bottom strip for Home and left/right strips for Back, where system gestures take priority over the app. — [Android Developers: Display content edge-to-edge](https://developer.android.com/training/gestures/edge-to-edge); [Gesture navigation codelab](https://codelabs.developers.google.com/codelabs/gesture-navigation)
- The AOSP framework commit set the full-gesture-nav bottom gesture inset to 32 dp, with a 48 dp three-button navigation bar. — [AOSP framework commit mirror](https://gitlab.e.foundation/e/os/android_frameworks_base/-/commit/b5e5bcb3ed8c3252041fc238b2cf15c4ba89d88f)
- The bottom mandatory gesture inset depends on taskbar state, either the content height or the gesture height. — [Launcher3 change](https://gerrit.omnirom.org/plugins/gitiles/android_packages_apps_Launcher3/+/21bb36fa6635bae7c8782490eb138c404f448755%5E%21)
- Google advises: "never hardcode" inset values, because the navigation bar can change size. — [Android Developers Medium: Gesture navigation, handling visual overlaps](https://medium.com/androiddevelopers/gesture-navigation-handling-visual-overlaps-4aed565c134c) (403 on fetch; quoted from search summary)
- iOS for comparison: the home-indicator bottom inset is about 34 pt on current iPhones. — [h-idris](https://h-idris.com/blog/mobile-game-ui-design.html)
- Pad controls at the edges because curved screens and case lips block edge touches. — [Hoober, UXmatters 2017](https://www.uxmatters.com/mt/archives/2017/07/design-for-fingers-touch-and-people-part-3.php)

### Inferences
- In Godot, read `DisplayServer.get_display_safe_area()` (and cutouts via `DisplayServer.get_display_cutouts()`) at startup and on resize. Lay out inside the safe rect, then add the game's own margins:
  - Top: ~8 dp below the safe-area top.
  - Sides: 16 dp. Android's back-gesture strips start at the very edge, so a horizontal drag that begins within ~16-24 dp of the edge may become Back. A 16 dp gutter plus an inset well keeps piece drags clear of them.
  - Bottom: ~8-16 dp above the gesture inset.
- Never place the well or a tappable button inside the bottom gesture inset. The background can draw there.
- The current near-full-width well (~0-16 dp side margins) puts the outer columns inside the back-gesture strips. That is a functional reason to shrink, beyond the visual one.

### Gaps
- I could not confirm current (Android 14-16, OEM skin) default dp values for status-bar height, gesture inset or back-gesture strip width. The 24/32/48 dp values come from older AOSP sources. Measure on the Vivo test phone by logging the safe area and cutout rects.
