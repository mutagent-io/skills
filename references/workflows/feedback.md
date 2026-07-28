---
name: mutagent-cli-workflows-feedback
description: |
  Product feedback workflow. Sends feedback about the CLI, Helix, or a lifecycle
  stage via `mutagent feedback send`. Optionally attaches the coding-agent
  session transcript as a separate context artifact. Login-gated.
triggers:
  - "send feedback"
  - "mutagent feedback"
  - "report a bug"
  - "file feedback"
  - "the cli crashed"
  - "feedback about"
---

# Workflow — Feedback

> **Scope**: sends a feedback message (and optionally your session transcript)
> to the MutagenT platform. Login-gated.

Read the **Core Rules** in [SKILL.md](../../SKILL.md) first. Key reminders:
- `--json` on every command
- `<command> --help` before first use
- **Login-gated** — run `mutagent login` first

---

## Surface

```bash
mutagent feedback send --help   # authoritative flags — read before first use

mutagent feedback send "<feedback body>" \
  [--title "<5-8 word summary>"] \
  [--category <cli|helix|stage:<spec|build|evaluate|diagnose|optimize>>] \
  [--session <id>] \
  [--attach-transcript [path]] \
  [--json]
```

- **Positional `<feedback body>`** — the feedback text (required, max 10000 chars).
- **`--title`** — optional short (5–8 word) summary of the session timeline.
- **`--category`** — one of:
  - `cli` (default) — feedback about the CLI itself
  - `helix` — feedback about Helix
  - `stage:<x>` — feedback about a lifecycle stage/skill, where `<x>` ∈ `spec | build | evaluate | diagnose | optimize`
- **`--session <id>`** — link this feedback to a specific session id, so the team can correlate it with that run. Optional.
- **`--attach-transcript [path]`** — upload the coding-agent session JSONL as context. This is a **SEPARATE artifact** from the feedback text. Bare flag auto-detects the newest session (across claude-code, codex, omp) and tail-caps it; or pass an explicit path.
- **`--json`** — structured output (Rule 1: always use).

Auto-captured context (harness, CLI version, platform, OS, node version) is
attached automatically — you never set it manually.

---

## Steps

```
1. mutagent auth status --json
   → feedback is login-gated; confirm session or run login first

2. mutagent feedback send --help
   → read the current flags (Rule 2)

3. Compose the feedback body from the user's own words
   → pick --category (default cli; use stage:<x> for a lifecycle stage)
   → offer --attach-transcript when reporting a bug or a session-specific issue

4. mutagent feedback send "<body>" --category <c> [--attach-transcript] --json
   → show the returned id + category + transcriptAttached to the user
```

---

## Examples

```bash
mutagent feedback send "Optimizer results were great" --json
mutagent feedback send "Eval gate was confusing" --category stage:evaluate --json
mutagent feedback send "CLI crashed on login" --category cli \
  --title "login crash on first run" --attach-transcript --json
mutagent feedback send "Diagnose loop stalled" --category stage:diagnose \
  --session run_abc123 --attach-transcript /tmp/session.jsonl --json
```

---

## Bug reporting (agent-aware)

When a mutagent command fails, this is the canonical bug-report path:

1. Show the user the failed command + error.
2. ASK if they want to file a report.
3. On approval, send feedback with the transcript attached so the team gets full context:
   ```bash
   mutagent feedback send "<one-line failure summary>" \
     --category cli --attach-transcript --json
   ```

---

## Output handling

- On success (`{ success: true, id, category, transcriptAttached }`): confirm the feedback id and whether a transcript was attached.
- If `--attach-transcript` (bare) finds no session: the CLI warns and continues without a transcript — tell the user the text was sent but no transcript was found, and offer to pass an explicit path.
- On an auth error: route to login, then retry.

---

## Common pitfalls

- Passing an invalid `--category` (only `cli`, `helix`, `stage:<x>` are valid).
- Confusing the feedback body with the transcript — the body is your message; the transcript is a separate uploaded artifact.
- Sending before login (feedback is login-gated).

---

## Cross-references

- [SKILL.md](../../SKILL.md) → Core Rules + Error Recovery
- [workflows/setup.md](./setup.md) → login (prerequisite for feedback)
