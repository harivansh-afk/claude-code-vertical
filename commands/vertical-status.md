---
description: Check status of plans and weavers. Shows tmux sessions, weaver progress, and PRs.
argument-hint: [plan-id]
---

# /status Command

Check the status of plans and weavers.

## Usage

```
/status                     # All plans
/status plan-20260119-1430  # Specific plan
```

## What You Do

When `/status` is invoked:

### Without Arguments (All Plans)

```bash
# List active tmux sessions
echo "=== Active Tmux Sessions ==="
tmux list-sessions 2>/dev/null | grep "^vertical-" || echo "No active sessions"
echo ""

# List plan statuses
echo "=== Plan Status ==="
if [ -d ".claude/vertical/plans" ]; then
  for plan_dir in .claude/vertical/plans/*/; do
    if [ -d "$plan_dir" ]; then
      plan_id=$(basename "$plan_dir")
      state_file="${plan_dir}run/state.json"
      
      if [ -f "$state_file" ]; then
        status=$(jq -r '.status // "unknown"' "$state_file" 2>/dev/null)
        echo "  ${plan_id}: ${status}"
      else
        meta_file="${plan_dir}meta.json"
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
```

Output:

```
=== Active Tmux Sessions ===
vertical-plan-20260119-1430-orch
vertical-plan-20260119-1430-w-01
vertical-plan-20260119-1430-w-02
vertical-plan-20260119-1445-orch

=== Plan Status ===
  plan-20260119-1430: running
  plan-20260119-1445: running
  plan-20260119-1400: complete
```

### With Plan ID (Specific Plan)

```bash
plan_id="$1"
plan_dir=".claude/vertical/plans/${plan_id}"

# Validate plan exists
if [ ! -d "$plan_dir" ]; then
  echo "Error: Plan not found: ${plan_id}"
  exit 1
fi

# Read state
state_file="${plan_dir}/run/state.json"
if [ -f "$state_file" ]; then
  status=$(jq -r '.status // "unknown"' "$state_file")
  started=$(jq -r '.started_at // "-"' "$state_file")
else
  status="ready (not started)"
  started="-"
fi

echo "=== Plan: ${plan_id} ==="
echo "Status: ${status}"
echo "Started: ${started}"
echo ""

# List specs
echo "=== Specs ==="
for spec in "${plan_dir}/specs/"*.yaml; do
  [ -f "$spec" ] && echo "  $(basename "$spec")"
done
echo ""

# List weaver status
echo "=== Weavers ==="
weavers_dir="${plan_dir}/run/weavers"
if [ -d "$weavers_dir" ]; then
  for weaver_file in "${weavers_dir}"/*.json; do
    if [ -f "$weaver_file" ]; then
      w_name=$(basename "$weaver_file" .json)
      w_status=$(jq -r '.status // "unknown"' "$weaver_file" 2>/dev/null)
      w_spec=$(jq -r '.spec // "?"' "$weaver_file" 2>/dev/null)
      w_pr=$(jq -r '.pr // "-"' "$weaver_file" 2>/dev/null)
      printf "  %-10s %-15s %-30s %s\n" "$w_name" "$w_status" "$w_spec" "$w_pr"
    fi
  done
else
  echo "  No weavers yet"
fi
echo ""

# List tmux sessions for this plan
echo "=== Tmux Sessions ==="
tmux list-sessions 2>/dev/null | grep "vertical-${plan_id}" | while read line; do
  session_name=$(echo "$line" | cut -d: -f1)
  echo "  ${session_name}"
done || echo "  No active sessions"
```

Output:

```
=== Plan: plan-20260119-1430 ===
Status: running
Started: 2026-01-19T14:35:00Z

=== Specs ===
  01-schema.yaml
  02-backend.yaml
  03-frontend.yaml

=== Weavers ===
  w-01       complete        01-schema.yaml                 https://github.com/...
  w-02       verifying       02-backend.yaml                -
  w-03       waiting         03-frontend.yaml               -

=== Tmux Sessions ===
  vertical-plan-20260119-1430-orch
  vertical-plan-20260119-1430-w-01
  vertical-plan-20260119-1430-w-02
```

## Weaver Status Reference

| Status | Meaning |
|--------|---------|
| waiting | Waiting for dependency to complete |
| building | Implementing the spec |
| verifying | Running verification checks |
| fixing | Fixing verification failures |
| complete | PR created successfully |
| failed | Failed after max iterations |
| blocked | Dependency failed |
| crashed | Session terminated unexpectedly |

## Quick Actions

Based on status, suggest actions:

| Status | Suggested Action |
|--------|------------------|
| complete | `gh pr list` to review PRs |
| running | `tmux attach -t <session>` to watch |
| failed | `claude --resume <session-id>` to debug |
| ready | `/build <plan-id>` to start |

## Viewing Results

```bash
# Summary (after completion)
cat .claude/vertical/plans/<plan-id>/run/summary.md

# State JSON
cat .claude/vertical/plans/<plan-id>/run/state.json | jq

# Specific weaver
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json | jq

# List PRs
gh pr list
```

## Tmux Helper Commands

```bash
# Source helpers
source lib/tmux.sh

# List all vertical sessions
vertical_list_sessions

# Full status
vertical_status

# Weaver status for a plan
vertical_weaver_status plan-20260119-1430

# Capture recent output
vertical_capture_output vertical-plan-20260119-1430-w-01

# Attach to a session
vertical_attach vertical-plan-20260119-1430-w-01
```
