# Cursor CLI Headless

Use official Cursor docs first when available:

- https://cursor.com/cn/docs/cli/headless

Confirm current flags with local help:

```bash
cursor-agent --help || agent --help
```

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

## Model Selection

Allow the user to specify Cursor's `--model` value. If the user asks what Cursor models are available, run `cursor-agent --list-models` or `agent models` and answer from the command output, not from the common-model list below.

Common model values for defaults and normalization:

- `auto`
- `composer-2.5`
- `gpt-5.3-codex-high`
- `gpt-5.5-high`
- `gpt-5.5-medium`
- `claude-opus-4-8-medium`
- `claude-opus-4-8-high`
- `claude-opus-4-8-xhigh`
- `claude-opus-4-8-max`

Default resolution:

- If the user names an exact model from the available list, pass it through unchanged.
- Normalize informal size words before choosing the model. Size order from smaller to larger is `medium` < `high` < `xhigh` < `max`.
- If the user asks for the largest size, choose the largest matching candidate present in the current available model list or, if not checking live availability, in the common model list.
- If the user asks for `gpt` without a version, use the newest GPT common model with `medium` size when available: `gpt-5.5-medium`.
- If the user asks for `gpt-5.5` without a size, use `gpt-5.5-medium`.
- If the user asks for `gpt-5.3-codex` without a size, use `gpt-5.3-codex-high` because no common `medium` variant is listed.
- If the user asks for `claude`, `opus`, or `claude opus` without a version, use the newest Claude common model with `medium` size when available: `claude-opus-4-8-medium`.
- If the user asks for `claude-opus-4-8` without a size, use `claude-opus-4-8-medium`.
- If the user asks for no model, use `auto`.

Preferred implementation command:

```bash
cursor-agent -p --model auto --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

If the binary is named `agent`:

```bash
agent -p --model auto --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

Preferred resume command when a chat id is known:

```bash
cursor-agent -p --model auto --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo --resume <chatId> < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

Preferred continuity command when no chat id is known but the task/repo pairing is safe:

```bash
cursor-agent -p --model auto --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo --continue < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

For read-only planning:

```bash
cursor-agent -p --mode plan --model auto --trust --workspace /path/to/repo < /tmp/<project-name>/<task-id>/plan.prompt.md
```

Progress notes:

- Headless output may be sparse. Monitor report files and git diff, not only stdout.
- `--trust` must be paired with `--print`; otherwise trust prompts may still appear.
- `--force` authorizes operations but does not replace `--trust`.
- `--approve-mcps` can expose powerful local tools. Use it only when intended.
- Do not print MCP environment secrets.
- Do not let Cursor commit, push, deploy, or open PRs unless the user explicitly asked.
