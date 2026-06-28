# Phase 1: Xcode Implementation Roadmap

**Document**: Phase 1 Implementation Plan  
**Date**: 2026-06-28  
**Status**: Ready for Kickoff  
**Duration**: 18 days (4 weeks)  
**Gate 1 Target**: 2026-07-16  

---

## Executive Summary

### Phase 1 Objective

Implement core Xcode Compatibility Baseline abstractions and validate all 12 conformance cases (CC-001 through CC-012) on Xcode 15.4+ (primary) and 14.3+ (secondary).

**Success Criteria**:
- ✅ 12/12 conformance cases passing
- ✅ 140+ unit tests green (85%+ coverage)
- ✅ 15+ integration tests validating abstraction interactions
- ✅ Gate 1 approval (unit + integration + conformance)
- ✅ Ready for Phase 2 (advanced features)

### Phase 1 Scope

| Dimension | Count | Status |
|-----------|-------|--------|
| Tasks | 12 | P1.1-P1.12 |
| Conformance Cases | 12 | CC-001-CC-012 |
| Shared Abstractions | 16+ | From P0-8/P0-9 |
| Unit Tests | 140+ | From P0-10 |
| Integration Tests | 15+ | All pairs tested |
| Effort | 18 days | 4 weeks |

### Phase 1 Roadmap at a Glance

```
WEEK 1: Foundation (5 days)
├─ P1.1: Matrix Evaluator & Policy (3d) — CC-001, CC-002
└─ P1.2: Detection & Normalization (2d) — CC-003, CC-007

WEEK 2: Validation Flow (5 days)
├─ P1.3: Orchestration (2d) — CC-001, CC-008
├─ P1.4: Edge Cases (2d) — CC-005, CC-006
└─ P1.5: Error Handling (1d) — CC-009, CC-010

WEEK 3: Completeness (3 days)
├─ P1.6: Fallback Guidance (1d) — CC-004
├─ P1.7: Matrix Consistency (1d) — CC-011
└─ P1.8: Determinism (1d) — CC-012

WEEK 4: Gates & Deployment (5 days)
├─ Gate 1: Unit Tests (1d)
├─ Gate 2: Integration Tests (1d)
├─ Gate 3: Conformance Tests (1d)
└─ Production Readiness (2d)
```

---

## Phase 1 Tasks: Detailed Breakdown

### Week 1: Foundation

#### **P1.1: Matrix Evaluator & Policy**

**Conformance Cases**: CC-001 (happy path), CC-002 (unsupported version)

**Purpose**: 
- Establish Xcode compatibility matrix
- Implement version validation policy
- Create baseline evaluator orchestrator

**Description**:
The Matrix Evaluator is the core decision engine determining if a given environment (Xcode version, macOS, Swift version) is supported. This task establishes the policy layer that gates all other validation.

**Technical Scope**:

1. **Xcode.Build Abstraction** (Xcode-specific):
   - Implement `getActiveXcodeVersion()` — shell out to `xcode-select --version`
   - Implement `evaluateXcodeVersion()` — check against minimum version (14.3.1)
   - Return version tuple: `(major, minor, patch, buildNumber)`
   - Cache result for 60s

2. **Security Abstraction**:
   - Implement `validateAgainstPolicy(version)` — check version against matrix
   - Support matrix format: `{ "min": "14.3.1", "max": nil, "note": "..." }`
   - Return decision: `.supported`, `.blocked(reason)`, `.degraded`
   - Fallback guidance generation (see CC-002)

3. **Build Abstraction**:
   - Implement `evaluateMatrix()` — validate ALL supported entries (Xcode × macOS)
   - Return structured result: `{ status, reason, currentXcodeVersion, minRequired }`
   - Pure function (no side effects) for determinism (see CC-011)

**Success Criteria**:
- [ ] `getActiveXcodeVersion()` returns correct version on Xcode 15.4+
- [ ] `evaluateXcodeVersion()` correctly classifies as supported/blocked
- [ ] `validateAgainstPolicy()` enforces minimum version requirement
- [ ] Fallback guidance generated per CC-002 (see below)
- [ ] Matrix evaluation deterministic across 100 calls (100% match)
- [ ] Version caching works and invalidates correctly
- [ ] Test fixtures pass for Xcode 15.4 and 14.3

**Shared Abstractions Used**:
- `Xcode.Build` (version detection, scheme listing)
- `Security` (policy validation)
- `Build` (matrix evaluation)
- `Diagnostics` (error reporting)

**CC-002 Fallback Guidance**:
```swift
struct FallbackGuidance {
  let reasonCode: String  // "xcode_version_not_supported"
  let minimumXcodeVersion: String  // "14.3.1"
  let currentXcodeVersion: String  // e.g., "13.4.1"
  let nextActions: [String]  // ["Upgrade to Xcode 14.3.1 or later", "Download from App Store"]
}
```

**Test Code Pattern**:
```swift
// Unit: Matrix evaluation
func testEvaluateXcodeVersion_Supported() async throws {
  let xcode = XcodeVersion(major: 15, minor: 4, patch: 0)
  let result = sut.evaluateXcodeVersion(xcode)
  XCTAssertEqual(result, .supported)
}

func testEvaluateXcodeVersion_Unsupported() async throws {
  let xcode = XcodeVersion(major: 13, minor: 4, patch: 0)
  let result = sut.evaluateXcodeVersion(xcode)
  XCTAssertEqual(result, .blocked(reason: "xcode_version_not_supported"))
}

// Integration: Security + Build
func testValidateAgainstPolicy_WithSecurity() async throws {
  let version = try await xcodeBuild.getActiveXcodeVersion()
  let decision = try await security.validateAgainstPolicy(version)
  XCTAssertNotNil(decision.fallbackGuidance)
}

// Conformance: CC-001 happy path
func testCC001_HappyPath_SupportedVersion() async throws {
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: .supportedWorkspace)
  XCTAssertEqual(result.overallStatus, .supported)
}

// Conformance: CC-002 unsupported version
func testCC002_UnsupportedVersion() async throws {
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: .supportedWorkspace, xcode: .v13)
  XCTAssertEqual(result.overallStatus, .blocked)
  XCTAssertEqual(result.blockedReason, "xcode_version_not_supported")
}
```

**Dependencies**:
- Xcode.Build abstraction (P0-9)
- Security abstraction (P0-9)
- Build abstraction (P0-9)

**Effort**: 3 days
- Day 1: Xcode.Build version detection, caching, matrix policy
- Day 2: Security validation, fallback guidance generation
- Day 3: Integration tests, edge cases (build number parsing, cache invalidation)

**Success Metrics**:
- 15+ unit tests (version parsing, matrix evaluation, caching)
- 3+ integration tests (Security + Build, Diagnostics integration)
- 2 conformance tests (CC-001, CC-002)
- 85%+ code coverage on module
- <100ms version detection latency
- Deterministic matrix evaluation (100% consistency)

---

#### **P1.2: Detection & Normalization**

**Conformance Cases**: CC-003 (multi-artifact), CC-007 (Swift PM only)

**Purpose**:
- Detect workspace/project/SPM structures
- Normalize artifact paths
- Handle precedence rules

**Description**:
Detection is the bootstrap phase identifying project structure (Xcode workspace, project, or Swift Package Manager). Normalization ensures consistent path handling across filesystem operations.

**Technical Scope**:

1. **FileSystem Abstraction**:
   - Implement `findFiles(pattern)` — recursive search for `.xcworkspace`, `.xcodeproj`, `Package.swift`
   - Return ordered list: workspace first, then project, then SPM
   - Implement `readDirectory(path)` — list directory contents with error handling
   - Respect precedence: workspace > project > SPM

2. **CodeAnalysis Abstraction**:
   - Implement `parseFile(path)` — parse `project.pbxproj` to extract targets
   - Support `.pbxproj` (ASCII property list format)
   - Extract target names, build phases, scheme info

3. **Xcode.Build Abstraction**:
   - Implement `getSchemes()` — invoke `xcodebuild -list -json` for workspace/project
   - Parse JSON output, extract scheme names
   - Return schemes in order: default first, then alphabetical

4. **Security Abstraction**:
   - Implement `detectUnsupportedPatterns()` — classify project type
   - Detect patterns: Cocoapods, frameworks, non-standard build configs
   - Mark as `.unsupported`, `.partial`, or `.full` support

**Success Criteria**:
- [ ] `findFiles()` correctly detects workspace/project/SPM in nested structures
- [ ] Precedence rule enforced (workspace > project > SPM)
- [ ] `getSchemes()` returns all schemes from workspace/project
- [ ] Scheme ordering correct (default first)
- [ ] Path normalization handles spaces and special characters (see P1.4)
- [ ] `parseFile()` extracts target info from `.pbxproj`
- [ ] Unsupported patterns detected and classified
- [ ] All fixtures pass (supported workspaces, nested projects, SPM-only)

**Shared Abstractions Used**:
- `FileSystem` (directory/file detection)
- `Xcode.Build` (scheme discovery)
- `CodeAnalysis` (`.pbxproj` parsing)
- `Security` (pattern classification)
- `Diagnostics` (error tracking)

**Test Code Pattern**:
```swift
// Unit: FileSystem detection
func testFindFiles_WorkspaceFirst() async throws {
  let structure = try loadFixture("workspace_and_project")
  let results = try await fs.findFiles("*.xcworkspace")
  XCTAssertEqual(results.count, 1)
  XCTAssert(results[0].contains(".xcworkspace"))
}

func testFindFiles_PrecedenceRules() async throws {
  let results = try await fs.findFiles("*", types: [.workspace, .project, .spm])
  // Workspace should be first
  if results.count > 1 {
    XCTAssert(results[0].contains(".xcworkspace"))
  }
}

// Unit: Scheme discovery
func testGetSchemes_FromWorkspace() async throws {
  let schemes = try await xcodeBuild.getSchemes(workspace: fixture)
  XCTAssertGreaterThan(schemes.count, 0)
  XCTAssertEqual(schemes[0], "App")  // Default scheme first
}

// Unit: Target parsing
func testParseFile_ExtractTargets() async throws {
  let pbxproj = try loadFixture("project.pbxproj")
  let targets = try codeAnalysis.parseFile(pbxproj)
  XCTAssertGreaterThan(targets.count, 0)
  XCTAssert(targets.contains { $0.name == "App" })
}

// Conformance: CC-003 multi-artifact
func testCC003_MultiArtifact_WorkspaceWithProject() async throws {
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: .workspaceAndProject)
  // Should choose workspace
  XCTAssert(result.normalizedArtifact.contains(".xcworkspace"))
}

// Conformance: CC-007 SPM only
func testCC007_SPMOnly_NoWorkspaceOrProject() async throws {
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: .spmOnly)
  XCTAssertEqual(result.projectType, .spm)
  XCTAssert(result.normalizedArtifact.contains("Package.swift"))
}
```

**Dependencies**:
- FileSystem abstraction (P0-9)
- CodeAnalysis abstraction (P0-9)
- Xcode.Build abstraction (P0-9)
- Security abstraction (P0-9)

**Effort**: 2 days
- Day 1: FileSystem detection, precedence rules, scheme discovery via xcodebuild
- Day 2: Target parsing, unsupported pattern detection, integration tests

**Success Metrics**:
- 18+ unit tests (file detection, precedence, scheme parsing, target extraction)
- 2+ integration tests (FileSystem + Xcode.Build, CodeAnalysis integration)
- 2 conformance tests (CC-003, CC-007)
- 85%+ code coverage on module
- <50ms file detection on typical workspace
- Deterministic precedence (always workspace > project > SPM)

---

### Week 2: Validation Flow

#### **P1.3: Orchestration (Open/Index/Build Phases)**

**Conformance Cases**: CC-001 (happy path phases), CC-008 (build failure)

**Purpose**:
- Orchestrate three validation phases: open, index, build
- Handle phase sequencing and error propagation
- Generate structured phase results

**Description**:
The orchestration layer sequences three phases:
1. **Open**: Can we open the workspace/project?
2. **Index**: Can Xcode index the code?
3. **Build**: Can we successfully build?

Each phase can fail independently, and errors must be properly classified.

**Technical Scope**:

1. **Build Abstraction**:
   - Implement `build(scheme)` — run `xcodebuild -scheme ... -json`
   - Parse JSON output, extract build status
   - Return structured result: `{ status: pass|fail, duration, phase: build, output }`
   - Map xcodebuild error codes to standard errors

2. **Xcode.Build Abstraction**:
   - Implement phase execution sequencing
   - Orchestrate: open → index → build (fail-fast)
   - Return composite result with all phase statuses

3. **Diagnostics Abstraction**:
   - Track phase execution time
   - Log phase transitions
   - Accumulate errors for post-mortem analysis

**Success Criteria**:
- [ ] All three phases execute in sequence
- [ ] Fail-fast prevents unnecessary phase execution (if open fails, skip index/build)
- [ ] Phase timings accurate (<5% deviation)
- [ ] Build error codes correctly classified
- [ ] Invalid scheme error handled and reported (CC-008)
- [ ] Happy path returns all phases with status: pass
- [ ] Structured result format consistent and parseable

**Shared Abstractions Used**:
- `Build` (phase execution, error mapping)
- `Xcode.Build` (orchestration)
- `Diagnostics` (timing, logging)
- `Xcode.Editor` (sidecar integration if needed)

**Test Code Pattern**:
```swift
// Unit: Build phase execution
func testBuild_ValidScheme() async throws {
  let result = try await build.build(scheme: "App", configuration: "Debug")
  XCTAssertEqual(result.status, .pass)
  XCTAssertLessThan(result.duration, 60)  // <60s baseline
}

func testBuild_InvalidScheme() async throws {
  let result = try await build.build(scheme: "NonExistent")
  XCTAssertEqual(result.status, .fail)
  XCTAssertEqual(result.errorCode, "SCHEME_NOT_FOUND")
}

// Integration: Phase orchestration
func testPhaseOrchestration_HappyPath() async throws {
  let result = try await orchestrator.validate(fixture: .supportedWorkspace)
  XCTAssertEqual(result.openPhase.status, .pass)
  XCTAssertEqual(result.indexPhase.status, .pass)
  XCTAssertEqual(result.buildPhase.status, .pass)
}

func testPhaseOrchestration_FailFast() async throws {
  let result = try await orchestrator.validate(fixture: .unreadableProject)
  XCTAssertEqual(result.openPhase.status, .fail)
  // Index/Build should be skipped
  XCTAssertNil(result.indexPhase)
  XCTAssertNil(result.buildPhase)
}

// Conformance: CC-001 happy path with phases
func testCC001_HappyPath_AllPhasesPass() async throws {
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: .supportedWorkspace)
  XCTAssertEqual(result.overallStatus, .supported)
  XCTAssertEqual(result.openPhase.status, .pass)
  XCTAssertEqual(result.indexPhase.status, .pass)
  XCTAssertEqual(result.buildPhase.status, .pass)
}

// Conformance: CC-008 build failure
func testCC008_BuildFails_InvalidScheme() async throws {
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: .supportedWorkspace, invalidScheme: true)
  XCTAssertEqual(result.overallStatus, .failed)
  XCTAssertEqual(result.buildPhase.status, .fail)
  XCTAssertEqual(result.buildPhase.errorReason, "scheme_not_found")
}
```

**Dependencies**:
- P1.1 (Matrix Evaluator — version check before orchestration)
- P1.2 (Detection — identify artifact before orchestration)
- Build abstraction (P0-9)
- Xcode.Build abstraction (P0-9)
- Diagnostics abstraction (P0-9)

**Effort**: 2 days
- Day 1: Phase execution sequencing, error mapping, xcodebuild integration
- Day 2: Fail-fast logic, composite result aggregation, integration tests

**Success Metrics**:
- 20+ unit tests (phase execution, error codes, timing)
- 3+ integration tests (orchestration sequences, error propagation, Diagnostics)
- 2 conformance tests (CC-001, CC-008)
- 85%+ code coverage
- Build <60s on supported workspace
- All phases tracked and timed
- Deterministic error classification

---

#### **P1.4: Edge Cases (Spaces & Special Characters)**

**Conformance Cases**: CC-005 (spaces in paths), CC-006 (special chars)

**Purpose**:
- Handle filesystem paths with spaces
- Handle special characters in paths
- Ensure proper escaping/quoting

**Description**:
Filesystem paths often contain spaces and special characters. Process API arguments must be properly escaped to avoid shell injection and path misinterpretation.

**Technical Scope**:

1. **Process API Usage** (Xcode platform constraint):
   - Use Process with `.arguments` array (NOT shell string)
   - Avoid shell escaping via `arguments` property
   - Example: `Process().arguments = ["/path/to My Project/App.xcworkspace"]`

2. **FileSystem Abstraction**:
   - Implement path normalization
   - Support spaces: `/Users/dev/My Projects/App.xcworkspace`
   - Support special chars: `@`, `#`, `&`, `(`, `)`, `[`, `]`
   - Not supported: null bytes, control characters

3. **Build Abstraction**:
   - Pass paths via `.arguments` array (safe by default)
   - Example: `xcodebuild -workspace "My Workspace.xcworkspace" -scheme App`
   - Verify path integrity after passing to xcodebuild

**Success Criteria**:
- [ ] Paths with spaces handled correctly
- [ ] Paths with special chars (@, #, &, etc.) handled correctly
- [ ] Process.arguments used (not shell string concatenation)
- [ ] No shell injection vulnerabilities
- [ ] Path integrity verified after build
- [ ] Error messages contain readable paths (decoded from escaping)
- [ ] All fixtures pass (spaces, special chars, combinations)

**Shared Abstractions Used**:
- `FileSystem` (path normalization, special char handling)
- `Process API` (argument array safe passing)
- `Build` (xcodebuild integration)

**Test Code Pattern**:
```swift
// Unit: Path with spaces
func testNormalizePath_WithSpaces() async throws {
  let path = "/Users/dev/My Projects/App.xcworkspace"
  let normalized = fs.normalizePath(path)
  XCTAssertEqual(normalized, path)  // Unchanged (no escaping needed with array)
}

// Unit: xcodebuild argument construction
func testBuildArguments_WithSpacesInPath() async throws {
  let workspace = "/Users/dev/My App/MyApp.xcworkspace"
  let args = Build.constructArguments(workspace: workspace, scheme: "MyApp")
  // Should use array, not shell string
  XCTAssertEqual(args[1], "/Users/dev/My App/MyApp.xcworkspace")
  XCTAssertEqual(args[0], "-workspace")
}

// Unit: Special characters
func testNormalizePath_WithSpecialChars() async throws {
  let path = "/Users/dev/App@2.0#beta/App.xcworkspace"
  let normalized = fs.normalizePath(path)
  XCTAssertEqual(normalized, path)
}

// Conformance: CC-005 spaces in path
func testCC005_Spaces_InProjectPath() async throws {
  let fixture = try loadFixture("workspace_with_spaces")
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: fixture)
  XCTAssertEqual(result.overallStatus, .supported)
}

// Conformance: CC-006 special characters
func testCC006_SpecialChars_InProjectPath() async throws {
  let fixture = try loadFixture("workspace_with_special_chars")
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: fixture)
  XCTAssertEqual(result.overallStatus, .supported)
}

// Integration: Build with special paths
func testBuild_WithSpecialCharPaths() async throws {
  let workspace = "/tmp/Test@2.0#beta/My App.xcworkspace"
  let result = try await build.build(workspace: workspace, scheme: "App")
  XCTAssertEqual(result.status, .pass)
}
```

**Dependencies**:
- P1.1 (Matrix Evaluator)
- P1.2 (Detection)
- FileSystem abstraction (P0-9)
- Build abstraction (P0-9)

**Effort**: 2 days
- Day 1: Path normalization, safe argument construction, Process API integration
- Day 2: Edge case testing (combinations of spaces + special chars), security review

**Success Metrics**:
- 16+ unit tests (individual special chars, space handling, path normalization)
- 2+ integration tests (Build with special paths, end-to-end)
- 2 conformance tests (CC-005, CC-006)
- 85%+ code coverage
- Zero shell injection vulnerabilities
- Path handling deterministic

---

#### **P1.5: Error Handling & Recovery**

**Conformance Cases**: CC-009 (transient FS error), CC-010 (repeat run safety)

**Purpose**:
- Handle transient filesystem errors (retry logic)
- Ensure repeat runs produce consistent results
- Track run identity

**Description**:
Transient errors (network filesystem hiccups, temporary lock files) should be retried. Repeat runs must be deterministic — same input always produces same output.

**Technical Scope**:

1. **FileSystem Abstraction**:
   - Implement retry logic for transient FS errors
   - Error types: EACCES (permission denied), EIO (input/output error), ETIMEDOUT
   - Retry strategy: exponential backoff (100ms, 200ms, 400ms, 800ms — max 4 retries)
   - Total timeout: <5 seconds for transient error recovery

2. **Diagnostics Abstraction**:
   - Implement `generateRunId()` — UUID for uniqueness
   - Log run ID at startup for traceability
   - Store run ID in structured result

3. **Build Abstraction**:
   - Use run ID to isolate temporary build artifacts
   - Ensure build phase references run ID (for forensics)

**Success Criteria**:
- [ ] Transient FS errors retried automatically
- [ ] Exponential backoff applied (100ms → 800ms)
- [ ] Max 4 retries, timeout <5s
- [ ] All retries logged with timestamps
- [ ] Repeat runs with same input produce identical output
- [ ] Run ID stable within single run, unique across runs
- [ ] Run ID present in all structured results for traceability

**Shared Abstractions Used**:
- `FileSystem` (retry logic)
- `Diagnostics` (run ID generation, logging)
- `Build` (run-isolated artifacts)

**Test Code Pattern**:
```swift
// Unit: Transient error retry
func testRetry_TransientError() async throws {
  var attemptCount = 0
  let mockFS = MockFileSystem { path in
    attemptCount += 1
    if attemptCount < 3 {
      throw FileSystemError.io(.eio)  // Transient
    }
    return "success"
  }
  
  let result = try await fs.readFile(path, withRetry: true)
  XCTAssertEqual(result, "success")
  XCTAssertEqual(attemptCount, 3)
}

// Unit: Run ID generation
func testGenerateRunId_Unique() async throws {
  let id1 = try diagnostics.generateRunId()
  let id2 = try diagnostics.generateRunId()
  XCTAssertNotEqual(id1, id2)
  XCTAssert(UUID(uuidString: id1) != nil)  // Valid UUID
}

// Integration: Repeat run determinism
func testRepeatRun_DeterministicOutput() async throws {
  let fixture = .supportedWorkspace
  let baseline = XcodeCompatibilityBaseline()
  
  let result1 = try await baseline.validate(fixture: fixture)
  let result2 = try await baseline.validate(fixture: fixture)
  
  // Same input → same output (except run IDs)
  XCTAssertEqual(result1.overallStatus, result2.overallStatus)
  XCTAssertEqual(result1.normalizedTarget, result2.normalizedTarget)
  XCTAssertEqual(result1.openPhase.status, result2.openPhase.status)
  XCTAssertEqual(result1.buildPhase.duration, result2.buildPhase.duration)
  // Run IDs should differ
  XCTAssertNotEqual(result1.runId, result2.runId)
}

// Conformance: CC-009 transient FS error
func testCC009_TransientError_AutoRecovery() async throws {
  let fixture = try loadFixture("workspace_on_flaky_filesystem")
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: fixture)
  // Should succeed after retry
  XCTAssertEqual(result.overallStatus, .supported)
}

// Conformance: CC-010 repeat run safety
func testCC010_RepeatRun_ConsistentResults() async throws {
  let fixture = try loadFixture("supported_workspace")
  let baseline = XcodeCompatibilityBaseline()
  
  var results = [XcodeCompatibilityBaseline.Result]()
  for _ in 0..<5 {
    let result = try await baseline.validate(fixture: fixture)
    results.append(result)
  }
  
  // All 5 runs should have identical status/output
  let firstStatus = results[0].overallStatus
  for result in results.dropFirst() {
    XCTAssertEqual(result.overallStatus, firstStatus)
  }
}
```

**Dependencies**:
- P1.1, P1.2, P1.3 (previous tasks establish baseline)
- FileSystem abstraction (P0-9)
- Diagnostics abstraction (P0-9)

**Effort**: 1 day
- Day 1: Retry logic with exponential backoff, run ID generation, repeat run validation

**Success Metrics**:
- 12+ unit tests (retry logic, backoff timing, run ID uniqueness)
- 2+ integration tests (repeat run determinism, transient error recovery)
- 2 conformance tests (CC-009, CC-010)
- 85%+ code coverage
- Transient error recovery <5 seconds
- Repeat run byte-for-byte identical (except run ID)

---

### Week 3: Completeness

#### **P1.6: Fallback Guidance & Classification**

**Conformance Cases**: CC-004 (false positive prevention)

**Purpose**:
- Detect unsupported project variants
- Generate remediation guidance
- Prevent false positives (marking supported as unsupported)

**Description**:
Some projects may use patterns incompatible with automated baseline validation (custom build scripts, non-standard configurations). We must detect these and provide guidance without false positives.

**Technical Scope**:

1. **Security Abstraction**:
   - Implement `detectUnsupportedPatterns()` — scan for incompatible patterns
   - Patterns: Cocoapods, Carthage, Fastlane, Ruby build scripts, Tuist
   - Return classification: `.fullySupported`, `.partiallySupported`, `.unsupported`

2. **Diagnostics Abstraction**:
   - Generate remediation guidance for each unsupported pattern
   - Example: "Cocoapods detected. Recommendation: Update to Swift Package Manager or use Cocoapods with Xcode integration."

3. **Security Abstraction**:
   - Implement false-positive prevention logic
   - If pattern detected but project still builds, mark as `.partiallySupported` (not `.unsupported`)
   - Allow user override ("trust this project")

**Success Criteria**:
- [ ] Cocoapods correctly detected and classified
- [ ] Custom build scripts detected (*.rb files in project)
- [ ] Tuist projects detected (Tuist/Config.swift)
- [ ] False positives minimized (pattern presence ≠ incompatible)
- [ ] Remediation guidance accurate and actionable
- [ ] User trust mechanism prevents repeated guidance for same pattern

**Shared Abstractions Used**:
- `Security` (pattern detection)
- `CodeAnalysis` (code scanning for patterns)
- `Diagnostics` (guidance generation)
- `FileSystem` (scan for metadata files)

**Test Code Pattern**:
```swift
// Unit: Pattern detection
func testDetect_Cocoapods() async throws {
  let fixture = try loadFixture("workspace_with_cocoapods")
  let patterns = try await security.detectUnsupportedPatterns(fixture)
  XCTAssert(patterns.contains { $0 == .cocoapods })
}

func testDetect_Tuist() async throws {
  let fixture = try loadFixture("tuist_project")
  let patterns = try await security.detectUnsupportedPatterns(fixture)
  XCTAssert(patterns.contains { $0 == .tuist })
}

// Unit: Guidance generation
func testGenerateGuidance_ForCocoapods() async throws {
  let guidance = security.generateRemediationGuidance(for: .cocoapods)
  XCTAssert(guidance.contains("Swift Package Manager"))
  XCTAssert(guidance.contains("Cocoapods"))
}

// Conformance: CC-004 false positive prevention
func testCC004_FalsePositive_PatternPresentButBuilds() async throws {
  // Workspace has Cocoapods in Podfile, but build still succeeds
  let fixture = try loadFixture("cocoapods_but_builds")
  let baseline = XcodeCompatibilityBaseline()
  let result = try await baseline.validate(fixture: fixture)
  // Should be partiallySupported, not unsupported
  XCTAssertEqual(result.supportLevel, .partiallySupported)
  XCTAssertNotEqual(result.supportLevel, .unsupported)
}
```

**Dependencies**:
- P1.1-P1.5 (establish baseline before classification)
- Security abstraction (P0-9)
- CodeAnalysis abstraction (P0-9)
- FileSystem abstraction (P0-9)

**Effort**: 1 day
- Day 1: Pattern detection, classification logic, guidance generation, false-positive prevention

**Success Metrics**:
- 12+ unit tests (pattern detection, guidance generation, classification)
- 1 integration test (end-to-end classification flow)
- 1 conformance test (CC-004)
- 85%+ code coverage
- False positive rate <5% (validated on fixture suite)
- Guidance generation deterministic

---

#### **P1.7: Matrix Consistency & Repeat Runs**

**Conformance Cases**: CC-011 (matrix consistency 100x)

**Purpose**:
- Validate matrix evaluation is deterministic
- Ensure 100 repeat evaluations produce identical results
- No race conditions or nondeterministic behavior

**Description**:
The matrix evaluator must be a pure function: same input always produces same output. This is critical for CI/CD reliability.

**Technical Scope**:

1. **Build Abstraction**:
   - Implement pure function constraint (no global state, no time-dependent logic)
   - Ensure all matrix lookups deterministic
   - No randomization in logic

2. **Testing**:
   - Run matrix evaluation 100 times on same input
   - Verify all 100 outputs identical (byte-for-byte hash comparison)
   - Profile for timing variance (should be <10% delta)

**Success Criteria**:
- [ ] 100 repeat evaluations on same input produce identical output
- [ ] Output hash stable across all 100 runs
- [ ] Timing variance <10% (no large outliers)
- [ ] No race conditions detected under concurrent load
- [ ] No side effects (no global state modified)

**Shared Abstractions Used**:
- `Build` (matrix evaluation, pure function)
- `Diagnostics` (profiling, timing)

**Test Code Pattern**:
```swift
// Conformance: CC-011 matrix consistency 100x
func testCC011_MatrixConsistency_100x() async throws {
  let fixture = .supportedWorkspace
  let baseline = XcodeCompatibilityBaseline()
  
  var results = [String]()  // Hash of each result
  for i in 0..<100 {
    let result = try await baseline.validate(fixture: fixture)
    let hash = hashResult(result)
    results.append(hash)
  }
  
  // All 100 hashes should be identical
  let firstHash = results[0]
  for (index, hash) in results.enumerated() {
    XCTAssertEqual(hash, firstHash, "Run \(index) hash differs")
  }
}

// Unit: Pure function validation
func testMatrixEvaluation_IsPureFunction() async throws {
  let input = CompatibilityMatrix(xcode: "15.4", macos: "14.5")
  let result1 = Build.evaluateMatrix(input)
  let result2 = Build.evaluateMatrix(input)
  XCTAssertEqual(result1, result2)
  
  // No global state should be modified
  let stateAfter = getGlobalState()
  XCTAssertEqual(stateAfter, globalStateAtStart)
}
```

**Dependencies**:
- P1.1 (Matrix Evaluator implementation)
- Build abstraction (P0-9)

**Effort**: 1 day
- Day 1: Pure function validation, 100-run stress test, profiling and analysis

**Success Metrics**:
- 1+ unit test (pure function property)
- 1 conformance test (CC-011 with 100 runs)
- 100% hash consistency across all runs
- Timing variance <10%
- Zero race conditions under concurrent load

---

#### **P1.8: Fallback Determinism**

**Conformance Cases**: CC-012 (fallback determinism 5x)

**Purpose**:
- Ensure fallback guidance is deterministic
- Validate 5 repeat fallback generations produce identical guidance
- No randomization in guidance logic

**Description**:
When validation fails or is blocked, the fallback guidance must be deterministic. Users must see consistent recommendations across multiple runs.

**Technical Scope**:

1. **Security Abstraction**:
   - Ensure fallback guidance generation has no randomization
   - Sort all collections for determinism (e.g., `nextActions` sorted by string)
   - No timestamps or UUIDs in guidance text

2. **Diagnostics Abstraction**:
   - Include run-specific data (run ID) but store separately from guidance
   - Separate guidance from telemetry

**Success Criteria**:
- [ ] 5 repeat fallback generations produce identical text
- [ ] No randomization in nextActions ordering
- [ ] No timestamps embedded in guidance
- [ ] Run ID available separately but not in guidance text
- [ ] Guidance hash stable across all 5 runs

**Shared Abstractions Used**:
- `Security` (fallback guidance generation)
- `Diagnostics` (run ID, telemetry)

**Test Code Pattern**:
```swift
// Conformance: CC-012 fallback determinism 5x
func testCC012_FallbackDeterminism_5x() async throws {
  let fixture = try loadFixture("unsupported_xcode_13")
  let baseline = XcodeCompatibilityBaseline()
  
  var guidances = [String]()
  for _ in 0..<5 {
    let result = try await baseline.validate(fixture: fixture)
    let guidance = result.fallbackGuidance.serialize()
    guidances.append(guidance)
  }
  
  // All 5 guidances should be identical
  let firstGuidance = guidances[0]
  for (index, guidance) in guidances.enumerated() {
    XCTAssertEqual(guidance, firstGuidance, "Run \(index) guidance differs")
  }
}

// Unit: Deterministic guidance generation
func testFallbackGuidance_Deterministic() async throws {
  let reason = BlockedReason.xcodeVersionNotSupported(
    current: "13.4.1",
    required: "14.3.1"
  )
  
  let guidance1 = security.generateFallbackGuidance(for: reason)
  let guidance2 = security.generateFallbackGuidance(for: reason)
  
  XCTAssertEqual(guidance1, guidance2)
  // nextActions should be sorted
  XCTAssertEqual(guidance1.nextActions, guidance1.nextActions.sorted())
}
```

**Dependencies**:
- P1.1 (Matrix Evaluator — generates fallback scenarios)
- Security abstraction (P0-9)

**Effort**: 1 day
- Day 1: Determinism validation, 5-run stress test, ordering enforcement

**Success Metrics**:
- 1+ unit test (deterministic guidance)
- 1 conformance test (CC-012 with 5 runs)
- 100% guidance consistency across all runs
- Zero randomization in guidance text
- Deterministic nextActions ordering

---

## Week 4: Gates & Deployment

### Gate 1: Unit Tests

**Requirement**: 140+ unit tests green, 85%+ code coverage

**Mapping to P1 Tasks**:
| Task | Unit Tests | Coverage Target |
|------|------------|-----------------|
| P1.1 | 15+ | 90%+ |
| P1.2 | 18+ | 90%+ |
| P1.3 | 20+ | 90%+ |
| P1.4 | 16+ | 90%+ |
| P1.5 | 12+ | 90%+ |
| P1.6 | 12+ | 90%+ |
| P1.7 | 2+ | 90%+ |
| P1.8 | 2+ | 90%+ |
| **TOTAL** | **140+** | **85%+ overall** |

**Execution Target**: <1.5 minutes on CI (8-core macOS runner)

**Blocking Criteria**:
- ❌ If any unit test fails → GATE BLOCKED (fix before proceeding)
- ❌ If coverage <85% → GATE BLOCKED (add tests)
- ❌ If execution >2 minutes → GATE BLOCKED (optimize or profile)

---

### Gate 2: Integration Tests

**Requirement**: 15+ integration tests green, all abstraction pairs validated

**Mapping to P1 Tasks**:
| Pair | Test Count | Status |
|------|-----------|--------|
| FileSystem + Build | 2 | P1.2, P1.3 |
| Build + Security | 2 | P1.1 |
| FileSystem + CodeAnalysis | 2 | P1.2 |
| Build + Diagnostics | 2 | P1.3, P1.5 |
| Xcode.Build + Build | 2 | P1.3 |
| Security + Diagnostics | 2 | P1.6 |
| **Orchestration** | 3+ | Cross-abstraction |
| **TOTAL** | **15+** | ✅ |

**Execution Target**: <30 seconds on CI

**Blocking Criteria**:
- ❌ If any integration test fails → GATE BLOCKED
- ❌ If execution >1 minute → GATE BLOCKED

---

### Gate 3: Conformance Tests

**Requirement**: 12/12 CCs passing, 100% on supported matrix

**Mapping to P1 Tasks**:
| CC | P1 Task | Status |
|----|---------|--------|
| CC-001 | P1.1, P1.3 | ✅ PASS |
| CC-002 | P1.1 | ✅ PASS |
| CC-003 | P1.2 | ✅ PASS |
| CC-004 | P1.6 | ✅ PASS |
| CC-005 | P1.4 | ✅ PASS |
| CC-006 | P1.4 | ✅ PASS |
| CC-007 | P1.2 | ✅ PASS |
| CC-008 | P1.3 | ✅ PASS |
| CC-009 | P1.5 | ✅ PASS |
| CC-010 | P1.5 | ✅ PASS |
| CC-011 | P1.7 | ✅ PASS |
| CC-012 | P1.8 | ✅ PASS |
| **TOTAL** | | **12/12 PASS** |

**Matrix Validation**:
```
✅ Xcode 15.4 + macOS 14.5
✅ Xcode 15.4 + macOS 13.5
✅ Xcode 14.3 + macOS 14.5
✅ Xcode 14.3 + macOS 13.5
```

**Execution Target**: <3 minutes on CI (full matrix)

**Blocking Criteria**:
- ❌ If any CC fails → GATE BLOCKED
- ❌ If matrix coverage <100% → GATE BLOCKED
- ❌ If execution >5 minutes → GATE BLOCKED

---

## GitHub Issues: Decomposition Template

After this plan is approved, create GitHub issues for each task:

### Issue Template

```markdown
# P1.N: [Task Title]

**Conformance Case(s)**: CC-001, CC-002
**Phase**: Week 1
**Effort**: 3 days
**Priority**: P0 (critical path)

## Summary
[Description from plan]

## Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
...

## Implementation Plan
1. [Step 1]
2. [Step 2]
...

## Test Strategy
- Unit Tests: [Count]
- Integration Tests: [Count]
- Conformance Tests: [Count]

## Abstractions Used
- `Xcode.Build`
- `Security`
- ...

## Related
- Implements: CC-001, CC-002
- Depends on: P1.0 (baseline setup)
- Blocks: P1.2 (next task)

## Acceptance Criteria
- [ ] All success criteria met
- [ ] All tests green (Unit + Integration + Conformance)
- [ ] Code coverage 85%+
- [ ] Code reviewed and approved
- [ ] Merged to main branch
```

### Issue Creation Order
1. Create issues for P1.1-P1.8 (8 issues)
2. Link issues via "depends on" relationships
3. Create tracking issue "Gate 1: Unit Tests" (meta-task)
4. Create tracking issue "Gate 2: Integration Tests" (meta-task)
5. Create tracking issue "Gate 3: Conformance Tests" (meta-task)

---

## Sprint Schedule (Calendar View)

### Week 1: Foundation (Mon-Fri, 5 days)

| Day | Task | Hours | Cumulative |
|-----|------|-------|-----------|
| Mon (Jun 28) | P1.1 kickoff | 3h | 3h |
| Tue (Jun 29) | P1.1 continued | 8h | 11h |
| Wed (Jun 30) | P1.1 complete | 5h | 16h |
| Thu (Jul 1) | P1.2 kickoff | 8h | 24h |
| Fri (Jul 2) | P1.2 continued + review | 8h | 32h |

### Week 2: Validation (Mon-Fri, 5 days)

| Day | Task | Hours | Cumulative |
|-----|------|-------|-----------|
| Mon (Jul 5) | P1.3 kickoff | 8h | 40h |
| Tue (Jul 6) | P1.3 continued | 8h | 48h |
| Wed (Jul 7) | P1.4 kickoff | 8h | 56h |
| Thu (Jul 8) | P1.4 continued | 8h | 64h |
| Fri (Jul 9) | P1.5 + review | 8h | 72h |

### Week 3: Completeness (Mon-Fri, 3 days effective)

| Day | Task | Hours | Cumulative |
|-----|------|-------|-----------|
| Mon (Jul 12) | P1.6 kickoff | 8h | 80h |
| Tue (Jul 13) | P1.7 + P1.8 | 8h | 88h |
| Wed (Jul 14) | Polish + review | 8h | 96h |

### Week 4: Gates & Deployment (Thu-Fri, 2 days)

| Day | Task | Hours | Cumulative |
|-----|------|-------|-----------|
| Thu (Jul 15) | Gate 1 + Gate 2 execution | 8h | 104h |
| Fri (Jul 16) | Gate 3 + production readiness | 8h | 112h |

**Gate 1 Target Date**: 2026-07-16 (18 days from Phase 0 complete date 2026-06-28)

---

## Risk Assessment & Mitigations

### Risk 1: xcodebuild Output Parsing (P1.1, P1.3)

**Risk**: xcodebuild JSON format changes between Xcode versions.

**Probability**: Medium (Apple changes minor formatting occasionally)

**Impact**: High (build validation would fail)

**Mitigation**:
- Use `xcodebuild -json` stable contract
- Version-specific parsing logic in Build abstraction
- Test against Xcode 15.4 and 14.3 fixtures
- Fallback to text parsing if JSON unavailable
- **Effort**: Already included in P1.1/P1.3 timeline

### Risk 2: Scheme Discovery Variability (P1.2)

**Risk**: `xcodebuild -list -json` output varies based on workspace/project structure.

**Probability**: Low (well-defined contract)

**Impact**: Medium (scheme discovery might miss variants)

**Mitigation**:
- Test on variety of fixture structures (simple, complex, nested)
- Verify all schemes returned
- Document edge cases in code comments
- **Effort**: Already included in P1.2 timeline

### Risk 3: Transient FS Errors Hard to Reproduce (P1.5)

**Risk**: Transient errors difficult to test reproducibly.

**Probability**: High (by nature, transient errors are hard to trigger)

**Impact**: Medium (tests might not validate retry logic)

**Mitigation**:
- Use mock FileSystem for deterministic error injection
- Test with MockFileSystem that simulates transient errors
- Validate backoff timing with synthetic delays
- **Effort**: Already included in P1.5 timeline

### Risk 4: Gate 1 Coverage Target Ambitious (Week 4)

**Risk**: 85%+ code coverage hard to achieve in 4 weeks.

**Probability**: Low (modular design supports high coverage)

**Impact**: High (can't ship without meeting gate)

**Mitigation**:
- Design for testability (inversion of control, protocol-based abstractions)
- Incrementally test each task (don't defer to Week 4)
- Aim for 90%+ per task (buffer for cross-module uncovered paths)
- Use coverage tools (Xcode coverage reports, SonarQube if available)
- **Effort**: Already included in per-task timelines

---

## Success Metrics & Observability

### Key Performance Indicators (KPIs)

| Metric | Target | Success |
|--------|--------|---------|
| **Unit Test Pass Rate** | 100% | ✅ All tests green |
| **Integration Test Pass Rate** | 100% | ✅ All tests green |
| **Conformance Test Pass Rate** | 100% (12/12 CCs) | ✅ All CCs passing |
| **Code Coverage** | 85%+ | ✅ Coverage met |
| **Build Latency** | <60s | ✅ <60s on typical workspace |
| **Version Detection Latency** | <100ms | ✅ <100ms |
| **Error Recovery Time** | <5s (transient errors) | ✅ <5s |
| **Matrix Consistency** | 100% (100 runs) | ✅ All runs identical |
| **Fallback Determinism** | 100% (5 runs) | ✅ All guidances identical |

### Observability Instrumentation

Per P0-12 (Testing Infrastructure), track:

1. **CI/CD Metrics**:
   - Test pass/fail rate per job
   - Test execution time per task
   - Code coverage trend
   - Build latency on 4-matrix entries

2. **Performance Baselines** (from P0-12):
   - FileSystem.readText <5ms
   - Git.commit <500ms
   - Build.build <60s
   - CodeAnalysis <100ms
   - MCP.Client.connect <200ms

3. **Regression Detection**:
   - Alert if test execution >1.5m (Unit)
   - Alert if coverage drops >2%
   - Alert if build latency >70s

---

## Approval & Kick-off

### Sign-Off Checklist

- [ ] Phase 1 plan reviewed and approved
- [ ] 12 tasks breakdown confirmed
- [ ] Effort estimates realistic (18 days)
- [ ] GitHub issues created (P1.1-P1.8)
- [ ] Gate criteria understood
- [ ] Risk mitigations accepted
- [ ] Team ready to kick off P1.1

### Next Action: Kick-off P1.1

Upon approval, immediately:
1. Create GitHub issues for P1.1-P1.8
2. Create tracking issues for Gate 1/2/3
3. Assign P1.1 to developer
4. Start P1.1 "Matrix Evaluator & Policy" (3-day task)
5. Post daily updates to tracking issue

---

## Document Metadata

**Version**: 1.0  
**Status**: Ready for Review  
**Next Update**: After Phase 1 kickoff (daily progress updates)  
**Related Artifacts**:
- P0-10: Test Planning & Strategy
- P0-11: Conformance Case Validation
- P0-12: Testing Infrastructure
- Phase 1 GitHub Issues (to be created)
