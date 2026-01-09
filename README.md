# Codex Skills

Personal collection of Codex skills for PR workflow, database migrations, and skill authoring.

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

### Database Migrations

**safe-migration**
- Alembic migration safety review
- Checks for dangerous operations, conflicts, table locks
- Trigger: "review migration", "check alembic"

### Meta

**write-skills**
- Create effective Codex skills
- Follow Anthropic guidelines + community best practices
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
# Backup existing skills (if any)
mv ~/.codex/skills ~/.codex/skills.backup

# Clone this repo as your skills directory
git clone https://github.com/gastonsalg/codex-skills.git ~/.codex/skills
```

Skills will be available across all your projects immediately.

### Or Install Individual Skills

```bash
# Create skills directory if it doesn't exist
mkdir -p ~/.codex/skills

# Clone and copy specific skills
git clone https://github.com/gastonsalg/codex-skills.git /tmp/codex-skills
cp -r /tmp/codex-skills/create-pr ~/.codex/skills/
cp -r /tmp/codex-skills/review-pr ~/.codex/skills/
# ... copy others as needed
```

## Usage

Skills activate automatically based on your requests:

- "Create a PR for this feature" -> `create-pr`
- "Review PR #123" -> `review-pr`
- "Address the Copilot feedback on my PR" -> `manage-pr-feedback`
- "Check if this Alembic migration is safe" -> `safe-migration`
- "Help me write a skill for X" -> `write-skills`

## Organization

**Personal Skills** (`~/.codex/skills/`):
- Available across all your projects
- Private to you
- This repo

**Project Skills** (`project/.codex/skills/`):
- Specific to one project
- Committed to git, shared with team
- Copy relevant skills from this repo

## Skill Design Principles

All skills follow these principles (from `write-skills`):

- WHAT not HOW: Describe what to achieve, not exact commands
- Focused scope: One capability per skill
- Address real failures: Document recurring problems
- Common mistakes section: Learn from actual failure modes
- Concise: Target 150-220 lines
- Empowering: Guide Codex, don't hand-hold

## Maintenance

To update skills:

```bash
cd ~/.codex/skills
git pull origin main
```

To contribute improvements:

```bash
cd ~/.codex/skills
# Make changes
git add .
git commit -m "improve: describe change"
git push origin main
```

## Background

These skills were created during development of an ETL project, addressing recurring failures in:
- PR creation workflow (pushing to main, skipping tests)
- PR reviews (blob comments instead of inline, wrong API usage)
- Migration safety (dangerous operations, production risks)

The collection emphasizes practical, battle-tested patterns over theoretical best practices.

## Related

- [Official Claude Code Skills Docs](https://code.claude.com/docs/en/skills)
- [Anthropic Skills Announcement](https://www.anthropic.com/news/skills)
- [Community Skills Repository](https://github.com/anthropics/skills)

## License

Public domain - use freely, modify as needed, no attribution required.
