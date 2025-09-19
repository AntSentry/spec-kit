#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || { echo "Must run inside a git repo" >&2; exit 1; })
cd "$ROOT"

echo "=== Spec Kit Updater (bash) ==="

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
require git

ensure_remote() {
  local name=$1 url=$2
  if git remote get-url "$name" >/dev/null 2>&1; then
    return 0
  fi
  git remote add "$name" "$url"
}

echo "Checking remotes..."
ensure_remote origin "https://github.com/AntSentry/spec-kit.git" || true
ensure_remote upstream "https://github.com/github/spec-kit.git" || true

echo "Fetching remotes..."
git fetch origin --tags
git fetch upstream --tags

# Guard against dirty tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree has local changes. Stashing them first..."
  git stash push -u -m "pre-update-$(date +%Y%m%d-%H%M%S)"
  STASHED=1
else
  STASHED=0
fi

echo "Switching to main and rebasing onto upstream/main..."
git checkout main
git fetch upstream main
git rebase upstream/main

echo "Pushing updated main to origin..."
git push origin main

if [[ "$STASHED" == "1" ]]; then
  echo "Re-applying stashed changes (if conflict-free)..."
  if git stash list | grep -q pre-update-; then
    git stash pop || {
      echo "Stash pop encountered conflicts. Resolve manually, commit, and push." >&2
      exit 2
    }
  fi
fi

echo "Running compatibility checks..."
set +e
python3 -m compileall "$ROOT/src/specify_cli" >/dev/null 2>&1
PY_OK=$?

MISSING=()
[[ -f "$ROOT/.github/workflows/scripts/create-release-packages.sh" ]] || MISSING+=(packaging_script)
[[ -f "$ROOT/scripts/bash/sync-codex-prompts.sh" ]] || MISSING+=(codex_sync_sh)
[[ -f "$ROOT/scripts/powershell/sync-codex-prompts.ps1" ]] || MISSING+=(codex_sync_ps1)
[[ -d "$ROOT/templates/commands/codex" ]] || MISSING+=(codex_templates)

echo "--- Update Report ---"
echo "root: $ROOT"
echo "branch: $(git rev-parse --abbrev-ref HEAD)"
echo "upstream HEAD: $(git rev-parse upstream/main)"
echo "local HEAD: $(git rev-parse HEAD)"
echo "cli_compile: $([[ $PY_OK -eq 0 ]] && echo ok || echo fail)"
if ((${#MISSING[@]})); then
  echo "missing: ${MISSING[*]}" >&2
  exit 3
fi
echo "status: updated"

