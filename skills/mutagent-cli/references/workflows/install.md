---
name: mutagent-cli-workflows-install
description: |
  Meta-installer workflow. Installs a MutagenT package (helix, diagnostics, or
  evaluator) into the user's environment via `mutagent install <package>`.
  Login-gated. diagnostics/evaluator come from public npm; helix is fetched
  from a private registry via a login-brokered signed URL (no static secret).
triggers:
  - "install diagnostics"
  - "install evaluator"
  - "install helix"
  - "mutagent install"
  - "add mutagent package"
  - "set up diagnostics"
  - "set up evaluator"
---

# Workflow — Install (Meta-Installer)

> **Scope**: installs a MutagenT package globally (or per the target harness).
> This WRITES to the user's machine — confirm before running (Core Rule 5).

Read the **Core Rules** in [SKILL.md](../../SKILL.md) first. Key reminders:
- `--json` on every command
- `<command> --help` before first use
- **Login-gated** — run `mutagent login` first
- Confirm before installing (writes to the user's machine)

---

## Surface

```bash
mutagent install --help    # authoritative flags — read before first use

mutagent install <package> [--harness <claude-code|codex|omp>] \
                           [--global] [--version <v>] [--json]
```

Where `<package>` is one of:

| Package | Source | Notes |
|---|---|---|
| `diagnostics` | public npm `@mutagent/diagnostics` | Ready to install |
| `evaluator` | public npm `@mutagent/evaluator` | Ready to install |
| `helix` | private registry via login-brokered signed URL | Ready to install — login-gated download, sha256-verified, then initialized into your project |

**Flags** (verify against `--help`):
- `--harness <claude-code|codex|omp>` -- target coding-agent harness (default `claude-code`).
- `--global` -- install globally (default on).
- `--version <v>` -- pin a specific version (default: latest).
- `--json` -- structured output (Rule 1).

---

## Steps

```
1. mutagent auth status --json
   → confirm the user is logged in (install is login-gated)
   → if not authenticated, run the login workflow first

2. mutagent install --help
   → read the current packages + flags (Rule 2)

3. Confirm with the user WHAT will be installed and WHERE
   → e.g. "I'll install @mutagent/diagnostics globally for claude-code. Proceed?"

4. mutagent install <package> [--harness <h>] [--version <v>] --json
   → run the install
   → show the command output (package, version, harness) to the user
```

---

## Examples

```bash
mutagent install helix --json
mutagent install helix --harness codex --json
mutagent install diagnostics --json
mutagent install evaluator --version 1.2.3 --json
mutagent install diagnostics --harness codex --json
```

---

## Output handling

- On success (`{ success: true, package, version, harness, global }`): tell the user what was installed and the resolved version. Surface `_links.install` / `_links.login`.
- For `helix`: the CLI resolves a signed download URL from the login broker, downloads + sha256-verifies the plugin, then runs its init into the project. An `INTEGRITY_ERROR` means the download failed checksum verification — retry.
- On an auth error (including a broker `AUTH_REQUIRED`): route to the login workflow, then retry.

---

## Common pitfalls

- Running before login → auth error (install is login-gated).
- Assuming `helix` installs from public npm — it is fetched from a private registry via a login-brokered signed URL (the CLI holds no static secret).
- Installing without confirming with the user first (Core Rule 5).

---

## Cross-references

- [SKILL.md](../../SKILL.md) → Core Rules + Task Router
- [workflows/setup.md](./setup.md) → login (prerequisite for install)
