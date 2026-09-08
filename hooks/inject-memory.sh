#!/usr/bin/env bash
# inject-memory.sh — UserPromptSubmit hook.
# Scores stored memory entries by keyword overlap with the current message and
# prints the top matches. On exit 0, stdout is forwarded into the agent context.
#
# Config via env: MAI_MEMORY_MAX (default 3), MAI_MEMORY_MIN_SCORE (default 1).

set -euo pipefail

INPUT=$(cat)
MSG=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")
[ -z "$MSG" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEM="$SCRIPT_DIR/../memory/memory.md"
[ -f "$MEM" ] || exit 0

MAX="${MAI_MEMORY_MAX:-3}"
MIN_SCORE="${MAI_MEMORY_MIN_SCORE:-1}"

# Tokens from the user message (lowercase, >=4 chars, unique), space-joined.
MSG_TOKENS=$(printf '%s' "$MSG" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -cs 'a-z0-9_.-' '\n' \
  | awk 'length($0) >= 4' \
  | awk '!seen[$0]++' \
  | paste -sd' ' - 2>/dev/null || true)
[ -z "$MSG_TOKENS" ] && exit 0

# Score each memory entry by how many of its keywords appear in the message tokens.
RESULT=$(awk -v tokens="$MSG_TOKENS" -v maxn="$MAX" -v minscore="$MIN_SCORE" '
  BEGIN {
    n = split(tokens, arr, " ")
    for (i = 1; i <= n; i++) have[arr[i]] = 1
    FS = " \\| "
  }
  /^[0-9]{4}-[0-9]{2}-[0-9]{2} \| / {
    kw = $2; text = $3
    score = 0
    m = split(kw, kws, ",")
    for (i = 1; i <= m; i++) {
      k = kws[i]
      gsub(/^ +| +$/, "", k)
      if (k != "" && have[k]) score++
    }
    if (score >= minscore) {
      entries[++cnt] = score "\t" text
    }
  }
  END {
    # Simple insertion sort by score desc (entry counts are small).
    for (i = 1; i <= cnt; i++)
      for (j = i + 1; j <= cnt; j++) {
        si = entries[i]; sj = entries[j]
        split(si, a, "\t"); split(sj, b, "\t")
        if (b[1] + 0 > a[1] + 0) { tmp = entries[i]; entries[i] = entries[j]; entries[j] = tmp }
      }
    shown = 0
    for (i = 1; i <= cnt && shown < maxn; i++) {
      split(entries[i], a, "\t")
      print a[2]
      shown++
    }
  }
' "$MEM")

[ -z "$RESULT" ] && exit 0

echo "📌 Relevant memory from past sessions (apply if still applicable):"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  echo "- $line"
done <<< "$RESULT"

exit 0
