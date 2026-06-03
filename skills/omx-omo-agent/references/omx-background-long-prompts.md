# OMX Background Runs With Long Prompts

Use this when launching OMX/Codex through Hermes for a large spec, review, or orchestration handoff.

## Pattern

1. Put the prompt in a temp file instead of nesting a large heredoc inside the `omx exec` command string.
2. Feed the file on stdin.
3. Run with the assistant's non-interactive process runner or normal shell command capture.

```bash
cat > /tmp/<task>-omx-prompt.txt <<'EOF'
<full prompt>
EOF

omx exec --skip-git-repo-check -C /path/to/repo < /tmp/<task>-omx-prompt.txt
```

For long-running work, capture output to a task log and monitor durable artifacts such as report files, `git status --short`, and `git diff --stat`.

## Why

Large inline command substitutions or heredocs can hit terminal timeout/quoting limits before the agent really starts. A prompt file keeps quoting stable and makes retries visible/reproducible without changing task semantics.

## Pitfalls

- If a direct long inline `omx exec` launch times out before producing durable artifacts, do not keep retrying the same command shape. Switch to prompt-file stdin.
- Keep the prompt file outside the repo unless it is itself a desired artifact.
- This is a launch/quoting workaround, not evidence that OMX failed or that auth/model setup is broken.
