# OpenCode Non-Interactive Development

Use official OpenCode docs when available, then confirm flags with local help.

Official docs checked while authoring:

- https://open-code.ai/en/docs/cli

```bash
opencode run --help
```

Known current flags from local help:

- `opencode run [message..]`: non-interactive message run.
- `-c, --continue`: continue the last session.
- `-s, --session <id>`: continue a specific session id.
- `--format json`: emit raw JSON events.
- `--dir <DIR>`: set directory.
- `--agent <AGENT>` and `--model <provider/model>`: select worker.
- `--dangerously-skip-permissions`: auto-approve permissions not explicitly denied.
- `--attach <server>`: attach to a running server when needed.

Preferred command shape:

```bash
opencode run \
  --dir /path/to/repo \
  --format json \
  --print-logs \
  --log-level INFO \
  --dangerously-skip-permissions \
  "$(cat /tmp/<task>.prompt.md)"
```

Preferred resume shape:

```bash
opencode run \
  --dir /path/to/repo \
  --format json \
  --print-logs \
  --log-level INFO \
  --dangerously-skip-permissions \
  --session <session-id> \
  "$(cat /tmp/<task>.prompt.md)"
```

If nested sandboxing prevents OpenCode from writing its local database or cache, retry with task-local state:

```bash
mkdir -p /tmp/opencode-<task>-data /tmp/opencode-<task>-cache /tmp/opencode-<task>-state
XDG_DATA_HOME=/tmp/opencode-<task>-data \
XDG_CACHE_HOME=/tmp/opencode-<task>-cache \
XDG_STATE_HOME=/tmp/opencode-<task>-state \
opencode run --dir /path/to/repo --dangerously-skip-permissions "$(cat /tmp/<task>.prompt.md)"
```

Capture session ids from JSON output when present. If no id is exposed, persist that the next run should use `--continue`, but only for the same repo/task.
