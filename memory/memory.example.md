# Memory (example)

The **consolidated** memory document. This is what the agent reads at the start
of a session. It is rewritten by the reorg step (an agent action) from the
append-only `log.md`, so that newer findings supersede older ones and duplicates
are merged. Keep it short, current, and readable.

This is a derived view — if it is ever wrong, it can be rebuilt from `log.md`.

Suggested structure (the reorg step maintains this):

## Preferences

- Prefer tabs over spaces in this repo.
- Keep commit subjects under 70 characters.

## Rules

- Don't use sed to edit JSON — use jq.
- Never commit directly to main; open a PR.

## Tooling

- Run pytest with `--tb=short`.

---
_Last reorg: <date> — <one-line changelog>_

The live file is `memory/memory.md`, git-ignored so your entries stay local.
