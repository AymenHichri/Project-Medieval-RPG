#!/usr/bin/env bash
# Full project check (WSL/Linux): source-asset checksums, import + parse check, tests.
#   GODOT=/path/to/Godot_console.exe tools/check.sh [--filter=<test substring>]
set -uo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-/mnt/c/Users/AymenH/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
if command -v wslpath >/dev/null 2>&1; then PROJECT="$(wslpath -w "$PWD")"; else PROJECT="$PWD"; fi
PY="${PYTHON:-python3}"
LOG="$(mktemp)"
status=0

echo "== 1/4 source assets unchanged"
"$PY" -I tools/verify_source_assets.py || status=1

echo "== 2/4 dfgui 2x copies"
if [ ! -d assets/vendor/dfgui/2x ]; then
  "$GODOT" --headless --path "$PROJECT" -s res://tools/upscale_ui.gd || status=1
fi

echo "== 2b/4 audio copies (tools/import_audio.py; not in git)"
"$PY" -I tools/import_audio.py --if-missing | grep -v "^  ok" || status=1

echo "== 3/4 import + parse check"
"$GODOT" --headless --path "$PROJECT" --import >"$LOG" 2>&1
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script" "$LOG"; then
  echo "parse errors found during import"; status=1
fi

echo "== 4/4 tests"
"$GODOT" --headless --path "$PROJECT" -s res://tests/test_runner.gd -- "$@" 2>&1 | grep -vE "^Godot Engine|^$"
[ "${PIPESTATUS[0]}" -eq 0 ] || status=1

rm -f "$LOG"
if [ $status -eq 0 ]; then echo "CHECK PASSED"; else echo "CHECK FAILED"; fi
exit $status
