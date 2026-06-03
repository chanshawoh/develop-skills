# Codex CLI Non-Interactive Development

Use official OpenAI Codex docs when available, then confirm flags with local help.

Official docs checked while authoring:

- https://www.mintlify.com/openai/codex/advanced/exec-mode
- https://www.mintlify.com/openai/codex/cli/exec

```bash
codex exec --help
codex exec resume --help
```

Known current flags from local help:

- `codex exec [PROMPT]`: non-interactive run.
- `codex exec resume [SESSION_ID] [PROMPT]`: resume a previous non-interactive session.
- `-C, --cd <DIR>`: set repo/workdir.
- `-s, --sandbox danger-full-access`: full filesystem sandbox mode.
- `--dangerously-bypass-approvals-and-sandbox`: skip approvals and sandboxing.
- `--json`: JSONL events.
- `-o, --output-last-message <FILE>`: write final message to a file.

Preferred command shape:

```bash
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  -s danger-full-access \
  --skip-git-repo-check \
  --json \
  -o /tmp/omx-omo-agent-sessions/<task>/codex.last.md \
  -C /path/to/repo \
  - < /tmp/<task>.prompt.md
```

Preferred resume shape:

```bash
codex exec resume \
  --dangerously-bypass-approvals-and-sandbox \
  --json \
  -o /tmp/omx-omo-agent-sessions/<task>/codex.last.md \
  <session-id> \
  - < /tmp/<task>.prompt.md
```

`codex exec resume` resumes the session's recorded context. Do not add `-C` or `-s` unless current `codex exec resume --help` shows those flags. If no session id is known, use `--last` only when the repo/task pairing makes "last" safe. Otherwise start a new session.

Capture session/thread ids from JSONL output when present. If the CLI output shape changes, search the JSONL for fields containing `session`, `thread`, or `conversation`, then persist the id under `/tmp/omx-omo-agent-sessions/<task>/codex.session`.
