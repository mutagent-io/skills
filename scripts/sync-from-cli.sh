#!/usr/bin/env bash
#
# Sync the mutagent-cli skill bundle from a published @mutagent/cli release.
#
# Flow:
#   1. Install @mutagent/cli@<version> into a throwaway temp dir
#   2. Run `mutagent skills install` inside a scratch git repo to materialize
#      the embedded skill markdown to disk
#   3. rsync the result into ./skills/mutagent-cli/, preserving CHANGELOG.md
#   4. Run scripts/sanitize.py to strip internal references
#   5. Bump the mutagent-cli plugin entry's `version` in .claude-plugin/marketplace.json
#      to match the synced CLI version
#   6. Print a diff summary and suggested next steps
#
# Trust note: SKILL.md frontmatter (including any version field upstream sets) is
# kept byte-identical to whatever the CLI ships. The proper place to normalize
# frontmatter shape is `sync-skill.ts` in the upstream CLI repo. Here we own only
# the marketplace.json plugin version.
#
# Usage:
#   ./scripts/sync-from-cli.sh                 # syncs from @mutagent/cli@latest
#   ./scripts/sync-from-cli.sh 0.1.178         # syncs from a specific version
#   ./scripts/sync-from-cli.sh latest          # explicit "latest"
#

set -euo pipefail

VERSION="${1:-latest}"
SKILL_NAME="mutagent-cli"
# Marketplace plugin entry whose version we bump in lockstep with the CLI.
# This is the single bundled plugin that ships every skill in the repo.
PLUGIN_NAME="mutagent"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$REPO_ROOT/.sync-tmp"
# Source of truth for skill content lives at the repo ROOT (so root-expecting
# registries and crawlers find it). scripts/mirror-skill.sh then re-syncs the
# skills/<name>/ duplicate for the Claude Code plugin spec.
TARGET_DIR="$REPO_ROOT"
MIRROR_DIR="$REPO_ROOT/skills/$SKILL_NAME"
MARKETPLACE_FILE="$REPO_ROOT/.claude-plugin/marketplace.json"
PLUGIN_FILE="$REPO_ROOT/.claude-plugin/plugin.json"

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

echo "==> Rsyncing skill content into repo root (overwriting matching files only)"
# Source layout: $INSTALLED_DIR/{SKILL.md, concepts/, workflows/}.
# We DELIBERATELY do not pass --delete here: target is the repo root, which
# contains README.md, CLAUDE.md, LICENSE, scripts/, .github/, etc. that the
# upstream skill bundle does not know about. Without --delete, rsync only
# overwrites files that exist in both — leaving the repo plumbing intact.
# CHANGELOG.md is hand-maintained per skill release, so we never overwrite it
# from upstream.
rsync -a \
  --exclude='CHANGELOG.md' \
  "$INSTALLED_DIR/" "$TARGET_DIR/"

# Catch a rename/deletion in the upstream skill bundle: any *.md under
# concepts/ or workflows/ that no longer exists upstream should be dropped
# from root too. Scoped to those two subdirs so we never touch README, etc.
for subdir in concepts workflows; do
  if [[ -d "$INSTALLED_DIR/$subdir" && -d "$TARGET_DIR/$subdir" ]]; then
    rsync -a --delete "$INSTALLED_DIR/$subdir/" "$TARGET_DIR/$subdir/"
  fi
done

echo "==> Sanitizing root-level skill content"
"$REPO_ROOT/scripts/sanitize.py" "$TARGET_DIR"

echo "==> Mirroring root → skills/$SKILL_NAME/ (Claude Code plugin layout)"
"$REPO_ROOT/scripts/mirror-skill.sh"

echo "==> Bumping $PLUGIN_NAME plugin version to $CLI_VERSION (marketplace.json + plugin.json)"
if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  echo "ERROR: $MARKETPLACE_FILE missing — cannot bump plugin version." >&2
  exit 1
fi
if [[ ! -f "$PLUGIN_FILE" ]]; then
  echo "ERROR: $PLUGIN_FILE missing — cannot bump plugin version." >&2
  exit 1
fi
python3 - "$MARKETPLACE_FILE" "$PLUGIN_FILE" "$PLUGIN_NAME" "$CLI_VERSION" <<'PY'
import json
import sys
from pathlib import Path

mp_path = Path(sys.argv[1])
plugin_path = Path(sys.argv[2])
target_plugin = sys.argv[3]
new_version = sys.argv[4]

# marketplace.json: bump the entry whose name == target_plugin
mp = json.loads(mp_path.read_text(encoding="utf-8"))
plugins = mp.get("plugins", [])
for entry in plugins:
    if entry.get("name") == target_plugin:
        entry["version"] = new_version
        break
else:
    print(
        f"ERROR: plugin entry '{target_plugin}' not found in marketplace.json",
        file=sys.stderr,
    )
    sys.exit(1)
mp_path.write_text(json.dumps(mp, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

# plugin.json: bump the manifest version too — Claude Code can read either; we
# keep them in lockstep to avoid the documented "plugin.json silently wins"
# footgun.
manifest = json.loads(plugin_path.read_text(encoding="utf-8"))
manifest["version"] = new_version
plugin_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

echo
echo "==> Diff summary"
cd "$REPO_ROOT"
# Watch the root skill files (source of truth) + the mirror + manifests.
WATCH_PATHS=(
  SKILL.md
  CHANGELOG.md
  concepts/
  workflows/
  "skills/$SKILL_NAME/"
  "$MARKETPLACE_FILE"
  "$PLUGIN_FILE"
)
if git diff --quiet -- "${WATCH_PATHS[@]}"; then
  echo "    (no changes — repo already up-to-date with CLI v$CLI_VERSION)"
  exit 0
fi
git diff --stat -- "${WATCH_PATHS[@]}"

echo
cat <<EOF
==> Done. CLI v$CLI_VERSION synced.
  - Root skill content updated (./SKILL.md, ./concepts/, ./workflows/)
  - skills/$SKILL_NAME/ mirror re-synced from root

Plugin version bumped to $CLI_VERSION in:
  - .claude-plugin/marketplace.json (plugins[].name == "$PLUGIN_NAME")
  - .claude-plugin/plugin.json (manifest version)

Next steps (manual):
  1. Review the diff:
       git diff -- SKILL.md CHANGELOG.md concepts/ workflows/ skills/ .claude-plugin/
  2. Update CHANGELOG.md (root) with a [$CLI_VERSION] entry summarizing changes.
     The mirror at skills/$SKILL_NAME/CHANGELOG.md will be regenerated by mirror-skill.sh.
  3. Commit and open a PR:
       git checkout -b sync/cli-v$CLI_VERSION
       git add SKILL.md CHANGELOG.md concepts/ workflows/ skills/ .claude-plugin/
       git commit -m "sync: $SKILL_NAME from CLI v$CLI_VERSION"
       git push -u origin sync/cli-v$CLI_VERSION
       gh pr create --base main --title "sync: $SKILL_NAME from CLI v$CLI_VERSION"

Tagging happens automatically on merge (see .github/workflows/tag-on-merge.yml).
EOF
