#!/usr/bin/env bash
#
# Mirror the root-level skill content into `skills/<name>/` so the Claude Code
# plugin spec is satisfied while keeping the root as the single source of truth
# for crawlers and registries that expect SKILL.md at the repo root.
#
# Source of truth: ./SKILL.md, ./CHANGELOG.md, ./concepts/, ./workflows/
# Mirror destination: ./skills/<SKILL_NAME>/{SKILL.md, CHANGELOG.md, concepts/, workflows/}
#
# Why both: see the README's "Layout" section. Symlinks fail on Windows clones
# and via raw.githubusercontent.com fetches — duplication is the only robust
# option.
#
# Usage:
#   ./scripts/mirror-skill.sh          # write the mirror (idempotent)
#   ./scripts/mirror-skill.sh --check  # verify root == mirror byte-for-byte; exit 1 if not
#
# The skill name is hard-coded for the single-skill phase. When a second skill
# is added, we restructure to `skills/<name>/` as the canonical layout and
# retire this script.
#

set -euo pipefail

SKILL_NAME="mutagent-cli"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIRROR_DIR="$REPO_ROOT/skills/$SKILL_NAME"

# Items at the repo root that constitute the skill bundle. Anything else at
# root (README, CLAUDE.md, LICENSE, scripts/, .github/, etc.) is NOT mirrored.
#
# Layout follows agentskills.io / skillsdirectory.com convention: SKILL.md
# + references/ (flat directory of markdown). The legacy
# concepts/ + workflows/ split has been flattened into references/.
ITEMS=(SKILL.md CHANGELOG.md references)

MODE="apply"
if [[ "${1:-}" == "--check" ]]; then
  MODE="check"
fi

# Confirm every source item exists at root.
for item in "${ITEMS[@]}"; do
  if [[ ! -e "$REPO_ROOT/$item" ]]; then
    echo "ERROR: source-of-truth missing at root: $item" >&2
    exit 2
  fi
done

if [[ "$MODE" == "check" ]]; then
  # Strict equality check between root and mirror. Used in CI.
  fail=0
  for item in "${ITEMS[@]}"; do
    src="$REPO_ROOT/$item"
    dst="$MIRROR_DIR/$item"
    if [[ ! -e "$dst" ]]; then
      echo "MISSING from mirror: skills/$SKILL_NAME/$item" >&2
      fail=1
      continue
    fi
    if ! diff -r -q "$src" "$dst" >/dev/null 2>&1; then
      echo "DIFFERS between root and mirror: $item" >&2
      diff -r "$src" "$dst" 2>&1 | head -20 >&2 || true
      fail=1
    fi
  done

  # Catch mirror-only stragglers (files in mirror that don't exist at root).
  if [[ -d "$MIRROR_DIR" ]]; then
    while IFS= read -r path; do
      rel="${path#$MIRROR_DIR/}"
      top="${rel%%/*}"
      found=0
      for item in "${ITEMS[@]}"; do
        if [[ "$top" == "$item" ]]; then found=1; break; fi
      done
      if [[ $found -eq 0 ]]; then
        echo "MIRROR-ONLY (not in source list): skills/$SKILL_NAME/$rel" >&2
        fail=1
      fi
    done < <(find "$MIRROR_DIR" -mindepth 1 -maxdepth 1)
  fi

  if [[ $fail -ne 0 ]]; then
    echo >&2
    echo "Re-sync the mirror by running:  ./scripts/mirror-skill.sh" >&2
    exit 1
  fi
  echo "✓ root and skills/$SKILL_NAME/ are byte-identical."
  exit 0
fi

# Apply mode: re-create the mirror from root content.
# Wipe ALL existing mirror contents (not just ITEMS) so that any stale
# directories from prior layouts (e.g. legacy concepts/, workflows/) get
# cleaned out. This ensures the mirror is always a fresh, exact copy.
if [[ -d "$MIRROR_DIR" ]]; then
  find "$MIRROR_DIR" -mindepth 1 -delete
fi
mkdir -p "$MIRROR_DIR"

for item in "${ITEMS[@]}"; do
  if [[ -d "$REPO_ROOT/$item" ]]; then
    cp -R "$REPO_ROOT/$item" "$MIRROR_DIR/$item"
  else
    cp "$REPO_ROOT/$item" "$MIRROR_DIR/$item"
  fi
done

echo "✓ mirrored root → skills/$SKILL_NAME/ ($(printf '%s ' "${ITEMS[@]}"| sed 's/ $//'))"
