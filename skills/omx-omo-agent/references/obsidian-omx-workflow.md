# Obsidian + OMX Spec Workflow

Use this reference when the user wants Codex/OMX and OpenCode/OMO orchestration to pass work through local documents rather than chat context.

## Storage Resolution

1. Prefer Obsidian when a vault/project path is available.
2. If Obsidian is unavailable, use OMX's project-local default directories, usually under `.omx/`.
3. Do not invent a second repo-local layout that conflicts with OMX conventions.
4. Always pass explicit spec/report paths to implementation agents; never assume another worktree can see a spec written inside OMX's worktree.

## Recommended Obsidian Project Layout

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

- Hermes: orchestration, path resolution, worktree management, local verification, final user feedback.
- OMX: spec owner, tool recommendation, final verification against spec.
- OMO/OpenCode: default implementation worker.
- Codex: surgical patch, review, or implementation when OMX recommends it.

## Pitfall

Two worktrees isolate code writes but also isolate local files. If OMX writes a spec in one worktree and OMO works in another, OMO will not see it unless Hermes stores it in Obsidian/shared storage or explicitly copies/passes it.