---
name: oracle
description: Deep planning via Oracle CLI (GPT-5.2 Codex). Use for complex tasks requiring extended thinking (10-60 minutes). Outputs plan.md for planner to transform into specs.
---

# Oracle

Oracle bundles your prompt + codebase files into a single request for GPT-5.2 Codex. Use it when planning is complex and requires deep, extended thinking.

## When to Use Oracle

| Trigger | Why |
|---------|-----|
| 5+ specs needed | Complex dependency management |
| Unclear dependency graph | Needs analysis |
| Architecture decisions | Extended thinking helps |
| Migration planning | Requires careful sequencing |
| Performance optimization | Needs deep code analysis |
| Any planning >10 minutes | Offload to Codex |

## When NOT to Use Oracle

- Simple 1-2 spec tasks
- Clear, linear implementations
- Bug fixes
- Quick refactors

## Prerequisites

Oracle CLI installed:

```bash
npm install -g @steipete/oracle
```

Or use npx:

```bash
npx -y @steipete/oracle --help
```

## Workflow

### Step 1: Craft the Prompt

Write to `/tmp/oracle-prompt.txt`:

```
Create a detailed implementation plan for [TASK].

## Context
- Project: [what the project does]
- Stack: [frameworks, languages, tools]
- Location: [key directories and files]

## Requirements
[ALL requirements gathered from human]
- [Requirement 1]
- [Requirement 2]
- Features needed:
  - [Feature A]
  - [Feature B]
- NOT needed: [explicit out-of-scope]

## Plan Structure

Output as plan.md with this structure:

# Plan: [Task Name]

## Overview
[Summary + recommended approach]

## Phase N: [Phase Name]
### Task N.M: [Task Name]
- Location: [file paths]
- Description: [what to do]
- Dependencies: [task IDs this depends on]
- Complexity: [1-10]
- Acceptance Criteria: [specific, testable]

## Dependency Graph
[Which tasks run parallel vs sequential]

## Testing Strategy
[What tests prove success]

## Instructions
- Write complete plan to plan.md
- Do NOT ask clarifying questions
- Be specific and actionable
- Include file paths and code locations
```

### Step 2: Preview Token Count

```bash
npx -y @steipete/oracle --dry-run summary --files-report \
  -p "$(cat /tmp/oracle-prompt.txt)" \
  --file "src/**" \
  --file "!**/*.test.*" \
  --file "!**/*.snap" \
  --file "!node_modules" \
  --file "!dist"
```

**Target:** <196k tokens

**If over budget:**
- Narrow file selection
- Exclude more test/build directories
- Split into focused prompts

### Step 3: Run Oracle

```bash
npx -y @steipete/oracle \
  --engine browser \
  --model gpt-5.2-codex \
  --slug "vertical-plan-$(date +%Y%m%d-%H%M)" \
  -p "$(cat /tmp/oracle-prompt.txt)" \
  --file "src/**" \
  --file "convex/**" \
  --file "!**/*.test.*" \
  --file "!**/*.snap" \
  --file "!node_modules" \
  --file "!dist"
```

**Why browser engine:**
- GPT-5.2 Codex runs take 10-60 minutes (normal)
- Browser mode handles long runs
- Sessions stored in `~/.oracle/sessions`
- Can reattach if timeout

### Step 4: Monitor

Tell the human:
```
Oracle is running. This typically takes 10-60 minutes.
I will check status periodically.
```

Check status:

```bash
npx -y @steipete/oracle status --hours 1
```

### Step 5: Reattach (if timeout)

If the CLI times out, do NOT re-run. Reattach:

```bash
npx -y @steipete/oracle session <session-id> --render > /tmp/oracle-result.txt
```

### Step 6: Read Output

Oracle writes `plan.md` to current directory. Read it:

```bash
cat plan.md
```

### Step 7: Transform to Specs

Convert Oracle's phases/tasks → spec YAML files:

| Oracle Output | Spec YAML |
|---------------|-----------|
| Phase N | Group of related specs |
| Task N.M | Individual spec file |
| Dependencies | pr.base field |
| Location | building_spec.files |
| Acceptance Criteria | verification_spec |

## File Attachment Patterns

**Include:**
```bash
--file "src/**"
--file "prisma/**"
--file "convex/**"
```

**Exclude:**
```bash
--file "!**/*.test.*"
--file "!**/*.spec.*"
--file "!**/*.snap"
--file "!node_modules"
--file "!dist"
--file "!build"
--file "!coverage"
--file "!.next"
```

**Default ignored:** node_modules, dist, coverage, .git, .turbo, .next, build, tmp

**Size limit:** Files >1MB are rejected

## Prompt Templates

### For Authentication

```
Create a detailed implementation plan for adding authentication.

## Context
- Project: [app name]
- Stack: Next.js, Prisma, PostgreSQL
- Location: src/pages/api/ for API, src/components/ for UI

## Requirements
- Methods: Email/password + Google OAuth
- Roles: Admin and User
- Features: Password reset, email verification
- NOT needed: 2FA, SSO

## Plan Structure
[standard structure]
```

### For API Development

```
Create a detailed implementation plan for building a REST API.

## Context
- Project: [app name]
- Stack: [framework]
- Location: src/api/ for routes

## Requirements
- Resources: [entities]
- Auth: [method]
- Rate limiting: [yes/no]
- NOT needed: [out of scope]

## Plan Structure
[standard structure]
```

### For Migration

```
Create a detailed implementation plan for migrating [from] to [to].

## Context
- Current: [current state]
- Target: [target state]
- Constraints: [downtime, rollback needs]

## Requirements
- Data to migrate: [what]
- Dual-write period: [yes/no]
- Rollback strategy: [required]

## Plan Structure
[standard structure]
```

## Important Rules

1. **One-shot execution** - Oracle doesn't interact, just outputs
2. **Always gpt-5.2-codex** - Use Codex model for coding tasks
3. **File output: plan.md** - Always outputs to current directory
4. **Don't re-run on timeout** - Reattach to session instead
5. **Use --force sparingly** - Only for intentional duplicate runs

## After Oracle Runs

1. Read `plan.md`
2. Review phases and tasks
3. Present breakdown to human for approval
4. Transform to spec YAMLs
5. Continue planner workflow
