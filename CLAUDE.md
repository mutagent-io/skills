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
├── .github/workflows/    — validate, tag-on-merge, release, sync-from-cli
├── scripts/
│   ├── sanitize.py       — canonical public/internal filter (idempotent)
│   └── sync-from-cli.sh  — fetch + reconstitute skill from npm
└── <skill-name>/
    ├── SKILL.md          — entry router with frontmatter (name, version, min CLI)
    ├── CHANGELOG.md      — Keep-a-Changelog format, one entry per release
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

## Versioning rule (READ FIRST)

**CLI-coupled skills lock `SKILL_VERSION` to the `@mutagent/cli` version they
were synced from.** A skill bundle that documents commands and flags from a
specific CLI release is meaningless paired with a different CLI release —
version-locking eliminates that drift.

So for `mutagent-cli`:

- `SKILL_VERSION` = the CLI version this skill was synced from (e.g. `0.1.178`).
- The sync script (`scripts/sync-from-cli.sh`) bumps it automatically on every
  sync, even if no skill content changed. A "no-op sync" still produces a new
  skill release that's verified-against-the-current-CLI.
- `SKILL_MIN_CLI_VERSION` is the *looser* compat floor (oldest CLI that still
  works). Bump it only when the skill references commands/flags that older
  CLIs don't have.

**Independent skills** (not coupled to a CLI binary) may use standalone semver.
If one is added, document the exception in its own `SKILL.md` and the README.

## Updating an existing skill

The normal path is **automatic** — `.github/workflows/sync-from-cli.yml` runs
daily, opens a PR with the synced bundle and the bumped `SKILL_VERSION`. You
review, update CHANGELOG, merge.

For a manual sync:

```bash
./scripts/sync-from-cli.sh           # latest @mutagent/cli
./scripts/sync-from-cli.sh 0.1.180   # a specific version
```

The script: installs the CLI in a scratch dir, runs `mutagent skills install`,
rsyncs the result into `mutagent-cli/`, runs `scripts/sanitize.py`, bumps
`SKILL_VERSION`, prints the diff, and tells you the next git commands.

After the sync (auto or manual), before merge:

1. Review the diff for behavioral changes that warrant a `SKILL_MIN_CLI_VERSION`
   bump.
2. Add a new `[<version>]` entry to `<skill>/CHANGELOG.md` describing the
   changes (CLI release notes are a good source).
3. Update the **Skill Index** version + tag link in `README.md`.
4. Open a PR. Never push directly to `main`.

On merge: `tag-on-merge.yml` pushes `<skill>/v<version>` and `release.yml`
publishes the GitHub Release with tarball.

## Adding a new skill

1. Create a top-level directory `<skill-name>/`.
2. Add `SKILL.md` with frontmatter: `name`, `description`, `SKILL_VERSION`,
   `SKILL_MIN_CLI_VERSION` (if CLI-dependent).
3. Add `concepts/` and `workflows/` subfolders only if they carry weight —
   small skills can live in a single `SKILL.md`.
4. Add a row to the **Skill Index** in `README.md`.
5. Open a PR with `feat(<skill-name>): initial publish`.

## Sanitization

The canonical filter lives in `scripts/sanitize.py`. It encodes every
public-vs-internal substitution this registry has ever made. Run it any time
you touch a skill file:

```bash
./scripts/sanitize.py            # apply all rules to the whole repo (idempotent)
./scripts/sanitize.py --check    # verify only, exit non-zero if dirty
./scripts/sanitize.py mutagent-cli   # scope to a single skill
```

`scripts/sync-from-cli.sh` runs it automatically after every sync, and
`.github/workflows/validate.yml` runs `--check` on every PR — a leak cannot
land on `main`.

If you spot a new internal reference that the script doesn't know about, add a
rule to `RULES` in `scripts/sanitize.py`. The script will fail loudly if leaks
remain after rules run, so missing rules don't slip through silently.

## House rules

- **Never push directly to `main`.** All changes go through a PR.
- **Never commit anything copied verbatim from `mutagent-monorepo/`** without
  passing the sanitization checklist.
- **Never add a relative link** that points outside this repo.
- **Treat every file as public.** If in doubt about whether something can ship,
  it can't.

## Tooling boundary

The only first-class tooling this repo carries is:

- `scripts/sanitize.py` (Python 3 stdlib only)
- `scripts/sync-from-cli.sh` (bash + npm + node + rsync)
- `.github/workflows/*.yml` (GitHub Actions)

Don't add a `package.json`, `Makefile`, build step, or test framework. Skills
are markdown. The scaffolding above is only what's needed to publish them
safely and predictably.
