# mai-kiro

Three small hooks for the [Kiro CLI](https://kiro.dev) agent that solve two everyday problems.

## The problems

**1. Secrets slip into git.** It's easy for a key or token to end up in a staged diff and get committed. Once it's in git history, it's expensive and awkward to remove.

**2. Markdown sprawl.** Over a long project the agent keeps spawning one-off `notes.md` / `plan.md` / `summary.md` files to track corrections and context. They pile up and go stale.

## The fix

- **`block-secrets.sh`** — before any `git commit` or `git push`, scans the staged diff for secret patterns (AWS keys, private keys, GitHub/Slack/OpenAI/Google tokens, generic `api_key =` assignments). If it finds one, the commit is hard-blocked until you remove it.
- **`capture-correction.sh` + `inject-memory.sh`** — funnel your corrections into **one** plain-text memory file and surface the relevant lines back into future prompts, instead of scattering stale docs across the repo.

Deliberately tiny: three hooks, one memory file. No codegen, no workflow engine.

## Layout

```
mai-kiro/
├── hooks/
│   ├── block-secrets.sh          # PreToolUse: hard-block commits/pushes with secrets
│   ├── capture-correction.sh     # UserPromptSubmit: append corrections to one file
│   └── inject-memory.sh          # UserPromptSubmit: surface relevant past corrections
├── memory/
│   └── memory.example.md         # format template (your live memory.md is git-ignored)
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

## How the memory works

- **Capture**: when your message looks like a correction ("no, don't…", "use X instead", "actually always…"), it appends a dated, keyworded line to `memory/memory.md`. Questions and long pasted blocks are skipped; duplicates are deduped.
- **Inject**: on each prompt it scores stored entries by keyword overlap with your message and prepends the top matches (default 3). Unrelated messages inject nothing.

Format — one entry per line:

```
YYYY-MM-DD | keyword,comma,list | the correction text
```

Your live `memory/memory.md` is git-ignored so corrections stay local. Remove it from `.gitignore` to publish your memory with the repo.

## Customize

Edit the scripts directly — this is meant to be yours:

- Add correction phrases in `capture-correction.sh`.
- Tune secret patterns in `block-secrets.sh`.
- Change the injection cap with `MAI_MEMORY_MAX` (default 3) and `MAI_MEMORY_MIN_SCORE` (default 1).

## Limitations

Both the secret scanner and the correction capture are pattern-based. They catch common cases, not every possible one. Treat them as strong defaults, not guarantees.

## License

MIT
