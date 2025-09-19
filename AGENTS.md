# Agent Guide for Spec Kit

This repository contains Spec Kit, a spec-driven development toolkit and the `specify` CLI. These instructions help AI coding agents (including OpenAI Codex) work safely and effectively within this repo and any projects bootstrapped by Spec Kit.

## Scope and Structure

- CLI code lives in `src/specify_cli` (Python 3.11+; Typer/Rich/httpx).
- Reusable command prompts live in `templates/commands/*.md` (`/specify`, `/plan`, `/tasks`).
- Automation scripts are under `scripts/bash` and `scripts/powershell`.
- Core guardrails live in `memory/constitution.md`.
- Docs are under `docs/` and end-user README is `README.md`.

## Agent Expectations

- Do not reorganize directories or rename public files. Keep changes focused and minimal.
- Do not add licenses or headers. Preserve existing licensing.
- When adding automation, place POSIX scripts in `scripts/bash` and PowerShell in `scripts/powershell`.
- Keep cross-platform support: any new script capability should have both `sh` and `ps` variants if user-facing.
- Respect the CLI entry point: keep `specify_cli:main` stable and avoid breaking CLI flags.
- For searches, use `rg` with small output windows to avoid truncation.

## Using with OpenAI Codex

- Spec Kit exposes agent-friendly commands via `templates/commands`:
  - `/specify` uses `create-new-feature` to scaffold a new feature and write the initial spec.
  - `/plan` prepares and executes the implementation plan template.
  - `/tasks` generates a dependency-ordered task list.
- When bootstrapping a downstream project, the CLI supports `--ai codex`. If a Codex-specific template is not published yet, the CLI safely falls back to the Copilot template without breaking behavior.
- Codex should follow these steps in downstream projects:
  - Run `specify init <project>` (or `--here`) to place templates and scripts.
  - Invoke `/specify`, `/plan`, `/tasks` as described in the Codex prompt overrides under `templates/commands/codex`.
  - Run `.specify/scripts/bash/sync-codex-prompts.sh` (or the PowerShell variant) to publish the prompts into `~/.codex/prompts/` for slash access.
  - Always use absolute paths for file operations.

## Coding Style

- Python: follow existing style patterns; avoid adding new top-level dependencies.
- Shell/PowerShell: keep scripts idempotent; perform safety checks and produce machine-parsable `--json` output when applicable.

## Testing and Validation

- Do not introduce unrelated refactors. Focus on requested changes.
- If adding behavior to the CLI, ensure default flows remain backward compatible.
- Prefer small, targeted patches. Validate by running `specify check` and by exercising the scripts in `scripts/` where possible.

## Release Compatibility

- The CLI downloads release assets of the form `spec-kit-template-<ai>-<script>.zip`.
- For `--ai codex`, the CLI falls back to `copilot` assets if a Codex-specific asset is unavailable, ensuring no degraded experience.

## Contact

For broader changes, update docs under `docs/` and `README.md` together with CLI behavior to keep user-facing guidance in sync.
