#!/usr/bin/env bash
# Tmux helper functions for claude-code-vertical
# Source this file: source lib/tmux.sh

VERTICAL_PREFIX="vertical"

# Generate a plan ID
vertical_plan_id() {
  echo "plan-$(date +%Y%m%d-%H%M%S)"
}

# Create plan directory structure
vertical_init_plan() {
  local plan_id=$1
  local base_dir="${2:-.claude/vertical}"

  mkdir -p "${base_dir}/plans/${plan_id}/specs"
  mkdir -p "${base_dir}/plans/${plan_id}/run/weavers"

  echo "${base_dir}/plans/${plan_id}"
}

# Spawn orchestrator for a plan
vertical_spawn_orchestrator() {
  local plan_id=$1
  local workdir=$2
  local prompt_file=$3

  local session_name="${VERTICAL_PREFIX}-${plan_id}-orch"

  tmux new-session -d -s "$session_name" -c "$workdir" \
    "claude -p \"\$(cat ${prompt_file})\" --dangerously-skip-permissions --model claude-opus-4-5-20250514; echo 'Session ended. Press any key to close.'; read"

  echo "$session_name"
}

# Spawn a weaver for a spec
vertical_spawn_weaver() {
  local plan_id=$1
  local weaver_num=$2
  local workdir=$3
  local prompt_file=$4

  local session_name="${VERTICAL_PREFIX}-${plan_id}-w-${weaver_num}"

  tmux new-session -d -s "$session_name" -c "$workdir" \
    "claude -p \"\$(cat ${prompt_file})\" --dangerously-skip-permissions --model claude-opus-4-5-20250514; echo 'Session ended. Press any key to close.'; read"

  echo "$session_name"
}

# List all vertical sessions
vertical_list_sessions() {
  tmux list-sessions 2>/dev/null | grep "^${VERTICAL_PREFIX}-" || echo "No active sessions"
}

# List sessions for a specific plan
vertical_list_plan_sessions() {
  local plan_id=$1
  tmux list-sessions 2>/dev/null | grep "^${VERTICAL_PREFIX}-${plan_id}" || echo "No sessions for ${plan_id}"
}

# Check if a session is still running
vertical_session_alive() {
  local session_name=$1
  tmux has-session -t "$session_name" 2>/dev/null && echo "running" || echo "done"
}

# Capture recent output from a session
vertical_capture_output() {
  local session_name=$1
  local lines=${2:-50}

  tmux capture-pane -t "$session_name" -p -S "-${lines}" 2>/dev/null
}

# Attach to a session interactively
vertical_attach() {
  local session_name=$1
  tmux attach -t "$session_name"
}

# Kill a single session
vertical_kill_session() {
  local session_name=$1
  tmux kill-session -t "$session_name" 2>/dev/null
}

# Kill all sessions for a plan
vertical_kill_plan() {
  local plan_id=$1

  # Kill orchestrator
  tmux kill-session -t "${VERTICAL_PREFIX}-${plan_id}-orch" 2>/dev/null

  # Kill all weavers
  for sess in $(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${VERTICAL_PREFIX}-${plan_id}-w-"); do
    tmux kill-session -t "$sess" 2>/dev/null
  done

  echo "Killed all sessions for ${plan_id}"
}

# Kill all vertical sessions
vertical_kill_all() {
  for sess in $(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${VERTICAL_PREFIX}-"); do
    tmux kill-session -t "$sess" 2>/dev/null
  done

  echo "Killed all vertical sessions"
}

# Get status of all plans
vertical_status() {
  local base_dir="${1:-.claude/vertical}"

  echo "=== Active Tmux Sessions ==="
  vertical_list_sessions
  echo ""

  echo "=== Plan Status ==="
  if [ -d "${base_dir}/plans" ]; then
    for plan_dir in "${base_dir}/plans"/*/; do
      if [ -d "$plan_dir" ]; then
        local plan_id=$(basename "$plan_dir")
        local state_file="${plan_dir}run/state.json"

        if [ -f "$state_file" ]; then
          local status=$(jq -r '.status // "unknown"' "$state_file" 2>/dev/null)
          echo "  ${plan_id}: ${status}"
        else
          local meta_file="${plan_dir}meta.json"
          if [ -f "$meta_file" ]; then
            echo "  ${plan_id}: ready (not started)"
          else
            echo "  ${plan_id}: incomplete"
          fi
        fi
      fi
    done
  else
    echo "  No plans found"
  fi
}

# Get weaver status for a plan
vertical_weaver_status() {
  local plan_id=$1
  local base_dir="${2:-.claude/vertical}"
  local weavers_dir="${base_dir}/plans/${plan_id}/run/weavers"

  if [ ! -d "$weavers_dir" ]; then
    echo "No weaver data for ${plan_id}"
    return
  fi

  echo "=== Weavers for ${plan_id} ==="
  for weaver_file in "${weavers_dir}"/*.json; do
    if [ -f "$weaver_file" ]; then
      local weaver_name=$(basename "$weaver_file" .json)
      local status=$(jq -r '.status // "unknown"' "$weaver_file" 2>/dev/null)
      local spec=$(jq -r '.spec // "?"' "$weaver_file" 2>/dev/null)
      local pr=$(jq -r '.pr // "-"' "$weaver_file" 2>/dev/null)

      printf "  %-10s %-15s %-30s %s\n" "$weaver_name" "$status" "$spec" "$pr"
    fi
  done
}

# Generate weaver prompt file
vertical_generate_weaver_prompt() {
  local output_file=$1
  local weaver_base_skill=$2
  local spec_file=$3
  local additional_skills=$4  # space-separated list of skill files

  cat > "$output_file" << 'PROMPT_HEADER'
You are a weaver agent. Execute the spec below.

<weaver-base>
PROMPT_HEADER

  cat "$weaver_base_skill" >> "$output_file"

  cat >> "$output_file" << 'PROMPT_MID1'
</weaver-base>

<spec>
PROMPT_MID1

  cat "$spec_file" >> "$output_file"

  cat >> "$output_file" << 'PROMPT_MID2'
</spec>

PROMPT_MID2

  if [ -n "$additional_skills" ]; then
    echo "<additional-skills>" >> "$output_file"
    for skill_file in $additional_skills; do
      if [ -f "$skill_file" ]; then
        echo "--- $(basename "$skill_file") ---" >> "$output_file"
        cat "$skill_file" >> "$output_file"
        echo "" >> "$output_file"
      fi
    done
    echo "</additional-skills>" >> "$output_file"
  fi

  cat >> "$output_file" << 'PROMPT_FOOTER'

Execute the spec now. Spawn verifier when implementation is complete. Create PR when verification passes.
PROMPT_FOOTER

  echo "$output_file"
}
