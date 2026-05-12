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

echo "==> Rsyncing SKILL.md to repo root"
# CHANGELOG.md is hand-maintained per skill release, never overwritten from
# upstream. Other top-level repo files (README, CLAUDE.md, LICENSE,
# scripts/, .github/) aren't in the upstream bundle, so won't be touched.
if [[ -f "$INSTALLED_DIR/SKILL.md" ]]; then
  cp "$INSTALLED_DIR/SKILL.md" "$TARGET_DIR/SKILL.md"
fi

echo "==> Transforming upstream concepts/ + workflows/ → references/{concepts,workflows}/ at root"
# Upstream CLI's bundled SKILL ships content as top-level concepts/ and
# workflows/ subdirs (alongside SKILL.md). The Agent Skills spec wants
# everything under a references/ parent. Move each subdir UNDER references/
# preserving its name — `references/concepts/` and `references/workflows/`.
#
# Why nested (not flat) under references/: the internal cross-references
# inside the moved files use relative paths like ../workflows/X.md and
# ../concepts/Y.md. Preserving the concept/workflow split under references/
# keeps those relative paths valid WITHOUT any in-file rewriting — the
# moved-file content is byte-identical to upstream. Only SKILL.md (at the
# skill root) needs its top-level path prefixes updated.
rm -rf "$TARGET_DIR/references"
mkdir -p "$TARGET_DIR/references"
for subdir in concepts workflows; do
  src="$INSTALLED_DIR/$subdir"
  if [[ -d "$src" ]]; then
    cp -R "$src" "$TARGET_DIR/references/$subdir"
  fi
done

# Two transformations are needed to bring upstream content into spec shape:
#   (1) SKILL.md path-prefix update (concepts/X.md → references/concepts/X.md,
#       workflows/X.md → references/workflows/X.md) — applied only to SKILL.md
#       at root, NOT to the moved subtree (its internal refs already work).
#   (2) frontmatter normalization (top-level SKILL_VERSION / SKILL_MIN_CLI_VERSION
#       → metadata.skill_version / metadata.skill_min_cli_version, plus
#       license: MIT). The upstream CLI fix tracked in monorepo #943 will
#       eventually make (2) a no-op; until it ships to npm, this script does it.
# Both rules are idempotent: if upstream already emits the new shape, the
# regex patterns don't match and no edits happen.
python3 - "$TARGET_DIR" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
skill_md = root / "SKILL.md"

# --- (1) Path adjustments ---
# (1a) SKILL.md: prepend `references/` to the (concepts|workflows)/X.md paths.
# (1b) Moved files under references/{concepts,workflows}/: the only relative
#      path that needs rewriting is `../SKILL.md` → `../../SKILL.md` because
#      the files moved one level deeper. All OTHER relative refs (`./X.md`
#      siblings and `../X/Y.md` cross-type) still resolve correctly under
#      references/ because the concept/workflow split is preserved.
SKILL_MD_RULES = [
    (re.compile(r"\./concepts/([a-z][a-z0-9-]*\.md)"),  r"./references/concepts/\1"),
    (re.compile(r"\./workflows/([a-z][a-z0-9-]*\.md)"), r"./references/workflows/\1"),
    (re.compile(r"\bconcepts/([a-z][a-z0-9-]*\.md)"),   r"references/concepts/\1"),
    (re.compile(r"\bworkflows/([a-z][a-z0-9-]*\.md)"),  r"references/workflows/\1"),
]

total = 0
if skill_md.is_file():
    text = skill_md.read_text(encoding="utf-8")
    new = text
    for pattern, replacement in SKILL_MD_RULES:
        new, n = pattern.subn(replacement, new)
        total += n
    # Guard against double-prefix on re-runs.
    new = re.sub(r"references/references/", "references/", new)
    if new != text:
        skill_md.write_text(new, encoding="utf-8")
        print(f"    Rewrote {total} path prefix(es) in SKILL.md")

# Files under references/{concepts,workflows}/: bump ../SKILL.md → ../../SKILL.md
bumped = 0
for ref_dir in ("concepts", "workflows"):
    for p in (root / "references" / ref_dir).rglob("*.md"):
        text = p.read_text(encoding="utf-8")
        # Avoid double-bump: ../../SKILL.md should stay as-is.
        new = re.sub(r"(?<!\.\./)\.\./SKILL\.md", "../../SKILL.md", text)
        if new != text:
            p.write_text(new, encoding="utf-8")
            bumped += 1
if bumped:
    print(f"    Bumped ../SKILL.md → ../../SKILL.md in {bumped} reference file(s)")

# --- (2) Frontmatter normalization ---
# Move top-level SKILL_VERSION / SKILL_MIN_CLI_VERSION into metadata: block
# (per agentskills.io spec). Add license: MIT if not already present.
if skill_md.is_file():
    text = skill_md.read_text(encoding="utf-8")
    fm_match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if fm_match:
        fm = fm_match.group(1)
        rest = text[fm_match.end():]

        # Capture old-style top-level keys; remove them from the frontmatter.
        sv_match = re.search(r"^SKILL_VERSION:\s*(.+)$", fm, re.MULTILINE)
        smcv_match = re.search(r"^SKILL_MIN_CLI_VERSION:\s*(.+)$", fm, re.MULTILINE)

        if sv_match or smcv_match:
            sv = sv_match.group(1).strip().strip('"').strip("'") if sv_match else None
            smcv = smcv_match.group(1).strip().strip('"').strip("'") if smcv_match else None

            # Strip the old top-level lines (plus any trailing blank).
            fm = re.sub(r"^SKILL_VERSION:.*\n",        "", fm, flags=re.MULTILINE)
            fm = re.sub(r"^SKILL_MIN_CLI_VERSION:.*\n", "", fm, flags=re.MULTILINE)
            fm = fm.rstrip() + "\n"

            # Ensure `license: MIT` is set (if not already).
            if not re.search(r"^license:", fm, re.MULTILINE):
                fm += "license: MIT\n"

            # Build / merge metadata block.
            md_match = re.search(r"^metadata:\n((?:[ \t].+\n)+)", fm, re.MULTILINE)
            if md_match:
                md_body = md_match.group(1)
                if sv and "skill_version:" not in md_body:
                    md_body += f'  skill_version: "{sv}"\n'
                if smcv and "skill_min_cli_version:" not in md_body:
                    md_body += f'  skill_min_cli_version: "{smcv}"\n'
                fm = fm[:md_match.start(1)] + md_body + fm[md_match.end(1):]
            else:
                md_block = "metadata:\n"
                if sv:
                    md_block += f'  skill_version: "{sv}"\n'
                if smcv:
                    md_block += f'  skill_min_cli_version: "{smcv}"\n'
                fm += md_block

            skill_md.write_text(f"---\n{fm}---\n{rest}", encoding="utf-8")
            print("    Normalized SKILL.md frontmatter (moved version keys → metadata)")

# In-body references: 'SKILL_MIN_CLI_VERSION' (upper) → spec-shape language.
if skill_md.is_file():
    text = skill_md.read_text(encoding="utf-8")
    new = re.sub(
        r"`SKILL_MIN_CLI_VERSION`",
        "`metadata.skill_min_cli_version`",
        text,
    )
    new = re.sub(
        r"\bSKILL_MIN_CLI_VERSION\b",
        "metadata.skill_min_cli_version",
        new,
    )
    if new != text:
        skill_md.write_text(new, encoding="utf-8")
        print("    Normalized in-body references to SKILL_MIN_CLI_VERSION")
PY

# Drop any vestigial upstream subdirs at root if rsync ever wrote them.
rm -rf "$TARGET_DIR/concepts" "$TARGET_DIR/workflows"

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
  references/
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
  - Root skill content updated (./SKILL.md, ./references/)
  - skills/$SKILL_NAME/ mirror re-synced from root

Plugin version bumped to $CLI_VERSION in:
  - .claude-plugin/marketplace.json (plugins[].name == "$PLUGIN_NAME")
  - .claude-plugin/plugin.json (manifest version)

Next steps (manual):
  1. Review the diff:
       git diff -- SKILL.md CHANGELOG.md references/ skills/ .claude-plugin/
  2. Update CHANGELOG.md (root) with a [$CLI_VERSION] entry summarizing changes.
     The mirror at skills/$SKILL_NAME/CHANGELOG.md will be regenerated by mirror-skill.sh.
  3. Commit and open a PR:
       git checkout -b sync/cli-v$CLI_VERSION
       git add SKILL.md CHANGELOG.md references/ skills/ .claude-plugin/
       git commit -m "sync: $SKILL_NAME from CLI v$CLI_VERSION"
       git push -u origin sync/cli-v$CLI_VERSION
       gh pr create --base main --title "sync: $SKILL_NAME from CLI v$CLI_VERSION"

Tagging happens automatically on merge (see .github/workflows/tag-on-merge.yml).
EOF
