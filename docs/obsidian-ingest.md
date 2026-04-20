# Obsidian knowledge-base ingest

Turn PDFs and Word docs in `~/Downloads/` into markdown notes inside the
Obsidian vault, routed into the folder whose content they match.

## Usage

From Claude Code:

```
/ingest-docs
```

Claude then:

1. Finds `*.pdf` / `*.docx` / `*.doc` files at the top level of `~/Downloads/`.
2. Converts each with [`markitdown`](https://github.com/microsoft/markitdown).
3. Reads the converted note, compares it against the vault's top-level
   folders, and places it in the best match — or in `inbox/` when no
   folder fits.
4. Moves the original file into `~/Downloads/_archived/`.

## Why markitdown

Tried a few options:

| Tool | PDF | DOCX | Notes |
| --- | --- | --- | --- |
| pandoc | poor | great | no structured PDF support |
| pdftotext | plain text | ❌ | loses headings, lists, tables |
| marker | great | — | ML models, ~1 GB, slow first run |
| **markitdown** | good | good | single tool, pipx-installable, handles pptx/xlsx/html too |

For a personal knowledge base (a handful of docs at a time, no GPU),
markitdown hits the sweet spot. Output keeps headings and lists, which
is what makes the notes useful in Obsidian.

## Install

```bash
sudo dnf install -y pipx
pipx install 'markitdown[all]'
```

Already wired into [`setup.sh`](../setup.sh).

## Folder routing

Candidates = every top-level subdirectory of the vault except
`.obsidian/`, `_synced/`, `_archived/`. Claude reads the converted note
and picks the best-fitting folder by content.

**Default to `inbox/` when unsure** — the user prefers triaging a small
inbox manually over hunting down a mis-filed note later.

New folders are never created by the skill unless you ask for them.

## Collisions

If a note with the same name already exists in the target folder, the
new note gets a `-YYYYMMDD-HHMMSS` suffix. No silent overwrites.

## Scope

- Only top-level files in `~/Downloads/`. Subdirs (including `_archived/`) are ignored.
- Google Docs are skipped — they don't live as local files.
- Originals are moved (not copied), so every source doc ends up exactly once: either ingested or in `_archived/`.
