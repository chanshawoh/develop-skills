# Development Skills Library

Portable, reusable Agent Skills for practical AI-assisted development workflows.

Each skill is self-contained and can be installed independently into Codex,
Cursor, Claude Code, OpenCode, or another compatible agent without bringing
along unrelated project state.

## Highlights

- **Portable by design** — install only the skills you need.
- **Workflow-oriented** — covers implementation, orchestration, databases, Git,
  local runtimes, project management, and diagramming.
- **Multi-agent compatible** — supports Codex, Cursor, Claude Code, OpenCode,
  OMO, OMX, and compatible skill systems.
- **Safety-conscious** — favors explicit confirmation, conservative defaults,
  reversible operations, and verification.

## Skills

| Skill | Purpose |
| --- | --- |
| [`cursor-agent`](skills/cursor-agent/) | Delegate implementation, refactoring, debugging, testing, reviews, and fix loops to Cursor CLI Agent in headless mode. |
| [`database-mcp-guard`](skills/database-mcp-guard/) | Prefer project-matched database MCP tools and require confirmation before destructive database operations. |
| [`macos-local-runtime`](skills/macos-local-runtime/) | Run and troubleshoot Java, Node.js, Python, and build tools on macOS with minimal environment changes. |
| [`merge-branch-release`](skills/merge-branch-release/) | Safely merge, push, and release branches while preserving the original working context. |
| [`next-ai-drawio`](skills/next-ai-drawio/) | Configure and use Next AI Draw.io MCP for creating, previewing, editing, and exporting diagrams. |
| [`obsidian-agile-project`](skills/obsidian-agile-project/) | Manage requirements, tasks, modules, releases, progress, and dashboards inside an Obsidian vault. |
| [`omc-cursor-agent`](skills/omc-cursor-agent/) | Use OMC/Claude Code for planning and verification while Cursor CLI Agent handles implementation. |
| [`omx-cursor-agent`](skills/omx-cursor-agent/) | Use OMX/Codex for planning and verification while Cursor CLI Agent handles implementation. |
| [`omx-omo-agent`](skills/omx-omo-agent/) | Orchestrate planning, implementation handoff, verification, documentation, and fix loops across OMX and OMO. |
| [`opencode-omo-agent`](skills/opencode-omo-agent/) | Delegate planning, implementation, debugging, testing, reviews, and fix loops to OMO/OpenCode agents. |

## Repository Layout

```text
skills/
  <skill-name>/
    SKILL.md
    agents/       # Optional agent metadata
    references/   # Optional supporting documentation
    scripts/      # Optional reusable scripts
```

Every skill directory is designed to remain portable on its own. Generated
runtime state, local logs, project-specific paths, and credentials should not
be committed to a skill.

## Install a Skill

### Codex

```bash
mkdir -p "$HOME/.codex/skills"
cp -R skills/<skill-name> "$HOME/.codex/skills/"
```

### Cursor

```bash
mkdir -p .cursor/skills
cp -R skills/<skill-name> .cursor/skills/
```

For other compatible agents, copy the selected skill directory into the
agent's skills directory.

## Skill Standards

- Keep `SKILL.md` concise and focused on actionable agent instructions.
- Use clear YAML frontmatter with `name` and `description`.
- Add scripts or references only when they materially improve repeatability.
- Do not include local workspace paths, secrets, logs, or temporary state.
- Prefer conservative, reversible workflows and verify important outcomes.

## License

No license has been selected yet. Add one before redistributing or encouraging
external reuse.

---

# 开发技能库

面向真实 AI 辅助开发流程的可移植、可复用 Agent Skills 技能库。

每个技能均保持独立，可按需安装到 Codex、Cursor、Claude Code、OpenCode
或其他兼容的智能体中，无需引入无关的项目状态。

## 核心特点

- **独立可移植** — 只安装需要的技能，不必引入整个仓库。
- **面向开发流程** — 覆盖编码实现、智能体编排、数据库、Git、本地运行环境、项目管理与绘图。
- **兼容多种智能体** — 支持 Codex、Cursor、Claude Code、OpenCode、OMO、OMX 及兼容的技能系统。
- **重视操作安全** — 强调明确确认、保守默认值、可逆操作和结果验证。

## 技能列表

| 技能 | 用途 |
| --- | --- |
| [`cursor-agent`](skills/cursor-agent/) | 将编码实现、重构、调试、测试、审查及修复循环委派给无头模式的 Cursor CLI Agent。 |
| [`database-mcp-guard`](skills/database-mcp-guard/) | 数据库操作前优先选择与项目匹配的 MCP 工具，并在执行破坏性操作前要求明确确认。 |
| [`macos-local-runtime`](skills/macos-local-runtime/) | 以尽量少的环境改动在 macOS 上运行和排查 Java、Node.js、Python 及构建工具。 |
| [`merge-branch-release`](skills/merge-branch-release/) | 安全完成分支合并、推送与发布，并保留原有工作上下文。 |
| [`next-ai-drawio`](skills/next-ai-drawio/) | 配置并使用 Next AI Draw.io MCP 创建、预览、编辑和导出各类图表。 |
| [`obsidian-agile-project`](skills/obsidian-agile-project/) | 在 Obsidian 仓库中管理需求、任务、模块、版本、项目进度和仪表盘。 |
| [`omc-cursor-agent`](skills/omc-cursor-agent/) | 由 OMC/Claude Code 负责规划与验证，Cursor CLI Agent 负责具体实现。 |
| [`omx-cursor-agent`](skills/omx-cursor-agent/) | 由 OMX/Codex 负责规划与验证，Cursor CLI Agent 负责具体实现。 |
| [`omx-omo-agent`](skills/omx-omo-agent/) | 在 OMX 与 OMO 之间编排规划、实现交接、验证、项目文档和持续修复流程。 |
| [`opencode-omo-agent`](skills/opencode-omo-agent/) | 将规划、实现、调试、测试、审查及修复循环委派给 OMO/OpenCode 智能体。 |

## 仓库结构

```text
skills/
  <skill-name>/
    SKILL.md
    agents/       # 可选：智能体元数据
    references/   # 可选：参考文档
    scripts/      # 可选：可复用脚本
```

每个技能目录都应能够独立使用。请勿在技能中提交运行时生成状态、本地日志、
项目专属路径或访问凭据。

## 安装技能

### Codex

```bash
mkdir -p "$HOME/.codex/skills"
cp -R skills/<skill-name> "$HOME/.codex/skills/"
```

### Cursor

```bash
mkdir -p .cursor/skills
cp -R skills/<skill-name> .cursor/skills/
```

其他兼容智能体可将所需技能目录复制到对应的 skills 目录中。

## 技能规范

- 保持 `SKILL.md` 简洁，聚焦可执行的智能体指令。
- 使用清晰的 YAML Frontmatter，并包含 `name` 和 `description`。
- 仅在确实能提升流程可重复性时添加脚本或参考资料。
- 不要包含本地工作区路径、密钥、日志或临时状态。
- 优先采用保守、可逆的工作流，并验证重要操作结果。

## 许可证

当前尚未选择开源许可证。在重新分发或鼓励外部复用前，请先添加许可证。
