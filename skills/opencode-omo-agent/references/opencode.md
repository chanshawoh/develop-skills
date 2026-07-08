# OpenCode Non-Interactive Development

Use official OpenCode docs when available, then confirm flags with local help.

Official docs checked while authoring:

- https://opencode.ai/docs/zh-cn/cli/

```bash
opencode run --help
```

Known current flags from official docs and local help:

- `opencode run [message..]`: non-interactive message run.
- `-c, --continue`: continue the last session.
- `-s, --session <id>`: continue a specific session id.
- `--format json`: emit raw JSON events.
- `--dir <DIR>`: set directory.
- `-f, --file <path>`: attach files to the message.
- `--title <text>`: set a stable session title.
- `--attach <url>`: attach the run command to an existing `opencode serve` backend.
- `--port <port>`: choose the local server port when OpenCode starts one for the run.
- `--agent <AGENT>` and `--model <provider/model>`: select worker.
- `--variant <name>`: provider-specific reasoning/model variant.
- `--thinking`: show thinking blocks when supported.
- `--auto`: auto-approve permissions not explicitly denied. Older installs may expose `--dangerously-skip-permissions` instead.

Preferred command shape:

```bash
opencode run \
  --dir /path/to/repo \
  --auto \
  --title <task-id> \
  "Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>.prompt.md"
```

The bundled launcher probes `opencode run --help` and chooses `--auto` when available, falling back to `--dangerously-skip-permissions` only for older OpenCode builds that still advertise it.

For OMO slash commands, keep the slash command at the beginning and still pass the prompt file by path:

```bash
opencode run \
  --dir /path/to/repo \
  --auto \
  "/ulw-loop Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>.prompt.md"
```

For repeated short runs, attach to a long-lived server to avoid repeated cold starts:

```bash
opencode serve --port 4096

opencode run \
  --attach http://localhost:4096 \
  --dir /path/to/repo \
  --auto \
  "Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>.prompt.md"
```

The launcher accepts `--attach <url>` directly. It also treats `OPENCODE_HOST` as the default attach URL and `OPENCODE_PORT` as the default run port, mirroring the OpenChamber pattern for connecting to an existing OpenCode server.

Optional resume shape:

```bash
opencode run \
  --dir /path/to/repo \
  --auto \
  --session <session-id> \
  "Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>.prompt.md"
```

Avoid hand-writing `$(cat /tmp/<task>.prompt.md)` in AI-generated commands. Missing a closing `)` or quote breaks the command, and prompt-file paths are easier for OpenCode/OMO to handle.

If nested sandboxing prevents OpenCode from writing its local database or cache, retry with task-local state. This isolates OpenCode config/auth/cache from the normal user install, so use it only as a recovery path or with already-provided environment credentials:

```bash
mkdir -p /tmp/opencode-<task>-data /tmp/opencode-<task>-cache /tmp/opencode-<task>-state
XDG_DATA_HOME=/tmp/opencode-<task>-data \
XDG_CACHE_HOME=/tmp/opencode-<task>-cache \
XDG_STATE_HOME=/tmp/opencode-<task>-state \
opencode run --dir /path/to/repo --auto \
  "Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>.prompt.md"
```

Capture session ids from JSON output when present. If no id is exposed, persist that the next run should use `--continue`, but only for the same repo/task.

OpenChamber reference points worth keeping:

- Persisted OpenCode state/config directories make long-lived server runs more reliable than ad hoc state for GUI or remote use.
- `OPENCODE_HOST` plus `OPENCODE_SKIP_START=true` is their external-server model; for this launcher the comparable direct-run path is `OPENCODE_HOST=<url>` or `--attach <url>`.
- Service contexts need explicit `PATH`, auth variables, and SSH agent environment. Do not assume a background/service-launched OpenCode sees the same tools as an interactive shell.
