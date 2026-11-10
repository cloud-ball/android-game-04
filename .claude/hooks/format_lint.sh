#!/usr/bin/env bash
# PostToolUse hook: format + lint the .gd file Claude just edited. Lint errors exit 2 so Claude sees them.
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
case "$f" in *.gd) ;; *) exit 0 ;; esac
[ -f "$f" ] || exit 0
command -v gdformat >/dev/null 2>&1 && gdformat "$f" >/dev/null 2>&1
if command -v gdlint >/dev/null 2>&1; then out=$(gdlint "$f" 2>&1) || { echo "$out" >&2; exit 2; }; fi
exit 0
