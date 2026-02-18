---
name: pull-request-loop
description: Run controlled multi-cycle PR hardening by alternating review-pr and manage-pr-feedback until blockers and unresolved threads are cleared or stop conditions trigger. Use when one review/fix pass is insufficient. Do not use for single-pass review only, feedback-only handling, creating PRs, or post-merge cleanup.
---

# PR Review Loop

## Overview

Use this skill when a PR needs repeated review/fix cycles, not a single pass.

It addresses recurring failures:
- stopping after one review pass while issues remain
- fixing comments without resolving threads
- looping forever on low-signal or conflicting feedback

Goal: reach a clean, review-ready PR state or stop safely with a clear escalation summary.

## Core Principles

- Alternate skills per cycle: `review-pr` then `manage-pr-feedback`.
- Track progress explicitly; never rely on memory.
- Resolve feedback at thread level, not only in code.
- Prefer small, test-backed fixes each cycle.
- Stop when loop risk appears; escalate instead of grinding.
- Preserve timeline context: each cycle posts a new cycle-labeled summary comment; never edit previous cycle summaries.

## Required Loop State

Maintain these values at the start and end of every cycle:
- `cycle_number`
- `open_blocking_findings`
- `open_non_blocking_findings`
- `unresolved_threads`
- `requested_changes_present` (yes/no)
- `ci_status` (pass/fail/pending/unavailable)
- `finding_fingerprint` (stable summary of current blockers)
- `files_touched_in_cycle`
- `assignee_present` (yes/no; authenticated GitHub user is in PR assignees)
- `execution_worktree` (absolute path used for review/fix commands)
- `head_branch_checked_out` (yes/no; execution worktree is on PR head branch)
- `latest_fix_commit` (sha or none)
- `stability_pass_completed` (yes/no)
- `external_review_pending` (yes/no when re-review requested)

## Workflow

### 1. Initialize

- Confirm PR number, branch, and current mergeability.
- Resolve authenticated GitHub login (`gh api user --jq .login`).
- Ensure the authenticated user is assigned to the PR before review/fix cycles:
  - `gh pr edit "$PR" --add-assignee "$GH_USER"`
  - verify with `gh pr view "$PR" --json assignees --jq '.assignees[].login'`
- Resolve execution worktree for the PR head branch before running review commands:
  - if head branch is already checked out in another worktree, run review/fix commands there
  - if not, use current repository worktree and check out the head branch
  - never force branch checkout when Git reports branch/worktree binding conflicts
- Capture baseline loop state.
- Set `max_cycles` (default: 6).
- Set no-progress threshold (default: 2 consecutive cycles).

### 2. Run Review Pass (`review-pr`)

- Perform a full current-state review (not only diff snippets).
- Identify only new, valid findings.
- Re-check existing threads before adding new comments.
- Post concise review outcome for this cycle.

### 3. Decision Gate

- If there are no actionable findings and no unresolved threads, run the stability gate (Step 3.5) before completion checks.
- Otherwise continue to fix/feedback handling.

### 3.5 Stability Gate (Required Before "Done")

- Run one additional broad review pass focused on second-order regressions in files touched since `latest_fix_commit`.
- Require explicit checks for:
  - boundary/duplicate/null input handling
  - guard/normalization ordering
  - newly introduced unconditional expensive calls
  - behavior parity under relevant flags/policies
- If any new actionable finding appears, continue with Step 4 (do not complete).
- Mark `stability_pass_completed=yes` only when this pass yields no actionable findings.

### 4. Run Fix + Feedback Pass (`manage-pr-feedback`)

- Process each actionable finding end-to-end:
  1. assess validity
  2. implement fix (if accepted)
  3. verify with targeted tests
  4. reply on PR
  5. resolve thread when appropriate
- Keep changes scoped to issues found in the cycle.
- Update `latest_fix_commit` after each fix commit.

### 5. Recompute State and Progress

- Recompute full loop state.
- Ensure this cycle has a new summary comment with cycle label (for example, `Cycle 2 Summary`), distinct from prior cycles.
- Compare against previous cycle:
  - Did blocker count decrease?
  - Did unresolved thread count decrease?
  - Did fingerprint change meaningfully?
  - Did CI move forward?
  - Is assignee still present?

### 5.5 External Review Synchronization (When Applicable)

- If Copilot or another external reviewer is active on the PR, request re-review after new fixes land.
- Before declaring completion, check for newly created review threads/comments after the last re-review request.
- If new external findings appear, return to Step 4.
- If external review is still pending, report status as "awaiting external review" rather than "fully clean."

### 6. Evaluate Stop Conditions

Stop immediately and escalate with a concise summary if any condition is met:

- `cycle_number >= max_cycles`
- no measurable progress for 2 consecutive cycles
- same blocker fingerprint appears in 2+ consecutive cycles after attempted fixes
- feedback is conflicting and requires maintainer policy decision
- scope expansion indicates rabbit hole (for example, repeated cross-module churn without blocker reduction)
- CI failure remains unrelated to changed code across 2 cycles and blocks validation

### 7. Iterate or Exit

- If stop condition met: exit with escalation summary.
- If actionable findings remain: start next cycle.
- If clean: run completion checks and exit success.

## Completion Checks

Before declaring done:
- no unresolved review threads
- no remaining blocking findings
- no pending requested-changes state tied to unresolved issues
- relevant tests pass for touched code
- PR has a final concise status update
- authenticated GitHub user remains assigned to the PR
- `execution_worktree` still maps to the PR head branch (`head_branch_checked_out=yes`)
- no unresolved branch/worktree mismatch (for example, PR head bound to a different worktree than the one used)
- `stability_pass_completed=yes` on latest code state
- no new external findings since last re-review request (or explicitly report pending external review)

## Escalation Output (When Stopping)

Provide:
- cycle count reached
- unresolved blockers and their file/line references
- what was tried in last cycle
- why progress stalled (explicit stop condition)
- specific maintainer decision needed

## Common Mistakes

### ❌ Batch-fixing all comments before replying/resolving
**Problem**: Threads stay open and state becomes inconsistent.
**Fix**: Complete each feedback item end-to-end in the same cycle.

### ❌ Re-reviewing without a progress baseline
**Problem**: Repeated work looks like progress but is not.
**Fix**: Track and compare explicit cycle state fields.

### ❌ Declaring "No Findings" Without Stability Pass
**Problem**: Known threads are closed, but new regressions from recent fixes are still undetected.
**Fix**: Require Step 3.5 stability gate before completion.

### ❌ Declaring Done Before External Re-Review Settles
**Problem**: Loop exits clean, then Copilot posts new findings minutes later.
**Fix**: Run external-review synchronization (Step 5.5) and re-enter loop if new findings appear.

### ❌ Chasing every suggestion indefinitely
**Problem**: Rabbit hole with no blocker reduction.
**Fix**: Enforce no-progress and max-cycle stop conditions.

### ❌ Treating CI noise as actionable PR regressions
**Problem**: Wasted cycles on unrelated failures.
**Fix**: Classify failures as related/unrelated before continuing.

### ❌ Reposting duplicate findings
**Problem**: Reviewer noise and churn.
**Fix**: Re-check existing threads and current code before posting.

### ❌ Skipping assignee validation in loop execution
**Problem**: PR feedback cycles complete with no explicit owner, causing follow-up ambiguity.
**Fix**: In Initialize, add authenticated user as assignee and track `assignee_present` each cycle.

### ❌ Ignoring branch/worktree binding for PR head
**Problem**: `git checkout` fails because the PR branch is already attached to another worktree; review runs in the wrong path or aborts.
**Fix**: Resolve `execution_worktree` in Initialize and run all cycle commands from that worktree.

## Red Flags (Fast-Fail)

- Two consecutive cycles with unchanged blockers and unchanged thread count.
- More files touched each cycle but no reduction in blocking findings.
- Alternating reviewer requests that cannot both be satisfied under current policy.
- Reopened threads for the same issue after multiple attempts.
- Authenticated user is not assigned to the PR after initialization.
- PR head branch is bound to a different worktree and `execution_worktree` is not updated.
- Loop attempts to complete with `stability_pass_completed=no`.
- New external review comments appear after "clean" decision.
