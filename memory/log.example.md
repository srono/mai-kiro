# Memory log (example)

Append-only source of truth. The capture hook appends one line per correction
or standing preference it detects. This file is NEVER rewritten by the reorg
step — it is the safety net. The consolidated `memory.md` is derived from it and
can always be rebuilt.

Entry format — one per line, newest at the bottom:

    YYYY-MM-DDTHH:MM:SS | raw text of the correction or preference

Examples:

    2026-01-15T09:12:03 | don't use sed to edit JSON, use jq instead
    2026-01-16T14:40:55 | always run pytest with --tb=short
    2026-01-18T11:02:10 | actually, prefer tabs over spaces in this repo
    2026-02-02T08:30:00 | never commit directly to main, open a PR

The live file is `memory/log.md`, git-ignored so your entries stay local.
