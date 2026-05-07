#!/usr/bin/env bash
#
# Sync the mutagent-cli skill bundle from a published @mutagent/cli release.
#
# Flow:
#   1. Install @mutagent/cli@<version> into a throwaway temp dir
#   2. Run `mutagent skills install` inside a scratch git repo to materialize
#      the embedded skill markdown to disk
#   3. rsync the result into ./mutagent-cli/, preserving CHANGELOG.md
#   4. Run scripts/sanitize.py to strip internal references
#   5. Bump SKILL_VERSION in SKILL.md to match the synced CLI version
#   6. Print a diff summary and suggested next steps
#
# Usage:
#   ./scripts/sync-from-cli.sh                 # syncs from @mutagent/cli@latest
#   ./scripts/sync-from-cli.sh 0.1.178         # syncs from a specific version
#   ./scripts/sync-from-cli.sh latest          # explicit "latest"
#

set -euo pipefail

VERSION="${1:-latest}"
SKILL_NAME="mutagent-cli"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$REPO_ROOT/.sync-tmp"
TARGET_DIR="$REPO_ROOT/$SKILL_NAME"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: '$1' is required but not on PATH." >&2
    exit 2
  }
}
require node
require npm
require rsync
require python3

echo "==> Preparing scratch dirs at $TMP"
rm -rf "$TMP"
mkdir -p "$TMP/install" "$TMP/scratch"

echo "==> Installing @mutagent/cli@$VERSION"
(
  cd "$TMP/install"
  npm init -y >/dev/null
  npm install --silent --no-audit --no-fund "@mutagent/cli@$VERSION"
)

CLI_VERSION="$(node -p "require('$TMP/install/node_modules/@mutagent/cli/package.json').version")"
echo "    Resolved CLI version: $CLI_VERSION"

echo "==> Running 'mutagent skills install' in scratch"
(
  cd "$TMP/scratch"
  git init -q
  "$TMP/install/node_modules/.bin/mutagent" skills install --json >/dev/null
)

INSTALLED_DIR="$TMP/scratch/.claude/skills/$SKILL_NAME"
if [[ ! -d "$INSTALLED_DIR" ]]; then
  echo "ERROR: 'skills install' did not produce $INSTALLED_DIR" >&2
  exit 1
fi

echo "==> Rsyncing skill into $TARGET_DIR (preserving CHANGELOG.md)"
mkdir -p "$TARGET_DIR"
rsync -a --delete \
  --exclude='CHANGELOG.md' \
  "$INSTALLED_DIR/" "$TARGET_DIR/"

echo "==> Sanitizing"
"$REPO_ROOT/scripts/sanitize.py" "$TARGET_DIR"

echo "==> Bumping SKILL_VERSION to $CLI_VERSION"
SKILL_FILE="$TARGET_DIR/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "ERROR: $SKILL_FILE missing after sync" >&2
  exit 1
fi
# Replace the SKILL_VERSION line in YAML frontmatter. POSIX sed differs between
# macOS and GNU; use python for portability.
python3 - "$SKILL_FILE" "$CLI_VERSION" <<'PY'
import sys, re, pathlib
path = pathlib.Path(sys.argv[1])
version = sys.argv[2]
text = path.read_text(encoding="utf-8")
new, n = re.subn(
    r"^SKILL_VERSION: .*$",
    f"SKILL_VERSION: {version}",
    text,
    count=1,
    flags=re.MULTILINE,
)
if n == 0:
    print(f"ERROR: no SKILL_VERSION line found in {path}", file=sys.stderr)
    sys.exit(1)
path.write_text(new, encoding="utf-8")
PY

echo
echo "==> Diff summary"
cd "$REPO_ROOT"
if git diff --quiet -- "$SKILL_NAME/"; then
  echo "    (no changes — repo already up-to-date with CLI v$CLI_VERSION)"
  exit 0
fi
git diff --stat -- "$SKILL_NAME/"

echo
cat <<EOF
==> Done. CLI v$CLI_VERSION synced into $SKILL_NAME/.

Next steps (manual):
  1. Review the diff:
       git diff -- $SKILL_NAME/
  2. Update $SKILL_NAME/CHANGELOG.md with a [$CLI_VERSION] entry summarizing changes.
  3. If MIN_CLI_VERSION needs to move forward (e.g. new CLI commands referenced),
     bump SKILL_MIN_CLI_VERSION in $SKILL_NAME/SKILL.md.
  4. Commit and open a PR:
       git checkout -b sync/cli-v$CLI_VERSION
       git add $SKILL_NAME/
       git commit -m "sync: $SKILL_NAME from CLI v$CLI_VERSION"
       git push -u origin sync/cli-v$CLI_VERSION
       gh pr create --base main --title "sync: $SKILL_NAME from CLI v$CLI_VERSION"

Tagging happens automatically on merge (see .github/workflows/tag-on-merge.yml).
EOF
