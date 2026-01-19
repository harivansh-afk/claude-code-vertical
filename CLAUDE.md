# Claude Code Vertical

Multi-agent orchestration system for Claude Code. Scale horizontally (multiple planning sessions) and vertically (weavers executing in parallel).

**Read the complete workflow:** [WORKFLOW.md](WORKFLOW.md)

## Architecture

```
You (Terminal)
    │
    │ /plan
    ▼
Planner (interactive)     ← You talk here
    │
    │ (writes specs)
    ▼
Orchestrator (tmux background)
    │
    ├─→ Weaver 01 (tmux) → Verifier (subagent) → PR
    ├─→ Weaver 02 (tmux) → Verifier (subagent) → PR
    └─→ Weaver 03 (tmux) → Verifier (subagent) → PR
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
          w-01.json       # Weaver status
          w-02.json
```

## All Agents Use Opus

Every agent uses `claude-opus-4-5-20250514`:
- Planner
- Orchestrator
- Weavers
- Verifiers (subagents)

## Key Rules

### Tests Never Ship

Weavers may write tests for verification. They are **never committed**:
```bash
git reset HEAD -- '*.test.*' '*.spec.*' '__tests__/' 'tests/'
```

### PRs Are Always Created

A weaver's success = PR created. No PR = failure.

### Verification Is Mandatory

Weavers spawn verifier subagents. No self-verification.

### Context Is Isolated

| Agent | Sees | Doesn't See |
|-------|------|-------------|
| Planner | Full codebase, human | Weaver impl |
| Orchestrator | Specs, skill index | Actual code |
| Weaver | Its spec, its skills | Other weavers |
| Verifier | Verification spec | Building spec |

## Tmux Session Naming

```
vertical-<plan-id>-orch     # Orchestrator
vertical-<plan-id>-w-01     # Weaver 1
vertical-<plan-id>-w-02     # Weaver 2
```

## Skill Index

Skills live in `skill-index/skills/`. The orchestrator uses `skill-index/index.yaml` to match `skill_hints` from specs.

## Resuming Sessions

```bash
# Get session ID from weaver status
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json | jq -r .session_id

# Resume
claude --resume <session-id>
```

## Debugging

```bash
source lib/tmux.sh

vertical_list_sessions                           # List all sessions
vertical_attach vertical-plan-20260119-1430-w-01 # Attach to weaver
vertical_capture_output <session> # Capture output
vertical_kill_plan plan-20260119-1430            # Kill plan sessions
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

## Oracle for Complex Planning

For complex tasks (5+ specs, unclear dependencies, architecture decisions), the planner invokes Oracle:

```bash
npx -y @steipete/oracle \
  --engine browser \
  --model gpt-5.2-codex \
  -p "$(cat /tmp/oracle-prompt.txt)" \
  --file "src/**"
```

Oracle takes 10-60 minutes and outputs `plan.md`. The planner transforms this into spec YAMLs.

## Parallel Execution

Multiple planning sessions can run simultaneously:

```
Terminal 1: /plan auth system
Terminal 2: /plan payment system
Terminal 3: /plan notification system
```

Each spawns its own orchestrator and weavers. All run in parallel.
