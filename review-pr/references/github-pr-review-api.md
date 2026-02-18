# GitHub PR Review API Reference

Use these templates when command syntax is needed during `review-pr`.

## Inline Comments Require Specific Endpoint

- Use `/pulls/{pr}/comments` endpoint (NOT `/reviews`) with `line` parameter
- Required fields: `commit_id`, `path`, `line`, `side`
- `side` parameter: `"RIGHT"` for new/modified lines, `"LEFT"` for deleted lines
- Use `suggestion` code fence for one-click fixes

## Suggestion Block Format

```markdown
\`\`\`suggestion
// Replacement code here
\`\`\`
```

GitHub creates an "Apply suggestion" button for one-click fixes.

## Resolve Thread (GraphQL Required)

```bash
# List unresolved threads
gh api graphql -f query='query {
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: '$PR') {
      reviewThreads(first: 100) {
        nodes { id isResolved comments(first: 1) { nodes { body } } }
      }
    }
  }
}'

# Resolve thread
gh api graphql -f query='mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { isResolved }
  }
}' -f threadId="THREAD_ID"
```

## Review Summary Formatting (Avoid Literal `\n`)

```bash
# Write review body with real newlines, then submit
cat <<'EOF' > /tmp/review-body.md
Review result: blocker found.

- [Critical] ...
EOF

gh pr review $PR --comment --body-file /tmp/review-body.md
```

Use `--body-file` for multi-line reviews so GitHub renders Markdown correctly.
