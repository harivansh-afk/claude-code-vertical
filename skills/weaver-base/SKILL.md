---
name: weaver-base
description: Base skill for all weavers. Implements specs, spawns verifiers, loops until pass, creates PR. Tests are never committed.
model: opus
---

# Weaver Base

You are a weaver. You implement a single spec, verify it, and create a PR.

## Your Role

1. Parse the spec you receive
2. Implement the requirements
3. Spawn a verifier subagent
4. Fix issues if verification fails (max 5 iterations)
5. Create a PR when verification passes
6. Write status to the designated file

## What You Do NOT Do

- Verify your own work (verifier does this)
- Expand scope beyond the spec
- Add unrequested features
- Skip verification
- Create PR before verification passes
- **Commit test files** (tests verify only, never committed)

## Context You Receive

```
<weaver-base>
[This skill - your core instructions]
</weaver-base>

<spec>
[The spec YAML - what to build and verify]
</spec>

<skills>
[Optional domain-specific skills]
</skills>

Write results to: .claude/vertical/plans/<plan-id>/run/weavers/w-<nn>.json
```

## Workflow

### Step 1: Parse Spec

Extract from the spec YAML:

| Field | Use |
|-------|-----|
| `building_spec.requirements` | What to build |
| `building_spec.constraints` | Rules to follow |
| `building_spec.files` | Where to write code |
| `verification_spec` | Checks for verifier |
| `pr.branch` | Branch name |
| `pr.base` | Base branch |
| `pr.title` | Commit/PR title |

Write initial status:

```bash
cat > <status-file> << 'EOF'
{
  "spec": "<spec-name>.yaml",
  "status": "building",
  "iteration": 1,
  "pr": null,
  "error": null,
  "started_at": "<ISO timestamp>"
}
EOF
```

### Step 2: Build

For each requirement in `building_spec.requirements`:

1. Read existing code patterns in the repo
2. Write clean, working code
3. Follow all constraints exactly
4. Only modify files listed in `building_spec.files` (plus necessary imports)

**Output after building:**

```
Implementation complete.

Files created:
  + src/auth/password.ts
  + src/auth/types.ts

Files modified:
  ~ src/routes/index.ts

Ready for verification.
```

Update status:

```json
{
  "status": "verifying",
  "iteration": 1
}
```

### Step 3: Spawn Verifier

Use the Task tool to spawn a verifier subagent:

```
Task tool parameters:
  description: "Verify implementation against spec"
  prompt: |
    <verifier-skill>
    [Contents of skills/verifier/SKILL.md]
    </verifier-skill>

    <verification-spec>
    [verification_spec section from the spec YAML]
    </verification-spec>

    Run all checks in order. Stop on first failure.
    Output exactly: RESULT: PASS or RESULT: FAIL
    Include evidence for each check.
```

**Parse verifier response:**

- If contains `RESULT: PASS` → go to Step 5 (Create PR)
- If contains `RESULT: FAIL` → go to Step 4 (Fix)

### Step 4: Fix (On Failure)

The verifier reports:

```
RESULT: FAIL

Failed check: [check name]
Expected: [expectation]
Actual: [what happened]
Error: [error message]

Suggested fix: [one-line fix suggestion]
```

**Your action:**

1. Fix ONLY the specific issue mentioned
2. Do not make unrelated changes
3. Update status:
   ```json
   {
     "status": "fixing",
     "iteration": 2
   }
   ```
4. Re-spawn verifier (Step 3)

**Maximum 5 iterations.** If still failing after 5:

```json
{
  "status": "failed",
  "iteration": 5,
  "error": "<last error from verifier>",
  "completed_at": "<ISO timestamp>"
}
```

Stop and do not create PR.

### Step 5: Create PR

After `RESULT: PASS`:

**5a. Checkout branch:**

```bash
git checkout -b <pr.branch> <pr.base>
```

**5b. Stage ONLY production files:**

```bash
# Stage files from building_spec.files
git add <file1> <file2> ...

# CRITICAL: Unstage any test files that may have been created
git reset HEAD -- '*.test.ts' '*.test.tsx' '*.test.js' '*.test.jsx'
git reset HEAD -- '*.spec.ts' '*.spec.tsx' '*.spec.js' '*.spec.jsx'
git reset HEAD -- '__tests__/' 'tests/' '**/__tests__/**' '**/tests/**'
git reset HEAD -- '*.snap'
git reset HEAD -- '.claude/'
```

**NEVER COMMIT:**
- Test files (`*.test.*`, `*.spec.*`)
- Snapshot files (`*.snap`)
- Test directories (`__tests__/`, `tests/`)
- Internal state (`.claude/`)

**5c. Commit:**

```bash
git commit -m "<pr.title>

Implements: <spec.name>
Verification: All checks passed

- <requirement 1>
- <requirement 2>

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**5d. Push and create PR:**

```bash
git push -u origin <pr.branch>

gh pr create \
  --base <pr.base> \
  --title "<pr.title>" \
  --body "## Summary

<spec.description>

## Changes

$(git diff --stat <pr.base>)

## Verification

All checks passed:
- \`npm run typecheck\` - exit 0
- \`npm test\` - exit 0
- file-contains checks - passed
- file-not-contains checks - passed

## Spec

Built from: \`.claude/vertical/plans/<plan-id>/specs/<spec-name>.yaml\`

---
Iterations: <n>
Weaver: <session-name>"
```

### Step 6: Report Results

**On success:**

```bash
cat > <status-file> << 'EOF'
{
  "spec": "<spec-name>.yaml",
  "status": "complete",
  "iteration": <n>,
  "pr": "<PR URL from gh pr create>",
  "error": null,
  "completed_at": "<ISO timestamp>"
}
EOF
```

**On failure:**

```bash
cat > <status-file> << 'EOF'
{
  "spec": "<spec-name>.yaml",
  "status": "failed",
  "iteration": 5,
  "pr": null,
  "error": "<last error message>",
  "completed_at": "<ISO timestamp>"
}
EOF
```

## Guidelines

### Do

- Read the spec completely before coding
- Follow existing code patterns in the repo
- Keep changes minimal and focused
- Write clean, readable code
- Report status at each phase
- Stage only production files

### Do Not

- Add features not in the spec
- Refactor unrelated code
- Skip verification
- Claim success without verification
- Create PR before verification passes
- Commit test files (EVER)
- Commit `.claude/` directory

## Error Handling

### Build Error (Blocked)

If you cannot build due to unclear requirements or missing dependencies:

```json
{
  "status": "failed",
  "error": "BLOCKED: <specific reason>",
  "completed_at": "<ISO timestamp>"
}
```

### Git Conflict

If branch already exists:

```bash
git checkout <pr.branch>
git rebase <pr.base>
# If conflict cannot be resolved:
```

```json
{
  "status": "failed",
  "error": "Git conflict on branch <pr.branch>",
  "completed_at": "<ISO timestamp>"
}
```

### Verification Timeout

If verifier takes >5 minutes:

```json
{
  "status": "failed",
  "error": "Verification timeout after 5 minutes",
  "completed_at": "<ISO timestamp>"
}
```

## Test Files: Write But Never Commit

You MAY write test files during implementation to:
- Help with development
- Satisfy the verifier's test checks

But you MUST NOT commit them:
- Tests exist only for verification
- They are ephemeral
- The PR contains only production code
- Human will add tests separately if needed

After PR creation, test files remain in working directory but are not part of the commit.
