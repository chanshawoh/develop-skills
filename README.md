# Development Skills Library

Public, reusable agent skills for common development workflows.

This repository keeps each skill self-contained so it can be installed into
Codex, Cursor, or another compatible skills directory without pulling in
unrelated project state.

## Skills

| Skill | Purpose |
| --- | --- |
| `database-mcp-guard` | Prefer project-matched database MCP tools before database work, with guardrails for destructive operations. |
| `macos-local-runtime` | Prefer existing ServBay Java/Node packages and uv-managed Python on macOS before conservative Homebrew fallbacks. |
| `merge-branch-release` | Safely merge the current working branch into a target release branch, push the target branch, and return to the original branch. |
| `next-ai-drawio` | Help AI agents configure and use the Next AI Draw.io MCP server for browser-previewed draw.io diagram creation, editing, and export. |
| `obsidian-agile-project` | Structure Obsidian vaults for agile PRDs, tasks, progress tracking, and dashboards. |

## Repository Layout

```text
skills/
  <skill-name>/
    SKILL.md
```

Each skill directory should be portable on its own. Avoid storing generated
runtime state, local logs, or project-specific credentials in a skill.

## Install A Skill

For Codex:

```bash
mkdir -p "$HOME/.codex/skills"
cp -R skills/<skill-name> "$HOME/.codex/skills/"
```

For Cursor:

```bash
mkdir -p .cursor/skills
cp -R skills/<skill-name> .cursor/skills/
```

## Skill Standards

- Keep `SKILL.md` concise and focused on agent instructions.
- Use clear YAML frontmatter with `name` and `description`.
- Add scripts or references only when they materially improve repeatability.
- Do not include local workspace paths, secrets, logs, or temporary state.
- Prefer conservative, reversible workflows for git and release skills.

## License

No license has been selected yet. Add one before encouraging external reuse.
