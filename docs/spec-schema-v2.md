# Spec Schema v2

Enhanced spec format incorporating learnings from agent workflows + oracle planning patterns.

## Full Schema

```yaml
# === METADATA ===
name: feature-name              # Short identifier (no spaces)
description: |                   # What this PR accomplishes
  Multi-line description of what this spec implements.
  Should be clear to someone reviewing the PR.

# === ATOMICITY ===
atomic: true                     # REQUIRED: Each spec = one commit
complexity: 3                    # 1-10 scale (for orchestrator scheduling)
estimated_minutes: 45            # Rough estimate (helps parallel scheduling)

# === DEMO & SPRINT CONTEXT ===
demo_goal: |                     # What this makes demoable at sprint level
  User can now authenticate with Google OAuth and see their profile.
  
sprint_checkpoint: true          # Is this a sprint demo milestone?

# === SKILLS ===
skill_hints:                     # Orchestrator matches to skill-index
  - typescript-patterns
  - react-testing
  - security-best-practices

# === BUILDING ===
building_spec:
  requirements:                  # What to build (specific, technical)
    - Add Google OAuth button to login page
    - Create /api/auth/google/callback route
    - Store OAuth tokens in Prisma database
    - Add GoogleUser type to schema
  
  constraints:                   # Rules to follow
    - Must use existing AuthContext pattern
    - No direct database access (use Prisma only)
    - Follow existing error handling patterns
    - Keep bundle size <5kb increase
  
  files:                         # Where code lives (helps weaver focus)
    - src/components/auth/GoogleButton.tsx
    - src/pages/api/auth/google/**
    - prisma/schema.prisma
  
  dependencies:                  # Task IDs this depends on
    - auth-01-schema             # Must complete before this
  
  test_first:                    # OPTIONAL: Write tests before implementation
    - test: "Google button redirects to OAuth URL"
      file: "src/components/auth/__tests__/GoogleButton.test.tsx"
    - test: "Callback route exchanges code for token"
      file: "src/pages/api/auth/google/__tests__/callback.test.ts"

# === VERIFICATION ===
verification_spec:
  # Deterministic checks first
  - type: command
    name: "typecheck"
    run: "npm run typecheck"
    expect: exit_code 0
  
  - type: command
    name: "tests"
    run: "npm test -- google"
    expect: exit_code 0
  
  - type: file-contains
    path: "src/components/auth/GoogleButton.tsx"
    pattern: "window.location.href.*google.*oauth"
    reason: "OAuth redirect must be implemented"
  
  - type: file-not-contains
    path: "src/"
    pattern: "console.log.*token"
    reason: "No token logging in production"
  
  # Test-first validation (if specified)
  - type: test-first-check
    description: "Verify tests were written before implementation"
    test_files:
      - "src/components/auth/__tests__/GoogleButton.test.tsx"
      - "src/pages/api/auth/google/__tests__/callback.test.ts"
  
  # Agent-based checks (last, non-deterministic)
  - type: agent
    name: "security-review"
    prompt: |
      Review OAuth implementation for security:
      1. No client secret exposed to frontend
      2. PKCE code_verifier generated securely
      3. State parameter validated (CSRF protection)
      4. Tokens stored server-side only
      Report PASS/FAIL with evidence.
  
  # Demo validation (for sprint checkpoints)
  - type: demo
    name: "google-oauth-flow"
    description: "Manual verification of OAuth flow"
    steps:
      - "npm run dev"
      - "Navigate to /login"
      - "Click 'Sign in with Google'"
      - "Complete OAuth flow in popup"
      - "Verify: redirected to dashboard with user profile"
    acceptance: "User can complete full OAuth flow without errors"

# === REVIEW (before weaver execution) ===
review_spec:
  type: subagent                 # Spawn reviewer before building
  model: opus                    # Review uses Opus
  prompt: |
    Review this spec for quality before building:
    
    Check:
    1. Is each requirement atomic (one commit)?
    2. Are tests defined clearly (or validation method)?
    3. Are dependencies identified?
    4. Is demo goal clear and testable?
    5. Are constraints specific (not vague)?
    
    Report PASS or FAIL with specific issues.
  
  accept_criteria:
    - "Requirements are atomic and specific"
    - "Tests or validation method defined"
    - "Dependencies identified (or none)"
    - "Demo goal is testable"

# === PR METADATA ===
pr:
  branch: auth/03-google-oauth
  base: auth/02-password         # Stacked on previous spec
  title: "feat(auth): add Google OAuth login"
  labels:                        # GitHub PR labels
    - auth
    - security
  reviewers:                     # Optional: auto-assign reviewers
    - security-team
```

## Key Changes from v1

### Added Fields

1. **`atomic: true`** - Enforces one-commit rule
2. **`complexity: 1-10`** - Helps orchestrator schedule parallel work
3. **`estimated_minutes`** - Rough time estimate
4. **`demo_goal`** - Sprint-level demoable outcome
5. **`sprint_checkpoint: true`** - Marks sprint milestones
6. **`dependencies`** - Explicit task IDs (not just PR base)
7. **`test_first`** - Write tests before implementation
8. **`review_spec`** - Subagent reviews spec before building

### Enhanced Sections

#### `verification_spec` additions:
- **`test-first-check`** - Validates tests exist
- **`demo`** type - Manual verification with steps
- **`name`** + **`reason`** fields for clarity

#### `building_spec` additions:
- **`test_first`** - List tests to write first
- **`dependencies`** - Task IDs (separate from PR stacking)

### Validation Types

```yaml
validation_type: "tests"         # Default: automated tests
validation_type: "manual"        # Visual/UX verification
validation_type: "demo"          # Sprint checkpoint demo
validation_type: "benchmark"     # Performance validation
```

## Usage in Vertical

### Planner Flow

1. **Gather requirements** (AskUserTool)
2. **Call oracle** with full context
3. **Oracle outputs** plan.md (following this schema)
4. **Planner transforms** plan.md tasks → spec yamls
5. **Review subagent** validates each spec
6. **Orchestrator executes** validated specs

### Orchestrator Scheduling

Uses new fields for smart scheduling:
- **`complexity`** - balance heavy/light tasks
- **`estimated_minutes`** - predict completion
- **`dependencies`** - build execution graph
- **`atomic: true`** - enforce one-commit rule

### Weaver Execution

1. Read spec (all fields)
2. If `test_first` exists, write tests first
3. Implement `building_spec.requirements`
4. Run `verification_spec` checks in order
5. If `demo` type exists, prompt human for manual verification
6. Create PR only after all checks pass

## Migration from v1

Old specs still work. New fields are optional except:
- **`atomic: true`** - should be added to all specs
- **`demo_goal`** - required for sprint checkpoints

## Examples

See:
- `examples/auth-google-oauth.yaml` - Full example above
- `examples/simple-bugfix.yaml` - Minimal spec (no test-first, no demo)
- `examples/sprint-milestone.yaml` - Sprint checkpoint with demo validation
