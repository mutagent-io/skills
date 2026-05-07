# CLAUDE.md

Guidance for AI coding agents (Claude Code, Cursor, etc.) working **inside this
repository**. If you are looking for *how to use* the skills, read
[`README.md`](./README.md) instead.

---

## What this repo is

The **public skills registry for the MutagenT platform**. It hosts user-facing
skill bundles that ship to AI coding agents — installable via
`mutagent skills install`, by direct clone, or as a git submodule.

It is **not** the source of truth. Skills are authored privately and published
here. Treat every file in this repo as world-readable.

## What lives here

```
.
├── CLAUDE.md             — this file
├── README.md             — public registry index
├── LICENSE               — MIT (skills only; the CLI has its own license)
└── <skill-name>/
    ├── SKILL.md          — entry router with frontmatter (name, description, version)
    ├── concepts/*.md     — WHY/WHAT pre-reads (load before related workflow)
    └── workflows/*.md    — HOW step sequences (CLI command flows)
```

Currently shipping:

- `mutagent-cli/` — guides agents through the MutagenT CLI (explore → upload →
  dataset → eval → optimize → trace).

Planned: `agent-builder/` (multi-turn agent design + optimization).

## What does NOT live here

These categories are off-limits in commits, file contents, and PR descriptions:

- Internal source paths from upstream repos (e.g. `mutagent-cli/src/...`,
  `mutagent/src/...`, anything resolving inside `mutagent-monorepo/`).
- Build / sync / publish scripts that reference internal layout.
- Internal decision records, RFCs, or design docs.
- TODOs, FIXMEs, or comments aimed at internal teammates.
- Relative links that escape this repo (e.g. `../../docs/...`).
- Customer data, API keys, workspace IDs, or trace payloads.

If you find any of the above when updating a skill, **strip it before
committing**. The sanitization checklist below codifies this.

## Updating an existing skill

1. Pull the latest skill bundle from upstream into the matching directory here.
2. Run the sanitization checklist (below) on every modified file.
3. If user-visible behavior changed, bump `SKILL_VERSION` in `SKILL.md`'s
   frontmatter (semver: patch for fixes, minor for additive changes, major for
   breaking router/rule changes).
4. If the skill now requires a newer CLI, bump `SKILL_MIN_CLI_VERSION` to match.
5. Update the **Skill Index** table in `README.md` (version + status).
6. Open a PR. Never push directly to `main`.

## Adding a new skill

1. Create a top-level directory `<skill-name>/`.
2. Add `SKILL.md` with frontmatter: `name`, `description`, `SKILL_VERSION`,
   `SKILL_MIN_CLI_VERSION` (if CLI-dependent).
3. Add `concepts/` and `workflows/` subfolders only if they carry weight —
   small skills can live in a single `SKILL.md`.
4. Add a row to the **Skill Index** in `README.md`.
5. Open a PR with `feat(<skill-name>): initial publish`.

## Sanitization checklist (run before every commit)

```bash
# From the repo root — should all return zero matches.
grep -rnE "(mutagent-cli/src|mutagent/src|monorepo|sync-skill)" .
grep -rnE "\.\./\.\./" .
grep -rnE "(TODO\(internal\)|FIXME\(internal\)|XXX)" .
```

In addition, eyeball any blockquote that starts with **"Canonical source"** or
**"Mirrored in"** — those usually leak internal paths. Rewrite to describe the
*concept*, not the *file*.

## House rules

- **Never push directly to `main`.** All changes go through a PR.
- **Never commit anything copied verbatim from `mutagent-monorepo/`** without
  passing the sanitization checklist.
- **Never add a relative link** that points outside this repo.
- **Treat every file as public.** If in doubt about whether something can ship,
  it can't.

## Memory and context

This repo has no CI, no build step, and no tests — it is pure markdown +
license. Don't add any of those without an explicit ask. Don't add a
`package.json`. Don't add a `Makefile`. Keep it boring.
