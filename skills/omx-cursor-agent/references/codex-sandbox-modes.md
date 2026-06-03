# Codex CLI Sandbox Modes

Source: https://developers.openai.com/codex/config-reference

## CLI Flag

```
-s, --sandbox <MODE>
```

Modes: `read-only` | `workspace-write` | `danger-full-access`

## config.toml Key

```toml
sandbox_mode = "workspace-write"
```

Place in `~/.codex/config.toml` (global) or `.codex/config.toml` (project).

Setting this globally means every `codex exec` / `omx exec` command can write files without the `-s` flag.

## Key Behavior

- `codex exec` (non-interactive) defaults to `read-only` sandbox
- `codex` (interactive TUI) behavior may differ
- `workspace-write` allows writes within the project directory + /tmp
- `danger-full-access` removes all filesystem restrictions

## Related Config Keys

- `sandbox_workspace_write.exclude_slash_tmp` — exclude /tmp from writable roots
- `sandbox_workspace_write.exclude_tmpdir_env_var` — exclude $TMPDIR from writable roots
- `sandbox_workspace_write.network_access` — allow network access in workspace-write mode

## Full Bypass

```
--dangerously-bypass-approvals-and-sandbox / --yolo
```

Runs without approvals or sandboxing. Only for externally-hardened environments.
