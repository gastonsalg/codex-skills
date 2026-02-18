---
name: write-skills
description: Create or refactor Codex Agent Skills that follow the open Agent Skills specification and Codex best practices. Use when authoring SKILL.md, frontmatter, skill layout, references/scripts/assets, or agents/openai.yaml.
---

# Write Skills

## Overview

Use this skill to design or refactor skills that are discoverable, reliable, and cheap in context usage.

Primary source alignment:
- Codex skills docs: trigger behavior, placement, progressive disclosure, and best practices
- Agent Skills specification: portable schema and validation rules
- openai/skills repository: practical patterns used in production-ready skills

Core principle: optimize for trigger quality and execution reliability, not document length.

---

## Core Principles

### 1. Description Drives Invocation
- Treat frontmatter `description` as the main trigger contract.
- State what the skill does, when it should trigger, and when it should not.
- Keep scope boundaries explicit to avoid accidental implicit invocation.

### 2. Prefer Instructions First
- Start with instruction-only skills.
- Add scripts only when deterministic behavior or repeated code generation is needed.
- Add references for large domain knowledge; keep SKILL.md focused on workflow.
- Add assets only when output files/templates are required.

### 3. Keep Context Lean
- Use progressive disclosure: metadata always loaded, SKILL.md loaded on trigger, references loaded on demand.
- Keep SKILL.md concise and structured (target well under 500 lines).
- Avoid duplicating the same content across SKILL.md and references.

### 4. Write Executable Guidance
- Use imperative instructions with explicit inputs and outputs.
- Describe checkpoints for fragile multi-step workflows.
- Encode failure handling and verification, not just happy paths.

### 5. One Skill, One Job
- A skill should cover one coherent capability.
- Split broad, multi-domain behavior into separate skills.

---

## Required Format

### Required File
- Skill folder must contain `SKILL.md` (uppercase).

### Frontmatter (Required)
```yaml
---
name: skill-name
description: Explain exactly when this skill should and should not trigger.
---
```

Frontmatter rules:
- `name`: lowercase letters, digits, hyphens; <= 64 chars.
- `description`: <= 1024 chars; specific trigger language.
- Do not use markdown formatting inside frontmatter values.

### Frontmatter (Optional, Spec/Implementation-Dependent)
- `author`
- `license` (prefer SPDX identifier)
- `version` (semantic versioning if used)
- `compatibility` (runtime/tool requirements)
- `allowed-tools` (implementation-specific restrictions)
- `metadata` (implementation-specific UI/extra metadata)

If portability matters, keep optional fields minimal and confirm target runtime support.

---

## Recommended Skill Layout

```text
skill-name/
|-- SKILL.md                # required
|-- scripts/                # optional, deterministic automation
|-- references/             # optional, load-on-demand docs
|-- assets/                 # optional, templates/static resources
`-- agents/openai.yaml      # optional, Codex UI + policy metadata
```

Guidelines:
- Keep references one hop away from SKILL.md (no deep reference chains).
- If references are long, include search hints in SKILL.md (`rg` patterns or section names).
- Avoid adding README/changelog-style files that do not improve agent execution.

---

## Codex Discovery and Placement

Prefer standard Codex skill locations:
- Repository scope: `.agents/skills` (searched from current directory up to repo root)
- User scope: `~/.agents/skills`
- Admin scope: `/etc/codex/skills`

Notes:
- Some Codex installations still use `~/.codex/skills`; if a workspace already uses that convention, preserve it.
- Explicit invocation: user mentions `$skill-name`.
- Implicit invocation: Codex matches user request against `description`.
- Duplicate skill names are not merged; avoid name collisions across scopes.

---

## Authoring Workflow

### 1. Define Trigger Contract
- Draft `name` and `description` first.
- Validate "should trigger" and "should not trigger" examples before writing body.

### 2. Decide Instruction-Only vs Bundled Resources
- Instruction-only: default path.
- Add `scripts/` only for fragile/repeated deterministic tasks.
- Add `references/` for large domain docs, schemas, policies, or API details.
- Add `assets/` for files copied/modified in outputs.

### 3. Write SKILL.md Body
- Keep body focused on "how to execute" after trigger.
- Use sections that reduce ambiguity:
  - Overview
  - Workflow
  - Validation checks
  - Common mistakes
  - Red flags / fail-fast conditions

### 4. Add Optional `agents/openai.yaml` When Needed
- Use for UI metadata (`display_name`, `short_description`, icons, color).
- Use policy controls (`allow_implicit_invocation`) when implicit triggering is risky.
- Declare tool dependencies (for example MCP servers) when the skill requires them.

### 5. Validate and Test
- Validate frontmatter and naming constraints.
- Test explicit invocation (`$skill-name`).
- Test implicit invocation with at least:
  - two prompts that should trigger
  - two prompts that should not trigger
- Smoke-test each script included in `scripts/`.

### 6. Refactor for Token Efficiency
- Move bulky examples/specs from SKILL.md into `references/`.
- Keep only high-leverage instructions in SKILL.md.
- Remove stale or duplicate guidance.

---

## `agents/openai.yaml` Guidance

Use only when it adds runtime value.

Recommended fields:
- `interface.display_name`
- `interface.short_description`
- `interface.default_prompt`
- `policy.allow_implicit_invocation`
- `dependencies.tools[]` (for MCP requirements)

If you set `default_prompt`, ensure it is short and explicitly references the skill as `$skill-name`.

---

## Common Mistakes

### Mistake: Ambiguous Description
Problem: Skill triggers unpredictably or not at all.
Fix: Add clear trigger boundaries and explicit non-trigger cases in `description`.

### Mistake: "When to Use" Only in Body
Problem: Invocation quality is weak because body loads after trigger.
Fix: Move trigger logic into frontmatter `description`.

### Mistake: Over-Scripting
Problem: Skill becomes brittle and environment-dependent.
Fix: Keep instructions first; add scripts only for deterministic repetition.

### Mistake: Bloated SKILL.md
Problem: Context waste and slower reasoning.
Fix: Move bulk content to `references/` and keep SKILL.md focused.

### Mistake: Monolithic Multi-Domain Skill
Problem: Poor matching and conflicting workflows.
Fix: Split by capability/domain; keep one job per skill.

### Mistake: Invalid Frontmatter Keys
Problem: Skill may fail validation or behave inconsistently across runtimes.
Fix: Keep required keys correct and use optional keys only when supported.

### Mistake: Unverified Trigger Behavior
Problem: Skill appears correct but never activates correctly in real prompts.
Fix: Run explicit/implicit trigger tests before shipping.

---

## Red Flags (Fail Fast)

- `description` does not contain trigger boundaries.
- SKILL.md exceeds practical context budget without references split.
- Script-heavy content with no script testing.
- Multiple unrelated capabilities in one skill.
- Optional metadata added without runtime support check.
- No negative test prompts for implicit invocation.

---

## Quick Review Checklist

- `name` is valid hyphen-case and <= 64 chars.
- `description` is specific, bounded, and <= 1024 chars.
- Skill is focused on one capability.
- SKILL.md is concise and workflow-oriented.
- `scripts/`, `references/`, and `assets/` are included only when justified.
- Optional `agents/openai.yaml` exists only if UI/policy/dependency metadata is needed.
- Explicit and implicit invocation behavior has been tested.
