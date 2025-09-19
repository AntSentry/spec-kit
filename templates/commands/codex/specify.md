---
description: Draft a complete specification using Spec Kit's template while leveraging Codex IDE scratchpads and critique features for high-confidence output.
scripts:
  sh: scripts/bash/create-new-feature.sh --json "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 -Json "{ARGS}"
---

You are working inside the OpenAI Codex IDE with the Spec Kit project loaded. Follow this Codex-optimized flow:

1. Execute `{SCRIPT}` from the project root. Parse the JSON for `BRANCH_NAME`, `SPEC_FILE`, and `SPECS_DIR`. All reported paths must be absolute.
2. Read the following context before drafting anything:
   - `memory/constitution.md` for non-negotiable principles.
   - Repository-level `AGENTS.md` plus `SPECS_DIR/AGENTS.md` if present (Codex auto-merges them on session start; refresh if you just generated one).
   - `templates/spec-template.md` for required structure, including acceptance checklist.
3. Start an `#analysis` scratchpad (Codex shortcut: Ctrl+L). Capture:
   - Key intent, actors, and constraints from the user arguments `{ARGS}`.
   - Any clarifying questions or gaps. If blockers exist, log them in the scratchpad and continue with best-effort assumptions, marking them as `OPEN QUESTION` in the spec.
   - Cross-check against constitution rules; note any friction.
4. With the plan recorded, switch to the main composer and draft the spec in two passes:
   - **Pass 1 – Outline**: Generate headings and bullet scaffolding that mirrors `spec-template.md`. Ensure user stories, functional requirements, non-functional requirements, success metrics, and open issues sections are present.
   - **Pass 2 – Detail**: Fill in the outline with concrete details distilled from `{ARGS}`, scratchpad insights, and constitution constraints. Keep prose actionable—Codex should be able to hand this to `/plan` without ambiguity.
5. Update the acceptance checklist at the end of the spec. Every satisfied item should be checked `[x]`. Leave unchecked items as `[ ]` with one-line rationale.
6. Save the final markdown to `SPEC_FILE` exactly. Preserve section order from the template.
7. Emit a completion report to the chat transcript including:
   - `branch`: `BRANCH_NAME`
   - `spec`: `SPEC_FILE`
   - Summary of unresolved questions or risks (if none, state `None`)
   - Confirmation that the spec is ready for `/plan`.

Do not commit changes. Let the user review before moving to the next phase.
