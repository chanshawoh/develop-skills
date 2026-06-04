# Claude Code Headless / OMC Brain

This is the OMC Claude Code analog of `cursor-headless.md`. It covers how to run the **planning/verification brain** as OMC Claude Code, either as native oh-my-claudecode subagents in Claude Code or as an isolated headless `claude -p` process from any assistant that can launch local commands.

Confirm current flags with local help before using unfamiliar ones:

```bash
claude --help
```

For OMC agent routing, model tiers, and the team pipeline, consult the native `omc-reference` skill when skills are available. If `omc-reference` is missing, do not assume native OMC agents exist.

## Installation / Availability

Native OMC lanes require Claude Code with the oh-my-claudecode plugin installed and setup completed.

Inside Claude Code, install the plugin with slash commands entered one at a time:

```text
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
/setup
```

The terminal/runtime path is:

```bash
npm i -g oh-my-claude-sisyphus@latest
omc setup
```

Use `claude --help`, `omc --help`, and the session's `omc-reference` skill to confirm current flags and agent names.

## Two Brain Modes

### Mode A — Native OMC subagents (default only inside Claude Code + OMC)

No recursive `claude` process. The assistant delegates to oh-my-claudecode subagents via the Claude Code session's Task/Agent facility. Keep authoring and verification in **separate lanes**:

- Requirement analysis / plan / spec authoring -> `planner` or `architect`.
- Durable doc writes (spec, handoff, closeout) -> `executor` or `writer`.
- Verification / review -> `verifier` or `code-reviewer`, after implementation, in a separate context.

Agent names may appear with the `oh-my-claudecode:` prefix depending on the session surface, for example `oh-my-claudecode:planner` and `oh-my-claudecode:verifier`.

Model tiers: `haiku` (quick lookups), `sonnet` (standard), `opus` (architecture, deep analysis, large/security verification). Pass `model` on the Agent call.

This mode shares the current repo and the assistant's normal file permissions, so spec/handoff/closeout writes land directly.

Do not use this mode from Codex, Cursor, OpenCode, Gemini CLI, or another non-Claude-Code assistant unless that surface explicitly exposes Claude Code OMC agents. Use Mode B instead.

### Mode B — Headless `claude -p` subprocess

Use when the current caller is not Claude Code, when native OMC agents are unavailable, or when you need an isolated brain process: parallel brains, a clean context window, a worktree-scoped brain, or a second opinion that must not see the current context.

```bash
claude -p \
  --permission-mode acceptEdits \
  --add-dir /path/to/repo \
  < /tmp/<project-name>/<task-id>/claude.prompt.md
```

For verification, prefer read-only permissions:

```bash
claude -p \
  --permission-mode plan \
  --add-dir /path/to/repo \
  < /tmp/<project-name>/<task-id>/claude.verify.prompt.md
```

Important flags:

- `-p, --print`: headless/non-interactive mode; print result and exit.
- `--output-format text|json|stream-json`: output format with `--print`.
- `--input-format text|stream-json`: input format.
- `--permission-mode <mode>`: `default` | `acceptEdits` | `plan` | `bypassPermissions`.
- `--dangerously-skip-permissions`: bypass all permission prompts; only in externally-hardened/safe contexts.
- `--add-dir <path>`: grant access to extra directories outside the cwd.
- `--allowedTools` / `--disallowedTools`: restrict the tool set for the run.
- `--model <model>`: pin the model. Use tier aliases on non-standard providers (see below).
- `--resume [sessionId]`: resume a specific session.
- `--continue`: continue the most recent session in this directory.
- `--append-system-prompt <text>`: add to the system prompt (e.g. lane/role constraint).

## Permission Mode Mapping (vs OMX/Codex sandbox)

The old `omx-cursor-agent` skill used Codex sandbox modes. OMC Claude Code maps them as:

- Codex `read-only` -> Claude `--permission-mode plan` (read/plan, no writes).
- Codex `workspace-write` -> Claude `--permission-mode acceptEdits` writing inside the repo / cwd.
- Codex `danger-full-access` / `--yolo` -> Claude `--add-dir <external>` + `acceptEdits`, or `--dangerously-skip-permissions` only when full local authority is required and safe.

Default brain modes:

- Spec / plan authoring inside repo: native `planner`/`architect` + `executor`/`writer`, or headless `claude -p --permission-mode acceptEdits`.
- Writing outside repo, shared docs, cloud-synced folders, or external doc exports: add `--add-dir <path>` (headless) or just use the assistant's own file tools (native), preferring the least authority that works.
- Read-only verification: `verifier`/`code-reviewer` (native), or headless `claude -p --permission-mode plan`. The verification lane must not modify source.

## Resume / Continue

- Native subagents do not resume; spawn a fresh lane each pass and pass durable artifact paths (spec, report, diff) as inputs.
- Headless: `--resume <sessionId>` when a session id was captured; otherwise `--continue` for the same repo/task.

## Non-Standard Provider Note

When the session provider is non-standard (CC Switch / Bedrock / Vertex / LiteLLM), pass subagent models as tier aliases (`sonnet`/`opus`/`haiku`), not provider-specific IDs. The pre-tool enforcer resolves tiers to provider-safe IDs; bare provider IDs and `[1m]`-suffixed IDs are denied for subagents.

## Progress Notes

- Native subagent results return as the tool result; relay only what matters. This applies only when the current surface actually supports OMC native agents.
- For headless runs, monitor durable artifacts (report files, `git status --short`, `git diff --stat`), not just stdout.
- Keep the spec-authoring lane and the verification lane separate; never self-approve in the same active context.
- Do not let the brain commit, push, deploy, or open PRs unless the user explicitly asked.
