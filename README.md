# mai-kiro

Four small hooks for the [Kiro CLI](https://kiro.dev) agent that solve two everyday problems.

## The problems

**1. Secrets slip into git.** It's easy for a key or token to end up in a staged diff and get committed. Once it's in git history, it's expensive and awkward to remove.

**2. Markdown sprawl.** Over a long project the agent keeps spawning one-off `notes.md` / `plan.md` / `summary.md` files to track corrections and context. They pile up and go stale.

## The fix

- **`block-secrets.sh`** — before any `git commit` or `git push`, scans the staged diff for secret patterns. On a match, the commit is hard-blocked until you remove it.
- **The memory system** — captures your corrections into one append-only log, then periodically uses the Kiro agent itself to rewrite a single **consolidated** memory document where newer findings supersede older ones. No regex matching, no scattered stale files — one always-current doc.

Deliberately small. Pure bash + `jq` for the mechanics; the consolidation is done by the agent (no API key, no extra service).

## How the memory works

Two files instead of one:

- **`memory/log.md`** — append-only source of truth. The capture hook adds one timestamped line per correction/preference. **Never rewritten** — it's the safety net.
- **`memory/memory.md`** — the consolidated, current document. Rewritten from the log by the agent so newer entries win and duplicates merge. This is what gets injected into sessions. If it's ever wrong, it can be rebuilt from the log.

The flow:

1. **Capture** (`capture-correction.sh`, on each prompt): if your message looks like a correction or standing preference ("no, don't…", "use X instead", "from now on…", "always…"), it appends the raw line to `log.md`. A loose filter decides *whether* to keep it; it does **not** try to interpret it.
2. **Reorg** (`reorg-check.sh`, throttled): once the log has grown by N new entries (default 10), it asks the agent to consolidate — read `log.md` + `memory.md`, rewrite `memory.md` per `memory/reorg.md`, and reset the counter. The rewrite is an agent action you'll see in-session (that's the tradeoff for using no API key). Trigger it manually anytime by saying "reorg memory" or running `bash mai-kiro/hooks/reorg-check.sh --force`.
3. **Inject** (`inject-memory.sh`, at session start): surfaces the whole consolidated `memory.md` into context. Because consolidation keeps it short, the agent gets the current state without any keyword matching.

**Why LLM consolidation instead of keyword matching?** Matching missed paraphrases and let near-duplicates pile up. Letting the agent rewrite the doc means newer findings always supersede older ones and the document stays clean and current — while the append-only log guarantees nothing is silently lost.

## Layout

```
mai-kiro/
├── hooks/
│   ├── block-secrets.sh          # PreToolUse: hard-block commits/pushes with secrets
│   ├── capture-correction.sh     # UserPromptSubmit: append corrections to log.md
│   ├── reorg-check.sh            # UserPromptSubmit: trigger consolidation when log grows
│   └── inject-memory.sh          # SessionStart: surface the consolidated memory.md
├── memory/
│   ├── log.md                    # append-only source of truth (git-ignored)
│   ├── memory.md                 # consolidated view (git-ignored)
│   ├── reorg.md                  # instructions the agent follows to consolidate
│   ├── log.example.md            # format templates
│   └── memory.example.md
├── install.sh / uninstall.sh
├── LICENSE
└── README.md
```

## Install

From the project you want to enhance (requires `jq`):

```bash
git clone https://github.com/srono/mai-kiro.git
bash mai-kiro/install.sh          # or: bash mai-kiro/install.sh /path/to/project
```

This writes hook definitions into `.kiro/hooks/`. Restart your Kiro CLI session to load them.

To remove: `bash mai-kiro/uninstall.sh` (deletes only the files it created).

## Formats

Log entry (one per line, newest at the bottom):

```
YYYY-MM-DDTHH:MM:SS | raw text of the correction or preference
```

Consolidated doc: short, sectioned Markdown (`## Preferences`, `## Rules`, `## Tooling`, …) ending with a `_Last reorg: …_` changelog line. See `memory/*.example.md`.

## Customize

Edit the scripts directly — this is meant to be yours:

- Add capture phrases in `capture-correction.sh` (`FILTER_RE`).
- Tune secret patterns in `block-secrets.sh`.
- Change the reorg threshold with `MAI_REORG_THRESHOLD` (default 10).
- Adjust consolidation behavior by editing `memory/reorg.md`.

## Limitations

- The secret scanner and the capture filter are pattern-based — they catch common cases, not every possible one.
- Consolidation is an LLM rewrite, so review the changelog line occasionally. The append-only `log.md` is never touched, so a bad rewrite is always recoverable.

## License

MIT
