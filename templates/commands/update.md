---
description: Update Spec Kit from upstream (github/spec-kit) into this fork and verify compatibility without breaking Codex or other agents.
scripts:
  sh: scripts/bash/update-spec-kit.sh
  ps: scripts/powershell/update-spec-kit.ps1
---

Execute the update procedure safely and report results:

1. Run `{SCRIPT}` from repo root. It will:
   - Ensure `origin` points to your fork and `upstream` points to `github/spec-kit`.
   - Fetch both remotes; rebase `main` onto `upstream/main` and push to `origin/main`.
   - Preserve Codex overrides and templates.
   - Run compatibility checks.
2. If any conflicts occur, the script will stop and print a summary with next steps; do not continue until they’re resolved.
3. On success, reply with:
   - `status`: updated
   - `branch`: main
   - `upstream`: tag/commit summary
   - `checks`: results for CLI compile, packaging, and presence of Codex assets

All file paths must be absolute in your report. Do not auto-commit beyond the rebase; the script handles commits when safe.

