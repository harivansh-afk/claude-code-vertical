---
description: Check status of plans and weavers. Shows tmux sessions, weaver progress, and PRs.
argument-hint: [plan-id]
---

# /status Command

Check the status of plans and weavers.

## Usage

```
/status                    # All plans
/status plan-20260119-1430 # Specific plan
```

## Output

### All Plans

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

### Specific Plan

```
=== Plan: plan-20260119-1430 ===
Status: running
Started: 2026-01-19T14:35:00Z

=== Specs ===
  01-schema.yaml
  02-backend.yaml
  03-frontend.yaml

=== Weavers ===
  w-01    complete   01-schema.yaml      https://github.com/owner/repo/pull/42
  w-02    verifying  02-backend.yaml     -
  w-03    waiting    03-frontend.yaml    -

=== Tmux Sessions ===
  vertical-plan-20260119-1430-orch    running
  vertical-plan-20260119-1430-w-01    done
  vertical-plan-20260119-1430-w-02    running
```

## Weaver Statuses

| Status | Meaning |
|--------|---------|
| waiting | Waiting for dependency |
| building | Implementing the spec |
| verifying | Running verification checks |
| fixing | Fixing verification failures |
| complete | PR created successfully |
| failed | Failed after max iterations |
| blocked | Dependency failed |

## Quick Commands

```bash
# Source helpers
source lib/tmux.sh

# List all sessions
vertical_list_sessions

# Status for all plans
vertical_status

# Weaver status for a plan
vertical_weaver_status plan-20260119-1430

# Capture recent output from a weaver
vertical_capture_output vertical-plan-20260119-1430-w-01

# Attach to a session
vertical_attach vertical-plan-20260119-1430-w-01
```

## Reading Results

After completion:

```bash
# Summary
cat .claude/vertical/plans/plan-20260119-1430/run/summary.md

# State
cat .claude/vertical/plans/plan-20260119-1430/run/state.json | jq

# Specific weaver
cat .claude/vertical/plans/plan-20260119-1430/run/weavers/w-01.json | jq
```

## PRs Created

When weavers complete, PRs are listed in:
- The summary.md file
- Each weaver's status JSON (`pr` field)
- The overall state.json (`weavers.<id>.pr`)

Merge order is indicated in summary.md for stacked PRs.
