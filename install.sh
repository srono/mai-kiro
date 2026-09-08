#!/usr/bin/env bash
# install.sh — wire mai-kiro hooks into a project's .kiro/hooks/.
#
# Usage:
#   bash mai-kiro/install.sh [target-project-dir]
#
# If no target is given, installs into the current working directory.
# Safe to re-run: it overwrites only the mai-kiro-*.json hook files it owns.

set -euo pipefail

# Absolute path to this repo (so hooks work regardless of cwd).
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_SRC="$REPO_DIR/hooks"

TARGET="${1:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"
HOOKS_DST="$TARGET/.kiro/hooks"

if [ ! -d "$HOOKS_SRC" ]; then
  echo "❌ Cannot find hooks/ in $REPO_DIR" >&2
  exit 1
fi

# Dependency check.
if ! command -v jq >/dev/null 2>&1; then
  echo "⚠️  jq is not installed. The hooks parse JSON with jq." >&2
  echo "    Install it with: brew install jq" >&2
fi

echo "📦 Installing mai-kiro hooks"
echo "    repo:   $REPO_DIR"
echo "    target: $TARGET"

mkdir -p "$HOOKS_DST"

# Make hook scripts executable.
chmod +x "$HOOKS_SRC"/*.sh

# write_hook <id> <name> <trigger> <matcher-or-empty> <script>
write_hook() {
  local id="$1" name="$2" trigger="$3" matcher="$4" script="$5"
  local script_path="$HOOKS_SRC/$script"
  local dst="$HOOKS_DST/mai-kiro-$id.json"

  local matcher_json=""
  if [ -n "$matcher" ]; then
    matcher_json=$(printf ',\n      "matcher": "%s"' "$matcher")
  fi

  cat > "$dst" <<JSON
{
  "version": "v1",
  "hooks": [
    {
      "name": "$name",
      "trigger": "$trigger"$matcher_json,
      "action": {
        "type": "command",
        "command": "bash '$script_path'"
      }
    }
  ]
}
JSON
  echo "    ✓ $dst"
}

# Enforcement gates — fire before shell tool use. Matcher targets the bash/execute tool.
BASH_MATCHER="(?i)(bash|shell|execute|command)"

write_hook "block-secrets"   "mai-kiro: block secrets"           "PreToolUse" "$BASH_MATCHER" "block-secrets.sh"
write_hook "block-dangerous" "mai-kiro: block dangerous commands" "PreToolUse" "$BASH_MATCHER" "block-dangerous.sh"
write_hook "block-outside"   "mai-kiro: block writes outside workspace" "PreToolUse" "$BASH_MATCHER" "block-outside-workspace.sh"

# Memory — fire on every user prompt.
write_hook "inject-memory"      "mai-kiro: inject memory"      "UserPromptSubmit" "" "inject-memory.sh"
write_hook "capture-correction" "mai-kiro: capture correction" "UserPromptSubmit" "" "capture-correction.sh"

echo ""
echo "✅ Done. Restart your Kiro CLI session to load the hooks."
echo "   Installed files: $HOOKS_DST/mai-kiro-*.json"
