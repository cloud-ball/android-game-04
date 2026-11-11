# Ship Serpent Grid (v0.1.0): checklist

Goal this week: Pocket Arena 8 v0.1.0 (hub + Serpent Grid) live on Google Play **closed testing**.
New personal developer accounts must keep 12+ testers opted in for 14 continuous days before they can
apply for production, so public release is ~2 weeks after the closed test starts. Start it as early as possible.

## Done in the repo
- [x] Game, hub, saves, tests (37 headless tests green)
- [x] Debug APK runs on a real phone (Vivo V2250, Android 15, Adreno 642L)
- [x] Release AAB builds through Gradle: package com.cloud198.pocketarena8, minSdk 24, targetSdk 36,
      only VIBRATE permission
- [x] Store icon, feature graphic, 4 phone screenshots, listing text, privacy policy text, app-content answers

## You (one time)
1. **Upload key**: `scripts/make_upload_key.sh` → pick a strong password → back up the .jks + password.
   Then `export PA8_KEYSTORE=~/.android-keys/pocketarena8-upload.jks` in ~/.zshrc.
2. **Build**: `export GODOT=/opt/homebrew/bin/godot && scripts/build_release.sh`
   → `build/pocket-arena-8-v0.1.0-1.aab`. Use `--bump` for every later upload (version code must increase).
3. **Privacy policy URL**: put docs/store/privacy-policy.md somewhere public (fill in the support email first):
   GitHub Pages (needs a public repo or paid plan), a public GitHub Gist, or Google Sites.
4. **Play Console** → Create app: name "Pocket Arena 8", Game, Free, accept declarations.
   - Dashboard → Set up your app: privacy policy, app access, ads (No), content rating, target audience (13+),
     data safety (no data collected), store listing (docs/store/listing.md + images).
   - Testing → Closed testing → Create track → Testers: add a Google Group or an email list with 12+ (aim for 15–20,
     some drop out) → Create release → upload the AAB → let Google manage the app-signing key → roll out.
   - Send testers the opt-in link. They must **opt in and keep the app installed**; the 14-day clock counts days
     with 12+ opted-in testers.
5. **After 14 days**: Dashboard → Apply for production (answer the questions about testing) → production release.

## Every update
`scripts/build_release.sh --bump` → upload to the closed (or production) track → release notes.
Run the ip-checker subagent before each store release.
