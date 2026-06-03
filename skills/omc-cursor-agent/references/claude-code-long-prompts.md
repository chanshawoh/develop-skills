# Claude Code Brain Runs With Long Prompts

Use this when launching the OMC Claude Code brain (native subagent or headless `claude -p`) for a large spec, review, or orchestration handoff.

## Pattern

1. Put the prompt in a temp file instead of nesting a large heredoc inside the `claude -p` command string.
2. Feed the file on stdin.
3. Run with the assistant's non-interactive process runner or normal shell command capture.

```bash
cat > /tmp/<project-name>/<task-id>/claude.prompt.md <<'EOF'
<full prompt>
EOF

claude -p --permission-mode acceptEdits --add-dir /path/to/repo < /tmp/<project-name>/<task-id>/claude.prompt.md
```

For native subagent delegation, pass the same prompt body to the Task tool instead of stdin; the temp file still helps you keep a durable, reproducible copy of large prompts.

For long-running work, capture output to a task log and monitor durable artifacts such as report files, `git status --short`, and `git diff --stat`.

## Why

Large inline command substitutions or heredocs can hit terminal timeout/quoting limits before the agent really starts. A prompt file keeps quoting stable and makes retries visible/reproducible without changing task semantics.

## Pitfalls

- If a direct long inline `claude -p` launch times out before producing durable artifacts, do not keep retrying the same command shape. Switch to prompt-file stdin.
- Keep the prompt file outside the repo unless it is itself a desired artifact.
- This is a launch/quoting workaround, not evidence that Claude Code failed or that auth/model setup is broken.
