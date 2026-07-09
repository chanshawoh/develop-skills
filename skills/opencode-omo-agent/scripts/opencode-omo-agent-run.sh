#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  opencode-omo-agent-run.sh --repo /path/to/repo --task task-id --prompt-file /tmp/task.prompt.md [--slash-command name] [--inline-prompt] [--allow-nested-launch] [--no-auto] [--json] [--print-logs] [--agent name] [--model provider/model] [--variant name] [--attach url] [--port number] [--title text] [--file path] [--pure] [--isolated-state] [--dry-run]
  opencode-omo-agent-run.sh --repo /path/to/repo --task task-id --smoke-test [same OpenCode options]

Simple non-interactive OpenCode+OMO launcher. Stores logs under /tmp/opencode-omo-agent-sessions.
EOF
}

repo=""
task=""
prompt_file=""
slash_command=""
auto_approve="1"
json_output="0"
print_logs="0"
agent=""
model=""
variant=""
attach=""
port=""
title=""
dry_run="0"
inline_prompt="0"
allow_nested_launch="0"
pure="0"
isolated_state="0"
smoke_test="0"
files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --task) task="${2:-}"; shift 2 ;;
    --prompt-file) prompt_file="${2:-}"; shift 2 ;;
    --slash-command) slash_command="${2:-}"; shift 2 ;;
    --no-auto|--no-danger) auto_approve="0"; shift ;;
    --json) json_output="1"; shift ;;
    --print-logs) print_logs="1"; shift ;;
    --agent) agent="${2:-}"; shift 2 ;;
    --model) model="${2:-}"; shift 2 ;;
    --variant) variant="${2:-}"; shift 2 ;;
    --attach) attach="${2:-}"; shift 2 ;;
    --port) port="${2:-}"; shift 2 ;;
    --title) title="${2:-}"; shift 2 ;;
    --file) files+=("${2:-}"); shift 2 ;;
    --pure) pure="1"; shift ;;
    --isolated-state) isolated_state="1"; shift ;;
    --smoke-test) smoke_test="1"; shift ;;
    --dry-run) dry_run="1"; shift ;;
    --inline-prompt) inline_prompt="1"; shift ;;
    --allow-nested-launch) allow_nested_launch="1"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$repo" || -z "$task" ]]; then
  usage >&2
  exit 2
fi

if [[ ! -d "$repo" ]]; then
  echo "Repo does not exist: $repo" >&2
  exit 2
fi

slug="$(printf '%s' "$task" | tr -cs 'A-Za-z0-9_.-' '-' | sed 's/^-//; s/-$//')"
state_dir="/tmp/opencode-omo-agent-sessions/$slug"
mkdir -p "$state_dir"
log_file="$state_dir/opencode.$(date +%Y%m%d%H%M%S).log"
last_file="$state_dir/opencode.last.log"
smoke_report_file="$state_dir/smoke-report.md"

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

write_smoke_prompt() {
  local prompt_path="$1"
  mkdir -p "$(dirname "$prompt_path")"
  cat > "$prompt_path" <<EOF
You are an OMO/OpenCode smoke-test worker.

Purpose: verify the opencode-omo-agent launcher can start, read a prompt file, inspect routing state, and write one bounded report without modifying repository files.

Repo/workdir: $repo
Allowed write scope: $smoke_report_file only.
Forbidden: editing repo files, creating repo-local artifacts, committing, pushing, deploying, starting another opencode run, invoking opencode-omo-agent-run.sh except for the help command below, or starting another OMO slash loop.

Run these checks from the repo/workdir and capture the important output:
1. pwd
2. git status --short
3. git branch --show-current
4. If either git command reports "not a git repository", run this aggregate-workspace discovery and classify the root as aggregate/non-git instead of treating it as a fatal failure:
   find "$repo" -maxdepth 3 \( -name .git -type d -o -name .git -type f \) -print
5. "$script_path" --help
6. git diff --stat || true
7. git ls-files --others --exclude-standard | head -40 || true

Write exactly one report to:
$smoke_report_file

Report format:
- Summary
- Current directory
- Git classification: git repo, aggregate workspace with sub-repos, or non-git workspace
- Git roots found when aggregate/non-git discovery ran
- Launcher help result
- Duplicate skill/plugin warnings observed, if any, and whether they were blocking
- Files changed or created; this should list only $smoke_report_file
- Risks or blockers

Do not change any other file.
EOF
}

if [[ "$smoke_test" == "1" ]]; then
  if [[ -n "$slash_command" ]]; then
    echo "--smoke-test cannot be combined with --slash-command; smoke mode must not start OMO loops." >&2
    exit 2
  fi
  if [[ -z "$prompt_file" ]]; then
    prompt_file="$state_dir/smoke.prompt.md"
  fi
  write_smoke_prompt "$prompt_file"
  title="${title:-$task-smoke}"
fi

if [[ -z "$prompt_file" ]]; then
  usage >&2
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

if [[ -z "$attach" && -n "${OPENCODE_HOST:-}" ]]; then
  attach="$OPENCODE_HOST"
fi
if [[ -z "$port" && -n "${OPENCODE_PORT:-}" ]]; then
  port="$OPENCODE_PORT"
fi

if [[ "$inline_prompt" == "1" ]]; then
  prompt="$(cat "$prompt_file")"
else
  prompt="Read the complete task prompt from this local file, then follow it exactly: $prompt_file"
fi
if [[ "$allow_nested_launch" != "1" ]]; then
  if [[ "$smoke_test" == "1" ]]; then
    worker_guard="You are the already-launched OMO/OpenCode worker for this task. Do the repository work directly in this OpenCode session. Do not invoke opencode-omo-agent-run.sh except when this smoke-test prompt explicitly asks you to run it with --help, do not run opencode run to start another worker, and do not start another /ralph-loop, /ulw-loop, /start-work, or other OMO slash command from inside this task. Treat any instructions about launching OMO/OpenCode as commander-only context, not worker instructions."
  else
    worker_guard="You are the already-launched OMO/OpenCode worker for this task. Do the repository work directly in this OpenCode session. Do not invoke opencode-omo-agent-run.sh, do not run opencode run to start another worker, and do not start another /ralph-loop, /ulw-loop, /start-work, or other OMO slash command from inside this task. Treat any instructions about launching OMO/OpenCode as commander-only context, not worker instructions."
  fi
  prompt="$worker_guard $prompt"
fi
if [[ -n "$slash_command" ]]; then
  slash_command="${slash_command#/}"
  prompt="/$slash_command $prompt"
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

if [[ "$pure" == "1" ]]; then
  require_run_flag "--pure" "1"
  cmd+=(--pure)
fi

if [[ "$json_output" == "1" ]]; then
  require_run_flag "--format" "1"
  cmd+=(--format json)
fi

if [[ "$print_logs" == "1" ]]; then
  require_run_flag "--print-logs" "1"
  cmd+=(--print-logs --log-level INFO)
fi

if [[ -n "$agent" ]]; then
  require_run_flag "--agent" "$agent"
  cmd+=(--agent "$agent")
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

if [[ "$dry_run" == "1" ]]; then
  printf 'command:'
  printf ' %q' "${cmd[@]}"
  printf ' %q\n' "$prompt"
  printf 'message-prefix: %s\n' "${prompt:0:80}"
  if [[ "$smoke_test" == "1" ]]; then
    printf 'smoke-prompt: %s\n' "$prompt_file"
    printf 'smoke-report: %s\n' "$smoke_report_file"
  fi
  exit 0
fi

if [[ "$isolated_state" == "1" ]]; then
  mkdir -p "$state_dir/xdg-data" "$state_dir/xdg-cache" "$state_dir/xdg-state" "$state_dir/xdg-config"
  export XDG_DATA_HOME="$state_dir/xdg-data"
  export XDG_CACHE_HOME="$state_dir/xdg-cache"
  export XDG_STATE_HOME="$state_dir/xdg-state"
  export XDG_CONFIG_HOME="$state_dir/xdg-config"
  echo "Using isolated OpenCode XDG state under: $state_dir" >&2
fi

if [[ "$smoke_test" == "1" ]]; then
  echo "OpenCode/OMO smoke test prompt: $prompt_file" >&2
  echo "OpenCode/OMO smoke test report: $smoke_report_file" >&2
fi

"${cmd[@]}" "$prompt" | tee "$log_file" | tee "$last_file"

echo "opencode-omo-agent log: $log_file" >&2
echo "opencode-omo-agent last output: $last_file" >&2
