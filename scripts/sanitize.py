#!/usr/bin/env python3
"""
Strip references to internal MutagenT monorepo paths from skill bundles.

The upstream `@mutagent/cli` ships the skill markdown verbatim — `sync-skill.ts`
does not filter internal-only references. This script applies the canonical
public-vs-internal split for every skill in this registry.

Idempotent: running twice produces the same output. Exits non-zero if any leak
pattern is still present after sanitization. Path-agnostic: every rule is a
(find, replace) pair applied across every skill markdown file in scope, so
restructuring the repo layout doesn't break rules.

Usage:
    ./scripts/sanitize.py                  # run on the whole repo (default)
    ./scripts/sanitize.py skills/<name>    # run on a single skill dir
    ./scripts/sanitize.py --check          # verify only, no edits
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Patterns that must NEVER appear in a published skill bundle.
#
# The `\.\./\.\./` pattern catches "escape from skill bundle" relative refs.
# Under the references/{concepts,workflows}/ nested layout, `../../SKILL.md`
# and `../../CHANGELOG.md` are LEGITIMATE (skill files going up two levels
# to the skill root). The negative-lookahead allows those two while still
# flagging anything else (e.g. `../../docs/internal-thing`).
LEAK_PATTERNS = [
    r"mutagent-cli/src/",
    r"mutagent/src/",
    r"sync-skill\.ts",
    r"cli-design-principles",
    r"prompt-evaluations/README",
    r"\.\./\.\./(?!SKILL\.md|CHANGELOG\.md)",
]
LEAK_RE = re.compile("|".join(LEAK_PATTERNS))

# Directories to skip during skill-file discovery.
SKIP_DIR_NAMES = {".sync-tmp", ".git", "node_modules"}

# Each rule = (find_text, replace_text). Strings are exact matches (no regex).
# Idempotent: if `find` is absent, no-op. Rules are applied to every skill
# markdown file — the multi-line `find` strings are specific enough that they
# will only match where intended.
RULES: list[tuple[str, str]] = [
    # --- SKILL.md (canonical-source blockquote referencing internal layout) ---
    (
        "> **Canonical source**: `mutagent-cli/.claude/skills/mutagent-cli/SKILL.md`\n"
        "> Packed into the CLI binary via `scripts/sync-skill.ts`. Installed to end-user\n"
        "> dev environments via `mutagent skills install`. Edit this file, not the installed copy.",
        "> Installed to dev environments via `mutagent skills install`. Bundled with the\n"
        "> CLI binary so it stays version-aligned. This published copy is the canonical\n"
        "> reference — edit upstream and re-publish, never the installed copy.",
    ),
    # --- SKILL.md (dangling decision-record link to monorepo docs/) ---
    (
        "`mutagent login` is canonical. `mutagent auth login` is a back-compat alias. "
        "Both delegate to `lib/auth-flow.ts`. Decision record: "
        "[cli-design-principles.md](../../docs/cli-design-principles.md) -> Login Unification.",
        "`mutagent login` is canonical. `mutagent auth login` is a back-compat alias.",
    ),
    # --- concepts/eval-criteria.md (BE-mirror reference in frontmatter description) ---
    (
        "  Includes current platform validation rules for criterion shape.\n"
        "  Mirrored in mutagent/src/modules/prompts/prompt-evaluations/README.md.",
        "  Includes current platform validation rules for criterion shape.",
    ),
    # --- concepts/eval-criteria.md (4-line canonical-source blockquote) ---
    (
        "> **Canonical source** for the INPUT vs OUTPUT framing. Mirrored in:\n"
        "> - `mutagent-cli/src/commands/prompts/evaluation/guided-workflow.ts` — kept in sync.\n"
        "> - `mutagent/src/modules/prompts/prompt-evaluations/README.md` as BE-side\n"
        ">   reference — mirror, not a fork.",
        "> **Canonical source** for the INPUT vs OUTPUT framing used by the MutagenT\n"
        "> evaluation engine.",
    ),
    # --- concepts/eval-criteria.md (BE-mirror cross-reference line) ---
    (
        "- [concepts/prompt-variables.md](./prompt-variables.md) → delimiter inference (used in MVC step)\n"
        "- `mutagent/src/modules/prompts/prompt-evaluations/README.md` → BE mirror",
        "- [concepts/prompt-variables.md](./prompt-variables.md) → delimiter inference (used in MVC step)",
    ),
    # --- concepts/dataset-design.md (frontmatter description line) ---
    (
        "  Parallel structure to concepts/eval-criteria.md for cognitive parity.\n"
        "  Mirrored in the CLI directive's bootstrappable instruction field.",
        "  Parallel structure to concepts/eval-criteria.md for cognitive parity.",
    ),
    # --- concepts/dataset-design.md (canonical-source blockquote w/ internal path) ---
    (
        "> **Parallel to** [concepts/eval-criteria.md](./eval-criteria.md) -- same section\n"
        "> structure so agents can navigate both consistently.\n"
        ">\n"
        "> **Canonical source** for dataset curation principles. Mirrored inline in\n"
        "> `mutagent-cli/src/commands/prompts/guided-dataset.ts` (directive instruction field)\n"
        "> so even agents without the Skill loaded can execute correctly.",
        "> **Parallel to** [concepts/eval-criteria.md](./eval-criteria.md) -- same section\n"
        "> structure so agents can navigate both consistently.\n"
        ">\n"
        "> **Canonical source** for dataset curation principles.",
    ),
    # --- concepts/prompt-variables.md (Source + Tests cross-references) ---
    (
        "- [concepts/eval-criteria.md](./eval-criteria.md) → MVC (Minimum Viable Context) — uses delimiter to enumerate input params\n"
        "- Source: `mutagent-cli/src/lib/explorer.ts` → `inferPromptVariables()` and `DiscoveredPrompt.delimiter`\n"
        "- Tests: `mutagent-cli/src/__tests__/lib/explorer.test.ts`",
        "- [concepts/eval-criteria.md](./eval-criteria.md) → MVC (Minimum Viable Context) — uses delimiter to enumerate input params",
    ),
    # --- concepts/scorecard-output.md (Reproduced from <internal path>) ---
    (
        "Reproduced from\n`mutagent/src/framework/metatuner/output/scorecard.ts`:",
        "The optimizer emits this shape on each iteration (TypeScript):",
    ),
]


def discover_skill_files(scope: Path) -> list[Path]:
    """Return every markdown file in a skill bundle. A skill bundle is a
    directory containing a SKILL.md. Per agentskills.io / skillsdirectory.com,
    a skill includes:
      - <skill_dir>/SKILL.md
      - <skill_dir>/references/**/*.md   (recursive — agentskills.io allows
        subdirs under references/; we ship `concepts/` + `workflows/` there
        to preserve the journey-router taxonomy without flattening)

    Anything else in the parent dir (README, CLAUDE.md, LICENSE, etc.) is NOT
    part of the skill bundle and is out of scope. This matters when the skill
    lives at the repo root — otherwise we'd pull in repo-level docs.

    CHANGELOG.md is always excluded (per-release, not authored skill content).
    Scratch/build dirs (.sync-tmp, .git, node_modules) are skipped.
    """
    if scope.is_file() and scope.suffix == ".md":
        return [scope]

    skill_dirs: set[Path] = set()
    for skill_md in scope.rglob("SKILL.md"):
        if any(part in SKIP_DIR_NAMES for part in skill_md.parts):
            continue
        skill_dirs.add(skill_md.parent)

    files: list[Path] = []
    seen: set[Path] = set()
    for skill_dir in skill_dirs:
        # SKILL.md itself
        skill_md = skill_dir / "SKILL.md"
        if skill_md.is_file() and skill_md not in seen:
            files.append(skill_md)
            seen.add(skill_md)
        # references/ subtree — recurse to pick up concepts/, workflows/, etc.
        references = skill_dir / "references"
        if not references.is_dir():
            continue
        for md in references.rglob("*.md"):
            if any(part in SKIP_DIR_NAMES for part in md.parts):
                continue
            if md.name == "CHANGELOG.md":
                continue
            if md in seen:
                continue
            files.append(md)
            seen.add(md)
    return files


def apply_rules(files: list[Path], *, check_only: bool) -> tuple[int, list[Path]]:
    """Apply every (find, replace) rule to every discovered skill file.
    Returns (rule_applications, files_modified)."""
    applications = 0
    modified: list[Path] = []
    for path in files:
        original = path.read_text(encoding="utf-8")
        new = original
        for find, replace in RULES:
            if find in new:
                new = new.replace(find, replace)
                applications += 1
        if new != original:
            modified.append(path)
            if not check_only:
                path.write_text(new, encoding="utf-8")
    return applications, modified


def scan_leaks(files: list[Path]) -> list[tuple[Path, int, str]]:
    """Return (file, line_no, line) for every leak match."""
    hits: list[tuple[Path, int, str]] = []
    for path in files:
        for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if LEAK_RE.search(line):
                hits.append((path, lineno, line.rstrip()))
    return hits


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    parser.add_argument(
        "scope",
        nargs="?",
        default=str(REPO_ROOT),
        help="File or directory to sanitize (default: repo root)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify only — do not modify files. Exits non-zero if leaks remain.",
    )
    args = parser.parse_args()

    scope = Path(args.scope).resolve()
    if not scope.exists():
        print(f"ERROR: scope does not exist: {scope}", file=sys.stderr)
        return 2

    files = discover_skill_files(scope)
    applications, modified = apply_rules(files, check_only=args.check)

    if args.check and applications:
        print(
            f"ERROR: {applications} sanitization rule application(s) would run "
            f"(re-run without --check):",
            file=sys.stderr,
        )
        for path in modified:
            print(f"  - {path.relative_to(REPO_ROOT)}", file=sys.stderr)
        return 1

    if applications:
        print(f"Applied {applications} sanitization rule application(s) across {len(modified)} file(s):")
        for path in modified:
            print(f"  - {path.relative_to(REPO_ROOT)}")
    else:
        print("No sanitization rules applied (already clean or no matching content).")

    leaks = scan_leaks(files)
    if leaks:
        print(
            f"\nERROR: {len(leaks)} leak match(es) remain after sanitization:",
            file=sys.stderr,
        )
        for path, lineno, line in leaks:
            print(f"  {path.relative_to(REPO_ROOT)}:{lineno}: {line}", file=sys.stderr)
        print(
            "\nThis means a new internal reference appeared upstream that the "
            "sanitizer doesn't know about. Add a rule to RULES in scripts/sanitize.py.",
            file=sys.stderr,
        )
        return 1

    print(f"\n✓ {len(files)} skill file(s) scanned, no leaks detected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
