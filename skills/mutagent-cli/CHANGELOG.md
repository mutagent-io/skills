# Changelog — `mutagent-cli` skill

All notable changes to the `mutagent-cli` skill will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions track the [`@mutagent/cli`](https://www.npmjs.com/package/@mutagent/cli)
release this skill was synced from. See the registry's
[`README.md`](https://github.com/mutagent-io/skills#versioning) for the full
versioning model.

---

## [0.1.208] — 2026-07-28

One-time refresh from `@mutagent/cli@0.1.208` before retiring the automated
CLI-to-public-repository synchronization workflow.

### Changed

- Refocused the skill on the current CLI surface:
  - authentication and project setup
  - workspace, provider, usage, skill, and hook discovery
  - installation of Helix, Diagnostics, and Evaluator
  - product feedback and transcript-assisted bug reporting
- Reduced the entry skill from the legacy prompt-optimization journey router to
  a smaller task router backed by three focused workflows.
- Updated plugin manifests from `0.1.178` to `0.1.208`.
- Updated skill metadata to `skill_version: "1.2.0"`.

### Added

- `references/workflows/setup.md`
- `references/workflows/install.md`
- `references/workflows/feedback.md`

### Removed

- Legacy prompt, dataset, evaluation, optimization, tracing, agent, and
  scorecard references that are no longer part of the current CLI skill.
- The scheduled `Sync from CLI` GitHub Actions workflow. Future public updates,
  if any, must be explicitly requested and reviewed as one-time changes.

### Compatibility

- `skill_version`: `1.2.0`
- `skill_min_cli_version`: `0.1.163`
- Synced from `@mutagent/cli@0.1.208`

## [0.1.178] — 2026-05-07

Initial public release of the skill registry.

### Added

- Full skill bundle (synced from `@mutagent/cli@0.1.178`):
  - `SKILL.md` — entry router with 5 core rules and the journey table
  - `concepts/dataset-design.md` — golden rule, case categories, anti-patterns
  - `concepts/eval-criteria.md` — INPUT MVC vs OUTPUT Standards rubric framing
  - `concepts/prompt-variables.md` — `{var}` vs `{{var}}` delimiter inference
  - `concepts/scorecard-output.md` — interpreting optimizer scorecards
  - `workflows/agents.md` — multi-turn agent path (work-in-progress notice)
  - `workflows/dataset-curation.md` — standalone dataset creation/expansion
  - `workflows/eval-creation.md` — standalone rubric creation
  - `workflows/exploration.md` — read-only codebase scan
  - `workflows/optimization.md` — full explore → upload → dataset → eval →
    optimize → apply loop
  - `workflows/tracing.md` — framework tracing integration

### Compatibility

- `SKILL_VERSION`: `0.1.178`
- `SKILL_MIN_CLI_VERSION`: `0.1.163` — older CLIs will see a non-blocking compat
  warning when the skill is loaded.

[0.1.208]: https://github.com/mutagent-io/skills/releases/tag/mutagent/v0.1.208
[0.1.178]: https://github.com/mutagent-io/skills/releases/tag/mutagent/v0.1.178
