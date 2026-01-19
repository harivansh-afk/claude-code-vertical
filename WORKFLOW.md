# Claude Code Vertical - Complete Workflow

This document describes the complete multi-agent workflow for Claude Code Vertical.

## Philosophy

This system is **prompt-driven**. Every agent is Claude reading markdown instructions. There is no traditional code—the markdown files ARE the program. Claude's ability to follow instructions precisely makes this possible.

**Key principles:**
- Tight prompts with no ambiguity
- Each agent has a single, focused responsibility
- Context isolation prevents bloat and confusion
- Human remains in control at key decision points

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                 HUMAN                                        │
│                                                                             │
│   You talk to the Planner. Everything else runs in the background.          │
│                                                                             │
│   Commands:                                                                 │
│     /plan              Start planning session                               │
│     /build <plan-id>   Execute plan (spawns orchestrator + weavers)        │
│     /status <plan-id>  Check progress                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ /plan
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PLANNER (Interactive)                              │
│                                                                             │
│   Location: Your terminal (direct Claude session)                           │
│   Skill: skills/planner/SKILL.md                                            │
│                                                                             │
│   Responsibilities:                                                         │
│     • Ask clarifying questions                                              │
│     • Research the codebase                                                 │
│     • Invoke Oracle for complex tasks (optional)                            │
│     • Design specs (each spec = one PR)                                     │
│     • Write specs to .claude/vertical/plans/<plan-id>/specs/               │
│                                                                             │
│   Output: Spec YAML files + meta.json                                       │
│   Handoff: Tells you to run /build <plan-id>                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ /build <plan-id>
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR (tmux background)                        │
│                                                                             │
│   Location: tmux session "vertical-<plan-id>-orch"                          │
│   Skill: skills/orchestrator/SKILL.md                                       │
│                                                                             │
│   Responsibilities:                                                         │
│     • Read specs and analyze dependencies                                   │
│     • Match skill_hints → skill-index                                       │
│     • Launch weavers in parallel tmux sessions                              │
│     • Track progress by polling status files                                │
│     • Launch dependent specs when dependencies complete                     │
│     • Write summary.md when all done                                        │
│                                                                             │
│   Human Interaction: None (runs autonomously)                               │
│   Output: run/state.json, run/summary.md                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
            ▼                        ▼                        ▼
┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐
│    WEAVER 01      │    │    WEAVER 02      │    │    WEAVER 03      │
│                   │    │                   │    │                   │
│ tmux: vertical-   │    │ tmux: vertical-   │    │ tmux: vertical-   │
│   <plan-id>-w-01  │    │   <plan-id>-w-02  │    │   <plan-id>-w-03  │
│                   │    │                   │    │                   │
│ Skill:            │    │ Skill:            │    │ Skill:            │
│  weaver-base +    │    │  weaver-base +    │    │  weaver-base +    │
│  matched skills   │    │  matched skills   │    │  matched skills   │
│                   │    │                   │    │                   │
│ 1. Parse spec     │    │ 1. Parse spec     │    │ 1. (waiting for   │
│ 2. Build code     │    │ 2. Build code     │    │     dependency)   │
│ 3. Spawn verifier │    │ 3. Spawn verifier │    │                   │
│ 4. Fix if failed  │    │ 4. Fix if failed  │    │                   │
│ 5. Create PR      │    │ 5. Create PR      │    │                   │
│                   │    │                   │    │                   │
│ Output: PR #42    │    │ Output: PR #43    │    │                   │
└─────────┬─────────┘    └─────────┬─────────┘    └───────────────────┘
          │                        │
          │ Task tool              │ Task tool
          ▼                        ▼
┌───────────────────┐    ┌───────────────────┐
│    VERIFIER       │    │    VERIFIER       │
│   (subagent)      │    │   (subagent)      │
│                   │    │                   │
│ • Run checks      │    │ • Run checks      │
│ • Fast-fail       │    │ • Fast-fail       │
│ • PASS or FAIL    │    │ • PASS or FAIL    │
└───────────────────┘    └───────────────────┘
```

---

## Complete Workflow

### Phase 1: Planning

**You start a planning session:**

```bash
$ claude
> /plan
```

**What happens:**

1. Claude loads `skills/planner/SKILL.md`
2. Claude generates plan ID: `plan-20260119-143052`
3. Claude creates `.claude/vertical/plans/<plan-id>/specs/` directory
4. Claude asks: "What would you like to build?"

**Interactive Q&A:**

```
Planner: What would you like to build?

You: I want to add user authentication with Google OAuth and email/password.

Planner: Let me understand the requirements better.
         
         1. What's your tech stack?
         
You: Next.js with Prisma and PostgreSQL.

Planner: 2. Do you need role-based access control?

You: Yes, admin and user roles.

Planner: 3. Any specific features?

You: Password reset and email verification.

Planner: Let me research your codebase...
         
         [Reads existing patterns, checks file structure]
         
         I found:
         - Stack: Next.js 14, Prisma, PostgreSQL
         - Existing patterns: Using NextAuth would fit well
         - Files to modify: prisma/schema.prisma, src/pages/api/...
         
         This is a complex task. I'll use Oracle for deep planning.
```

**Oracle (for complex tasks):**

```
Planner: Running Oracle for deep planning...
         This typically takes 10-60 minutes.
         I'll monitor and let you know when ready.
         
         [Oracle runs via browser engine with GPT-5.2 Codex]
         
         ...
         
Planner: Oracle complete. Here's the breakdown:
         
         Phase 1: Schema
           01-schema.yaml - Add User, Session, Account tables
         
         Phase 2: Backend
           02-password-service.yaml - Password hashing with bcrypt
           03-google-oauth.yaml - Google OAuth integration
           04-auth-endpoints.yaml - Login/register/reset endpoints
         
         Phase 3: Frontend
           05-login-ui.yaml - Login page with Google button
         
         Parallel: 01, 02, 03 can run together
         Sequential: 04 waits for 02 and 03; 05 waits for 04
         
         Approve this breakdown? [yes/modify]
```

**Specs written:**

```
Planner: ════════════════════════════════════════════════════════════════
         PLANNING COMPLETE: plan-20260119-143052
         ════════════════════════════════════════════════════════════════
         
         Specs created:
           .claude/vertical/plans/plan-20260119-143052/specs/
             01-schema.yaml
             02-password-service.yaml
             03-google-oauth.yaml
             04-auth-endpoints.yaml
             05-login-ui.yaml
         
         To execute:
           /build plan-20260119-143052
         
         ════════════════════════════════════════════════════════════════
```

### Phase 2: Execution

**You trigger the build:**

```bash
> /build plan-20260119-143052
```

**What happens:**

1. Claude generates orchestrator prompt with plan context
2. Claude launches tmux session: `vertical-plan-20260119-143052-orch`
3. Claude confirms launch and returns control to you

```
════════════════════════════════════════════════════════════════
BUILD LAUNCHED: plan-20260119-143052
════════════════════════════════════════════════════════════════

Orchestrator: vertical-plan-20260119-143052-orch

Monitor commands:
  /status plan-20260119-143052
  tmux attach -t vertical-plan-20260119-143052-orch

Results will be at:
  .claude/vertical/plans/plan-20260119-143052/run/summary.md

════════════════════════════════════════════════════════════════
```

**Behind the scenes (orchestrator):**

```
Orchestrator: Reading specs...
              Found 5 specs.
              
              Dependency analysis:
                01-schema.yaml       → base: main (parallel)
                02-password.yaml     → base: main (parallel)
                03-google-oauth.yaml → base: main (parallel)
                04-endpoints.yaml    → base: feature/password (waits)
                05-login-ui.yaml     → base: feature/endpoints (waits)
              
              Matching skills...
                01 → database-patterns
                02 → security-patterns
                03 → security-patterns
                04 → api-design
                05 → react-patterns
              
              Launching parallel weavers...
                vertical-plan-20260119-143052-w-01 → 01-schema
                vertical-plan-20260119-143052-w-02 → 02-password
                vertical-plan-20260119-143052-w-03 → 03-google-oauth
              
              Polling status...
```

**Behind the scenes (weaver):**

```
Weaver 01: Parsing spec 01-schema.yaml...
           
           Requirements:
             - Add User model to Prisma
             - Add Session model
             - Add Account model for OAuth
           
           Building...
           
           Files created:
             + prisma/schema.prisma (modified)
           
           Spawning verifier...

Verifier:  1. [command] npx prisma validate → PASS
           2. [command] npx prisma generate → PASS
           3. [file-contains] model User → PASS
           
           RESULT: PASS

Weaver 01: Verification passed. Creating PR...
           
           git checkout -b auth/01-schema main
           git add prisma/schema.prisma
           git commit -m "feat(auth): add user authentication schema"
           git push -u origin auth/01-schema
           gh pr create...
           
           PR #42 created.
```

### Phase 3: Monitoring

**You check status periodically:**

```bash
> /status plan-20260119-143052
```

```
=== Plan: plan-20260119-143052 ===
Status: running
Started: 2026-01-19T14:35:00Z

=== Specs ===
  01-schema.yaml
  02-password-service.yaml
  03-google-oauth.yaml
  04-auth-endpoints.yaml
  05-login-ui.yaml

=== Weavers ===
  w-01    complete   01-schema.yaml              PR #42
  w-02    verifying  02-password-service.yaml    -
  w-03    complete   03-google-oauth.yaml        PR #44
  w-04    waiting    04-auth-endpoints.yaml      -
  w-05    waiting    05-login-ui.yaml            -

=== Tmux Sessions ===
  vertical-plan-20260119-143052-orch    running
  vertical-plan-20260119-143052-w-02    running
```

**Optional: Attach to watch:**

```bash
$ tmux attach -t vertical-plan-20260119-143052-w-02
```

### Phase 4: Results

**When complete, the orchestrator outputs:**

```
╔══════════════════════════════════════════════════════════════════╗
║                    BUILD COMPLETE: plan-20260119-143052          ║
╠══════════════════════════════════════════════════════════════════╣
║  ✓ 01-schema          complete     PR #42                        ║
║  ✓ 02-password        complete     PR #43                        ║
║  ✓ 03-google-oauth    complete     PR #44                        ║
║  ✓ 04-endpoints       complete     PR #45                        ║
║  ✓ 05-login-ui        complete     PR #46                        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Summary: .claude/vertical/plans/plan-20260119-143052/run/summary.md
║  PRs:     gh pr list                                             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

**View summary:**

```bash
$ cat .claude/vertical/plans/plan-20260119-143052/run/summary.md

# Build Complete: plan-20260119-143052

**Status**: complete
**Started**: 2026-01-19T14:35:00Z
**Completed**: 2026-01-19T15:12:00Z

## Results

| Spec | Status | PR |
|------|--------|-----|
| 01-schema | ✓ complete | [#42](https://github.com/.../42) |
| 02-password | ✓ complete | [#43](https://github.com/.../43) |
| 03-google-oauth | ✓ complete | [#44](https://github.com/.../44) |
| 04-endpoints | ✓ complete | [#45](https://github.com/.../45) |
| 05-login-ui | ✓ complete | [#46](https://github.com/.../46) |

## PRs Ready for Review

Merge in this order (stacked):
1. #42 - feat(auth): add user authentication schema
2. #43 - feat(auth): add password hashing service
3. #44 - feat(auth): add Google OAuth integration
4. #45 - feat(auth): add authentication endpoints
5. #46 - feat(auth): add login UI

## Commands

```bash
gh pr list
gh pr merge 42 --merge
```
```

**Review and merge PRs:**

```bash
$ gh pr list
$ gh pr view 42
$ gh pr merge 42 --merge
$ gh pr merge 43 --merge
# ... etc
```

---

## Tmux Session Reference

| Session | Purpose | Attach Command |
|---------|---------|----------------|
| `vertical-<plan-id>-orch` | Orchestrator | `tmux attach -t vertical-<plan-id>-orch` |
| `vertical-<plan-id>-w-01` | Weaver 01 | `tmux attach -t vertical-<plan-id>-w-01` |
| `vertical-<plan-id>-w-02` | Weaver 02 | `tmux attach -t vertical-<plan-id>-w-02` |
| ... | ... | ... |

**Detach from tmux:** `Ctrl+B` then `D`

**Helper functions:**

```bash
source lib/tmux.sh

vertical_list_sessions              # List all vertical sessions
vertical_status                     # Show all plans with status
vertical_attach <session>           # Attach to session
vertical_capture_output <session>   # Capture recent output
vertical_kill_plan <plan-id>        # Kill all sessions for plan
vertical_kill_all                   # Kill all vertical sessions
```

---

## Directory Structure

```
.claude/vertical/
  plans/
    plan-20260119-143052/
      meta.json                 # Plan metadata
      specs/
        01-schema.yaml          # Spec files
        02-password.yaml
        ...
      run/
        state.json              # Orchestrator state
        summary.md              # Human-readable summary
        weavers/
          w-01.json             # Weaver 01 status
          w-02.json             # Weaver 02 status
          ...
```

---

## Spec Format

```yaml
name: feature-name
description: |
  What this PR accomplishes.

skill_hints:
  - security-patterns
  - typescript-patterns

building_spec:
  requirements:
    - Specific requirement 1
    - Specific requirement 2
  constraints:
    - Rule to follow
  files:
    - src/path/to/file.ts

verification_spec:
  - type: command
    run: "npm run typecheck"
    expect: exit_code 0
  - type: file-contains
    path: src/path/to/file.ts
    pattern: "expected"

pr:
  branch: feature/name
  base: main
  title: "feat(scope): description"
```

---

## Error Handling

### Weaver Fails After 5 Iterations

The weaver stops and reports failure. The orchestrator:
1. Marks the spec as failed
2. Blocks dependent specs
3. Continues with independent specs
4. Notes failure in summary

**To debug:**

```bash
# Check the error
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json

# Resume the session
claude --resume <session-id>

# Or attach to tmux if still running
tmux attach -t vertical-<plan-id>-w-01
```

### Dependency Failure

If spec A fails and spec B depends on A:
- B is marked as `blocked`
- B is never launched
- Summary notes the blocking

### Killing a Stuck Build

```bash
source lib/tmux.sh
vertical_kill_plan <plan-id>
```

---

## Key Rules

### Tests Are Never Committed

Weavers may write tests during implementation to satisfy verification. But they **never commit test files**:

```bash
# Weaver always runs:
git reset HEAD -- '*.test.*' '*.spec.*' '__tests__/' 'tests/'
```

Tests are ephemeral. They verify the implementation but don't ship.

### PRs Are Always Created

A weaver's success condition is a created PR. No PR = failure.

### Verification Is Mandatory

Weavers must spawn a verifier subagent. They cannot self-verify.

### Context Is Isolated

| Agent | Sees | Doesn't See |
|-------|------|-------------|
| Planner | Full codebase, human input | Weaver implementation |
| Orchestrator | Specs, skill index | Actual code |
| Weaver | Its spec, its skills | Other weavers |
| Verifier | Verification spec | Building requirements |

---

## Parallel Execution

### Multiple Plans

Run multiple planning sessions:

```
Terminal 1: /plan authentication
Terminal 2: /plan payments
Terminal 3: /plan notifications
```

Each creates its own plan ID and executes independently.

### Parallel Weavers

Within a plan, independent specs run in parallel:

```
01-schema.yaml    (base: main) ──┬── parallel
02-backend.yaml   (base: main) ──┤
03-frontend.yaml  (base: feature/backend) ── sequential (waits for 02)
```

---

## Resuming Sessions

Every Claude session can be resumed:

```bash
# Find session ID
cat .claude/vertical/plans/<plan-id>/meta.json | jq -r .planner_session

# Resume
claude --resume <session-id>
```

Weaver sessions are also saved:

```bash
cat .claude/vertical/plans/<plan-id>/run/weavers/w-01.json | jq -r .session_id
claude --resume <session-id>
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `/plan` | Start planning session |
| `/build <plan-id>` | Execute plan |
| `/status <plan-id>` | Check status |
| `tmux attach -t <session>` | Watch a session |
| `Ctrl+B D` | Detach from tmux |
| `source lib/tmux.sh` | Load helper functions |
| `vertical_status` | Show all plans |
| `vertical_kill_plan <id>` | Kill a plan |
| `gh pr list` | List created PRs |
| `gh pr merge <n>` | Merge a PR |
