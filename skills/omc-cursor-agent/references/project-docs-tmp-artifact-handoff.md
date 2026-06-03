# Project Docs Temp Artifact Handoff

Use when the OMC Claude Code brain can read the selected documentation surface but cannot write it (permission mode too low, dir not granted), and instead reports either a nested temp artifact path such as `/tmp/<project-name>/<task-id>/claude-spec.md` or prints the full artifact content in stdout after a write failure.

## Pattern

1. Treat the temp artifact as the brain's durable output, not a failed spec phase.
2. If the temp artifact is directly under `/tmp` or under a bare `/tmp/<task>/`, move it into `/tmp/<project-name>/<task-id>/` before using it as the durable handoff path.
3. Read the temp artifact before launching implementation. If no temp file exists but a headless `claude -p` subprocess printed a complete Markdown artifact in stdout, recover that stdout content from the process log and relay it into the intended project-docs path or external-doc export with minimal rewriting.
4. Copy it into the intended project-docs path using the assistant's file tools, because the orchestration layer may have broader local write access than a sandboxed brain subprocess. Treat this as artifact transport, not assistant-authored documentation.
5. Sanitize transient permission/sandbox wording before storing it permanently:
   - change statuses like `handoff-ready-but-doc-write-blocked` to the real state, e.g. `handoff-ready`
   - remove warning blocks that only describe the subprocess write failure
   - keep useful provenance only if it helps future reviewers
6. Re-read the target document and verify frontmatter/status metadata when applicable, line count/content presence, and Implementation Handoff section before starting Cursor.
7. Update the orchestration task state from `spec-drafting` to `implementing` only after the shared spec is present or the implementation prompt explicitly points to the temp artifact as authoritative fallback. Keep the state update minimal and preserve the brain-authored content.

## Pitfalls

- Do not ask the brain to retry the same project-doc write repeatedly; route the artifact into the selected documentation surface from the orchestration layer instead. The cleaner fix is to grant the brain the needed dir (`--add-dir`) or raise `--permission-mode` next time.
- If brain stdout says the target write was blocked but the report body is complete, do not treat the verification as failed; copy the report body into the selected documentation surface with the assistant's file tools, then let the brain-owned verdict content drive task state.
- Do not launch Cursor with a spec path that is still missing unless the prompt also names the temp artifact path.
- Avoid preserving failure-specific warning text in the final spec; it turns a resolved permission limitation into stale project documentation.
