# Platform UI/UX guidelines for a mobile in-game HUD (Stack Drop): touch targets, text, contrast, safe areas, unit conversion

Researched 2026-11-12. Project context checked in repo: `project.godot` uses a base viewport of 1080x1920, `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"` and portrait orientation. `export_presets.cfg` has `screen/immersive_mode=true` and an empty `gradle_build/target_sdk` (Godot default). Because of `expand`, a portrait phone taller than 16:9 keeps the canvas **1080 units wide** and grows the height. A 20:9 phone gets a 1080 x 2400 canvas.

## Q1. Material Design 3 / Android accessibility: touch targets, spacing, text sizes (sp), minimum readable size, scaling

### Takeaway
Android's floor is a **48x48 dp touch target with at least 8 dp between targets**. The hit area may be larger than the visible element. For text, use sp units, keep **body text at 12 sp or larger**, and treat the M3 type scale as the reference: labelSmall 11 sp, bodySmall 12, bodyMedium 14, bodyLarge 16, titleLarge 22, headlineSmall 24, displaySmall 36.

### Cited Findings
- "we recommend that each interactive UI element have a focusable area, or touch target size, of at least 48dpx48dp. Larger is even better." Precise pointer input (mouse or trackpad) may use smaller targets. — [Android Developers: Make apps more accessible](https://developer.android.com/guide/topics/ui/accessibility/apps)
- "Ensure all touch targets are at least 48 dp, even if this extends past the UI element visual." — [Android Design: Accessibility](https://developer.android.com/design/ui/mobile/guides/foundations/accessibility)
- Google Accessibility Scanner help: targets should be at least 48 dp wide and tall and "separated by 8dp of space or more". It also says "A touch target of 48x48dp results in a physical size of about 9mm, regardless of screen size." TouchDelegate can enlarge a hit area without changing visuals. — [Android Accessibility Help: Touch target size](https://support.google.com/accessibility/android/answer/7101858)
- Text guidance: specify font sizes in sp so users can scale them, and "Don't make the body size any smaller than 12 sp. This guideline aligns with the Material typescale as a default." — [Android Design: Accessibility](https://developer.android.com/design/ui/mobile/guides/foundations/accessibility)
- Contrast on Android: "If the text is smaller than 18sp, or if the text is bold and smaller than 14sp", use at least 4.5:1. "For all other text", use at least 3:1. — [Android Developers: Make apps more accessible](https://developer.android.com/guide/topics/ui/accessibility/apps). Use 3:1 between surfaces and non-text elements such as icons. — [Android Design: Accessibility](https://developer.android.com/design/ui/mobile/guides/foundations/accessibility)
- M3 type scale from the Material Components for Android token file (`TextAppearance.M3.Sys.Typescale.*`), as size / line height in sp:
  - Display: Large 57/64, Medium 45/52, Small 36/44
  - Headline: Large 32/40, Medium 28/36, Small 24/32
  - Title: Large 22/28, Medium 16/24, Small 14/20
  - Body: Large 16/24, Medium 14/20, Small 12/16
  - Label: Large 14/20, Medium 12/16, Small 11/16 (labelSmall line height inferred from the M3 spec pattern; the file lists textSize for all 15 styles)

  — [material-components-android typography tokens.xml (master)](https://raw.githubusercontent.com/material-components/material-components-android/master/lib/java/com/google/android/material/typography/res/values/tokens.xml)

### Inferences
- **Godot does not use sp or the system font scale automatically.** Our Labels are sized in canvas units. To honor Android's font-size setting we would have to read it ourselves (for example through a small Android plugin reading `Configuration.fontScale`) or offer an in-game text-size option. The in-game option is what the game guidelines in Q6 recommend.
- Mapping the M3 scale onto the HUD: score and line digits fit titleLarge to headlineSmall (22 to 24 sp). Small captions such as "NEXT" and "HOLD" fit labelMedium to labelLarge (12 to 14 sp), with labelSmall 11 sp as the absolute floor. Banners such as "TETRIS-style clear" fit displaySmall to headlineLarge (32 to 36 sp). Don't use a game-protected name in a banner; per CLAUDE.md, use our own wording.
- Google's "about 9 mm" for 48 dp does not match nominal dp math. 1 dp = 1/160 in, so 48 dp = 0.3 in = **7.62 mm** nominally. Real phones differ from nominal because OEMs pick a rounded density bucket (see Q5). Treat 48 dp as roughly 7.6 to 9 mm.

### Gaps
- m3.material.io renders client-side and its pages (touch-target, typography, layout) returned no text to the fetch tool. The touch-target and type numbers above come from Android Developers pages and the Material Components token source, not the m3.material.io prose. I found no Material page that sets a "minimum readable text size" separate from the 12 sp body rule and the 11 sp labelSmall.
- I found no Material guidance written for game HUDs.

## Q2. Apple Human Interface Guidelines: 44x44 pt, text sizes, safe areas and Home indicator, game guidance

### Takeaway
On iOS, frequently used game controls should be **at least 44x44 pt**. Less important controls such as menus can go down to **28x28 pt**. Leave about **12 pt of padding around bezeled controls and about 24 pt around unbezeled ones**. Default text is **17 pt and the minimum is 11 pt**. Keep controls clear of the Home indicator and Dynamic Island by honoring the system safe area.

### Cited Findings
- HIG Accessibility (change log: March 7, 2025 rewrite; last entry June 9, 2025) lists default and minimum **control** sizes. iOS/iPadOS: 44x44 pt default, 28x28 pt minimum. macOS: 28x28 / 20x20. tvOS: 66x66 / 56x56. visionOS: 60x60 / 28x28. watchOS: 44x44 / 28x28. On spacing: "it works well to add about 12 points of padding around elements that include a bezel. For elements without a bezel, about 24 points of padding works well around the element's visible edges." — [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- The same page lists default and minimum **text** sizes. iOS/iPadOS: 17 pt / 11 pt. macOS: 13 / 10. tvOS: 29 / 23. visionOS: 17 / 12. watchOS: 16 / 12. It adds: "Ideally, give people the option to enlarge text by at least 200 percent". Thin-weight fonts should go larger than these sizes. — [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- Apple's contrast table follows WCAG AA. Text up to 17 pt, any weight: 4.5:1. Text of 18 pt or more: 3:1. Bold text at any size: 3:1. If the default falls short, provide a higher-contrast scheme when the user turns on Increase Contrast. — [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- iOS Dynamic Type at the default "Large" setting, in pt (size/leading): Large Title 34/41, Title 1 28/34, Title 2 22/28, Title 3 20/25, Headline 17/22 (semibold), Body 17/22, Callout 16/21, Subhead 15/20, Footnote 13/18, Caption 1 12/16, Caption 2 11/13. The typography change log's latest entry is December 16, 2025. — [Apple HIG: Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- On text-size changes in games: "in a game, people are often more interested in a character's dialog than in transient hit-damage values". Not every label has to scale. — [Apple HIG: Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- HIG Designing for games (change log: June 9, 2025):
  - "buttons in iOS must be at least 44x44 pt to accommodate touch interaction". The page repeats the text and control size tables.
  - "Integrate device features into your layout… rounded corners or a camera housing… relying on platform-provided safe areas when possible."
  - In-game menus must adapt to aspect ratios such as 16:10, 19.5:9 and 4:3.
  - "Make sure text is always legible… contrasts well with the background and uses at least the recommended minimum text size".

  — [Apple HIG: Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)
- HIG Game controls, Touch controls (change log: June 9, 2025):
  - "Make sure frequently used controls are a minimum size of 44x44 pt, and less important controls, such as menus, are a minimum size of 28x28 pt".
  - "position buttons where they don't overlap system features like the Home indicator or Dynamic Island… Place frequently used buttons near a player's thumb… Place secondary controls, like menus, at the top of the screen."
  - "Always include visible and tactile press states… such as a glow, that they can see even when their finger is covering the control."
  - Hide controls that are unavailable or irrelevant.

  — [Apple HIG: Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls)
- HIG Layout (latest change log entry: September 9, 2026, "Updated guidance to reflect current best practices"): "Respecting the safe area is essential to make sure system UI and hardware features like the Dynamic Island don't obstruct content and controls." — [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

### Inferences
- Apple's game advice fits our layout directly. Pause is a secondary "menu" control, so 28x28 pt at the top is the minimum, but 44 pt is better given our 48 dp Android floor. The tappable HOLD box is a frequent gameplay control, so it needs at least 44 pt, sits near the thumb and needs a press-state glow that stays visible beside the finger.
- To use one rule on both platforms, take max(48 dp, 44 pt). Both are roughly the same physical size (Q5), so **48 "logical units" covers both**.

### Gaps
- The HIG pages fetched here give no numeric safe-area insets for iPhones. The commonly cited values are about 34 pt for the bottom Home-indicator inset in portrait and about 47 to 62 pt at the top on notch or Dynamic Island models. I could not confirm them from an Apple source in this pass, so read them at runtime (Godot `DisplayServer.get_display_safe_area()`).
- The per-device specification tables (iPhone point widths such as 375, 390, 393, 402, 430 and 440 pt) live on a separate HIG page I did not extract. Treat those widths as unverified.

## Q3. WCAG 2.2 contrast and how game guidelines apply it to HUD text over animated 3D backgrounds

### Takeaway
Normal text needs **4.5:1** and large text (≥18 pt / 24 CSS px, or ≥14 pt bold) needs **3:1**. UI components and meaningful graphics need **3:1** against adjacent colors. On a moving 3D background, measure against the **lowest-contrast area** behind the element. The practical fixes are a solid or semi-opaque plate (scrim), a dual outline or stroke, and an optional high-contrast mode at **7:1**.

### Cited Findings
- WCAG 2.2 SC 1.4.11 Non-text Contrast (AA): "The visual presentation of the following have a contrast ratio of at least 3:1 against adjacent color(s)". This covers user interface components (visual information needed to identify components and their states) and graphical objects. Ratios are not rounded, so 2.999:1 fails. For multi-color or gradient areas, test "the least contrasting area". Text inside a graphic must meet 1.4.3. — [W3C Understanding SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)
- The 1.4.3 thresholds in platform form are 4.5:1 below 18 sp (or below 14 sp bold) and 3:1 otherwise. — [Android Developers](https://developer.android.com/guide/topics/ui/accessibility/apps); [Apple HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- WCAG 2.2 SC 2.5.8 Target Size (Minimum), AA: targets are "at least 24 by 24 CSS pixels", unless a 24 CSS px circle centered on each undersized target doesn't intersect another target. SC 2.5.5 (Enhanced) uses 44x44 CSS px. A CSS pixel is defined as a visual angle of about 0.0213°. — [W3C Understanding SC 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)
- Xbox Accessibility Guideline 102 (ms.date 2023-06-08, page updated 2026-06-17):
  - Standard text and visual elements that carry gameplay information need **4.5:1**. Large text and large visual elements need **3:1**. Inactive-element text needs **3:1**. A high-contrast mode should reach **7:1** for all UI elements.
  - "When text is displayed over a non-solid color background, the text contrast ratio should be measured between the text and the lowest contrasting area of the background."
  - Suggested fixes: "put a solid background behind any on screen text or give players the option to adjust the opacity of that background", player-selectable colors, a high-contrast mode, and "Add borders around text or elements".
  - Read the platform's high-contrast setting at launch.
  - The guideline cites a white-plus-black double outline on HUD symbols, which stays visible on both dark and light backgrounds.

  — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 101 cites black-outlined white prompt text that stays readable "regardless of the color of elements behind the text". — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- Apple: if default contrast is insufficient, provide a higher-contrast scheme when Increase Contrast is on. — [Apple HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

### Inferences
- In Stack Drop, the score bar, NEXT and HOLD labels and the CPU mini-board sit over a tower of bright, animated crystal blocks. Under the "lowest-contrast area" rule, white text over a white or cyan crystal flash fails. Recommended defaults:
  1. A dark panel at about 60 to 80% opacity behind HUD text. The slim see-through side panels from commit 8e9ad99 need enough opacity that the brightest block color still gives 4.5:1 against the text.
  2. A 2 to 4 canvas-unit dark outline on HUD numerals.
  3. A 3:1 border or outline on the HOLD box and pause button so the controls themselves meet 1.4.11.
- A quick check: with a dark scrim of opacity α over the brightest background (luminance L_bg), the effective background luminance is about (1−α)·L_bg + α·L_scrim. Pick α so that (L_text+0.05)/(L_eff+0.05) ≥ 4.5. For white text (L = 1.0) over a pure white flash (L = 1.0) with a black scrim, α ≥ about 0.79 gives 4.5:1, and α ≥ about 0.70 gives 3:1 for large text. These figures come from the WCAG relative-luminance formula, calculated here; they are not from a source.

### Gaps
- I did not fetch the WCAG 2.2 Understanding page for SC 1.4.3 directly. The 4.5:1 / 3:1 and 18 pt / 14 pt bold values come from the Android and Apple pages, which state they follow WCAG AA.
- W3C offers no specific guidance on text over moving video or 3D. XAG 102's "lowest contrasting area" rule is the closest authoritative statement.

## Q4. Android display cutouts, gesture navigation, edge-to-edge (SDK 35/36) and immersive mode

### Takeaway
Any app targeting SDK 35 is forced edge-to-edge on Android 15+. **From SDK 36 the opt-out is gone on Android 16 devices.** Google Play has required SDK 36 for new apps and updates since **2026-08-31**. A full-screen Godot game is therefore always edge-to-edge and must keep HUD and controls out of three inset areas: system bars, the display cutout and the system gesture zones. Do this by reading insets at runtime rather than hard-coding them.

### Cited Findings
- "Once you target SDK 35 or higher on a device running Android 15 or higher, your app is displayed edge-to-edge." The doc defines three inset types:
  - **System bars insets**, "best for views that are tappable and that must not be visually obscured"
  - **Display cutout insets**
  - **System gesture insets**, "areas used by the system that take priority over your app", with common uses including "swiping in games". On Android 10+ they "contain a bottom inset for the home gesture, and a left and right inset for the back gestures".

  In desktop windowing mode, the caption bar "is always visible… even for game apps in immersive mode". — [Android Developers: Edge-to-edge (Views)](https://developer.android.com/develop/ui/views/layout/edge-to-edge)
- Android 16 behavior changes (targetSdk 36): "`R.attr#windowOptOutEdgeToEdgeEnforcement` is deprecated and disabled, and your app can't opt-out of going edge-to-edge" on Android 16 devices. The opt-out still works on Android 15 devices. — [Android 16 behavior changes](https://developer.android.com/about/versions/16/behavior-changes-16)
- The same page says that on displays with sw ≥ 600 dp (tablets, unfolded foldables), apps targeting 36 have their orientation, resizability and aspect-ratio restrictions ignored. **Games are exempt**, "based on the `android:appCategory` flag". — [Android 16 behavior changes](https://developer.android.com/about/versions/16/behavior-changes-16)
- Display cutouts: with `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES`, content extends into the cutout on the short edge. For apps targeting SDK 35, `LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER` is treated as `ALWAYS` for non-floating windows. This comes from the search summary of the doc, which I did not fetch in full. — [Android Developers: Support display cutouts](https://developer.android.com/guide/topics/display-cutout)
- Google Play target API: new apps and updates must target Android 16 (API 36) from August 31, 2026. Existing apps must target API 35 or higher to remain available to users on newer Android versions. — [Play Console Help: Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-419); [Android Developers: Target SDK](https://developer.android.com/google/play/requirements/target-sdk)
- Typical inset sizes:
  - The classic Material spec gives the Android status bar as **24 dp**. — [Material Design (M2) Android bars](https://material.io/design/platform-guidance/android-bars.html)
  - AOSP framework diffs show the 3-button nav bar frame at **48 dp** and the gestural-navigation gesture area at **32 dp**. Another diff changes a gestural `navigation_bar_height` from 16 dp to 24 dp. — [/e/OS mirror of AOSP frameworks/base commit](https://gitlab.e.foundation/e/os/android_frameworks_base/-/commit/72caa8e573a166cadc36bdfd93dcd1e1a5a6b976) (secondary mirror; context of each value not fully clear)
  - Several sources say not to hard-code these and to read WindowInsets instead. — [Android Developers: Compose insets](https://developer.android.com/jetpack/compose/layouts/insets)
- Godot 4.7 Android export options:
  - `screen/edge_to_edge`: "makes the navigation and status bars translucent and allows the application content to extend edge to edge". Developers "should ensure that none of the application content is occluded by system elements" by using `DisplayServer.get_display_safe_area()` and `DisplayServer.get_display_cutouts()`.
  - `screen/immersive_mode`: "hides the navigation and status bar"; change it at runtime with `DisplayServer.window_set_mode()`.

  — [Godot 4.7 docs: EditorExportPlatformAndroid](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html)
- Godot engine commits in mid-2025: "Android: Fix DisplayServer.get_display_safe_area() issues" (June 2025) and "Android: Don't exclude display cutout in immersive mode" (July 2025). — [Godot commit mirror](https://remotebranch.eu/Stowage/godot/commits/commit/53be3b78d1634406f1fb29e3802c608a5f5104a1/platform/android/java) (mirror, not the official GitHub; the search summary did not tie each date to a release)

### Inferences
- **What this means for Stack Drop:**
  - We already set `screen/immersive_mode=true`, so the status and navigation bars are hidden, but the **cutout (punch-hole camera) still intrudes** at the top. Since mid-2025 Godot no longer excludes the cutout in immersive mode, so the canvas draws under it. The score bar and pause button must start below `get_display_safe_area().position.y`, converted to canvas units.
  - **Gesture zones still apply in immersive mode.** The bottom home swipe and the left and right back swipes run from the screen edges. A first edge swipe usually reveals the transient bars. Keep the HOLD box, any swipe-to-move or hard-drop region, and banners' dismiss taps out of the bottom gesture strip (about 24 to 32 dp) and away from the extreme left and right edges.
  - Set `android:appCategory="game"` so the Android 16 large-screen orientation override doesn't apply. That keeps us portrait-locked on foldables and tablets.
- The current `gradle_build/target_sdk=""` leaves the target SDK to the Godot 4.7 default. Before a Play upload, confirm it is at least 36, which is required for updates after 2026-08-31.
- Rough budget for a 20:9 phone at 1080x2400 canvas with about 411 dp width (2.63 canvas units per dp, see Q5):
  - Top: a punch-hole status area of about 24 to 50 dp ≈ **63 to 130 canvas units**.
  - Bottom: a gesture strip of about 24 to 32 dp ≈ **63 to 84 canvas units**.
  - Treat these as fallbacks only; use runtime insets where available.

### Gaps
- I found no authoritative survey of status-bar or cutout heights in dp on current 20:9 phones (Vivo, Samsung, Pixel, 2025 to 2026). Values vary by OEM and by camera hole. Measure on the test phone: log `DisplayServer.get_display_safe_area()` and `get_display_cutouts()` in px, or run `adb shell dumpsys window | grep -i inset`.
- The back-gesture side inset width and the system-gesture-exclusion limit (commonly recalled as a 200 dp vertical cap per edge for `setSystemGestureExclusionRects`) were not verified in this pass. Godot does not expose exclusion rects directly as far as I found.
- I did not confirm the Godot 4.7 default `target_sdk` value.

## Q5. Conversion formulas: dp to px, dp/pt to mm, dp to our 1080-wide canvas units (with table)

### Takeaway
**Canvas units per dp = 1080 / (screen width in dp).** This is independent of pixel density, because `canvas_items` + `expand` scales the 1080-wide canvas to the full screen width. On a 411 dp-wide phone, **1 dp ≈ 2.63 canvas units, so 48 dp ≈ 126 units**. Size against the **narrowest supported phone (360 dp → 3.0 units/dp, 48 dp = 144 units)** so minimum sizes hold on every device.

### Cited Findings
- 1 dp is a density-independent pixel; Android sizes touch targets in dp and text in sp. — [Android Developers: accessibility apps](https://developer.android.com/guide/topics/ui/accessibility/apps); [Android Design: Accessibility](https://developer.android.com/design/ui/mobile/guides/foundations/accessibility)
- Android: 48x48 dp is "about 9mm" physically. — [Android Accessibility Help](https://support.google.com/accessibility/android/answer/7101858)
- Our project scales a 1080x1920 base with `canvas_items` / `expand`. Checked in `/Users/sandeep/Documents/GitHub/android-game-04/project.godot`.

### Inferences
**Formulas** (standard Android definitions: px/dp = densityDpi / 160, with 160 dpi as the baseline):

- `px = dp × (densityDpi / 160)`. The ratio `densityDpi/160` is the "density" scale, e.g. 2.625, 3.0 or 3.5.
- `dp_width = screen_px_width / (densityDpi / 160)`
- `canvas_units_per_px = 1080 / screen_px_width`, so `canvas_units = dp × (densityDpi/160) × 1080 / screen_px_width = dp × 1080 / dp_width`
- Canvas height on a phone with aspect H:W is `1080 × H/W`. That gives 20:9 → 2400 units, 19.5:9 → 2340, 16:9 → 1920.
- Nominal physical size: `mm = dp × 25.4 / 160 = dp × 0.15875`, so 48 dp ≈ 7.62 mm. Actual physical size: `mm = px × 25.4 / panel_ppi`.
- iOS points: on @3x iPhones, 1 pt = 3 px. The physical size of a point varies by panel (about 1/150 to 1/163 in), so 44 pt ≈ 6.9 to 7.5 mm, which is comparable to 48 dp.

**Checking the test-device numbers in the brief.** A 1260x2800 panel at 6.6 in has a diagonal of √(1260² + 2800²) = 3070.5 px, so **≈ 465 ppi**.

- "411 dp wide" and "2.625 px/dp" can't both be true for a **1260-px** panel. 1260 / 411 = **3.07 px/dp** (densityDpi ≈ 490), while 1260 / 2.625 = **480 dp**. The figure 2.625 px/dp × 411 dp = 1079 px describes a 1080-px-wide phone such as a Pixel at 420 dpi.
- Coincidentally, **1080 / 411 = 2.628 canvas units per dp**, so "2.625" is correct as *canvas units per dp* on a 411-dp phone.
- Most 1260-px OEM panels ship with densityDpi 480 (3.0 px/dp → 420 dp wide) or a value near it, and the user's "Display size" setting changes this. Read the real value with `adb shell wm size` and `adb shell wm density`, then compute dp_width = 1260 × 160 / density.
- Physical width of a 1260 px panel at 465 ppi = 2.71 in = **68.8 mm**, so 1 canvas unit ≈ 0.0637 mm and 1 mm ≈ 15.7 units.
  - 48 dp at 420 dp-wide ≈ 7.9 mm ≈ 123 units.
  - At 411 dp-wide ≈ 8.0 mm ≈ 126 units.
  - Google's "≈9 mm" for 48 dp would be ≈ 141 units on this phone.

**Conversion table: canvas units (1080-wide canvas) for common sizes**

| Phone width | units per dp | 8 dp gap | 11 sp (M3 labelSmall / iOS min) | 12 sp (Android body min) | 14 sp | 16 sp | 17 pt (iOS body) | 24 dp | 28 pt (iOS min ctrl) | 44 pt | 48 dp |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 360 dp | 3.000 | 24 | 33 | 36 | 42 | 48 | 51 | 72 | 84 | 132 | **144** |
| 393 dp | 2.748 | 22 | 30 | 33 | 38 | 44 | 47 | 66 | 77 | 121 | **132** |
| 411 dp | 2.628 | 21 | 29 | 32 | 37 | 42 | 45 | 63 | 74 | 116 | **126** |
| 430 dp | 2.512 | 20 | 28 | 30 | 35 | 40 | 43 | 60 | 70 | 111 | **121** |

The pt columns assume 1 pt ≈ 1 dp for sizing parity, and sp = dp at the default font scale of 1.0. Godot font size is the em size in canvas units, comparable to sp.

- **Design rule:** use the 360 dp column as the minimum.
  - Pause button and HOLD box: at least **144 x 144 hit area**.
  - Gaps between tappable elements: at least **24 units**.
  - Smallest label (NEXT/HOLD caption): at least **36 units**.
  - Score digits: about **66 to 72 units** (22 to 24 sp).
  - Banners: about **96 to 108 units** (32 to 36 sp).
- The visual element can be smaller than the hit area. Enlarge the Control's rect or use an invisible hit Control, which is the Godot equivalent of TouchDelegate.

### Gaps
- I found no source giving the exact densityDpi Vivo ships on its 1260x2800 6.6-inch models. Measure it on the device.
- The iOS pt-to-mm figures are calculated estimates, not from a sourced device table.

## Q6. Game accessibility guidelines: minimum font size in mobile games and HUD element sizing

### Takeaway
Game-specific guidelines set **higher** text floors than the app guidelines and ask for **player-adjustable text up to 200%**. XAG 101's mobile figure (18 px at 100 DPI, scaling linearly) is a physical size of about **4.6 mm body height**, which is much larger than Android's 12 sp. It is aimed at Xbox Game Streaming. GAG recommends a large default plus a font-size option.

### Cited Findings
- Xbox Accessibility Guideline 101, Text display (ms.date 2022-05-09, page updated 2026-06-17). Minimum **default** text size, measured as **body height** (top of the ascender to the bottom of the descender):
  - Console: 26 px at 1080p
  - PC/VR: 18 px at 1080p
  - **Mobile/Xbox Game Streaming: 18 px at 100 DPI, 36 px at 200 DPI, 72 px at 400 DPI, "Scale linearly as DPI increases"** ("a 5.5" screen with a 1080p resolution is roughly 400 DPI")
  - Text inside icons and glyphs must meet the same minimum, and icons should scale with text up to 200%.
  - "Players should be able to resize text up to 200 percent of the minimum font sizes… without the loss of content". Scaling below the minimum is fine at the player's choice.
  - "Platform-provided screen magnification tools aren't an appropriate mitigation for small text size."
  - Provide at least one sans-serif option, and use sentence case for lines of text; one- or two-word labels are exempt.

  — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- XAG 102 defines **large text on mobile/Xbox Game Streaming** as 36 px at 100 DPI, 72 px at 200 DPI and 144 px at 400 DPI, scaling linearly. Large text qualifies for the 3:1 contrast threshold. — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- Game Accessibility Guidelines, "Use an easily readable default font size": the only number given is "28px minimum when viewed on a 1080p screen" (from Amazon's TV 10-foot UI guidelines), described as matching 20/20 Snellen acuity at average screen size. Use it "as a minimum rather than a target". The page gives **no separate mobile figure**. Its ideal is "Allowing a choice of font size". — [GAG: easily readable default font size](https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/)
- Apple: offer at least 200% text enlargement through Dynamic Type or custom UI; Apple's Unity plug-in supports Dynamic Type in games. — [Apple HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility); [Apple HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)

### Inferences
- **Converting the XAG mobile minimum for the test phone.** At 465 ppi: 18 px × 465 / 100 ≈ 84 px body height ≈ 4.57 mm. At 1260 / 1080 = 1.167 px per canvas unit, that is **≈ 72 canvas units of ascender-to-descender height**. For typical sans fonts the body height is about 0.9 to 1.0 em, so this corresponds to a Godot font size of about **72 to 80 units (≈ 27 to 30 dp)**.
  - This is about 2× the Android body minimum, so it fits score numerals and banners better than every caption.
  - Treat XAG mobile as the target for **critical gameplay text** (score, lines, countdowns, banners), and the M3/HIG floors (11 to 12 sp, ≈ 33 to 36 units at 360 dp) as the hard floor for small captions.
  - Note the conflict between the sources: XAG's mobile number is written for streamed console UIs, while Android and Apple set much smaller app minimums.
- XAG large text on mobile (36 px at 100 DPI ≈ 9.1 mm body height ≈ 144 units on this phone) is the size where 3:1 contrast becomes acceptable. Below that, HUD text needs 4.5:1.
- HUD sizing summary for the Stack Drop redesign, synthesized from all sources:
  - Pause button and HOLD box: hit area ≥ 48 dp (≥ 144 units at a 360 dp width), with ≥ 8 dp (24 units) of space between them.
  - HOLD gets a visible press glow; pause sits at the top, below the safe area.
  - The NEXT queue and CPU mini-board are display-only, so they have no target minimum. Their text and key graphics still need 4.5:1 (text) and 3:1 (piece outlines against the board).
  - Add an in-game "Text size" option (100 / 150 / 200%) to meet the XAG, HIG and GAG scaling advice, because Godot won't pick up the system font scale automatically.

### Gaps
- I found no mobile-specific numeric font minimum on gameaccessibilityguidelines.com. Its 28 px @ 1080p figure is for TV viewing.
- I found no official Google Play guidance on HUD sizes for games beyond the general 48 dp and 12 sp rules.
