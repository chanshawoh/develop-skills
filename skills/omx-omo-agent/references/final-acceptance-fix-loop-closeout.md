# Final Acceptance Fix Loop Closeout

Use when OMX final verification fails after an OMO/OpenCode implementation, especially when the remaining issues are narrow semantic blockers rather than broad implementation gaps.

## Loop Shape

1. Treat OMX final verification as authoritative for release readiness, even if OMO reports success and tests pass.
2. Convert only the remaining FAIL/PARTIAL items into a surgical OMO `/ralph-loop` prompt.
3. Re-run compile and the exact targeted tests after each fix loop; do not rely only on OMO's reported output.
4. Ask OMX to rerun final acceptance after the fix, focused on the previous blockers.
5. If OMX finds another semantic blocker, repeat the narrow loop instead of widening scope.
6. When OMX returns PASS, have OMX/Codex reconcile reports and task status surfaces in the selected documentation surface for human reading.

## Semantic Blocker Handling

When the verifier flags a field-value semantic issue, route that exact meaning to OMO, not just the failing line. Include:

- current incorrect value and why it is semantically wrong,
- source-of-truth field/comment/DDL evidence,
- required corrected value,
- whether blank/null should fail fast or fallback,
- test assertion that should guard the semantic distinction.

Example pattern from WOO-23 class of issue:

```text
embeddingModelId is numeric ID; embeddingModel is model identifier string.
Do not write String.valueOf(embeddingModelId) into embeddingModel.
Use knowledgeDO.getEmbeddingModel(); blank should fail fast.
Update test to assert text-embedding-3-small, not "10".
```

## Sandbox Report Handoff

OMX/Codex workers may be unable to write shared documentation paths, cloud-synced folders, Notion/Obsidian exports, or other outside-repo surfaces from their sandbox and may write `/tmp/<project-name>/<task-id>/<report>.md` instead. Do not treat that as verifier failure.

1. Read the nested `/tmp/<project-name>/<task-id>/` report with file tools.
2. Copy its full content into the intended report path or external-doc export using Hermes/assistant file tools with minimal rewriting.
3. Re-read the target report path or exported document to verify the write.
4. Continue closeout from the report verdict.

## Documentation Done Closeout

When final verification is PASS and the user wants completed tasks visible, have OMX/Codex perform final closeout in the selected documentation surface:

1. Update orchestration task frontmatter (`status: done`, `completed: <date>`).
2. Update visible task state/current-state sections, not only frontmatter.
3. Update source/imported task note local status surfaces (`status`, `status_type`, metadata table, checklist/status lines).
4. Add links to final verification and fix reports if missing.
5. Preserve Done-column entries; do not remove completed cards from kanban source lists.
6. State clearly if this is local/project-doc status only and not synced to external trackers.

## Stale Text Sweep

Before final delivery, grep reports for stale blocker phrases and reconcile contradictions:

```bash
rg 'FAIL|PARTIAL|待补测试|唯一未闭合|建议先补测试|test-gap|Unit tests to be written|BLOCKED' <report-paths>
```

Also sweep for stale factual counts and obsolete implementation descriptions, not only explicit failure words. Final verifiers can correctly return PARTIAL when an appended closeout says PASS but earlier report sections still say old facts (for example "5 tests" after tests grew to 14, or "rerankModelId != null -> available" after the code changed to conservative rerank semantics). Re-read the whole report, not just the closeout section, and update summary tables, pipeline descriptions, and test coverage sections to match current code.

If final verification returns PARTIAL only for report inconsistency:

1. Patch the report-only stale sections as closeout documentation, not implementation.
2. Re-run OMX final verification focused on the prior report inconsistency.
3. Copy the new PASS report into the selected verification report path.
4. Only then mark local task/board status Done or verified.

Old FAIL/PARTIAL text may be acceptable when quoted as history, but current verdict/status sections must clearly override it with final PASS evidence.

## Runtime Artifact Cleanup

Before final handoff, remove or exclude local-only runtime artifacts and rerun hygiene checks:

```bash
rm -rf .sisyphus
pgrep -af 'opencode serve|opencode run' || true
git diff --check
```

If `graphify-out/` is tracked, do not delete or ignore it as a runtime artifact. Treat it as a generated tracked report: keep it in the worktree, strip trailing whitespace if `git diff --check` flags generated `GRAPH_REPORT.md`, and rerun `git diff --check` before declaring hygiene PASS.

## Verification Evidence

For final user status, cite:

- final OMX verdict,
- concrete code file:line evidence for the prior blockers,
- compile command and result,
- targeted test command and `Tests run` line,
- project docs updated,
- remaining non-blocking risks.
