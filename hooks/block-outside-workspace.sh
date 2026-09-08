#!/usr/bin/env bash
# block-outside-workspace.sh — PreToolUse gate.
# Blocks shell commands that write to absolute paths outside the workspace.
# exit 2 = block; anything else = allow.
#
# Honest limitation: heuristic. It inspects redirections and common write
# commands for absolute paths that escape the workspace root. It does not
# parse the shell — creative constructs can evade it.

set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .toolInput.command // ""' 2>/dev/null || echo "")
[ -z "$CMD" ] && exit 0

# Workspace root: prefer git toplevel, fall back to cwd.
WS=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

NORM=$(printf '%s' "$CMD" | tr -s '[:space:]' ' ')

deny() {
  echo "🚧 BLOCKED: command appears to write outside the workspace: $1" >&2
  echo "Workspace root is: $WS" >&2
  echo "Keep writes inside the workspace, or run this yourself if intended." >&2
  exit 2
}

# Collect candidate absolute paths that are write targets:
#   redirections:  > /abs  >> /abs
#   write cmds:    tee /abs   cp/mv ... /abs   touch /abs   mkdir /abs
CANDIDATES=$(printf '%s' "$NORM" | grep -oE '(>>?|(\b(tee|touch|mkdir)\b)) +/[^ ]+' | grep -oE '/[^ ]+' || true)
# Also catch install-style absolute targets after cp/mv (last arg heuristic is hard; keep simple).

[ -z "$CANDIDATES" ] && exit 0

while IFS= read -r p; do
  [ -z "$p" ] && continue
  # Allow well-known safe scratch areas.
  case "$p" in
    /tmp/*|/dev/null|/dev/stdout|/dev/stderr) continue ;;
  esac
  # Resolve to an absolute, normalized form (path may not exist yet).
  case "$p" in
    "$WS"|"$WS"/*) continue ;;  # inside workspace → allow
    /*) deny "$p" ;;            # absolute and outside → block
  esac
done <<< "$CANDIDATES"

exit 0
