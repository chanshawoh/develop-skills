#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  omx-omo-agent-run.sh --tool codex|opencode --repo /path/to/repo --task task-id --prompt-file /tmp/task.prompt.md [--fresh]

Non-interactive launcher for AI coding tools. Stores session state under /tmp/omx-omo-agent-sessions.
EOF
}

tool=""
repo=""
task=""
prompt_file=""
fresh="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) tool="${2:-}"; shift 2 ;;
    --repo) repo="${2:-}"; shift 2 ;;
    --task) task="${2:-}"; shift 2 ;;
    --prompt-file) prompt_file="${2:-}"; shift 2 ;;
    --fresh) fresh="1"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$tool" || -z "$repo" || -z "$task" || -z "$prompt_file" ]]; then
  usage >&2
  exit 2
fi

if [[ "$tool" != "codex" && "$tool" != "opencode" ]]; then
  echo "--tool must be codex or opencode" >&2
  exit 2
fi

if [[ ! -d "$repo" ]]; then
  echo "Repo does not exist: $repo" >&2
  exit 2
fi

if [[ ! -s "$prompt_file" ]]; then
  echo "Prompt file is missing or empty: $prompt_file" >&2
  exit 2
fi

slug="$(printf '%s' "$task" | tr -cs 'A-Za-z0-9_.-' '-' | sed 's/^-//; s/-$//')"
state_dir="/tmp/omx-omo-agent-sessions/$slug"
mkdir -p "$state_dir"
log_file="$state_dir/$tool.$(date +%Y%m%d%H%M%S).jsonl"
last_file="$state_dir/$tool.last.md"
session_file="$state_dir/$tool.session"
continue_file="$state_dir/$tool.continue"

extract_session_id() {
  local file="$1"
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$file" <<'PY' || true
import json, re, sys
path = sys.argv[1]
keys = ("session_id", "sessionId", "sessionID", "thread_id", "threadId", "threadID", "conversation_id", "conversationId", "conversationID")
best = ""
with open(path, "r", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:
            m = None
            if "session" in line.lower() or "thread" in line.lower() or "conversation" in line.lower():
                m = re.search(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", line)
            if m:
                best = m.group(0)
            continue
        stack = [obj]
        while stack:
            cur = stack.pop()
            if isinstance(cur, dict):
                for k, v in cur.items():
                    if k in keys and isinstance(v, str) and v:
                        best = v
                    elif isinstance(v, (dict, list)):
                        stack.append(v)
            elif isinstance(cur, list):
                stack.extend(cur)
if best:
    print(best)
PY
}

run_codex() {
  command -v codex >/dev/null
  codex exec --help >/dev/null
  codex exec resume --help >/dev/null

  if [[ "$fresh" != "1" && -s "$session_file" ]]; then
    session_id="$(cat "$session_file")"
    codex exec resume \
      --dangerously-bypass-approvals-and-sandbox \
      --skip-git-repo-check \
      --json \
      -o "$last_file" \
      "$session_id" \
      - < "$prompt_file" | tee "$log_file"
  else
    codex exec \
      --dangerously-bypass-approvals-and-sandbox \
      -s danger-full-access \
      --skip-git-repo-check \
      --json \
      -o "$last_file" \
      -C "$repo" \
      - < "$prompt_file" | tee "$log_file"
  fi

  new_session="$(extract_session_id "$log_file" | tail -1 || true)"
  if [[ -n "${new_session:-}" ]]; then
    printf '%s\n' "$new_session" > "$session_file"
  fi
}

run_opencode() {
  command -v opencode >/dev/null
  opencode run --help >/dev/null

  mkdir -p "/tmp/opencode-$slug-data" "/tmp/opencode-$slug-cache" "/tmp/opencode-$slug-state"
  export XDG_DATA_HOME="/tmp/opencode-$slug-data"
  export XDG_CACHE_HOME="/tmp/opencode-$slug-cache"
  export XDG_STATE_HOME="/tmp/opencode-$slug-state"

  if [[ "$fresh" != "1" && -s "$session_file" ]]; then
    opencode run \
      --dir "$repo" \
      --format json \
      --print-logs \
      --log-level INFO \
      --dangerously-skip-permissions \
      --session "$(cat "$session_file")" \
      "$(cat "$prompt_file")" | tee "$log_file"
  elif [[ "$fresh" != "1" && -f "$continue_file" ]]; then
    opencode run \
      --dir "$repo" \
      --format json \
      --print-logs \
      --log-level INFO \
      --dangerously-skip-permissions \
      --continue \
      "$(cat "$prompt_file")" | tee "$log_file"
  else
    opencode run \
      --dir "$repo" \
      --format json \
      --print-logs \
      --log-level INFO \
      --dangerously-skip-permissions \
      "$(cat "$prompt_file")" | tee "$log_file"
  fi

  new_session="$(extract_session_id "$log_file" | tail -1 || true)"
  if [[ -n "${new_session:-}" ]]; then
    printf '%s\n' "$new_session" > "$session_file"
  else
    : > "$continue_file"
  fi
}

case "$tool" in
  codex) run_codex ;;
  opencode) run_opencode ;;
esac

echo "omx-omo-agent log: $log_file" >&2
echo "omx-omo-agent last message: $last_file" >&2
