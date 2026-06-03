# Cursor CLI Headless

Use the official Cursor headless docs first:

- https://cursor.com/cn/docs/cli/headless

Confirm current flags with local help:

```bash
cursor-agent --help || agent --help
```

Current local help shows the command as `agent`; this machine also has `cursor-agent`.

Important flags:

- `-p, --print`: headless/script mode. Has access to tools, including write and shell.
- `--output-format text|json|stream-json`: output format with `--print`.
- `--stream-partial-output`: stream partial text deltas with `stream-json`.
- `--mode plan|ask` or `--plan`: read-only planning/ask modes.
- `--resume [chatId]`: resume a specific or selected chat.
- `--continue`: continue the previous session.
- `--model <model>` and `--list-models`.
- `-f, --force` / `--yolo`: force allow commands unless explicitly denied.
- `--sandbox enabled|disabled`: explicitly control Cursor sandbox mode.
- `--approve-mcps`: approve MCP servers for this run.
- `--trust`: trust the workspace without prompting; only works with headless `--print`.
- `--workspace <path>`: set workspace directory.
- `-w, --worktree [name]`: run in a Cursor-managed isolated worktree.

Preferred implementation command:

```bash
cursor-agent -p \
  --trust \
  --force \
  --sandbox disabled \
  --approve-mcps \
  --workspace /path/to/repo \
  < /tmp/<task>.cursor.prompt.md
```

If the binary is named `agent`:

```bash
agent -p --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo < /tmp/<task>.cursor.prompt.md
```

Preferred resume command when a chat id is known:

```bash
cursor-agent -p \
  --trust \
  --force \
  --sandbox disabled \
  --approve-mcps \
  --workspace /path/to/repo \
  --resume <chatId> \
  < /tmp/<task>.cursor.prompt.md
```

Preferred continuity command when no chat id is known but the task/repo pairing is safe:

```bash
cursor-agent -p \
  --trust \
  --force \
  --sandbox disabled \
  --approve-mcps \
  --workspace /path/to/repo \
  --continue \
  < /tmp/<task>.cursor.prompt.md
```

For read-only planning:

```bash
cursor-agent -p --mode plan --trust --workspace /path/to/repo < /tmp/<task>.plan.prompt.md
```

Progress notes:

- Headless output may be sparse. Monitor report files and git diff, not only stdout.
- `--trust` must be paired with `--print`; otherwise trust prompts may still appear.
- `--force` authorizes operations but does not replace `--trust`.
- `--approve-mcps` can expose powerful local tools. Use it only when intended.
- Do not print MCP environment secrets.
- Do not let Cursor commit, push, deploy, or open PRs unless the user explicitly asked.
