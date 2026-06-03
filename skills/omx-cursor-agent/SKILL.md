---
name: omx-cursor-agent
description: Use when orchestrating AI-assisted software development through OMX/Codex as the planning, specification, verification, and closeout brain, with Cursor CLI Agent headless mode as the implementation worker. Based on the old Hermes omx-cursor-development-orchestration skill and enhanced with non-interactive Cursor headless runs, maximum local permissions, prompt-file stdin, session resume/continue, official Cursor CLI docs/help checks, and sandbox/write-permission recovery.
---

# OMX Cursor Agent

This skill is based on the old Hermes `omx-cursor-development-orchestration` workflow. It keeps the old orchestration contract while replacing terminal/TUI assumptions with Cursor CLI headless mode.

## Core Principle

Keep the old role split:

- **OMX/Codex** owns requirement analysis, planning, executable specs, verification, review, and closeout.
- **Cursor CLI Agent** owns implementation, refactors, tests, and implementation reports.
- **The assistant** owns orchestration: launch tools, pass durable artifacts, monitor progress, recover from launch/sandbox issues, and summarize verified results.

Enhancements over the old skill:

- Use Cursor headless mode, not interactive terminal mode.
- Use high-authority Cursor flags for autonomous local development.
- Put long prompts in temporary files and feed them through stdin.
- Reuse Cursor conversations with `--resume` or `--continue` across assistant turns.
- Prefer official Cursor docs and current local `--help` over remembered flags.
- Recover from OMX read-only sandbox, Cursor trust prompts, MCP approval prompts, and long prompt quoting failures before declaring a blocker.

## Mandatory Documentation Check

Cursor CLI changes quickly. Before using unfamiliar or failing flags, check:

```bash
cursor-agent --help || agent --help
omx exec --help
```

Official Cursor reference provided by the user:

- https://cursor.com/cn/docs/cli/headless

If official docs and local help cannot be found, report which command lacks documentation and ask the user to provide it. Do not guess unsupported flags.

Use these references only when relevant:

- Cursor headless and resume: `references/cursor-headless.md`
- OMX/Codex sandbox modes: `references/codex-sandbox-modes.md`
- Long OMX prompts: `references/omx-background-long-prompts.md`
- Obsidian/project docs: `references/obsidian-omx-workflow.md`, `references/obsidian-concurrent-edit-safety.md`, `references/obsidian-tmp-artifact-handoff.md`
- Worktrees and merge safety: `references/dirty-worktree-merge.md`, `references/worktree-consolidation-verification.md`
- Fix/review loops: `references/final-acceptance-fix-loop-closeout.md`, `references/omx-deep-review.md`

## Default Workflow

1. Inspect only routing state:

```bash
git status --short
git branch --show-current
```

2. Create a durable task id and artifact paths. Prefer an existing Obsidian project path when provided; otherwise use `.omx/` or `/tmp/<task>/`.
3. Ask OMX/Codex to analyze the user's requirement and write a spec. For repo-local writes use `workspace-write`; for Obsidian/iCloud/outside-repo writes use `danger-full-access`.
4. The spec must include an `Implementation Handoff` for Cursor:
   - repo/workdir
   - edit scope and avoid list
   - done-when criteria
   - required tests/checks
   - report path
   - complete prompt for Cursor CLI Agent
5. Launch Cursor headless with a prompt file and full local authority.
6. Require a Cursor implementation report with summary, files changed, commands run, test results, deviations, risks, and blockers.
7. Ask OMX/Codex to verify Cursor's implementation against the approved spec, report, diff, and tests.
8. If verification finds issues, route only exact narrow fixes back to Cursor and repeat Cursor -> report -> OMX verification.
9. Close out with task/spec/report updates and a short user summary.

## Launcher

Use the bundled launcher for direct Cursor implementation/review tasks:

```bash
skills/omx-cursor-agent/scripts/omx-cursor-agent-run.sh \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<task-id>.cursor.prompt.md
```

The launcher stores state under `/tmp/omx-cursor-agent-sessions/<task-id>/`. Later assistant turns should reuse the same `task-id` to continue the same Cursor conversation.

## Prompt Rules

For large prompts, never inline the prompt in the shell command:

```bash
cat > /tmp/<task-id>.cursor.prompt.md <<'EOF'
<full Cursor worker prompt>
EOF
```

For OMX spec/review prompts, pass the user's requirement and artifact instructions. Do not pre-load large repo summaries; OMX/Codex should inspect the repo itself.

Cursor implementation prompt:

```text
You are the implementation worker. Repo/workdir: <repo>.
Task: <task>.
Spec path: <spec-path>.
Implementation report path: <implementation-report-path>.

Read the spec before editing. Implement only the approved acceptance criteria.
Use full local permissions. Do not wait for terminal approval prompts.
Keep changes surgical. Do not touch unrelated files. Do not commit unless asked.
After editing, run these verification commands: <commands>.
Write the implementation report with summary, files changed, commands run and results, deviations, risks, and blockers.
```

OMX verification prompt:

```text
Verify Cursor's implementation against the approved spec.
Inputs: spec path, implementation report, repo/worktree, current diff, and test output.
Do not modify files.
Write verdict PASS/FAIL/PARTIAL, concrete issues with file:line when possible, missing tests, exact fixes needed, and release readiness.
```

## Cursor Headless Defaults

Use Cursor headless for implementation:

```bash
cursor-agent -p --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo < /tmp/<task>.cursor.prompt.md
```

If the binary is installed as `agent`, use `agent` instead of `cursor-agent`.

Use `--continue` for the same repo/task when no explicit chat id was captured. Use `--resume <chatId>` when a chat id was captured. Read `references/cursor-headless.md` before changing this behavior.

Use `--approve-mcps` only when the task likely needs Cursor MCP tools or the user has authorized Cursor's local MCP ecosystem. Never print MCP secrets.

## Permission And Sandbox Recovery

- Cursor implementation: `-p --trust --force --sandbox disabled --workspace <repo>`.
- Cursor MCP prompt/approval friction: add `--approve-mcps` if MCP use is intended and safe.
- Cursor resume: `--resume <chatId>` when known; otherwise `--continue` for the same task.
- OMX writing inside repo: `omx exec -s workspace-write --skip-git-repo-check -C <repo> < /tmp/<task>.prompt.md`.
- OMX writing outside repo, Obsidian, or iCloud: `omx exec -s danger-full-access --skip-git-repo-check -C <repo> < /tmp/<task>.prompt.md`.
- Long prompt failure: switch to prompt file stdin.

If a TUI, picker, trust prompt, or approval prompt appears, stop that launch shape and switch to headless `-p --trust --force --sandbox disabled` or current documented equivalent.

## Progress Gates

Do not trust process liveness or Cursor's self-report alone. Verify progress with:

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard | head -40
test -s <implementation-report-path> && wc -l <implementation-report-path> || echo NO_REPORT
```

If Cursor output is quiet but files/report advance, keep supervising. If there is no output, no diff, and no report after a bounded wait, retry with:

- prompt file stdin if the prompt was inline,
- `--trust --force --sandbox disabled`,
- `--approve-mcps` only if MCP approval is the blocker,
- `--continue` or `--resume <chatId>` for the same task,
- a narrower fix prompt if partial edits already landed.

After recovery attempts fail, write a blocker artifact with attempted commands, evidence, paths, and next viable action.

## Worktree Strategy

Default: edit directly in the target repo unless the user asks for isolation.

Use Cursor-managed `-w <name>` or manual git worktrees only when the user asks for isolation, parallel workers need separate directories, or the task is experimental. If using `-w`, avoid `/` in the name.

Before merging worktree output, check untracked files and protect unrelated user changes. Read `references/dirty-worktree-merge.md` when merging into a dirty main worktree.

## Completion

Before telling the user work is complete:

- Cursor implementation report exists or final output is captured,
- OMX verification report/output exists for non-trivial work,
- required tests/checks were run or a clear test gap is stated,
- `git status --short` and `git diff --stat` were reviewed,
- no unrelated user changes were overwritten,
- any requested Obsidian/project docs are updated or the write blocker is reported.

Final replies should be short: changed files, tests/checks run, outcome, and remaining risks.
