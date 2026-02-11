---
name: pull-request-loop
description: Iteratively review and harden a pull request by alternating review-pr and manage-pr-feedback until no actionable findings remain, with explicit stop conditions to prevent infinite loops or rabbit holes.
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

## Workflow

### 1. Initialize

- Confirm PR number, branch, and current mergeability.
- Capture baseline loop state.
- Set `max_cycles` (default: 6).
- Set no-progress threshold (default: 2 consecutive cycles).

### 2. Run Review Pass (`review-pr`)

- Perform a full current-state review (not only diff snippets).
- Identify only new, valid findings.
- Re-check existing threads before adding new comments.
- Post concise review outcome for this cycle.

### 3. Decision Gate

- If there are no actionable findings and no unresolved threads, go to completion checks.
- Otherwise continue to fix/feedback handling.

### 4. Run Fix + Feedback Pass (`manage-pr-feedback`)

- Process each actionable finding end-to-end:
  1. assess validity
  2. implement fix (if accepted)
  3. verify with targeted tests
  4. reply on PR
  5. resolve thread when appropriate
- Keep changes scoped to issues found in the cycle.

### 5. Recompute State and Progress

- Recompute full loop state.
- Compare against previous cycle:
  - Did blocker count decrease?
  - Did unresolved thread count decrease?
  - Did fingerprint change meaningfully?
  - Did CI move forward?

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

### ❌ Chasing every suggestion indefinitely
**Problem**: Rabbit hole with no blocker reduction.
**Fix**: Enforce no-progress and max-cycle stop conditions.

### ❌ Treating CI noise as actionable PR regressions
**Problem**: Wasted cycles on unrelated failures.
**Fix**: Classify failures as related/unrelated before continuing.

### ❌ Reposting duplicate findings
**Problem**: Reviewer noise and churn.
**Fix**: Re-check existing threads and current code before posting.

## Red Flags (Fast-Fail)

- Two consecutive cycles with unchanged blockers and unchanged thread count.
- More files touched each cycle but no reduction in blocking findings.
- Alternating reviewer requests that cannot both be satisfied under current policy.
- Reopened threads for the same issue after multiple attempts.
