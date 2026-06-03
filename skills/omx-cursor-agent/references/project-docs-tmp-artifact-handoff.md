# Project Docs Temp Artifact Handoff

Use when OMX/Codex can read the selected documentation surface but cannot write it from its sandbox, and instead reports either a nested temp artifact path such as `/tmp/<project-name>/<task-id>/omx-spec.md` or prints the full artifact content in stdout after an `operation not permitted` write failure.

## Pattern

1. Treat the temp artifact as OMX's durable output, not a failed spec phase.
2. If the temp artifact is directly under `/tmp` or under a bare `/tmp/<task>/`, move it into `/tmp/<project-name>/<task-id>/` before using it as the durable handoff path.
3. Read the temp artifact before launching implementation. If no temp file exists but the subprocess printed a complete Markdown artifact in stdout, recover that stdout content from `process log` and relay it into the intended project-docs path or external-doc export from Hermes/assistant with minimal rewriting.
4. Copy it into the intended project-docs path from Hermes/assistant using a file tool or a short `execute_code`/Python copy, because Hermes may have broader local write access than the OMX subprocess. Treat this as artifact transport, not assistant-authored documentation.
5. Sanitize transient sandbox wording before storing it permanently:
   - change statuses like `handoff-ready-but-doc-write-blocked` to the real state, e.g. `handoff-ready`
   - remove warning blocks that only describe the subprocess write failure
   - keep useful provenance only if it helps future reviewers
6. Re-read the target document and verify frontmatter/status metadata when applicable, line count/content presence, and Implementation Handoff section before starting OMO/OpenCode.
7. Update the orchestration task state from `spec-drafting` to `implementing` only after the shared spec is present or the implementation prompt explicitly points to the temp artifact as authoritative fallback. Keep the state update minimal and preserve the OMX/Codex-authored content.

## Pitfalls

- Do not ask OMX to retry the same project-doc write repeatedly; route the artifact into the selected documentation surface from Hermes/assistant instead.
- If OMX stdout says the target write was blocked but the report body is complete, do not treat the verification as failed; copy the report body into the selected documentation surface with Hermes/assistant file tools, then let OMX/Codex-owned verdict content drive task state.
- Do not launch OMO with a spec path that is still missing unless the prompt also names the temp artifact path.
- Avoid preserving failure-specific warning text in the final spec; it turns a resolved sandbox limitation into stale project documentation.
