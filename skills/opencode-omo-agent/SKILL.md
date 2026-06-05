---
name: opencode-omo-agent
description: Use when Codex, Claude Code, Cursor, OMX, or another AI coding tool should delegate planning, implementation, refactoring, debugging, tests, reviews, repository exploration, orchestration, or fix loops to Oh My OpenAgent / OMO / OpenCode agents in non-interactive mode. Use when the user says to use OpenCode, OMO, oh-my-openagent, opencode-omo-agent, Sisyphus, Hephaestus, Prometheus, Atlas, or another OMO agent, unless they explicitly assign the work to a different tool or human.
---

# OpenCode OMO Agent

## Overview

Use this skill to let the current AI tool act as the commander and OpenCode with the OMO Ultimate plugin act as the worker. The commander owns intent, routing, prompts, verification, and final reporting; OMO owns as much repo-local execution as it can safely perform inside OpenCode through the right OMO agent, hooks, skills, and slash commands.

This is the lightweight sibling of `omx-omo-agent`: use it when the user wants OpenCode/OMO as the implementation worker, but does not need the full OMX spec, verification, and closeout document workflow.

Primary upstream reference: `code-yeongyu/oh-my-openagent`. Read `references/omo-openagent.md` before changing OMO launch behavior, agent selection, or install guidance.

## Core Contract

- **Commander**: Codex, Claude Code, Cursor, OMX, or the active AI tool in the current session.
- **Worker**: OpenCode with the OMO Ultimate plugin loaded. Use `opencode run` for non-interactive work. `oh-my-openagent run` / `oh-my-opencode run` are wrapper conveniences, not the core runtime.
- **Default routing**: Delegate implementation-shaped work to OMO whenever useful. OMO agents can inspect code, edit files, run commands, test, debug, review, orchestrate specialists, and report. Keep work in the commander only when it is tiny, user-specified, unsupported by OMO, or requires a capability the commander uniquely has.
- **User override**: If the user names who should do the work, honor that assignment. Examples: "你来改" means the current assistant edits; "让 Cursor 做" means do not route that slice to OpenCode/OMO unless needed as a helper.
- **Authority boundary**: Do not let OpenCode/OMO commit, push, deploy, delete unrelated work, expose secrets, or operate production systems unless the user explicitly requested that action.

## Mandatory OMO Check

OMO/OpenCode workflows change quickly. Before using unfamiliar or failing flags, check local help:

```bash
opencode run --help
opencode serve --help
oh-my-openagent run --help || oh-my-opencode run --help || true
```

Read `references/omo-openagent.md` first. Read `references/opencode.md` when falling back to raw `opencode run`.

Use these references only when relevant:

- OpenCode run behavior: `references/opencode.md`
- OMO server supervision: `references/opencode-server-supervision.md`
- OMO `/ralph-loop` launch details: `references/omo-ralph-loop-launch.md`
- Codex launching OpenCode workaround: `references/codex-invokes-opencode.md`

## Default Workflow

1. Capture the user's target result, constraints, requested worker, repo/workdir, and stop condition.
2. Inspect routing state only:

```bash
git status --short
git branch --show-current
```

3. Decide the lane and agent:
   - Use OMO default/Sisyphus for broad development work, orchestration, `/ulw-loop`, and work that may benefit from delegation.
   - Use Hephaestus for autonomous deep implementation, hard refactors, bug fixes, and multi-file technical work.
   - Use Prometheus for planning/interview/spec work before implementation.
   - Use Atlas for executing an existing plan or coordinating task execution.
   - Use raw OpenCode without OMO only when the OMO plugin is unavailable or the user explicitly wants raw OpenCode.
   - Keep planning, prompt construction, risk decisions, verification judgment, and user-facing summary with the commander.
   - Use another worker only when the user explicitly names it or OMO/OpenCode is unavailable after recovery attempts.
4. Create a durable task id and artifact paths under `.omx/`, project docs, or `/tmp/<project-name>/<task-id>/`.
5. Write an OpenCode/OMO prompt file. Never inline long prompts in shell commands.
6. Launch OMO/OpenCode through the bundled script.
7. Monitor git diff, report files, and command output. Do not trust process liveness alone.
8. Verify OpenCode/OMO's work independently: read the diff, inspect changed files, run the smallest tests/checks that prove the claim, and route exact fixes back to OpenCode/OMO when needed.
9. Final response: worker used, changed files, checks run, outcome, and residual risks.

## Launcher

Use the bundled launcher:

```bash
skills/opencode-omo-agent/scripts/opencode-omo-agent-run.sh \
  --runner opencode \
  --slash-command ulw-loop \
  --agent hephaestus \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/opencode.prompt.md
```

The launcher stores session state under `/tmp/opencode-omo-agent-sessions/<task-id>/`. Reuse the same `task-id` to continue the same OMO/OpenCode conversation.

Options:

- `--runner opencode|omo`: default `opencode`; `omo` uses the package wrapper when explicitly requested.
- `--slash-command <name>`: prepend `/<name>` to the prompt so OMO's OpenCode slash-command path handles it, for example `--slash-command ulw-loop`.
- `--agent <name>`: OMO agent name, for example `sisyphus`, `hephaestus`, `prometheus`, or `atlas`.
- `--model <provider/model>`: OMO model override, for example `openai/gpt-5.5`.
- `--session-id <id>`: resume a captured OMO/OpenCode session.
- `--fresh`: do not resume/continue the previous OpenCode conversation.
- `--no-danger`: avoid `--dangerously-skip-permissions`.
- `--port <port>` / `--attach <url>`: OMO server connection controls.

## OpenCode/OMO Prompt Template

```text
You are an OMO/OpenCode worker agent.

Commander: <Codex | Claude Code | Cursor | other>.
Repo/workdir: <absolute path>.
Task: <user goal>.
Constraints: <files to edit, files to avoid, style rules, safety limits>.
Done when: <observable acceptance criteria>.
Required checks: <commands or "choose targeted checks and explain">.
Implementation report path: <absolute path>.

Do as much useful work as your selected OMO agent can safely do for this task.
Inspect the repo before editing. Keep changes surgical and consistent with existing patterns.
Do not touch unrelated files. Do not commit, push, deploy, or expose secrets unless explicitly instructed.
Run the required checks, or explain why they cannot run and use the next-best verification.
Write the implementation report with: summary, files changed, commands run and results, deviations, risks, blockers, and next recommended action.
```

## Agent Selection

OMO `run` resolves agents in this order: `--agent`, `OPENCODE_DEFAULT_AGENT`, `default_run_agent` in OMO config, then `sisyphus`.

Use this default map:

- `sisyphus`: default lead/orchestrator for broad work, `ultrawork`, delegation, and "just get it done" tasks.
- `hephaestus`: autonomous deep implementation worker. Prefer for hard multi-file coding and debugging when GPT-family access exists.
- `prometheus`: planner/interviewer. Prefer for unclear requirements, planning, and spec generation. It should not be asked to implement.
- `atlas`: plan executor/conductor. Prefer when a plan already exists and work should be coordinated into tasks.
- `oracle`: architecture/debug consultation, usually as a subagent rather than top-level `run`.
- `explore` / `librarian`: repo and docs search specialists, usually invoked by OMO internals rather than direct top-level `run`.

Run diagnostics when routing depends on installed agents, models, or auth:

```bash
oh-my-openagent doctor --verbose || oh-my-opencode doctor --verbose
opencode models
opencode auth list
```

## OMO Slash Commands In OpenCode

OMO Ultimate runs inside OpenCode. To trigger commands such as `/ulw-loop`, include the slash command in the message sent to OpenCode:

```bash
opencode run \
  --dir /path/to/repo \
  --format json \
  --print-logs \
  --log-level INFO \
  --dangerously-skip-permissions \
  "/ulw-loop $(cat /tmp/<project-name>/<task-id>/opencode.prompt.md)"
```

The OMO plugin detects raw `/ulw-loop ...` messages in OpenCode and starts the ultrawork loop through its slash-command/chat-message hooks. This is different from the Codex Light `omo ulw-loop` component CLI.

Other OMO commands use the same pattern:

```bash
opencode run --dir /path/to/repo "/ralph-loop <task>"
opencode run --dir /path/to/repo "/start-work <plan or instruction>"
```

When using raw `opencode run`, `--agent` must match an OpenCode-visible agent id/name from `opencode agent list`. OMO wrapper agent names such as `sisyphus` or `hephaestus` are reliable through `oh-my-openagent run`; raw OpenCode installations may expose display names instead, or rely on OMO slash-command routing to choose the agent.

## Wrapper CLI Fallback

`oh-my-openagent run` and `oh-my-opencode run` wrap OpenCode and wait until todos/child sessions are idle. Use them only when they are installed and the wrapper behavior is desired:

```bash
oh-my-openagent run --directory /path/to/repo --agent hephaestus "/ulw-loop <task>"
```

## Raw OpenCode Fallback

Use non-interactive OpenCode directly for ordinary OMO plugin work:

```bash
opencode run \
  --dir /path/to/repo \
  --format json \
  --print-logs \
  --log-level INFO \
  --dangerously-skip-permissions \
  "$(cat /tmp/<project-name>/<task-id>/opencode.prompt.md)"
```

The bundled launcher redirects OpenCode home state to task-local `/tmp` directories to avoid home-directory write failures:

```bash
XDG_DATA_HOME=/tmp/opencode-<task-id>-data
XDG_CACHE_HOME=/tmp/opencode-<task-id>-cache
XDG_STATE_HOME=/tmp/opencode-<task-id>-state
```

Use `--continue` for the same repo/task when no explicit OpenCode session id was captured. Use `--session <session-id>` when a session id was captured. Read `references/opencode.md` before changing raw OpenCode behavior.

## OMO Server Mode

Prefer `opencode run` with OMO plugin-loaded prompts for ordinary implementation tasks in non-interactive assistant channels.

Use supervised server/API mode when:

- the user explicitly requests OMO server behavior,
- direct `opencode run` stalls, opens a TUI, or cannot make progress,
- the task depends on an OMO workflow such as `/ralph-loop`, Team Mode, or another server-backed workflow, or
- current OpenCode docs/help show the needed action is only supported through server mode.

Before using server mode, read `references/opencode-server-supervision.md`. For `/ralph-loop`, also read `references/omo-ralph-loop-launch.md`.

## Progress Gates

Check progress with:

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard | head -40
test -s <implementation-report-path> && wc -l <implementation-report-path> || echo NO_REPORT
```

If there is no output, no diff, and no report after a bounded wait, retry with a prompt file, full local permissions, `--continue` or `--session`, task-local XDG state, and a narrower prompt. If that still fails, write a blocker note with attempted commands and evidence, then switch to the next viable worker or direct execution.

## Permission Recovery

Preferred implementation flags:

```bash
opencode run --dir /path/to/repo --format json --print-logs --log-level INFO --dangerously-skip-permissions "$(cat /tmp/<project-name>/<task-id>/opencode.prompt.md)"
```

Recovery steps:

- If the package wrapper CLI is missing, keep using `opencode run`; OMO Ultimate is an OpenCode plugin and slash commands such as `/ulw-loop` are triggered by message text.
- If the wrong npm package is being resolved, do not use `bunx omo` or `npx omo`; upstream warns that `omo` is a different package name in npm resolution.
- If home-state writes fail in raw OpenCode fallback, redirect `XDG_DATA_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME` to task-local `/tmp` paths.
- If prompt quoting fails, write a smaller prompt file and pass `$(cat <prompt-file>)`.
- If `opencode run` hangs on a TUI, picker, or approval prompt, stop that launch shape and switch to the current documented non-interactive or server/API mode.
- If direct OpenCode cannot run from the current assistant surface, read `references/codex-invokes-opencode.md` and use the Codex-launches-OpenCode workaround only when safe.

## Completion Checklist

- OpenCode/OMO output or implementation report exists, or a blocker artifact explains why not.
- Commander reviewed the diff and changed files.
- Required tests/checks were run, or the gap is explicit.
- `git status --short` and `git diff --stat` were reviewed.
- No unrelated user changes were overwritten.
- User-facing final names the worker used and the evidence.
