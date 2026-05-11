# Changelog — `mutagent-cli` skill

All notable changes to the `mutagent-cli` skill will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions track the [`@mutagent/cli`](https://www.npmjs.com/package/@mutagent/cli)
release this skill was synced from. See the registry's
[`README.md`](../README.md) for the full versioning model.

---

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

[0.1.178]: https://github.com/mutagent-io/skills/releases/tag/mutagent-cli/v0.1.178
