---
name: obsidian-agile-project
description: Use when a development task involves maintaining requirements, tasks, interfaces/modules, releases, project progress, or lightweight agile project-management records in an Obsidian vault.
---

# Obsidian Agile Project

Use this skill when you detect that the user or repository uses Obsidian to maintain development documents, requirements, tasks, milestones, or progress tracking.

The goal is a minimal Obsidian-native project-management space: requirements are explicit, tasks are traceable to requirements, progress is visible through views, and the vault remains useful with Obsidian files alone.

Do not introduce non-Obsidian project-management systems into the structure. Keep generated folders, properties, links, and terminology Obsidian-native unless the user explicitly asks to migrate or import an existing external source.

Default assumption: Obsidian has no community plugins. Any generated project must remain readable and maintainable with plain Markdown files, YAML properties, checkbox lists, tags, backlinks, and wikilinks alone. Use plugins only after detecting that they are already installed or the user explicitly asks for them.

## Project Documentation Conventions

For development projects, first inspect the existing vault and project notes to learn local conventions. Some projects may have a `项目说明.md` README / AGENT-style note for document structure and collaboration rules, but this file is optional and must not be required for new projects.

If `项目说明.md` exists, use it as a local convention source only. It should normally define where information belongs; it should not carry concrete requirements, task details, API fields, implementation notes, or release logs. Do not edit it unless the user explicitly asks to modify that file. If the user says "整理到项目说明" or similar, interpret it as "follow the local project-document structure and write to the matching child documents" unless they clearly request changes to `项目说明.md` itself.

Before writing, classify the update:

- Current project state, focus, risks, and entry links: `项目总览.md`
- Product requirements, PRDs, business rules, scope, non-goals, and acceptance criteria: `需求/`
- Task boards, execution state, implementation checklists, and verification evidence: `任务/`
- HTTP APIs, pages, modules, data flow, local paths, run commands, configuration, release notes, and validation checklists: `接口/`
- Sprint or phase planning: `迭代/`
- Milestone goals and acceptance scope: `里程碑/`
- Meeting notes: `会议/`
- Architecture/product decisions: `决策/`
- Release records: `发布/`
- Dashboards and plugin views: `视图/`
- Reusable formats: `模板/`

Do not pile all information into one document. Keep each note small enough to be linked, reviewed, and updated independently.

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

Before editing, identify the vault root and project root. If it is unclear, infer them from the `obsidian://open` link, `.obsidian/`, `项目总览.md`, an optional `项目说明.md`, or the path the user supplied. Ask only if multiple plausible vault roots would change where files are written.

## Minimum Structure

Every development project must have at least this Obsidian-native documentation structure:

```text
项目总览.md
需求/
  00-需求索引.md
  PRD标题1.md
任务/
  00-任务索引.md
  任务标题1.md
接口/
  00-接口索引.md
  模块名/
    00-模块说明.md
```

Use this richer structure when the project already has it or the user asks for full agile delivery records:

```text
项目总览.md
需求/
  00-说明.md
  00-需求索引.md
  PRD标题1.md
任务/
  00-说明.md
  00-任务索引.md
  任务标题1.md
接口/
  00-说明.md
  00-接口索引.md
  模块名/
    00-模块说明.md
视图/
  需求看板.base
  任务看板.base
  任务看板.md
迭代/
里程碑/
会议/
决策/
发布/
模板/
  PRD模板.md
  任务模板.md
  模块说明模板.md
```

Only add optional folders such as `迭代/`, `里程碑/`, `会议/`, `决策/`, `发布/`, `视图/`, or `模板/` when the user asks for a richer process or the existing vault already uses them.

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

## 非目标

## 用户故事

## 验收标准

## 实现同步

## 剩余风险

## 关联任务
```

Status values should normally be `draft`, `todo`, `doing`, `done`, `demo-ready`, `active`, or `cancelled` unless the vault already has a stronger convention. When a feature becomes implemented, add `实现同步｜YYYY-MM-DD` with completed scope, current product completeness, key fixes, verification evidence, and remaining risks.

### Task Notes

Create task notes under `任务/`. Link every implementation task to a PRD and interface/module note when they exist.

```markdown
---
type: task
status: todo
priority: P2
owner:
prd: "[[PRD标题1]]"
interface: "[[接口/模块名/00-模块说明]]"
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

## 实现同步

## 关联

- 需求: [[PRD标题1]]
- 接口: [[接口/模块名/00-模块说明]]
```

Status values should normally be `todo`, `doing`, `blocked`, `review`, `done`, `demo-ready`, or `cancelled`.

Avoid external-tool metadata in new Obsidian-native task notes. Do not add source IDs, external sync fields, external URLs, or imported file paths unless the user specifically requests an import or migration.

### Interface And Module Notes

Create interface, page, and module notes under `接口/`. If the first version has no formal HTTP API, still document the page/module, data flow, local files, run commands, demo path, validation checklist, and current boundaries.

```markdown
---
type: module
status: draft
priority: P2
prd: "[[PRD标题1]]"
task: "[[任务/任务标题1]]"
created:
updated:
tags:
  - project/module
---

# 模块名

## 当前能力

## 数据路径

## 页面 / 接口

## 文件与运行方式

## 配置与迁移

## 验证清单

## 发布说明

## 当前边界与风险

## 关联

- 需求: [[PRD标题1]]
- 任务: [[任务/任务标题1]]
```

Keep module notes honest: distinguish demo-ready from production-ready, preserve real TODOs, and do not imply production API guarantees for a demo module.

## Link And State Synchronization

Maintain a clickable chain for every feature:

```text
项目总览
  -> 需求索引
  -> 具体需求 PRD
  -> 任务索引 / 任务看板 / 具体任务
  -> 接口 / 模块说明
  -> 发布说明 when applicable
```

When implementation, acceptance, or status changes, update all affected documents in the chain:

- `项目总览.md`: current focus, done items, risks, and blocking links.
- `需求/00-需求索引.md`: feature entry status and links.
- Specific PRD: scope, acceptance criteria, implementation sync, and remaining risks.
- `任务/00-任务索引.md`: task status summary.
- Task board or task note: status, checklist, verification evidence, and links.
- `接口/00-接口索引.md`: module/API/page entry and path summary.
- Specific module/API note: data flow, run commands, config, migration, release notes, validation checklist, and boundaries.

Use `[x]` only for truly completed items. Keep unfinished work as explicit `[ ]` TODOs even when the main path is done.

## Plugin And Feature Selection

Prefer built-in Obsidian features first:

1. Use folders, Markdown headings, YAML properties, tags, wikilinks, backlinks, and checkbox lists for the base system.
2. Detect installed plugins before emitting plugin-specific syntax.
3. Choose the best compatible view format from the plugins already installed in the vault.
4. Recommend a plugin only when it materially improves the workflow; do not make the project unusable without it.

When plugins are available, use them this way:

- Kanban: preferred for task-flow boards when installed; create `视图/任务看板.md` using the vault's existing Kanban style.
- Bases: preferred for property-driven tables/cards when available; create `.base` files under `视图/`.
- Tasks: keep actionable checkboxes in task notes; include due dates, priorities, and status syntax only if the vault already uses that plugin style.
- Dataview: create Markdown dashboard queries only if Dataview is installed and Bases is unavailable or the vault already uses Dataview.
- Projects: use it only if the vault already uses Projects for table or board views; do not invent plugin-specific config without checking local conventions.
- Templater: place reusable templates under `模板/` only if the vault already uses Templater syntax or the user asks for it.

To inspect plugins, check `.obsidian/community-plugins.json`, `.obsidian/plugins/`, and existing dashboard notes. Treat missing `.obsidian/`, missing `community-plugins.json`, an empty plugin list, or disabled safe mode as "no usable plugins detected."

Fallback rules:

- No Kanban plugin: use plain Markdown status sections (`Todo`, `Doing`, `Blocked`, `Review`, `Done`) with checkbox wikilinks.
- No Bases plugin: use index tables in Markdown or a plain `视图/任务看板.md`.
- No Dataview plugin: do not emit dataview code blocks.
- No Tasks plugin: use ordinary `- [ ]` and `- [x]` checkboxes without plugin-only priority/due syntax.
- No Templater plugin: templates are ordinary Markdown files with placeholders, not Templater expressions.

Kanban placement follows local convention first. Some vaults keep global dashboards in `视图/`, while delivery projects may keep module boards under `任务/{模块名}/Tasks-{编号}-{需求名}.kanban.md`. If creating a Kanban board, inspect existing board format first and put requirement/interface links at the top of the board. If Kanban is missing and the user wants drag-and-drop task flow, recommend installing the Kanban plugin, but still create the usable Markdown fallback immediately.

## Dashboard Guidance

Create `项目总览.md` as the entry point. It should link to the required areas and current views, for example:

```markdown
# 项目总览

## 快速入口

- [[需求/00-需求索引|需求索引]]
- [[任务/00-任务索引|任务索引]]
- [[接口/00-接口索引|接口索引]]
- [[视图/任务看板|任务看板]]

## 当前重点

## 风险与阻塞
```

Choose the view format in this order:

1. Existing local convention in `视图/` or `任务/`.
2. Kanban board when the Kanban plugin is installed and task status flow matters.
3. Bases when the Bases plugin is available and property tables/cards are useful.
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
- Use Markdown links only for external URLs.
- Never write secrets, production credentials, real API keys, raw phone numbers, ID numbers, or sensitive student/user data into project notes.
- Be conservative with claims involving AI, student data, or outcome improvement: describe evidence and limits, do not promise guaranteed results.
- Do not overwrite existing notes unless the user asked for replacement; merge or append conservatively.
- Create templates only when they will be reused.
- After writing files, verify paths exist and Markdown/YAML syntax is valid enough for Obsidian to parse.
- Search changed feature keywords, `status: todo`, unchecked tasks, and sensitive terms after substantial updates; confirm states and links do not contradict each other.
