---
name: ingest-docs
description: Convert PDFs and Word docs from ~/Downloads into markdown, route each into the matching Obsidian vault folder (or inbox/), and archive the original
disable-model-invocation: true
allowed-tools: Bash, Read, Glob
---

# Ingest Docs Skill

Convert documents from `~/Downloads/` into markdown, file each into the
most relevant Obsidian vault folder based on its content (falling back to
`inbox/` when nothing matches well), and archive the original.

Vault: `~/Documents/obsidian-vault` (override with `$OBSIDIAN_VAULT`).

## Steps

1. **Find candidates** — top-level only, skip `_archived/`:

   ```
   find ~/Downloads -maxdepth 1 -type f \( -iname '*.pdf' -o -iname '*.docx' -o -iname '*.doc' \)
   ```

   If empty, say so and stop.

2. **List vault folders** to choose from (skip hidden dirs and managed dirs):

   ```
   find "${OBSIDIAN_VAULT:-$HOME/Documents/obsidian-vault}" \
       -maxdepth 1 -mindepth 1 -type d \
       ! -name '.*' ! -name '_synced' ! -name '_archived' \
       -printf '%f\n' | sort
   ```

3. Ensure the archive and inbox dirs exist. Use whichever `inbox` casing
   already exists in the vault (`Inbox/` or `inbox/`); if neither, create
   `Inbox/`:

   ```
   mkdir -p ~/Downloads/_archived
   V="${OBSIDIAN_VAULT:-$HOME/Documents/obsidian-vault}"
   if   [[ -d "$V/Inbox" ]]; then INBOX="$V/Inbox"
   elif [[ -d "$V/inbox" ]]; then INBOX="$V/inbox"
   else mkdir -p "$V/Inbox" && INBOX="$V/Inbox"; fi
   ```

4. **For each source doc:**

   1. Convert with `markitdown`:

      ```
      markitdown "$doc" -o "/tmp/ingest-$$-<safe-stem>.md"
      ```

      If `markitdown` fails with `PDFPasswordIncorrect`, or any other
      conversion error, skip the file and note it in the summary —
      do NOT archive a source whose conversion failed.

   2. Read the top of the output (~80 lines) to get the gist.
   3. Decide the target folder from the step-2 list based on content.
      **When in doubt, use `inbox/`** — the user prefers manual triage
      over mis-filing. Don't create new top-level folders.
   4. Move the md into place:
      `$VAULT/<folder>/<stem>.md`. If the target exists, append
      `-<YYYYMMDD-HHMMSS>` to the stem.
   5. Move the original: `mv "$doc" ~/Downloads/_archived/`.

5. **Report:** one line per file → `<filename> → <folder>`, plus any
   failures (conversion errors, permission issues, etc.).

## Notes

- Requires `markitdown` on `$PATH` (installed via `pipx install 'markitdown[all]'`).
- If `markitdown` is missing, stop and tell the user how to install it.
- Preserve the original filename as the note stem (Obsidian handles spaces and unicode fine).
- See `~/devcage/docs/obsidian-ingest.md` for the full design.
