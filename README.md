# Claude Code Vertical

Scale your Claude Code usage horizontally and vertically.

**Horizontal**: Run multiple planning sessions in parallel
<img width="3600" height="2338" alt="image" src="https://github.com/user-attachments/assets/e37ec8e9-64e4-4aa5-915f-b90eaf014995" />

**Vertical**: Each plan spawns multiple weavers executing specs concurrently
<img width="1978" height="1506" alt="image" src="https://github.com/user-attachments/assets/a8687d18-1529-439a-a513-926846d2f6b6" />

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/harivansh-afk/claude-code-vertical/main/install.sh | bash
```

Requires: [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code), tmux (`brew install tmux`)

## Quick Start

```bash
# Start a planning session
claude
> /plan

# Design specs interactively with the planner...
# When ready:
> /build plan-20260119-1430

# Check status
> /status plan-20260119-1430
```

## Documentation

| Document | Description |
|----------|-------------|
| [WORKFLOW.md](WORKFLOW.md) | Complete workflow guide with examples |
| [CLAUDE.md](CLAUDE.md) | Project instructions and quick reference |
| [docs/spec-schema-v2.md](docs/spec-schema-v2.md) | Full spec YAML schema |

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
| `/build <plan-id>` | Execute plan via tmux weavers |
| `/status [plan-id]` | Check plan/weaver status |

## Directory Structure

```
claude-code-vertical/
├── CLAUDE.md              # Project instructions
├── WORKFLOW.md            # Complete workflow guide
├── skills/
│   ├── planner/           # Interactive planning
│   ├── orchestrator/      # Tmux + weaver management
│   ├── weaver-base/       # Base skill for all weavers
│   ├── verifier/          # Verification subagent
│   └── oracle/            # Deep planning with GPT-5.2 Codex
├── commands/
│   ├── vertical-plan.md
│   ├── vertical-build.md
│   └── vertical-status.md
├── skill-index/
│   ├── index.yaml         # Skill registry
│   └── skills/            # Available skills
├── lib/
│   └── tmux.sh            # Tmux helper functions
└── .claude/
    └── vertical/
        └── plans/         # Your plans live here
```

## All Agents Use Opus

Every agent uses `claude-opus-4-5-20250514` for maximum capability.

## Key Rules

1. **Tests never ship** - Weavers may write tests for verification, but they're never committed
2. **PRs always created** - Weaver success = PR created
3. **Verification mandatory** - Weavers spawn verifier subagents
4. **Context isolated** - Each agent sees only what it needs

## Skill Index

The orchestrator matches `skill_hints` from specs to skills in `skill-index/index.yaml`.

## Resume Any Session

```bash
# Find session ID
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json | jq -r .session_id

# Resume
claude --resume <session-id>
```

## Tmux Helpers

```bash
source lib/tmux.sh

vertical_status              # Show all plans
vertical_list_sessions       # List tmux sessions
vertical_attach <session>    # Attach to session
vertical_kill_plan <plan-id> # Kill all sessions for a plan
```

## Oracle for Complex Planning

For complex tasks, the planner invokes Oracle (GPT-5.2 Codex) for deep planning:

```bash
npx -y @steipete/oracle --engine browser --model gpt-5.2-codex ...
```

Oracle runs 10-60 minutes and outputs `plan.md`, which the planner transforms into specs.
