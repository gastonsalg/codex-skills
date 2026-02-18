---
name: review-pr
description: Review a pull request and post precise inline findings plus a concise review summary. Use when the task is to evaluate code quality/risk in a PR. Do not use to implement fixes, resolve author feedback loops, create new PRs, or perform post-merge branch cleanup.
---

# Review Pull Request Skill

## Overview

This skill addresses recurring failures in PR reviews:
- Creating blob comments instead of inline comments on specific lines
- Using wrong GitHub API endpoints (reviews endpoint vs comments endpoint)
- Not using suggestion blocks for one-click code fixes
- Verbose, over-praising feedback instead of concise findings

**Why this matters**: Inline comments keep discussions contextual and actionable. Blob comments scatter feedback and make it hard to track what's addressed.

---

## Core Principles

### Review Focus
- **Security**: SQL injection, XSS, exposed secrets, auth bypasses
- **Logic**: Off-by-one errors, null handling, edge cases
- **Performance**: N+1 queries, unnecessary loops, memory leaks
- **Architecture**: Violations of project patterns (see CLAUDE.md, ARCHITECTURE.md)
- **Testing**: Missing tests, inadequate coverage

### Communication Style
- **Concise**: One finding per comment, no verbosity
- **Objective**: Focus on facts, not validation
- **Specific**: Reference exact lines, provide fixes
- **Non-redundant**: Don't duplicate other reviewers' feedback
- **Inline for code issues**: Post comments on exact lines (MANDATORY)
- **Format**: Emoji prefix (❌ Critical | ⚠️ Warning | 💡 Suggestion | 🔍 Question | ✅ Strength) + Issue + Fix
- **Signature**: Append `🤖 Generated with Codex` as the final line of every inline comment and review summary

---

## Workflow

### 1. Setup and Checkout
- Use TodoWrite to track review progress
- Get PR context (title, body, linked issues, files changed)
- Get the actual branch name from the PR
- Checkout the PR branch and pull latest changes
- Verify you're on the correct branch before proceeding

### 2. Check Existing Feedback and Current State
**CRITICAL: See what's been reported and what actually exists NOW**
- Fetch all existing inline comments and PR conversation reviews
- Check recent commits for "Fix:" commits addressing previous feedback
- **Read actual current files** to see complete state (not just diffs)

**For each existing unresolved thread**:
- Read current code to verify if issue still exists
- If **already fixed**: Note for step 7 (you'll reply + resolve), DO NOT post new comment
- If **still present**: Valid finding you may escalate or comment on
- Track findings in todo list to avoid duplicates

**Don't trust without verification**:
- Diffs alone (show changes, not complete state)
- Commit messages ("Fix X" doesn't guarantee X is fixed)
- Previous comments (verify issues exist in actual current code)

### 3. Understand Context
- **Read project docs**: CLAUDE.md, README.md, ARCHITECTURE.md, CONTRIBUTING.md
- **Review diff** to see what changed from base
- **Understand intent**: What problem is this PR solving?

### 4. Analyze Code (Adversarial Mindset)
- **Assume bugs exist** - Hunt for them systematically
- **Check security first** - Most critical findings
- **Verify architecture** - Does it follow project patterns?
- **Test coverage** - Are edge cases handled?

### 5. Post NEW Findings Only
**CRITICAL: Only post comments for issues NOT already mentioned**
- Check your todo list from step 2 - don't duplicate existing unresolved threads
- If an issue was already reported (even if unresolved), skip to step 6 to handle it

**For code-specific issues** - Post inline comments on exact lines:
- Use `/repos/{owner}/{repo}/pulls/{pr}/comments` endpoint
- Requires: `commit_id`, `path`, `line`, `side` ("RIGHT" for new/modified, "LEFT" for deleted)
- Use `suggestion` code fence for one-click fixes
- Append signature footer at end of each comment body: `🤖 Generated with Codex`

**For architectural/conceptual feedback** - Use review summary

### 6. Resolve Addressed Threads
**CRITICAL: Clean up resolved issues from ANY reviewer**
- Fetch unresolved review threads (see API reference)
- For each unresolved thread (from Copilot, humans, or yourself):
  - Check if issue is fixed in current code by reading actual files
  - Check if author replied explaining the fix
  - If addressed: Reply "Fixed in commit [sha]" and resolve thread using GraphQL mutation
- **Your role**: As reviewer, you should resolve threads that have been addressed, regardless of who created them
- **Don't leave threads unresolved** if they've been tackled

### 7. Create Review Summary
**CRITICAL: Check PR authorship before approval**
- Get PR author and current user credentials
- **If author matches current user**: Use `--comment` instead of `--approve` (cannot self-approve)
- **If different author**: Use appropriate event based on findings

**Review event selection**:
- APPROVE (no blockers) | REQUEST_CHANGES (critical issues) | COMMENT (suggestions only or self-authored PR)
- List NEW findings by severity with file:line references
- State approval rationale clearly
- Keep concise - no PR overview, no file lists
- For multi-line review text, do NOT use quoted `\n` in `--body`; use `--body-file` (or heredoc to a temp file) and verify rendered formatting after posting
- End review summary text with signature footer: `🤖 Generated with Codex`

### 8. Return to Main Branch
- Always return to main after review

---

## API Quick Reference

For full command templates, load `references/github-pr-review-api.md`.

Minimum reminders:
- Inline review comments use `/pulls/{pr}/comments` (not `/reviews`).
- Suggestion blocks should use the `suggestion` fenced code block.
- Resolve threads via GraphQL mutation after confirming issue is addressed.
- Use `--body-file` for multiline review summaries to avoid literal `\n` rendering.

---

## Common Mistakes

### ❌ Creating Blob Comments
**Problem**: Using regular PR comments instead of inline comments
**Fix**: Use `/pulls/{pr}/comments` endpoint with `line` parameter

### ❌ Wrong API Endpoint
**Problem**: Using `/reviews` endpoint with `line` parameter (doesn't work)
**Fix**: Use `/comments` endpoint for inline comments, `/reviews` for summary

### ❌ Not Using Suggestion Blocks
**Problem**: Describing fixes in prose instead of showing code
**Fix**: Use `suggestion` code fence - GitHub creates one-click apply button

### ❌ Leaving Threads Unresolved
**Problem**: Not resolving threads after issues are fixed or answered
**Fix**: Check unresolved threads at end of review, resolve those that have been addressed

### ❌ Verbose Feedback
**Problem**: Over-explaining, excessive praise, repeating context
**Fix**: One finding per comment, state issue + fix only

### ❌ Duplicating Feedback
**Problem**: Repeating what other reviewers already said
**Fix**: Check existing reviews first, only add new findings

### ❌ Ignoring Project Standards
**Problem**: Reviewing against generic best practices
**Fix**: Read CLAUDE.md and ARCHITECTURE.md first

### ❌ Re-Reporting Fixed Issues
**Problem**: Reporting issues that were already fixed in recent commits
**Fix**: Checkout PR branch, read actual current files, verify issue exists in current code before reporting

### ❌ Reviewing Diffs Instead of Actual Code
**Problem**: Only looking at diffs/commits without reading complete current files
**Fix**: Always read the full current files to see actual state, not just what changed

### ❌ Creating Duplicate Comments for Already-Reported Issues
**Problem**: Seeing an unresolved thread from another reviewer about issue X, verifying it's fixed, then posting a NEW comment about X instead of resolving the existing thread
**Fix**: If an issue was already reported (even if unresolved), don't create a new comment - instead reply to and resolve the existing thread
**Detection**: You find yourself posting a comment about something Copilot or another reviewer already mentioned

### ❌ Quoted `\n` Strings in Review Summary
**Problem**: Running `gh pr review --comment --body "line1\nline2"` sends literal `\n`, so the review renders as plain escaped text.
**Fix**: Put multi-line content in a file and submit with `--body-file`, then verify formatting in `gh pr view --comments`.

### ❌ Attempting to Approve Self-Authored PR
**Problem**: Trying to use `gh pr review --approve` on a PR you created, causing "Can not approve your own pull request" error
**Fix**: Check PR author before approval - if it matches current user, use `--comment` instead of `--approve`
**Detection**: Getting GraphQL error "Can not approve your own pull request" when running approval command

### ❌ Missing AI Signature on Review Messages
**Problem**: Inline comments or review summary are posted without provenance footer.
**Fix**: Append a blank line, then `🤖 Generated with Codex` at the end of every GitHub review message body.

---

## Red Flags (Fail Fast)

- ❌ Running commands before TodoWrite
- ❌ Operating on wrong branch (not PR branch)
- ❌ Not checking out and pulling latest PR branch code
- ❌ Reviewing diffs/commits instead of reading actual current files
- ❌ Skipping existing feedback check (inline comments + reviews)
- ❌ Posting blob comments instead of inline
- ❌ Assuming code is correct without adversarial analysis
- ❌ Reporting issues without verifying they exist in current code
- ❌ Posting new comment about issue already mentioned in existing unresolved thread
- ❌ Leaving unresolved threads when issues have been fixed (from any reviewer)
- ❌ Attempting to approve PR without checking if you're the author
- ❌ Posting review summary with quoted `\n` in `--body` (renders escaped text)
- ❌ Posting inline/review summary text without `🤖 Generated with Codex` footer
