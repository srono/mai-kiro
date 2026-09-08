#!/usr/bin/env bash
# inject-memory.sh — SessionStart (and UserPromptSubmit fallback) hook.
# Surfaces the consolidated memory document into the agent context. No matching —
# the whole current doc is injected, since reorg keeps it short. On exit 0,
# stdout is forwarded into the agent context.
#
# Dedup: injects at most once per session (SessionStart), or once per hour if
# wired to UserPromptSubmit, so it does not repeat on every prompt.

set -euo pipefail

# Drain stdin if present (UserPromptSubmit provides JSON; SessionStart may not).
INPUT=$(cat 2>/dev/null || true)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEM="$SCRIPT_DIR/../memory/memory.md"
[ -f "$MEM" ] || exit 0

# Skip if the doc has no real content beyond the header/marker.
CONTENT=$(grep -Ev '^(#|_Last reorg:|---|\s*$)' "$MEM" | grep -Ev '^Consolidated|^Empty until' || true)
[ -z "$CONTENT" ] && exit 0

# Per-context dedup so it doesn't repeat every prompt (60 min window).
WS_HASH=$(pwd | shasum 2>/dev/null | cut -c1-8 || echo default)
DEDUP="/tmp/mai-kiro-inject-${WS_HASH}.ts"
NOW=$(date +%s)
if [ -z "${MAI_INJECT_ALWAYS:-}" ] && [ -f "$DEDUP" ]; then
  LAST=$(cat "$DEDUP" 2>/dev/null || echo 0)
  if [ $((NOW - LAST)) -lt 3600 ]; then
    exit 0
  fi
fi
echo "$NOW" > "$DEDUP"

echo "📌 Project memory (from past sessions — apply what's still relevant):"
echo ""
cat "$MEM"
exit 0
