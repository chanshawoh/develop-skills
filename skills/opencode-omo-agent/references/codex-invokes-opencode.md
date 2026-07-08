# Codex as OpenCode/OMO Launcher

Use when the user asks to route OpenCode/OMO through Codex, or direct Hermes `opencode run` launches stall while Codex remains usable.

## Pattern

1. Keep Hermes in scheduler role; Codex is also an orchestrator here, not the implementation worker.
2. Write two prompt files:
   - `/tmp/<task>-omo-fix-prompt.txt`: starts with `/ralph-loop ...` and contains the actual implementation task for OpenCode/OMO.
   - `/tmp/<task>-codex-invoke-opencode.txt`: instructs Codex to run OpenCode, monitor output/diff/report, and not edit source itself.
3. Launch Codex with current CLI-compatible flags:

```bash
codex exec --full-auto -C /path/to/worktree < /tmp/<task>-codex-invoke-opencode.txt
```

Use `--full-auto` rather than older/unsupported `--ask-for-approval never` on current Codex versions. If unsure, check `codex exec --help`.

## OpenCode DB Sandbox Workaround

When Codex runs in `workspace-write`, OpenCode may fail writing its default database under `~/.local/share/opencode/opencode.db`, with errors like:

```text
Failed to run the query 'PRAGMA wal_checkpoint(PASSIVE)'
Error: attempt to write a readonly database
```

Do not conclude OpenCode is broken. Have Codex retry OpenCode with XDG state/data/cache/config redirected to writable `/tmp` paths:

```bash
mkdir -p /tmp/opencode-<task>-data /tmp/opencode-<task>-cache /tmp/opencode-<task>-state /tmp/opencode-<task>-config
XDG_DATA_HOME=/tmp/opencode-<task>-data \
XDG_CACHE_HOME=/tmp/opencode-<task>-cache \
XDG_STATE_HOME=/tmp/opencode-<task>-state \
XDG_CONFIG_HOME=/tmp/opencode-<task>-config \
opencode run --auto --print-logs --log-level INFO \
  "/ralph-loop Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>-omo-fix-prompt.txt"
```

This keeps source edits in the worktree while letting OpenCode write its own SQLite/session files.

## Monitoring

Check all three before declaring progress:

```bash
git status --short
git diff --stat -- . ':(exclude).omx'
test -s /path/to/report.md && wc -l /path/to/report.md || echo NO_REPORT
```

If Codex/OpenCode is running but there is no new diff/report after a few minutes, capture the exact command and failure mode in the task report, then choose another route (OMX, direct OpenCode TUI, or user-auth fix).

## Pitfalls

- MCP token refresh warnings from Codex can be noisy and non-fatal; look for actual agent continuation or final error.
- `opencode run "$(cat prompt)"` can fail from malformed shell quoting or nested-sandbox OpenCode DB writes. Prefer passing the prompt file path in the OpenCode message.
- Do not let Codex implement the code if the user's requested boundary is “Codex invokes OpenCode”; the implementation worker should still be OpenCode/OMO.
