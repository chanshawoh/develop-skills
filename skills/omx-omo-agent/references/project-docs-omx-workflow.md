# Project Docs + OMX Spec Workflow

Use this reference when the user wants Codex/OMX and OpenCode/OMO orchestration to pass work through project documentation rather than chat context.

## Storage Resolution

1. Prefer the user's requested documentation surface, such as Notion, Obsidian, local markdown, repo docs, or another project system.
2. If the user did not specify a surface, prefer existing project habits and paths already present in the task, repo, or prior reports.
3. If no shared surface is available, use OMX's project-local default directories, usually under `.omx/`, or `/tmp/<project-name>/<task-id>/` for temporary handoff artifacts.
4. Do not invent a second repo-local layout that conflicts with OMX conventions.
5. Do not write documentation artifacts directly under `/tmp` or a bare `/tmp/<task>/`; temporary docs need at least a project directory and task directory.
6. Always pass explicit spec/report paths or document links to implementation agents; never assume another worktree can see a spec written inside OMX's worktree.

## Shared Writing Contract

Project docs are shared writable project memory. Any role may write to the selected surface when needed, but default authorship is role-biased:

- The assistant records user intent, constraints, artifact paths, launch choices, and lightweight state transitions. Preserve the user's wording where possible; do not over-polish, reinterpret, or become the main document author.
- OMX/Codex writes the implementation-facing documents after receiving the assistant's instruction: specs, implementation handoffs, verification reports, review verdicts, and final closeout notes.
- OMO/OpenCode/Cursor writes implementation evidence only: implementation reports, changed-file summaries, command/test output, deviations, risks, and blockers.
- Final project-doc reconciliation belongs to OMX/Codex: make reports and task status readable for humans, link downstream evidence, and remove contradictions without rewriting the user's requirement beyond necessary clarification.

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
    OMX Spec Template.md
    Implementation Report Template.md
    OMX Verification Template.md
```

## Workflow State Machine

```text
inbox -> spec-drafting -> spec-review -> ready-for-implementation
-> implementing -> implementation-reported -> hermes-verifying
-> omx-verifying -> needs-fix | done | blocked
```

## Task Naming

```text
<PROJECT>-YYYYMMDD-001.md
<PROJECT>-YYYYMMDD-001-omx-spec.md
<PROJECT>-YYYYMMDD-001-implementation.md
<PROJECT>-YYYYMMDD-001-omx-verification.md
```

## Required OMX Spec Sections

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
- tool: omo | opencode | codex | omx-team | hermes
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

- Hermes/assistant: orchestration, path resolution, worktree management, instruction relay, lightweight state updates, and final user feedback.
- OMX/Codex: spec owner, implementation handoff author, tool recommendation, final verification against spec, and final project-doc reconciliation.
- OMO/OpenCode/Cursor: default implementation worker and implementation-evidence author.
- Codex implementation worker: surgical patch, review, or implementation when OMX recommends it; follow the same implementation-evidence boundary as other downstream workers.

## Pitfall

Two worktrees isolate code writes but also isolate local files. If OMX writes a spec in one worktree and OMO works in another, OMO will not see it unless Hermes stores it in the selected shared documentation surface or explicitly copies/passes it.
