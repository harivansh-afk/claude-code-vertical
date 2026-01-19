---
description: Execute a plan by launching orchestrator and weavers in tmux. Creates PRs for each spec.
argument-hint: <plan-id> [spec-names...]
---

# /build Command

Execute a plan. Launches orchestrator in tmux, which spawns weavers for each spec.

## Usage

```
/build plan-20260119-1430
/build plan-20260119-1430 01-schema 02-backend
```

## What Happens

1. Read plan from `.claude/vertical/plans/<plan-id>/`
2. Launch orchestrator in tmux: `vertical-<plan-id>-orch`
3. Orchestrator reads specs, selects skills, spawns weavers
4. Each weaver runs in tmux: `vertical-<plan-id>-w-01`, etc.
5. Weavers build, verify, create PRs
6. Results written to `.claude/vertical/plans/<plan-id>/run/`

## Execution Flow

```
/build plan-20260119-1430
  |
  +-> Orchestrator (tmux: vertical-plan-20260119-1430-orch)
        |
        +-> Weaver 01 (tmux: vertical-plan-20260119-1430-w-01)
        |     |
        |     +-> Verifier (subagent)
        |     +-> PR #42
        |
        +-> Weaver 02 (tmux: vertical-plan-20260119-1430-w-02)
        |     |
        |     +-> Verifier (subagent)
        |     +-> PR #43
        |
        +-> Summary written to run/summary.md
```

## Parallelization

- Independent specs (all with `pr.base: main`) run in parallel
- Dependent specs (with `pr.base: <other-branch>`) wait for dependencies

## Monitoring

Check status while running:

```
/status plan-20260119-1430
```

Or directly:

```bash
# List tmux sessions
tmux list-sessions | grep vertical

# Attach to orchestrator
tmux attach -t vertical-plan-20260119-1430-orch

# Attach to a weaver
tmux attach -t vertical-plan-20260119-1430-w-01

# Capture weaver output
tmux capture-pane -t vertical-plan-20260119-1430-w-01 -p
```

## Results

When complete, find results at:

- `.claude/vertical/plans/<plan-id>/run/state.json` - Overall status
- `.claude/vertical/plans/<plan-id>/run/summary.md` - Human-readable summary
- `.claude/vertical/plans/<plan-id>/run/weavers/w-*.json` - Per-weaver status

## Debugging Failures

If a weaver fails, you can resume its session:

```bash
# Get session ID from weaver status
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json | jq -r .session_id

# Resume
claude --resume <session-id>
```

Or attach to the tmux session if still running:

```bash
tmux attach -t vertical-<plan-id>-w-01
```

## Killing a Build

```bash
# Kill all sessions for a plan
source lib/tmux.sh
vertical_kill_plan plan-20260119-1430

# Or kill everything
vertical_kill_all
```

## Implementation Notes

This command:
1. Loads orchestrator skill
2. Generates orchestrator prompt with plan context
3. Spawns tmux session with `claude -p "<prompt>" --dangerously-skip-permissions --model opus`
4. Returns immediately (orchestrator runs in background)

The orchestrator handles everything from there.
