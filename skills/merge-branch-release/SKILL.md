---
name: merge-branch-release
description: Use when the user wants to merge the current branch into another branch, publish code, push to a target branch, release to test/pre-release/prod, or says to merge and push.
---

# Merge Branch Release

## Core Rule

Preserve the user's working branch. Commit current-branch work first, merge that
branch into the target branch, push the target branch, then switch back to the
original branch.

## Workflow

1. Capture starting state:
   - `source_branch=$(git branch --show-current)`
   - `git status --short`
   - `git diff --staged; git diff`
   - `git log --oneline -10`

2. Determine the target branch from the user request.
   - If unclear, ask.
   - If the target branch is the same as `source_branch`, stop and clarify.

3. Commit current branch code before switching.
   - Review staged and unstaged changes.
   - Stage only relevant files for the requested work.
   - Do not commit secrets or unrelated user changes without explicit confirmation.
   - Commit with a concise message via heredoc:

```bash
git commit -m "$(cat <<'EOF'
feat(scope): concise intent

EOF
)"
```

4. Check whether the target branch exists.
   - Fetch branch refs first when network is needed: `git fetch origin`
   - If local target exists: `git checkout <target>`
   - Else if remote target exists: `git checkout -b <target> origin/<target>`
   - Else create target from current branch state: `git checkout -b <target> <source_branch>`

5. Update the target branch if it tracks a remote.
   - If target has upstream: `git pull --ff-only`
   - If pull cannot fast-forward, stop and report; do not rebase or reset unless explicitly requested.

6. Merge source into target.
   - If target was newly created from source, no merge is needed.
   - Otherwise run: `git merge --no-ff <source_branch>`
   - If conflicts occur, stop after reporting conflicted files unless the fix is obvious and requested.

7. Push target.
   - Existing upstream: `git push`
   - No upstream or newly created branch: `git push -u origin <target>`

8. Verify and switch back.
   - Run `git status -sb` and `git log --oneline -3`.
   - Switch back: `git checkout <source_branch>`.
   - Run `git status -sb` again and tell the user whether source is ahead/behind its remote.

## Safety Constraints

- Never use `git reset --hard`, `git checkout --`, force push, or rebase unless the user explicitly requests it.
- Never skip hooks with `--no-verify`.
- Do not push the source branch unless the user asks; only push the target branch for this workflow.
- If uncommitted unrelated changes are present, ask before including them.
- If a command needs network or unrestricted git access, request the needed tool permission and continue.

## Final Response

Report:

- commit hash created on the source branch, if any
- target branch updated
- push result
- final branch after switching back
- any residual ahead/behind status or conflicts
