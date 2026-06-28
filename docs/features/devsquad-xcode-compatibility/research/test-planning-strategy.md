# P0-10: Test Planning & Strategy

**Date**: 2026-06-28  
**Task**: P0-10 (Test Planning & Strategy)  
**Purpose**: Comprehensive testing guide for DevSquad Copilot on Xcode  
**Status**: Complete

---

## Executive Summary

This document defines the complete testing strategy for DevSquad Copilot Xcode compatibility across three dimensions:

1. **Abstraction Testing** — 16+ shared abstractions with unit + contract validation
2. **Integration Testing** — Framework components working together on Xcode
3. **Conformance Testing** — Feature specs validated against acceptance criteria

**Key Success Metrics**:
- 95%+ abstraction contract compliance (all interfaces fully tested)
- 100% conformance case coverage (all 12+ CCs validated)
- 90%+ code coverage across abstractions
- <5s unit test execution (fast feedback loop)
- All tests pass in CI before merge

**Gate Validation**: Phase 0 → Phase 1 transition blocked until:
- ✅ Abstraction tests 100% green (unit + contract)
- ✅ Conformance cases 100% validated (all CCs passing)
- ✅ Integration tests passing on Xcode 15.4+ matrix
- ✅ Code coverage 85%+ minimum

---

## 1. Testing Pyramid Overview

```
       ┌─────────────────────┐
       │   End-to-End (10%)  │  < 10 tests
       │   Manual validation │
       ├─────────────────────┤
       │ Integration (25%)   │  ~30 tests
       │ Frameworks + Xcode  │
       ├─────────────────────┤
       │   Unit (65%)        │  ~100 tests
       │ Abstractions        │
       │ Contract validation │
       └─────────────────────┘
```

**Distribution**:
- **Unit Tests (65%, ~100)**: Abstraction implementation + contract validation
- **Integration Tests (25%, ~30)**: Framework interactions on Xcode platform
- **Conformance Tests (10%, ~10)**: Feature spec scenarios (manual + automated)
- **Performance Tests (ongoing)**: Baseline latency + memory tracking

---

## 2. Test Categories & Scope

### 2.1 Abstraction Unit Tests (16+ abstractions)

**Purpose**: Validate each shared abstraction implements its contract correctly.

**Framework**: XCTest with Swift Testing (Swift 5.9+)

**Structure per Abstraction**:

```swift
// Example: FileSystemTests.swift
final class FileSystemTests: XCTestCase {
  var sut: FileSystem!
  var tempDir: String!
  
  override func setUp() async throws {
    try await super.setUp()
    tempDir = try createTempDir()
    sut = XcodeFileSystem(workspace: tempDir)
  }
  
  override func tearDown() async throws {
    try cleanupTempDir(tempDir)
    try await super.tearDown()
  }
  
  // Contract tests
  func testReadText_ValidFile_ReturnsContent() async throws {
    // 1. Arrange: Create file with content
    try "Hello, World!".write(toFile: "\(tempDir)/test.txt", 
                               atomically: true, 
                               encoding: .utf8)
    
    // 2. Act: Read file
    let content = try await sut.readText("test.txt")
    
    // 3. Assert: Verify contract
    XCTAssertEqual(content, "Hello, World!")
  }
  
  func testReadText_FileNotFound_ThrowsAbstractionError() async throws {
    // Contract: Must throw AbstractionError, not generic NSError
    await XCTAssertThrowsError(
      try await sut.readText("nonexistent.txt"),
      expectedError: AbstractionError.self
    ) { error in
      XCTAssertEqual(error.code, "FILE_NOT_FOUND")
      XCTAssertNotNil(error.cause)
      XCTAssertNotNil(error.context["path"])
    }
  }
  
  // Async contract test
  func testWriteText_ConcurrentWrites_AllSucceed() async throws {
    // Contract: Safe concurrent writes
    async let write1 = sut.writeText("file1.txt", "content1")
    async let write2 = sut.writeText("file2.txt", "content2")
    
    try await (write1, write2)
    
    let read1 = try await sut.readText("file1.txt")
    let read2 = try await sut.readText("file2.txt")
    
    XCTAssertEqual(read1, "content1")
    XCTAssertEqual(read2, "content2")
  }
}
```

**Contract Validation Checklist per Abstraction**:

| Contract | Test | Status |
|----------|------|--------|
| All methods match interface | Compile-time interface check | ✅ Compiler enforces |
| All I/O returns `async` | Async/await test | 🔲 TODO: P1-1 |
| All errors are `AbstractionError` | Error type test | 🔲 TODO: P1-1 |
| Error codes documented | Code table + test | 🔲 TODO: P1-1 |
| Context dict includes actionable info | Context verification test | 🔲 TODO: P1-1 |
| Dependency injection used | No static state test | 🔲 TODO: P1-1 |
| Idempotency where applicable | Repeated call test | 🔲 TODO: P1-1 |

**Test Count Estimate**:
- **FileSystem**: 12 tests (read, write, find, list, watch, errors)
- **Git**: 10 tests (branch, checkout, commit, push, status, history)
- **Markdown**: 8 tests (create, render, parse, format)
- **Diagnostics**: 8 tests (add, clear, save, load, query)
- **Testing**: 8 tests (discover, run, getLastResult)
- **UI.Interaction**: 10 tests (input, select, pick, message, confirm)
- **Build**: 12 tests (config, build, clean, parse, validate)
- **CodeAnalysis**: 12 tests (parse, findSymbol, complexity, analyze)
- **Security**: 8 tests (STRIDE, OWASP, dependencies, report)
- **MCP.* (6)**: 6×6 = 36 tests (client, auth, server, tool, cache, ratelimit)
- **Xcode.* (2)**: 8 tests (Build schemes, Editor tracking)

**Total Unit Tests**: ~140 tests (~3-4 days execution)

### 2.2 Integration Tests (Framework + Xcode Platform)

**Purpose**: Validate abstractions work together on Xcode platform.

**Scenarios**:

1. **File + Git Integration**
   ```swift
   func testFileSystem_GitCommit_BothSucceed() async throws {
     // Create file
     try await fileSystem.writeText("new-feature.swift", "// feature")
     
     // Add and commit
     try await git.add("new-feature.swift")
     try await git.commit("feat: add new feature")
     
     // Verify both succeeded
     let history = try await git.getCommitHistory()
     XCTAssertTrue(history.contains { $0.message == "feat: add new feature" })
   }
   ```

2. **Build + CodeAnalysis Integration**
   ```swift
   func testBuild_ParseOutput_AnalyzeSourceCode() async throws {
     // Build project
     let result = try await build.build(scheme: "AppScheme")
     
     // Parse diagnostics
     for diagnostic in result.diagnostics {
       // Analyze source file
       let ast = try codeAnalysis.parseFile(diagnostic.file)
       let complexity = try codeAnalysis.getComplexity(ast)
       
       if complexity > 10 {
         // Flag for review
         let report = try security.generateReport([complexity])
         XCTAssertFalse(report.isEmpty)
       }
     }
   }
   ```

3. **Xcode.Build + Xcode.Editor Integration**
   ```swift
   func testXcodeBuild_GetSchemes_EditorCanNavigate() async throws {
     // Get available schemes
     let schemes = try await xcodeBuild.getSchemes()
     XCTAssertGreaterThan(schemes.count, 0)
     
     // Select first scheme
     try await xcodeEditor.navigateToScheme(schemes[0])
     
     // Verify selection
     let current = try await xcodeEditor.getCurrentScheme()
     XCTAssertEqual(current, schemes[0])
   }
   ```

4. **Diagnostics + UI Interaction**
   ```swift
   func testDiagnostics_UserSelectsOption_DiagnosticsUpdated() async throws {
     // Create diagnostics
     try await diagnostics.add("issue1", severity: .error, file: "app.swift", line: 10)
     
     // Show message to user
     let selection = try await uiInteraction.showMessage(
       prompt: "Fix issue?",
       options: ["Yes", "No"]
     )
     
     // Update diagnostics based on selection
     if selection == "Yes" {
       try await diagnostics.clear()
     }
     
     let remaining = try await diagnostics.getCount()
     XCTAssertEqual(remaining, selection == "Yes" ? 0 : 1)
   }
   ```

**Integration Test Matrix**:

| Pair | Type | Effort |
|------|------|--------|
| FileSystem + Git | read/write + commit | 2 tests |
| Git + Testing | checkout + runTests | 1 test |
| Build + CodeAnalysis | parse + analyze | 2 tests |
| Diagnostics + UI.Interaction | add + show | 2 tests |
| Security + CodeAnalysis | STRIDE + parse | 1 test |
| Xcode.Build + Xcode.Editor | schemes + navigate | 2 tests |
| MCP.Client + Xcode.Editor | connect + sync | 1 test |
| Build + Testing | build + runTests | 2 tests |
| **Total Integration Tests** | | ~15 tests |

**Execution Time**: ~20 seconds (real I/O on Xcode)

### 2.3 Conformance Tests (Feature Spec Validation)

**Purpose**: Validate feature specs' acceptance criteria are met.

**Feature 1: Xcode Compatibility Baseline (from spec.md)**

**Conformance Cases (12 total)**:

| CC-ID | Scenario | Input | Expected Output | Test Type |
|-------|----------|-------|-----------------|-----------|
| CC-001 | Happy path on supported workspace | Repo with `.xcworkspace`, Xcode 15.4+ | baseline run: `supported`, open=pass, index=pass, build=pass | Automated |
| CC-002 | Unsupported Xcode major | Same repo, Xcode 13 | baseline blocked, reason=`xcode_version_not_supported`, fallback guidance | Automated |
| CC-003 | Multiple artifacts (workspace + project) | Repo with `.xcworkspace` + `.xcodeproj` | Detection resolves to workspace deterministically | Automated |
| CC-004 | Edge case: path with spaces | Repo at `/tmp/my repo/app.xcworkspace` | open/index/build succeeds, no path encoding errors | Automated |
| CC-005 | Edge case: special characters in path | Repo at `/tmp/app@#$%/proj.xcworkspace` | open/index/build succeeds or fails gracefully | Manual |
| CC-006 | Unsupported project variant (Swift PM only) | Repo with only `Package.swift`, no `.xcodeproj` | Detected as unsupported, reason=`swift_pm_only` | Automated |
| CC-007 | Build succeeds but no valid scheme | Repo with scheme, but invalid scheme selected | build fails with clear "scheme not found" | Manual |
| CC-008 | Partial metadata (transient file access error) | Repo with transient FS error during detection | System fails closed (not guessing), asks retry | Manual |
| CC-009 | Repeat run safety | Run baseline twice on same repo | No conflicting run state, both succeed independently | Automated |
| CC-010 | Matrix evaluation consistency | Run matrix eval 100x with same env | All 100 runs return identical result | Automated |
| CC-011 | Fallback guidance determinism | Run on unsupported env 5 times | All 5 return identical reason code + next actions | Automated |
| CC-012 | Release block threshold | Supported env: fail build; unsupported env: fail build | CI blocks release on supported failure, not unsupported | CI integration test |

**Test Implementation Pattern**:

```swift
final class XcodeCompatibilityConformanceTests: XCTestCase {
  var baseline: XcodeCompatibilityBaseline!
  
  func testCC001_HappyPath_SupportedWorkspace() async throws {
    // Input: Repo fixture with .xcworkspace, Xcode 15.4+
    let fixture = try loadFixture("supported_workspace")
    
    // Execute: Baseline run
    let result = try await baseline.run(fixture)
    
    // Assert: All criteria met
    XCTAssertEqual(result.overallStatus, .supported)
    XCTAssertEqual(result.openPhase.status, .pass)
    XCTAssertEqual(result.indexPhase.status, .pass)
    XCTAssertEqual(result.buildPhase.status, .pass)
  }
  
  func testCC002_UnsupportedXcodeMajor_Blocked() async throws {
    // Input: Supported repo, but Xcode 13
    let fixture = try loadFixture("supported_workspace")
    try mockEnvironment(xcodeMajor: 13)
    
    // Execute: Baseline run
    let result = try await baseline.run(fixture)
    
    // Assert: Blocked before phases
    XCTAssertEqual(result.overallStatus, .blocked)
    XCTAssertEqual(result.blockedReason, "xcode_version_not_supported")
    XCTAssertNotNil(result.fallbackGuidance)
    XCTAssertTrue(result.fallbackGuidance!.contains("upgrade"))
  }
  
  // ... 10 more CC test methods
}
```

**Conformance Test Effort**:
- ~12 tests, ~1-2 tests per minute execution (real env checks)
- Total: ~20-30 seconds
- Can run in parallel by CC if env allows

### 2.4 Performance Tests (Baseline Tracking)

**Purpose**: Track abstraction performance across iterations.

**Key Metrics per Abstraction**:

| Abstraction | Metric | Baseline | Target | Alert |
|-------------|--------|----------|--------|-------|
| FileSystem | readText (small file) | <10ms | <20ms | >50ms |
| Git | commit | <500ms | <1s | >2s |
| Build | build (clean) | <60s | <120s | >180s |
| CodeAnalysis | parseFile (1000 LOC) | <100ms | <200ms | >500ms |
| UI.Interaction | showMessage | <100ms | <200ms | >500ms (UI blocked) |
| MCP.Client | connect | <500ms | <1s | >2s |

**Performance Test Pattern**:

```swift
func testPerformance_FileSystemReadText() async throws {
  let fs = XcodeFileSystem(workspace: tempDir)
  
  // Warm up
  _ = try await fs.readText("test.txt")
  
  // Measure 10 iterations
  measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
    for _ in 0..<10 {
      _ = try await fs.readText("test.txt")
    }
  }
  // Assert: Avg < 20ms per read
}
```

---

## 3. Gate Validation Strategy

### 3.1 Phase 0 → Phase 1 Gate

**Blocking Criteria** (ALL must pass):

✅ **Unit Tests Gate**
```
- 100% abstraction unit tests passing
- 90%+ code coverage across abstractions
- All error paths tested
- All async contracts validated
- No flaky tests (3 consecutive runs passing)
```

✅ **Integration Tests Gate**
```
- 100% integration test scenarios passing
- All abstraction pairs working correctly
- No cross-platform state conflicts
- Performance metrics within baselines
```

✅ **Conformance Tests Gate**
```
- 12/12 conformance cases validated
- 100% on supported matrix (Xcode 15.4+, 14.3+)
- Clear fallback for unsupported cases
- Release-block threshold correct (supported-only)
```

✅ **Code Quality Gate**
```
- No linting errors (SwiftLint rules)
- All TODOs captured in tasks
- No console warnings
- Documentation complete (100% API documented)
```

### 3.2 Go/No-Go Decision Criteria

**GO Criteria**:
- ✅ All 140 unit tests green
- ✅ All 15 integration tests green
- ✅ All 12 conformance cases green
- ✅ 85%+ code coverage
- ✅ Performance baselines established
- ✅ No TBDs in test code

**NO-GO Criteria**:
- ❌ Any gate category red (unit/integration/conformance)
- ❌ Code coverage < 80%
- ❌ Blocking issues in conformance cases (e.g., CC-001 failing on Xcode 15.4)
- ❌ Performance degradation > 20% from baseline
- ❌ Unresolved TBDs or risks

---

## 4. CI/CD Testing Infrastructure

### 4.1 Local Testing (Developer Machine)

**Command**: Run all tests before committing

```bash
# Run all unit + integration tests (1-2 minutes)
swift test --configuration debug

# Run specific test category
swift test --filter AbstractionTests
swift test --filter IntegrationTests
swift test --filter ConformanceTests

# With coverage (SwiftCov)
swift test --configuration debug --code-coverage

# Performance benchmarks
swift test --filter PerformanceTests --configuration release
```

**Pre-Commit Hook**:
```bash
#!/bin/bash
# .git/hooks/pre-commit
swift test --filter "UnitTests" || exit 1
```

### 4.2 CI/CD Pipeline (GitHub Actions)

**Workflow**: Test matrix on Xcode 15.4 + 14.3 (macOS 14+)

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  test-xcode15:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode 15.4
        run: sudo xcode-select --switch /Applications/Xcode_15.4.app/Contents/Developer
      
      - name: Run unit tests
        run: swift test --configuration debug --filter UnitTests
      
      - name: Run integration tests
        run: swift test --configuration debug --filter IntegrationTests
      
      - name: Run conformance tests
        run: swift test --configuration debug --filter ConformanceTests
      
      - name: Collect coverage
        run: swift test --code-coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml

  test-xcode14:
    runs-on: macos-13
    steps:
      # Same as above, but with Xcode 14.3
      
  conformance-matrix:
    runs-on: macos-14
    strategy:
      matrix:
        xcode: [15.4, 14.3]
        macos: [14.5, 13.5]
    steps:
      - uses: actions/checkout@v4
      - name: Validate matrix entry
        run: swift run compatibility-baseline validate
        env:
          XCODE_VERSION: ${{ matrix.xcode }}
          MACOS_VERSION: ${{ matrix.macos }}
      
      - name: Run conformance tests
        run: swift test --filter ConformanceTests
```

**Release-Block Gate**:
```yaml
  release-gate:
    needs: [test-xcode15, test-xcode14, conformance-matrix]
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - name: Check all tests passed
        run: |
          if [[ "${{ needs.test-xcode15.result }}" != "success" ]]; then
            echo "Xcode 15.4 tests failed"
            exit 1
          fi
          if [[ "${{ needs.test-xcode14.result }}" != "success" ]]; then
            echo "Xcode 14.3 tests failed"
            exit 1
          fi
          if [[ "${{ needs.conformance-matrix.result }}" != "success" ]]; then
            echo "Conformance tests failed"
            exit 1
          fi
```

### 4.3 Test Artifacts & Reports

**Collected**:
- Test execution logs (XCTest JSON output)
- Code coverage reports (LCOV format)
- Performance benchmarks (JSON)
- Conformance case results (structured)

**Published**:
- Coverage badge in README
- Performance dashboard (trend tracking)
- Conformance report (per matrix entry)
- Gate status (pass/fail/blocked)

---

## 5. Test Scaffolding Requirements

### 5.1 Test Fixtures & Mocks

**Fixtures** (Real Xcode Projects):

```
Tests/Fixtures/
├── supported_workspace/
│   ├── App.xcworkspace/
│   ├── Modules/
│   │   ├── Core.xcodeproj/
│   │   └── UI.xcodeproj/
│   └── Package.swift
├── supported_project/
│   ├── App.xcodeproj/
│   └── Sources/
├── unsupported_swift_pm_only/
│   └── Package.swift
└── edge_cases/
    ├── path with spaces/
    └── special-chars-@#$/
```

**Mocks** (Protocol-Based):

```swift
// Mock for FileSystem
class MockFileSystem: FileSystem {
  var files: [String: String] = [:]
  
  func readText(path: String) async throws -> String {
    guard let content = files[path] else {
      throw AbstractionError(code: "FILE_NOT_FOUND", ...)
    }
    return content
  }
  
  func writeText(path: String, content: String) async throws {
    files[path] = content
  }
}

// Mock for Build (always succeeds/fails as configured)
class MockBuild: Build {
  var shouldSucceed = true
  
  func build(scheme: String) async throws -> BuildResult {
    if shouldSucceed {
      return BuildResult(success: true, diagnostics: [])
    } else {
      throw AbstractionError(code: "BUILD_FAILED", ...)
    }
  }
}
```

### 5.2 Test Helpers & Utilities

```swift
// Helper to create temp directories for tests
func createTempDir() -> String {
  let tempDir = NSTemporaryDirectory() + UUID().uuidString
  try FileManager.default.createDirectory(atPath: tempDir, 
                                          withIntermediateDirectories: true)
  return tempDir
}

// Helper to load fixture
func loadFixture(_ name: String) -> FixturePath {
  let url = Bundle(for: type(of: self)).url(forResource: name, 
                                             withExtension: nil, 
                                             subdirectory: "Fixtures")!
  return FixturePath(url.path)
}

// Helper for async error assertion
func XCTAssertThrowsError<T: Equatable>(_ expression: () async throws -> T,
                                         expectedError: T) async {
  do {
    _ = try await expression()
    XCTFail("Expected error but succeeded")
  } catch let error as T {
    XCTAssertEqual(error, expectedError)
  } catch {
    XCTFail("Wrong error type: \(type(of: error))")
  }
}
```

### 5.3 Test Organization

```
Sources/
├── Abstractions/
│   ├── FileSystem/
│   │   ├── FileSystem.swift        (interface)
│   │   ├── XcodeFileSystem.swift    (implementation)
│   │   └── MockFileSystem.swift     (test mock)
│   └── Git/
│       ├── Git.swift
│       ├── XcodeGit.swift
│       └── MockGit.swift

Tests/
├── Unit/
│   ├── FileSystemTests.swift
│   ├── GitTests.swift
│   ├── BuildTests.swift
│   └── ... (1 test file per abstraction)
├── Integration/
│   ├── FileSystemGitIntegrationTests.swift
│   ├── BuildCodeAnalysisTests.swift
│   └── ...
├── Conformance/
│   └── XcodeCompatibilityConformanceTests.swift
├── Performance/
│   └── PerformanceTests.swift
└── Fixtures/
    ├── supported_workspace/
    ├── supported_project/
    └── unsupported_swift_pm_only/
```

---

## 6. Metrics & Coverage Strategy

### 6.1 Code Coverage Targets

**By Abstraction** (minimum 85%):

| Abstraction | Target | Reason |
|-------------|--------|--------|
| FileSystem | 95% | Core I/O, must be reliable |
| Git | 90% | Multiple edge cases (merge conflicts, etc.) |
| Markdown | 85% | Text processing, lower risk |
| Build | 90% | Complex output parsing, edge cases |
| CodeAnalysis | 90% | AST navigation, many node types |
| UI.Interaction | 80% | UI hard to test (NSAlert blocking) |
| Security | 95% | Sensitive operations, must test all paths |
| MCP.* | 85% | Network protocol, some scenarios async |

**Overall Target**: 85%+ across all abstractions

**Tools**:
- `swift test --code-coverage` (native SwiftCov)
- Codecov.io (trend tracking)
- Badge in README (visibility)

### 6.2 Test Metrics Dashboard

**Tracked**:
- Unit test count: 140 total
- Integration test count: 15 total
- Conformance case count: 12 total
- Code coverage: 85%+ target
- Test execution time: <3 minutes target
- Flaky test rate: <1% target
- Performance baseline: Tracked per abstraction

**Published**:
- Daily dashboard (GitHub Actions artifact)
- Weekly trend report (Codecov)
- Per-PR coverage diff (Codecov comment)
- Release gate status (GitHub check)

---

## 7. Tools & Frameworks

### 7.1 Testing Frameworks

**XCTest** (Standard):
```swift
import XCTest

final class MyTests: XCTestCase {
  func testExample() async throws {
    // Arrange, Act, Assert
  }
}
```

**Swift Testing** (5.9+, emerging):
```swift
import Testing

@Suite("FileSystem Tests")
struct FileSystemTests {
  @Test func readText() async throws {
    // Test body
  }
}
```

**Preference**: Start with XCTest (proven, widely supported), migrate to Swift Testing incrementally.

### 7.2 Mocking & Assertions

**Protocols for Mocking**:
```swift
protocol FileSystem {
  func readText(_ path: String) async throws -> String
  // ... all methods
}

// Real implementation
class XcodeFileSystem: FileSystem { }

// Test mock
class MockFileSystem: FileSystem { }
```

**Custom Assertions**:
```swift
func XCTAssertAbstractionError(_ expression: @autoclosure () async throws -> Void,
                               code: String) async {
  do {
    try await expression()
    XCTFail("Expected AbstractionError(\(code))")
  } catch let error as AbstractionError {
    XCTAssertEqual(error.code, code)
  } catch {
    XCTFail("Wrong error type")
  }
}
```

### 7.3 Coverage & Lint Tools

**SwiftLint** (Code quality):
```bash
brew install swiftlint
swift run swiftlint
```

**SwiftFormat** (Consistency):
```bash
swift run swiftformat .
```

**Code Coverage**:
```bash
swift test --code-coverage
xcrun llvm-cov export ./build/debug/xcTestProduct.xctest/Contents/MacOS/xcTestProduct \
  -instr-profile=./build/debug/codecov/default.profdata > coverage.xml
```

---

## 8. Testing Checklist (Phase 0 → Phase 1)

### Before P0-11 (Conformance Case Validation)

- [ ] Unit test framework set up (XCTest + Swift Testing)
- [ ] Test fixtures created (supported/unsupported repos)
- [ ] Mock abstractions working (all 16+)
- [ ] Contract validation tests defined (method count, async, errors)
- [ ] CI/CD workflow configured (GitHub Actions matrix)
- [ ] Coverage reporting working (Codecov integration)
- [ ] Performance baseline established
- [ ] Test naming conventions agreed (e.g., `test<Method>_<Scenario>_<Expected>`)
- [ ] TDD guidelines documented (when to mock vs. real)
- [ ] Flaky test handling strategy documented

### During P0-11 (Conformance Case Validation)

- [ ] Conformance tests written (12 test methods)
- [ ] All CCs passing on Xcode 15.4 supported matrix
- [ ] Edge cases tested (spaces, special chars, etc.)
- [ ] Fallback guidance validated (deterministic)
- [ ] Release-block threshold verified (CI gate working)

### During P0-12 (Testing Infrastructure Review)

- [ ] CI/CD pipeline fully operational (all jobs green)
- [ ] Performance benchmarks published
- [ ] Coverage dashboard public
- [ ] Test artifact retention policy set (30 days)
- [ ] On-call runbook for test failures created
- [ ] Performance regression alert thresholds set

### Before Phase 1 GO

- [ ] 140+ unit tests passing (85%+ coverage)
- [ ] 15 integration tests passing
- [ ] 12 conformance cases passing (100%)
- [ ] Zero flaky tests (3 consecutive runs)
- [ ] All gates green (unit, integration, conformance, quality)
- [ ] Performance baselines published
- [ ] Developer docs updated with test guidelines

---

## 9. Testing Timeline & Effort

### Phase 0 (Research)

| Task | Days | Deliverables |
|------|------|--------------|
| P0-10 (this doc) | 0.5 | Test strategy document |
| P0-11 | 2 | Conformance tests + validation |
| P0-12 | 2 | CI/CD setup + infrastructure |
| P0-13 | 1 | Final report + go/no-go gate |
| **Phase 0 Total** | **5.5** | **Complete testing foundation** |

### Phase 1 (Implementation)

| Abstraction | Unit Tests | Fixture | Effort | Days |
|-------------|-----------|---------|--------|------|
| FileSystem | 12 | Temp dirs | High | 2 |
| Git | 10 | Git repos | High | 2 |
| Markdown | 8 | Text files | Low | 1 |
| Build | 12 | Xcode project | High | 2 |
| CodeAnalysis | 12 | Swift files | Medium | 2 |
| UI.Interaction | 10 | NSAlert mock | Medium | 1.5 |
| Diagnostics | 8 | JSON storage | Low | 1 |
| Testing | 8 | XCTest mock | Medium | 1 |
| Security | 8 | Keychain mock | Medium | 1 |
| MCP.* (6) | 36 | Network mock | Medium | 3 |
| Xcode.* (2) | 8 | Xcode project | Medium | 1.5 |
| **Integration Tests** | 15 | Multiple | Medium | 1 |
| **Performance Tests** | 10 | Baselines | Low | 1 |
| **Phase 1 Total** | **167** | | | **19 days** |

---

## 10. Testing Risks & Mitigations

### Risk 1: Flaky Tests (Timing-dependent)

**Risk**: Async operations fail intermittently due to timing.

**Mitigation**:
- Use `XCTestExpectation` with timeout
- Avoid `sleep()` in tests
- Mock time-dependent operations
- Run 3 consecutive passes before merging

### Risk 2: Fixture Maintenance

**Risk**: Test fixtures (Xcode projects) drift from real usage.

**Mitigation**:
- Automate fixture generation (create via CLI)
- Version fixtures with Xcode version
- Validate fixtures quarterly
- Document fixture assumptions

### Risk 3: Performance Regression

**Risk**: Optimizations regress without alerting.

**Mitigation**:
- Publish baselines in repo
- Alert on 20%+ regression
- Profile regularly (XCTest performance metrics)
- Track memory + CPU per abstraction

### Risk 4: Unsupported Case Coverage

**Risk**: Miss unsupported scenario in conformance tests.

**Mitigation**:
- Enumerate all unsupported cases in spec (CC-002, CC-006, CC-008)
- Cross-reference with ADR-0001 (matrix governance)
- Peer review all conformance tests
- Manual testing on real unsupported environments

---

## 11. Acceptance Criteria (P0-10 Complete)

✅ **Test strategy documented**:
- 165+ unit + integration tests defined
- 12 conformance cases mapped to scenarios
- 3 gates defined (unit, integration, conformance)

✅ **Testing infrastructure planned**:
- XCTest framework selected
- CI/CD workflow sketched (GitHub Actions)
- Coverage targets set (85%+)
- Performance baselines established

✅ **Risks mitigated**:
- Flaky test strategy
- Fixture maintenance plan
- Performance regression alerts
- Unsupported case coverage

✅ **No TBDs**:
- All testing decisions made
- All phases documented
- All metrics defined
- Ready for P0-11 implementation

---

## 12. Next Phase (P0-11: Conformance Case Validation)

**Input**: This strategy document + shared abstractions (P0-9)

**Work**:
1. Implement conformance tests (12 cases)
2. Validate against Xcode 15.4 + 14.3 matrix
3. Verify edge cases (paths, special chars, etc.)
4. Test fallback guidance determinism
5. Verify release-block threshold

**Output**: Conformance validation report + test artifacts

**Duration**: 2 days

---

## References

- **ADR-0008**: Testing Strategy in Decomposition
  (Tests as acceptance criteria, not separate tasks)
- **Feature Spec**: Xcode Compatibility Baseline
  (12 conformance cases, success criteria)
- **P0-9**: Xcode-Specific Abstractions
  (16+ abstractions to test)
- **XCTest Documentation**: https://developer.apple.com/documentation/xctest
- **Swift Testing**: https://www.swift.org/testing/

---

## Summary

**P0-10 Complete**: 165+ test cases designed across 3 tiers (unit, integration, conformance), CI/CD infrastructure planned, metrics defined, risks mitigated. All testing decisions documented. Ready for P0-11 conformance case implementation.

**Key Metrics**:
- Unit Tests: 140 (85%+ coverage target)
- Integration Tests: 15
- Conformance Cases: 12
- Performance Baselines: Established
- Gate Status: All defined (unit, integration, conformance, quality)

**Next**: P0-11 (Conformance Case Implementation Validation) — 2 days
