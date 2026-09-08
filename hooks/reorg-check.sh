#!/usr/bin/env bash
# reorg-check.sh — UserPromptSubmit hook (throttle) + manual trigger.
# Counts new entries in the memory log since the last reorg. When enough have
# accumulated, it emits an instruction telling the agent to consolidate the
# memory (per memory/reorg.md). The actual rewrite is done by the agent — this
# hook only decides WHEN.
#
# On exit 0, stdout is forwarded into the agent context.
#
# Threshold: MAI_REORG_THRESHOLD (default 10 new entries).
# Manual override: run `bash reorg-check.sh --force` to emit the trigger now.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEM_DIR="$SCRIPT_DIR/../memory"
LOG="$MEM_DIR/log.md"
COUNT_FILE="$MEM_DIR/.reorg-count"
THRESHOLD="${MAI_REORG_THRESHOLD:-10}"

FORCE=""
[ "${1:-}" = "--force" ] && FORCE=1

# Drain stdin (UserPromptSubmit provides JSON we don't need here).
cat >/dev/null 2>&1 || true

[ -f "$LOG" ] || exit 0

# Current number of timestamped entries in the log.
TOTAL=$(grep -cE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$LOG" 2>/dev/null || echo 0)

# Entry count at last reorg (0 if never).
LAST=0
[ -f "$COUNT_FILE" ] && LAST=$(tr -cd '0-9' < "$COUNT_FILE" 2>/dev/null || echo 0)
[ -z "$LAST" ] && LAST=0

NEW=$((TOTAL - LAST))
[ "$NEW" -lt 0 ] && NEW=0

if [ -z "$FORCE" ] && [ "$NEW" -lt "$THRESHOLD" ]; then
  exit 0
fi

# Nothing to consolidate.
[ "$TOTAL" -eq 0 ] && exit 0

REORG_DOC="$MEM_DIR/reorg.md"
cat <<EOF
🧠 Memory reorg due: $NEW new entr$( [ "$NEW" -eq 1 ] && echo y || echo ies ) in the log since the last consolidation (threshold $THRESHOLD).

Please consolidate the memory now, following the instructions in:
  $REORG_DOC

In short: read $LOG (read-only source of truth) and $MEM_DIR/memory.md, rewrite
memory.md so newer entries supersede older ones and duplicates are merged, append
a changelog line, and write the new log entry count ($TOTAL) to $COUNT_FILE.
EOF
exit 0
