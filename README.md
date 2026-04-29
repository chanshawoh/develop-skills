# Development Skills Library

Public, reusable agent skills for common development workflows.

This repository keeps each skill self-contained so it can be installed into
Codex, Cursor, or another compatible skills directory without pulling in
unrelated project state.

## Skills

| Skill | Purpose |
| --- | --- |
| `merge-branch-release` | Safely merge the current working branch into a target release branch, push the target branch, and return to the original branch. |

## Repository Layout

```text
skills/
  <skill-name>/
    SKILL.md
    agents/
      openai.yaml
```

Each skill directory should be portable on its own. Avoid storing generated
runtime state, local logs, or project-specific credentials in a skill.

## Install A Skill

For Codex:

```bash
mkdir -p "$HOME/.codex/skills"
cp -R skills/merge-branch-release "$HOME/.codex/skills/"
```

For Cursor:

```bash
mkdir -p .cursor/skills
cp -R skills/merge-branch-release .cursor/skills/
```

## Skill Standards

- Keep `SKILL.md` concise and focused on agent instructions.
- Use clear YAML frontmatter with `name` and `description`.
- Put UI metadata in `agents/openai.yaml`.
- Add scripts or references only when they materially improve repeatability.
- Do not include local workspace paths, secrets, logs, or temporary state.
- Prefer conservative, reversible workflows for git and release skills.

## License

No license has been selected yet. Add one before encouraging external reuse.
