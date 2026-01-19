# Claude Code Vertical

Multi-agent orchestration system for Claude Code. Scale horizontally (multiple planning sessions) and vertically (weavers executing in parallel).

## Architecture

```
You (Terminal)
    |
    v
Planner (interactive)     <- You talk here
    |
    v (specs)
Orchestrator (tmux background)
    |
    +-> Weaver 01 (tmux) -> Verifier (subagent) -> PR
    +-> Weaver 02 (tmux) -> Verifier (subagent) -> PR
    +-> Weaver 03 (tmux) -> Verifier (subagent) -> PR
```

## Commands

| Command | Description |
|---------|-------------|
| `/plan` | Start interactive planning session |
| `/build <plan-id>` | Execute a plan (spawns orchestrator + weavers) |
| `/status [plan-id]` | Check status of plans and weavers |

## Quick Start

```bash
# Start planning
claude
> /plan

# Design your specs interactively...
# When ready, planner tells you the plan-id

# Execute
> /build plan-20260119-1430

# Check status
> /status plan-20260119-1430
```

## Directory Structure

```
.claude/vertical/
  plans/
    <plan-id>/
      meta.json           # Plan metadata
      specs/              # Spec YAML files
        01-schema.yaml
        02-backend.yaml
      run/
        state.json        # Orchestrator state
        summary.md        # Human-readable results
        weavers/
          w-01.json       # Weaver status + session ID
          w-02.json
```

## All Agents Use Opus

Every agent in the system uses `claude-opus-4-5-20250514`:
- Planner
- Orchestrator
- Weavers
- Verifiers (subagents)

## Tmux Session Naming

```
vertical-<plan-id>-orch     # Orchestrator
vertical-<plan-id>-w-01     # Weaver 1
vertical-<plan-id>-w-02     # Weaver 2
```

## Skill Index

Skills live in `skill-index/skills/`. The orchestrator uses `skill-index/index.yaml` to match `skill_hints` from specs to actual skills.

To add a skill:
1. Create `skill-index/skills/<name>/SKILL.md`
2. Add entry to `skill-index/index.yaml`

## Resuming Sessions

Every Claude session can be resumed:

```bash
# Get session ID from weaver status
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json | jq -r .session_id

# Resume
claude --resume <session-id>
```

## Debugging

```bash
# Source helpers
source lib/tmux.sh

# List all sessions
vertical_list_sessions

# Attach to a weaver
vertical_attach vertical-plan-20260119-1430-w-01

# Capture output
vertical_capture_output vertical-plan-20260119-1430-w-01

# Kill a plan's sessions
vertical_kill_plan plan-20260119-1430
```

## Spec Format

```yaml
name: feature-name
description: What this PR accomplishes

skill_hints:
  - relevant-skill-1
  - relevant-skill-2

building_spec:
  requirements:
    - Requirement 1
    - Requirement 2
  constraints:
    - Constraint 1
  files:
    - src/path/to/file.ts

verification_spec:
  - type: command
    run: "npm run typecheck"
    expect: exit_code 0
  - type: file-contains
    path: src/path/to/file.ts
    pattern: "expected pattern"

pr:
  branch: feature/branch-name
  base: main
  title: "feat: description"
```

## Context Isolation

Each agent gets minimal, focused context:

| Agent | Receives | Does NOT Receive |
|-------|----------|------------------|
| Planner | Full codebase, your questions | Weaver implementation |
| Orchestrator | Specs, skill index, status | Actual code |
| Weaver | Spec + skills | Other weavers' work |
| Verifier | Verification spec only | Building requirements |

This prevents context bloat and keeps agents focused.

## Parallel Execution

Multiple planning sessions can run simultaneously:

```
Terminal 1: /plan auth system
Terminal 2: /plan payment system
Terminal 3: /plan notification system
```

Each spawns its own orchestrator and weavers. All run in parallel.

## Weavers Always Create PRs

Weavers follow the eval-skill pattern:
1. Build implementation
2. Spawn verifier subagent
3. Fix on failure (max 5 iterations)
4. Create PR on success

No PR = failure. This is enforced.
