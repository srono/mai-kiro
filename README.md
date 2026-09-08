# mai-kiro

A deliberately small framework that gives the [Kiro CLI](https://kiro.dev) agent two things it lacks by default:

1. **Enforcement it cannot skip** — a few hard hooks that block genuinely dangerous actions (secret commits, destructive commands, writes outside the workspace). Code enforces; prompts only suggest.
2. **Memory that survives sessions** — corrections you make are captured to a file and the relevant ones are injected back into future prompts.

That's it. No codegen, no symlink indirection, no 19-hook sprawl. Three hooks and one memory file. Grow it when a real failure demands it — not before.

> Inspired by the ideas in [oh-my-kiro](https://github.com/KaimingWan/oh-my-kiro), rebuilt minimal and personalizable.

## Philosophy

- **If code can enforce it, don't ask a prompt to.** A prompt that says "never commit secrets" is followed probabilistically. A hook that `exit 2`s on a secret is followed every time.
- **Small over complete.** Every hook is a thing that can also wrongly block you. Keep the set tiny and honest about its limits.
- **Memory is a tool, not magic.** This captures your corrections and surfaces them again. It does not "learn" — it remembers. That's enough to be useful.

## What's inside

```
mai-kiro/
├── hooks/
│   ├── block-secrets.sh          # PreToolUse: blocks committing/pushing obvious secrets
│   ├── block-dangerous.sh        # PreToolUse: blocks rm -rf /, curl|bash, etc.
│   ├── block-outside-workspace.sh# PreToolUse: blocks writes outside the workspace
│   ├── capture-correction.sh     # UserPromptSubmit: detects corrections, appends to memory
│   └── inject-memory.sh          # UserPromptSubmit: surfaces relevant past memory
├── memory/
│   └── memory.md                 # your persisted corrections (git-ignored by default)
├── install.sh                    # wires hooks into .kiro/hooks
├── LICENSE
└── README.md
```

## Install

From inside the project where you want the agent enhanced:

```bash
git clone https://github.com/<you>/mai-kiro.git
bash mai-kiro/install.sh
```

This writes hook definitions into `.kiro/hooks/` pointing at the scripts in this repo. Restart your Kiro CLI session to pick them up.

## The hooks

### Enforcement (hard blocks)

These run on `PreToolUse` and `exit 2` to block the action. The agent sees the reason and can retry safely.

| Hook | Blocks |
|------|--------|
| `block-secrets.sh` | `git commit`/`git push` when staged content matches API keys, private keys, tokens |
| `block-dangerous.sh` | `rm -rf /`, `rm -rf ~`, `curl \| bash`, `sudo rm`, fork bombs |
| `block-outside-workspace.sh` | Shell commands that redirect/write to absolute paths outside the workspace |

**Honest limitation:** command blocklists are speed bumps, not walls. `rm -r -f` with odd spacing or `$(echo rm)` tricks can slip through. These catch the accidental `rm -rf /`, not a determined adversary. Treat them accordingly.

### Memory

- `capture-correction.sh` (`UserPromptSubmit`): if your message looks like a correction ("no, don't", "wrong", "use X instead", "actually"), it appends a dated entry to `memory/memory.md`.
- `inject-memory.sh` (`UserPromptSubmit`): keyword-matches your message against stored memory and prepends the most relevant entries (capped) so the agent sees them.

Memory is intentionally plain Markdown you can read and edit by hand.

## Customize

This is meant to be *yours*. Edit the scripts directly:

- Add your own correction phrases to `capture-correction.sh`.
- Tune the secret patterns in `block-secrets.sh` for your stack.
- Raise/lower the injection cap in `inject-memory.sh`.

## License

MIT
