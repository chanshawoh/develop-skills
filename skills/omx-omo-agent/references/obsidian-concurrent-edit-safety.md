# Obsidian Concurrent Edit Safety

Use when editing Obsidian task/spec/report notes that may be touched by another agent or sibling worktree.

## Safe sequence

1. Read latest file content immediately before patching.
2. If the last read was paginated/partial, re-read enough current content to cover every field you will edit before writing.
3. If a tool warns that the file was modified by a sibling subagent or another writer, stop unless the user has just explicitly authorized that exact local edit.
4. Re-read current content, reconcile intended hunk, then patch from latest state.
5. After write, verify frontmatter/status lines and any linked status markers still match intent.

## Local Obsidian status closeout

When the user says local Obsidian state is authoritative and external trackers do not matter, do not block on Linear/API sync. For a Linear-synced Obsidian task note, update all visible local status surfaces consistently:

- frontmatter `status` and `status_type`
- metadata table status row
- bottom status checkbox/label
- orchestration task status under `AI编排/Tasks/` when present
- kanban board membership under `视图/` when the task belongs to a visible board

Keep completed tasks visible in task kanban lists. Do not remove items from the `Done` column just because they are complete; preserve existing Done entries and only move/add/remove a card when the requested state change requires it. If another task is blocked, leave it outside Done and record the blocker in the orchestration task/report instead of disturbing completed cards.

Phrase the result as a local Obsidian status update, not an external Linear update.

## Why

Avoids overwriting concurrent orchestration edits, especially status flips in durable task notes, while respecting the user's local-first task tracking preference.
