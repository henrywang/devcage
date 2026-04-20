# Obsidian knowledge-base sync

Mirror `*.md` files from source project directories into the Obsidian
vault so they're indexed and searchable alongside hand-curated notes.

## Layout

Vault root: `~/Documents/obsidian-vault` (override with `OBSIDIAN_VAULT`).

| Source | Destination |
| --- | --- |
| `~/devcage/` | `_synced/devcage/` |
| `~/workspace/` | `_synced/workspace/` |

The `_synced/` subtree is managed entirely by the script. Anything
outside it — `bluehat/`, `redhat/`, daily notes, etc. — is never
touched.

## Usage

Directly:

```bash
~/devcage/bin/sync-notes.sh
```

From Claude Code:

```
/sync-notes
```

## Behavior

- Only `*.md` files are copied. Directory hierarchy is preserved.
- Skipped paths: `.git/`, `.obsidian/`, `_synced/`, `node_modules/`,
  `target/`, `dist/`, `build/`, `.venv/`, `venv/`, `__pycache__/`,
  `vendor/`.
- `--delete`: md files removed from the source disappear from
  `_synced/` on the next run. Non-md files inside `_synced/` are left
  alone — drop an index note there by hand and it survives.
- Obsidian's file watcher picks up changes live while the app is running.

## Why rsync and not obsidian-cli

`obsidian-cli` is for driving the *running* Obsidian app (open a note,
list aliases, run commands). It's one round-trip per file and needs
Obsidian running. rsync is a file-level mirror: fast, offline-friendly,
and since Obsidian stores notes as plain `.md` on disk, copying files is
all that's needed.

## Editing the source list

Edit the `sources=(...)` array near the top of
[`bin/sync-notes.sh`](../bin/sync-notes.sh). Each entry is
`<absolute-path>:<dest-name-under-_synced>`.
