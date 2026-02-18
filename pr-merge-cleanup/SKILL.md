---
name: pr-merge-cleanup
description: Clean local and remote branch/worktree state after a pull request is already merged, then return repository state to updated main/master. Use only for post-merge cleanup. Do not use to review PR code, address feedback, create new PRs, or perform merge actions.
---

# PR Merge Cleanup

## Overview

This skill performs safe, repeatable cleanup after a pull request is merged.

**Recurring failures this addresses:**
- Deleting branches before confirming the PR is actually merged
- Leaving stale local branches and worktrees around
- Staying on a feature branch after merge
- Forgetting to refresh local `main`
- Accidental deletion of the wrong branch

**Why this matters:**
- Prevents data loss and accidental branch deletion
- Keeps local repositories predictable and clean
- Reduces branch/worktree drift over time

## Critical Rules

**NEVER:**
- ❌ Merge PRs on behalf of the user (do not run `gh pr merge` in this workflow)
- ❌ Delete branches until merged state is verified
- ❌ Delete `main`, `master`, or the PR base branch
- ❌ Force-delete unrelated worktrees
- ❌ Pull with unresolved local conflicts or a dirty worktree unless explicitly requested

**ALWAYS:**
- ✅ Resolve the PR first (number/URL/current branch)
- ✅ Verify merged state from GitHub before cleanup
- ✅ Delete only the PR head branch and stale local artifacts
- ✅ End on local `main` (or `master` fallback) and update it

## Companion Script

Preferred execution path:
- Run `scripts/cleanup_pr.sh` from inside the target repository.
- Pass a PR number or URL; omit it to infer the PR from the current branch.
- The script enforces merged-only cleanup and never merges PRs.

Examples:
```bash
scripts/cleanup_pr.sh 123
scripts/cleanup_pr.sh https://github.com/owner/repo/pull/123
scripts/cleanup_pr.sh
```

## Workflow

### 1. Resolve PR Context
- Accept PR number, URL, or infer from the current branch.
- Read PR metadata with `gh pr view` and capture:
  - `state` / `mergedAt`
  - `headRefName`
  - `baseRefName`
  - whether the head branch belongs to this repository
- If PR cannot be resolved, stop and report the blocker.

### 2. Verify It Is Merged (Checkpoint)
- Continue only when PR is clearly merged (`state == MERGED` or `mergedAt` is set).
- If PR is `OPEN` or `CLOSED` without merge, communicate that clearly to the user and stop immediately.
- Under no circumstance merge the PR as part of cleanup; this workflow only verifies state and cleans local/remote artifacts for already-merged PRs.

### 3. Safety Validation Before Deletes
- Confirm the head branch is not `main`, `master`, or the PR base branch.
- Identify the target default local branch (`main`, or `master` if `main` does not exist).
- If the current checkout is the branch being deleted, switch away first.

### 4. Delete Remote Head Branch
- If the PR head branch is in the same repository and still exists on `origin`, delete it.
- If the head branch is from a fork or already deleted, skip remote deletion and note it.
- After deletion, prune remote tracking refs (`fetch --prune` / `remote prune`).

### 5. Clean Local Branches and Stale Tracking
- Delete the local copy of the PR head branch if it exists.
- Prefer safe delete first; if it fails only due local merge shape (for example squash merge), force delete only after merged verification.
- Remove stale remote-tracking refs.

### 6. Clean Worktrees
- Inspect `git worktree list --porcelain` for worktrees bound to deleted/nonexistent branches.
- Remove worktrees tied to the PR head branch when safe.
- Prune stale worktree metadata.
- If a worktree is dirty or locked, stop deletion for that path and report manual action needed.

### 7. Return Repo to Clean Main State
- Checkout local `main` (or `master` fallback).
- Update from remote with a safe pull strategy (`--ff-only`).
- Report final state:
  - current branch
  - whether local branch and remote head branch are deleted
  - whether any worktrees were skipped (with explicit paths/reasons)

### 8. Post-Cleanup Invariant Checkpoint
- Verify PR head branch no longer exists locally.
- Verify no worktree is still bound to the PR head branch.
- If either invariant fails, return a clear manual-action summary and exit non-zero (cleanup is partial, not complete).

## Common Mistakes

### ❌ Cleaning Up Before Merge Confirmation
**Problem**: Branches are deleted for PRs that were only closed, not merged.
**Fix**: Require explicit merged signal from GitHub before deletion.

### ❌ Deleting the Base Branch by Accident
**Problem**: Script/command deletes `main` or another protected branch.
**Fix**: Block deletion when branch equals `main`, `master`, or `baseRefName`.

### ❌ Leaving Local State Dirty Before Switching to Main
**Problem**: `git checkout main` or `git pull` fails and cleanup is half-done.
**Fix**: Detect dirty state early; stash or stop with a clear instruction.

### ❌ Ignoring Worktrees
**Problem**: Branch removed but stale worktree directories and metadata remain.
**Fix**: Always inspect and prune worktrees as part of post-merge cleanup.

### ❌ Assuming Remote Branch Exists
**Problem**: Deletion step fails noisily when branch is already gone.
**Fix**: Check existence first; treat missing remote branch as success.

### ❌ Reporting success when cleanup is partial
**Problem**: Dirty/locked worktree skips leave the PR head branch effectively active, but output still looks fully successful.
**Fix**: Add a post-cleanup invariant checkpoint and fail the run if head-branch artifacts remain.

## Red Flags (Fail Fast)

- ❌ PR is not merged
- ❌ Head branch resolves to `main`, `master`, or base branch
- ❌ Cannot determine repo/PR context from `gh`
- ❌ Current repository has unresolved local changes that block checkout/pull
- ❌ Target worktree is dirty/locked and cannot be safely removed
- ❌ Post-cleanup invariants fail (head branch/worktree artifacts still present)
