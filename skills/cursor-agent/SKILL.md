---
name: cursor-agent
description: Use when Codex, Claude Code, OpenCode, OMO, OMX, or another AI coding tool should delegate implementation, refactoring, debugging, tests, reviews, repository exploration, or fix loops to Cursor CLI Agent headless mode, especially when the user says to use Cursor, cursor-agent, or agent CLI. Use unless the user explicitly assigns the work to a different tool or human.
---

# Cursor Agent

## Overview

Use this skill to let the current AI tool act as the commander and Cursor CLI Agent act as the worker. The commander owns intent, routing, prompts, verification, and final reporting; Cursor owns as much repo-local execution as it can safely perform.

## Core Contract

- **Commander**: Codex, Claude Code, OpenCode, OMX, OMO, or the active AI tool in the current session.
- **Worker**: Cursor CLI Agent in headless/script mode, available as `cursor-agent` or `agent`.
- **Default routing**: Delegate implementation-shaped work to Cursor whenever useful. Cursor can inspect code, edit files, run commands, test, debug, review, and report. Keep work in the commander only when it is tiny, user-specified, unsupported by Cursor, or requires a capability the commander uniquely has.
- **User override**: If the user names who should do the work, honor that assignment. Examples: "你来改" means the current assistant edits; "让 Claude Code 做" means do not route that slice to Cursor unless needed as a helper.
- **Authority boundary**: Do not let Cursor commit, push, deploy, delete unrelated work, expose secrets, or operate production systems unless the user explicitly requested that action.
- **Native runtime boundary**: Cursor CLI Agent depends on the user's real Cursor profile and macOS Keychain. Prefer launching Cursor from a native Terminal, iTerm, or attached tmux shell with the real `HOME`; do not redirect `HOME` or Cursor state to `/tmp` to work around sandbox errors.

## Mandatory Cursor Check

Cursor CLI changes quickly. Before using unfamiliar or failing flags, check local help:

```bash
cursor-agent --help || agent --help
```

Read `references/cursor-headless.md` when selecting models, resume behavior, worktree mode, or permission flags.

## Default Workflow

1. Capture the user's target result, constraints, requested worker, repo/workdir, and stop condition.
2. Inspect routing state only:

```bash
git status --short
git branch --show-current
```

3. Decide the lane:
   - Use Cursor for implementation, refactors, bug fixes, test creation, test repair, repo exploration that benefits from agentic inspection, and review/fix loops.
   - Keep planning, prompt construction, risk decisions, verification judgment, and user-facing summary with the commander.
   - Use another worker only when the user explicitly names it or Cursor is unavailable after recovery attempts.
4. Create a durable task id and artifact paths under `.omx/`, project docs, or `/tmp/<project-name>/<task-id>/`.
5. Write a Cursor prompt file. Never inline long prompts in shell commands.
6. Launch Cursor through the bundled script. If the script reports that the current surface is Codex Desktop/App, run the generated `native-command.sh` from the user's native shell or an attached OMX/OMC tmux shell instead of retrying inside the app sandbox.
7. Monitor git diff, report files, and command output. Do not trust process liveness alone.
8. Verify Cursor's work independently: read the diff, inspect changed files, run the smallest tests/checks that prove the claim, and route exact fixes back to Cursor when needed.
9. Final response: worker used, changed files, checks run, outcome, and residual risks.

## Launcher

Use the bundled launcher:

```bash
skills/cursor-agent/scripts/cursor-agent-run.sh \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/cursor.prompt.md
```

The launcher stores session state under `/tmp/cursor-agent-sessions/<task-id>/`. Reuse the same `task-id` to continue the same Cursor conversation.

Options:

- `--fresh`: do not resume/continue the previous Cursor conversation.
- `--model <model>`: pass a Cursor model. Default is Cursor's `auto`.
- `--no-approve-mcps`: avoid `--approve-mcps`.
- `--worktree <name>`: use Cursor-managed isolated worktree mode.

## Cursor Prompt Template

```text
You are Cursor CLI Agent, the execution worker.

Commander: <Codex | Claude Code | OpenCode | other>.
Repo/workdir: <absolute path>.
Task: <user goal>.
Constraints: <files to edit, files to avoid, style rules, safety limits>.
Done when: <observable acceptance criteria>.
Required checks: <commands or "choose targeted checks and explain">.
Implementation report path: <absolute path>.

Do as much useful work as Cursor can safely do for this task.
Inspect the repo before editing. Keep changes surgical and consistent with existing patterns.
Do not touch unrelated files. Do not commit, push, deploy, or expose secrets unless explicitly instructed.
Run the required checks, or explain why they cannot run and use the next-best verification.
Write the implementation report with: summary, files changed, commands run and results, deviations, risks, blockers, and next recommended action.
```

## Progress Gates

Check progress with:

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard | head -40
test -s <implementation-report-path> && wc -l <implementation-report-path> || echo NO_REPORT
```

If there is no output, no diff, and no report after a bounded wait, retry with a prompt file, full headless permissions, `--continue` or `--resume`, and a narrower prompt. If that still fails, write a blocker note with attempted commands and evidence, then switch to the next viable worker or direct execution.

## Permission Recovery

Cursor is a native macOS credentialed tool, not a generic nested-sandbox worker. Prefer the native user environment over sandbox workarounds:

- Keep the real `HOME` so Cursor can read/write `~/.cursor` and access Keychain-backed credentials.
- Do not set `HOME=/tmp/...`, `XDG_*=/tmp/...`, or similar Cursor state redirects as a recovery step.
- If Codex Desktop/App blocks Cursor credentials, use the launcher's generated `native-command.sh` from Terminal, iTerm, or an attached tmux shell.
- Treat `SecItemCopyMatching failed -50`, segmentation faults after changing `HOME`, or inability to write `~/.cursor` from Codex App as a runtime-surface blocker, not a task blocker.

Preferred implementation flags:

```bash
cursor-agent -p --model auto --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

If the binary is named `agent`, use `agent` instead of `cursor-agent`.

Use `--approve-mcps` only when Cursor MCP tools are intended and safe. Never print MCP secrets.

## Completion Checklist

- Cursor output or implementation report exists, or a blocker artifact explains why not.
- Commander reviewed the diff and changed files.
- Required tests/checks were run, or the gap is explicit.
- `git status --short` and `git diff --stat` were reviewed.
- No unrelated user changes were overwritten.
- User-facing final names the worker used and the evidence.
