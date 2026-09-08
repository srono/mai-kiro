#!/usr/bin/env bash
# capture-correction.sh — UserPromptSubmit hook.
# If the user's message looks like a correction or standing preference, append it
# (raw) to the append-only memory log. No keyword extraction, no matching — the
# reorg step (an agent action) is what turns this log into a consolidated doc.
# Always exits 0 (never blocks the prompt).
#
# Format written:  YYYY-MM-DDTHH:MM:SS | raw text

set -euo pipefail

INPUT=$(cat)
MSG=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")
[ -z "$MSG" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SCRIPT_DIR/../memory/log.md"
[ -f "$LOG" ] || exit 0

# Skip long pasted blocks — corrections/preferences are short.
LINE_COUNT=$(printf '%s' "$MSG" | wc -l | tr -d ' ')
[ "$LINE_COUNT" -gt 4 ] && exit 0

# Loose filter: does this look like a correction or a standing preference?
# We only decide WHETHER to keep the line here. WHAT it means is the reorg step's
# job — so this stays deliberately permissive.
FILTER_RE='(^|[^a-z])(no,|nope|wrong|incorrect|not (like )?that|don'"'"'t|do not|stop( doing| using)?|actually,|instead|should(n'"'"'t| not)? |must( not)? |never |always |avoid |prefer |use .* not |from now on|going forward|remember to|make sure|by default)'
printf '%s' "$MSG" | grep -Eiq "$FILTER_RE" || exit 0

# Skip pure questions (a "?" ending with no imperative signal).
if printf '%s' "$MSG" | grep -Eq '\?[[:space:]]*$' \
   && ! printf '%s' "$MSG" | grep -Eiq '(don'"'"'t|do not|instead|not that|use |avoid|prefer|always|never|must)'; then
  exit 0
fi

# Collapse to one line, trim length.
CLEAN=$(printf '%s' "$MSG" | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//;s/ *$//' | cut -c1-300)
[ -z "$CLEAN" ] && exit 0

# Cheap exact-dup guard against the immediately previous entry only (append-only
# otherwise — the reorg step does real de-duplication).
LAST=$(grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$LOG" 2>/dev/null | tail -1 | sed 's/^[^|]*| //' || true)
[ "$LAST" = "$CLEAN" ] && exit 0

printf '%s | %s\n' "$(date +%FT%T)" "$CLEAN" >> "$LOG"
exit 0
