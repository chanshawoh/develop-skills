---
name: omc-cursor-agent
description: Use when orchestrating AI-assisted software development through OMC Claude Code as the planning, specification, verification, and closeout brain, with Cursor CLI Agent headless mode as the implementation worker. Applies from Claude Code with oh-my-claudecode native agents or from other assistants via Claude Code headless handoffs, keeping authoring and verification in separate lanes with prompt-file stdin, resume, docs checks, and permission recovery.
---

# OMC Cursor Agent

This skill mirrors `omx-cursor-agent`. It keeps the same orchestration contract but replaces the OMX/Codex planning brain with **OMC Claude Code** (oh-my-claudecode running inside Claude Code, or an isolated Claude Code headless process). Cursor CLI headless mode stays the implementation worker.

## Core Principle

Keep the role split, with OMC Claude Code as the brain:

- **OMC Claude Code** owns requirement analysis, planning, executable specs, verification, review, and closeout. In Claude Code, this means using the oh-my-claudecode plugin's native skills/agents. In other assistants, this usually means launching `claude -p` or handing off durable prompt/spec files to a Claude Code session that has OMC installed.
- **Cursor CLI Agent** owns implementation, refactors, tests, and implementation reports.
- **The orchestration layer** (whatever assistant loaded this skill) owns: launch tools, pass durable artifacts, monitor progress, recover from launch/permission issues, and summarize verified results.

Critical lane rule (OMC native): **never self-approve in the same active context**. The planning/spec pass and the verification pass must be different OMC agent lanes:

- Planning / spec authoring -> `planner` or `architect` (use `model=opus` for complex work), with `executor`/`writer` for durable doc writes.
- Verification / review -> `verifier` or `code-reviewer` in a separate lane, after the implementation lands. The agent that wrote the spec must not also sign off on the implementation in the same context.

Documentation ownership:

- **Project docs are a shared writable surface**: use the user's requested surface first, then existing project habits, then local `.omc/` or `/tmp/<project-name>/<task-id>/` fallback. The surface may be Obsidian, Notion, local markdown, repo docs, or another project system. The orchestration layer, OMC Claude Code, and Cursor may write there when their role requires it, but each role should keep to its lane.
- **Temporary documentation artifacts must be nested**: never write project docs directly under `/tmp` or a bare `/tmp/<task>/`; use at least `/tmp/<project-name>/<task-id>/`.
- **The orchestration layer owns instruction relay and orchestration state**: capture the user's request, constraints, artifact paths, launch decisions, and status transitions with minimal rewriting.
- **OMC Claude Code owns implementation-facing and human-facing documents**: write specs, implementation handoffs, verification reports, review verdicts, task/status updates, and final closeout notes. Route these through the appropriate OMC agent lane (`planner`/`executor`/`writer` to author, `verifier`/`code-reviewer` to evaluate).
- **Cursor owns implementation evidence**: write implementation reports, changed-file summaries, command/test output, deviations, risks, and blockers. Avoid updating specs, verification reports, final closeout notes, or user-requirement text unless the handoff explicitly lists those files as implementation outputs.

Enhancements over the old skill:

- Use Cursor headless mode, not interactive terminal mode.
- Use high-authority Cursor flags for autonomous local development.
- Run Cursor from the native user environment when possible; Cursor uses the real `HOME`, `~/.cursor`, and macOS Keychain credentials. Do not recover Cursor credential failures by redirecting `HOME` or Cursor state to `/tmp`.
- Put long prompts in temporary files and feed them through stdin.
- Reuse Cursor conversations with `--resume` or `--continue` across orchestration turns.
- Prefer official Cursor docs and current local `--help` over remembered flags.
- Recover from Cursor trust prompts, MCP approval prompts, Claude Code permission prompts, and long prompt quoting failures before declaring a blocker.

## Runtime Surfaces

The caller is not assumed to be Codex. Choose the OMC brain surface that actually exists in the current environment:

- **Claude Code with the oh-my-claudecode plugin installed**: prefer native OMC skills and agents. Use slash skills such as `/oh-my-claudecode:ralplan`, `/oh-my-claudecode:team`, `/oh-my-claudecode:verify`, or the shorter aliases if setup enabled them. Delegate agent lanes with the OMC agent names/prefixes exposed by the session, for example `oh-my-claudecode:planner`, `oh-my-claudecode:architect`, `oh-my-claudecode:executor`, `oh-my-claudecode:writer`, `oh-my-claudecode:verifier`, and `oh-my-claudecode:code-reviewer`.
- **Claude Code without the plugin**: install/setup OMC first, or fall back to plain `claude -p` headless runs with explicit role prompts. Plain Claude Code is not an OMC native lane until the plugin/setup has provided the skills, agents, and MCP config.
- **Codex, Cursor, OpenCode, Gemini CLI, or another assistant**: do not assume native OMC agents are callable. Use durable prompt files and launch `claude -p` as the OMC brain when the `claude` CLI is available, or write a handoff artifact for a human/Claude Code session to run. The current assistant may still orchestrate Cursor and verify local evidence, but must not claim "native OMC verification" unless it actually used an OMC Claude Code lane or a Claude Code headless brain.
- **No Claude Code/OMC available**: run Cursor directly only if the user asked for that fallback, and state that the OMC brain lane was unavailable.

## OMC Plugin Prerequisites

The OMC brain depends on the oh-my-claudecode Claude Code plugin or the OMC npm/runtime install.

Plugin-first setup inside Claude Code:

```text
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
/setup
```

Run those slash commands one at a time inside Claude Code. If the session uses the longer skill names, `/oh-my-claudecode:setup` or `/oh-my-claudecode:omc-setup` are acceptable equivalents.

Terminal/runtime setup:

```bash
npm i -g oh-my-claude-sisyphus@latest
omc setup
```

After setup, the OMC reference skill should be available in Claude Code, commonly as `omc-reference`. It lists the agent catalog, skill registry, model tiers, and runtime tools. If this reference is missing, treat native OMC agent routing as unavailable until setup is fixed.

## Mandatory Documentation Check

Cursor CLI, Claude Code, and OMC change quickly. Before using unfamiliar or failing flags, check:

```bash
cursor-agent --help || agent --help
claude --help
omc --help || true
```

Official Cursor reference provided by the user:

- https://cursor.com/cn/docs/cli/headless

Official OMC reference:

- https://github.com/Yeachan-Heo/oh-my-claudecode

For OMC Claude Code routing and agents, consult the native `omc-reference` skill when skills are available.

If official docs and local help cannot be found, report which command lacks documentation and ask the user to provide it. Do not guess unsupported flags.

Use these references only when relevant:

- Cursor headless and resume: `references/cursor-headless.md`
- OMC Claude Code brain (subagents and `claude -p` headless): `references/claude-code-headless.md`
- Long OMC prompts: `references/claude-code-long-prompts.md`
- Project docs workflow/safety: `references/project-docs-omc-workflow.md`, `references/project-docs-concurrent-edit-safety.md`, `references/project-docs-tmp-artifact-handoff.md`
- Worktrees and merge safety: `references/dirty-worktree-merge.md`, `references/worktree-consolidation-verification.md`
- Fix/review loops: `references/final-acceptance-fix-loop-closeout.md`, `references/claude-code-deep-review.md`

## Default Workflow

1. Inspect only routing state:

```bash
git status --short
git branch --show-current
```

2. Create a durable task id and artifact paths. Prefer the user's requested documentation surface, then existing project habits, then `.omc/` or `/tmp/<project-name>/<task-id>/`.
3. Have OMC Claude Code analyze the user's requirement and write the durable spec. In Claude Code with OMC installed, delegate to the `planner` or `architect` agent (`model=opus` for complex work) and let `executor`/`writer` persist the spec file. Outside Claude Code, run headless `claude -p` with an explicit planner/architect prompt instead (see `references/claude-code-headless.md`).
4. The spec must include an `Implementation Handoff` for Cursor:
   - repo/workdir
   - edit scope and avoid list
   - done-when criteria
   - required tests/checks
   - report path
   - complete prompt for Cursor CLI Agent
5. Launch Cursor headless with a prompt file and full local authority. If the current assistant is running inside Codex Desktop/App, use the launcher's generated `native-command.sh` from Terminal, iTerm, or an attached OMC/OMX tmux shell instead of retrying Cursor inside the app sandbox.
6. Require Cursor to write only the implementation report with summary, files changed, commands run, test results, deviations, risks, and blockers.
7. Have OMC Claude Code write the verification result in a **separate agent lane** (`verifier` or `code-reviewer`, `model=opus` for large/security work), or a separate read-only `claude -p` verification process, after checking Cursor's implementation against the approved spec, report, diff, and tests. Do not reuse the spec-authoring context for this pass.
8. If verification finds issues, route only exact narrow fixes back to Cursor and repeat Cursor -> report -> OMC verification.
9. Have OMC Claude Code close out by updating task/spec/verification docs into a human-readable final state, preserving Cursor's implementation report as downstream evidence, then provide a short user summary.

## Launcher

Use the bundled launcher for direct Cursor implementation/review tasks:

```bash
skills/omc-cursor-agent/scripts/omc-cursor-agent-run.sh \
  --repo /path/to/repo \
  --task <task-id> \
  --prompt-file /tmp/<project-name>/<task-id>/cursor.prompt.md
```

The launcher stores state under `/tmp/omc-cursor-agent-sessions/<task-id>/`. Later turns should reuse the same `task-id` to continue the same Cursor conversation.

## Prompt Rules

For large prompts, never inline the prompt in the shell command:

```bash
cat > /tmp/<project-name>/<task-id>/cursor.prompt.md <<'EOF'
<full Cursor worker prompt>
EOF
```

For OMC brain work inside Claude Code with OMC installed, prefer delegating to OMC subagents via the session's agent/task facility with the user's requirement and artifact instructions. When the caller is not Claude Code or native OMC agents are unavailable, run headless `claude -p` as a separate brain process and pass the prompt through a prompt file on stdin. Do not pre-load large repo summaries; OMC Claude Code should inspect the repo itself.

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
Do not update specs, user-requirement text, verification reports, or closeout notes unless the handoff explicitly lists those files as implementation outputs.
```

OMC verification prompt (route to `verifier`/`code-reviewer`, separate lane):

```text
Verify Cursor's implementation against the approved spec.
Inputs: spec path, implementation report, repo/worktree, current diff, and test output.
Do not modify files.
Write verdict PASS/FAIL/PARTIAL, concrete issues with file:line when possible, missing tests, exact fixes needed, and release readiness.
```

## Cursor Headless Defaults

Use Cursor headless for implementation:

```bash
cursor-agent -p --model auto --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

If the binary is installed as `agent`, use `agent` instead of `cursor-agent`.

Allow the user to specify Cursor's `--model`. If no model is specified, use `auto`. If the user asks for Cursor's available models, run `cursor-agent --list-models` or `agent models` and answer from the command output. If the user asks for `gpt` or `claude` without an exact version or size, choose the newest matching common model from `references/cursor-headless.md`; normalize informal size words such as "high", "高的", "medium", "中等", and "中号". For "最大", "最高", or "最强" wording, choose the largest size available among the matching candidate models, not always `high`. Default to `medium` size when available and use a larger size only when requested or when no matching `medium` model exists.

Use `--continue` for the same repo/task when no explicit chat id was captured. Use `--resume <chatId>` when a chat id was captured. Read `references/cursor-headless.md` before changing this behavior.

Use `--approve-mcps` only when the task likely needs Cursor MCP tools or the user has authorized Cursor's local MCP ecosystem. Never print MCP secrets.

## OMC Claude Code Brain Defaults

Default to native OMC subagents only when the current surface is Claude Code with oh-my-claudecode installed and the OMC agents are available (no recursive process):

- Requirement analysis / plan / spec authoring -> `planner` or `architect` (`model=opus` for complex work).
- Durable doc writes (spec, handoff, closeout) -> `executor` or `writer`.
- Verification / review -> `verifier` or `code-reviewer` in a **separate** lane (`model=opus` for large/security work).

If the caller is another assistant, or if Claude Code is present but OMC native agents are not callable, use headless `claude -p` as the OMC brain. Headless is also appropriate for parallel work, clean context, second opinions, or a worktree-scoped brain. See `references/claude-code-headless.md` for flags and permission-mode mapping. When the session provider is non-standard (CC Switch / Bedrock / Vertex / LiteLLM), pass subagent models as tier aliases (`sonnet`/`opus`/`haiku`), not provider-specific IDs.

## Permission And Sandbox Recovery

- Cursor native runtime: use the real `HOME` and native shell environment. Do not set `HOME=/tmp/...` or redirect `XDG_*` state for Cursor.
- Codex Desktop/App credential failure: if Cursor cannot write `~/.cursor`, reports `SecItemCopyMatching failed -50`, or crashes after HOME/state changes, stop retrying inside the app sandbox and run the generated `native-command.sh` from a native terminal or attached OMC/OMX tmux shell.
- Cursor implementation: `-p --trust --force --sandbox disabled --workspace <repo>`.
- Cursor MCP prompt/approval friction: add `--approve-mcps` if MCP use is intended and safe.
- Cursor resume: `--resume <chatId>` when known; otherwise `--continue` for the same task.
- OMC brain writing inside repo (native): delegate to `executor`/`writer`; edits land under the repo with the assistant's normal permissions.
- OMC brain headless inside repo: `claude -p --permission-mode acceptEdits ... < /tmp/<project-name>/<task-id>/claude.prompt.md`.
- OMC brain writing outside repo, shared docs, cloud-synced folders, or external doc exports: add the target with `--add-dir <path>` and `--permission-mode acceptEdits`, or use `--dangerously-skip-permissions` only when full local authority is required and safe.
- OMC brain resume: `--resume <sessionId>` when known; otherwise `--continue` for the same task.
- Long prompt failure: switch to prompt file stdin.

If a TUI, picker, trust prompt, or approval prompt appears in Cursor, stop that launch shape and switch to headless `-p --trust --force --sandbox disabled` or current documented equivalent. If Claude Code blocks on a permission prompt in headless mode, raise the permission mode (`acceptEdits`) or add the needed dir/tool rather than abandoning the run.

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
- OMC Claude Code verification report/output exists for non-trivial work, produced in a separate agent lane,
- required tests/checks were run or a clear test gap is stated,
- `git status --short` and `git diff --stat` were reviewed,
- no unrelated user changes were overwritten,
- any requested project docs have been reconciled by OMC Claude Code during closeout or the write blocker is reported.

Final replies should be short: changed files, tests/checks run, outcome, and remaining risks.
