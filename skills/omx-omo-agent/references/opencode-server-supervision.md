# OpenCode Server Supervision And Closeout

Use when supervising `opencode serve` sessions through the local HTTP API, especially long OMO `/ralph-loop` work.

## Launch Sequence

```bash
# 1. Start server (background)
opencode serve --hostname 127.0.0.1 --port 4096

# 2. Verify server is up
curl -sS http://127.0.0.1:4096/global/health
# => {"healthy":true,"version":"1.14.48"}

# 3. Create session
curl -sS -X POST 'http://127.0.0.1:4096/session?directory=/tmp/worktree' \
  -H 'content-type: application/json' \
  --data '{
    "agent": "Sisyphus - Ultraworker",
    "model": {"providerID":"<provider>","id":"<model>"},
    "title": "Task description",
    "permission": [
      {"permission":"question","pattern":"*","action":"deny"},
      {"permission":"plan_enter","pattern":"*","action":"deny"},
      {"permission":"plan_exit","pattern":"*","action":"deny"}
    ]
  }'
# Returns: {"id":"ses_xxx","slug":"...","directory":"..."}
# Save session ID for subsequent calls

# 4. Send async prompt
curl -sS -X POST \
  'http://127.0.0.1:4096/session/<ses_id>/prompt_async?directory=/tmp/worktree' \
  -H 'content-type: application/json' \
  --data '{
    "agent":"Sisyphus - Ultraworker",
    "model":{"providerID":"<provider>","modelID":"<model>"},
    "parts":[{"type":"text","text":"<prompt text>"}]
  }'
# Returns 204 on success (fire-and-forget, agent starts working)
```

## Key API Endpoints

All endpoints accept `?directory=<url-encoded-path>` for multi-project servers.

| Endpoint | Method | Purpose |
|---|---|---|
| `/global/health` | GET | Health check |
| `/doc` | GET | Full OpenAPI 3.1 spec (JSON) |
| `/session` | POST | Create new session |
| `/session/status` | GET | Map of session_id → `{type: "busy"}` or `{}` |
| `/session/{id}/message` | GET | Messages (newest first); `?limit=N` |
| `/session/{id}/message` | POST | Send prompt (synchronous, blocks) |
| `/session/{id}/prompt_async` | POST | Send prompt (async, returns 204) |
| `/session/{id}/diff` | GET | Array of file diffs with additions/deletions/status |
| `/session/{id}/children` | GET | Sub-agent sessions spawned by this session |
| `/session/{id}/todo` | GET | TODO items with status/priority |
| `/session/{id}/abort` | POST | Abort running session |
| `/question` | GET | Pending user questions (empty = no blocks) |
| `/permission` | GET | Pending permission requests (empty = no blocks) |

## Message Structure

Each message has `info` (role, finish, tokens, model, timestamps) and `parts` array:

- `step-start`: snapshot hash at start of step
- `reasoning`: agent's chain-of-thought text
- `text`: visible output text
- `tool`: tool call with `state.status` (completed/running), `state.input`, `state.output`

Key `finish` values: `stop` (agent done), `tool-calls` (agent called tools, will continue), `None` (still running/in-progress).

## Monitoring Pattern

```python
import urllib.request, urllib.parse, json

sid = 'ses_xxx'
enc = urllib.parse.quote('/tmp/worktree', safe='')
base = 'http://127.0.0.1:4096'

# Status
with urllib.request.urlopen(f'{base}/session/status?directory={enc}') as r:
    status = json.loads(r.read())  # {"ses_xxx": {"type": "busy"}} or {}

# Latest messages
with urllib.request.urlopen(f'{base}/session/{sid}/message?directory={enc}&limit=2') as r:
    msgs = json.loads(r.read())

# Diff (file-level stats + patches)
with urllib.request.urlopen(f'{base}/session/{sid}/diff?directory={enc}') as r:
    diffs = json.loads(r.read())  # [{file, additions, deletions, status, patch}]

# Children (sub-agents)
with urllib.request.urlopen(f'{base}/session/{sid}/children?directory={enc}') as r:
    children = json.loads(r.read())  # [{id, title, agent, summary: {files, additions, deletions}}]

# TODO progress
with urllib.request.urlopen(f'{base}/session/{sid}/todo?directory={enc}') as r:
    todos = json.loads(r.read())  # [{content, status, priority}]

# Pending questions/permissions
with urllib.request.urlopen(f'{base}/question?directory={enc}') as r:
    questions = json.loads(r.read())  # [] if none
```

## Status Is Not Enough

`/session/status` may remain `busy` while work is effectively complete, or become `{}` after OpenCode has stopped tracking the session. Always combine status with message tail, expected artifacts, and worktree/report checks.

Minimum poll:

```bash
sid=$(cat /tmp/<task>-opencode-server-session-id)
enc='<url-encoded-workdir>'

curl -sS "http://127.0.0.1:<port>/session/status?directory=$enc"
curl -sS "http://127.0.0.1:<port>/session/$sid/message?directory=$enc&limit=2"
curl -sS "http://127.0.0.1:<port>/session/$sid/diff?directory=$enc"
curl -sS "http://127.0.0.1:<port>/question?directory=$enc"
curl -sS "http://127.0.0.1:<port>/permission?directory=$enc"
```

Read the last assistant messages for explicit stop/completion text, not just tool-call chatter.

## Detect Completion Despite `busy`

Treat the worker as effectively complete if all are true:

1. Message tail contains a terminal summary (`finish=stop`, `All ... resolved`, `report written`, `BUILD SUCCESS`, etc.).
2. Expected report/test/artifact paths exist and have current mtimes.
3. `question` and `permission` endpoints return empty arrays.
4. Worktree has expected diffs and no new tool activity is needed.

If `/session/status` returns `{}`, confirm artifacts and message tail before reporting completion. `{}` can be normal after the session is no longer active.

## Sub-Agent Monitoring

Sisyphus Ultraworker spawns child sessions (explore, Sisyphus-Junior, etc.). Check children for progress:

- Children with `summary.files=0, additions=0` may still be initializing or stuck.
- Check child message tails for `finish` state.
- Children diff may show work even if parent diff is unchanged (work gets committed to parent worktree).
- Parent TODO list tracks overall task status (`completed`/`in_progress`/`pending`).

## Rate-Limit Retry Pattern

OpenCode server may report `Too Many Requests: Request rate increased too quickly` while still making progress. Do not immediately kill.

1. Back off polling cadence (45-90s).
2. Check expected artifact mtimes and message tail.
3. If messages/artifacts advance, keep supervising.
4. If no changes after the user's wait window, close out from durable artifacts or restart/kill only after preserving reports.

## Report Closeout

If a worker writes an interim report before later background tasks finish, reread and reconcile it after final artifacts appear. Search for stale text such as:

```bash
rg '待补测试|test-gap|唯一未闭合|进行中|Unit tests to be written' <report.md>
```

Patch the report to match final evidence, but do not invent verification: say whether tests were written, run, or only compile-checked.

## Runtime Artifact Check

After OpenCode/OMO finishes, rerun `git status --short`. Directories such as `.sisyphus/` or `.omc/` can be regenerated by the agent after being deleted. Do not claim they are gone solely because an earlier worker deleted them; check at final closeout and either remove/ignore them if authorized or flag them before commit.

## Final User Status

When user asks whether it is stuck or still running, answer with one of:

- running with progress
- running but likely stuck
- complete but server still says busy
- complete and inactive
- needs user decision

Include: session status, latest meaningful message, artifact/report state, and remaining action.
