---
name: merge-branch-release
description: Use when the user wants to merge the current branch into another branch, repeat a previous merge after new local changes, publish code, push to a target branch, release to test/pre-release/prod, or says to merge and push, including workspaces that contain multiple Git repositories.
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
the current Git state proves there are no new commits, no pending source changes
belong to the requested release, and the source commit is already reachable from
the target.
If the user merged once, the agent switched back to the source branch, the user
edited code, and then the user asks to merge again, the second request is a new
release attempt. Re-run status, diff, commit, push, target update, merge, push,
verification, and switch-back steps from the current state.

Never rely on conversational memory alone to decide that a merge is duplicate
or complete. Git state is the source of truth.

## Repository Scope Resolution

Resolve the repository scope before resolving source or target branches. In a
workspace containing multiple Git repositories, treat each Git root and index
as independent even when repositories are nested under one parent directory.

Use this evidence in order:

1. An explicitly named repository, module, or path in the user's request.
2. The repository containing the files, implementation, or task the user is
   referring to in the current context.
3. The repository containing the relevant dirty changes or source commits from
   the current task.
4. The current Git root only when the preceding context does not point to a
   different repository.

For every plausible repository, resolve its Git root independently and inspect
its current branch, status, worktrees, remotes, and local/remote target refs.
Use `git -C <repo> ...` when necessary; never run one repository's Git commands
from another repository by accident.

When the user only says "merge to test", "合并到 test", or names another release
lane without naming a repository:

- Use the repository implied by the active task and changed files only when the
  context identifies it unambiguously and that repository contains the named
  target as a local branch or remote-tracking branch.
- If the context intentionally covers multiple repositories, build an explicit
  repository list and verify the named target separately in every repository.
- If multiple repositories remain plausible, report the candidates, relevant
  context evidence, current/source branches, and whether each contains the
  target, then ask the user to choose the repository scope.
- If the context points to one repository but that repository lacks the target,
  stop and report the missing branch. Do not switch to another repository merely
  because that repository has a branch with the requested name.
- Treat naming `test`, `pre`, `prod`, or another target as a merge destination,
  not as permission to create that branch. Never auto-create a missing target.

## No SHA Shortcut

`merge-base --is-ancestor`, matching local/remote SHAs, or seeing the same commit
on `source`, `target`, and `origin/*` is only evidence for one skip condition.
It never replaces the workflow.

Do not answer "already merged", "nothing to do", or "no need to merge" until
you have either:

- completed steps 1-10 below, where `git merge --no-ff <source_branch>` and
  `git push` may legitimately report "Already up to date" or "Everything
  up-to-date"; or
- completed the Skip Audit below and every item passes with fresh command
  evidence from this request.

If any Skip Audit item fails or is unknown, do not simplify the result to
"already merged." Either continue the full workflow when safe, or stop at the
specific blocker and ask for the needed confirmation.

## Skip Audit

Skipping the target checkout/pull/merge/push sequence is allowed only when all
items below pass in the current request. This is stricter than "the commits look
the same."

| Item | Required evidence |
|------|-------------------|
| No pending release work | `git status --short` has no staged or unstaged changes that the user asked to include in this release. Dirty unrelated files do not block a verified skip when they can remain untouched. |
| No source commit needed | Fresh staged/unstaged diff review shows no relevant releasable changes. |
| Source pushed | `git status -sb` and upstream comparison show no unpushed source commits, or a fresh `git push` succeeded. |
| Target updated | Target branch/worktree was fetched and, when it tracks upstream, `git pull --ff-only` succeeded or upstream equality was freshly verified. |
| Target contains source tip | `git merge-base --is-ancestor <source_tip> <target_tip>` succeeds after target update. |
| Target pushed | Target branch is not ahead of its upstream; remote target equals local target tip. |

Do not treat suspected secrets, credentials, config files, `.env` files, or key
material as a special merge blocker. If such files are part of the user's
requested source changes, commit and merge them like other relevant release
work. Do not sanitize, redact, replace with placeholders, or otherwise edit file
contents unless the user explicitly asks for that remediation. Do not switch
branches with dirty files unless Git says it is safe and the dirty files are
intentionally carried, or use a clean target worktree instead.

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

- `git status --short` has no staged or unstaged changes that should be
  included in this release. Suspected secrets alone do not make a change
  unreleasable or require placeholdering.
- The source branch has no unpushed commits that should be released.
- The target branch already contains the current source branch tip, for example
  `git merge-base --is-ancestor <source_branch> <target>` succeeds after
  fetching/updating the target.
- The target branch is pushed and up to date with its upstream.

Even when all of those are true, report the fresh verification evidence instead
of relying on an earlier run.

## Source Branch Resolution

Default source branch is the current checkout. But when the user explicitly
names a source branch, as in "merge dev into main", that named branch is the
source even if the current checkout is different.

- Capture `current_branch=$(git branch --show-current)` and resolve
  `source_branch` from the request before deciding what to commit or push.
- Capture these values independently for each selected repository. Do not reuse
  a source branch name or commit conclusion across repositories.
- If `source_branch != current_branch`, do not stage or commit the current
  branch's dirty files as source work.
- Inspect and push the named source branch from its existing worktree, or check
  it out only after confirming the current worktree can switch safely.
- If dirty files or another checked-out worktree make source checkout unsafe,
  stop and report the blocker or use the source branch's existing worktree. Do
  not silently fall back to the current branch. Do not rewrite dirty files to
  placeholders to make checkout easier.

## Target Branch Resolution

After resolving the repository scope, detect worktree state and resolve the
target branch inside that repository in this order:

1. Explicit user target branch.
2. Explicit release lane alias mapped to an existing branch, for example `main`, `master`, `develop`, `test`, `pre`, or `prod`.
3. Remote default branch from `git symbolic-ref --short refs/remotes/origin/HEAD`, if the user asked for the trunk but did not name it.
4. Local trunk fallback: `main`, then `master`, then `develop`.
5. Other checked-out worktree branch, only when the user clearly requested that branch.

Require the resolved target to exist as `refs/heads/<target>` or
`refs/remotes/<remote>/<target>` after the appropriate ref check or fetch. A
same-named branch in a sibling or parent repository does not satisfy this check.
If the target is absent, stop at a User Decision Gate. Do not create it unless
the user explicitly asks to create that missing branch after seeing the result.

When the target branch is checked out in another worktree:

- Do not force checkout that branch in the current worktree.
- If the branch cannot be checked out because Git reports it is already checked out elsewhere, use the path from `git worktree list --porcelain`.
- Before running target steps there, run `git -C <target_worktree_path> status --short`; stop if that worktree has unrelated uncommitted changes.
- Commit and push source changes first, then run the target-branch update, merge, push, and verification commands from that target worktree path.
- Switch the user's current shell back to the original `repo_root` after verification.

## Validation Policy

Avoid duplicate time-consuming validation. Before running source tests, lint,
builds, or type checks, reuse a successful current-task result for this repository
and relevant work when it covers the latest edits, remains valid, and is reportable.

Otherwise run the repository's appropriate source checks, except in Fast Merge
Mode. Conversational context may prove test execution; use Git for branch,
commit, diff, and push state. Record whether validation was run or reused.

After merging and before target push, inspect the combined diff and diff stat.
Run focused and relevant broader checks after any conflict or for large/high-
impact changes such as cross-module, dependency/build, configuration, schema,
migration, public API, or data-contract changes. Judge affected behavior and
repository conventions, not file count alone. A small conflict-free merge may
reuse qualifying evidence when the target adds no material interaction risk. Cheap Git checks
always remain. If required validation fails or cannot run, stop before target push.

### Fast Merge Mode

Enable Fast Merge Mode only when the user explicitly asks for a fast merge or
explicitly asks to skip tests or time-consuming validation. Do not infer it
from general release urgency alone.

In Fast Merge Mode, skip time-consuming validation even for a large change, but keep cheap Git
checks. Report every conflict, follow the normal protocol and gates, and report each skip.

## User Decision Gates

Stop, explain the evidence and risk, recommend an option, and ask the user to
decide before any of these actions:

- Select a repository when multiple repositories remain plausible from context.
- Include, discard, stash, move, or overwrite unrelated uncommitted work.
- Create a missing target branch. Naming a merge destination alone is not
  permission to create it.
- Pull, merge, rebase, reset, force push, or otherwise rewrite history after a
  rejected source push or a non-fast-forward target update.
- Resolve a semantic conflict by choosing one behavior over another, deleting
  either side's code, changing a public API or data contract, or materially
  rewriting code introduced by either branch.
- Choose an entire file with `--ours` or `--theirs` when the file contains more
  than mechanical generated output.
- Continue after required conflict validation fails or cannot cover the affected
  behavior, except when Fast Merge Mode waived time-consuming validation.
- Delete the original branch or any worktree.

Do not ask the user to decide low-risk mechanical details when all intent is
preserved, such as combining independent additions or resolving whitespace.
Still report any modification to `theirs` as required below.

For each decision gate, use a clear prompt containing: the blocked step, current
state, evidence, options, impact of each option, recommended option with reason,
and the exact decision needed. Do not continue the risky step until the user
answers.

## Conflict Resolution Protocol

With the target branch checked out, use Git terms precisely:

- `ours` is the checked-out target branch.
- `theirs` is the source branch being merged.
- Do not equate `theirs` with older, incorrect, or disposable code.

When `git merge --no-ff <source_branch>` reports conflicts:

1. Stop before editing. Do not abort the merge unless the user requests it.
2. Capture the conflict state with `git status --short`,
   `git diff --name-only --diff-filter=U`, `git diff --diff-filter=U`, and
   `git ls-files -u`.
3. Inspect each conflicted file's base, ours, and theirs stages with
   `git show :1:<path>`, `git show :2:<path>`, and `git show :3:<path>` when
   those stages exist. Account for add/add and modify/delete conflicts where a
   stage may be absent.
4. Determine intent and which logic supersedes the other. Compute the merge
   base, inspect the commits and diffs on both branches since that base, trace
   callers and dependencies when relevant, and inspect related tests and
   documentation. Do not decide that code is newer or correct from timestamps,
   commit order, branch names, or `ours`/`theirs` labels alone.
5. Present a decision packet for every risky conflict:
   - conflicted file and affected function, module, API, or behavior
   - what changed on ours and why
   - what changed on theirs and why
   - evidence about which logic is newer or superseding
   - viable resolution options, including preserving both when possible
   - recommended option, risks, and verification plan
   Ask the user to choose before editing.
6. Resolve only the approved scope. Preserve non-conflicting changes from both
   sides. Do not use whole-file `git checkout --ours` or `--theirs` merely for
   convenience.
7. Before staging each resolved file, inspect and record how the resolution
   differs from both sides, including `git diff --ours -- <path>` and
   `git diff --theirs -- <path>`. Treat any removal, replacement, or behavioral
   alteration of code from stage 3 as a modification to `theirs`.
8. Require empty `git diff --name-only --diff-filter=U` output and review the
   resolved diff. Unless Fast Merge Mode applies, run focused and relevant
   broader tests. If required validation fails or is unavailable, enter a User
   Decision Gate. Fast Merge Mode skips those tests, not conflict reporting or
   cheap Git/diff verification.
9. Commit and push the target only after the approved resolution is complete
   and verified. Then finish the normal verification and switch-back workflow.

If the resolution modifies `theirs`, make the change highly visible in the
final response under a separate `## ⚠️ WARNING: THEIRS CODE CHANGED` heading. List
the affected files and behavior, what was changed or removed, why the selected
logic is newer or safer, the user's decision that authorized it, and the tests
or checks performed. Never bury this notice in a general merge summary.

## Workflow

0. Resolve repository scope:
   - Identify all Git roots plausibly involved in the current request.
   - Map the current task, referenced files, relevant changes, and source commits
     to their owning repositories.
   - Check whether the requested target exists locally or remotely in each
     plausible repository.
   - Continue automatically only when context and branch evidence identify one
     repository unambiguously, or when the user clearly requested a known set of
     repositories. Otherwise enter a User Decision Gate.

1. Capture starting state:
   - `current_branch=$(git branch --show-current)`
   - `source_branch=<current_branch or explicitly named source branch>`
   - `repo_root=$(git rev-parse --show-toplevel)`
   - `git_common_dir=$(git rev-parse --git-common-dir)`
   - `git worktree list --porcelain`
   - `git status --short`
   - `git diff --staged; git diff`
   - `git log --oneline -10`
   - Do this independently in every selected repository on every merge request,
     including repeated requests for the same source and target branches. Do not
     reuse status, diff, log, or branch conclusions from another repository or a
     previous merge attempt.
   - If `git status --short` is non-empty, classify each dirty path before
     deciding anything: relevant releasable work, unrelated user work, or
     generated noise. Do not add a separate secret/credential blocker category,
     and do not redact or placeholder file contents during classification.

2. Determine whether the current checkout is part of a Git worktree setup.
   - Parse `git worktree list --porcelain`.
   - Match the current `repo_root` to a `worktree <path>` entry.
   - Treat the checkout as a worktree checkout when the repository has more than one `worktree` entry or the matched path is not the primary worktree path.
   - Record all checked-out branches from `branch refs/heads/<name>` entries.

3. Determine the target branch from the user request.
   - If unclear, ask.
   - If the target branch is the same as `source_branch`, stop and clarify.
   - If the user explicitly names a target branch, use that branch only inside
     the resolved repository scope.
   - If the user says "main", "master", "trunk", "主干", "test", "pre", "prod", or another release lane, resolve it to the matching local or remote branch.
   - If the current checkout is a worktree and the user asks to merge to the trunk, merge into the trunk branch.
   - If the current checkout is a worktree and the user asks to merge to another branch that is checked out in a different worktree, merge into that requested branch.
   - Do not infer the target from worktree paths alone when the user named a branch; the named branch wins.

4. Validate, commit, and push source branch code before switching.
   - Review staged and unstaged changes in the source branch/worktree.
   - Stage only relevant files for the requested work.
   - Do not commit unrelated user changes without explicit confirmation.
   - Do not block or rewrite relevant release changes because they look like
     secrets, credentials, config, `.env`, or key material. If the user said to
     merge/release them, preserve their contents exactly.
   - Apply the Validation Policy; reuse qualifying current-task validation
     instead of rerunning it.
   - Create the source-branch commit before any target checkout or merge.
   - For a repeated merge request, check for new source changes again. If new
     relevant changes exist, commit them even if an earlier merge in the same
     conversation already completed successfully.
   - If there are no relevant source changes to commit, record that no source commit was needed and still verify the source branch is pushed/up to date before switching.
   - If unrelated dirty files remain, do not use them as a reason to claim the
     merge is complete. Either use a separate clean target worktree for the
     target steps, or enter a User Decision Gate and report the dirty paths and
     available choices. Do not stash, discard, include, or move them without the
     user's decision.
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
   - If the source push fails or is rejected, stop, report the divergence and
     enter a User Decision Gate. Do not switch branches or merge into the target.
   - Do not pull, merge, rebase, force push, or otherwise rewrite source history
     to make the push work unless the user explicitly selects that option.

5. Check whether the target branch exists.
   - Fetch branch refs first when network is needed: `git fetch origin`
   - If local target exists: `git checkout <target>`
   - Else if remote target exists: `git checkout -b <target> origin/<target>`
   - Else stop and report that the target is missing. Never auto-create it.
   - Only after the user explicitly decides to create the known-missing branch,
     create it from the approved base, normally
     `git checkout -b <target> <source_branch>`.
   - If the target branch is checked out in another worktree, do not run `git checkout <target>` here; run target-branch steps inside that worktree path.

6. Update the target branch if it tracks a remote.
   - If target steps run in another worktree path, first verify that path is on `<target>` and has no unrelated uncommitted changes.
   - If target has upstream: `git pull --ff-only`
   - If pull cannot fast-forward, stop and present the local/remote divergence,
     available options, and risks. Let the user decide; do not merge, rebase,
     reset, or force push unless explicitly selected.

7. Merge source into target.
   - If target was newly created from source, no merge is needed.
   - Otherwise run: `git merge --no-ff <source_branch>`
   - For a repeated merge request, run the merge decision from the current
     target state. It is acceptable for Git to report "Already up to date" only
     after the source branch has been freshly checked, pushed or verified, and
     the target branch has been freshly updated.
   - If conflicts occur, follow the Conflict Resolution Protocol. Resolve only
     low-risk mechanical conflicts without a new decision; enter a User Decision
     Gate for every semantic or destructive choice.
   - Do not replace this step with only `merge-base --is-ancestor` unless the
     Skip Audit passed completely and you are explicitly reporting a verified
     skip.

8. Validate the merged target.
   - Apply the Validation Policy to the combined target diff before pushing.
   - If required validation fails or cannot run, enter a User Decision Gate.

9. Push target.
   - Existing upstream: `git push`
   - No upstream or newly created branch: `git push -u origin <target>`

10. Verify and switch back.
   - Run `git status -sb` and `git log --oneline -3`.
   - Unless the user explicitly requested not to switch back or explicitly requested deleting the original branch, return to the original branch/worktree. If this worktree was switched away from the user's starting branch, run `git checkout <current_branch>`.
   - If target steps ran in another worktree path, return to the original `repo_root` instead of switching that target worktree away from its branch.
   - Run `git status -sb` again from the original branch/worktree and tell the user whether source is ahead/behind its remote.
   - If the user requested deleting the original branch, delete it only after target push verification and only when no unmerged work would be lost.

## Safety Constraints

- Never use `git reset --hard`, `git checkout --`, force push, or rebase unless the user explicitly requests it.
- Never use whole-file `git checkout --ours`, `git checkout --theirs`,
  `git restore --ours`, or `git restore --theirs` for a semantic conflict unless
  the user selected that exact resolution after reviewing its impact.
- Never skip hooks with `--no-verify`.
- Never infer one repository's branch existence from another repository. Never
  auto-create a missing release branch such as `test`, `pre`, or `prod`.
- Always push the source branch successfully before merging it into the target branch.
- Do not push unrelated source-branch commits or unrelated files; only include changes that belong to the requested release work.
- Do not remove, prune, or modify worktrees unless the user explicitly requests it.
- Do not leave the user on the target branch after a merge unless the user explicitly requested not to switch back or requested deleting the original branch.
- If uncommitted unrelated changes are present, ask before including them.
- Never assume later commit time means newer business logic. Compare both sides
  from the merge base and verify the affected behavior.
- Never silently remove or rewrite code from `theirs`. Require a user decision
  when the change is risky and always emit the prominent post-resolution notice.
- Do not perform secret cleanup as part of merge/release. Never redact,
  placeholder, rotate, delete, or otherwise modify suspected secrets or
  credentials unless the user explicitly asks for that separate cleanup.
- If a command needs network or unrestricted git access, request the needed tool permission and continue.

## Red Flags - Stop and Re-check

These phrases indicate the agent is about to violate the skill:

- "All refs are the same SHA, so no need to do anything."
- "`merge-base` says the source is already included, so I can skip the rest."
- "The remote is aligned" without a target checkout/worktree update and target
  push/upstream verification.
- Dirty config, `.env`, credential, or key files exist, and the agent edits them
  to placeholders or refuses to merge solely because of their contents.
- "Theirs has a later commit, so it must be the newer logic."
- "This sibling repository has `test`, so it must be the intended repository."
- "The user said merge to `test`, so I can create `test` when it is missing."
- The agent resolves a semantic conflict or rewrites `theirs` before the user
  answers the required decision prompt.
- The agent modifies `theirs` but omits the prominent warning and validation
  evidence from the final response.
- The final answer omits source push, target update, target merge/push, and
  switch-back status.

When any red flag appears, return to the Workflow or Skip Audit. Do not final.

## Final Response

Use this structure. If a step was skipped, name the exact Skip Audit evidence
that allowed it; otherwise report the command result.

- resolved repository path for every repository in scope and the context
  evidence used to select it
- commit hash created on the source branch, if any
- source branch push result
- target branch updated
- target merge result, including "Already up to date" when that is what Git reported
- source validation result, reused evidence, or Fast Merge Mode skip reason
- post-merge risk assessment and target validation result or skip reason
- whether a separate worktree path was used for the target branch
- target branch push result
- final branch/worktree after switching back, or the explicit user exception that skipped switching back
- any residual ahead/behind status or conflicts
- conflict decisions made by the user and the verification performed
- a separate `## ⚠️ WARNING: THEIRS CODE CHANGED` section whenever the resolution
  modified code from `theirs`, including affected files/behavior, rationale,
  authorization, and test results
- dirty files not committed, if any, and whether they were unrelated to the
  requested release
