#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  opencode-omo-agent-run.sh --repo /path/to/repo --task task-id --prompt-file /tmp/task.prompt.md [--runner opencode|omo] [--slash-command name] [--agent name] [--model provider/model] [--session-id id] [--fresh] [--no-danger] [--port port | --attach url]

Non-interactive OMO/OpenCode launcher. Stores session state under /tmp/opencode-omo-agent-sessions.
EOF
}

runner="opencode"
repo=""
task=""
prompt_file=""
fresh="0"
danger="1"
agent=""
model=""
session_id=""
port=""
attach=""
slash_command=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runner) runner="${2:-}"; shift 2 ;;
    --slash-command) slash_command="${2:-}"; shift 2 ;;
    --repo) repo="${2:-}"; shift 2 ;;
    --task) task="${2:-}"; shift 2 ;;
    --prompt-file) prompt_file="${2:-}"; shift 2 ;;
    --agent) agent="${2:-}"; shift 2 ;;
    --model) model="${2:-}"; shift 2 ;;
    --session-id) session_id="${2:-}"; shift 2 ;;
    --port) port="${2:-}"; shift 2 ;;
    --attach) attach="${2:-}"; shift 2 ;;
    --fresh) fresh="1"; shift ;;
    --no-danger) danger="0"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$runner" != "omo" && "$runner" != "opencode" ]]; then
  echo "--runner must be omo or opencode" >&2
  exit 2
fi

if [[ -z "$repo" || -z "$task" || -z "$prompt_file" ]]; then
  usage >&2
  exit 2
fi

if [[ -n "$port" && -n "$attach" ]]; then
  echo "--port and --attach are mutually exclusive" >&2
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
state_dir="/tmp/opencode-omo-agent-sessions/$slug"
mkdir -p "$state_dir"

find_omo_bin() {
  if command -v oh-my-openagent >/dev/null 2>&1; then
    printf '%s\n' "oh-my-openagent"
  elif command -v oh-my-opencode >/dev/null 2>&1; then
    printf '%s\n' "oh-my-opencode"
  elif command -v omo >/dev/null 2>&1; then
    printf '%s\n' "omo"
  elif command -v bunx >/dev/null 2>&1; then
    printf '%s\n' "bunx oh-my-openagent"
  else
    return 1
  fi
}

extract_session_id() {
  local file="$1"
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$file" <<'PY' || true
import json, re, sys

path = sys.argv[1]
keys = ("session_id", "sessionId", "sessionID", "thread_id", "threadId", "threadID", "conversation_id", "conversationId", "conversationID", "id")
best = ""

with open(path, "r", errors="ignore") as f:
    for line in f:
        s = line.strip()
        if not s:
            continue
        try:
            obj = json.loads(s)
        except Exception:
            if any(word in s.lower() for word in ("session", "thread", "conversation")):
                m = re.search(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", s)
                if not m:
                    m = re.search(r"[A-Za-z0-9_-]{8,}", s)
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

build_prompt() {
  local prompt
  prompt="$(cat "$prompt_file")"
  if [[ -n "$slash_command" ]]; then
    slash_command="${slash_command#/}"
    prompt="/$slash_command $prompt"
  fi
  printf '%s' "$prompt"
}

mkdir -p "/tmp/opencode-omo-$slug-data" "/tmp/opencode-omo-$slug-cache" "/tmp/opencode-omo-$slug-state"
export XDG_DATA_HOME="/tmp/opencode-omo-$slug-data"
export XDG_CACHE_HOME="/tmp/opencode-omo-$slug-cache"
export XDG_STATE_HOME="/tmp/opencode-omo-$slug-state"

run_omo() {
  local omo_bin
  omo_bin="$(find_omo_bin)" || {
    echo "oh-my-openagent, oh-my-opencode, omo, and bunx were not found on PATH" >&2
    return 127
  }

  read -r -a cmd <<< "$omo_bin"
  cmd+=(run --directory "$repo" --no-timestamp)

  if [[ -n "$agent" ]]; then
    cmd+=(--agent "$agent")
  fi

  if [[ -n "$model" ]]; then
    cmd+=(--model "$model")
  fi

  if [[ -n "$port" ]]; then
    cmd+=(--port "$port")
  fi

  if [[ -n "$attach" ]]; then
    cmd+=(--attach "$attach")
  fi

  if [[ "$fresh" != "1" && -n "$session_id" ]]; then
    cmd+=(--session-id "$session_id")
  elif [[ "$fresh" != "1" && -s "$state_dir/omo.session" ]]; then
    cmd+=(--session-id "$(cat "$state_dir/omo.session")")
  fi

  local log_file="$state_dir/omo.$(date +%Y%m%d%H%M%S).log"
  local last_file="$state_dir/omo.last.log"

  "${cmd[@]}" "$(build_prompt)" | tee "$log_file" | tee "$last_file"

  local new_session
  new_session="$(extract_session_id "$log_file" | tail -1 || true)"
  if [[ -n "${new_session:-}" ]]; then
    printf '%s\n' "$new_session" > "$state_dir/omo.session"
  fi

  echo "opencode-omo-agent OMO log: $log_file" >&2
  echo "opencode-omo-agent OMO last output: $last_file" >&2
}

run_raw_opencode() {
  if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode was not found on PATH" >&2
    return 127
  fi

  opencode run --help >/dev/null

  local log_file="$state_dir/opencode.$(date +%Y%m%d%H%M%S).jsonl"
  local last_file="$state_dir/opencode.last.jsonl"
  local session_file="$state_dir/opencode.session"
  local continue_file="$state_dir/opencode.continue"
  local cmd=(opencode run --dir "$repo" --format json --print-logs --log-level INFO)

  if [[ "$danger" == "1" ]]; then
    cmd+=(--dangerously-skip-permissions)
  fi

  if [[ -n "$agent" ]]; then
    cmd+=(--agent "$agent")
  fi

  if [[ -n "$model" ]]; then
    cmd+=(--model "$model")
  fi

  if [[ -n "$port" ]]; then
    cmd+=(--port "$port")
  fi

  if [[ -n "$attach" ]]; then
    cmd+=(--attach "$attach")
  fi

  if [[ "$fresh" != "1" && -n "$session_id" ]]; then
    cmd+=(--session "$session_id")
  elif [[ "$fresh" != "1" && -s "$session_file" ]]; then
    cmd+=(--session "$(cat "$session_file")")
  elif [[ "$fresh" != "1" && -f "$continue_file" ]]; then
    cmd+=(--continue)
  fi

  "${cmd[@]}" "$(build_prompt)" | tee "$log_file" | tee "$last_file"

  local new_session
  new_session="$(extract_session_id "$log_file" | tail -1 || true)"
  if [[ -n "${new_session:-}" ]]; then
    printf '%s\n' "$new_session" > "$session_file"
  else
    : > "$continue_file"
  fi

  echo "opencode-omo-agent raw OpenCode log: $log_file" >&2
  echo "opencode-omo-agent raw OpenCode last output: $last_file" >&2
}

case "$runner" in
  omo) run_omo ;;
  opencode) run_raw_opencode ;;
esac
