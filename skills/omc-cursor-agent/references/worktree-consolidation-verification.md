# Worktree Consolidation + OMC Verification

Use this when a task was implemented across Cursor worktrees and the user asks whether it is done, whether worktrees should be merged, or asks OMC Claude Code to verify.

## Pattern

1. Resolve the task note/spec first, preferably from the user's selected documentation surface, such as a Notion page, Obsidian link, local project path, or repo doc.
2. Identify the real repo and branch from the task note, prior reports, or code search.
3. Inspect every worktree:

```bash
git -C <repo> worktree list --porcelain
for wt in <main> <worker1> <worker2>; do
  echo "## $wt"
  git -C "$wt" status --short
  git -C "$wt" diff --stat
  git -C "$wt" ls-files --others --exclude-standard
 done
```

4. Compare worker outputs against the main worktree before merging:

```bash
for f in $(git -C <worker> diff --name-only; git -C <worker> ls-files --others --exclude-standard); do
  if [ -e "<main>/$f" ]; then
    cmp -s "<main>/$f" "<worker>/$f" && echo "SAME $f" || echo "DIFF $f"
  else
    echo "MISSING_MAIN $f"
  fi
done
```

5. If a worker is clean, record it as having no unique changes.
6. If worker changes are already present in main, do not merge again; record `main is superset/current state`.
7. If main has newer improvements over worker changes, keep main unless the user explicitly requested the worker's version.
8. Do not delete temporary worktrees without explicit confirmation; report them and offer cleanup.
9. Write durable reports under the existing project's selected documentation area, e.g. `AI编排/Reports/<task-id>-implementation-check.md` and `AI编排/Reports/<task-id>-omc-verification.md` for local markdown projects.
10. Have OMC Claude Code verify against the task/spec/report/code in a separate verification lane. Have the brain write its report to the selected verification report path.

## Verification Commands

Run relevant local checks yourself before asking the verification lane, but report blockers accurately. If Maven/test execution fails due to missing private snapshot dependencies or credentials, mark verification as `BLOCKED`, not `PASS` or `FAIL`.

Use the OMC verification lane (native `verifier`/`code-reviewer`, `model=opus` for large/security work, or a read-only headless `claude -p --permission-mode plan`) with a prompt shape like:

```text
You are the OMC verification reviewer. Verify <task-id> implementation against <task-path> and <implementation-report>. Inspect code as needed. Write a concise markdown verification report to <verification-report>. Include verdict (PASS/BLOCKED/FAIL), acceptance mapping, risks, and exact commands reviewed/run. Do not modify source code.
```

## Report Requirements

Implementation check report should include:

- worktree list and per-worktree status
- whether worker changes are unique, already merged, or superseded
- acceptance mapping
- relevant files
- test/build commands and exact result
- residual risks/blockers

OMC verification report should include:

- verdict: `PASS`, `BLOCKED`, or `FAIL`
- acceptance mapping
- product/semantic risks separate from test blockers
- exact commands reviewed/run
- final assessment

## Pitfalls

- Do not equate `static coverage looks OK` with `done` when tests cannot run.
- Do not use Markdown tables in chat-gateway-targeted summaries; prefer bullets. Project reports can use bullets for maximum gateway readability too.
- Do not overwrite a main worktree with a worker branch if main contains later review/hardening improvements.
- If a graphify update is required by project rules and fails only on HTML viz size after AST extraction, report that nuance; do not imply code verification failed.
- Keep verification in a separate lane from the spec-authoring context; never self-approve in the same active context.
