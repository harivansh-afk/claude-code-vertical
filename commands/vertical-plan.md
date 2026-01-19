---
description: Start an interactive planning session. Design specs through Q&A with the planner.
argument-hint: [description]
---

# /plan Command

Start a planning session. You become the planner agent.

## Usage

```
/plan
/plan Add user authentication with OAuth
```

## What You Do

When `/plan` is invoked:

### Step 1: Load Planner Skill

Read and internalize `skills/planner/SKILL.md`.

### Step 2: Generate Plan ID

```bash
plan_id="plan-$(date +%Y%m%d-%H%M%S)"
```

### Step 3: Create Plan Directory

```bash
mkdir -p ".claude/vertical/plans/${plan_id}/specs"
mkdir -p ".claude/vertical/plans/${plan_id}/run/weavers"
```

### Step 4: Start Interactive Planning

Follow the planner skill phases:

1. **Understand** - Ask questions until task is crystal clear
2. **Research** - Explore codebase, find patterns
3. **Assess Complexity** - Decide if Oracle is needed
4. **Oracle (optional)** - For complex tasks, invoke Oracle
5. **Design** - Break into specs (each = one PR)
6. **Write** - Create spec YAML files
7. **Hand off** - Tell human to run `/build <plan-id>`

### Step 5: Confirm Plan Ready

When specs are written:

```
════════════════════════════════════════════════════════════════
PLANNING COMPLETE: <plan-id>
════════════════════════════════════════════════════════════════

Specs created:
  .claude/vertical/plans/<plan-id>/specs/
    01-schema.yaml
    02-backend.yaml
    03-frontend.yaml

To execute:
  /build <plan-id>

To check status:
  /status <plan-id>

════════════════════════════════════════════════════════════════
```

## When to Use Oracle

The planner will invoke Oracle for:

| Trigger | Why |
|---------|-----|
| 5+ specs needed | Complex dependency management |
| Unclear dependencies | Need deep analysis |
| Architecture decisions | Needs extended thinking |
| Performance/migration planning | Requires careful sequencing |

Oracle runs via browser engine (10-60 minutes typical).

## Spec Output Location

```
.claude/vertical/plans/<plan-id>/
  meta.json           # Plan metadata
  specs/
    01-schema.yaml    # First spec
    02-backend.yaml   # Second spec
    03-frontend.yaml  # Third spec
```

## Transitioning to Build

When specs are ready, the human runs:

```
/build <plan-id>
```

This launches the orchestrator in tmux, which spawns weavers.

## Multiple Planning Sessions

Run multiple planning sessions in parallel:

```
# Terminal 1
/plan Add authentication

# Terminal 2
/plan Add payment processing

# Terminal 3
/plan Add notification system
```

Each gets its own plan-id and can be built independently.

## Resuming a Planning Session

Planning sessions are Claude Code sessions. Resume with:

```bash
claude --resume <session-id>
```

The session ID is saved in `.claude/vertical/plans/<plan-id>/meta.json`.

## Example Interaction

```
Human: /plan

Claude: Starting plan: plan-20260119-143052
        What would you like to build?