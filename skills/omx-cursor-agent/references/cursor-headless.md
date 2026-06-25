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

## Native macOS Runtime

Cursor CLI Agent should run in the user's native macOS environment whenever possible:

- Use the real `HOME` and the user's normal shell environment so Cursor can access `~/.cursor` and macOS Keychain credentials.
- Use `--sandbox disabled` for Cursor's own sandbox, but do not confuse that with the outer host application's sandbox.
- Do not recover Cursor credential failures by setting `HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, or `XDG_STATE_HOME` to `/tmp`.
- If a launcher is running from Codex Desktop/App, prefer generating a shell script and running it from Terminal, iTerm, or an attached OMX/OMC tmux shell.

Known bad recovery pattern:

```bash
HOME=/tmp/cursor-home cursor-agent -p ...
```

This can make Cursor miss its real profile and trigger native credential errors such as `SecItemCopyMatching failed -50` or crashes. Treat those symptoms as evidence to move the Cursor run to the native environment, not as a reason to keep changing state directories.

## Model Selection

Allow the user to specify Cursor's `--model` value. If the user asks what Cursor models are available, run `cursor-agent --list-models` or `agent models` and answer from the command output, not from the common-model list below. Confirm availability with those commands when the requested model may not be available for the current account.

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
  - `medium`: `medium`, `mid`, `middle`, `normal`, `default`, `标准`, `默认`, `中`, `中等`, `中号`, `中配`
  - `high`: `high`, `higher`, `large`, `big`, `大的`, `大号`, `高`, `高的`, `高配`, `强`, `强的`
  - largest available size: `largest`, `max`, `maximum`, `highest`, `strongest`, `最大`, `最高`, `最强`, `最最大`, `拉满`
- If the user asks for the largest size, choose the largest matching candidate present in the current available model list or, if not checking live availability, in the common model list. Do not assume largest means `high`; Claude may have `xhigh` or `max`.
- If the user asks for `gpt` without a version, use the newest GPT common model with `medium` size when available: `gpt-5.5-medium`.
- If the user asks for `gpt-5.5` without a size, use `gpt-5.5-medium`.
- If the user asks for `gpt-5.3-codex` without a size, use `gpt-5.3-codex-high` because no common `medium` variant is listed.
- If the user asks for `claude`, `opus`, or `claude opus` without a version, use the newest Claude common model with `medium` size when available: `claude-opus-4-8-medium`.
- If the user asks for `claude-opus-4-8` without a size, use `claude-opus-4-8-medium`.
- If the user asks for no model, use `auto`.
- Do not silently choose a larger size when a matching `medium` model exists, unless the user asked for a larger/largest size or no matching `medium` model exists.

Preferred implementation command:

```bash
cursor-agent -p \
  --model auto \
  --trust \
  --force \
  --sandbox disabled \
  --approve-mcps \
  --workspace /path/to/repo \
  < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

If the binary is named `agent`:

```bash
agent -p --model auto --trust --force --sandbox disabled --approve-mcps --workspace /path/to/repo < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

Preferred resume command when a chat id is known:

```bash
cursor-agent -p \
  --model auto \
  --trust \
  --force \
  --sandbox disabled \
  --approve-mcps \
  --workspace /path/to/repo \
  --resume <chatId> \
  < /tmp/<project-name>/<task-id>/cursor.prompt.md
```

Preferred continuity command when no chat id is known but the task/repo pairing is safe:

```bash
cursor-agent -p \
  --model auto \
  --trust \
  --force \
  --sandbox disabled \
  --approve-mcps \
  --workspace /path/to/repo \
  --continue \
  < /tmp/<project-name>/<task-id>/cursor.prompt.md
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
