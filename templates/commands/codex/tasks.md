---
description: Produce a dependency-ordered tasks.md optimized for Codex automation, honoring Spec Kit’s execution philosophy.
scripts:
  sh: scripts/bash/check-task-prerequisites.sh --json
  ps: scripts/powershell/check-task-prerequisites.ps1 -Json
---

Run inside Codex IDE to create actionable tasks:

Model tier: {MODEL_TIER} | Mode: {MODE}
Mode guidance: fast → fewer, tightly-scoped tasks; thorough → more granular tasks + validation; safety → emphasize tests and guardrails first.

1. Execute `{SCRIPT}` from repo root. Parse `FEATURE_DIR` and `AVAILABLE_DOCS[]`. All values must be absolute.
2. Load every available artifact listed:
   - Always read `plan.md`.
   - Optionally load `data-model.md`, `contracts/`, `research.md`, `quickstart.md` when present.
   - Re-scan `AGENTS.md` so project guardrails influence task wording.
3. In the scratchpad, map out:
   - Build phases (setup, domain, integration, polish)
   - Parallelization opportunities (mark `[P]` when independent per Spec Kit rules)
   - Tests that must exist before implementation begins.
4. Open `templates/tasks-template.md`. Clone it to `FEATURE_DIR/tasks.md` if not already created.
5. Populate the template carefully:
   - Use IDs `T001`, `T002`, …
   - Clearly label setup, test, implementation, integration, polish sections.
   - Tag truly parallel tasks with `[P]` and explain the sharding criteria.
   - Reference absolute file paths so Codex automation can jump directly to files.
   - Tie every user story + acceptance criterion to at least one task.
6. Add a “Verification” section listing the commands Codex should run after implementation (tests, linters, smoke flows).
7. Save `FEATURE_DIR/tasks.md`.
8. Reply in chat with:
   - `feature_dir`: `FEATURE_DIR`
   - `tasks`: absolute path to `tasks.md`
   - Count of total tasks and `[P]` tasks
   - Highlights of critical dependencies or blockers

Do not begin implementation; await user confirmation or follow-up prompts.
