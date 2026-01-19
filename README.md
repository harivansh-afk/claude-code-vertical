# Claude Code Vertical

Scale your Claude Code usage horizontally and vertically.

**Horizontal**: Run multiple planning sessions in parallel
<img width="3600" height="2338" alt="image" src="https://github.com/user-attachments/assets/e37ec8e9-64e4-4aa5-915f-b90eaf014995" />

**Vertical**: Each plan spawns multiple weavers executing specs concurrently
<img width="1978" height="1506" alt="image" src="https://github.com/user-attachments/assets/a8687d18-1529-439a-a513-926846d2f6b6" />

## Installation

Install to any project with a single command:

```bash
# From your project directory
/path/to/claude-code-vertical/install.sh

# Or specify target explicitly
./install.sh /path/to/your/project
```

This creates symlinks in your project's `.claude/` directory:

```
your-project/.claude/
  commands/      -> slash commands (/plan, /build, /status)
  skills/        -> agent skills (planner, orchestrator, weaver, verifier)
  skill-index/   -> library of additional skills
  lib/           -> tmux helpers
  vertical/plans/  -> where your plans live
```

**Prerequisites:**
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- tmux: `brew install tmux`

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
| `/build <plan-id>` | Execute plan via tmux weavers |
| `/status [plan-id]` | Check plan/weaver status |

## Directory Structure

```
claude-code-vertical/
├── CLAUDE.md              # Project instructions
├── skills/
│   ├── planner/           # Interactive planning
│   ├── orchestrator/      # Tmux + weaver management
│   ├── weaver-base/       # Base skill for all weavers
│   └── verifier/          # Verification subagent
├── commands/
│   ├── plan.md
│   ├── build.md
│   └── status.md
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

## Skill Index

The orchestrator matches `skill_hints` from specs to skills in `skill-index/index.yaml`.

Current skills include:
- Swift/iOS development (concurrency, SwiftUI, testing, debugging)
- Build and memory debugging
- Database and networking patterns
- Agent orchestration tools

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
