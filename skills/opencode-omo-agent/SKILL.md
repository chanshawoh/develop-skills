---
name: opencode-omo-agent
description: Use when Codex, Claude Code, Cursor, OMX, or another AI coding tool should delegate planning, implementation, refactoring, debugging, tests, reviews, repository exploration, orchestration, or fix loops to Oh My OpenAgent / OMO running inside OpenCode. Use when the user says to use OpenCode, OMO, oh-my-openagent, opencode-omo-agent, /ulw-loop, /ralph-loop, Sisyphus, Hephaestus, Prometheus, Atlas, or another OMO agent, unless they explicitly assign the work to a different tool or human.
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

## Mandatory Check

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
4. If the user requested `/ulw-loop`, `/ralph-loop`, or another OMO slash command, ensure it is the first text in the final OpenCode message.
5. Launch with the bundled script or the direct command.
6. Monitor progress with diff/report checks; do not trust process liveness alone.
7. Verify OMO's work independently by reading the diff and running the smallest checks that prove the done-when criteria.
8. If verification finds issues, send exact narrow fixes back through the same OpenCode/OMO path.
9. Final response: worker used, changed files, checks run, outcome, and residual risks.

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

Options:

- `--slash-command <name>`: prefix `/<name> ` at the very beginning of the final message, for example `ulw-loop`.
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
