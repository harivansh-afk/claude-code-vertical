---
description: Execute a plan by launching orchestrator in tmux. Creates PRs for each spec.
argument-hint: <plan-id> [spec-names...]
---

# /build Command

Execute a plan. Launches orchestrator in tmux, which spawns weavers for each spec.

## Usage

```
/build plan-20260119-1430
/build plan-20260119-1430 01-schema 02-backend
```

## What You Do

When `/build <plan-id>` is invoked:

### Step 1: Validate Plan Exists

```bash
if [ ! -f ".claude/vertical/plans/<plan-id>/meta.json" ]; then
  echo "Error: Plan not found: <plan-id>"
  echo "Run /status to see available plans"
  exit 1
fi
```

### Step 2: Generate Orchestrator Prompt

```bash
cat > /tmp/orch-prompt-<plan-id>.md << 'PROMPT_EOF'
<orchestrator-skill>
$(cat skills/orchestrator/SKILL.md)
</orchestrator-skill>

<plan-id><plan-id></plan-id>
<repo-path>$(pwd)</repo-path>

Execute the plan. Spawn weavers. Track progress. Write summary.

Begin now.
PROMPT_EOF
```

### Step 3: Launch Orchestrator in Tmux

```bash
tmux new-session -d -s "vertical-<plan-id>-orch" -c "$(pwd)" \
  "claude -p \"\$(cat /tmp/orch-prompt-<plan-id>.md)\" --dangerously-skip-permissions --model claude-opus-4-5-20250514; echo '[Orchestrator complete. Press any key to close.]'; read"
```

### Step 4: Confirm Launch

Output to human:

```
════════════════════════════════════════════════════════════════
BUILD LAUNCHED: <plan-id>
════════════════════════════════════════════════════════════════

Orchestrator: vertical-<plan-id>-orch

The orchestrator will:
  1. Read specs from .claude/vertical/plans/<plan-id>/specs/
  2. Spawn weavers in parallel tmux sessions
  3. Track progress and handle dependencies
  4. Write summary when complete

Monitor commands:
  /status <plan-id>                              # Check status
  tmux attach -t vertical-<plan-id>-orch         # Watch orchestrator
  tmux list-sessions | grep vertical             # List all sessions

Results will be at:
  .claude/vertical/plans/<plan-id>/run/summary.md

════════════════════════════════════════════════════════════════
```

## Partial Execution

To execute specific specs only:

```
/build plan-20260119-1430 01-schema 02-backend
```

Modify the orchestrator prompt:

```
<specs-to-execute>01-schema, 02-backend</specs-to-execute>
```

The orchestrator will only process those specs.

## Monitoring While Running

### Check Status

```bash
/status <plan-id>
```

### Attach to Orchestrator

```bash
tmux attach -t vertical-<plan-id>-orch
# Detach: Ctrl+B then D
```

### Attach to a Weaver

```bash
tmux attach -t vertical-<plan-id>-w-01
# Detach: Ctrl+B then D
```

### Capture Weaver Output

```bash
tmux capture-pane -t vertical-<plan-id>-w-01 -p -S -100
```

## Results

When complete, find results at:

| File | Contents |
|------|----------|
| `run/state.json` | Overall status and weaver states |
| `run/summary.md` | Human-readable summary with PR links |
| `run/weavers/w-*.json` | Per-weaver status |

## Debugging Failures

### Resume a Failed Weaver

```bash
# Get session ID from weaver status
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json | jq -r .session_id

# Resume
claude --resume <session-id>
```

### Attach to Running Weaver

```bash
tmux attach -t vertical-<plan-id>-w-01
```

## Killing a Build

```bash
# Source helpers
source lib/tmux.sh

# Kill all sessions for this plan
vertical_kill_plan <plan-id>

# Or kill everything
vertical_kill_all
```

## What Happens Behind the Scenes

```
/build plan-20260119-1430
  │
  ├─→ Create orchestrator prompt
  │
  ├─→ Launch tmux: vertical-plan-20260119-1430-orch
  │     │
  │     ├─→ Read specs
  │     ├─→ Analyze dependencies
  │     ├─→ Launch weavers in parallel
  │     │     │
  │     │     ├─→ vertical-plan-20260119-1430-w-01
  │     │     │     └─→ Build → Verify → PR #42
  │     │     │
  │     │     ├─→ vertical-plan-20260119-1430-w-02
  │     │     │     └─→ Build → Verify → PR #43
  │     │     │
  │     │     └─→ (waits for dependencies...)
  │     │
  │     ├─→ Poll weaver status
  │     ├─→ Launch dependent specs when ready
  │     └─→ Write summary.md
  │
  └─→ Human runs /status to check progress
```
