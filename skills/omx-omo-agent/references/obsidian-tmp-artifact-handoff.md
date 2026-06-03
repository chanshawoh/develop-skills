# Obsidian Temp Artifact Handoff

Use when OMX/Codex can read Obsidian/iCloud vault files but cannot write them from its sandbox, and instead reports either a temp artifact path such as `/tmp/<task>-omx-spec.md` or prints the full artifact content in stdout after an `operation not permitted` write failure.

## Pattern

1. Treat the temp artifact as OMX's durable output, not a failed spec phase.
2. Read the temp artifact before launching implementation. If no temp file exists but the subprocess printed a complete Markdown artifact in stdout, recover that stdout content from `process log` and write it into the intended Obsidian path from Hermes.
3. Copy it into the intended Obsidian path from Hermes using a file tool or a short `execute_code`/Python copy, because Hermes may have broader local write access than the OMX subprocess.
4. Sanitize transient sandbox wording before storing it permanently:
   - change statuses like `handoff-ready-but-obsidian-write-blocked` to the real state, e.g. `handoff-ready`
   - remove warning blocks that only describe the subprocess write failure
   - keep useful provenance only if it helps future reviewers
5. Re-read the Obsidian target and verify frontmatter status, line count/content presence, and Implementation Handoff section before starting OMO/OpenCode.
6. Update the orchestration task state from `spec-drafting` to `implementing` only after the Obsidian spec is present or the implementation prompt explicitly points to the temp artifact as authoritative fallback.

## Pitfalls

- Do not ask OMX to retry the same Obsidian write repeatedly; route the artifact into Obsidian from Hermes instead.
- If OMX stdout says the target write was blocked but the report body is complete, do not treat the verification as failed; copy the report body into Obsidian with Hermes file tools, then update task state from that verdict.
- Do not launch OMO with a spec path that is still missing unless the prompt also names the temp artifact path.
- Avoid preserving failure-specific warning text in the final spec; it turns a resolved sandbox limitation into stale project documentation.
