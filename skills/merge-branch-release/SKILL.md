---
name: merge-branch-release
description: Use when the user wants to merge the current branch into another branch, repeat a previous merge after new local changes, publish code, push to a target branch, release to test/pre-release/prod, or says to merge and push.
---

# Merge Branch Release

## Core Rule

Preserve the user's working branch. Before any branch switch or target merge,
commit the current branch's relevant work and push the source branch
successfully. Then merge that branch into the target branch, push the target
branch, and switch back to the original branch. For any workflow that switches
branches or uses another worktree to merge, returning to the original branch is
mandatory by default.

Only skip returning to the original branch when the user explicitly says not to
switch back, or explicitly asks to delete the original branch after the merge.
Do not infer either exception from release wording alone.

Treat every user merge request as a fresh command, even when the same source
branch was already merged into the same target branch earlier in the
conversation. Do not skip the workflow because "this was already merged" unless
the current Git state proves there are no new commits, no relevant staged or
unstaged changes, and the source commit is already reachable from the target.
If the user merged once, the agent switched back to the source branch, the user
edited code, and then the user asks to merge again, the second request is a new
release attempt. Re-run status, diff, commit, push, target update, merge, push,
verification, and switch-back steps from the current state.

Never rely on conversational memory alone to decide that a merge is duplicate
or complete. Git state is the source of truth.

## Repeat Merge Rule

Repeated merge requests are common and expected. The user may:

1. Ask to merge the current branch into a target branch.
2. Wait for the agent to commit, push, merge, push the target, and switch back.
3. Make more edits on the original branch.
4. Ask to merge again using the same words as before.

In that case, do not answer that the merge has already been done. Start again
from the current checkout:

- Re-capture `source_branch`, `repo_root`, worktree state, status, diffs, and
  recent log.
- Detect and commit new relevant source changes before switching branches.
- Push the source branch again after any new commit.
- Re-enter or use the target branch/worktree and update it from its upstream.
- Merge the latest source branch tip into the target branch.
- Push the target branch again.
- Verify and return to the original branch/worktree again.

A repeated request may be skipped only after an explicit fresh check shows all
of these are true:

- `git status --short` has no relevant staged or unstaged source changes.
- The source branch has no unpushed commits that should be released.
- The target branch already contains the current source branch tip, for example
  `git merge-base --is-ancestor <source_branch> <target>` succeeds after
  fetching/updating the target.
- The target branch is pushed and up to date with its upstream.

Even when all of those are true, report the fresh verification evidence instead
of relying on an earlier run.

## Worktree Target Resolution

Before switching branches, detect worktree state and resolve the target branch
in this order:

1. Explicit user target branch.
2. Explicit release lane alias mapped to an existing branch, for example `main`, `master`, `develop`, `test`, `pre`, or `prod`.
3. Remote default branch from `git symbolic-ref --short refs/remotes/origin/HEAD`, if the user asked for the trunk but did not name it.
4. Local trunk fallback: `main`, then `master`, then `develop`.
5. Other checked-out worktree branch, only when the user clearly requested that branch.

When the target branch is checked out in another worktree:

- Do not force checkout that branch in the current worktree.
- If the branch cannot be checked out because Git reports it is already checked out elsewhere, use the path from `git worktree list --porcelain`.
- Before running target steps there, run `git -C <target_worktree_path> status --short`; stop if that worktree has unrelated uncommitted changes.
- Commit and push source changes first, then run the target-branch update, merge, push, and verification commands from that target worktree path.
- Switch the user's current shell back to the original `repo_root` after verification.

## Workflow

1. Capture starting state:
   - `source_branch=$(git branch --show-current)`
   - `repo_root=$(git rev-parse --show-toplevel)`
   - `git_common_dir=$(git rev-parse --git-common-dir)`
   - `git worktree list --porcelain`
   - `git status --short`
   - `git diff --staged; git diff`
   - `git log --oneline -10`
   - Do this on every merge request, including repeated requests for the same
     source and target branches. Do not reuse status, diff, log, or branch
     conclusions from a previous merge attempt.

2. Determine whether the current checkout is part of a Git worktree setup.
   - Parse `git worktree list --porcelain`.
   - Match the current `repo_root` to a `worktree <path>` entry.
   - Treat the checkout as a worktree checkout when the repository has more than one `worktree` entry or the matched path is not the primary worktree path.
   - Record all checked-out branches from `branch refs/heads/<name>` entries.

3. Determine the target branch from the user request.
   - If unclear, ask.
   - If the target branch is the same as `source_branch`, stop and clarify.
   - If the user explicitly names a target branch, use that branch.
   - If the user says "main", "master", "trunk", "主干", "test", "pre", "prod", or another release lane, resolve it to the matching local or remote branch.
   - If the current checkout is a worktree and the user asks to merge to the trunk, merge into the trunk branch.
   - If the current checkout is a worktree and the user asks to merge to another branch that is checked out in a different worktree, merge into that requested branch.
   - Do not infer the target from worktree paths alone when the user named a branch; the named branch wins.

4. Commit and push current branch code before switching.
   - Review staged and unstaged changes.
   - Stage only relevant files for the requested work.
   - Do not commit secrets or unrelated user changes without explicit confirmation.
   - Create the source-branch commit before any target checkout or merge.
   - For a repeated merge request, check for new source changes again. If new
     relevant changes exist, commit them even if an earlier merge in the same
     conversation already completed successfully.
   - If there are no relevant source changes to commit, record that no source commit was needed and still verify the source branch is pushed/up to date before switching.
   - Commit with a concise message via heredoc:

```bash
git commit -m "$(cat <<'EOF'
feat(scope): concise intent

EOF
)"
```

   - Push the source branch immediately after the commit succeeds.
   - If source has upstream: `git push`
   - If source has no upstream: `git push -u origin <source_branch>`
   - If the source push fails or is rejected, stop and report; do not switch branches or merge into the target.
   - Do not pull, rebase, force push, or otherwise rewrite source history to make the push work unless the user explicitly requests it.

5. Check whether the target branch exists.
   - Fetch branch refs first when network is needed: `git fetch origin`
   - If local target exists: `git checkout <target>`
   - Else if remote target exists: `git checkout -b <target> origin/<target>`
   - Else create target from current branch state: `git checkout -b <target> <source_branch>`
   - If the target branch is checked out in another worktree, do not run `git checkout <target>` here; run target-branch steps inside that worktree path.

6. Update the target branch if it tracks a remote.
   - If target steps run in another worktree path, first verify that path is on `<target>` and has no unrelated uncommitted changes.
   - If target has upstream: `git pull --ff-only`
   - If pull cannot fast-forward, stop and report; do not rebase or reset unless explicitly requested.

7. Merge source into target.
   - If target was newly created from source, no merge is needed.
   - Otherwise run: `git merge --no-ff <source_branch>`
   - For a repeated merge request, run the merge decision from the current
     target state. It is acceptable for Git to report "Already up to date" only
     after the source branch has been freshly checked, pushed or verified, and
     the target branch has been freshly updated.
   - If conflicts occur, stop after reporting conflicted files unless the fix is obvious and requested.

8. Push target.
   - Existing upstream: `git push`
   - No upstream or newly created branch: `git push -u origin <target>`

9. Verify and switch back.
   - Run `git status -sb` and `git log --oneline -3`.
   - Unless the user explicitly requested not to switch back or explicitly requested deleting the original branch, switch back: `git checkout <source_branch>`.
   - If target steps ran in another worktree path, return to the original `repo_root` instead of switching that target worktree away from its branch.
   - Run `git status -sb` again from the original branch/worktree and tell the user whether source is ahead/behind its remote.
   - If the user requested deleting the original branch, delete it only after target push verification and only when no unmerged work would be lost.

## Safety Constraints

- Never use `git reset --hard`, `git checkout --`, force push, or rebase unless the user explicitly requests it.
- Never skip hooks with `--no-verify`.
- Always push the source branch successfully before merging it into the target branch.
- Do not push unrelated source-branch commits or unrelated files; only include changes that belong to the requested release work.
- Do not remove, prune, or modify worktrees unless the user explicitly requests it.
- Do not leave the user on the target branch after a merge unless the user explicitly requested not to switch back or requested deleting the original branch.
- If uncommitted unrelated changes are present, ask before including them.
- If a command needs network or unrestricted git access, request the needed tool permission and continue.

## Final Response

Report:

- commit hash created on the source branch, if any
- source branch push result
- target branch updated
- whether a separate worktree path was used for the target branch
- target branch push result
- final branch/worktree after switching back, or the explicit user exception that skipped switching back
- any residual ahead/behind status or conflicts
