---
name: obsidian-agile-project
description: Use when a development task involves maintaining documentation, PRDs, tasks, delivery progress, sprint notes, or project management records in an Obsidian vault. Create an agile project-management folder structure inspired by Aliyun Yunxiao-style project organization, with PRD notes under 需求/, task notes under 任务/, progress views, Obsidian properties, wikilinks, and suitable Obsidian plugins such as Bases, Tasks, Dataview, or Projects when available.
---

# Obsidian Agile Project

Use this skill when you detect that the user or repository uses Obsidian to maintain development documents, requirements, tasks, milestones, or progress tracking.

The goal is to make the vault behave like a lightweight agile project-management space: requirements are explicit, tasks are traceable to PRDs, progress is visible, and Obsidian-native features are used without forcing unnecessary plugins.

## Pair With Obsidian Skills

- Use `obsidian-cli` when reading or writing a live Obsidian vault from the command line.
- Use `obsidian-markdown` when creating `.md` notes with properties, wikilinks, callouts, embeds, or tags.
- Use `obsidian-bases` when creating `.base` views for requirement/task dashboards.

If those skills are unavailable, still follow this structure using normal filesystem edits and valid Obsidian Markdown.

## Detection

Treat the task as an Obsidian agile-project task when any of these are true:

- The user mentions Obsidian, vaults, notes, Bases, Dataview, Tasks, Projects, wikilinks, or task progress in Obsidian.
- The repository contains `.obsidian/`, `.base` files, Obsidian-style wikilinks, or project notes with YAML properties.
- The user asks to create PRDs, tasks, sprint plans, delivery status, backlog, or development documentation and points at an Obsidian vault.

Before editing, identify the vault root. If it is unclear, infer it from `.obsidian/` or the path the user supplied. Ask only if multiple plausible vault roots would change where files are written.

## Minimum Structure

Create at least these directories:

```text
需求/
  PRD标题1.md
任务/
  任务标题1.md
```

For a complete agile workspace, prefer this structure:

```text
项目总览.md
需求/
  PRD标题1.md
任务/
  任务标题1.md
迭代/
  Sprint-YYYY-WW.md
里程碑/
  里程碑标题.md
会议/
  YYYY-MM-DD-会议标题.md
决策/
  ADR-0001-决策标题.md
发布/
  Release-版本号.md
视图/
  需求看板.base
  任务看板.base
模板/
  PRD模板.md
  任务模板.md
```

Keep folder names Chinese when the vault is Chinese-first. If the existing vault uses English taxonomy, preserve the local convention but keep the same conceptual buckets.

## Note Contracts

### PRD Notes

Create PRD notes under `需求/`. Use this property shape unless the vault already has a stronger convention:

```markdown
---
type: prd
status: draft
priority: P2
owner:
iteration:
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
iteration:
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

## Plugin And Feature Selection

Prefer built-in Obsidian features first:

1. Use folders, properties, tags, wikilinks, and backlinks for the base system.
2. Use Obsidian Bases when available for dashboards under `视图/`.
3. Use community plugins only when they are already installed or the user asked for plugin setup.

When plugins are available, use them this way:

- Tasks: keep actionable checkboxes in task notes; include due dates, priorities, and status syntax only if the vault already uses that plugin style.
- Dataview: create Markdown dashboard queries only if Dataview is installed and Bases is unavailable or the vault already uses Dataview.
- Projects: use it only if the vault already uses Projects for kanban/table views; do not invent plugin-specific config without checking local conventions.
- Templater: place reusable templates under `模板/` only if the vault already uses Templater syntax or the user asks for it.

To inspect plugins, check `.obsidian/community-plugins.json`, `.obsidian/plugins/`, and existing dashboard notes. Do not require users to install plugins. If recommending a plugin, explain the reason and keep the generated vault useful without it.

## Dashboard Guidance

Create `项目总览.md` as the entry point. It should link to core folders and current views, for example:

```markdown
# 项目总览

## 快速入口

- [[需求/PRD标题1|需求]]
- [[任务/任务标题1|任务]]
- [[视图/需求看板.base|需求看板]]
- [[视图/任务看板.base|任务看板]]

## 当前重点

## 风险与阻塞
```

If using Bases, create separate `.base` files for PRDs and tasks with filters on `type`. Keep formulas simple and validate YAML before claiming completion.

If using Dataview, keep queries readable and scoped to the project folders.

## Working Rules

- Preserve existing vault naming, property keys, and status vocabulary when present.
- Prefer one note per PRD and one note per task so links and dashboards remain stable.
- Use wikilinks for internal references, not raw Markdown links.
- Do not overwrite existing notes unless the user asked for replacement; merge or append conservatively.
- Create templates only when they will be reused.
- After writing files, verify paths exist and Markdown/YAML syntax is valid enough for Obsidian to parse.
