---
description: Start an interactive planning session. Design specs through Q&A, then hand off to build.
argument-hint: [description]
---

# /plan Command

Start a planning session. You become the planner agent.

## Usage

```
/plan
/plan Add user authentication with OAuth
```

## What Happens

1. Load the planner skill from `skills/planner/SKILL.md`
2. Generate a plan ID: `plan-YYYYMMDD-HHMMSS`
3. Create plan directory: `.claude/vertical/plans/<plan-id>/`
4. Enter interactive planning mode

## Planning Flow

1. **Understand** - Ask questions until the task is crystal clear
2. **Research** - Explore the codebase, find patterns
3. **Design** - Break into specs (each = one PR)
4. **Write** - Create spec files in `specs/` directory
5. **Hand off** - Tell user to run `/build <plan-id>`

## Spec Output

Specs go to: `.claude/vertical/plans/<plan-id>/specs/`

```
01-schema.yaml
02-backend.yaml
03-frontend.yaml
```

## Transitioning to Build

When specs are ready:

```
Specs ready. To execute:

  /build <plan-id>

To execute specific specs:

  /build <plan-id> 01-schema 02-backend

To check status:

  /status <plan-id>
```

## Multiple Planning Sessions

You can run multiple planning sessions in parallel:

```
# Terminal 1
/plan Add authentication

# Terminal 2
/plan Add payment processing
```

Each gets its own plan-id and can be built independently.

## Resuming

Planning sessions are Claude Code sessions. Resume with:

```
claude --resume <session-id>
```

The session ID is saved in `.claude/vertical/plans/<plan-id>/meta.json`.
