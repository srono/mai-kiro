#!/usr/bin/env bash
# capture-correction.sh — UserPromptSubmit hook.
# If the user's message looks like a correction, append it to memory/memory.md.
# Always exits 0 (never blocks the prompt).
#
# Format written:  YYYY-MM-DD | keyword,list | correction text

set -euo pipefail

INPUT=$(cat)
MSG=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")
[ -z "$MSG" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEM="$SCRIPT_DIR/../memory/memory.md"
[ -f "$MEM" ] || exit 0

# Only capture single-line-ish corrections; skip long pasted blocks.
LINE_COUNT=$(printf '%s' "$MSG" | wc -l | tr -d ' ')
[ "$LINE_COUNT" -gt 4 ] && exit 0

# Correction signals (case-insensitive). Add your own phrases here.
CORRECTION_RE='(^|[^a-z])(no,|nope|wrong|incorrect|not (like )?that|don'"'"'t|do not|stop|actually,|instead|should(n'"'"'t| not)? |never |always |use .* not |prefer )'

printf '%s' "$MSG" | grep -Eiq "$CORRECTION_RE" || exit 0

# Skip pure questions — a "?" with no imperative is usually not a correction.
if printf '%s' "$MSG" | grep -Eq '\?[[:space:]]*$' && ! printf '%s' "$MSG" | grep -Eiq '(don'"'"'t|do not|instead|not that|use )'; then
  exit 0
fi

# Extract keywords: lowercase words >=4 chars, drop common stopwords, keep up to 6.
STOP='^(the|and|for|you|your|with|that|this|dont|does|use|used|using|always|never|should|instead|actually|stop|wrong|nope|from|into|when|what|have|has|are|was|were|will|would|could|about|there|their|them|then)$'
KEYWORDS=$(printf '%s' "$MSG" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -cs 'a-z0-9_.-' '\n' \
  | awk 'length($0) >= 4' \
  | grep -Eiv "$STOP" \
  | awk '!seen[$0]++' \
  | head -6 \
  | paste -sd, - 2>/dev/null || true)
[ -z "$KEYWORDS" ] && KEYWORDS="misc"

# Collapse the message to one line and trim length.
CLEAN=$(printf '%s' "$MSG" | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//;s/ *$//' | cut -c1-200)

# Dedup: skip if this exact text is already stored.
if grep -Fq "| $CLEAN" "$MEM" 2>/dev/null; then
  exit 0
fi

printf '%s | %s | %s\n' "$(date +%F)" "$KEYWORDS" "$CLEAN" >> "$MEM"
exit 0
