# Spec Kit × OpenAI Codex IDE

Use this guide to work inside Spec Kit projects with the OpenAI Codex IDE extension or CLI.

## Command Palette

Codex loads prompts from `~/.codex/prompts/`. Run:

```bash
.specify/scripts/bash/sync-codex-prompts.sh   # or PowerShell equivalent
```

This copies the Spec Kit slash commands (`/specify`, `/plan`, `/tasks`, etc.) into Codex with the latest repository rules.

## Workflow Expectations

1. **Specifications first** – always run `/specify` before any implementation. Capture intent, success metrics, and open questions in `specs/<branch>/spec.md`.
2. **Constitution-aligned planning** – `/plan` generates the full execution blueprint and artifacts (research, data model, contracts, quickstart). Keep progress tracking accurate.
3. **Task orchestration** – `/tasks` emits dependency-ordered work suitable for Codex automation. Only begin coding once tasks are approved.
4. **Preserve guardrails** – Codex merges `AGENTS.md` files automatically. Update `.specify/templates` to keep guardrails tight.

## Codex-Specific Tips

- Use scratchpads (`Cmd/Ctrl+L`) to outline reasoning before sending messages.
- Invoke `/status` frequently to review queued filesystem changes before approving.
- Run `codex exec` for scripted operations (linting, tests) to keep the transcript clean.
- Keep prompts concise but referential—Codex has first-class understanding of repository structure.

## Helpful Cookbook Patterns

- Apply the [Plan-and-Execute pattern](https://cookbook.openai.com/examples/plan_and_execute) to outline work before generating artifacts.
- Use the [Critique → Revise loop](https://cookbook.openai.com/examples/critique_and_revise) when instructions are ambiguous—Codex is excellent at self-auditing.
- Prefer structured replies (tables, checklists) so downstream phases can parse them automatically.

Stay true to Spec Kit’s philosophy: intentional specs, disciplined planning, test-first execution.
