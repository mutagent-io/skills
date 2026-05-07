#!/usr/bin/env python3
"""
Strip references to internal MutagenT monorepo paths from skill bundles.

The upstream `@mutagent/cli` ships the skill markdown verbatim — `sync-skill.ts`
does not filter internal-only references. This script applies the canonical
public-vs-internal split for every skill in this registry.

Idempotent: running twice produces the same output. Exits non-zero if any leak
pattern is still present after sanitization.

Usage:
    ./scripts/sanitize.py                  # run on the whole repo (default)
    ./scripts/sanitize.py mutagent-cli     # run on a single skill dir
    ./scripts/sanitize.py --check          # verify only, no edits
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Patterns that must NEVER appear in a published skill bundle.
LEAK_PATTERNS = [
    r"mutagent-cli/src/",
    r"mutagent/src/",
    r"sync-skill\.ts",
    r"cli-design-principles",
    r"prompt-evaluations/README",
    r"\.\./\.\./",
]
LEAK_RE = re.compile("|".join(LEAK_PATTERNS))

# Each rule = (relative_path, find_text, replace_text).
# Strings are exact matches (no regex). Idempotent: if `find` is absent, no-op.
RULES: list[tuple[str, str, str]] = [
    # --- mutagent-cli/SKILL.md ---
    (
        "mutagent-cli/SKILL.md",
        "> **Canonical source**: `mutagent-cli/.claude/skills/mutagent-cli/SKILL.md`\n"
        "> Packed into the CLI binary via `scripts/sync-skill.ts`. Installed to end-user\n"
        "> dev environments via `mutagent skills install`. Edit this file, not the installed copy.",
        "> Installed to dev environments via `mutagent skills install`. Bundled with the\n"
        "> CLI binary so it stays version-aligned. This published copy is the canonical\n"
        "> reference — edit upstream and re-publish, never the installed copy.",
    ),
    (
        "mutagent-cli/SKILL.md",
        "`mutagent login` is canonical. `mutagent auth login` is a back-compat alias. "
        "Both delegate to `lib/auth-flow.ts`. Decision record: "
        "[cli-design-principles.md](../../docs/cli-design-principles.md) -> Login Unification.",
        "`mutagent login` is canonical. `mutagent auth login` is a back-compat alias.",
    ),
    # --- mutagent-cli/concepts/eval-criteria.md ---
    (
        "mutagent-cli/concepts/eval-criteria.md",
        "  Includes current platform validation rules for criterion shape.\n"
        "  Mirrored in mutagent/src/modules/prompts/prompt-evaluations/README.md.",
        "  Includes current platform validation rules for criterion shape.",
    ),
    (
        "mutagent-cli/concepts/eval-criteria.md",
        "> **Canonical source** for the INPUT vs OUTPUT framing. Mirrored in:\n"
        "> - `mutagent-cli/src/commands/prompts/evaluation/guided-workflow.ts` — kept in sync.\n"
        "> - `mutagent/src/modules/prompts/prompt-evaluations/README.md` as BE-side\n"
        ">   reference — mirror, not a fork.",
        "> **Canonical source** for the INPUT vs OUTPUT framing used by the MutagenT\n"
        "> evaluation engine.",
    ),
    (
        "mutagent-cli/concepts/eval-criteria.md",
        "- [concepts/prompt-variables.md](./prompt-variables.md) → delimiter inference (used in MVC step)\n"
        "- `mutagent/src/modules/prompts/prompt-evaluations/README.md` → BE mirror",
        "- [concepts/prompt-variables.md](./prompt-variables.md) → delimiter inference (used in MVC step)",
    ),
    # --- mutagent-cli/concepts/dataset-design.md ---
    (
        "mutagent-cli/concepts/dataset-design.md",
        "  Parallel structure to concepts/eval-criteria.md for cognitive parity.\n"
        "  Mirrored in the CLI directive's bootstrappable instruction field.",
        "  Parallel structure to concepts/eval-criteria.md for cognitive parity.",
    ),
    (
        "mutagent-cli/concepts/dataset-design.md",
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
    # --- mutagent-cli/concepts/prompt-variables.md ---
    (
        "mutagent-cli/concepts/prompt-variables.md",
        "- [concepts/eval-criteria.md](./eval-criteria.md) → MVC (Minimum Viable Context) — uses delimiter to enumerate input params\n"
        "- Source: `mutagent-cli/src/lib/explorer.ts` → `inferPromptVariables()` and `DiscoveredPrompt.delimiter`\n"
        "- Tests: `mutagent-cli/src/__tests__/lib/explorer.test.ts`",
        "- [concepts/eval-criteria.md](./eval-criteria.md) → MVC (Minimum Viable Context) — uses delimiter to enumerate input params",
    ),
    # --- mutagent-cli/concepts/scorecard-output.md ---
    (
        "mutagent-cli/concepts/scorecard-output.md",
        "Reproduced from\n`mutagent/src/framework/metatuner/output/scorecard.ts`:",
        "The optimizer emits this shape on each iteration (TypeScript):",
    ),
]


def discover_skill_files(scope: Path) -> list[Path]:
    """Return every *.md under skill directories (anything containing SKILL.md)."""
    files: list[Path] = []
    if scope.is_file() and scope.suffix == ".md":
        return [scope]
    candidates = [scope] if (scope / "SKILL.md").is_file() else [
        d for d in scope.iterdir() if d.is_dir() and (d / "SKILL.md").is_file()
    ]
    for skill_dir in candidates:
        for md in skill_dir.rglob("*.md"):
            if md.name == "CHANGELOG.md":
                continue
            files.append(md)
    return files


def apply_rules(scope: Path, *, check_only: bool) -> tuple[int, list[Path]]:
    """Apply substitution rules. Returns (changes_made, modified_files)."""
    changes = 0
    modified: list[Path] = []
    for rel_path, find, replace in RULES:
        target = REPO_ROOT / rel_path
        try:
            target.relative_to(scope.resolve())
        except ValueError:
            # Rule's target is outside the requested scope — skip it.
            continue
        if not target.is_file():
            continue
        original = target.read_text(encoding="utf-8")
        if find not in original:
            continue
        new = original.replace(find, replace)
        if new == original:
            continue
        changes += 1
        modified.append(target)
        if not check_only:
            target.write_text(new, encoding="utf-8")
    return changes, modified


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

    changes, modified = apply_rules(scope, check_only=args.check)
    if args.check and changes:
        print(
            f"ERROR: {changes} sanitization rule(s) would be applied (run without --check):",
            file=sys.stderr,
        )
        for path in modified:
            print(f"  - {path.relative_to(REPO_ROOT)}", file=sys.stderr)
        return 1
    if changes:
        print(f"Applied {changes} sanitization rule(s):")
        for path in modified:
            print(f"  - {path.relative_to(REPO_ROOT)}")
    else:
        print("No sanitization rules applied (already clean or no matching content).")

    files = discover_skill_files(scope)
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
            "sanitizer doesn't know about. Add a rule to scripts/sanitize.py.",
            file=sys.stderr,
        )
        return 1

    print(f"\n✓ {len(files)} skill file(s) scanned, no leaks detected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
