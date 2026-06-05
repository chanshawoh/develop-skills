# OMO `/ralph-loop` Launch Pattern

Use when launching OpenCode/OMO for this user's implementation work.

## Preferred command

Run from the target repo/worktree explicitly:

```bash
cd /path/to/worktree && opencode run "/ralph-loop <work prompt>"
```

For long prompts, keep the first token `/ralph-loop` in the prompt file and run:

```bash
cd /path/to/worktree && opencode run \
  "/ralph-loop Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>-ralph-loop-prompt.txt"
```

Use `/ralph-loop` as the first token in the prompt. Do not default to `ultrawork` unless the user asks for it.

## If one-shot appears stuck

Symptoms:

- `opencode run ...` process stays running.
- No stdout/stderr lines after several minutes.
- Worktree has no `git status --short` changes beyond the pre-existing baseline.
- Expected report file is absent.

Safe check sequence:

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard | head
test -s /path/to/expected-report.md && wc -l /path/to/expected-report.md || echo NO_REPORT
```

Use a progress gate instead of waiting indefinitely: record the baseline diff/report state at launch, then re-check after a few minutes. If there is still no stdout, no new diff, and no report, kill the stuck process and retry with a different non-interactive launch mode. Do not let a silent one-shot run for an hour just because the PID is alive.

Preferred retry order for message-channel assistants:

1. Retry with `--print-logs --log-level INFO`.
2. Retry with task-local `XDG_DATA_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME` under `/tmp`.
3. Use `opencode serve` and the HTTP API; see `opencode-server-supervision.md`.
4. Use the Codex-launches-OpenCode workaround; see `codex-invokes-opencode.md`.

Do not use a TUI retry unless the user explicitly asks for an interactive terminal session.

## Silent Output Cases

If `opencode run` appears silent, do not conclude the task failed from logs alone. Distinguish these cases:

1. **Logs are silent, but worktree/report changes appear**: the agent is working; continue supervising via `git status`, report file, and process completion.
2. **Logs are silent and no diff/report appears after several minutes**: treat as stuck; kill and retry with non-interactive logs, `/tmp` XDG state, server/API, or Codex-launcher mode.
3. **A terminal/TUI was explicitly requested and shows prompt text but no response**: prompt may be sitting in the input box; switch back to one-shot/server mode unless the user wants live terminal operation.

When recording the command in a blocker artifact, include the exact `cd /path && opencode run ...` shape.

## Progress verification

Do not trust a running process as progress. Verify at least one of:

- log contains model response/tool activity,
- worktree has modified/untracked files beyond the pre-launch baseline,
- requested report file exists and has content.

If none are true after a reasonable wait, report no progress and change launch mode. When a user asks "is it done yet?" or similar, immediately poll the process plus baseline diff/report state and give a direct status: running-but-no-progress, running-with-progress, completed, or stuck-and-retried. Do not answer from process liveness alone.
