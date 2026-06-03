---
name: omx-omo-agent
description: Use when orchestrating AI-assisted software development through Codex, OMX, OpenCode, or OMO from a non-interactive AI assistant channel. This is a compact enhanced version of the old Hermes OMX/OMO development orchestration skill: it preserves planning, implementation handoff, report, verification, Obsidian, and fix-loop behavior while adding maximum local permissions, stdin prompt files, resume/continue session reuse, official-doc/help checks, and sandbox/write-permission recovery.
---

# OMX OMO Agent

This skill is based on the old Hermes `omx-omo-development-orchestration` workflow, but simplified around one core job: an AI assistant delegates development work to AI coding tools and keeps the tool-side workflow moving without relying on an interactive terminal.

## Core Principle

Keep the old role split:

- **OMX/Codex** owns requirement analysis, planning, specs, verification, review, and closeout.
- **OMO/OpenCode** owns implementation when the user wants the OMO workflow.
- **The assistant** owns orchestration: launch tools, pass durable artifacts, monitor progress, recover from launch/sandbox issues, and summarize results.

Enhancement over the old skill:

- Prefer non-interactive tool surfaces.
- Use highest local permissions when the task asks for autonomous development.
- Use prompt files and stdin for large prompts.
- Reuse the same coding-tool session across assistant turns where possible.
- Recover from read-only sandbox, home-directory write denial, prompt quoting, and TUI/picker hangs before declaring a blocker.

## Mandatory Documentation Check

Before using an unfamiliar or failing tool shape, check current official docs or local help:

```bash
codex exec --help
codex exec resume --help
opencode run --help
omx exec --help
```

If official docs and local help cannot be found for the selected AI development tool, tell the user which tool lacks documentation and ask them to provide it. Do not guess unsupported flags.

Tool references:

- Codex non-interactive/resume: `references/codex.md`
- OpenCode non-interactive/resume: `references/opencode.md`
- Codex launching OpenCode workaround: `references/codex-invokes-opencode.md`
- Long prompt stdin pattern: `references/omx-background-long-prompts.md`
- OpenCode server supervision: `references/opencode-server-supervision.md`

## Default Workflow

1. Inspect only routing state:

```bash
git status --short
git branch --show-current
```

2. Create a durable task id and artifact paths. Prefer existing Obsidian project paths when provided; otherwise use `.omx/` or `/tmp/<task>/`.
3. Ask OMX/Codex to analyze the user's requirement and write a spec. For tasks that require writing outside the repo, use `danger-full-access`.
4. The spec must include an `Implementation Handoff` with:
   - implementation tool: `codex`, `omx`, `omo`, or `opencode`
   - repo/workdir
   - edit scope and avoid list
   - done-when criteria
   - required tests/checks
   - report path
   - complete prompt for the worker
5. Launch the implementation worker with non-interactive, high-permission, prompt-file stdin where possible.
6. Require an implementation report containing files changed, tests run, deviations, blockers, and risks.
7. Ask OMX/Codex to verify the implementation against the approved spec.
8. If verification finds issues, route exact narrow fixes back to the implementation worker and repeat implementation -> report -> verification.
9. Close out by updating task/spec/report docs when available and summarizing only result, changed files, tests, and remaining risks.

## Launcher

Use the bundled launcher when the task is a direct Codex/OpenCode implementation or review:

```bash
skills/omx-omo-agent/scripts/omx-omo-agent-run.sh \
  --tool codex \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<task-id>.prompt.md
```

OpenCode:

```bash
skills/omx-omo-agent/scripts/omx-omo-agent-run.sh \
  --tool opencode \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<task-id>.prompt.md
```

The launcher stores session state under `/tmp/omx-omo-agent-sessions/<task-id>/`. Later assistant turns should reuse the same `task-id` to continue the same coding-tool session.

## Prompt Rules

For large prompts, never inline the prompt in the shell command.

```bash
cat > /tmp/<task-id>.prompt.md <<'EOF'
<full worker prompt>
EOF
```

For OMX spec/review prompts, pass the user's requirement and artifact instructions. Do not pre-load large repo summaries into the prompt; OMX/Codex should inspect the repo itself.

Implementation worker prompt:

```text
You are a coding worker. Repo: <repo>. Task: <task>.
Spec path: <spec-path>.
Report path: <implementation-report-path>.

Read the spec before editing. Implement only the approved acceptance criteria.
Use full local permissions. Do not wait for terminal approval prompts.
Keep changes surgical. Do not touch unrelated files. Do not commit unless asked.
Done when: <tests/checks> pass.
After editing, run <verification commands>.
Write the report with files changed, commands run and results, deviations, risks, and blockers.
```

Verification worker prompt:

```text
Verify implementation against the approved spec.
Inputs: spec path, implementation report, repo/worktree, current diff, and test output.
Do not modify files.
Return pass/fail, concrete issues with file:line when possible, missing tests, exact fixes needed, and release readiness.
```

## Permission And Sandbox Recovery

Use the smallest tool-specific recovery that preserves the user's requested autonomy:

- Codex direct run: `--dangerously-bypass-approvals-and-sandbox`, `-s danger-full-access`, `-C <repo>`, stdin prompt file.
- Codex resume: `codex exec resume <session-id> - < /tmp/<task>.prompt.md`; do not add flags unsupported by current `codex exec resume --help`.
- OMX writing inside repo: `omx exec -s workspace-write --skip-git-repo-check -C <repo> < /tmp/<task>.prompt.md`.
- OMX writing outside repo, Obsidian, or iCloud: `omx exec -s danger-full-access --skip-git-repo-check -C <repo> < /tmp/<task>.prompt.md`.
- OpenCode direct run: `opencode run --dangerously-skip-permissions --dir <repo> "$(cat /tmp/<task>.prompt.md)"`.
- OpenCode home-state failure: redirect `XDG_DATA_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME` to task-local `/tmp` paths.

If a TUI, picker, or approval prompt appears, stop that launch shape and switch to a non-interactive command or server/API mode.

## OpenCode/OMO Notes

The old skill preferred `opencode serve` for real OMO implementation. Keep that when OMO server supervision is needed; read `references/opencode-server-supervision.md`.

Use `opencode run` only when:

- the user explicitly requests it,
- the task is a tiny smoke test,
- the non-interactive runner is the only available message-channel path, or
- direct server supervision is unavailable and current docs/help confirm `opencode run` supports the needed flags.

For OMO `/ralph-loop` details, read `references/omo-ralph-loop-launch.md`, but replace TUI retries with non-interactive/server retries first for message-channel assistants.

## Progress Gates

Do not trust process liveness. Verify progress with:

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard | head -40
test -s <report-path> && wc -l <report-path> || echo NO_REPORT
```

If there is no output, no diff, and no report after a bounded wait, change launch mode once:

- inline prompt -> prompt file stdin
- read-only/workspace sandbox -> danger/full permission
- OpenCode default home state -> `/tmp` XDG state
- direct OpenCode -> server/API or Codex-launches-OpenCode workaround

After recovery attempts fail, write a concise blocker artifact with attempted commands, evidence, paths, and next viable tool.

## References From The Old Skill

Load these only when relevant:

- Obsidian workflow/safety: `references/obsidian-omx-workflow.md`, `references/obsidian-concurrent-edit-safety.md`, `references/obsidian-tmp-artifact-handoff.md`
- OpenCode/OMO supervision: `references/opencode-server-supervision.md`, `references/omo-ralph-loop-launch.md`, `references/opencode-launch-no-progress-closeout.md`
- Fix/review/closeout loops: `references/final-acceptance-fix-loop-closeout.md`, `references/omx-deep-review.md`
- Worktree/merge safety: `references/dirty-worktree-merge.md`, `references/worktree-consolidation-verification.md`

## Completion

Before telling the user the development work is complete:

- implementation report exists or final tool output is captured,
- verification report/output exists for non-trivial work,
- required tests/checks were run or a clear test gap is stated,
- `git status --short` and `git diff --stat` were reviewed,
- no unrelated user changes were overwritten,
- any Obsidian/project docs requested by the workflow are updated or the write blocker is reported.

Final replies should be short: changed files, tests/checks run, outcome, and remaining risks.
