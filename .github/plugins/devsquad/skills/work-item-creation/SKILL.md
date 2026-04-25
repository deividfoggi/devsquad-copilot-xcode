---
name: work-item-creation
description: Rules and checklist for creating work items on GitHub Issues or Azure DevOps. Use when you need to create issues, user stories, tasks, epics, or features on the board. Do not use for platform configuration (use board-config), managing workflow of existing tasks (use work-item-workflow), or for comments on work items.
---

## Required Checklist

Before creating ANY work item, verify:

1. **Platform**: Read `.memory/board-config.md` to identify GitHub or Azure DevOps
2. **Duplicates**: Check if a similar work item already exists on the board
3. **Required tags/labels**: all present (see section below)
4. **Title in correct format**: see Title section
5. **Body filled in**: per the platform format (see GitHub and Azure DevOps sections)
6. **Hierarchy**: parent linked correctly
7. **Durable descriptions**: body describes *behavior* using domain language, not implementation details (see Durability Rules below)

## AI Model Traceability

All generated work items must include the tag/label `ai-model:<model-name>`.

### How to identify the model in use

1. Try reading Copilot CLI logs:
   ```bash
   grep -h "Using.*model" ~/.copilot/logs/*.log 2>/dev/null | tail -1
   ```
2. If not found, check config:
   ```bash
   cat ~/.copilot/config.json 2>/dev/null | grep -i model
   ```
3. If unable to identify, ask the user
4. Last resort: use `ai-model:unknown`

## Required Tags/Labels (every work item)

### Auto-creation of Labels (GitHub)

Before applying labels to a work item, check if they exist in the repository:

```
github/list_label(owner, repo)
```

If any required label does not exist, create it automatically via `github/label_write`:

| Label | Color (hex) |
|-------|-------------|
| `copilot-generated` | `1d76db` |
| `ai-model:*` | `5319e7` |
| `type:user-story` | `0e8a16` |
| `type:task` | `0e8a16` |
| `type:adr` | `0e8a16` |
| `type:tech-debt` | `d93f0b` |
| `feature:*` | `c5def5` |
| `priority:p1` | `b60205` |
| `priority:p2` | `fbca04` |
| `priority:p3` | `0e8a16` |
| `phase:*` | `bfdadc` |
| `severity:high` | `b60205` |
| `severity:medium` | `fbca04` |
| `severity:low` | `0e8a16` |
| `epic` | `3e4b9e` |
| `feature` | `c5def5` |
| `parallel` | `d4c5f9` |
| `blocked` | `b60205` |
| `copilot-candidate` | `1d76db` |
| `needs-human` | `e4e669` |
| `scope:cross-cutting` | `bfdadc` |
| `scope:feature-scoped` | `bfdadc` |

Cache the list of existing labels to avoid repeated calls during the same creation session.

| Tag/Label | Required | Description |
|-----------|----------|-------------|
| `copilot-generated` | Always | Identifies item created by AI |
| `ai-model:<name>` | Always | Model used |

## Tags/Labels by Type

### User Stories

| Tag/Label | Required |
|-----------|----------|
| `type:user-story` (GitHub) | Yes |
| `feature:<name>` | Yes |
| `priority:<p1\|p2\|p3>` | Yes |

### Tasks

| Tag/Label | Required |
|-----------|----------|
| `type:task` (GitHub) | Yes |
| `feature:<name>` | Yes |
| `phase:<phase>` | Yes |

### Epics

| Tag/Label | Required |
|-----------|----------|
| `epic` (GitHub) | Yes |

### Features

| Tag/Label | Required |
|-----------|----------|
| `feature` (GitHub) | Yes |
| `priority:<p1\|p2\|p3>` | Yes |

### Missing ADRs

| Tag/Label | Required |
|-----------|----------|
| `type:adr` | Yes |
| `scope:cross-cutting` or `scope:feature-scoped` | Yes |
| `feature:<name>` | Yes (if feature-scoped) |

### Tech Debt

| Tag/Label | Required |
|-----------|----------|
| `type:tech-debt` | Yes |
| `severity:<high\|medium\|low>` | Yes |
| `feature:<name>` | No (optional) |

### Optional Labels

| Label | Usage |
|-------|-------|
| `parallel` | Parallelizable task |
| `blocked` | Task with unresolved dependencies |
| `copilot-candidate` | Task delegable for autonomous agent execution |
| `needs-human` | Task requiring human judgment, access, or approval |

## Title

- User Stories and Tasks: `[<feature>] <description>`
- Epics: `[Epic] <name>`
- Features: `[Feature] <name>`
- ADRs: `[ADR] <domain>` or `[<feature>][ADR] <domain>`
- Tech Debt: `[Tech Debt] <description>`

## Hierarchy

- Tasks are children of User Stories
- User Stories are children of Features
- Features are children of Epics
- Dependencies between tasks documented in the body or via links

## Creation Order

1. User Stories first
2. Tasks second
3. Parent-child links third
4. Dependencies between tasks fourth

**NEVER create duplicate work items.** If a similar item already exists, skip it and record it in the report.

## Durability Rules

Work items live longer than the code they reference. File paths, line numbers, and commit SHAs rot as the codebase evolves. Write descriptions that remain useful after major refactors.

| Do | Do not |
|---|---|
| Describe behavior and symptoms in domain language | Reference file paths or line numbers |
| "When a user submits a form with an expired session, the system silently drops the submission" | "In src/handlers/form.ts:247, the catch block swallows the SessionExpiredError" |
| Reference domain concepts and user-visible outcomes | Reference internal module names, class names, or variable names |
| Link implementation context in PRs and commits | Embed implementation details in the work item body |

Implementation-specific context (file paths, code snippets, stack traces) belongs in linked PRs, commits, and comments, not in the work item description.

## Autonomy Classification

Classify each task to indicate whether it can be completed by an AI agent autonomously or requires human judgment.

### Agent-autonomous (`copilot-candidate`)

Add `copilot-candidate` to tasks that meet ALL criteria:
- Low impact (no schema change, public API, or integration)
- Well-defined scope (specific files, clear behavior)
- Established pattern (follows existing code or ADR)
- No pending architectural decisions

### Human-required (`needs-human`)

Add `needs-human` to tasks that meet ANY criteria:
- Requires architectural or design judgment not covered by an ADR
- Involves external system access, manual testing, or environment-specific verification
- Requires stakeholder input or approval (UX decisions, business rules, compliance)
- Touches security-sensitive code without an established pattern
- Cross-team coordination needed

---

## Format by Platform

Read `.memory/board-config.md` to identify the platform, then read **only** the corresponding reference:

| Platform | Reference |
|----------|-----------|
| GitHub Issues | Read `references/github-format.md` |
| Azure DevOps | Read `references/azdo-format.md` |
