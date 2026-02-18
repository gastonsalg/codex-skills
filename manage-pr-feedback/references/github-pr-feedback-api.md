# GitHub PR Feedback API Reference

Use these templates when command syntax is needed during `manage-pr-feedback`.

## Get Unresolved Threads

```bash
gh api graphql -f query='
query {
  repository(owner: "owner", name: "repo") {
    pullRequest(number: '$PR') {
      reviewThreads(first: 50) {
        nodes {
          id
          isResolved
          comments(first: 10) {
            nodes {
              id
              databaseId
              author { login }
              body
              path
              line
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

Important: Each comment has two IDs:
- `id` (node ID): GraphQL string like `"PRRC_kwDO..."` (GraphQL mutations)
- `databaseId`: Integer like `2541077340` (REST reply endpoint)

## Get PR Conversation Comments

```bash
# Shows all comments including review summaries with suggestions
gh pr view $PR --comments

# Or via API for recent comments
gh api repos/owner/repo/issues/$PR/comments
```

## Reply to Comment

```bash
# Use databaseId (integer), not node id (GraphQL string)
gh api --method POST \
  repos/owner/repo/pulls/$PR/comments/$DATABASE_ID/replies \
  --field body="Fixed in commit abc1234. Now validates input before processing.

🤖 Generated with Codex"
```

Common error: using node ID (`PRRC_kwDO...`) returns 404.

## Resolve Thread

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "THREAD_ID"}) {
    thread {
      id
      isResolved
    }
  }
}'
```

## Ensure Assignee

```bash
GH_USER="$(gh api user --jq .login)"
gh pr edit "$PR" --add-assignee "$GH_USER"
gh pr view "$PR" --json assignees --jq '.assignees[].login'
```

## Post Summary and Request Re-Review

```bash
gh pr comment $PR -b "All feedback addressed:
- ✅ Fixed SQL injection (commit abc1234)
- ✅ Added error handling (commit def5678)
- ✅ Declined suggestion X (reasoning: performance trade-off)

@reviewer Ready for re-review.

🤖 Generated with Codex"
```
