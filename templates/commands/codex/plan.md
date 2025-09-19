---
description: Run the implementation planning workflow with Codex, combining structured execution with automated validation hooks.
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
---

Operate as an OpenAI Codex IDE agent and generate the Spec Kit implementation plan with resilience:

Model tier: {MODEL_TIER} | Mode: {MODE}
Mode guidance: fast → minimal research iterations; thorough → full critique + verify artifacts; safety → add preflight checks before file writes.

1. Execute `{SCRIPT}` from repository root. Parse JSON for `FEATURE_SPEC`, `IMPL_PLAN`, `SPECS_DIR`, and `BRANCH`. Paths must be absolute.
2. Load prerequisite context before writing:
   - `memory/constitution.md`
   - `FEATURE_SPEC`
   - Any `AGENTS.md` files Codex merged for this session.
3. Use the Codex scratchpad to outline each phase (0–2). Note open questions, dependencies, and risk areas. Confirm that all acceptance criteria from the spec are mapped to a concrete plan step.
4. Open the pre-seeded `IMPL_PLAN` (copied from `templates/plan-template.md`). Follow the template verbatim:
   - Update the header metadata (feature name, branch, owners, date).
   - Populate **Input Summary** referencing `FEATURE_SPEC` highlights.
   - Execute **Phase 0 → research.md**: document ecosystem decisions, benchmarks, and trade-offs. Call out cookbook references or prior art you rely on.
   - Execute **Phase 1 → design artifacts**: produce `data-model.md`, `contracts/`, and `quickstart.md` as instructed. Each artifact must live inside `SPECS_DIR`.
   - Execute **Phase 2 → tasks.md**: outline high-level milestones (detailed task breakdown comes later in `/tasks`).
   - Keep the Progress Tracker in sync—mark each phase `Complete` only after assets exist.
5. Whenever the template instructs “Run command”, honor it exactly. Use Codex exec blocks (` ```bash … ````) so the user can replay shell steps. In safety mode, prefer dry-run flags when available.
6. After completing all phases, run Codex’s diff viewer to confirm the artifacts changed exactly where expected.
7. In the final section of `IMPL_PLAN`, record:
   - Generated artifact paths
   - Open risks / pending decisions
   - Next action (`/tasks`)
8. Save all modified files. Do **not** auto-commit.
9. Respond in chat with:
   - `branch`: `BRANCH`
   - `plan`: `IMPL_PLAN`
   - `artifacts`: list of absolute paths created/updated
   - Risk summary

If any phase cannot complete, document the blocker in both the plan and the chat response before exiting.
