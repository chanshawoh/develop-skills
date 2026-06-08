#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  opencode-omo-agent-run.sh --repo /path/to/repo --task task-id --prompt-file /tmp/task.prompt.md [--slash-command name] [--inline-prompt] [--allow-nested-launch] [--no-danger] [--json] [--print-logs] [--agent name] [--model provider/model] [--dry-run]

Simple non-interactive OpenCode+OMO launcher. Stores logs under /tmp/opencode-omo-agent-sessions.
EOF
}

repo=""
task=""
prompt_file=""
slash_command=""
danger="1"
json_output="0"
print_logs="0"
agent=""
model=""
dry_run="0"
inline_prompt="0"
allow_nested_launch="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --task) task="${2:-}"; shift 2 ;;
    --prompt-file) prompt_file="${2:-}"; shift 2 ;;
    --slash-command) slash_command="${2:-}"; shift 2 ;;
    --no-danger) danger="0"; shift ;;
    --json) json_output="1"; shift ;;
    --print-logs) print_logs="1"; shift ;;
    --agent) agent="${2:-}"; shift 2 ;;
    --model) model="${2:-}"; shift 2 ;;
    --dry-run) dry_run="1"; shift ;;
    --inline-prompt) inline_prompt="1"; shift ;;
    --allow-nested-launch) allow_nested_launch="1"; shift ;;
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

if ! command -v opencode >/dev/null 2>&1; then
  echo "opencode was not found on PATH" >&2
  exit 127
fi

if [[ "$dry_run" != "1" ]]; then
  opencode run --help >/dev/null
fi

slug="$(printf '%s' "$task" | tr -cs 'A-Za-z0-9_.-' '-' | sed 's/^-//; s/-$//')"
state_dir="/tmp/opencode-omo-agent-sessions/$slug"
mkdir -p "$state_dir"
log_file="$state_dir/opencode.$(date +%Y%m%d%H%M%S).log"
last_file="$state_dir/opencode.last.log"

if [[ "$inline_prompt" == "1" ]]; then
  prompt="$(cat "$prompt_file")"
else
  prompt="Read the complete task prompt from this local file, then follow it exactly: $prompt_file"
fi
if [[ "$allow_nested_launch" != "1" ]]; then
  worker_guard="You are the already-launched OMO/OpenCode worker for this task. Do the repository work directly in this OpenCode session. Do not invoke opencode-omo-agent-run.sh, do not run opencode run to start another worker, and do not start another /ralph-loop, /ulw-loop, /start-work, or other OMO slash command from inside this task. Treat any instructions about launching OMO/OpenCode as commander-only context, not worker instructions."
  prompt="$worker_guard $prompt"
fi
if [[ -n "$slash_command" ]]; then
  slash_command="${slash_command#/}"
  prompt="/$slash_command $prompt"
fi

cmd=(opencode run)

if [[ "$danger" == "1" ]]; then
  cmd+=(--dangerously-skip-permissions)
fi

cmd+=(--dir "$repo")

if [[ "$json_output" == "1" ]]; then
  cmd+=(--format json)
fi

if [[ "$print_logs" == "1" ]]; then
  cmd+=(--print-logs --log-level INFO)
fi

if [[ -n "$agent" ]]; then
  cmd+=(--agent "$agent")
fi

if [[ -n "$model" ]]; then
  cmd+=(--model "$model")
fi

if [[ "$dry_run" == "1" ]]; then
  printf 'command:'
  printf ' %q' "${cmd[@]}"
  printf ' %q\n' "$prompt"
  printf 'message-prefix: %s\n' "${prompt:0:80}"
  exit 0
fi

"${cmd[@]}" "$prompt" | tee "$log_file" | tee "$last_file"

echo "opencode-omo-agent log: $log_file" >&2
echo "opencode-omo-agent last output: $last_file" >&2
