#!/usr/bin/env bash
# Stop hook: keep Claude working while the headless GdUnit4 suite fails. Exits 0 when stop_hook_active (no loops)
# or before the Godot project is scaffolded.
input=$(cat)
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then exit 0; fi
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
[ -f project.godot ] || exit 0
[ -x addons/gdUnit4/runtest.sh ] || exit 0
GODOT="${GODOT:-godot}"; log=$(mktemp)
if ./addons/gdUnit4/runtest.sh --godot_binary "$GODOT" -a res://tests -a res://games >"$log" 2>&1; then rm -f "$log"; exit 0; fi
tail -n 60 "$log" >&2; rm -f "$log"
echo "Headless tests failed: fix them before finishing. Do not weaken or delete tests." >&2
exit 2
