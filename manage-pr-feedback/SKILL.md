---
name: manage-pr-feedback
description: Address feedback on an existing pull request by evaluating comments, implementing fixes, replying, resolving threads, and requesting re-review. Use when acting as PR author after review comments land. Do not use for first-pass PR code review, creating a new PR, or post-merge cleanup.
---

# Manage PR Feedback Skill

## Overview

This skill addresses recurring failures when responding to PR feedback:
- **Replying to comments but forgetting to resolve threads** (most common)
- **Only checking inline threads, missing conversation comments** (common)
- **Missing non-blocking feedback in approved PRs** (common - approval creates false sense of completion)
- **Processing feedback on unassigned PRs, leaving ownership unclear** (common)
- Losing track of which feedback has been addressed
- Batch processing feedback (fix all → reply all → resolve all), which causes forgotten resolutions
- Not assessing whether reviewer suggestions are actually correct

**Why this matters**: Unresolved threads block PR merges, frustrate reviewers, and create bottlenecks. Proper per-comment handling ensures nothing falls through the cracks.

---

## Core Principles

### Per-Comment Workflow (Critical)
**Process each comment individually in sequence**:
1. Read comment
2. Assess if suggestion is valid (don't take for granted)
3. Fix if necessary + commit
4. Reply to comment with commit reference
5. **Resolve thread immediately** (if appropriate)
6. Move to next comment

**Why per-comment**: Prevents forgotten resolutions. Resolution happens while context is fresh, not as a separate batch step later.

### Assessment First
- **Don't blindly implement**: Evaluate whether reviewer's suggestion is correct
- **Push back respectfully**: If suggestion is wrong, explain why with reasoning
- **Ask for clarification**: If unclear, ask before implementing
- **Consider trade-offs**: Some suggestions have downsides

### When to Resolve Threads
**Resolve immediately after reply if**:
- ✅ You fixed the issue AND pushed commit
- ✅ You answered question with sufficient detail
- ✅ You declined suggestion with clear reasoning

**Don't resolve if**:
- ❌ Issue not yet fixed
- ❌ Reviewer's question wasn't fully answered
- ❌ Discussion is ongoing (awaiting reviewer response)
- ❌ Reviewer explicitly asks for re-review

### Communication Style
- **Concise**: "Fixed in [sha]. Now validates input before processing."
- **Specific**: Reference exact commits/lines changed
- **Objective**: State facts, avoid defensiveness
- **Actionable**: Clear what was done or will be done
- **Signature**: Append `🤖 Generated with Codex` as the final line of every GitHub reply/comment body

### Approval Status Is Not Completion Signal
**Critical**: PR approval ≠ all feedback addressed
- Reviewers often approve with "minor observations", "non-blocking suggestions", or "nice-to-haves"
- **Read the ENTIRE approval comment** - look for sections like:
  - "Minor observations", "Non-blocking issues", "Suggestions"
  - "LGTM but...", "Approved with recommendations"
  - Lists of improvements marked as "(not bugs)" or "(optional)"
- **Assess each observation**: Even if marked "non-blocking", consider addressing for code quality
- Don't use approval as signal to stop reading - parse the full comment text

### Assignee Ownership (Required)
- Feedback handling should keep PR ownership explicit: assignee = authenticated GitHub user driving the fixes
- If the PR has no assignee, add the authenticated user before processing comments
- If someone else is already assigned for valid team reasons, keep them and add authenticated user only when policy requires co-ownership

---

## Workflow

### 0. Ensure PR Is Assigned to the Authenticated User
**Before processing any feedback, ensure the PR has explicit ownership:**
- Resolve authenticated login once (`gh api user --jq .login`)
- Check current assignees on the PR
- If authenticated user is missing, add them as assignee immediately
- Verify assignee update succeeded, then continue

### 1. Check and Resolve Merge Conflicts (If Present)
**BEFORE processing feedback, handle any merge conflicts**:

**Check for conflicts**:
- Fetch PR details: `gh pr view $PR --json mergeable`
- If `mergeable: "CONFLICTING"`, resolve conflicts first

**Resolve conflicts**:
- Check out the PR branch (use actual branch name, not `pr-###` syntax)
- Merge or rebase with base branch (usually `main`)
- If conflicts are simple (imports, formatting), resolve them
- If conflicts are complex or unclear, **ASK USER** before proceeding
- Commit resolved conflicts with clear message
- Push to remote

**Only proceed to feedback processing after conflicts are resolved.**

### 2. Get All Feedback (Both Sources)
**Check BOTH inline threads AND conversation comments**:
- **Review threads**: Fetch unresolved review threads via GraphQL API (inline code comments with file/line context)
- **Conversation comments**: Check PR conversation tab with `gh pr view $PR --comments` (review summaries, approvals with suggestions)

**Why both?** Reviewers often leave inline threads for code-specific issues (resolvable) and conversation comments for general feedback, "APPROVED ✅ with minor suggestions" reviews, architecture discussions.

**Critical for approved PRs**:
- **Don't stop at "APPROVED" status** - read the full approval comment
- Look for sections: "Minor observations", "Suggestions", "Non-blocking", "Nice-to-haves"
- Parse lists of improvements even if marked "(not bugs)" or "(optional)"
- Count ALL feedback items, not just unresolved threads

**Use TodoWrite to track ALL feedback** (inline + conversation + non-blocking observations):
- Create one todo per feedback item
- Prioritize: blocking issues → security → suggestions → minor observations

### 3. Process Each Comment Individually

**CRITICAL**: You MUST complete ALL steps (A→B→C→D) for ONE comment before moving to the next.

**Stop and verify before proceeding**: After completing step D for a comment, explicitly confirm in your response: "✅ Comment [N] complete: fixed, replied, resolved." Only then move to the next comment.

**For each unresolved thread (in sequence)**:

#### A. Read and Assess
- Update todo: mark this comment as "in_progress"
- Read comment carefully
- **Assess validity**: Is this suggestion correct? Are there trade-offs?
- Decide: implement, decline, or ask for clarification
- State your decision explicitly before proceeding

#### B. Take Action Based on Assessment
**If implementing**:
- Make the code change
- Run relevant tests to verify fix
- Commit with clear message describing the fix
- Push to remote
- Record commit SHA for reply

**If declining**:
- Prepare respectful explanation with reasoning
- Consider trade-offs or alternative approaches
- Prepare your response text

**If unclear**:
- Prepare clarifying questions for reviewer
- Note that thread should NOT be resolved (awaiting response)

#### C. Reply to Comment
**Do this IMMEDIATELY after step B, before any other work**:
- Use the comment's **databaseId** (integer) from GraphQL query, NOT the node id
- State what you did or decided
- Reference commit SHA if fixed: "Fixed in [sha]. Now [description]."
- If declining: explain reasoning clearly with technical justification
- If clarifying: ask specific questions
- End reply body with signature footer: `🤖 Generated with Codex`
- Verify reply posted successfully (check for 404 errors - means wrong ID type)

#### D. Resolve Thread (IMMEDIATELY After Reply)
**CRITICAL CHECKPOINT - Do NOT skip this step**:
- Get thread ID from GraphQL query
- Use GraphQL mutation to resolve thread
- Verify thread shows `isResolved: true`
- **Only skip resolution if**: awaiting reviewer response to your question
- Update todo: mark this comment as "completed"

**STOP**: Confirm completion with "✅ Comment [N] complete: [action taken], replied, resolved."

**Now and ONLY now proceed to the next comment. Return to step A.**

### 4. Post Summary Comment
After processing all feedback (inline threads + conversation comments):
- List what was addressed with commit references
- Reply to conversation comments with explanations
- Trigger official re-review requests via the GitHub API for each reviewer (humans + Copilot). Only fall back to @-mentions when the API rejects the reviewer (e.g., chatgpt-codex-connector).
- Mention any items awaiting reviewer response
- End summary comment body with signature footer: `🤖 Generated with Codex`
- Always post a NEW summary comment for each completed feedback pass; do not edit prior summary comments.
- In multi-pass workflows (for example `pull-request-loop`), include pass/cycle identifier in the summary heading (for example, `Feedback Pass 2`) so timeline context remains intact.
- Before posting, verify the outgoing body contains the exact footer `🤖 Generated with Codex`.
- When posting new summaries, pipe the body via a single-quoted heredoc so the shell doesn't swallow backticks or quotes:
  ```bash
  cat <<'EOF' | gh pr comment $PR --repo owner/repo -F -
  Addressed items...
  EOF
  ```
- Verify the command output shows the created URL (or run `gh pr view $PR --comments | tail`) before re-running so you don't spam duplicates.
- After posting the summary, request re-review via API (`gh api repos/{owner}/{repo}/pulls/{pr}/requested_reviewers --method POST -f "reviewers[]=name"`). If the API returns a validation error for a bot (e.g., chatgpt-codex-connector), mention them instead.

---

## API Quick Reference

For full command templates, load `references/github-pr-feedback-api.md`.

Minimum reminders:
- Fetch both unresolved review threads and conversation comments.
- Reply API requires `databaseId` (integer), not GraphQL node ID.
- Resolve handled threads immediately after posting reply.
- Use heredoc or `-F -`/`--body-file` patterns to avoid shell escaping issues.
- Request re-review via API after posting the summary.

---

## Common Mistakes

### ❌ Forgetting to Resolve Threads After Replying
**Problem**: Reply to comment, move to next item, forget to resolve thread
**Fix**: Resolve thread IMMEDIATELY after replying, before moving to next comment

### ❌ Batch Processing (Fix All → Reply All → Resolve All)
**Problem**: By the time you get to resolution step, you've lost context and forget some
**Fix**: Use per-comment workflow - complete one comment fully (A→B→C→D) before moving to next
**Detection**: If you find yourself making multiple commits before replying to any comments, STOP - you're batch processing
**Enforcement**: After EACH comment resolution, explicitly confirm: "✅ Comment [N] complete" before proceeding

### ❌ Blindly Implementing All Suggestions
**Problem**: Implementing suggestions without assessing validity or trade-offs
**Fix**: Evaluate each suggestion critically - push back respectfully if incorrect

### ❌ Resolving Without Fixing
**Problem**: Resolving threads before actually addressing the issue
**Fix**: Only resolve after fix is committed and pushed

### ❌ Vague Replies
**Problem**: "Fixed" without specifics
**Fix**: "Fixed in commit abc1234 by adding validation on line 42"

### ❌ Not Tracking Progress
**Problem**: Losing track of which threads are addressed
**Fix**: Use TodoWrite to track each thread systematically

### ❌ Skipping Assignee Check Before Feedback Work
**Problem**: Addressing review comments while PR remains unassigned, causing unclear ownership and follow-up gaps.
**Fix**: Make assignee validation the first step in workflow: authenticated user must be in PR assignees before processing comments.
**Detection**: `gh pr view $PR --json assignees --jq '.assignees[].login'` does not include the authenticated user.

### ❌ Posting Duplicate Summary Comments
**Problem**: Re-running `gh pr comment` after a partial failure posts 2-3 identical re-review summaries, spamming reviewers.
**Fix**: Before retrying, confirm whether the previous command created a comment (check for the returned URL or run `gh pr view $PR --comments | tail`). If it already posted, do not post again unless there is net-new information; if clarification is needed, add a short follow-up comment instead of editing history.
**Detection**: CLI already printed `https://github.com/...` or the conversation feed shows your status update.

### ❌ Editing Historical Summary Comments Across Passes
**Problem**: Editing the prior pass summary comment rewrites history and breaks review conversation context.
**Fix**: Never edit prior pass/cycle summary comments. Post a new comment for each pass with explicit pass/cycle label and scope.

### ❌ Shell Escaping Problems When Posting Summaries
**Problem**: Using inline `--body` with quotes/backticks causes `gh pr comment` commands to fail silently, leading to retries and duplicate posts once quoting is corrected.
**Fix**: Pipe the body through a single-quoted heredoc (`cat <<'EOF' | gh pr comment ... -F -`) so the literal text reaches GitHub unchanged.
**Detection**: Shell errors such as `command not found` or truncated text in the posted comment indicate escaping issues—switch to the heredoc pattern before retrying.

### ❌ Skipping the Official Re-Review Request
**Problem**: Summary comment says "ready for re-review" but no API request was sent, so reviewers never get an actionable notification (especially Copilot).
**Fix**: Use the reviewers API to request re-review for every reviewer whenever new changes land. If the API rejects a reviewer (e.g., chatgpt-codex-connector), immediately fall back to an @-mention in the summary comment.

### ❌ Only Checking Inline Threads, Missing Conversation Comments
**Problem**: Fetching unresolved threads, seeing they're all resolved, concluding "all done" - but missing review summary comments with suggestions in PR conversation
**Fix**: ALWAYS check both sources:
- `gh api graphql` for inline review threads
- `gh pr view --comments` for conversation comments with embedded feedback

### ❌ Stopping at "APPROVED" Status Without Reading Full Comment
**Problem**: PR shows "APPROVED", assume all feedback addressed, miss "Minor observations" section with valid improvements
**Fix**: Approval status is NOT a completion signal - parse the entire approval comment text:
- Look for sections: "Minor observations", "Suggestions", "Non-blocking issues"
- Watch for phrases: "LGTM but...", "Approved with recommendations", "(not bugs)"
- Assess each observation - even "minor" improvements enhance code quality

**Example of this mistake**:
- PR #286 approved by eduxing with "LGTM"
- Approval comment included "Minor Observations (not bugs)" section with 3 items
- Initial scan missed these because unresolved threads = 0 and status = APPROVED
- User caught the miss: "Did you notice those?"

### ❌ Not Handling Merge Conflicts First
**Problem**: Attempting to process feedback while PR has merge conflicts
**Fix**: Always check `mergeable` status first and resolve conflicts before addressing feedback
**When to ask**: If conflicts involve complex logic changes or you're unsure which version to keep

### ❌ Using Node ID Instead of Database ID for Reply API
**Problem**: Using GraphQL node ID (e.g., `PRRC_kwDOJYs3c86XdcNc`) in REST API reply endpoint returns 404
**Fix**: Use `databaseId` field (integer) from GraphQL query, not `id` field (string)
**Detection**: "Parent comment not found (HTTP 404)" when trying to reply to comment
**Example**:
- ❌ Wrong: `repos/owner/repo/pulls/190/comments/PRRC_kwDOJYs3c86XdcNc/replies`
- ✅ Right: `repos/owner/repo/pulls/190/comments/2541077340/replies`

### ❌ Missing AI Signature on Feedback Responses
**Problem**: Thread replies or summary comments are posted without provenance footer.
**Fix**: Append a blank line, then `🤖 Generated with Codex` as the final line in each GitHub reply/comment body.

---

## Red Flags (Fail Fast)

**Process violations (STOP immediately if detected)**:
- ❌ Making multiple commits without replying to comments → You're batch processing
- ❌ Planning to "fix all issues then reply" → Wrong approach, use per-comment workflow
- ❌ Thinking "I'll resolve threads at the end" → Threads must be resolved immediately after reply
- ❌ Resolving thread before pushing fix commit → Wrong order

**Feedback gathering violations**:
- ❌ Only checking `reviewThreads`, not checking conversation comments → Missing feedback
- ❌ Seeing "APPROVED" status and stopping without reading full comment → Missing non-blocking feedback
- ❌ Unresolved threads = 0, concluding "all done" without checking conversation → Missing feedback

**Communication violations**:
- ❌ Not replying to reviewer questions → Threads left unresolved
- ❌ Defensive or dismissive tone in replies → Unprofessional
- ❌ Ignoring blocking feedback → PR won't be approved
- ❌ Replying/posting summary without `🤖 Generated with Codex` footer

**Conflict handling violations**:
- ❌ Processing feedback while PR has merge conflicts → Resolve conflicts first
- ❌ Resolving complex conflicts without asking user → Ask for guidance on non-trivial conflicts

---

## Example: Processing One Comment

```markdown
**Thread**: "Add validation for integer overflow in migration"

1. **Read**: Copilot suggests checking INT max range
2. **Assess**: Valid concern - MySQL INT has max value
3. **Fix**: Add overflow check in migration, commit
4. **Reply**: "Fixed in commit 190f0ce. Added check to cap values at INT max."
5. **Resolve**: Run GraphQL mutation to resolve thread IMMEDIATELY
6. **Move to next comment**
```
