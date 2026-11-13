# HUD layout patterns for portrait falling-block and versus puzzle games

Scope note: these notes describe genre conventions generically. The sources below sometimes name commercial titles; they are cited only to show that a convention exists, not as templates to copy. Research budget was about 18 tool calls. Primary-source coverage of portrait-phone layouts specifically is thin (see Gaps).

## 1. Where next queue and hold go in portrait, and the trade-offs

### Takeaway
The genre defines what the HUD contains (hold slot, next queue, score, lines, level, time, playfield, ghost piece) but has no fixed layout rule. Two placements recur on phones. One puts hold and next in a top strip above the board. The other, carried over from landscape and console games, puts hold on one side and next on the other. In portrait the top strip keeps the well widest. Side columns cost the well width it cannot spare on a 9-wide board.

### Cited Findings
- The genre's standard single-player HUD lists 9 components: Hold Queue, Next Queue, Score, Lines, Level, Time, Playfield, Active piece, Ghost piece. The only position it gives is that the Next Queue shows pieces "to be placed (generated) just above the Matrix". It gives no positions for hold, score, lines, level or time and no preview sizes. — [Hard Drop wiki: Game interface](https://harddrop.com/wiki/Game_interface)
- Search summaries of genre wikis and guides agree on behavior: one hold slot that can be used once per piece, and a next queue of up to 6 pieces. They do not set a canonical HUD position, so each game chooses its own. — [Hard Drop wiki: Guideline](https://harddrop.com/wiki/Guideline); [Gamertag blog: guideline explained](https://gamertagmythras.com/blog/tetris/tetris-guideline-explained)
- A developer adding hold to a hobby clone wrote that the HUD "must now have space for the HOLD slot" and moved it to the top-right. This shows hold placement is a space trade-off developers solve case by case. — [DEV Community: the hold piece](https://dev.to/xzzz3/tetris-development-5-the-hold-piece-4cmi)
- A commercial portrait-only block game says in its store listing that it is "Portrait-only for focused, one-handed gameplay", with an optional preview of the next 3 pieces "stacked above the board". — [App Store listing, Tetris Basic](https://apps.apple.com/is/app/tetris-basic/id6748584524) (via search snippet; page not fetched in full)
- An older licensed mobile version put hold in a box at the top-left that the player touches to hold. A review praised the "portrait-shaped (and fixed) game environment" as a good fit for phones. — [PlayStudios help: controls](https://playstudios.helpshift.com/hc/en/16-tetris-mobile/faq/2944-tetris-controls); [PocketGamer review](https://www.pocketgamer.com/tetris/tetris-mobile-review/) (both via search snippets)
- An open-source web clone's release notes say it replaced side HUDs with "a single horizontal chip at the top of the viewport" holding HOLD, score and NEXT, with the board below. This is a hobbyist data point, not a commercial one. — [GitHub: paulfxyz/tetris releases](https://github.com/paulfxyz/tetris/releases) (via search snippet)
- One indie portrait/landscape block game lets players move and resize on-screen controls in portrait, a sign that a single fixed arrangement does not suit every player. — [Falling Lightblocks devlog, Sep 2019](https://mrstahlfelge.itch.io/lightblocks/devlog/101862/adjustable-on-screen-controls)
- Thumb reach: in Hoober's study of 1,333 phone users, 49% held the phone one-handed, 36% cradled it and 15% used two hands. On larger screens the comfortable thumb zone stays about the same size while the hard-to-reach area grows, mostly at the top. — [Scott Hurff, Game Developer, 2014](https://gamedeveloper.com/design/how-to-design-for-thumbs-in-the-era-of-huge-screens)
- A 2024 AHFE paper on mobile game input says the "functional area of the thumb" differs between studies, age groups and thumb sizes, so there is no single reliable map of reachable zones. — [AHFE 2024: mobile game input unreachability](https://openaccess.cms-conferences.org/publications/book/978-1-964867-13-7/article/978-1-964867-13-7_13)

### Inferences
- Pattern A, a top strip above the well (hold on one side, next queue running horizontally or as a short stack, score in between). The well keeps nearly full width. The queue sits near the spawn point, which is where the eye already goes when a piece appears. The cost is a taller layout above the well, which shortens the well's height. The hold tap target ends up in the hardest-to-reach area for one-handed play. On a 20:9 screen with a 9x18 well (aspect 1:2), height is the tighter constraint, so the strip may not cost much. See the calculation in section 4.
- Pattern B, side columns (hold left, next right, or both on one side). This is the familiar console/landscape layout. In portrait it takes width directly from the well. Two columns of about 2.5 cells each would shrink a 9-wide well's cell size by roughly a third. Usually the worst choice for portrait.
- Pattern C, below the well. Hold sits in the thumb zone, which is good for a tappable hold. But the next queue ends up far from the spawn row, and a strip there competes with gesture-bar insets and any on-screen controls. It works well for hold and pause, poorly for next.
- Pattern D, overlaid on the well (the current Stack Drop approach). See section 5. Rows 0-3 at the top are the spawn and danger zone, so panels over the top corners cover exactly the area that matters most when the stack is high.
- A hybrid is common in the inferred design space and suits Stack Drop's constraints: next queue in a strip just above the well, near spawn. Hold as a large tap target in the lower corner or bottom strip, within thumb reach. Score and pause in a thin top bar inside the safe area.

### Gaps
- No primary design write-up, GDC talk or Game Developer article was found that compares portrait next/hold placements with measured data. The Game UI Database was not reachable as structured data in this session, so its puzzle-genre screenshots were not surveyed.
- No published figures were found for the share of phone puzzle games using each pattern.

## 2. How many previews in portrait, and at what scale

### Takeaway
Modern genre games show 3-6 previews, and some let the player set the count from 1 to 6 (one popular browser game defaults to 5). Older or simpler games show 1. No source gave a size ratio for preview cells. Rendering the first preview larger than the rest is common practice, but this research did not find a source for it.

### Cited Findings
- Next queue: 3 pieces in guideline games, 1 in older games, according to the interface page. — [Hard Drop wiki: Game interface](https://harddrop.com/wiki/Game_interface)
- "Most Guideline games show you a next queue of up to six pieces." — [Gamertag blog](https://gamertagmythras.com/blog/tetris/tetris-guideline-explained) (secondary blog)
- One popular browser versus game exposes next count as a setting, "1~6 (default 5)", and makes hold a toggle, "Yes (default)". — [tetris.wiki: TETR.IO](https://tetris.wiki/TETR.IO)
- A portrait-only mobile game shows 3 optional next pieces stacked above the board. — [App Store listing, Tetris Basic](https://apps.apple.com/is/app/tetris-basic/id6748584524) (via snippet)

### Inferences
- Stack Drop's 3-piece queue matches the portrait norm. 3 is enough for casual vs-CPU play and fits a top strip.
- Scale is a design choice. A reasonable starting point (not sourced) is the first preview at about 60-75% of the well's cell size and later previews at about 45-55%. On a 1080-px-wide screen with a 9-wide well at about 110 px per cell, a 3-wide piece at 60% is about 200 px wide. Three pieces in a row plus gaps come to about 650-700 px, which fits in a top strip beside a hold slot.

### Gaps
- No source found for preview cell size relative to well cell size (the 50-70% figure in the brief could not be confirmed or ruled out).
- The tetris.wiki "Next" page returned 404, so per-game preview-scaling details could not be checked.

## 3. Opponent board and incoming garbage in versus play

### Takeaway
The near-universal garbage convention is a vertical meter right beside the player's well, usually on the left in the cited examples. It fills with pending lines and changes color as they get closer to entering, and an extra warning can appear when an attack lands. Opponent boards are shown much smaller than the player's: either surrounding mini-boards in many-player modes, or a reduced board beside or above the player's in 1v1. No source gave a portrait-specific size ratio.

### Cited Findings
- Incoming garbage waits in a queue "shown as a red bar on the side of your board". Your own outgoing lines cancel incoming lines before anything is sent. — [Tetrowars wiki: How garbage works](https://tetrowars.com/wiki/garbage)
- Queued garbage enters at the bottom when the player places a piece without clearing a line, and the player's own clears can cancel pending lines first. — [tetris.wiki: Garbage](https://tetris.wiki/Garbage)
- In one browser game, queued lines show as "transparent yellow", then "transparent red", then "opaque red once active". Pop-up "damage numbers" appear when sending or blocking lines. A former yellow spike counter on the left of the board was removed in a later version, which suggests designers trim extra counters next to the well. — [tetris.wiki: TETR.IO](https://tetris.wiki/TETR.IO)
- In a 99-player battle game, the garbage meter sits to the left of the matrix. A warning also appears at the bottom of the screen when attacks are incoming, and pending lines are capped at 12. Sources disagree on the color order (one says grey, then yellow, then red; the Hard Drop wiki describes yellow for the first attack and grey for later ones). — [Hard Drop wiki: Tetris 99](https://www.harddrop.com/wiki/Tetris_99); [Gamertag strategy guide](https://gamertagmythras.com/blog/tetris/tetris-99-strategy-guide) (conflicting color order; secondary sources)
- Battle-royale layout: one central full-size playfield "surrounded by dozens of shrinking opponent boards". — [tetris.wiki: Tetris 99](https://tetris.wiki/Tetris_99) (via search snippet)
- In a mobile 1v1 game, a review notes the opponent's board is "on the other side of the screen". The snippet does not say the orientation or size. — [Gamezebo review: Tetris Battle Drop](https://www.gamezebo.com/reviews/tetris-battle-drop-review-get-used-to-it/) (via snippet)
- In a two-player-on-one-phone portrait block game, the opponent's grid is mirrored at the top of the screen while the player's grid is at the bottom. — [Android Police: Bit Bit Blocks](https://www.androidpolice.com/2016/09/08/bit-bit-blocks-fast-paced-puzzle-game-support-two-players-one-device/)

### Inferences
- For Stack Drop, the garbage meter belongs flush against one side of the well, as a thin column (about 0.3-0.5 cell wide) running the well's full height or its lower half, with segments sized in cell units. Then 1 pending line reads as 1 cell of meter. Escalating color and a short pulse on the well border when a batch arrives follow the eye-line guidance in section 6.
- For the CPU mini-view in portrait, the inferred options are:
  (a) A small board in the top bar beside score. Scale about 15-25% of the main well's cell size, so a 9x18 board is roughly 180-250 px tall on a 2400-px screen. Readable as a silhouette and doesn't cover the well.
  (b) A slim side strip with the mini-board on the side opposite the garbage meter. This costs well width.
  (c) An overlay in a corner of the well, which covers the spawn area (avoid).
  In 1v1, the player mostly needs to know the opponent's stack height and whether a big attack is coming. A silhouette or height bar at about 20% scale carries that information.

### Gaps
- No source gave the mini-board to main-board size ratio for any portrait game.
- No GDC or Game Developer write-up on versus-puzzle garbage UI was found.

## 4. Score, level, lines, timer and pause: placement, size, and density

### Takeaway
Genre sources list score, lines, level and time as standard HUD readouts but don't say where they go. Platform guidance gives concrete sizes for anything tappable: at least 48x48 dp on Android (44x44 pt on iOS), with about 8 dp spacing. Avoid edges and notches with safe-area insets. Persistent readouts at the screen edges are acceptable.

### Cited Findings
- Score, Lines (cleared, or remaining in sprint), Level and Time are standard readouts. — [Hard Drop wiki: Game interface](https://harddrop.com/wiki/Game_interface)
- In some modes of one browser game, extra counters sit on the left and right of the board, and lines remaining or time left sit "at the top of the board". A progress bar sits "under the board". — [tetris.wiki: TETR.IO](https://tetris.wiki/TETR.IO)
- Android touch targets should be at least 48x48 dp. Material says "48 x 48 dp minimum touch targets should be the default", and padding can enlarge the hit area without enlarging the icon. — [Google Accessibility Help: touch target size](https://support.google.com/accessibility/android/answer/7101858); [Material: applying density](https://material.io/design/layout/applying-density.html)
- WCAG 2.2 sets the floor at 24x24 CSS px for AA (2.5.8) and 44x44 for AAA (2.5.5). About 8 dp spacing between targets is a common rule of thumb, not a formal Material rule. — [TetraLogical: target size](https://tetralogical.com/blog/2022/12/20/foundations-target-size/)
- Game Accessibility Guidelines, Basic level: "Ensure interactive elements / virtual controls are large and well spaced, particularly on small or touch screens", "Use an easily readable default font size", and "Provide high contrast between text/UI and background". Intermediate level: "Allow interfaces to be resized" and "Allow interfaces to be rearranged". — [Game Accessibility Guidelines: full list](https://gameaccessibilityguidelines.com/full-list/)
- Notches, rounded corners and gesture bars cut into screen edges. Guides recommend anchoring the HUD to platform safe-area insets rather than hard-coded pixels, and adding extra bottom padding so buttons don't sit next to gesture zones. — [Game Developer: camera notch issues](https://www.gamedeveloper.com/game-platforms/mobile-games-issues-with-frontal-camera-notch); [Cursa: safe areas](https://cursa.app/en/page/mobile-screen-resolution-aspect-ratios-and-safe-areas)

### Inferences
- Sizing for a 1080x2400 (20:9) phone at about 2.6 px/dp (about 420 dpi): 48 dp is about 125 px, so the pause button and hold slot should each be at least about 125 px square.
- Vertical budget: a full-width 9-cell well at about 115 px per cell (1035 px wide) is 18 x 115 = 2070 px tall. That leaves about 330 px of 2400 for the status bar or notch inset (about 80-100 px), a top strip and a bottom strip. So the well cannot be both full width and have a usable top strip and bottom strip. Two options follow:
  (i) Shrink the cell to about 95-100 px. The well is then about 860-900 px wide (about 80-83% of the width) and 1710-1800 px tall. That frees about 500-600 px for a top strip (score, CPU mini-board, pause, next queue) and a bottom strip (hold), plus side gutters of about 90-110 px each. One gutter takes the garbage meter, the other can take a slim level/lines readout.
  (ii) Keep the well near full width and accept overlays. This is the current approach and what the user finds awkward.
- Density on small screens: combine score, lines and level into one compact row of label/value pairs in small caps. Hide secondary stats (lines, level) behind pause in vs mode, and keep only what changes decisions on screen (next, hold, garbage, opponent height).

### Gaps
- No survey data found on typical pause-button size or position (top-left or top-right) in phone puzzle games.

## 5. Is overlaying HUD panels on the well acceptable?

### Takeaway
No source endorses overlaying HUD on a puzzle well. Guidance agrees that UI should not cover elements the player must read or interact with, and that minor overlaps are tolerated only when they don't interfere. For a falling-block well, the top rows (spawn and top-out zone) are the most critical area at exactly the moments of highest pressure, so overlay panels there are a usability risk.

### Cited Findings
- A web-game platform's publishing requirement rejects games where "a significant area of any object is covered or it interferes with reading the element or interacting with it". Minor overlaps are allowed only if they "should not affect how the user interacts with the interface". — [Yandex Games requirement 1.10](https://yandex.com/dev/games/doc/en/requirements/1/10)
- A heuristic from a third-party streaming-overlay guide recommends 60-80% transparency for overlays and keeping them out of control areas entirely. It is low reliability and from another genre. — [BitTopup overlay guide](https://bittopup.com/article/Best-PUBG-Mobile-Overlay-Design-2025-Complete-Safe-Zone-Guide)
- One browser versus game removed a counter that sat beside the board (alpha 6.1.0). This is weak evidence that designers prune clutter around the field. — [tetris.wiki: TETR.IO](https://tetris.wiki/TETR.IO)

### Inferences
- Overlays are tolerable only where the well is almost always empty and the player does not need the information there. In a falling-block game the top rows fill exactly when the player is under pressure from garbage, so corner panels cover the cells that decide top-out. Translucency helps a little, but stacked 3D crystal blocks behind a translucent panel lose shape and edge contrast. That conflicts with the GAG Basic guideline on high UI/background contrast.
- If any overlay remains, collapse it when the stack reaches the top quarter, or move it out of the well's top 4 rows.

### Gaps
- No HCI or game-UX study on puzzle-well occlusion was found. The conclusion above is drawn from general guidance plus the genre's mechanics.

## 6. Design guidance: clarity, peripheral vision, an unobstructed field

### Takeaway
Two principles from accessibility and cognitive UX writing apply directly. Put temporary, essential warnings, such as an incoming garbage alert, near where the player is looking (the well), not in corners. Persistent readouts can sit at the edges because players learn where they are.

### Cited Findings
- Game Accessibility Guidelines, Intermediate: "Avoid placing essential temporary information outside the player's eye-line." Rationale: "Many vision impairments can result in loss of peripheral vision", so temporary elements at the edges "can easily be missed". Also: "arranging interface elements along the edges of a screen is fine" for persistent elements, and "audio cues alone are not sufficient". — [GAG: eye-line guideline](https://gameaccessibilityguidelines.com/avoid-placing-essential-temporary-information-outside-the-players-eye-line/)
- Celia Hodent (cognitive psychologist, former UX director at Epic Games) argues for conveying information where the player's eyes and attention already are, rather than making players search the corners. She also says removing the HUD doesn't automatically help, because it can raise cognitive load. Players often miss HUD elements in playtests because they lack the designers' context. — [Creative Bloq interview](https://www.creativebloq.com/features/how-neuroscience-and-ux-impacts-video-game-design) (article text could not be fetched in full; claims come from the search summary and should be checked against the original); [Game Developer: GDC UX masterclass](https://www.gamedeveloper.com/game-platforms/gdc-masterclass-on-ux-brings-psychology-into-game-development); book: *The Gamer's Brain* (CRC Press, 2017)
- Game Accessibility Guidelines also call for high-contrast UI against the background (Basic), adjustable contrast (Intermediate), and resizable or rearrangeable interfaces (Intermediate). — [GAG full list](https://gameaccessibilityguidelines.com/full-list/)
- A mobile puzzle UI course advises putting important buttons where they are easy to reach while keeping the most important content in the center and top. These two pull in opposite directions, so tappable controls belong low and read-only information high. — [GameInAI: mobile puzzle UI lesson](https://gamineai.com/courses/mobile-puzzle-game/lessons/lesson-6-mobile-ui-ux-design) (course material, moderate reliability)

### Inferences
- Applied to Stack Drop: the garbage meter and warning flash belong on the well's edge (in the eye-line). The next queue belongs at the well's top edge (near spawn). Score and the CPU mini-board can sit at the screen's top edge (persistent and learned). Hold and pause, as tappable controls, belong in the lower half or at least away from the top corners. Grouping by Gestalt proximity (Hodent recommends designers learn Gestalt principles) favors a clean top band and bottom band over corner panels floating on the well.
- An options toggle for HUD scale or for swapping hold to the left or right side would satisfy the GAG resize and rearrange items cheaply.

### Gaps
- No GDC Vault talk specifically about mobile falling-block or versus-puzzle UI was found in this pass.
- The Game UI Database (gameuidatabase.com) was not queried directly, so screenshot-level convention counts from it are missing.
