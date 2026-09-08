# mai-kiro

Three small hooks for the [Kiro CLI](https://kiro.dev) agent that fix two problems Kiro doesn't fully solve on its own:

1. **Secrets leaking into git.** Kiro will *flag* a suspicious file, but nothing hard-blocks a commit whose staged diff contains an actual key. `block-secrets.sh` scans the staged diff and `exit 2`s the commit/push. A leaked credential in git history is expensive and hard to undo — this is the one place a deterministic wall clearly beats an advisory prompt.

2. **Markdown sprawl.** The agent tends to spawn a new `notes.md` / `plan.md` / `summary.md` every time you correct it, and they rot. `capture-correction.sh` + `inject-memory.sh` funnel your corrections into **one** plain-text memory file and surface the relevant lines back into future prompts — instead of scattering stale docs across the repo.

Deliberately tiny. No codegen, no symlink indirection, no workflow engine. Three hooks and one memory file. Grow it when a real failure demands it.

> Inspired by ideas in [oh-my-kiro](https://github.com/KaimingWan/oh-my-kiro), rebuilt minimal and personalizable. This intentionally drops the pieces (dangerous-command and outside-workspace blockers) that mostly duplicate Kiro's built-in safety behavior — Kiro already pauses on `rm -rf`, `curl | bash`, and writes outside the workspace.

## What's inside

```
mai-kiro/
├── hooks/
│   ├── block-secrets.sh          # PreToolUse: hard-blocks git commit/push when the staged diff has secrets
│   ├── capture-correction.sh     # UserPromptSubmit: detects corrections, appends them to one memory file
│   └── inject-memory.sh          # UserPromptSubmit: surfaces the most relevant past corrections
├── memory/
│   └── memory.example.md         # format template (your live memory.md is git-ignored)
├── install.sh / uninstall.sh
├── LICENSE
└── README.md
```

## Install

From the project you want to enhance:

```bash
git clone https://github.com/<you>/mai-kiro.git
bash mai-kiro/install.sh          # or: bash mai-kiro/install.sh /path/to/project
```

This writes hook definitions into `.kiro/hooks/` pointing at the scripts in this repo. Restart your Kiro CLI session to load them. Requires `jq`.

To remove: `bash mai-kiro/uninstall.sh` (deletes only the `mai-kiro-*.json` files it created).

## The secret scanner

`block-secrets.sh` runs on `PreToolUse`. It only acts when the command is a `git commit` or `git push`; then it scans `git diff --cached` against patterns for AWS keys, private keys, GitHub/Slack/OpenAI/Google tokens, and generic `secret =`/`api_key =` assignments. A match prints the reason and `exit 2`s — the commit is blocked until you remove the secret.

**Why this and not the other blockers:** the cost of a leaked secret is high and often irreversible, and the false-positive rate is low (it only fires on commit/push). That asymmetry is exactly when a hard, deterministic block earns its keep. Extend the `PATTERNS` array for your own stack.

**Honest limitation:** it's pattern-based. It catches common key shapes, not every possible secret.

## The memory system (anti-sprawl)

The problem: over a long project the agent litters the repo with one-off markdown files, and they drift out of date. The fix is to give corrections a single home.

- **`capture-correction.sh`** (`UserPromptSubmit`): when your message looks like a correction ("no, don't…", "use X instead", "actually always…"), it appends a dated, keyworded line to `memory/memory.md`. Questions and long pasted blocks are skipped; exact duplicates are deduped.
- **`inject-memory.sh`** (`UserPromptSubmit`): tokenizes your message, scores each stored entry by keyword overlap, and prepends the top matches (default 3) into the agent's context. Unrelated messages inject nothing.

One file. Plain text. You can read and hand-edit it. Tune with `MAI_MEMORY_MAX` (default 3) and `MAI_MEMORY_MIN_SCORE` (default 1).

### Memory format

```
YYYY-MM-DD | keyword,comma,list | the correction text
```

See `memory/memory.example.md`. Your live `memory/memory.md` is git-ignored by default so corrections stay local — remove it from `.gitignore` if you want to publish your memory with the repo.

## Customize

This is meant to be *yours*. Edit the scripts directly:

- Add your own correction phrases in `capture-correction.sh`.
- Tune the secret patterns in `block-secrets.sh`.
- Raise/lower the injection cap in `inject-memory.sh`.

## What this intentionally does NOT do

- **No dangerous-command / outside-workspace blocking** — Kiro's built-in safety already pauses on those.
- **No autonomous execution loop** — Kiro's subagent orchestration covers fresh-context, parallel, crash-resilient work without an external runner.
- **No auto-promotion of memory into "rules", no semantic index** — add them only if the flat file stops being enough.

## License

MIT
