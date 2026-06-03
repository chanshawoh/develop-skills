# Merging Worker Worktree Output Into A Dirty Main Worktree

Use when Cursor workers implement in isolated worktrees but the user's main worktree already has unrelated changes.

## Recipe

1. Inspect main worktree first and preserve context:

```bash
git status --short
git diff --name-only
git ls-files --others --exclude-standard
```

2. In the worker worktree, capture tracked changes and untracked files separately. Plain `git diff` omits untracked files.

```bash
git diff --binary > /tmp/worker.patch
git ls-files --others --exclude-standard > /tmp/worker-untracked.txt
```

If untracked files should be part of the patch, either copy them explicitly or mark intent-to-add before diffing:

```bash
git add -N $(git ls-files --others --exclude-standard)
git diff --binary > /tmp/worker-with-untracked.patch
```

3. Check patch against main. If only some files conflict, do not force apply over user changes.

```bash
git apply --check --3way /tmp/worker-with-untracked.patch
```

4. For conflicts in already-dirty files, save the main diff before touching them:

```bash
git diff -- path/to/conflict.java > /tmp/main-existing-conflict.diff
```

5. Apply non-conflicting files by removing conflict file chunks from a temporary patch, then apply normally.

```bash
cp /tmp/worker-with-untracked.patch /tmp/worker-nonconflict.patch
# Remove conflict file sections from /tmp/worker-nonconflict.patch using a small script or editor.
git apply --check /tmp/worker-nonconflict.patch
git apply /tmp/worker-nonconflict.patch
```

6. Manually merge only the needed hunks into conflict files. Keep existing user changes; do not restore worker file wholesale unless user approves.

7. Verify in main worktree, not just worker worktree:

```bash
git diff --check
mvn -pl <module> -am -Dtest='<focused tests>' -Dsurefire.failIfNoSpecifiedTests=false test
mvn -pl <module> -am -DskipTests compile
mvn -pl <module> -am -DskipTests test-compile
```

## Pitfalls

- `git diff --binary` does not include untracked files unless they are intent-to-add or explicitly copied.
- `git apply --check --3way` can report some files apply cleanly and others fail; treat it as diagnostic, not permission to overwrite conflict files.
- Dirty main files may contain user or another-agent changes. Preserve them and merge only the worker's minimal deltas.
- Validate after merge in the destination worktree because worker-green does not prove main-green.
