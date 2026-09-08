#!/usr/bin/env bash
# block-secrets.sh — PreToolUse gate.
# Blocks git commit/push when the staged diff contains obvious secrets.
# exit 2 = block; anything else = allow.
#
# Honest limitation: pattern-based. Catches common key shapes, not everything.

set -euo pipefail

INPUT=$(cat)

# Extract the shell command the agent is about to run.
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .toolInput.command // ""' 2>/dev/null || echo "")

# Only care about git commit / git push.
case "$CMD" in
  *"git commit"*|*"git push"*) : ;;
  *) exit 0 ;;
esac

# Grab the staged diff. If not in a git repo or nothing staged, allow.
DIFF=$(git diff --cached 2>/dev/null || true)
[ -z "$DIFF" ] && exit 0

# Secret patterns. Extend for your own stack.
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                                  # AWS access key id
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'                # private keys
  'gh[pousr]_[A-Za-z0-9]{36,}'                         # GitHub tokens
  'xox[baprs]-[A-Za-z0-9-]{10,}'                       # Slack tokens
  'sk-[A-Za-z0-9]{20,}'                                # OpenAI-style keys
  'AIza[0-9A-Za-z_-]{35}'                              # Google API key
  '(secret|password|passwd|api[_-]?key|token)[[:space:]]*[:=][[:space:]]*['"'"'"][^'"'"'"]{8,}' # generic assignment
)

for pat in "${PATTERNS[@]}"; do
  if printf '%s' "$DIFF" | grep -Eiq -e "$pat"; then
    echo "🔒 BLOCKED: staged changes appear to contain a secret (matched pattern: /${pat}/)." >&2
    echo "Remove it from the diff (git restore --staged <file>), move it to an env var or secret store, then retry." >&2
    exit 2
  fi
done

exit 0
