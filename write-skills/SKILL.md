---
name: write-skills
description: Creates effective Claude Code skills following official Anthropic guidelines and community best practices. Use when creating or refactoring skills. Focuses on WHAT not HOW, proper structure, and addressing real failure modes.
---

# Write Skills Skill

## Overview

This skill encodes best practices for creating Claude Code skills, synthesized from official Anthropic documentation and community "writing-skills" TDD methodology.

**Key principle**: Skills should tell Claude WHAT to do (principles), not HOW (exact commands). Skills empower rather than hand-hold.

---

## When Skills Are Appropriate

### ✅ Good Use Cases
- **Enforcing critical workflows** (git branch rules, production safety)
- **Teaching specialized domain knowledge** (Alembic safety patterns)
- **Encoding project-specific conventions** (PR review style)
- **Addressing recurring failures** (documented baseline problems)

### ❌ Bad Use Cases (Use Documentation Instead)
- Reference material (templates, checklists) → docs/
- Extensive how-to guides (step-by-step tutorials) → docs/
- General best practices (already in training data)
- One-time tasks (no recurring pattern)

**The Test**: "Does this address a recurring failure or encode unique knowledge?"
- **Yes** → Skill | **No** → Documentation

---

## Official Anthropic Requirements

### File Structure (CRITICAL)

**Must be named `SKILL.md` (uppercase)** in directory:
- Personal: `~/.codex/skills/skill-name/SKILL.md` (Codex CLI) or `~/.claude/skills/skill-name/SKILL.md` (Claude)
- Project: `.codex/skills/skill-name/SKILL.md` or `.claude/skills/skill-name/SKILL.md` depending on repo setup

**Common mistakes**: `.claude.md`, `skill.md`, `Skill.md` (all wrong)

### YAML Frontmatter
```yaml
---
name: skill-name           # lowercase, hyphens, max 64 chars
description: What this does and when to use it. Max 1024 chars. Include trigger terms.
---
```

**Key guidelines**: Focused scope, specific descriptions, clear naming, no duplication

---

## Recommended Structure

### 1. Overview (REQUIRED)
Explain WHY this skill exists:
- What recurring failures it addresses
- Why failures matter (consequences)
- Context (2-3 sentences)

### 2. Core Principles (WHAT to do)
High-level guidance, not commands:
- Bullet lists
- Principles, not procedures
- "What" not "how"

### 3. Workflow (High-Level)
Major steps without verbose commands (1-2 sentences each)

**For frequently-violated sequential workflows, add enforcement**:
- **Checkpoints**: "STOP and verify before proceeding"
- **Confirmations**: "✅ Step N complete" before next step
- **State tracking**: "Update todo: mark as 'in_progress'"
- **Verification**: "Verify X posted successfully"
- **Self-monitoring**: "If doing Y, STOP - you're violating"

**When to enforce**: User reports violations, steps have dependencies, batch processing causes problems

**Example comparison**:
```markdown
❌ Basic: "Reply to each comment and resolve thread"
✅ Enforced: "Reply → Verify posted → Resolve immediately →
             Confirm '✅ Complete' → ONLY THEN next"
```

### 4. API Quick Reference (Optional)
Include only if syntax is non-obvious or error-prone:
- One example per concept
- Essential parameters only
- Brief comments

### 5. Common Mistakes (REQUIRED)
Document real failure modes:
```markdown
### ❌ Mistake Title
**Problem**: What goes wrong
**Fix**: How to avoid it
**Detection**: (optional) Signs you need this fix
```

Source from: user reports, TDD RED phase, testing experience

### 6. Red Flags (Recommended)
Bullet list of fast-fail conditions

---

## Length Guidelines

**Target**: 150-220 lines per skill

**If exceeding 250 lines**: Split skills, move reference material to docs/, consolidate content

---

## WHAT vs HOW - The Key Distinction

### ❌ TOO MUCH HOW (Hand-Holding)
```markdown
1. **Check branch**:
   ```bash
   CURRENT_BRANCH=$(git branch --show-current)
   if [[ "$CURRENT_BRANCH" == "main" ]]; then
       git checkout -b feature/name
   fi
   ```
```
**Problems**: Verbose commands, hand-holding syntax, assumes Claude doesn't know basics, fragile

### ✅ RIGHT BALANCE (Empowering)
```markdown
### 1. Verify Git State
- Check current branch - if on main/master, create feature branch
- Verify changes exist before proceeding
- Review staged files (avoid secrets)
```
**Strengths**: Describes WHAT, lets Claude choose HOW, concise, resilient

---

## Workflow Enforcement Techniques

Use these for critical workflows that Claude often violates:

| Technique | Pattern | Why It Works |
|-----------|---------|--------------|
| **Checkpoints** | "STOP and verify: After X, confirm Y" | Creates pause points |
| **Confirmations** | "Confirm '✅ Item [N] complete'" | Forces sequential thinking |
| **State Tracking** | "Update todo: mark 'in_progress'" | Explicit state transitions |
| **Verification** | "Verify X posted successfully" | Prevents assumption-based skipping |
| **Self-Monitoring** | "If doing Y, STOP - violation" | Enables self-correction |
| **Process Red Flags** | List specific anti-patterns | Fast-fail detection |

**Signs you need enforcement**:
- User says "you did X but forgot Y"
- Steps get skipped or reordered
- Batch processing occurs despite guidance
- "I'll do X at the end" rationalizations

**Don't overuse when**: Workflow naturally sequential, steps independent, task simple (< 3 steps)

---

## Common Mistakes in Writing Skills

### ❌ Too Much HOW, Not Enough WHAT
**Problem**: Verbose command examples instead of principles
**Fix**: Describe what to achieve, let Claude choose commands

### ❌ Reference Material Disguised as Skill
**Problem**: 300+ lines of templates and checklists
**Fix**: Move to docs/, keep skill as principles + links

### ❌ No "Recurring Failures" Context
**Problem**: Unclear why skill exists
**Fix**: Add Overview explaining real problems this solves

### ❌ Missing "Common Mistakes" Section
**Problem**: No documentation of failure modes
**Fix**: Document real failures from user experience

### ❌ Duplicating Built-In Knowledge
**Problem**: Teaching Claude things it already knows
**Fix**: Only encode unique project/domain knowledge

### ❌ Unclear Trigger Description
**Problem**: Claude doesn't know when to use skill
**Fix**: Add specific trigger terms and use cases to description

### ❌ Scope Too Broad
**Problem**: Skill tries to cover multiple distinct capabilities
**Fix**: Split into focused skills (one capability each)

### ❌ Wrong Filename
**Problem**: Using `.claude.md` or `skill.md` instead of `SKILL.md`
**Fix**: File MUST be `SKILL.md` (uppercase) in `~/.claude/skills/name/` or `.claude/skills/name/`

### ❌ Weak Workflow Enforcement
**Problem**: Describing sequential steps without enforcement, Claude batch processes
**Fix**: Add checkpoints, confirmations, state tracking, self-monitoring
**Detection signals**:
- User reports "you did X but forgot Y"
- Claude fixes multiple items before completing workflows
- Steps get skipped or reordered
- "I'll do X at the end" rationalizations

---

## Testing Your Skill (Community Practice)

**RED Phase**: Test Claude WITHOUT skill, document exact failures and rationalizations

**GREEN Phase**: Add skill, test same scenarios, verify failures prevented

**REFACTOR Phase**: Find workarounds, add to "Common Mistakes" or "Red Flags", test again

**Note**: TDD methodology is community best practice, not Anthropic requirement

---

## Skill Locations

**Personal** (`~/.claude/skills/`): Universal workflows, personal preferences
**Project** (`.claude/skills/`): Project-specific patterns, team conventions

---

## Refactoring Existing Skills

**When to refactor**: Exceeds 250 lines, verbose commands, duplicated content, missing sections

**Process**:
1. Identify WHAT vs HOW sections
2. Reduce HOW (consolidate to API reference)
3. Expand WHAT (principles, workflow)
4. Add "Common Mistakes" from real failures
5. Add Overview with recurring failures
6. Aim for 20-40% reduction

---

## Red Flags When Writing Skills

**Structure and content**:
- ❌ Skill is mostly bash commands → Too much HOW
- ❌ Over 300 lines without clear sections → Split or consolidate
- ❌ No mention of recurring failures → Missing context
- ❌ Duplicates general knowledge → Unnecessary
- ❌ Could be a docs page → Use docs/
- ❌ Overlaps with another skill → Consolidate
- ❌ No "Common Mistakes" section → Missing failure docs
- ❌ File not named `SKILL.md` (uppercase) → Won't load

**Workflow enforcement**:
- ❌ Critical workflow without checkpoints → Will be violated
- ❌ No confirmation requirements → Steps will be skipped
- ❌ Sequential steps described but not enforced → Batch processing
- ❌ No self-monitoring patterns → Claude won't detect violations
- ❌ Missing "STOP" or verification language → Claude will rush ahead
