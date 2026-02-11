---
name: create-pr
description: Creates a feature branch (if needed), commits changes, runs automated code review, and creates a PR with proper description. Use when ready to commit code changes. Enforces the mandatory git workflow and includes automated quality checks.
---

# Create Pull Request Skill

## Overview

This skill enforces the mandatory git workflow for production safety. Direct pushes to main/master trigger automatic deployments and bypass code review, which can break production systems.

**Recurring failures this addresses:**
- Accidentally working on main/master branch
- Pushing directly to protected branches
- Skipping tests before committing
- Creating PRs without running code review
- Committing secrets or temporary files
- Creating PRs targeting wrong base branch (feature branch instead of main)
- Using stale local branches from previous (merged) PRs instead of branching fresh from main
- Creating feature branches from outdated local main (not pulling before branching)
- Forgetting post-creation PR verification checks

**Why this matters:**
- Production deployments trigger automatically from main
- Database migrations are immediately applied
- Direct pushes bypass CI/CD checks and code review
- Repository protection rules exist for critical safety

---

## Critical Rules

**NEVER:**
- ❌ Commit/push directly to main or master
- ❌ Approve or merge PRs (user only)
- ❌ Use `git push --force` to main/master
- ❌ Skip tests or code review
- ❌ Commit secrets, temp files, or debug code

**ALWAYS:**
- ✅ Work in feature branches (create if on main)
- ✅ Run relevant tests before committing
- ✅ Run code review before creating PR
- ✅ Verify staged changes (avoid secrets)
- ✅ Write descriptive commit messages

---

## Workflow

### 1. Verify Git State
**CRITICAL: Always start from a fresh, up-to-date main branch**

- Check current branch name
- **If on an existing feature branch**: STOP and assess - is this a stale branch from a previous PR? Check if branch exists on remote. If remote branch doesn't exist or was already merged, this is a stale branch - do NOT reuse it
- **If on main/master**: Fetch and pull latest before branching (`git fetch origin main && git pull`)
- Create a NEW feature branch with a name matching the current task
- Verify changes exist before proceeding

**Red flags for stale branches:**
- Branch name references old version/issue (e.g., `feat/update-to-v1.2` when updating to v1.3)
- Branch doesn't exist on remote (already merged and deleted)
- Branch is behind main by multiple commits

### 2. Run Tests
**Test strategy based on changes:**
- **Migrations changed**: Run `check_alembic_heads.py` to detect conflicts
- **ETL code changed**: Run targeted regression tests (`test.py --only <importer>`)
- **Refactoring**: Run pytest for golden master comparison
- **All changes**: Run full test suite before final commit

### 3. Automated Code Review
- Invoke code-reviewer agent to catch issues early
- Review findings: Security, best practices, architecture, performance
- Address critical issues before proceeding
- Document findings for PR description

### 4. Commit Changes
**Commit process:**
- Stage specific files (review each, avoid secrets/temp files)
- Verify staged changes with `git diff --staged`
- Write commit message: `<type>: <description>` (feat, fix, refactor, docs, test, chore)
- Keep subject under 72 chars, focus on "why" not "what"
- When Codex materially authored code, append a single co-author trailer per Dariusz Parys' "Should AI Be Listed as a Co-Author in Your Git Commits?" (2025-07-29) to keep provenance clear without extra noise

**Commit message structure:**
```
<type>: <short description>

<detailed explanation of why this change>

Co-Authored-By: codex <223734131+codex@users.noreply.github.com>
```

### 5. Push Feature Branch
- Push with upstream tracking: `git push -u origin <branch-name>`
- Verify push succeeded

### 6. Assess Base Branch & Create Pull Request
**CRITICAL: Determine correct base/destination branch before creating PR**

**Default pattern (most common):**
- ✅ Target `main` (or `master`) for independent fixes/features
- Each PR should merge independently into main

**When to target a different branch:**
- Long-lived feature branch exists for epic/large feature
- Intentional dependency chain (rare, requires justification)
- Release branch workflow (if project uses it)

**Assessment questions:**
- Is this fix/feature independent? → Target main
- Does this depend on unmerged code in another branch? → Verify if dependency is necessary
- Are we building on a long-lived feature branch? → Confirm with user

**PR description includes:**
- Summary (1-3 bullet points)
- Testing checklist (unit, integration, manual)
- Code review findings addressed
- Migration notes (if applicable)
- Related issues (Fixes #123)
- **Formatting warning**: `gh pr create/edit --body "line\nline"` sends literal `\n`. Use real newlines via a here-doc or `--body-file`, then preview with `gh pr view` to confirm rendering.

**Create PR with descriptive title and structured body**

### 7. Final Verification
- View PR to confirm creation
- Check CI status (all checks should trigger)
- Verify no accidental push to main (git log check)

---

## Common Mistakes

### ❌ Working Directly on Main
**Problem**: Committing changes while on main/master branch
**Fix**: Always check branch first, create feature branch if needed

### ❌ Skipping Tests
**Problem**: Committing without running tests, causing CI failures
**Fix**: Run relevant tests before commit (migrations, ETL, pytest)

### ❌ Ignoring Code Review
**Problem**: Not addressing critical security/architecture issues
**Fix**: Run code-reviewer agent, fix critical findings before PR

### ❌ Force Pushing to Main
**Problem**: Using `--force` on protected branches
**Fix**: Never force push to main/master, only to feature branches with `--force-with-lease`

### ❌ "Just This Once" Thinking
**Problem**: Skipping process for "quick fixes" that break production
**Fix**: Process exists for safety - no exceptions

### ❌ Committing Secrets
**Problem**: Accidentally staging .env files, API keys, credentials
**Fix**: Review `git diff --staged` before commit, use .gitignore

### ❌ Vague Commit Messages
**Problem**: Messages like "fix bug" or "update code"
**Fix**: Describe why the change was needed, not just what changed

### ❌ Wrong Base Branch for PR
**Problem**: Creating PR targeting feature branch instead of main, creating unnecessary dependency chain
**Fix**: Always assess destination branch - default is main unless there's a clear reason (long-lived feature branch, intentional dependency). When in doubt, target main.

**Example of mistake:**
- Working on issue #287 (connection pool optimization)
- Branched from `fix/issue-286` to avoid conflicts
- Created PR targeting `fix/issue-286` instead of `main`
- Result: PR #287 can't merge until PR #286 merges (unnecessary dependency)

**Correct approach:**
- Branch from `main` for independent fixes
- Both PRs target `main` independently
- Can merge in any order

### ❌ Reusing Stale Local Branches
**Problem**: Using an existing local branch from a previous (already merged) PR instead of creating a fresh branch from main. Causes merge conflicts because local branch is based on old main.
**Fix**: Always check if the current branch is fresh. Red flags: branch name references old version/task, branch doesn't exist on remote, branch is behind main.
**Detection**: Before reusing any existing feature branch, verify it exists on remote (`git ls-remote --heads origin <branch>`). If it doesn't exist, the PR was likely merged and branch deleted - create a new branch.

**Example of mistake:**
- Local branch `feat/update-metabase-to-v0.57.3` exists from previous PR
- Previous PR was merged and remote branch deleted
- Started working on v0.57.4 update using the stale local branch
- Created PR with merge conflicts because branch was based on old main

### ❌ Branching from Outdated Local Main
**Problem**: Creating feature branch from local main without pulling latest changes first. Local main may be commits behind remote.
**Fix**: ALWAYS run `git fetch origin main && git pull` before creating a new feature branch. Never assume local main is current.
**Detection**: After checkout to main, check `git status` - if it says "behind origin/main", you must pull first.

---



### ❌ Quoted `\n` Strings in PR Body
**Problem**: Running `gh pr edit --body "line1\nline2"` stores literal `\n`, rendering the entire body as a single heading.
**Fix**: Use real newlines (here-doc or `--body-file`) and view the PR afterward to confirm Markdown rendering.

---

## Edge Cases

**Already on feature branch:**
- Continue from step 2 (tests)

**Uncommitted changes on main:**
- Stash changes, create feature branch, pop stash

**PR exists for branch:**
- Add more commits and push (updates existing PR)

**Merge conflicts:**
- Fetch main, rebase, resolve conflicts, push with `--force-with-lease`

**Pre-commit hook changes:**
- Check authorship before amending
- Never amend other developers' commits
- Create new commit if authorship differs

---

## Red Flags (Fail Fast)

- ❌ Current branch is main/master (need to create feature branch)
- ❌ Current feature branch doesn't exist on remote (stale local branch - create fresh)
- ❌ Current feature branch name references old version/task (stale - create fresh)
- ❌ Local main is behind remote (must pull before branching)
- ❌ No changes to commit (empty diff)
- ❌ Tests failing
- ❌ Critical code review findings unresolved
- ❌ Secrets in staged changes
- ❌ Force push to main/master
- ❌ PR targeting feature branch without clear justification
