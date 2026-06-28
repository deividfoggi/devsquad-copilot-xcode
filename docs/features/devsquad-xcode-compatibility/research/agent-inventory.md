# P0-1: Agent Inventory Audit

**Issue**: GitHub #5  
**Phase**: Phase 0 - Inventory & Gap Analysis  
**Status**: IN PROGRESS  
**Date**: 2026-06-28  

---

## Overview

Complete inventory of all 12 DevSquad agents with Xcode compatibility assessment. This document establishes baseline understanding of agent capabilities, dependencies, and Xcode feasibility.

### Agent Categories

- **Lifecycle Agents** (7): Project initialization through implementation
- **Support Agents** (5): Review, security, sprint planning, backlog health, framework extension

---

## Part 1: Lifecycle Agents

### 1. devsquad.init

**Purpose**: Initialize or update a project with SDD Framework configuration files and templates.

**Lifecycle Role**: Setup phase (entry point)

**Input Schema**:
```
{
  action: "create" | "update" | "verify" | "diff"
  scope: "config" | "docs" | "scaffold" | "all"
  targetProject?: string
  force?: boolean
}
```

**Outputs**:
- Framework configuration files (copilot-instructions.md, instruction files)
- Documentation templates (features, migrations, ADRs, envisioning)
- Community scaffold files (SECURITY.md, CONTRIBUTING.md, LICENSE, CODE_OF_CONDUCT.md)

**Primary Tools/Skills Used**:
- `init-config`: Manages .github/copilot-instructions.md, coding guidelines
- `init-docs`: Creates spec/ADR/envisioning templates
- `init-scaffold`: Community files (SECURITY.md, etc.)
- File system operations (mkdir, write, update, diff)

**VS Code Dependencies**:
- File I/O capability
- Working directory access
- GitHub repository detection
- No VS Code UI extensions required

**Xcode Compatibility Assessment**:
- ✅ **PASS**: File I/O is platform-agnostic
- ✅ **PASS**: No VS Code-specific UI dependencies
- ✅ **PASS**: Directory structure creation is standard (mkdir, touch)
- ⚠️ **Minor**: Copilot-instructions.md format might need Xcode-specific defaults

**Implementation Strategy for Xcode**:
- Reuse file I/O abstractions (shared/core/FileSystem protocol)
- Create Xcode-specific template variants (xcode/.github/copilot-instructions.md)
- Swift implementation via Foundation.FileManager
- No UI blocking required

---

### 2. devsquad.envision

**Purpose**: Capture strategic product vision through structured questions about customer, pain points, goals, and constraints.

**Lifecycle Role**: Vision capture phase

**Input Schema**:
```
{
  mode: "interactive" | "direct" | "incremental"
  context?: {
    customer?: string
    domain?: string
    painPoints?: string[]
    goals?: string[]
  }
  targetFile?: string
  language?: string
}
```

**Outputs**:
- `docs/envisioning/README.md` with 5 structured sections
- Customer context, pain points, goals, constraints documented

**Primary Tools/Skills Used**:
- `documentation-style`: Markdown formatting standards
- `reasoning`: Decision logging
- User interaction: ASK questions via vscode_askQuestions tool
- Markdown generation

**VS Code Dependencies**:
- vscode_askQuestions tool (interactive Q&A)
- File creation capability
- No UI extensions

**Xcode Compatibility Assessment**:
- ✅ **PASS**: Interactive Q&A translates to any IDE (use native dialogs)
- ✅ **PASS**: Markdown generation is platform-agnostic
- ✅ **PASS**: Can use Xcode native UI for user input (NSOpenPanel, dialog boxes)
- ⚠️ **Minor**: vscode_askQuestions needs Xcode equivalent (NSPanel or command-line prompts)

**Implementation Strategy for Xcode**:
- Replace vscode_askQuestions with Xcode native input (NSOpenPanel, NSAlert)
- Reuse Markdown generation logic (platform-agnostic)
- Keep decision reasoning format identical
- Test: Use Xcode UI framework for interactive prompts

---

### 3. devsquad.kickoff

**Purpose**: Structure project hierarchy (epics, features, dependencies) and sync with issue tracking board.

**Lifecycle Role**: Project structure phase

**Input Schema**:
```
{
  mode: "vision-only" | "defined-scope" | "existing-board" | "zero"
  boardPlatform: "github" | "azure-devops"
  context?: {
    epics?: Epic[]
    features?: Feature[]
  }
  detectState?: boolean
}
```

**Outputs**:
- Board structure (epics, features, dependencies created)
- `docs/envisioning/structure.md` cache file
- Work items on GitHub Issues or Azure DevOps

**Primary Tools/Skills Used**:
- `board-config`: Detects GitHub/Azure DevOps
- `work-item-creation`: Creates epics, features on board
- `complexity-analysis`: Epic/feature sizing
- `documentation-style`: Markdown for cache file
- Board API tools (GitHub Issues API, Azure DevOps API)

**VS Code Dependencies**:
- GitHub REST API access (Octokit)
- Azure DevOps SDK
- mcp_github_mcp_se_issue_write tool
- mcp_azure_devops__wit_create_work_item tool

**Xcode Compatibility Assessment**:
- ✅ **PASS**: GitHub/Azure APIs are HTTP-based, platform-agnostic
- ✅ **PASS**: Markdown generation for structure.md is portable
- ⚠️ **PARTIAL**: MCP tools (GitHub, Azure) need to work from Xcode context
- ⚠️ **Minor**: Board state detection might need Xcode-specific caching

**Implementation Strategy for Xcode**:
- Use URLSession for GitHub/Azure REST API calls (native Swift)
- Ensure MCP server integration (shared/mcp/Client protocol)
- Implement board-config for Xcode (detect vs-code/ vs xcode-main branch)
- Cache board state locally (shared/artifacts/BoardCache)

---

### 4. devsquad.specify

**Purpose**: Create or update feature/migration specifications with user stories and conformance criteria.

**Lifecycle Role**: Specification authoring phase

**Input Schema**:
```
{
  type: "feature" | "migration"
  description: string
  context?: string
  existingSpec?: string
  targetFile: string
  language?: string
}
```

**Outputs**:
- `docs/features/{name}/spec.md` (feature spec)
- User stories (P1/P2/P3) with acceptance criteria
- Conformance table (minimum 3 test cases)
- Optional: Risk assessment, success criteria

**Primary Tools/Skills Used**:
- `documentation-style`: Markdown formatting
- `reasoning`: Decision logging
- `quality-gate`: Spec validation checklist
- `complexity-analysis`: User story sizing
- User interaction: Deep clarification questions

**VS Code Dependencies**:
- vscode_askQuestions tool for clarification
- File creation capability
- No UI extensions

**Xcode Compatibility Assessment**:
- ✅ **PASS**: Markdown spec generation is platform-agnostic
- ✅ **PASS**: User story formatting (P1/P2/P3) is text-based
- ✅ **PASS**: Conformance table format is portable
- ⚠️ **Minor**: Clarification questions use vscode_askQuestions (needs Xcode UI replacement)

**Implementation Strategy for Xcode**:
- Keep spec.md format identical (text-based, versioned in Git)
- Replace vscode_askQuestions with Xcode UI or command-line prompts
- Reuse quality-gate validation logic
- Test: Create sample specs in Xcode

---

### 5. devsquad.plan

**Purpose**: Technical planning with ADRs, data model, and architecture decisions.

**Lifecycle Role**: Architecture design phase

**Input Schema**:
```
{
  specFile: string
  targetProject?: string
  adrsFolder?: string
  mode: "architecture" | "security" | "engineering-practices"
  context?: {
    decisions?: Decision[]
    constraints?: string[]
  }
}
```

**Outputs**:
- `plan.md` with implementation strategy, timeline, commands
- Architecture Decision Records (ADRs) in docs/architecture/decisions/
- Design artifacts (data model diagrams, contracts, interfaces)

**Primary Tools/Skills Used**:
- `documentation-style`: Markdown for plan
- `reasoning`: Architecture decisions
- `adr-workflow`: ADR creation with Microsoft Learn lookup
- `complexity-analysis`: Effort estimation
- `engineering-practices`: Socratic guidance on CI/CD, branching, observability

**VS Code Dependencies**:
- File creation (plan.md, ADRs)
- mcp_azure_mcp_ser_pricing tool (cost estimation)
- User interaction (Socratic Q&A via vscode_askQuestions)

**Xcode Compatibility Assessment**:
- ✅ **PASS**: ADR format (Markdown) is platform-agnostic
- ✅ **PASS**: plan.md is text-based, versioned in Git
- ✅ **PASS**: Cost estimation via Azure APIs works from any platform
- ⚠️ **Minor**: Socratic Q&A needs Xcode UI replacement
- ⚠️ **Minor**: Microsoft Learn lookup (API) may need regional/auth considerations

**Implementation Strategy for Xcode**:
- Reuse ADR Markdown format (identical to VS Code)
- Replace vscode_askQuestions with Xcode UI prompts
- Ensure Azure Pricing API access from Xcode context (URLSession)
- Test: Create plan.md for Xcode-compatibility feature (already done)

---

### 6. devsquad.decompose

**Purpose**: Decompose specs into user stories, tasks, and work items on the board.

**Lifecycle Role**: Task decomposition phase

**Input Schema**:
```
{
  specFile: string
  targetProject?: string
  boardPlatform: "github" | "azure-devops"
  mode: "automatic" | "interactive"
  validateMissingAdrs?: boolean
}
```

**Outputs**:
- `tasks.md` with granular task breakdown
- Work items created on board (GitHub Issues or Azure DevOps)
- Milestones, labels, and dependencies assigned

**Primary Tools/Skills Used**:
- `work-item-creation`: Creates tasks, user stories, epics
- `board-config`: Detects GitHub/Azure DevOps
- `complexity-analysis`: Task sizing and effort estimation
- `work-item-workflow`: Task assignment and state management
- Board API tools (GitHub Issues, Azure DevOps)

**VS Code Dependencies**:
- GitHub/Azure DevOps APIs
- mcp_github_mcp_se_issue_write, mcp_azure_devops__wit_create_work_item tools
- File creation (tasks.md)

**Xcode Compatibility Assessment**:
- ✅ **PASS**: GitHub/Azure APIs are HTTP-based
- ✅ **PASS**: tasks.md is text-based Markdown
- ⚠️ **PARTIAL**: MCP tools (GitHub, Azure) must work from Xcode
- ⚠️ **Minor**: Work item state tracking needs local caching

**Implementation Strategy for Xcode**:
- Use shared/mcp/Client protocol for GitHub/Azure communication
- Reuse tasks.md Markdown format (identical)
- Implement work item cache (shared/artifacts/WorkItemCache)
- Test: Decompose already-created spec and tasks.md

---

### 7. devsquad.implement

**Purpose**: Execute implementation from tasks.md, GitHub issue, or Azure DevOps work item.

**Lifecycle Role**: Code implementation phase

**Input Schema**:
```
{
  source: "tasks.md" | "github-issue" | "azure-devops-work-item"
  targetTask?: string
  context?: string
  language?: string
  targetPath?: string
}
```

**Outputs**:
- Source code changes (language-specific)
- Pull requests (GitHub) or PR queue (Azure DevOps)
- Conventional commit messages
- PR automation, reviews, technical debt tracking

**Primary Tools/Skills Used**:
- `documentation-style`: Code comments, docstrings
- `reasoning`: Decision logging
- `work-item-creation`: Task updates
- `git-branch`: Branch creation per task
- `git-commit`: Conventional commits
- `pull-request`: PR automation and reviews
- Language-specific tools (TypeScript, Python, Swift, etc.)

**VS Code Dependencies**:
- Git CLI (git branch, commit, push)
- GitHub/Azure DevOps for PR creation
- Language-specific runtimes and tools
- IDE integration (diagnostics, test execution)

**Xcode Compatibility Assessment**:
- ✅ **PASS**: Git operations are platform-agnostic
- ✅ **PASS**: PR creation via GitHub/Azure APIs works from any OS
- ✅ **PASS**: Swift code generation is native to Xcode
- ⚠️ **PARTIAL**: Test execution depends on Swift tooling (XCTest)
- ⚠️ **Minor**: IDE diagnostics need Xcode equivalent to VS Code

**Implementation Strategy for Xcode**:
- Reuse git operations (platform-agnostic)
- For Xcode project: Use Swift/Objective-C code generation (native)
- Implement Xcode diagnostics bridge (shared/diagnostics/XcodeDiagnosticsProvider)
- Use XCTest for test execution
- Test: Implement first Xcode compatibility feature

---

## Part 2: Support Agents

### 8. devsquad.review

**Purpose**: Validate implementation against spec, ADRs, and plan with independent context.

**Support Role**: Code and design quality validation

**Input Schema**:
```
{
  scope: "pull-request" | "work-item" | "feature-completion"
  targetResource: {
    repo?: string
    prNumber?: number
    issueNumber?: number
  }
  context?: string
  autoCorrect?: boolean
}
```

**Outputs**:
- Review log with findings by severity (critical, high, medium, low, info)
- Spec deviations, ADR violations, plan misalignment flagged
- Self-correction recommendations or escalation

**Primary Tools/Skills Used**:
- `documentation-style`: Review report formatting
- `reasoning`: Review decision logging
- `quality-gate`: Multi-checker validation (spec, ADR, code, security, tests)
- Parallel validation workers for independent analysis

**VS Code Dependencies**:
- Pull request API (GitHub/Azure DevOps)
- Diff analysis capability
- File access to source code
- spec.md, plan.md, ADR access
- Test execution and result parsing

**Xcode Compatibility Assessment**:
- ✅ **PASS**: PR API calls are HTTP-based, platform-agnostic
- ✅ **PASS**: Review report (Markdown) is portable
- ⚠️ **PARTIAL**: Diff analysis may depend on platform-specific tools
- ⚠️ **Minor**: Test result parsing needs XCTest output parsing

**Implementation Strategy for Xcode**:
- Reuse PR API calls (GitHub/Azure DevOps via URLSession)
- Implement XCTest output parser (shared/testing/XCTestParser)
- Diff analysis via Git (platform-agnostic: git diff)
- Quality-gate validation identical to VS Code version

---

### 9. devsquad.security

**Purpose**: Security assessment in two modes: architectural (design-time) and code (implementation-time).

**Support Role**: Security threat analysis and compliance validation

**Input Schema**:
```
{
  mode: "architectural" | "code"
  scope: "feature" | "implementation" | "infrastructure"
  context?: {
    threatModel?: string
    dependencyList?: string[]
  }
  adrsFolder?: string
  sourceCode?: string
}
```

**Outputs**:
- Security report with STRIDE threats, OWASP vulnerabilities
- ADR security evaluation
- GitHub security alerts (code scanning, secret scanning, Dependabot)
- Trust boundary mapping, Azure compliance checks

**Primary Tools/Skills Used**:
- `documentation-style`: Security report formatting
- `reasoning`: Security decision logging
- STRIDE threat analysis framework
- OWASP vulnerability mapping
- GitHub/Azure security alert parsing

**VS Code Dependencies**:
- GitHub security alerts API (code scanning, Dependabot)
- Secret scanning capability
- Dependency analysis tools (npm audit, pip audit, etc.)
- Source code access

**Xcode Compatibility Assessment**:
- ✅ **PASS**: GitHub security alerts API is platform-agnostic
- ✅ **PASS**: STRIDE/OWASP frameworks are methodology-based
- ⚠️ **PARTIAL**: Dependency analysis tools vary by language (Swift Package Manager vs npm)
- ⚠️ **Minor**: Secret scanning needs Swift/Xcode-specific patterns

**Implementation Strategy for Xcode**:
- Reuse STRIDE/OWASP frameworks (methodology-based)
- Implement Swift Package Manager dependency analyzer (shared/security/SPMDependencyAnalyzer)
- Use GitHub security alerts API (platform-agnostic)
- Add Xcode-specific secret scanning patterns

---

### 10. devsquad.sprint

**Purpose**: Sprint planning with velocity analysis and adaptive capacity calculation.

**Support Role**: Sprint scope planning and estimation

**Input Schema**:
```
{
  teamSize: number
  availability?: number
  includeHistorical?: boolean
  sprintLength?: number
  backlogItems?: WorkItem[]
}
```

**Outputs**:
- `docs/sprints/sprint-N.md` with velocity analysis
- Scope options (committed vs stretch)
- Backlog readiness assessment
- Evidence-based capacity calculation

**Primary Tools/Skills Used**:
- `documentation-style`: Sprint planning report
- `reasoning`: Capacity and velocity calculations
- Board API access (GitHub Issues, Azure DevOps)
- Velocity trending and forecasting

**VS Code Dependencies**:
- Board API access (GitHub/Azure DevOps)
- Work item history retrieval
- Velocity calculation from closed items
- No UI extensions required

**Xcode Compatibility Assessment**:
- ✅ **PASS**: Board APIs are HTTP-based, platform-agnostic
- ✅ **PASS**: Sprint report (Markdown) is portable
- ✅ **PASS**: Velocity calculations are language-independent
- ✅ **PASS**: No platform-specific UI needed

**Implementation Strategy for Xcode**:
- Reuse board API calls (GitHub/Azure via URLSession)
- Identical sprint planning logic to VS Code
- No special Xcode considerations needed

---

### 11. devsquad.refine

**Purpose**: Analyze backlog health and apply scoped spec/ADR amendments during implementation.

**Support Role**: Continuous backlog and artifact health monitoring

**Input Schema**:
```
{
  mode: "backlog-health" | "spec-amendment"
  scope: "feature" | "sprint" | "entire-backlog"
  targetResource?: {
    specFile?: string
    adrFile?: string
  }
  amendmentContext?: string
}
```

**Outputs**:
- Backlog health analysis (spec-board mismatch, ADR gaps, orphan tasks)
- Scoped spec/ADR amendments (when `mode: "spec-amendment"`)
- Durable analysis artifacts

**Primary Tools/Skills Used**:
- `documentation-style`: Health report and amendment formatting
- `reasoning`: Amendment decision logging
- `work-item-creation`: Task creation for health issues
- Parallel workers for artifact and board analysis

**VS Code Dependencies**:
- Board API access (GitHub/Azure DevOps)
- File access (specs, ADRs)
- Work item creation capability

**Xcode Compatibility Assessment**:
- ✅ **PASS**: Board APIs are HTTP-based
- ✅ **PASS**: Spec/ADR amendments are Markdown edits (platform-agnostic)
- ✅ **PASS**: Health analysis is methodology-based
- ✅ **PASS**: No platform-specific UI needed

**Implementation Strategy for Xcode**:
- Reuse board API calls (GitHub/Azure)
- Identical refine logic to VS Code
- Use shared file system abstractions (shared/core/FileSystem)

---

### 12. devsquad.extend

**Purpose**: Guide creation of extensions for the SDD framework (skills, agents, instructions, hooks, MCP servers).

**Support Role**: Framework customization and extension

**Input Schema**:
```
{
  extensionType: "instruction" | "skill" | "agent" | "hook" | "tool-extension" | "mcp-server"
  description: string
  context?: string
  referenceExample?: string
}
```

**Outputs**:
- Custom instruction file (< 50 lines)
- Skill YAML + implementation guide (50-200 lines)
- Agent scaffold (> 200 lines, own tools)
- Hook configuration (deterministic validation)
- MCP server setup (external API access)

**Primary Tools/Skills Used**:
- `documentation-style`: Extension templates
- `reasoning`: Extension decision logging
- `agent-customization`: Instruction/skill/agent/hook scaffolding
- File creation and validation

**VS Code Dependencies**:
- File creation (.instructions.md, SKILL.md, .agent.md, hooks.yaml)
- Optional: MCP server HTTP access
- No UI extensions required

**Xcode Compatibility Assessment**:
- ✅ **PASS**: Extension format is Markdown/YAML (platform-agnostic)
- ✅ **PASS**: Instruction scaffolding is text-based
- ✅ **PASS**: MCP servers use HTTP (platform-agnostic)
- ✅ **PASS**: No platform-specific UI or dependencies

**Implementation Strategy for Xcode**:
- Reuse extension templates (identical to VS Code format)
- Use shared MCP client (shared/mcp/Client)
- Provide Xcode-specific skill examples (e.g., `xcode-build`, `xcode-test`)

---

## Part 3: Xcode Compatibility Summary

### Legend
- ✅ **PASS**: Fully compatible with Xcode (no changes needed)
- ⚠️ **PARTIAL**: Compatible with minor adaptations (UI replacement, API compatibility)
- ❌ **FAIL**: Incompatible (would require major refactor)

### Compatibility Matrix

| Agent | Category | Status | Notes |
|-------|----------|--------|-------|
| devsquad.init | Lifecycle | ⚠️ PARTIAL | File I/O is portable; copilot-instructions.md needs Xcode variant |
| devsquad.envision | Lifecycle | ⚠️ PARTIAL | Markdown output portable; vscode_askQuestions → Xcode UI |
| devsquad.kickoff | Lifecycle | ⚠️ PARTIAL | APIs portable; needs MCP integration for GitHub/Azure |
| devsquad.specify | Lifecycle | ⚠️ PARTIAL | Spec format portable; UI Q&A needs Xcode replacement |
| devsquad.plan | Lifecycle | ⚠️ PARTIAL | ADR format portable; Azure pricing API works; UI Q&A needs replacement |
| devsquad.decompose | Lifecycle | ⚠️ PARTIAL | tasks.md portable; MCP tools must be accessible from Xcode |
| devsquad.implement | Lifecycle | ⚠️ PARTIAL | Git portable; Swift code generation native; test execution via XCTest |
| devsquad.review | Support | ⚠️ PARTIAL | PR APIs portable; XCTest output parsing needed |
| devsquad.security | Support | ⚠️ PARTIAL | Threat frameworks portable; SPM dependency analysis needed |
| devsquad.sprint | Support | ✅ PASS | No adaptations needed |
| devsquad.refine | Support | ✅ PASS | No adaptations needed |
| devsquad.extend | Support | ✅ PASS | No adaptations needed |

### Compatibility Score

- **PASS**: 3/12 (25%)
- **PARTIAL**: 9/12 (75%)
- **FAIL**: 0/12 (0%)

**Overall Xcode Compatibility**: 📊 **75%+ viable with targeted adapations**

---

## Part 4: Key Findings

### ✅ Strengths
1. **No fundamental blockers**: All agents CAN work in Xcode with adaptations
2. **Artifact format is portable**: Spec.md, tasks.md, ADRs all use Markdown (platform-agnostic)
3. **APIs are HTTP-based**: GitHub, Azure DevOps, Azure services all use REST APIs
4. **Git operations are cross-platform**: Branch creation, commits, pushes work on any OS
5. **Swift support for code generation**: Native Xcode advantage for Swift/Objective-C

### ⚠️ Adaptation Points
1. **UI/Interaction**: vscode_askQuestions tool needs Xcode native UI replacement (NSAlert, NSOpenPanel)
2. **MCP Tools**: GitHub and Azure DevOps tools must be accessible from Xcode context
3. **Testing**: Test execution uses Swift XCTest instead of npm/pytest runners
4. **Diagnostics**: IDE error/warning integration needs Xcode equivalent
5. **Dependency Analysis**: Swift Package Manager analysis vs npm audit patterns

### 🎯 Implementation Priority
1. **Must-Have**: File I/O abstractions (shared/core/FileSystem)
2. **Must-Have**: MCP client for GitHub/Azure (shared/mcp/Client)
3. **Must-Have**: Git operations wrapper (shared/core/Git)
4. **Should-Have**: Xcode UI bridges (Xcode native dialogs)
5. **Nice-to-Have**: Xcode-specific extensions and optimizations

---

## Part 5: Shared Abstractions Required

Based on agent analysis, these abstractions are critical for Xcode implementation:

| Abstraction | Purpose | Used By Agents |
|-------------|---------|----------------|
| FileSystem | File I/O (create, read, update, delete) | init, specify, plan, decompose, review |
| MCP.Client | GitHub/Azure API access | kickoff, decompose, sprint, review |
| Git | Branch, commit, push operations | implement, review, kickoff |
| Markdown | Spec/ADR/Plan generation | specify, plan, review, extend |
| Diagnostics | IDE error/warning integration | implement, review |
| Testing | Test execution and parsing | implement, review |
| UI.Interaction | User Q&A and prompts | envision, specify, plan |
| Security | STRIDE/OWASP frameworks | security, review |

---

## Acceptance Criteria

- ✅ All 12 agents documented with input schemas, outputs, tools, dependencies
- ✅ Xcode compatibility assessment completed for each agent
- ✅ Compatibility matrix created (3 PASS, 9 PARTIAL, 0 FAIL)
- ✅ Key findings and adaptation points identified
- ✅ Shared abstractions list prepared for Phase 0-1 gap analysis
- ✅ No TBDs remaining (all agents assessed)

---

## Next Steps

→ **P0-2**: Skills Inventory Audit (document 50+ skills and dependencies)

→ **P0-5**: VS Code Surface Analysis (identify all APIs, UI patterns, and dependencies)

→ **P0-9**: Shared Abstractions Definition (create interfaces and implementation strategy for 8-12 abstractions)

---

**Status**: READY FOR REVIEW  
**Deliverable**: docs/features/devsquad-xcode-compatibility/research/agent-inventory.md  
**Lines**: 650+  
**Research Time**: ~2 hours (comprehensive agent documentation from framework source)
