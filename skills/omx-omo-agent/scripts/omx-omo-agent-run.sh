#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  omx-omo-agent-run.sh --tool codex|opencode --repo /path/to/repo --task task-id --prompt-file /tmp/task.prompt.md [--fresh] [--no-auto] [--pure] [--model provider/model] [--variant name] [--attach url] [--port number] [--title text] [--file path] [--isolated-state] [--dry-run]

Non-interactive launcher for AI coding tools. Stores session state under /tmp/omx-omo-agent-sessions.
EOF
}

tool=""
repo=""
task=""
prompt_file=""
fresh="0"
auto_approve="1"
pure="0"
model=""
variant=""
attach=""
port=""
title=""
isolated_state="0"
dry_run="0"
files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) tool="${2:-}"; shift 2 ;;
    --repo) repo="${2:-}"; shift 2 ;;
    --task) task="${2:-}"; shift 2 ;;
    --prompt-file) prompt_file="${2:-}"; shift 2 ;;
    --fresh) fresh="1"; shift ;;
    --no-auto|--no-danger) auto_approve="0"; shift ;;
    --pure) pure="1"; shift ;;
    --model) model="${2:-}"; shift 2 ;;
    --variant) variant="${2:-}"; shift 2 ;;
    --attach) attach="${2:-}"; shift 2 ;;
    --port) port="${2:-}"; shift 2 ;;
    --title) title="${2:-}"; shift 2 ;;
    --file) files+=("${2:-}"); shift 2 ;;
    --isolated-state) isolated_state="1"; shift ;;
    --dry-run) dry_run="1"; shift ;;
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
  run_help="$(opencode run --help 2>&1 || true)"
  if [[ -z "$run_help" ]]; then
    echo "Unable to read 'opencode run --help'" >&2
    exit 2
  fi

  run_help_has() {
    grep -q -- "$1" <<<"$run_help"
  }

  require_run_flag() {
    local flag="$1"
    local value="$2"
    if [[ -n "$value" ]] && ! run_help_has "$flag"; then
      echo "Current opencode run does not support $flag. Check 'opencode run --help'." >&2
      exit 2
    fi
  }

  if [[ "$isolated_state" == "1" ]]; then
    mkdir -p "$state_dir/xdg-data" "$state_dir/xdg-cache" "$state_dir/xdg-state" "$state_dir/xdg-config"
    export XDG_DATA_HOME="$state_dir/xdg-data"
    export XDG_CACHE_HOME="$state_dir/xdg-cache"
    export XDG_STATE_HOME="$state_dir/xdg-state"
    export XDG_CONFIG_HOME="$state_dir/xdg-config"
    echo "Using isolated OpenCode XDG state under: $state_dir" >&2
  fi

  if [[ -z "$attach" && -n "${OPENCODE_HOST:-}" ]]; then
    attach="$OPENCODE_HOST"
  fi
  if [[ -z "$port" && -n "${OPENCODE_PORT:-}" ]]; then
    port="$OPENCODE_PORT"
  fi

  cmd=(opencode run)

  if [[ "$auto_approve" == "1" ]]; then
    if run_help_has "--auto"; then
      cmd+=(--auto)
    elif run_help_has "--dangerously-skip-permissions"; then
      cmd+=(--dangerously-skip-permissions)
    else
      echo "Warning: current opencode run exposes no known auto-approval flag; proceeding without one." >&2
    fi
  fi

  cmd+=(--dir "$repo")

  require_run_flag "--format" "1"
  cmd+=(--format json)

  if run_help_has "--print-logs"; then
    cmd+=(--print-logs --log-level INFO)
  fi

  if [[ "$pure" == "1" ]]; then
    require_run_flag "--pure" "1"
    cmd+=(--pure)
  fi
  if [[ -n "$model" ]]; then
    require_run_flag "--model" "$model"
    cmd+=(--model "$model")
  fi
  if [[ -n "$variant" ]]; then
    require_run_flag "--variant" "$variant"
    cmd+=(--variant "$variant")
  fi
  if [[ -n "$attach" ]]; then
    require_run_flag "--attach" "$attach"
    cmd+=(--attach "$attach")
  fi
  if [[ -n "$port" ]]; then
    require_run_flag "--port" "$port"
    cmd+=(--port "$port")
  fi
  if [[ -n "$title" ]]; then
    require_run_flag "--title" "$title"
    cmd+=(--title "$title")
  elif run_help_has "--title"; then
    cmd+=(--title "$task")
  fi
  for file in "${files[@]+"${files[@]}"}"; do
    require_run_flag "--file" "$file"
    if [[ ! -e "$file" ]]; then
      echo "Attached file does not exist: $file" >&2
      exit 2
    fi
    cmd+=(--file "$file")
  done

  prompt="Read the complete task prompt from this local file, then follow it exactly: $prompt_file"

  if [[ "$fresh" != "1" && -s "$session_file" ]]; then
    require_run_flag "--session" "1"
    cmd+=(--session "$(cat "$session_file")")
  elif [[ "$fresh" != "1" && -f "$continue_file" ]]; then
    require_run_flag "--continue" "1"
    cmd+=(--continue)
  fi

  if [[ "$dry_run" == "1" ]]; then
    printf 'command:'
    printf ' %q' "${cmd[@]}"
    printf ' %q\n' "$prompt"
    printf 'message-prefix: %s\n' "${prompt:0:80}"
    exit 0
  fi

  "${cmd[@]}" "$prompt" | tee "$log_file"

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
