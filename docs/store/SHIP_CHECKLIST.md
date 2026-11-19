# Ship Playjar v0.2.0: checklist

Goal: Playjar v0.2.0 (hub + Serpent Grid, Facetfall, Break & Bank, Cup Dash) live on Google Play
**closed testing**, then production. New personal developer accounts must keep 12+ testers opted in
for 14 days in a row before they can apply for production, so public release is ~2-3 weeks after
the closed test starts. Unfinished games stay hidden as "SOON" cards
(enabled=false) and arrive later as updates.

## Done in the repo (branch release-v0.2, 2026-11-17)
- [x] Golf renamed Fairway Flick -> **Cup Dash** before the first upload (2026-11-19): "Flick Golf!"
      is an existing golf game series; no app called "Cup Dash" was found on Google Play or the App
      Store (nearest: unrelated cup puzzles such as Cup Connect!, Cup Chase).
- [x] Three games enabled and green: all headless tests pass; build script refuses to build otherwise.
- [x] Break & Bank ball colours fixed (they rendered darker than designed).
- [x] Release AAB pipeline verified end to end with a THROWAWAY key (not uploadable; deleted from
      build/): signed bundle builds in ~1 min, `jarsigner -verify` passes, arm64-v8a + armeabi-v7a,
      minSdk 24, targetSdk 36 (meets Play's current requirement), version 0.2.0 / code 1,
      package com.cloud198.playjar, only the VIBRATE permission (no INTERNET).
- [x] Store listing for all three games: docs/store/listing.md (short description 79/80 chars,
      full 1.6k/4000), app-content answers re-checked (coins are earned only: no gambling).
- [x] 6 captioned phone screenshots, 1080x1920: docs/store/screenshots/ (made by
      docs/store/src/frame_shots.py from desktop captures; Roboto font, SIL OFL).
- [x] New feature graphic 1024x500 showing all three games: docs/store/feature_graphic_1024x500.png
      (source docs/store/src/feature_graphic.html, rendered with headless Chrome). The old one still
      showed the pool game's former name.
- [x] Release notes: docs/store/release_notes.md. Tester invitation: docs/store/tester_invite.md.
- [x] Originality check (ip-checker, 2026-11-17) over store text, graphics sources and in-game
      strings: no protected names anywhere; "Cue Club" gone from everything user-facing; store text
      says "eight-ball billiards" (not "8-ball pool"); icons, store images and Roboto recorded in
      ASSETS.md; in-app version now 0.2.0.
- [x] Names: the app is **Playjar** (2026-11-19, the user's pick; "a jar full of little games").
      History: Pocket Arena 8 (close to "Heroes: Pocket Arena" and a "Pocket Arena" monster game)
      → Octorival → Playjar. The block game is **Facetfall** (was Stack Drop: already a Play app
      title, com.rpm.stackdrop). Playjar and Facetfall had no exact match on Google Play, the App
      Store, Steam, itch.io or the web (nearest: "JarPlay", a J2ME emulator; two itch.io games
      called "Facet"). "Break & Bank" and "Serpent Grid" were clear. Package id
      com.cloud198.playjar, set before the first upload (it can never change after).
- [x] New original app icon: a glass jar with a gold lid holding a snake, a cut gem and a blue
      billiard ball (never a black 8-ball). Sources docs/store/src/icon_*.svg and icon.svg.
- [x] Facetfall look redone (was the ip-checker BLOCKER: flat classic-coloured squares in a gridded
      well): emerald-cut gems, a jewel palette where no shard keeps its shape's classic colour, a
      gridless crystal tower, and the same gems in HUD, how-to cards and hub icon. Screenshots 01,
      03, 06 and the feature graphic retaken.

## You (one time)
1. **Upload key**: `scripts/make_upload_key.sh` → pick a strong password → back up the .jks file AND
   the password (password manager + offline copy). Then add to ~/.zshrc:
   `export PA8_KEYSTORE=~/.android-keys/playjar-upload.jks`
2. **Build**: `export GODOT=/opt/homebrew/bin/godot && scripts/build_release.sh`
   → `build/playjar-v0.2.0-1.aab` (asks for the key password; runs the tests first).
   Version code 1 is right for the very first upload; use `--bump` for every later upload.
3. ~~Privacy policy URL~~ DONE 2026-11-19: **https://cloud-ball.github.io/privacy.html** (the Cloud198
   developer site, repo cloud-ball/cloud-ball.github.io; it has an Playjar section; Daily Drift was
   removed). Support email: cloud198games@gmail.com. Website: https://cloud-ball.github.io/
4. **Play Console** → Create app: name "Playjar", Game, Free, accept the declarations.
   - Dashboard → Set up your app: privacy policy URL (above), app access (all available), ads (No), content
     rating (questionnaire answers in listing.md), target audience (13+), data safety (no data
     collected or shared), store listing (listing.md text + icon_512.png + feature graphic +
     the 6 screenshots).
   - Testing → Closed testing → Create track → Testers: a Google Group or email list with 15-20
     people → Create release → upload the AAB → let Google manage the app-signing key → paste the
     release notes → Review → Roll out.
   - Send testers docs/store/tester_invite.md with the opt-in link. They must opt in and KEEP the
     app installed; the 14-day clock counts days with 12+ opted-in testers.
5. **After 14 days**: Dashboard → Apply for production (questions about the test) → production
   release.

## Every update
`scripts/build_release.sh --bump` → upload to the closed (or production) track → release notes.
Run the ip-checker subagent before each store release. Retake screenshots when a game changes look:
capture at `--resolution 1030x1832` (the Mac screen caps window height) with `--bot --autostart`,
then frame them with docs/store/src/frame_shots.py.
