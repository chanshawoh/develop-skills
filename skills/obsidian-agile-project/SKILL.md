---
name: obsidian-agile-project
description: Use when a development task involves maintaining requirements, tasks, project progress, or lightweight agile project-management records in an Obsidian vault. Create the minimum Obsidian-native project structure with 需求/, 任务/, and 视图/, plus PRD/task note templates, Obsidian properties, wikilinks, and Bases or other Obsidian plugins only when suitable and already available.
---

# Obsidian Agile Project

Use this skill when you detect that the user or repository uses Obsidian to maintain development documents, requirements, tasks, milestones, or progress tracking.

The goal is a minimal Obsidian-native project-management space: requirements are explicit, tasks are traceable to requirements, progress is visible through views, and the vault remains useful with Obsidian files alone.

Do not introduce non-Obsidian project-management systems into the structure. Keep generated folders, properties, links, and terminology Obsidian-native unless the user explicitly asks to migrate or import an existing external source.

## Pair With Obsidian Skills

- Use `obsidian-cli` when reading or writing a live Obsidian vault from the command line.
- Use `obsidian-markdown` when creating `.md` notes with properties, wikilinks, callouts, embeds, or tags.
- Use `obsidian-bases` when creating `.base` views for requirement/task dashboards.

If those skills are unavailable, still follow this structure using normal filesystem edits and valid Obsidian Markdown.

## Detection

Treat the task as an Obsidian agile-project task when any of these are true:

- The user mentions Obsidian, vaults, notes, Bases, Dataview, Tasks, Kanban, Projects, wikilinks, or task progress in Obsidian.
- The repository contains `.obsidian/`, `.base` files, Obsidian-style wikilinks, or project notes with YAML properties.
- The user asks to create PRDs, tasks, sprint plans, delivery status, backlog, or development documentation and points at an Obsidian vault.

Before editing, identify the vault root. If it is unclear, infer it from `.obsidian/` or the path the user supplied. Ask only if multiple plausible vault roots would change where files are written.

## Minimum Structure

Every project must have at least these three directories:

```text
需求/
  PRD标题1.md
任务/
  任务标题1.md
视图/
  任务看板.md
```

Use a small structure by default:

```text
项目总览.md
需求/
  PRD标题1.md
任务/
  任务标题1.md
视图/
  需求看板.base
  任务看板.base
  任务看板.md
模板/
  PRD模板.md
  任务模板.md
```

Only add optional folders such as `迭代/`, `里程碑/`, `会议/`, `决策/`, or `发布/` when the user asks for a richer process or the existing vault already uses them.

Keep folder names Chinese when the vault is Chinese-first. If an existing project uses `需求文档/`, preserve it; for new projects prefer the shorter `需求/`.

## Note Contracts

### PRD Notes

Create requirement notes under `需求/`. Use this property shape unless the vault already has a stronger convention:

```markdown
---
type: prd
status: draft
priority: P2
owner:
phase:
milestone:
created:
updated:
tags:
  - project/prd
---

# PRD标题1

## 背景

## 目标

## 范围

## 用户故事

## 验收标准

## 关联任务
```

Status values should normally be `draft`, `reviewing`, `approved`, `in_progress`, `done`, or `cancelled`.

### Task Notes

Create task notes under `任务/`. Link every implementation task to a PRD when one exists.

```markdown
---
type: task
status: todo
priority: P2
owner:
prd: "[[PRD标题1]]"
phase:
milestone:
estimate:
created:
updated:
tags:
  - project/task
---

# 任务标题1

## 目标

## 实施清单

- [ ] 

## 验收标准

## 关联

- 需求: [[PRD标题1]]
```

Status values should normally be `todo`, `doing`, `blocked`, `review`, `done`, or `cancelled`.

Avoid external-tool metadata in new Obsidian-native task notes. Do not add source IDs, external sync fields, external URLs, or imported file paths unless the user specifically requests an import or migration.

## Plugin And Feature Selection

Prefer built-in Obsidian features first:

1. Use folders, properties, tags, wikilinks, and backlinks for the base system.
2. Choose the best compatible view format from the plugins already installed in the vault.
3. Recommend a plugin only when it materially improves the workflow; do not make the project unusable without it.

When plugins are available, use them this way:

- Kanban: preferred for task-flow boards when installed; create `视图/任务看板.md` using the vault's existing Kanban style.
- Bases: preferred for property-driven tables/cards when available; create `.base` files under `视图/`.
- Tasks: keep actionable checkboxes in task notes; include due dates, priorities, and status syntax only if the vault already uses that plugin style.
- Dataview: create Markdown dashboard queries only if Dataview is installed and Bases is unavailable or the vault already uses Dataview.
- Projects: use it only if the vault already uses Projects for table or board views; do not invent plugin-specific config without checking local conventions.
- Templater: place reusable templates under `模板/` only if the vault already uses Templater syntax or the user asks for it.

To inspect plugins, check `.obsidian/community-plugins.json`, `.obsidian/plugins/`, and existing dashboard notes. If Kanban is missing and the user wants drag-and-drop task flow, recommend installing the Kanban plugin. If no suitable plugin is installed, automatically fall back to plain Obsidian Markdown under `视图/任务看板.md` with checkbox lists grouped by status.

## Dashboard Guidance

Create `项目总览.md` as the entry point. It should link to the three required areas and current views, for example:

```markdown
# 项目总览

## 快速入口

- [[需求]]
- [[任务]]
- [[视图]]
- [[视图/任务看板.base|任务看板]]
- [[视图/任务看板|任务看板]]

## 当前重点

## 风险与阻塞
```

Choose the view format in this order:

1. Existing local convention in `视图/`.
2. Kanban board when the Kanban plugin is installed and task status flow matters.
3. Bases when property tables/cards are available and useful.
4. Dataview when the vault already relies on Dataview.
5. Plain Markdown checklist board when no plugin is available.

If using Bases, create `.base` files for PRDs and tasks with filters on folders and `type`. Keep formulas simple and validate YAML before claiming completion.

Example `视图/任务看板.base`:

```yaml
filters:
  and:
    - file.inFolder("任务")
    - type == "task"
properties:
  phase:
    displayName: 阶段
  status:
    displayName: 状态
  priority:
    displayName: 优先级
  milestone:
    displayName: 里程碑
  owner:
    displayName: 负责人
  updated:
    displayName: 更新时间
views:
  - type: table
    name: 全部任务
    order:
      - file.name
      - phase
      - status
      - priority
      - milestone
      - owner
      - updated
  - type: cards
    name: 未完成
    filters:
      and:
        - status != "done"
        - status != "cancelled"
    order:
      - file.name
      - phase
      - priority
      - status
      - milestone
  - type: table
    name: 已完成
    filters:
      and:
        - status == "done"
    order:
      - file.name
      - phase
      - status
      - updated
```

If using Dataview, keep queries readable and scoped to the project folders.

If using plain Markdown fallback, create `视图/任务看板.md`:

```markdown
# 任务看板

## Todo

- [ ] [[任务标题1]]

## Doing

## Blocked

## Review

## Done
```

## Working Rules

- Preserve existing vault naming, property keys, and status vocabulary when present.
- Prefer one note per PRD and one note per task so links and dashboards remain stable.
- Use wikilinks for internal references, not raw Markdown links.
- Do not overwrite existing notes unless the user asked for replacement; merge or append conservatively.
- Create templates only when they will be reused.
- After writing files, verify paths exist and Markdown/YAML syntax is valid enough for Obsidian to parse.
