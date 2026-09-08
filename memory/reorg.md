# Reorg instructions

You are consolidating the memory. Follow these steps exactly.

## Inputs

- `memory/log.md` — append-only source of truth. Treat as READ-ONLY. Never edit or delete lines here.
- `memory/memory.md` — the consolidated document you will rewrite.

## Goal

Produce an up-to-date `memory/memory.md` that reflects everything still relevant
in `log.md`, with newer entries superseding older ones. The consolidated doc
should be short, de-duplicated, well-organized, and directly usable as guidance.

## Rules

1. **Read both files fully first.** `log.md` entries are timestamped; later timestamps win when two entries conflict.
2. **Newer supersedes older.** If a later entry contradicts an earlier one (e.g. "use spaces" then later "use tabs"), keep only the newer intent. Do not keep both.
3. **Merge duplicates.** Collapse entries that say the same thing into one clear line.
4. **Never silently drop a still-relevant rule.** Only omit an entry if it is (a) superseded by a newer entry, or (b) clearly one-off/no longer applicable. If you drop something for reason (b), note it in the changelog.
5. **Do not invent rules.** Only consolidate what is actually in the log. No embellishment.
6. **Keep it organized.** Group into sections like `## Preferences`, `## Rules`, `## Tooling`, `## Project context` — whatever fits the content. Prefer short imperative lines.
7. **Keep it short.** If the doc is growing large, tighten wording; do not pad.

## Output

1. Overwrite `memory/memory.md` with the consolidated content.
2. End the file with a changelog line:

   ```
   ---
   _Last reorg: YYYY-MM-DD — <one-line summary: merged X and Y; dropped Z (superseded); N entries consolidated>_
   ```

3. Update the reorg marker so the throttle counter resets:
   - Write the current entry count of `log.md` to `memory/.reorg-count`
     (count = number of lines matching the `YYYY-MM-DDTHH:MM:SS |` timestamp format).

## Safety

- `log.md` is the source of truth and is never modified here. If your rewrite of
  `memory.md` turns out wrong, it can be rebuilt from `log.md`. Because of that,
  prefer keeping a borderline-relevant rule over dropping it.
