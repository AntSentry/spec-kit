#!/usr/bin/env bash
set -euo pipefail

# Sync Spec Kit Codex prompts into the user's Codex prompt directory.
# Usage: bash .specify/scripts/bash/sync-codex-prompts.sh

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ "$SCRIPT_DIR" == *"/.specify/"* ]]; then
  PROJECT_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
else
  PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
fi

SOURCE_DIR="$PROJECT_ROOT/.codex/prompts"
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: Codex prompts not found at $SOURCE_DIR" >&2
  exit 1
fi

CODEX_HOME=${CODEX_HOME:-"$HOME/.codex"}
TARGET_DIR="$CODEX_HOME/prompts"
mkdir -p "$TARGET_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$TARGET_DIR/.backup-spec-kit-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Copy markdown prompts shipped with Spec Kit
shopt -s nullglob
PROMPT_FILES=($SOURCE_DIR/*.md)
if (( ${#PROMPT_FILES[@]} == 0 )); then
  echo "ERROR: No Codex prompts found under $SOURCE_DIR" >&2
  exit 1
fi

for file in "${PROMPT_FILES[@]}"; do
  base=$(basename "$file")
  if [[ -f "$TARGET_DIR/$base" ]]; then
    mv "$TARGET_DIR/$base" "$BACKUP_DIR/$base"
  fi
  cp "$file" "$TARGET_DIR/$base"
  echo "Installed $TARGET_DIR/$base"
done

cat <<MSG

Codex prompts synchronized.
- Source: $SOURCE_DIR
- Target: $TARGET_DIR
- Backup: $BACKUP_DIR

Restart your Codex session to pick up the new slash commands.
MSG
