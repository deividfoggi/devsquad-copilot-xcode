---
name: pull-request
description: "Implementation finalization with PR. Use when implementation is complete and you need to commit, push, or open a pull request. Includes automated reviews and technical debt tracking. Do not use during implementation (use devsquad.implement), for standalone intermediate commits (use git-commit), or for branch creation (use git-branch)."
---

# Pull Request — Implementation Finalization

## Check Git State

Use `read/changes` to list source control changes. In addition:

```bash
git status
git diff --stat
```

## Commit

If there are uncommitted changes, use the `git-commit` skill to commit.

## Integration Branch Guard

Before pushing or creating a PR, verify the current branch is not the integration branch:

```bash
CURRENT_BRANCH=$(git branch --show-current)
```

Resolve the integration branch in this order:

1. `Integration Branch` from `.memory/git-config.md` (if it exists)
2. Repository default branch via `git symbolic-ref refs/remotes/origin/HEAD`
3. Fallback: match against `main`, `master`, or `develop`

**If the current branch matches the integration branch**, stop and offer recovery:

```
You are on `[branch]`, which is the integration branch. A PR cannot be created from the integration branch to itself, and pushing directly bypasses code review.

[B] Create a feature branch from the current commit(s) and open a PR (recommended)
[P] Push directly to [branch] (not recommended, bypasses code review)
```

If the user chooses **[B]**:

| Current state | Recovery action |
|---|---|
| Committed locally, not pushed | Create feature branch at `HEAD`, then reset integration branch to `origin/[branch]`: `git branch <feature-branch>`, `git reset --hard origin/[branch]`, `git checkout <feature-branch>`. Confirm with the user before resetting. |
| Already pushed to integration branch | Create feature branch from the offending commit(s), push it, offer to revert the commit on the integration branch, then open PR from the feature branch. |

If the user chooses **[P]**, proceed with the push. Log the override decision.

This guard applies to both the PR creation path and the Push Only path below.

## Offer PR Creation

If the automated review was already executed by `devsquad.implement` (step 9 of the orchestration flow), **do not re-execute review**. Use the result already obtained.

```
Implementation completed and committed.

Would you like me to open a Pull Request?

[Y] Yes, open PR
[R] Review implementation before PR (recommended for medium/high impact)
[N] No, just push
```

If the user chooses **[R]** and the automated review was already executed, present the existing result instead of re-executing.

## Automated Reviews (sub-agents)

The type of review depends on the task's impact. Security review is delegated to `devsquad.review` when it is invoked — both never run separately.

### High impact: Implementation Review (includes security)

**Triggers** (any of):

- Task classified as high impact
- Multiple user stories affected
- Changes to public API or schema

Execute `devsquad.review` as a **sub-agent**. Pass the feature, task, and modified files.

```
High impact task. Running independent review...
```

After sub-agent result:

- **PASSED**: Proceed with PR.
- **PASSED_WITH_FINDINGS**: Present findings and ask if they want to fix now or proceed (findings are recorded in the review log).
- **FAILED**: Do not proceed with PR. Present critical findings and offer to fix or escalate for spec/plan review.

### Medium/low impact: Direct Security Review

When `devsquad.review` is **not** invoked automatically, assess if a security review is needed by evaluating the security triggers defined in `devsquad.security` (Authentication/Authorization, Sensitive data, External input, Persistence, Integrations).

If a trigger is detected, execute `devsquad.security` as a **sub-agent** in code mode.

After the result, present the verdict (PASSED / PASSED_WITH_FINDINGS / FAILED) following the same format above.

If no trigger is detected, proceed with PR.

### Summary: who runs what

| Impact | Review | Security |
|--------|--------|----------|
| High | `devsquad.review` (auto) | Delegated by `devsquad.review` internally |
| Medium/Low + security trigger | No (available via `[R]`) | `devsquad.security` direct |
| Medium/Low without trigger | No (available via `[R]`) | No |

## Record Technical Debt

If during implementation you find problematic code **outside the scope of the current task**, record it as a work item.

| Signal | Example |
|--------|---------|
| Existing TODO/FIXME/HACK comments | `// TODO: refactor this` |
| Significant duplication | Same logic in 3+ places |
| Excessive coupling | Change in one module requires changes in several others |
| Code without tests in critical area | Business logic without coverage |
| Outdated dependency with vulnerability | Package with known CVE |

Ask the user:

```
I identified technical debt outside the scope of this task:

[problem description]
Files: [list]
Suggested severity: [high/medium/low]

[C] Create tech debt work item on the board
[I] Ignore (do not record)
```

If confirmed, create the work item following the `work-item-creation` skill (Tech Debt section).

## Determine Target Branch

Before creating the PR, determine the target branch:

```bash
cat .memory/git-config.md 2>/dev/null
```

Use `Integration Branch` from the config. If it doesn't exist, use the repository's default branch.

## Create Pull Request

### Detect Platform

Read `.memory/board-config.md` to determine the repo platform. If it contains `Platform: azure-devops` or the git remote points to `dev.azure.com` or `visualstudio.com`, use ADO tools. Otherwise use GitHub tools.

### Check for Existing PR

```
# GitHub
github/list_pull_requests(owner, repo, head: "<owner>:<branch>", state: "open")

# Azure DevOps
ado/repo_pull_request(action: "list", status: "active", sourceRefName: "refs/heads/<branch>")
```

If an open PR already exists, inform and ask if they want to update the existing one.

Push the branch:

```bash
git push -u origin <branch-name>
```

Create PR with:

- **Title**: Based on the main issue/task
- **Body**:
  ```markdown
  ## Description

  [Summary of what was implemented]

  ## Related issue

  Closes #[number]

  ## Changes

  - [list of main changes]

  ## Checklist

  - [ ] Tests passing
  - [ ] Code follows project standards
  - [ ] Documentation updated (if needed)
  ```

### Closing keyword rules (do not skip)

The PR body **must** include one of GitHub's recognized closing keywords on its own line for every work item the PR fully resolves. Only these keywords trigger automatic close on merge: `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`. `Refs #N` and `See #N` are read-only and do **not** close anything.

| Situation | Use | Example |
|---|---|---|
| PR fully implements/resolves a tracked task, story, bug, or spike | `Closes #N` (one per resolved item, on its own line) | `Closes #11` |
| PR contributes to a parent feature, epic, or related issue but does not close it | `Refs #N` | `Refs #1` |
| PR partially addresses an issue and intentionally leaves follow-up | `Refs #N` plus a "Remaining work" note in the body | `Refs #11` + `Remaining: …` |

Examples that work and examples that silently break:

```markdown
# Works (issues #11 and #29 auto-close on merge; #1 stays open as parent)
Closes #11
Closes #29
Refs #1

# Silently broken (#11 and #29 stay open)
Refs #11 #29 #1
```

Spike PRs are not exempt: if the spike's deliverable is complete, `Closes #<spike>` is required. Use `Refs` only when the spike is intentionally incomplete and the issue should remain open for follow-up.

### Pre-flight check

Before calling `github/create_pull_request` or `ado/repo_pull_request_write`, verify:

1. Identify every work item the PR resolves (typically: the task or story the implementation was started from, plus any sub-issues fully delivered in this branch).
2. For each resolved item, confirm a `Closes #N`, `Fixes #N`, or `Resolves #N` line exists on its own line in the body.
3. If any resolved item is missing its closing keyword (or only appears under `Refs`), regenerate the body before creating the PR.
- **Labels**: Inherit labels from the issue (feature, priority, etc.)

Use the platform-appropriate tool:

```
# GitHub
github/create_pull_request(owner, repo, title, body, head: "<branch>", base: "<target>")

# Azure DevOps
ado/repo_pull_request_write(action: "create", title, description, sourceRefName: "refs/heads/<branch>", targetRefName: "refs/heads/<target>")
```

After creating the PR, ask about reviewers:

```
Pull Request created: [link]

Would you like to assign reviewers?

[Y] Yes, suggest (search repo members)
[N] No, I'll request review manually
[name] Assign directly to: _
```

If the user chooses [Y] or provides names, use `github/update_pull_request` with the `reviewers` field to assign.

## Check CI (post-creation)

After PR creation, check the status of checks:

```
github/pull_request_read(owner, repo, pullNumber, method: "get_check_runs")
```

Report summarized check status (passed / failed / pending).

If there are failures, use `github/get_job_logs` (if available) to fetch logs from failed jobs and present a diagnosis.

Report:

```
Pull Request created: [link]

Branch: [branch] -> [integration-branch]
Issue: Closes #[number]
Reviewers: [list or "none assigned"]
CI: [summarized status]
```

## Request Copilot Review (optional)

If the project uses GitHub Copilot, offer automated review via `github/request_copilot_review(owner, repo, pullNumber)`.

## Update PR Branch

If the PR is behind the base branch, offer update via `github/update_pull_request_branch(owner, repo, pullNumber)`.

## Merge PR

If CI passed and reviews were approved, offer merge with options: squash, rebase, or merge commit.

If confirmed, use `github/merge_pull_request(owner, repo, pullNumber, merge_method: "<choice>")`.

## Push Only (no PR)

The Integration Branch Guard (above) must pass before pushing. If the current branch is the integration branch, the guard offers recovery options before reaching this step.

```bash
git push -u origin <branch-name>
```

Inform that the PR can be opened later by invoking the skill again.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It works in staging, it will work in production" | Production has different data, traffic patterns, and edge cases. Monitor after deploy. |
| "We do not need feature flags for this" | Every non-trivial feature benefits from a kill switch. Even "simple" changes can break things. |
| "Monitoring is overhead" | Not having monitoring means discovering problems from user complaints instead of dashboards. |
| "The review is a formality" | Reviews that rubber-stamp changes miss bugs, security issues, and architectural drift. |
| "Rolling back is admitting failure" | Rolling back is responsible engineering. Shipping a broken feature to users is the failure. |
