# Feature Spec: Xcode Project/Workspace Compatibility Baseline

Status: Draft
Owner: TBD
Last updated: 2026-06-20
Related board items: Epic #1, Feature #2

## 1. Executive Summary

This feature defines the baseline compatibility contract required for reliable DevSquad Copilot usage in Xcode-centered development workflows.

The first release must support project/workspace open, indexing readiness, and build command reliability across:
- latest stable Xcode major
- previous stable Xcode major
- a minimum macOS mapping for each supported Xcode major

The primary outcome for v1 is that supported projects/workspaces can open, index, and execute build commands reliably with predictable behavior and actionable fallback when unsupported.

## 2. Problem Statement

Teams using Xcode cannot reliably use DevSquad Copilot due to compatibility gaps and inconsistent behavior across project/workspace layouts and toolchain versions.

This causes:
- blocked adoption in Xcode workflows
- degraded developer productivity
- low confidence in assistant reliability for Apple-platform projects

## 3. Goals

1. Establish an explicit and testable Xcode compatibility baseline contract.
2. Ensure supported projects/workspaces open successfully and reach indexing-ready state.
3. Ensure build command execution is reliable for supported baseline combinations.
4. Provide clear, actionable fallback messaging for unsupported combinations.

## 4. Non-Goals

1. Full workflow parity for authoring/navigation assist behaviors (handled in Feature #3).
2. Broad compatibility matrix and CI gate policy hardening (handled in Feature #4).
3. Support for Xcode versions outside the defined baseline.
4. Custom toolchain integrations beyond baseline open/index/build reliability.

## 5. Scope

### In Scope

1. Baseline detection for:
- Xcode major version
- macOS version
- project/workspace type and structure

2. Reliable execution path for:
- opening .xcodeproj and .xcworkspace
- indexing readiness checks
- build command execution for supported combinations

3. Unsupported path behavior:
- deterministic detection
- explicit reason code
- actionable remediation guidance

### Out of Scope

1. Auto-remediation of unsupported local environments.
2. End-to-end optimization of build performance.
3. Advanced cross-repo or monorepo orchestration semantics beyond baseline detection.

## 6. Assumptions

1. Supported Xcode versions are defined as the current and previous stable majors at release time.
2. Minimum macOS mapping per supported Xcode major follows official Apple compatibility requirements.
3. Validation uses representative fixture repositories for Apple-platform project types.

## 7. Users and Primary Journeys

### User Story 1 (P1)
As an Xcode developer, I want my project or workspace to open through the compatibility layer so that I can start work without setup uncertainty.

Acceptance intent:
- supported .xcodeproj and .xcworkspace are detected and opened successfully
- unsupported structures are rejected with explicit remediation guidance

### User Story 2 (P1)
As an Xcode developer, I want indexing readiness to be validated before build execution so that build operations are reliable and predictable.

Acceptance intent:
- readiness checks gate build command execution
- readiness failures return actionable feedback instead of silent failure

### User Story 3 (P1)
As an Xcode developer, I want build commands to run reliably on supported baseline combinations so that I can trust the workflow.

Acceptance intent:
- build invocation succeeds for supported baseline combinations
- failure modes include normalized error classification

## 8. Edge Cases and Failure Modes

1. Project exists but contains unsupported dependency/toolchain config.
2. Workspace opens but indexing never reaches ready state within timeout.
3. Build command partially executes and exits with non-zero status.
4. Xcode version appears supported but paired macOS version is below minimum.
5. Multiple schemes/targets exist and default resolution is ambiguous.

## 9. Functional Requirements

1. The system must detect and validate Xcode major version at runtime.
2. The system must detect and validate macOS version against per-Xcode-major minimum requirements.
3. The system must classify project inputs as supported or unsupported for .xcodeproj/.xcworkspace baseline shapes.
4. The system must provide deterministic open behavior for supported inputs.
5. The system must perform indexing readiness checks before build execution.
6. The system must execute baseline build commands reliably for supported combinations.
7. The system must emit normalized reason codes for unsupported states and build/index failures.
8. The system must provide actionable fallback guidance when unsupported conditions are detected.

## 10. Data/Domain Entities

1. CompatibilityProfile
- xcodeMajor
- minMacOS
- supportedProjectShapes

2. WorkspaceDescriptor
- inputPath
- kind (project/workspace)
- structureFlags

3. CompatibilityResult
- status (supported/unsupported)
- reasonCode
- remediation

4. BuildExecutionResult
- command
- exitCode
- classification
- diagnostics

## 11. Success Criteria

1. Open reliability: >= 95% successful open on supported fixtures.
2. Index readiness reliability: >= 95% readiness pass rate on supported fixtures within agreed timeout.
3. Build command reliability: >= 90% successful baseline build execution on supported fixtures.
4. Unsupported-path quality: 100% of unsupported outcomes include reason code and remediation guidance.

## 12. Conformance Cases

1. Must: Supported Xcode/macOS + valid .xcworkspace opens, reaches indexing readiness, and executes baseline build command successfully.
2. Must: Supported Xcode/macOS + valid .xcodeproj opens, reaches indexing readiness, and executes baseline build command successfully.
3. Must: Unsupported Xcode/macOS combination is rejected before build with explicit reason code and remediation.
4. Must Not: The system must not attempt build execution when compatibility validation fails.

## 13. Cross-Cutting Invariants

1. Compatibility validation runs before any build execution path.
2. Unsupported states never fail silently.
3. Error outputs include machine-readable classification plus user-facing remediation.

## 14. Open Questions

1. Which fixture repositories are canonical for baseline validation?
2. What timeout threshold is accepted for indexing readiness in CI and local runs?
3. Which build command profile is canonical for baseline (for example, target/scheme defaults)?

## 15. Spec Evolution Log

- 2026-06-20: Initial draft created from kickoff Feature #2 and specify decisions.
