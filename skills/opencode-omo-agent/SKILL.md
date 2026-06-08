---
name: opencode-omo-agent
description: Use when Codex, Claude Code, Cursor, OMX, or another AI coding tool should delegate planning, implementation, refactoring, debugging, tests, reviews, repository exploration, orchestration, or fix loops to Oh My OpenAgent / OMO running inside OpenCode. Use when the user says to use OpenCode, OMO, oh-my-openagent, opencode-omo-agent, /init-deep, /ralph-loop, /ulw-loop, /cancel-ralph, /refactor, /start-work, /stop-continuation, /handoff, Sisyphus, Hephaestus, Prometheus, Atlas, or another OMO agent, unless they explicitly assign the work to a different tool or human.
---

# OpenCode OMO Agent

## Core Principle

This skill is the OpenCode/OMO-focused sibling of `omx-omo-agent`. Keep the same role split:

- **Commander**: Codex, Claude Code, Cursor, OMX, or the current assistant. Owns requirement shaping, prompt construction, launch, monitoring, verification, and final reporting.
- **Worker**: OMO Ultimate running inside OpenCode. Owns implementation work when the user wants OMO/OpenCode.

The stable core launch path is the `omx-omo-agent` OpenCode direct-run pattern, but pass prompt files by path instead of shell-inlining them:

```bash
opencode run --dangerously-skip-permissions --dir <repo> \
  "Read the complete task prompt from this local file, then follow it exactly: <prompt-file>"
```

For OMO slash commands, put the slash command at the very beginning of the message:

```bash
opencode run --dangerously-skip-permissions --dir <repo> \
  "/ulw-loop Read the complete task prompt from this local file, then follow it exactly: <prompt-file>"
```

Do not treat `omo ulw-loop` as the primary path. OMO Ultimate slash commands such as `/ulw-loop` are triggered by message text inside OpenCode.

Avoid hand-writing commands like `"/ulw-loop $(cat <prompt-file>)"`. AI development tools often generate malformed shell quoting or forget the closing `)` / quote, and large prompts make that worse. A local prompt file is already readable to OpenCode in the same workspace, so prefer passing the file path in the message.

## OMO Slash Commands

OMO slash commands are not default behavior. Use them only when the user explicitly requests the command, when the task wording clearly names the command, or when the commander intentionally selects the matching OMO workflow. The final OpenCode message must start with the slash command, before any prompt-file instruction.

Supported OMO command routing:

- `/init-deep`: initialize a layered `AGENTS.md` knowledge base.
- `/ralph-loop`: start a self-referential development loop until completion.
- `/ulw-loop`: start the Ultimate/Ultrawork loop and continue into overload mode.
- `/cancel-ralph`: cancel an active Ralph loop.
- `/refactor`: run intelligent refactoring with LSP, AST-grep, architecture analysis, and TDD verification.
- `/start-work`: start a Sisyphus work session from a Prometheus plan.
- `/stop-continuation`: stop all continuation mechanisms for this session, including Ralph loop, todo continuation, and Boulder.
- `/handoff`: create a detailed context summary so work can continue in a new session.

Use the launcher option by removing the leading slash:

```bash
skills/opencode-omo-agent/scripts/opencode-omo-agent-run.sh \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/opencode.prompt.md \
  --slash-command refactor
```

The command above sends an OpenCode message that begins with `/refactor`. Replace `refactor` with `init-deep`, `ralph-loop`, `ulw-loop`, `cancel-ralph`, `start-work`, `stop-continuation`, or `handoff` as needed.

## Preflight Checks

### Permission Gate

Before launching the bundled script from any installed skill location, verify it is executable. If it is not executable, or if shell execution fails with `permission denied`, automatically fix the script mode and retry once:

```bash
chmod +x /path/to/opencode-omo-agent/scripts/opencode-omo-agent-run.sh
```

Do this without asking the user when the script is owned by the current user and the path is under a local skill installation such as `~/.agents/skills/opencode-omo-agent/`, `~/.codex/skills/opencode-omo-agent/`, or this repository's `skills/opencode-omo-agent/`. Use `bash /path/to/script.sh ...` only as a temporary fallback when `chmod +x` cannot be applied.

Recommended preflight:

```bash
test -x /path/to/opencode-omo-agent/scripts/opencode-omo-agent-run.sh || \
  chmod +x /path/to/opencode-omo-agent/scripts/opencode-omo-agent-run.sh
```

Before changing launch flags or recovering from a failing run, check:

```bash
opencode run --help
```

Read `references/omo-openagent.md` before changing OMO slash-command behavior. Read `references/opencode.md` for raw OpenCode run behavior. Read `references/opencode-server-supervision.md` only when direct `opencode run` cannot make progress and server supervision is needed.

## Default Workflow

1. Capture the user's goal, repo/workdir, edit scope, avoid list, done-when criteria, required checks, and implementation report path.
2. Inspect routing state only:

```bash
git status --short
git branch --show-current
```

3. Write a durable prompt file under `.omx/`, project docs, or `/tmp/<project-name>/<task-id>/`.
4. If the user requested `/init-deep`, `/ralph-loop`, `/ulw-loop`, `/cancel-ralph`, `/refactor`, `/start-work`, `/stop-continuation`, `/handoff`, or another OMO slash command, ensure it is the first text in the final OpenCode message.
5. Ensure the bundled launcher is executable; if not, automatically run `chmod +x` and continue.
6. Launch with the bundled script or the direct command.
7. Monitor progress with diff/report checks; do not trust process liveness alone.
8. Verify OMO's work independently by reading the diff and running the smallest checks that prove the done-when criteria.
9. If verification finds issues, send exact narrow fixes back through the same OpenCode/OMO path.
10. Final response: worker used, changed files, checks run, outcome, and residual risks.

## Launcher

Use the bundled launcher for the stable direct OpenCode path:

```bash
skills/opencode-omo-agent/scripts/opencode-omo-agent-run.sh \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/opencode.prompt.md
```

For `/ulw-loop`, the launcher only prefixes the final message:

```bash
skills/opencode-omo-agent/scripts/opencode-omo-agent-run.sh \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/opencode.prompt.md \
  --slash-command ulw-loop
```

The command above is equivalent to:

```bash
opencode run \
  --dangerously-skip-permissions \
  --dir /path/to/repo \
  "/ulw-loop Read the complete task prompt from this local file, then follow it exactly: /tmp/<project-name>/<task-id>/opencode.prompt.md"
```

Default launcher behavior is intentionally minimal:

- It does not default to `--agent`; OMO slash-command routing should choose the worker unless a known OpenCode-visible agent is required.
- It does not default to JSON/log flags; add `--json --print-logs` only when machine-readable logs are needed.
- It does not default to session resume/continue; reuse can cause stale loops or apparent no-progress runs.
- It does not redirect OpenCode home state by default; use the `omx-omo-agent` recovery references only if OpenCode has a real home-state write failure.
- It does not inline prompt-file contents by default; it passes the prompt file path to OpenCode. Use `--inline-prompt` only for tiny prompts when path reading is not possible.
- It injects a worker guard by default so the OMO/OpenCode worker implements in the current session instead of calling this launcher, starting another `opencode run`, or recursively launching `/ralph-loop`, `/ulw-loop`, `/start-work`, or another OMO command.

Options:

- `--slash-command <name>`: prefix `/<name> ` at the very beginning of the final message, for example `ulw-loop`.
- `--allow-nested-launch`: opt out of the worker guard only when the task is explicitly to test or orchestrate nested OMO/OpenCode launches.
- `--no-danger`: omit `--dangerously-skip-permissions`.
- `--json`: add `--format json`.
- `--print-logs`: add `--print-logs --log-level INFO`.
- `--agent <name>`: pass an OpenCode-visible agent id/name from `opencode agent list`.
- `--model <provider/model>`: pass an OpenCode-visible model from `opencode models`.
- `--dry-run`: print the command and message prefix without starting OpenCode.
- `--inline-prompt`: inline the prompt file content into the OpenCode message. Avoid this for normal use.

## Prompt Template

```text
You are an OMO/OpenCode worker.

Commander: <Codex | Claude Code | Cursor | other>.
Repo/workdir: <absolute path>.
Task: <user goal>.
Edit scope: <files/areas allowed>.
Avoid: <files/areas/actions forbidden>.
Done when: <observable acceptance criteria>.
Required checks: <commands or "choose targeted checks and explain">.
Implementation report path: <absolute path>.

Inspect the repo before editing. Keep changes surgical and consistent with existing patterns.
Do not touch unrelated files. Do not commit, push, deploy, or expose secrets unless explicitly instructed.
Do not invoke `opencode-omo-agent-run.sh`, run `opencode run`, or start another OMO slash loop from inside the worker session unless the task explicitly says to test nested launcher behavior.
Run the required checks, or explain why they cannot run and use the next-best verification.
Write the implementation report with: summary, files changed, commands run and results, deviations, risks, blockers, and next recommended action.
```

When using `/ulw-loop`, the final OpenCode message must start with `/ulw-loop`. Prefer a prompt-file reference:

```text
/ulw-loop Read the complete task prompt from this local file, then follow it exactly: <absolute prompt file path>
```

## Agent Selection

Let OMO route by slash command unless a specific agent is needed.

Use these OMO meanings when choosing a worker:

- `sisyphus`: default lead/orchestrator for broad work, `/ulw-loop`, delegation, and "finish this" tasks.
- `hephaestus`: autonomous deep implementation worker for hard multi-file coding and debugging.
- `prometheus`: planning/interview/spec work; do not ask it to implement.
- `atlas`: executes an existing plan and coordinates task execution.

Raw `opencode run --agent` requires an OpenCode-visible agent id/name. Check:

```bash
opencode agent list
```

Wrapper names such as `sisyphus` and `hephaestus` are reliable through OMO wrapper commands, but raw OpenCode installations may expose display names. Avoid passing `--agent` unless you have verified the exact id/name.

## Progress Gates

Check progress with:

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard | head -40
test -s <implementation-report-path> && wc -l <implementation-report-path> || echo NO_REPORT
```

If there is no useful output, no diff, and no report after a bounded wait, do one focused recovery:

- `permission denied` on the launcher -> run `chmod +x <launcher>` automatically and retry once
- worker repeatedly starts this launcher or another `opencode run` -> kill the nested processes, retry once with the same prompt through direct `opencode run` or the launcher guard, and explicitly instruct the worker to implement directly without starting another slash-loop
- prompt inline failure -> pass the prompt file path in the OpenCode message
- permissions prompt -> use `--dangerously-skip-permissions`
- stale/no-progress session -> start a fresh `opencode run` without `--continue` or `--session`
- direct OpenCode cannot progress -> read `references/opencode-server-supervision.md`

After recovery fails, write a blocker artifact with attempted commands, evidence, paths, and next viable tool.

## Completion Checklist

- OpenCode/OMO output or implementation report exists, or a blocker artifact explains why not.
- Commander reviewed the diff and changed files.
- Required tests/checks were run, or the gap is explicit.
- `git status --short` and `git diff --stat` were reviewed.
- No unrelated user changes were overwritten.
- Final answer names the OpenCode/OMO worker path and the evidence.
