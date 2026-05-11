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
  <a href="#"><img src="https://img.shields.io/badge/Marketplace-mutagent-7c3aed?style=for-the-badge" alt="Marketplace: mutagent"></a>
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
  whole catalog; `/plugin install <plugin>@mutagent-io` installs one plugin.
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
/plugin install mutagent@mutagent-io
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
│   └── marketplace.json          # Catalog read by /plugin marketplace add
├── skills/
│   └── mutagent-cli/
│       ├── SKILL.md              # Entry router (frontmatter + body)
│       ├── CHANGELOG.md
│       ├── concepts/             # WHY/WHAT pre-reads
│       └── workflows/            # HOW step sequences
└── ...
```

Every skill is a directory under `skills/` containing at minimum a `SKILL.md`.
The directory name and the `name:` field in the SKILL frontmatter must match
(both kebab-case). All paths in `marketplace.json` are relative — never
escapes the repo root.

---

## How an agent uses a skill

Skills are **model-invoked**, not slash-commanded: Claude reads each skill's
`description` frontmatter at startup and auto-loads the matching one when a
user's request lines up with its triggers. The body of `SKILL.md` then routes
the agent to a specific `workflows/` file; `concepts/` pages are loaded only
when a workflow asks for them.

Non-negotiable conventions every skill in this marketplace follows:

- **`--json` on every CLI call** — agents parse structured output.
- **Explore before modify** — read-only discovery precedes any write.
- **Cost transparency** — usage shown to the user before any LLM spend.
- **Never auto-generate eval rubrics** — collected from the user, never
  invented.

See each skill's `SKILL.md` for the full rule set.

---

## How to add a new skill

The marketplace ships one bundled plugin (`mutagent`). Adding a skill
means dropping a new directory under `./skills/` — no marketplace.json edits
needed unless you want different metadata.

1. Create `skills/<new-name>/SKILL.md` with valid frontmatter — the `name`
   field must match the folder name exactly (kebab-case, no leading/trailing
   hyphen, no consecutive `--`, ≤ 64 chars). The `description` must explain
   **what** the skill does AND **when** to use it (triggers, file types,
   scenarios), ≤ 1024 chars. See [`agentskills.io/specification`][spec] for
   the full frontmatter rules.
2. Bump the plugin version in both `.claude-plugin/plugin.json` and the
   `mutagent` entry in `.claude-plugin/marketplace.json` (semver:
   minor for new skills, patch for content updates).
3. Add a `skills/<new-name>/CHANGELOG.md` with the initial release entry.
4. Validate locally:
   ```bash
   skills-ref validate ./skills/<new-name>   # Agent Skills spec
   claude plugin validate .                  # marketplace + plugin wrapper
   ./scripts/sanitize.py --check             # internal-leak guard
   ```
5. Open a PR. CI runs the same three validators on every PR.

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
