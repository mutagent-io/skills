# CLAUDE.md

Guidance for AI coding agents (Claude Code, Cursor, etc.) working **inside this
repository**. If you are looking for *how to use* the skills, read
[`README.md`](./README.md) instead.

---

## What this repo is

The **public skills marketplace for the MutagenT platform**. It hosts
user-facing skill bundles that ship to AI coding agents — installable via
Claude Code's `/plugin marketplace add`, via `mutagent skills install`, by
direct clone, or as a git submodule.

It satisfies two compatible specs from one source of truth:

- [Agent Skills spec](https://agentskills.io/specification) — every skill at
  `skills/<name>/SKILL.md` is a valid bare skill.
- [Claude Code marketplace spec](https://code.claude.com/docs/en/plugin-marketplaces)
  — `.claude-plugin/marketplace.json` at the repo root wraps the skills as
  installable plugins.

It is **not** the source of truth for skill content. Skills are authored
privately (`@mutagent/cli` carries the canonical `mutagent-cli` skill in its
own source tree) and published here. Treat every file in this repo as
world-readable.

## What lives here

```
.
├── .claude-plugin/
│   ├── marketplace.json     — marketplace catalog (Claude Code reads this)
│   └── plugin.json          — plugin manifest (the repo itself IS the plugin)
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md         — entry router; YAML frontmatter + Markdown body
│       ├── CHANGELOG.md     — Keep-a-Changelog format, one entry per release
│       ├── concepts/*.md    — WHY/WHAT pre-reads (load before related workflow)
│       └── workflows/*.md   — HOW step sequences (CLI command flows)
├── CLAUDE.md                — this file
├── README.md                — public registry index, install paths
├── LICENSE                  — MIT (skills only; the CLI has its own license)
├── .github/workflows/       — validate, tag-on-merge, release, sync-from-cli
└── scripts/
    ├── sanitize.py          — canonical public/internal filter (idempotent)
    └── sync-from-cli.sh     — fetch + reconstitute skill from npm
```

**Layout shape.** The marketplace catalogs ONE bundled plugin
(`mutagent`) whose source is the repo root (`./`). Every skill lives
flat under `./skills/<name>/`, never nested inside a per-skill plugin
directory. This is forced by Claude Code's plugin spec: plugin source must
contain `skills/<name>/SKILL.md`, with no way to express "the source dir IS
the skill". One bundled plugin avoids the nesting redundancy.

Currently shipping:

- `skills/mutagent-cli/` — guides agents through the MutagenT CLI (explore →
  upload → dataset → eval → optimize → trace).

Planned: `skills/agent-builder/` (multi-turn agent design + optimization).
Adding it is just: drop a `skills/agent-builder/` dir with a SKILL.md; bump
the plugin version; ship.

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
committing**. `scripts/sanitize.py --check` is the gate; CI fails on leaks.

## Versioning rule (READ FIRST)

**There is one plugin version.** It lives in two files kept in lockstep by
the sync script:

- `.claude-plugin/plugin.json` → `version`
- `.claude-plugin/marketplace.json` → `plugins[name="mutagent"].version`

Tags follow `mutagent/v<X.Y.Z>` and are pushed automatically by
`.github/workflows/tag-on-merge.yml` when the version field in
`marketplace.json` changes on `main`.

For CLI-coupled syncs (`mutagent-cli` skill from `@mutagent/cli`), the plugin
version is bumped in lockstep with the synced CLI release. The sync script
(`scripts/sync-from-cli.sh`) handles the bump automatically — even on no-op
syncs, the plugin version moves to whatever the CLI is at, so each release is
a verified-against-the-current-CLI artifact.

Each individual skill's `SKILL.md` frontmatter currently carries
`SKILL_VERSION` and `SKILL_MIN_CLI_VERSION` as top-level keys, mirrored from
the upstream CLI's `.claude/skills/` source. These are **informational** and
may not strictly conform to the Agent Skills spec (which expects custom keys
under `metadata:`). The proper fix is upstream in the CLI's `sync-skill.ts`.
Do not hand-rewrite the frontmatter here — every sync would clobber it.

**Future skills** (e.g. `agent-builder`) join the same plugin bundle. Their
content updates bump the same plugin version. If a skill ever wants
independent install/update granularity, that's a future decision to split the
marketplace into multiple plugin entries.

## Updating an existing skill

The normal path is **automatic** — `.github/workflows/sync-from-cli.yml` runs
daily, opens a PR with the synced bundle and the bumped plugin version. You
review, update CHANGELOG, merge.

For a manual sync:

```bash
./scripts/sync-from-cli.sh           # latest @mutagent/cli
./scripts/sync-from-cli.sh 0.1.180   # a specific version
```

The script: installs the CLI in a scratch dir, runs `mutagent skills install`,
rsyncs the result into `skills/mutagent-cli/`, runs `scripts/sanitize.py`,
bumps the plugin version in both `marketplace.json` and `plugin.json`, prints
the diff, and tells you the next git commands.

After the sync (auto or manual), before merge:

1. Review the diff for behavioral changes.
2. Add a new `[<version>]` entry to `skills/mutagent-cli/CHANGELOG.md`
   describing the changes (CLI release notes are a good source).
3. Open a PR. Never push directly to `main`.

On merge: `tag-on-merge.yml` pushes `mutagent/v<version>` and
`release.yml` publishes the GitHub Release with tarball.

## Adding a new skill

The single-plugin layout makes this lightweight — drop a directory under
`skills/`, no marketplace.json plugin-entry edits needed.

1. Create `skills/<new-name>/SKILL.md` with valid frontmatter per the
   [Agent Skills spec](https://agentskills.io/specification):
   - `name` — must match the folder name exactly. Lowercase a-z + digits +
     hyphens only. 1-64 chars. No leading/trailing hyphen, no `--`.
   - `description` — what the skill does AND when to use it (triggers, file
     types, scenarios). 1-1024 chars. Vague descriptions get rejected by
     downstream registries.
2. Bump the plugin version in `.claude-plugin/plugin.json` and the
   `mutagent` entry in `.claude-plugin/marketplace.json`. Use semver:
   minor bump for the new skill (additive), patch for content updates only.
3. Add `skills/<new-name>/CHANGELOG.md` with the initial release entry.
4. Validate locally:
   ```bash
   skills-ref validate ./skills/<new-name>
   claude plugin validate .
   ./scripts/sanitize.py --check
   ```
5. Open a PR with `feat(<new-name>): initial publish`.

## Sanitization

The canonical filter lives in `scripts/sanitize.py`. It encodes every
public-vs-internal substitution this registry has ever made and is
path-agnostic (rules are applied across every discovered SKILL.md and its
siblings, with no hardcoded file paths).

```bash
./scripts/sanitize.py            # apply all rules to the whole repo (idempotent)
./scripts/sanitize.py --check    # verify only, exit non-zero if dirty
./scripts/sanitize.py skills/<name>   # scope to a single skill
```

`scripts/sync-from-cli.sh` runs it automatically after every sync, and
`.github/workflows/validate.yml` runs `--check` on every PR — a leak cannot
land on `main`.

If you spot a new internal reference that the script doesn't know about, add a
`(find, replace)` 2-tuple to the `RULES` list in `scripts/sanitize.py`. The
script will fail loudly if leaks remain after rules run, so missing rules
don't slip through silently.

## House rules

- **Never push directly to `main`.** All changes go through a PR.
- **Never commit anything copied verbatim from `mutagent-monorepo/`** without
  passing the sanitization checklist.
- **Never add a relative link** that points outside this repo.
- **Never rewrite SKILL.md frontmatter** here — it's auto-synced from the CLI;
  the proper fix is upstream.
- **Treat every file as public.** If in doubt about whether something can
  ship, it can't.

## Validation stack

Three checks run on every PR:

1. **`./scripts/sanitize.py --check`** — internal-leak guard (this repo's
   responsibility).
2. **[`skills-ref`](https://github.com/agentskills/agentskills)
   `validate ./skills/<name>`** — Agent Skills spec compliance (frontmatter
   shape, name format, description length, file layout).
3. **`claude plugin validate .`** — Claude Code marketplace wrapper compliance
   (manifest schema, source path resolution, plugin structure).

All three must pass. They cover non-overlapping layers and don't conflict.

## Tooling boundary

The only first-class tooling this repo carries is:

- `scripts/sanitize.py` (Python 3 stdlib only)
- `scripts/sync-from-cli.sh` (bash + npm + node + rsync)
- `.github/workflows/*.yml` (GitHub Actions; CI also installs `skills-ref` and
  `@anthropic-ai/claude-code` for the validation jobs)

Don't add a `package.json`, `Makefile`, build step, or test framework in the
repo root. Skills are markdown. The scaffolding above is only what's needed
to publish them safely and predictably.
