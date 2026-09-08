# Memory (example)

This is a template showing the format. The live file is `memory/memory.md`,
which is git-ignored by default so your personal corrections stay local.

Entry format — one per line:

    YYYY-MM-DD | keyword,comma,list | the correction text

Examples:

    2026-01-15 | sed,json,jq | don't use sed to edit JSON, use jq instead
    2026-01-16 | pytest,tests | always run pytest with --tb=short
    2026-01-18 | commit,message | keep commit subjects under 70 chars

`capture-correction.sh` appends here automatically; `inject-memory.sh` reads it.
To publish your memory with the repo, remove `memory/memory.md` from `.gitignore`.
