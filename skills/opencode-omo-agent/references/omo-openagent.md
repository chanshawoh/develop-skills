# Oh My OpenAgent / OMO Reference

Source studied: `code-yeongyu/oh-my-openagent` README, CLI reference, configuration reference, orchestration guide, team-mode guide, and `src/cli/run/*`.

## Editions

- **Ultimate**: OpenCode plugin installed with `bunx oh-my-openagent install`; includes OMO agents, hooks, MCPs, slash commands, Team Mode, tmux, and orchestration.
- **Light**: Codex CLI plugin installed with `npx lazycodex-ai install`; includes portable Codex components but not full OpenCode agent orchestration.

For this skill, "OMO worker" means OpenCode with the OMO Ultimate plugin loaded. The most direct non-interactive path is `opencode run` with a message that includes an OMO slash command such as `/ulw-loop`.

## Command Names

Published package names:

- `oh-my-openagent` preferred.
- `oh-my-opencode` compatibility name.
- Local bin alias `omo`.
- `lazycodex-ai` is the Codex Light installer shortcut.

Important: upstream warns not to use `bunx omo` or `npx omo`, because npm may resolve a different package. Use `bunx oh-my-openagent` or `bunx oh-my-opencode` when invoking through a package runner.

## Non-Interactive OpenCode Run

Canonical OMO Ultimate run:

```bash
opencode run --auto --dir /repo \
  "/ulw-loop Read the complete task prompt from this local file, then follow it exactly: /tmp/<task>.prompt.md"
```

Wrapper compatibility:

```bash
oh-my-openagent run --directory /repo --agent sisyphus "/ulw-loop task prompt"
oh-my-opencode run --directory /repo --agent prometheus "/ralph-loop task prompt"
```

Options confirmed from docs/source:

- `-a, --agent <name>`: agent to use.
- `-m, --model <provider/model>`: model override.
- `-d, --directory <path>`: working directory.
- `-p, --port <port>`: server port; attaches if already in use.
- `--attach <url>`: attach to an existing OpenCode server.
- `--on-complete <command>`: shell command after completion.
- `--json`: structured JSON output.
- `--no-timestamp`: disable timestamp prefix.
- `--verbose`: full event stream.
- `--session-id <id>`: resume existing session.

`opencode run` starts/connects to OpenCode. With the OMO plugin installed, a message whose first user-visible text is a raw slash command such as `/ulw-loop` is intercepted by OMO's OpenCode hooks and routed through the slash-command/chat-message path.

Do not confuse this with the Codex Light `omo ulw-loop` component CLI. The Codex component is installed by `lazycodex-ai`; OMO Ultimate slash commands run inside OpenCode.

For raw `opencode run`, only pass `--agent` when the value is visible in `opencode agent list`. The OMO package wrapper accepts OMO agent ids such as `sisyphus`, `hephaestus`, `prometheus`, and `atlas`; raw OpenCode may expose display names or let the OMO slash-command hook route the work.

## Agent Resolution

Resolution order:

1. `--agent`
2. `OPENCODE_DEFAULT_AGENT`
3. `default_run_agent` in `.opencode/oh-my-openagent.json[c]` or `.opencode/oh-my-opencode.json[c]`
4. `sisyphus`

Source note: one generated `src/cli/run/AGENTS.md` file mentions `OPENCODE_AGENT`, but `src/cli/run/agent-resolver.ts` and CLI help use `OPENCODE_DEFAULT_AGENT`. Prefer `--agent` to avoid ambiguity.

## Agent Map

Primary agents:

- `sisyphus`: lead orchestrator. Best default for broad work, ultrawork, delegation, and "finish this" requests.
- `hephaestus`: autonomous deep worker. Best for implementation, refactors, difficult bugs, and multi-file technical execution. Built for GPT-family models.
- `prometheus`: strategic planner/interviewer. Read-only planning/spec role; do not ask it to implement.
- `atlas`: conductor/executor for existing plans; coordinates task execution and delegates writing.

Subagents:

- `oracle`: architecture/debug consultation and skeptical review.
- `librarian`: docs/code search.
- `explore`: fast codebase grep and pattern discovery.
- `multimodal-looker`: vision/screenshots.
- `metis`: plan gap analyzer.
- `momus`: rigorous reviewer.
- `sisyphus-junior`: focused task executor used by Atlas/category routing.

Team Mode eligible direct members: `sisyphus`, `atlas`, `sisyphus-junior`; `hephaestus` is conditional on teammate permission. `oracle`, `librarian`, `explore`, `multimodal-looker`, `metis`, `momus`, and `prometheus` are hard-rejected as Team Mode members.

## Model Matching

General families:

- Claude/Kimi/GLM style: communicative, long instruction following. Good for `sisyphus`, `prometheus`, `atlas`, `metis`, broad orchestration.
- GPT style: principle-driven autonomous technical work. Required/preferred for `hephaestus`, `oracle`, `momus`, deep coding categories.
- Gemini/Qwen style: visual/frontend/design tasks.
- MiniMax and other cheap models: utility/search/light tasks, not deep autonomous work.

Safe defaults:

- Sisyphus: Claude Opus/Sonnet, Kimi K2.6/K2.5, GLM 5/5.1, or GPT-5.5 only where dedicated prompt paths exist.
- Hephaestus: GPT-5.5 or GPT-5.5 Codex through OpenAI, Copilot, OpenCode, Vercel, or equivalent GPT-family provider.
- Prometheus: Claude/Kimi/GLM for interview/planning, GPT-5.5 where GPT prompt path is available.
- Atlas: Claude Sonnet/Kimi/GPT-5.5.
- Visual tasks: Gemini 3.1 Pro, with Qwen as alternate.

Dangerous overrides:

- Do not put Hephaestus on Claude/Kimi/GLM/MiniMax for deep work.
- Do not use MiniMax for Oracle/Momus deep reasoning.
- Do not use Opus for Explore/Librarian utility work unless the user explicitly accepts the cost waste.

Use diagnostics before exact model promises:

```bash
opencode models
opencode auth list
oh-my-openagent doctor --verbose
```

## Config Files

Config discovery:

1. Project walk from working directory: `.opencode/oh-my-openagent.json[c]` or legacy `.opencode/oh-my-opencode.json[c]`.
2. User config: `~/.config/opencode/oh-my-openagent.json[c]` or legacy basename.

Useful fields:

- `default_run_agent`
- `agent_order`
- `disabled_agents`
- `agents.<name>.model`
- `agents.<name>.fallback_models`
- `agents.<name>.variant`
- `agents.<name>.reasoningEffort`
- `categories.<name>.model`
- `team_mode.enabled`

Schema:

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json"
}
```

## Team Mode

Enable in OMO config:

```jsonc
{
  "team_mode": {
    "enabled": true,
    "max_parallel_members": 4,
    "max_members": 8,
    "tmux_visualization": false
  }
}
```

Team specs live under `~/.omo/teams/{name}/config.json` or `<project>/.omo/teams/{name}/config.json`.

Member kinds:

- `subagent_type`: direct eligible agent.
- `category`: routes through `sisyphus-junior` with a category model.

Team Mode is overkill for small edits; prefer one OMO run unless the work naturally splits into parallel lanes.

## Slash Command Trigger

Confirmed from upstream source:

- `src/plugin/chat-message/loop-commands.ts` parses raw `/ralph-loop` and `/ulw-loop` messages.
- `src/plugin/chat-message.test.ts` covers raw `/ulw-loop "Ship feature" --strategy=continue` through the chat-message fallback.
- `src/plugin/command-execute-before.ts` handles native command execution for `ralph-loop` and `ulw-loop`.
- `src/features/builtin-commands/commands.ts` defines the built-in `ulw-loop` command template.

Practical invocation:

```bash
opencode run --auto --dir /repo "/ulw-loop Ship the requested feature"
```

Short prompts can be written directly after `/ulw-loop`. Longer prompts should be stored in a local prompt file and passed by path, not via `$(cat ...)`.

Only add `--format json --print-logs --log-level INFO`, `--agent`, `--model`, `--continue`, or `--session` when there is a concrete reason. The stable default is a fresh direct `opencode run` with `/ulw-loop` at the very beginning of the message.
