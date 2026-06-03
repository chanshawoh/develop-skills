# Project Docs + OMC Spec Workflow

Use this reference when the user wants OMC Claude Code (planning/verification brain) and Cursor (implementation worker) orchestration to pass work through project documentation rather than chat context.

## Storage Resolution

1. Prefer the user's requested documentation surface, such as Notion, Obsidian, local markdown, repo docs, or another project system.
2. If the user did not specify a surface, prefer existing project habits and paths already present in the task, repo, or prior reports.
3. If no shared surface is available, use OMC's project-local default directories, usually under `.omc/`, or `/tmp/<project-name>/<task-id>/` for temporary handoff artifacts.
4. Do not invent a second repo-local layout that conflicts with OMC conventions.
5. Do not write documentation artifacts directly under `/tmp` or a bare `/tmp/<task>/`; temporary docs need at least a project directory and task directory.
6. Always pass explicit spec/report paths or document links to implementation agents; never assume another worktree can see a spec written inside another worktree.

## Shared Writing Contract

Project docs are shared writable project memory. Any role may write to the selected surface when needed, but default authorship is role-biased:

- The orchestration layer records user intent, constraints, artifact paths, launch choices, and lightweight state transitions. Preserve the user's wording where possible; do not over-polish, reinterpret, or become the main document author.
- OMC Claude Code writes the implementation-facing documents after receiving the orchestration instruction: specs, implementation handoffs, verification reports, review verdicts, and final closeout notes. Author through `planner`/`architect` + `executor`/`writer`; evaluate through `verifier`/`code-reviewer` in a separate lane.
- Cursor writes implementation evidence only: implementation reports, changed-file summaries, command/test output, deviations, risks, and blockers.
- Final project-doc reconciliation belongs to OMC Claude Code: make reports and task status readable for humans, link downstream evidence, and remove contradictions without rewriting the user's requirement beyond necessary clarification.

## Recommended Local Markdown Layout

```text
Projects/<project>/
  _index.md
  Agents.md
  Decisions.md
  Workflow.md
  Inbox/
  Tasks/
  Specs/
  Plans/
  Reports/
  Logs/
  Templates/
    Task Template.md
    OMC Spec Template.md
    Implementation Report Template.md
    OMC Verification Template.md
```

## Workflow State Machine

```text
inbox -> spec-drafting -> spec-review -> ready-for-implementation
-> implementing -> implementation-reported -> orchestrator-verifying
-> omc-verifying -> needs-fix | done | blocked
```

## Task Naming

```text
<PROJECT>-YYYYMMDD-001.md
<PROJECT>-YYYYMMDD-001-omc-spec.md
<PROJECT>-YYYYMMDD-001-implementation.md
<PROJECT>-YYYYMMDD-001-omc-verification.md
```

## Required OMC Spec Sections

- Goal
- Non Goals
- Context
- Requirements
- Acceptance Criteria
- Likely Files / Modules
- Test Strategy
- Risks
- Open Questions
- Implementation Handoff

## Implementation Handoff Contract

```markdown
## Implementation Handoff

### Recommended Tool
- tool: cursor | omc-native | claude-headless
- reason: <why>

### Implementation Mode
- worktree: yes/no
- branch: agent/<task-id>
- edit scope: <files/modules>
- avoid: <files/modules>

### Prompt To Implementation Agent
<complete prompt>

### Required Feedback
- files changed
- tests run
- deviations from spec
- blockers
```

## Agent Responsibilities

- Orchestration layer (this assistant as router): orchestration, path resolution, worktree management, instruction relay, lightweight state updates, and final user feedback.
- OMC Claude Code: spec owner, implementation handoff author, tool recommendation, final verification against spec (separate lane), and final project-doc reconciliation.
- Cursor: default implementation worker and implementation-evidence author.

## Pitfall

Two worktrees isolate code writes but also isolate local files. If the brain writes a spec in one worktree and Cursor works in another, Cursor will not see it unless the orchestration layer stores it in the selected shared documentation surface or explicitly copies/passes it.
