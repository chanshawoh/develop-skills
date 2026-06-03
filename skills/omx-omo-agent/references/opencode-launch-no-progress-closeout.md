# OpenCode/OMO No-Progress Closeout

Use when OpenCode/OMO implementation launch appears accepted but makes no observable progress.

## Progress Gate

Do not wait indefinitely on process liveness. After each launch mode, verify all three surfaces:

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard | head -40
test -s /path/to/implementation-report.md && wc -l /path/to/implementation-report.md || echo NO_REPORT
```

Treat as no progress when all are true after a reasonable wait:

- stdout/logs show no model/tool activity,
- worktree has no modified or untracked files,
- expected report is absent or still the placeholder.

## Escalation Sequence

1. Direct one-shot from worktree:

```bash
cd /path/to/worktree && opencode run "$(cat /tmp/<task>-omo-prompt.txt)"
```

2. Retry with task-local OpenCode state:

```bash
mkdir -p /tmp/opencode-<task>-data /tmp/opencode-<task>-cache /tmp/opencode-<task>-state
XDG_DATA_HOME=/tmp/opencode-<task>-data \
XDG_CACHE_HOME=/tmp/opencode-<task>-cache \
XDG_STATE_HOME=/tmp/opencode-<task>-state \
opencode run --dir /path/to/worktree --print-logs --log-level INFO --dangerously-skip-permissions "$(cat /tmp/<task>-omo-prompt.txt)"
```

3. OpenCode server/API supervision:

Start or attach to `opencode serve`, create a session via HTTP API, send `prompt_async`, and poll status/messages/diff/questions/permissions. See `opencode-server-supervision.md`.

4. Codex launcher workaround:

```bash
mkdir -p /tmp/opencode-<task>-data /tmp/opencode-<task>-cache /tmp/opencode-<task>-state
XDG_DATA_HOME=/tmp/opencode-<task>-data \
XDG_CACHE_HOME=/tmp/opencode-<task>-cache \
XDG_STATE_HOME=/tmp/opencode-<task>-state \
opencode run --print-logs --log-level INFO "$(cat /tmp/<task>-omo-prompt.txt)"
```

Do not retry through a TUI unless the user explicitly asks for an interactive terminal session.

## Stop Rule

If all attempted modes show no diff/report/log progress, stop retrying. This is a launch/progress blocker, not implementation completion.

Write a concise failure artifact, for example `/tmp/<task>-opencode-launch-failure.md`, containing:

- attempted commands/modes,
- evidence from status/diff/untracked/report checks,
- exact report/spec/worktree paths,
- final status: implementation not started.

Update the Obsidian implementation report to `status: blocked` with `Files changed: none`, `Tests run: not run`, concrete blockers, and the failure-artifact path.

Update the orchestration task note to blocked only after re-reading it, preserving board/task visibility. Keep any implementation worktree intact for relaunch.

## Pitfalls

- Do not call the code task failed when implementation never started; call launch blocked.
- Do not keep retrying the same silent launch path after two no-progress gates.
- Do not record durable memory that OpenCode/OMO is broken; this can be environment/session-specific.
- Do not remove the implementation worktree unless the user asks; it may be useful for manual relaunch.
