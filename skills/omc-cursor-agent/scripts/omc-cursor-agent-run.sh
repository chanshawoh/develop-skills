#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  omc-cursor-agent-run.sh --repo /path/to/repo --task task-id --prompt-file /tmp/task.cursor.prompt.md [--fresh] [--model model] [--no-approve-mcps] [--worktree name]

Non-interactive Cursor headless launcher. Stores session state under /tmp/omc-cursor-agent-sessions.
EOF
}

repo=""
task=""
prompt_file=""
fresh="0"
model=""
approve_mcps="1"
worktree=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --task) task="${2:-}"; shift 2 ;;
    --prompt-file) prompt_file="${2:-}"; shift 2 ;;
    --fresh) fresh="1"; shift ;;
    --model) model="${2:-}"; shift 2 ;;
    --no-approve-mcps) approve_mcps="0"; shift ;;
    --worktree) worktree="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$repo" || -z "$task" || -z "$prompt_file" ]]; then
  usage >&2
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

if command -v cursor-agent >/dev/null 2>&1; then
  agent_bin="cursor-agent"
elif command -v agent >/dev/null 2>&1; then
  agent_bin="agent"
else
  echo "Neither cursor-agent nor agent was found on PATH" >&2
  exit 127
fi

"$agent_bin" --help >/dev/null

slug="$(printf '%s' "$task" | tr -cs 'A-Za-z0-9_.-' '-' | sed 's/^-//; s/-$//')"
state_dir="/tmp/omc-cursor-agent-sessions/$slug"
mkdir -p "$state_dir"
log_file="$state_dir/cursor.$(date +%Y%m%d%H%M%S).log"
last_file="$state_dir/cursor.last.txt"
chat_file="$state_dir/cursor.chat"
continue_file="$state_dir/cursor.continue"

extract_chat_id() {
  local file="$1"
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$file" <<'PY' || true
import json, re, sys
path = sys.argv[1]
keys = ("chat_id", "chatId", "chatID", "session_id", "sessionId", "thread_id", "threadId", "id")
best = ""
with open(path, "r", errors="ignore") as f:
    for line in f:
        s = line.strip()
        if not s:
            continue
        try:
            obj = json.loads(s)
        except Exception:
            if any(word in s.lower() for word in ("chat", "session", "thread")):
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

cmd=("$agent_bin" -p --trust --force --sandbox disabled --workspace "$repo")

if [[ "$approve_mcps" == "1" ]]; then
  cmd+=(--approve-mcps)
fi

if [[ -n "$model" ]]; then
  cmd+=(--model "$model")
fi

if [[ -n "$worktree" ]]; then
  cmd+=(-w "$worktree")
fi

if [[ "$fresh" != "1" && -s "$chat_file" ]]; then
  cmd+=(--resume "$(cat "$chat_file")")
elif [[ "$fresh" != "1" && -f "$continue_file" ]]; then
  cmd+=(--continue)
fi

"${cmd[@]}" < "$prompt_file" | tee "$log_file" | tee "$last_file"

new_chat="$(extract_chat_id "$log_file" | tail -1 || true)"
if [[ -n "${new_chat:-}" ]]; then
  printf '%s\n' "$new_chat" > "$chat_file"
else
  : > "$continue_file"
fi

echo "omc-cursor-agent log: $log_file" >&2
echo "omc-cursor-agent last output: $last_file" >&2
