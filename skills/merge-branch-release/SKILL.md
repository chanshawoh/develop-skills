---
name: merge-branch-release
description: Use when the user wants to merge the current branch into another branch, repeat a previous merge after new local changes, publish code, push to a target branch, release to test/pre-release/prod, or says to merge and push, including workspaces that contain multiple Git repositories.
---

# Merge Branch Release

## Operating Contract

Treat every merge request, including a repeated request, as a fresh release
attempt. Git state is authoritative; never rely on conversational memory or a
previous SHA check alone.

Before mutation, resolve and record:

- `repo_root`, `remote_name`, and `remote_url`
- `current_branch`, `source_branch`, and after source commit, `source_tip`
- `target_branch`, `target_path`, and after target update, `target_before`

Commit and push only relevant source work, update exactly the requested target,
merge `source_tip` into it, review the result, push the explicit target ref, and
return to the starting branch/worktree. Never merge the source into the current
or starting branch unless the user named that branch as the target.

Do not chain checkout, pull, merge, commit, or push together. Inspect each
state-changing result; push must always be a separate command. Never skip hooks
with `--no-verify`.

## Validation Policy

Avoid duplicate time-consuming checks. Reuse a successful current-task test,
lint, build, or type-check result only when it covers this repository and latest
edits, remains valid, and can be reported. Otherwise run appropriate checks.
Conversational evidence may prove validation; use Git for branch, commit, diff,
and push state. Record whether validation ran, was reused, or was skipped.

After merge, always inspect the combined diff. Run focused and relevant broader
checks after conflicts or high-impact cross-module, dependency/build, config,
schema, migration, public API, or data-contract changes. A small conflict-free
merge may reuse qualifying evidence when the target adds no material interaction
risk. Judge behavior and repository conventions, not file count alone.

Enable Fast Merge Mode only when the user explicitly asks for a fast merge or
to skip tests/time-consuming validation. It may skip those checks even for a
large change, but never skips conflict reporting, User Decision Gates, or cheap
Git/diff checks. Report every skipped check and reason.

## User Decision Gates

Stop before the risky action, show evidence, options and impact, recommend one,
and ask for the exact decision when any of these applies:

- Multiple repositories remain plausible.
- Unrelated work would be included, discarded, stashed, moved, or overwritten.
- The target branch is missing and would need creation.
- A source push is rejected or target update is non-fast-forward and recovery
  would require pull, merge, rebase, reset, force push, or history rewriting.
- A conflict requires choosing business behavior, deleting either side's code,
  changing an API/data contract, or selecting a whole non-generated file with
  `--ours` or `--theirs`.
- Required validation fails, cannot run, or does not cover affected behavior;
  an explicit Fast Merge Mode waiver is a skip, not a failure.
- The proposed target diff contains unexpected deletion, rename, unrelated
  scope, or high-impact schema, migration, dependency, configuration, auth,
  security, public API, or data-contract changes.
- Recovering an incorrect commit, merge, or release would require revert,
  reset, force push, cherry-pick, or reverting a revert.
- Deleting a source branch or any worktree.

Resolve low-risk mechanical conflicts without asking only when all intent is
preserved, such as independent additions or whitespace. Still report any
modification to `theirs` as required below.

## Workflow

### 1. Resolve repository and starting state

In multi-repository workspaces, treat every Git root independently. Select the
repository using this evidence order:

1. Explicit repository, module, or path from the user.
2. Repository owning the referenced files or current task.
3. Repository owning relevant dirty changes or source commits.
4. Current Git root only when earlier evidence is absent.

For every plausible repository, inspect its root, branch, status, worktrees,
remotes, and local/remote target refs with `git -C <repo> ...`. A target branch
in a sibling repository is irrelevant. If scope remains ambiguous, enter a User
Decision Gate.

Capture fresh state in every selected repository:

```bash
git rev-parse --show-toplevel
git branch --show-current
git worktree list --porcelain
git status --short
git diff --staged
git diff
git log --oneline -10
```

Classify dirty paths as relevant release work, unrelated user work, or generated
noise. Do not include unrelated work without approval. Do not treat suspected
secrets, credentials, `.env`, config, or key material as a special merge
blocker; preserve relevant requested contents exactly unless the user separately
asks for cleanup.

### 2. Resolve source, target, and execution path

Default `source_branch` to the current checkout. If the user names a source,
use that branch; do not silently substitute the current branch or commit its
dirty files. Use its existing worktree when present, otherwise check it out only
when safe.

Resolve `target_branch` from the explicit target or release-lane alias. For an
unnamed trunk, prefer the remote default branch, then existing `main`, `master`,
or `develop`. The named branch always wins over worktree paths.

Require target and source to differ. Require the target to exist locally or as
`refs/remotes/<remote_name>/<target_branch>` after a fetch. Naming `test`, `pre`,
`prod`, or another destination is not permission to create it. If missing,
enter a User Decision Gate.

Parse `git worktree list --porcelain` before choosing `target_path`:

- If the target is checked out elsewhere, do not force-check it out here.
- Use an existing target worktree only when this task owns it and its state can
  remain stable; a clean status does not prove exclusive ownership.
- When another session/process is active or ownership is unknown, use a
  task-owned temporary clone or isolated checkout.
- Stop if the selected target path contains unrelated uncommitted changes.
- Never prune, remove, or repurpose a worktree without user approval.

### 3. Validate, commit, and push source work

Review staged and unstaged source changes. Stage and commit only requested
release work before any target checkout or merge. Apply the Validation Policy;
reuse qualifying current-task evidence instead of rerunning it. On repeated
requests, check again for new changes and validation coverage.

If no source commit is needed, still verify the source branch is pushed and up
to date. If unrelated dirty paths prevent safe switching, use an isolated target
path or enter a User Decision Gate; never stash, discard, or move them silently.

Immediately before source push, re-assert repository root, source branch, and
remote URL. Push the explicit ref:

```bash
git push <remote_name> <source_branch>:refs/heads/<source_branch>
```

Use `-u` only when establishing upstream. If rejected, stop before target work;
do not pull, merge, rebase, reset, or force push without the user's decision.
Capture `source_tip`, verify the remote source equals it, and freeze that SHA for
this attempt.

### 4. Prepare and update target

Fetch `<remote_name>`. Use the existing target worktree, check out the local
target, or create a local tracking branch from the existing remote target. Do
not create a known-missing target unless the user approved its exact base.

Immediately before target update, freshly verify repository root, remote URL,
target path, and `git branch --show-current == target_branch`. If it tracks a
remote, run `git pull --ff-only`. Stop on divergence and enter a User Decision
Gate; never auto-merge, rebase, reset, or force push. Capture `target_before`
after the update.

### 5. Preview and merge

Before mutation, review source commits and scope against the updated target:

```bash
git log --oneline <target_before>..<source_tip>
git diff --stat <target_before>...<source_tip>
git diff --name-status <target_before>...<source_tip>
```

Enter a User Decision Gate for unexpected scope or high-impact changes. Do not
merge first and explain later.

Freshly re-assert the complete merge contract, then run this as its own command:

```bash
git merge --no-ff <source_tip>
```

If conflicts occur, follow the Conflict Resolution Protocol. Otherwise continue
to combined-diff validation and pre-push review.

### 6. Validate, review, and push target

Apply the Validation Policy to the combined target diff. Before push, require:

- No unmerged paths.
- `target_before` and `source_tip` are ancestors of `HEAD`.
- A new merge commit's first parent equals `target_before`.
- Required checks passed or were validly reused; Fast Merge Mode skips are
  explicit and reported.
- `git diff --stat <target_before>..HEAD` and
  `git diff --name-status <target_before>..HEAD` contain only reviewed scope.

Unexpected deletion, rename, unrelated scope, or high-impact behavior enters a
User Decision Gate. A successful merge alone is not authorization to push.

Freshly re-assert repository root, remote URL, target branch, and reviewed
`HEAD`. Push only the explicit destination:

```bash
git push <remote_name> HEAD:refs/heads/<target_branch>
```

Never force push unless the user selected that recovery after reviewing impact.
Verify the remote target equals the reviewed local commit.

### 7. Verify, report, and return

Run `git status -sb` and `git log --oneline -3` on the target, then return to the
original branch/worktree unless the user explicitly requested otherwise. When
target work used another path, leave that path on its target and return to the
original `repo_root`.

Recheck the original status and report residual dirty files, conflicts, and
source ahead/behind state. Delete a branch only after verified target push and
explicit user approval.

### Verified skip

Report a verified skip instead of running target merge/push only when fresh
evidence proves all of the following:

- No relevant staged or unstaged source work remains.
- No source commit or push is pending; remote source equals `source_tip`.
- The target was freshly fetched/updated and contains `source_tip`.
- Local and remote target tips are equal.

If any item is unknown, continue the workflow or report the exact blocker. A
matching SHA or `merge-base --is-ancestor` result alone is insufficient.

## Conflict Resolution Protocol

On the checked-out target, `ours` means target and `theirs` means source. Never
infer that `theirs` is older, wrong, or disposable.

1. Stop before editing; do not abort unless requested.
2. Capture `git status --short`, unmerged paths, conflict diff, and
   `git ls-files -u`.
3. Inspect available base/ours/theirs stages with `git show :1:<path>`,
   `:2:<path>`, and `:3:<path>`, accounting for absent stages.
4. Inspect merge base, both branches' commits/diffs, callers, dependencies,
   tests, and documentation. Do not infer newer business logic from timestamps,
   commit order, branch names, or ours/theirs labels.
5. For every semantic or destructive choice, present the affected behavior,
   each side's intent, evidence, viable options, recommendation, risks, and
   verification plan; wait for the user's decision.
6. Resolve only the approved scope. Preserve non-conflicting changes from both
   sides; never select a whole semantic file merely for convenience.
7. Before staging, compare each resolution with both sides using
   `git diff --ours -- <path>` and `git diff --theirs -- <path>`. Treat removal,
   replacement, or behavioral alteration of stage 3 as modifying `theirs`.
8. Require zero unmerged paths and review the complete resolved diff. Apply the
   Validation Policy; Fast Merge Mode skips time-consuming checks, not conflict
   reporting or cheap Git/diff verification.
9. Re-assert the merge contract, commit only after approval and validation,
   then repeat pre-push invariants and push as a separate command.

Whenever the resolution modifies `theirs`, include a separate final section:

```markdown
## ⚠️ WARNING: THEIRS CODE CHANGED
```

List affected files/behavior, what changed or was removed, why, the user decision
that authorized it, and validation performed.

## Wrong-Target or Bad-Merge Recovery

Stop all pushes and downstream releases when repository, remote, branch, parent,
diff, or commit message is unexpected. Capture the bad commit and parents,
affected local/remote refs, `git branch -a --contains <bad_commit>`, and release
branch ancestry.

Do not auto-revert or rewrite history. A revert preserves history but its inverse
patch can later delete functionality merged independently into downstream
branches. Present revert/reset/force-push/cherry-pick options, propagation impact,
recommendation, and verification plan at a User Decision Gate.

Never use `git reset --hard`, `git checkout --`, rebase, or force push unless the
user explicitly selects that action after reviewing its scope and impact.

## Final Response

Report repository/remote selection, merge contract SHAs, source commit/push,
source validation run/reuse/Fast Mode skip, target update, merge or verified
skip, combined-diff risk review and target validation, target push and remote
equality, execution path/isolation, final branch/worktree, residual status,
user decisions, recovery actions, and unresolved risks. Include the prominent
`THEIRS CODE CHANGED` section whenever applicable.
