#!/usr/bin/env bash
# uninstall.sh — remove mai-kiro hooks from a project's .kiro/hooks/.
#
# Usage:
#   bash mai-kiro/uninstall.sh [target-project-dir]
#
# Removes only the mai-kiro-*.json files this repo installed. Leaves your
# other hooks and your memory file untouched.

set -euo pipefail

TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"
HOOKS_DST="$TARGET/.kiro/hooks"

if [ ! -d "$HOOKS_DST" ]; then
  echo "Nothing to remove: $HOOKS_DST does not exist."
  exit 0
fi

removed=0
for f in "$HOOKS_DST"/mai-kiro-*.json; do
  [ -e "$f" ] || continue
  rm -f "$f"
  echo "    ✗ removed $f"
  removed=$((removed + 1))
done

if [ "$removed" -eq 0 ]; then
  echo "No mai-kiro hooks found in $HOOKS_DST."
else
  echo "✅ Removed $removed mai-kiro hook file(s). Restart your Kiro CLI session."
fi
