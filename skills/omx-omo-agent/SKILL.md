---
name: omx-omo-agent
description: "Use when orchestrating AI-assisted software development through Codex, OMX, OpenCode, or OMO from a non-interactive AI assistant channel. This is a compact enhanced version of the old Hermes OMX/OMO development orchestration skill: it preserves planning, implementation handoff, report, verification, project documentation, and fix-loop behavior while adding maximum local permissions, stdin prompt files, resume/continue session reuse, official-doc/help checks, and sandbox/write-permission recovery."
---

# OMX OMO Agent

This skill is based on the old Hermes `omx-omo-development-orchestration` workflow, but simplified around one core job: an AI assistant delegates development work to AI coding tools and keeps the tool-side workflow moving without relying on an interactive terminal.

## Core Principle

Keep the old role split:

- **OMX/Codex** owns requirement analysis, planning, specs, verification, review, and closeout.
- **OMO/OpenCode** owns implementation when the user wants the OMO workflow.
- **The assistant** owns orchestration: launch tools, pass durable artifacts, monitor progress, recover from launch/sandbox issues, and summarize results.

Documentation ownership:

- **Project docs are a shared writable surface**: use the user's requested surface first, then existing project habits, then local `.omx/` or `/tmp/<project-name>/<task-id>/` fallback. The surface may be Obsidian, Notion, local markdown, repo docs, or another project system. The assistant, OMX/Codex, and OMO/OpenCode may write there when their role requires it, but each role should keep to its lane.
- **Temporary documentation artifacts must be nested**: never write project docs directly under `/tmp` or a bare `/tmp/<task>/`; use at least `/tmp/<project-name>/<task-id>/`.
- **The assistant owns instruction relay and orchestration state**: capture the user's request, constraints, artifact paths, launch decisions, and status transitions with minimal rewriting. Do not turn the assistant into the main documentation writer unless the user explicitly asks.
- **OMX/Codex owns implementation-facing and human-facing documents**: write specs, implementation handoffs, verification reports, review verdicts, task/status updates, and final closeout notes after receiving the assistant's instruction.
- **OMO/OpenCode owns implementation evidence**: write implementation reports, changed-file summaries, command/test output, deviations, risks, and blockers. Avoid updating specs, verification reports, final closeout notes, or user-requirement text unless the handoff explicitly lists those files as implementation outputs.

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

2. Create a durable task id and artifact paths. Prefer the user's requested documentation surface, then existing project habits, then `.omx/` or `/tmp/<project-name>/<task-id>/`.
3. Ask OMX/Codex to analyze the user's requirement and write the durable spec. For tasks that require writing outside the repo, external docs, cloud-synced folders, Notion/Obsidian exports, or shared docs, use `danger-full-access`.
4. The spec must include an `Implementation Handoff` with:
   - implementation tool: `codex`, `omx`, `omo`, or `opencode`
   - repo/workdir
   - edit scope and avoid list
   - done-when criteria
   - required tests/checks
   - report path
   - complete prompt for the worker
5. Launch the implementation worker with non-interactive, high-permission, prompt-file stdin where possible.
6. Require the implementation worker to write only the implementation report containing files changed, tests run, deviations, blockers, and risks.
7. Ask OMX/Codex to write the verification result after checking the implementation against the approved spec.
8. If verification finds issues, route exact narrow fixes back to the implementation worker and repeat implementation -> report -> verification.
9. Ask OMX/Codex to close out by updating task/spec/verification docs into a human-readable final state, preserving the implementation report as downstream evidence, then summarize only result, changed files, tests, and remaining risks.

## Launcher

Use the bundled launcher when the task is a direct Codex/OpenCode implementation or review:

```bash
skills/omx-omo-agent/scripts/omx-omo-agent-run.sh \
  --tool codex \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/worker.prompt.md
```

OpenCode:

```bash
skills/omx-omo-agent/scripts/omx-omo-agent-run.sh \
  --tool opencode \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/worker.prompt.md
```

The launcher stores session state under `/tmp/omx-omo-agent-sessions/<task-id>/`. Later assistant turns should reuse the same `task-id` to continue the same coding-tool session.

## Prompt Rules

For large prompts, never inline the prompt in the shell command.

```bash
cat > /tmp/<project-name>/<task-id>/worker.prompt.md <<'EOF'
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
Do not update specs, user-requirement text, verification reports, or closeout notes unless the handoff explicitly lists those files as implementation outputs.
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
- Codex resume: `codex exec resume <session-id> - < /tmp/<project-name>/<task-id>/worker.prompt.md`; do not add flags unsupported by current `codex exec resume --help`.
- OMX writing inside repo: `omx exec -s workspace-write --skip-git-repo-check -C <repo> < /tmp/<project-name>/<task-id>/omx.prompt.md`.
- OMX writing outside repo, shared docs, cloud-synced folders, or external doc exports: `omx exec -s danger-full-access --skip-git-repo-check -C <repo> < /tmp/<project-name>/<task-id>/omx.prompt.md`.
- OpenCode direct run: `opencode run --dangerously-skip-permissions --dir <repo> "$(cat /tmp/<project-name>/<task-id>/worker.prompt.md)"`.
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

- Project docs workflow/safety: `references/project-docs-omx-workflow.md`, `references/project-docs-concurrent-edit-safety.md`, `references/project-docs-tmp-artifact-handoff.md`
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
- any project docs requested by the workflow have been reconciled by OMX/Codex during closeout or the write blocker is reported.

Final replies should be short: changed files, tests/checks run, outcome, and remaining risks.
