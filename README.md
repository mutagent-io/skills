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
  <a href="#"><img src="https://img.shields.io/badge/Registry-Skills-7c3aed?style=for-the-badge" alt="Skills Registry"></a>
  <a href="https://docs.claude.com/en/docs/claude-code"><img src="https://img.shields.io/badge/Claude_Code-Compatible-f97316?style=for-the-badge" alt="Claude Code Compatible"></a>
</p>

<p align="center">
  <strong>Skill plugins for AI coding agents working with the MutagenT platform.</strong>
</p>

---

## What is this?

This is the **public registry of MutagenT skills** — markdown-only bundles that
teach AI coding agents (Claude Code, Cursor, Aider, Continue, and any other
runtime that supports the Anthropic skill format) how to drive the MutagenT
platform end-to-end: from prompt discovery to optimization to framework
tracing.

A skill is a directory containing:

- `SKILL.md` — the entry router. Frontmatter declares the skill's name,
  description, version, and any minimum CLI version. The body routes the agent
  to the right workflow based on user intent.
- `concepts/*.md` — *why/what* references. Loaded on-demand to give the agent
  the conceptual frame for a task (eval rubric design, dataset principles,
  variable delimiters, scorecard interpretation).
- `workflows/*.md` — *how* step sequences. CLI command flows for concrete
  goals (optimize a prompt, curate a dataset, add tracing).

Skills are runtime-agnostic by design. They use Claude Code's skill format
because it's the most expressive, but the conventions (`AskUserQuestion`,
`--json`, directive cards) translate cleanly to any agent runtime.

---

## Skill Index

| Skill | Status | Version | Description | Min CLI |
|---|---|---|---|---|
| [`mutagent-cli`](./mutagent-cli/) | ✅ Stable | [v0.1.178](https://github.com/mutagent-io/skills/releases/tag/mutagent-cli/v0.1.178) | Guides agents through prompt upload, dataset curation, evaluation rubric creation, optimization, and framework tracing | `>= 0.1.163` |
| `agent-builder` | 🚧 Coming soon | — | Multi-turn agent design, evaluation, and optimization workflows | TBD |

> **Status legend:** ✅ Stable · 🟡 Beta · 🚧 Coming soon · ⚠️ Deprecated

---

## Install

### Recommended — via the MutagenT CLI

```bash
# Install the CLI (one of)
bun add -g @mutagent/cli
pnpm add -g @mutagent/cli
yarn global add @mutagent/cli
npm install -g @mutagent/cli

# Authenticate
mutagent login --browser

# Install all bundled skills into your project's .claude/skills/
mutagent skills install
```

`mutagent skills install` drops the appropriate `.claude/skills/<skill>/`
directory into your project so Claude Code (and any runtime that reads
`.claude/skills/`) picks it up automatically.

### Manual — clone or copy

```bash
# Clone into your project
git clone https://github.com/mutagent-io/skills .claude/skills/mutagent

# Or copy a single skill
cp -r mutagent-cli /path/to/your/project/.claude/skills/
```

### Pinned tarball (per-version, no clone)

Each tagged release ships a tarball as a release asset:

```bash
SKILL=mutagent-cli; VERSION=0.1.178
curl -L "https://github.com/mutagent-io/skills/releases/download/${SKILL}/v${VERSION}/${SKILL}-v${VERSION}.tar.gz" \
  | tar -xz -C .claude/skills/
```

### Submodule

```bash
git submodule add https://github.com/mutagent-io/skills .claude/skills/mutagent
```

---

## How an agent uses a skill

When a user's request matches a skill's trigger phrases (e.g. *"optimize this
prompt"*, *"add tracing"*), the agent loads `SKILL.md` and follows its journey
router to the matching workflow. Concept files are loaded only when the
workflow asks for them — keeping the agent's context window lean.

The skills in this registry follow a few non-negotiable conventions:

- **`--json` on every CLI call.** Agents parse structured output, not chatter.
- **Explore before modify.** Read-only discovery (`mutagent explore --json`)
  always precedes any write.
- **Cost transparency.** `mutagent usage --json` is shown to the user before
  any optimization spend.
- **Never auto-generate eval rubrics.** Rubrics are collected from the user
  field-by-field, never invented from context.

See each skill's `SKILL.md` for the full rule set.

---

## Versioning

Each skill declares its own version in `SKILL.md` frontmatter:

```yaml
SKILL_VERSION: 0.1.178         # locked to the @mutagent/cli release this skill ships with
SKILL_MIN_CLI_VERSION: 0.1.163 # minimum compatible @mutagent/cli version
```

**CLI-coupled skills (e.g. `mutagent-cli`) lock `SKILL_VERSION` to the
`@mutagent/cli` version they were synced from.** Every CLI release produces a
matching skill release, so `mutagent-cli/v0.1.178` always pairs with
`@mutagent/cli@0.1.178` — no version-skew surprises. The
`scripts/sync-from-cli.sh` script bumps `SKILL_VERSION` automatically on each
sync.

`SKILL_MIN_CLI_VERSION` is the looser compat floor: the skill works with any
CLI from this version onwards. The CLI surfaces a non-blocking warning when the
installed CLI is older.

**Independent skills** (future, non-CLI-coupled) may use their own semver. They
are noted explicitly in `CLAUDE.md`.

### Releases & tags

- Each skill has its own tag namespace: `mutagent-cli/vX.Y.Z`,
  `agent-builder/vX.Y.Z`.
- Tags are pushed automatically on merge to `main` when `SKILL_VERSION` changes
  (see `.github/workflows/tag-on-merge.yml`).
- A GitHub Release is built for every tag, with the skill's `CHANGELOG.md`
  excerpt as the release notes and a `<skill>-v<X.Y.Z>.tar.gz` asset
  (see `.github/workflows/release.yml`).

### Auto-sync

A daily GitHub Action (`.github/workflows/sync-from-cli.yml`) pulls the latest
`@mutagent/cli` from npm, runs the sync script, and opens a PR if anything
changed. You can also dispatch it manually with a specific CLI version.

---

## Contributing

Issues and PRs are welcome — especially:

- **Wording fixes** in skill prose where an agent went off-script.
- **New trigger phrases** for the journey router (real user wording you've
  seen).
- **New concept files** for cross-cutting MutagenT topics that workflows can
  pre-load.

For new top-level skills (e.g. integrations with other agent runtimes), open
an issue first to align on scope before sending a PR.

All contributors must keep the [house rules in `CLAUDE.md`](./CLAUDE.md) — no
internal paths, no relative links escaping the repo, no commits that haven't
passed the sanitization checklist.

---

## License

MIT — see [LICENSE](./LICENSE). The skills in this registry are independent
of the [MutagenT CLI license](https://www.npmjs.com/package/@mutagent/cli);
you can fork, adapt, and republish them under MIT terms.

---

<p align="center">
  Built by <a href="https://mutagent.io">Mutagent</a>
</p>
