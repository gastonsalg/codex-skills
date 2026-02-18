# Codex Skills

Personal collection of Codex skills for PR workflow, database migrations, ExecPlan work, and skill authoring.

## Available Skills

### PR Workflow

**create-pr**
- Create PRs with proper git workflow
- Branch management, tests, code review integration
- Trigger: "create a PR", "commit and push"

**review-pr**
- Review PRs with inline comments
- Copilot-style suggestions, thread resolution
- Trigger: "review PR #123"

**manage-pr-feedback**
- Respond to feedback on your PRs (author perspective)
- Reply to comments, resolve threads systematically
- Trigger: "address PR feedback", "respond to Copilot"

**pull-request-loop**
- Run iterative review/fix loops until PR blockers are cleared or stop conditions trigger
- Alternates `review-pr` and `manage-pr-feedback` with cycle tracking
- Trigger: "run a PR hardening loop", "iterate review/fix cycles"

**pr-merge-cleanup**
- Clean local and remote branch/worktree state after PR merge
- Verifies merged state first, then returns repo to updated main/master
- Trigger: "cleanup after PR merge", "remove merged PR branch/worktree"

### Planning

**exec-plan** (folder: `create-exec-plan`)
- Create, revise, discuss, or execute Codex ExecPlans
- Uses `PLAN.md` as source of truth
- Trigger: "create/revise/execute an ExecPlan"

### Database Migrations

**safe-migration**
- Alembic migration safety review
- Checks for dangerous operations, conflicts, table locks
- Trigger: "review migration", "check alembic"

### Meta

**write-skills**
- Create or refactor Codex Agent Skills
- Follow Codex + Agent Skills specification guidance
- Trigger: "create a skill", "write a skill"

### System Skills

**skill-creator**
- Guide for creating new skills
- Trigger: "create a new skill"

**skill-installer**
- Install skills from curated lists or repos
- Trigger: "install a skill"

## Installation

### Clone to Personal Skills Directory

```bash
# Choose the directory your Codex setup uses.
# Common options:
#   ~/.codex/skills
#   ~/.agents/skills
SKILLS_DIR="${SKILLS_DIR:-$HOME/.codex/skills}"

# Backup existing skills (if any)
mv "$SKILLS_DIR" "${SKILLS_DIR}.backup" 2>/dev/null || true

# Clone this repo as your skills directory
git clone https://github.com/gastonsalg/codex-skills.git "$SKILLS_DIR"
```

Skills will be available across all your projects immediately.

### Or Install Individual Skills

```bash
# Create skills directory if it doesn't exist
SKILLS_DIR="${SKILLS_DIR:-$HOME/.codex/skills}"
mkdir -p "$SKILLS_DIR"

# Clone and copy specific skills
git clone https://github.com/gastonsalg/codex-skills.git /tmp/codex-skills
cp -r /tmp/codex-skills/create-pr "$SKILLS_DIR/"
cp -r /tmp/codex-skills/review-pr "$SKILLS_DIR/"
# ... copy others as needed
```

## Usage

Skills activate automatically based on your requests:

- "Create a PR for this feature" -> `create-pr`
- "Review PR #123" -> `review-pr`
- "Address the Copilot feedback on my PR" -> `manage-pr-feedback`
- "Run another review/fix pass on this PR" -> `pull-request-loop`
- "Clean up branches/worktrees after PR merge" -> `pr-merge-cleanup`
- "Create an ExecPlan for this task" -> `exec-plan`
- "Check if this Alembic migration is safe" -> `safe-migration`
- "Help me write a skill for X" -> `write-skills`

## Organization

**Personal Skills** (`~/.codex/skills/` or `~/.agents/skills/`):
- Available across all your projects
- Private to you
- This repo

**Project Skills** (`project/.agents/skills/`):
- Specific to one project
- Committed to git, shared with team
- Copy relevant skills from this repo

## Skill Design Principles

All skills follow these principles (from `write-skills`):

- WHAT not HOW: Describe what to achieve, not exact commands
- Trigger clarity first: `description` must define when to trigger and when not to
- Focused scope: One capability per skill
- Address real failures: Document recurring problems
- Common mistakes section: Learn from actual failure modes
- Progressive disclosure: keep SKILL.md lean; move heavy details into `references/`
- Empowering: Guide Codex, don't hand-hold

## Maintenance

To update skills:

```bash
SKILLS_DIR="${SKILLS_DIR:-$HOME/.codex/skills}"
cd "$SKILLS_DIR"
git pull origin main
```

To contribute improvements:

```bash
SKILLS_DIR="${SKILLS_DIR:-$HOME/.codex/skills}"
cd "$SKILLS_DIR"
git checkout -b feature/describe-change
# Make changes
git add .
git commit -m "improve: describe change"
git push -u origin feature/describe-change
gh pr create
```

## Background

These skills were created during development of an ETL project, addressing recurring failures in:
- PR creation workflow (pushing to main, skipping tests)
- PR reviews (blob comments instead of inline, wrong API usage)
- Migration safety (dangerous operations, production risks)

The collection emphasizes practical, battle-tested patterns over theoretical best practices.

## Related

- [OpenAI Codex Skills Docs](https://developers.openai.com/codex/skills)
- [Agent Skills Specification](https://agentskills.io/specification)
- [OpenAI Skills Repository](https://github.com/openai/skills)

## License

Public domain - use freely, modify as needed, no attribution required.
