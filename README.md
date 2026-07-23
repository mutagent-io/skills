# MutagenT Skills

```
  ███╗   ███╗██╗   ██╗████████╗ █████╗  ██████╗ ███████╗███╗   ██╗████████╗
  ████╗ ████║██║   ██║╚══██╔══╝██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝
  ██╔████╔██║██║   ██║   ██║   ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║
  ██║╚██╔╝██║██║   ██║   ██║   ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║
  ██║ ╚═╝ ██║╚██████╔╝   ██║   ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║
  ╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝
                  ███████╗██╗  ██╗██╗██╗     ██╗     ███████╗
                  ██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝
                  ███████╗█████╔╝ ██║██║     ██║     ███████╗
                  ╚════██║██╔═██╗ ██║██║     ██║     ╚════██║
                  ███████║██║  ██╗██║███████╗███████╗███████║
                  ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚══════╝
```

<p align="center">
  <a href="https://www.npmjs.com/package/@mutagent/cli"><img src="https://img.shields.io/npm/v/@mutagent/cli?style=for-the-badge&color=cb3837&logo=npm&logoColor=white&label=CLI" alt="CLI on npm"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge" alt="License: MIT"></a>
  <a href="#"><img src="https://img.shields.io/badge/Marketplace-mutagent--skills-7c3aed?style=for-the-badge" alt="Marketplace: mutagent-skills"></a>
  <a href="https://docs.claude.com/en/docs/claude-code"><img src="https://img.shields.io/badge/Claude_Code-Plugin-f97316?style=for-the-badge" alt="Claude Code Plugin"></a>
  <a href="https://agentskills.io"><img src="https://img.shields.io/badge/Agent_Skills-Spec-2563eb?style=for-the-badge" alt="Agent Skills spec"></a>
</p>

<p align="center">
  <strong>Official MutagenT skills for AI coding agents — MutagenT is the platform for optimizing prompts and agents.</strong>
</p>

---

## What is this?

The **public marketplace of MutagenT skills** for AI coding agents (Claude Code,
Cursor, Aider, Continue — anything that consumes the [Agent Skills
spec](https://agentskills.io/specification)). Each skill teaches the agent how
to drive one part of the MutagenT platform: prompt optimization, evaluation,
dataset curation, observability, and agent design.

The repository serves **two compatible formats from a single source of truth**:

- **Claude Code plugin marketplace** — `/plugin marketplace add` installs the
  whole catalog; `/plugin install <plugin>@mutagent-skills` installs one plugin.
- **Bare [Agent Skills](https://agentskills.io)** — every skill lives at
  `skills/<name>/SKILL.md` and is consumable by any registry, crawler, or
  runtime that reads the open spec.

---

## Skill Index

The marketplace ships one bundled plugin (`mutagent`) that contains every skill. Releases are tagged at the plugin level: [`mutagent/v0.1.178`](https://github.com/mutagent-io/skills/releases/tag/mutagent/v0.1.178).

| Skill | Status | Path | Description |
|---|---|---|---|
| [`mutagent-cli`](./skills/mutagent-cli/) | ✅ Stable | `skills/mutagent-cli/` | Prompt upload, dataset curation, evaluation rubric creation, optimization, and framework tracing via [`@mutagent/cli`](https://www.npmjs.com/package/@mutagent/cli). |
| `agent-builder` | 🚧 Coming soon | `skills/agent-builder/` | Multi-turn agent design, evaluation, and optimization workflows. |

> **Status legend:** ✅ Stable · 🟡 Beta · 🚧 Coming soon · ⚠️ Deprecated

---

## Install

### Recommended — via Claude Code marketplace

```bash
# Inside Claude Code
/plugin marketplace add mutagent-io/skills
/plugin install mutagent@mutagent-skills
```

That's it. Claude Code reads `.claude-plugin/marketplace.json` from this repo
and caches the bundled `mutagent` plugin under
`~/.claude/plugins/cache/`. Every skill inside (`mutagent-cli`, etc.) is
auto-invoked when the agent detects matching trigger phrases (e.g. *"optimize
this prompt"*, *"add tracing"*). Skill namespace: `/mutagent:mutagent-cli`.

### Alternative — via the MutagenT CLI

```bash
# Install the CLI (one of)
bun add -g @mutagent/cli
pnpm add -g @mutagent/cli
yarn global add @mutagent/cli
npm install -g @mutagent/cli

# Authenticate
mutagent login --browser

# Install the bundled skill into your project's .claude/skills/
mutagent skills install
```

`mutagent skills install` writes `.claude/skills/mutagent-cli/` into your
project root. Useful if you already use the MutagenT CLI and don't want to
involve Claude Code's plugin manager.

### Pinned tarball (per-version, no clone)

Each tagged release ships a tarball as a release asset (contains
`.claude-plugin/`, `skills/`, `LICENSE`, `README.md`):

```bash
VERSION=0.1.178
curl -L "https://github.com/mutagent-io/skills/releases/download/mutagent/v${VERSION}/mutagent-v${VERSION}.tar.gz" \
  | tar -xz -C ./my-skills-snapshot
```

### Clone or submodule

```bash
# Clone the whole repo
git clone https://github.com/mutagent-io/skills

# Or as a submodule
git submodule add https://github.com/mutagent-io/skills .claude/skills/mutagent

# Then copy a specific skill where Claude Code will pick it up
cp -r skills/mutagent-cli /path/to/your/project/.claude/skills/
```

---

## Layout

```
.
├── .claude-plugin/
│   ├── marketplace.json          # Catalog read by /plugin marketplace add
│   └── plugin.json               # Plugin manifest (repo root is the plugin)
├── SKILL.md                      # ← source of truth (root, for crawlers)
├── CHANGELOG.md
├── references/                   # spec-required parent folder
│   ├── concepts/                 #   WHY/WHAT — design references
│   │   ├── dataset-design.md
│   │   ├── eval-criteria.md
│   │   ├── prompt-variables.md
│   │   └── scorecard-output.md
│   └── workflows/                #   HOW — step sequences
│       ├── agents.md
│       ├── dataset-curation.md
│       ├── eval-creation.md
│       ├── exploration.md
│       ├── optimization.md
│       └── tracing.md
├── skills/
│   └── mutagent-cli/             # ← byte-identical mirror (Claude Code spec)
│       ├── SKILL.md              #   regenerated by scripts/mirror-skill.sh
│       ├── CHANGELOG.md          #   CI enforces parity with root
│       └── references/           #   same nested concepts/+workflows/ shape
└── ...
```

**Why both locations.** The skill content lives in two places because two
groups of consumers want it in different layouts:

- **Crawlers / registries** (SkillsMP, claudeskills.info, Lobehub, SkillRegistry,
  majiayu000/claude-skill-registry) look for `SKILL.md` at or near the repo
  root — that's the bare [Agent Skills spec](https://agentskills.io/specification)
  convention.
- **Claude Code's plugin system** requires `<plugin-source>/skills/<name>/SKILL.md`
  — a fixed two-level nesting from the plugin source. There's no validator-
  accepted way to put SKILL.md at the plugin root.

The root copy is the **source of truth**. `skills/mutagent-cli/` is a
byte-identical mirror, regenerated by `scripts/mirror-skill.sh` and enforced
by a CI parity check (`validate.yml` → `mirror-check` job).

Symlinks would break on Windows clones (Git stores them as text files
containing the target path) and via `raw.githubusercontent.com` fetches.
Committed duplicates are the only universally-robust option.

When a second skill is added (e.g. `agent-builder`), we'll restructure to
`skills/<name>/` as the sole canonical layout — at that point root-level
SKILL.md only makes sense for single-skill repos.

---

## How an agent uses a skill

Skills are **model-invoked**, not slash-commanded: Claude reads each skill's
`description` frontmatter at startup and auto-loads the matching one when a
user's request lines up with its triggers. The body of `SKILL.md` then routes
the agent to specific files under `references/` — the journey router knows
which references hold the WHY (concept docs) and which hold the HOW (step
sequences).

Non-negotiable conventions every skill in this marketplace follows:

- **`--json` on every CLI call** — agents parse structured output.
- **Explore before modify** — read-only discovery precedes any write.
- **Cost transparency** — usage shown to the user before any LLM spend.
- **Never auto-generate eval rubrics** — collected from the user, never
  invented.

See each skill's `SKILL.md` for the full rule set.

---

## How to add a new skill

The current single-skill layout has root as source of truth + a `skills/<name>/`
mirror. When a second skill is added, we restructure: root-level SKILL.md
goes away (it only makes sense for single-skill repos), and every skill lives
canonically under `skills/<name>/`. The PR that introduces the second skill
also drops the mirror script and CI parity job — they're no longer needed.

### For the future second skill

1. Restructure: move the existing root files (`SKILL.md`, `CHANGELOG.md`,
   `references/`) back to `skills/mutagent-cli/` as their canonical home;
   delete the now-empty top-level copies.
2. Create `skills/<new-name>/SKILL.md` with valid frontmatter — the `name`
   field must match the folder name exactly (kebab-case, no leading/trailing
   hyphen, no consecutive `--`, ≤ 64 chars). The `description` must explain
   **what** the skill does AND **when** to use it (triggers, file types,
   scenarios), ≤ 1024 chars. See [`agentskills.io/specification`][spec] for
   the full frontmatter rules.
3. Bump the plugin version in both `.claude-plugin/plugin.json` and the
   `mutagent` entry in `.claude-plugin/marketplace.json` (semver: minor for
   new skills, patch for content updates).
4. Add `skills/<new-name>/CHANGELOG.md` with the initial release entry.
5. Delete `scripts/mirror-skill.sh` and the `mirror-check` job in
   `.github/workflows/validate.yml` — no longer needed once there's no
   root copy.
6. Validate locally:
   ```bash
   skills-ref validate ./skills/<new-name>   # Agent Skills spec
   claude plugin validate .                  # marketplace + plugin wrapper
   ./scripts/sanitize.py --check             # internal-leak guard
   ```
7. Open a PR. CI runs the same three validators on every PR.

### For editing the existing skill (while in single-skill mode)

Edit at root (`./SKILL.md`, `./references/`). Then run
`./scripts/mirror-skill.sh` to refresh the `skills/mutagent-cli/` mirror.
The CI `mirror-check` job fails on any byte-level drift.

[spec]: https://agentskills.io/specification

---

## Versioning

The bundled `mutagent` plugin has a single version (in both
`.claude-plugin/plugin.json` and the `mutagent` entry in
`.claude-plugin/marketplace.json`, kept in lockstep by the sync script).
Tags follow `mutagent/v<X.Y.Z>` and are pushed automatically when the
version field changes on `main` (see `.github/workflows/tag-on-merge.yml`).

For CLI-coupled releases, the plugin version is bumped in lockstep with the
synced `@mutagent/cli` release — `mutagent/v0.1.178` was synced from
`@mutagent/cli@0.1.178`. When non-CLI-coupled skills (e.g. `agent-builder`)
land later, the plugin version moves on whichever event triggered it (any
content change in any skill).

A daily GitHub Action (`.github/workflows/sync-from-cli.yml`) checks npm for
new `@mutagent/cli` releases, runs the sync script, and opens a PR if
anything changed.

---

## Validation

Two complementary validators run on every PR:

- **[`skills-ref`](https://github.com/agentskills/agentskills)** — validates
  each skill against the open Agent Skills spec (frontmatter shape, name
  format, description length, file layout).
- **`claude plugin validate`** — validates the marketplace + plugin wrapper
  (manifest schema, source path resolution, no-`..` rule).

Both must pass. Plus our own `scripts/sanitize.py --check` catches any
internal-monorepo references that slip in via the auto-sync.

---

## Contributing

Issues and PRs are welcome — especially:

- **Wording fixes** in skill prose where an agent went off-script.
- **New trigger phrases** for the journey router (real user wording you've
  seen in production).
- **New concept files** for cross-cutting MutagenT topics that workflows can
  pre-load.
- **New skills** following the procedure above.

All contributors must keep the [house rules in `CLAUDE.md`](./CLAUDE.md) — no
internal paths, no relative links escaping the repo, no commits that haven't
passed the validators.

---

## License

MIT — see [LICENSE](./LICENSE). The skills in this marketplace are licensed
independently of the [MutagenT CLI](https://www.npmjs.com/package/@mutagent/cli);
you can fork, adapt, and republish them under MIT terms.

---

<p align="center">
  Built by <a href="https://mutagent.io">Mutagent</a>
</p>
