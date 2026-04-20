#!/usr/bin/env bash
# Sync *.md files from source project dirs into the Obsidian vault.
# Destination is scoped to $VAULT/_synced/ so hand-curated notes are safe.
set -euo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/obsidian-vault}"
DEST="$VAULT/_synced"

if [[ ! -d "$VAULT" ]]; then
    echo "error: vault not found at $VAULT" >&2
    exit 1
fi

# <source-path>:<dest-name-under-_synced>
sources=(
    "$HOME/devcage:devcage"
    "$HOME/workspace:workspace"
)

excludes=(
    --exclude='.git/'
    --exclude='.obsidian/'
    --exclude='_synced/'
    --exclude='node_modules/'
    --exclude='target/'
    --exclude='dist/'
    --exclude='build/'
    --exclude='.venv/'
    --exclude='venv/'
    --exclude='__pycache__/'
    --exclude='vendor/'
)

mkdir -p "$DEST"

for pair in "${sources[@]}"; do
    src="${pair%:*}"
    name="${pair#*:}"
    if [[ ! -d "$src" ]]; then
        echo "skip: $src (not a directory)"
        continue
    fi
    echo "==> $src → $DEST/$name"
    mkdir -p "$DEST/$name"
    rsync -ah --prune-empty-dirs --delete --itemize-changes \
        "${excludes[@]}" \
        --include='*/' \
        --include='*.md' \
        --exclude='*' \
        "$src/" "$DEST/$name/"
done

echo "==> done"
