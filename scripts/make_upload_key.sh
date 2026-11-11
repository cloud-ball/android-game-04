#!/usr/bin/env bash
# One-time: create the Google Play UPLOAD key (Play App Signing holds the real app-signing key).
# You choose the password at the prompt. Back up the .jks file and the password (password manager
# + an offline copy). If it is lost, Play support can reset the upload key, but it takes days.
# Usage: scripts/make_upload_key.sh [path]   (default ~/.android-keys/pocketarena8-upload.jks)
set -euo pipefail
dest="${1:-$HOME/.android-keys/pocketarena8-upload.jks}"
if [ -e "$dest" ]; then echo "$dest already exists - not overwriting."; exit 1; fi
mkdir -p "$(dirname "$dest")"
chmod 700 "$(dirname "$dest")"
keytool -genkeypair -v -keystore "$dest" -storetype PKCS12 -alias upload \
  -keyalg RSA -keysize 4096 -validity 10000
chmod 600 "$dest"
echo
echo "Created $dest"
echo "Add this to ~/.zshrc so scripts/build_release.sh finds it:"
echo "  export PA8_KEYSTORE=\"$dest\""
