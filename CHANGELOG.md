# Changelog

All notable changes to the Specify CLI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Codex-specific command templates and prompts aligned with OpenAI Cookbook guidance
- Sync scripts (`sync-codex-prompts`) for propagating Spec Kit slash commands into Codex
- Release packaging for `spec-kit-template-codex-{sh,ps}` assets plus `CODEX.md` guidance

### Changed

- CLI codex next steps now highlight prompt sync workflow
- Agent context scripts (`update-agent-context`) support Codex alongside existing agents

## [0.0.6] - 2025-09-17

### Added

- opencode support as additional AI assistant option

## [0.0.5] - 2025-09-17

### Added

- Qwen Code support as additional AI assistant option

## [0.0.4] - 2025-09-14

### Added

- SOCKS proxy support for corporate environments via `httpx[socks]` dependency

### Fixed

N/A

### Changed

N/A
