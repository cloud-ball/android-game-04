#!/usr/bin/env bash
# Build the signed release AAB for Google Play: runs the headless tests first, then exports.
# Needs PA8_KEYSTORE (from scripts/make_upload_key.sh). The password is prompted for, or read
# from PA8_KEYSTORE_PASS. Nothing secret is written to the repo.
# Usage: scripts/build_release.sh [--bump]   (--bump increments version/code before building)
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$(command -v godot || true)}"
[ -x "$GODOT" ] || { echo "Set GODOT to the Godot 4.7 binary."; exit 1; }
: "${PA8_KEYSTORE:?Set PA8_KEYSTORE to your upload keystore (run scripts/make_upload_key.sh first)}"
[ -f "$PA8_KEYSTORE" ] || { echo "No keystore at $PA8_KEYSTORE"; exit 1; }
if [ -z "${PA8_KEYSTORE_PASS:-}" ]; then
  read -rsp "Upload keystore password: " PA8_KEYSTORE_PASS
  echo
fi

if [ "${1:-}" = "--bump" ]; then
  python3 -I - <<'EOF'
import re
p = "export_presets.cfg"
s = open(p).read()
s = re.sub(r"version/code=(\d+)", lambda m: "version/code=%d" % (int(m.group(1)) + 1), s)
open(p, "w").write(s)
EOF
fi
code=$(grep -m1 '^version/code=' export_presets.cfg | cut -d= -f2)
name=$(grep -m1 '^version/name=' export_presets.cfg | cut -d= -f2 | tr -d '"')

echo "Running headless tests..."
log=$(mktemp)
if ! ./addons/gdUnit4/runtest.sh --godot_binary "$GODOT" --headless --ignoreHeadlessMode \
    -a res://tests -a res://games >"$log" 2>&1; then
  tail -n 40 "$log"; rm -f "$log"; echo "Tests failed - not building."; exit 1
fi
rm -f "$log"

mkdir -p build
out="build/pocket-arena-8-v${name}-${code}.aab"
echo "Exporting $out ..."
GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PA8_KEYSTORE" \
GODOT_ANDROID_KEYSTORE_RELEASE_USER="${PA8_KEY_ALIAS:-upload}" \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PA8_KEYSTORE_PASS" \
  "$GODOT" --headless --path . --install-android-build-template --export-release "Android" "$out" \
  >build/export.log 2>&1 || { tail -n 30 build/export.log; echo "Export failed."; exit 1; }
[ -s "$out" ] || { tail -n 30 build/export.log; echo "Export produced no file."; exit 1; }
echo "Built $out (version $name, code $code). Upload it in Play Console > Testing > Closed testing."
