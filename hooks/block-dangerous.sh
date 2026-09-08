#!/usr/bin/env bash
# block-dangerous.sh — PreToolUse gate.
# Blocks a small set of genuinely destructive shell commands.
# exit 2 = block; anything else = allow.
#
# Honest limitation: this is a speed bump, not a sandbox. Obfuscated variants
# (rm -r -f, $(echo rm), aliases) can slip through. It stops the accidental
# catastrophe, not a determined one.

set -euo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .toolInput.command // ""' 2>/dev/null || echo "")
[ -z "$CMD" ] && exit 0

# Normalize whitespace to make matching a little less brittle.
NORM=$(printf '%s' "$CMD" | tr -s '[:space:]' ' ')

deny() {
  echo "💥 BLOCKED: command matched a dangerous pattern: $1" >&2
  echo "If you genuinely intend this, run it yourself outside the agent." >&2
  exit 2
}

# Destructive recursive deletes of root/home.
printf '%s' "$NORM" | grep -Eq 'rm +-[a-z]*r[a-z]* +(-[a-z]+ +)*(/|~|\$HOME|/\*)( |$)' && deny "recursive delete of / or ~"
printf '%s' "$NORM" | grep -Eq 'rm +-[a-z]*f[a-z]*r[a-z]* +(/|~)( |$)' && deny "recursive force delete of / or ~"

# curl|bash and wget|sh remote code execution.
printf '%s' "$NORM" | grep -Eq '(curl|wget)[^|]*\| *(sudo *)?(bash|sh|zsh)' && deny "piping a remote download into a shell"

# sudo rm.
printf '%s' "$NORM" | grep -Eq 'sudo +rm +' && deny "sudo rm"

# Overwriting a block device.
printf '%s' "$NORM" | grep -Eq 'dd +if=.* of=/dev/(sd|nvme|disk|hd)' && deny "dd to a raw block device"

# Fork bomb.
printf '%s' "$NORM" | grep -Eq ':\(\) *\{ *:\|:& *\} *;:' && deny "fork bomb"

# chmod/chown -R on root.
printf '%s' "$NORM" | grep -Eq 'ch(mod|own) +-[a-zA-Z]*R[a-zA-Z]* +[^ ]* +/( |$)' && deny "recursive chmod/chown on /"

exit 0
