---
name: sync-notes
description: Sync markdown files from ~/devcage and ~/workspace into the Obsidian vault's _synced/ folder
disable-model-invocation: true
allowed-tools: Bash
---

# Sync Notes Skill

Mirror `*.md` files from source project dirs into the Obsidian vault so the
knowledge base stays in step with the working tree.

## Steps

1. Run `sync-notes` (from `~/.local/bin/`).
2. Summarize briefly: which source dirs got synced, how many files changed
   (from rsync's itemized output), and whether any source was skipped.
3. If rsync exited non-zero, show the error and stop.

## Notes

- Target is `~/Documents/obsidian-vault/_synced/` (override with `OBSIDIAN_VAULT`).
- Hand-curated notes outside `_synced/` are never touched.
- See `~/devcage/docs/obsidian-sync.md` for the full behavior.
