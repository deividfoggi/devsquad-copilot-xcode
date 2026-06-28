# P0-8: Shared Abstractions Definition

**Status**: Complete  
**Date**: 2026-06-28  
**Scope**: Define 16+ shared abstractions for dual VS Code / Xcode implementation  
**Purpose**: Single source of truth for platform-agnostic interfaces across DevSquad Copilot  

---

## Table of Contents

1. [Abstraction Model Overview](#abstraction-model-overview)
2. [Core Abstractions (9)](#core-abstractions-9)
3. [MCP Layer Abstractions (6)](#mcp-layer-abstractions-6)
4. [Cross-Cutting Abstractions (1)](#cross-cutting-abstractions-1)
5. [Shared Interface Guidelines](#shared-interface-guidelines)
6. [Implementation Strategy](#implementation-strategy)

---

## Abstraction Model Overview

### Architecture

```
┌─────────────────────────────────────────────────┐
│           Agent Workflows (12)                  │  Platform-agnostic
│  (conductor, init, specify, plan, implement)    │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────┐
│           Skills (24)                           │  Platform-agnostic
│  (git-commit, git-branch, quality-gate, etc)    │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────┴────────────────────────────────┐
│      Shared Abstractions (16)                   │  Platform-agnostic
│  (FileSystem, Git, Markdown, MCP.*, etc)        │  interfaces
└────────────────┬────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼────┐      ┌─────▼──────┐
   │ VS Code │      │   Xcode    │  Platform-specific
   │Impl (TS)│      │  Impl (Sw) │  implementations
   └─────────┘      └────────────┘
```

### Design Principles

1. **Interface Segregation**: Minimal, focused contracts
2. **Dependency Injection**: No static state, testable
3. **Error Handling**: Consistent Result<T> pattern
4. **Async/Await**: All I/O operations support async
5. **Logging**: Built-in structured logging
6. **Caching**: Optional, transparent caching
7. **Retry Logic**: Built-in exponential backoff

### Shared Interface Pattern

All abstractions follow this pattern:

```typescript
// Shared interface (platform-agnostic)
export interface FileSystem {
  readText(path: string): Promise<string>;
  writeText(path: string, content: string): Promise<void>;
  // ...
}

// VS Code implementation
export class VSCodeFileSystem implements FileSystem {
  // Uses vscode.workspace APIs
}

// Xcode implementation
export class XcodeFileSystem implements FileSystem {
  // Uses FileManager APIs
}

// Factory (platform-aware)
export function createFileSystem(platform: Platform): FileSystem {
  switch (platform) {
    case "vscode": return new VSCodeFileSystem();
    case "xcode": return new XcodeFileSystem();
  }
}
```

---

## Core Abstractions (9)

### 1. FileSystem

**Purpose**: Unified file I/O across platforms  
**Scope**: Read, write, search, glob patterns, file watching  
**Platform Gap**: vscode.workspace vs FileManager APIs  
**Priority**: P0 (Day 1)  
**Effort**: 1 day

#### Interface

```typescript
export interface FileSystem {
  // Basic operations
  readText(path: string): Promise<string>;
  writeText(path: string, content: string): Promise<void>;
  delete(path: string): Promise<void>;
  exists(path: string): Promise<boolean>;
  
  // Directory operations
  findFiles(pattern: string): Promise<string[]>;
  listDirectory(path: string): Promise<FileEntry[]>;
  createDirectory(path: string): Promise<void>;
  
  // File watching
  watchFile(path: string, callback: (event: FileChangeEvent) => void): Disposable;
  
  // Utility
  getWorkspaceRoot(): Promise<string>;
  normalizePath(path: string): string;
}

export interface FileEntry {
  path: string;
  isDirectory: boolean;
  size?: number;
  modified?: Date;
}

export interface FileChangeEvent {
  path: string;
  type: 'created' | 'changed' | 'deleted';
}
```

#### VS Code Implementation
- Uses `vscode.workspace.openTextDocument` + `TextEditor`
- Uses `vscode.workspace.findFiles` for glob
- Uses `vscode.workspace.createFileSystemWatcher` for watching
- `workspaceFolders[0]` for workspace root

#### Xcode Implementation
- Uses `FileManager.default` for read/write
- Uses `FileManager.contents(atPath:)` for reading
- Uses `String(contentsOfFile:)` for UTF-8
- Uses `try? FileManager.default.contentsOfDirectory(at:)` for listing
- Uses `FSEvents` API for file watching (macOS-native)
- `.git` directory root for workspace

#### Shared Contract
- All paths are absolute or relative to workspace root
- Errors throw/return Result<T> (never silent failures)
- Async/await for all operations
- Paths use forward slashes (normalized internally)

---

### 2. Git

**Purpose**: Unified Git CLI operations  
**Scope**: Checkout, commit, push, log, status, branches, tags  
**Platform Gap**: Same (CLI-based for both)  
**Priority**: P0 (Day 1)  
**Effort**: 1 day

#### Interface

```typescript
export interface Git {
  // Branches
  createBranch(name: string, from?: string): Promise<void>;
  deleteBranch(name: string): Promise<void>;
  checkout(branch: string): Promise<void>;
  getCurrentBranch(): Promise<string>;
  listBranches(): Promise<string[]>;
  
  // Commits
  add(paths: string[]): Promise<void>;
  commit(message: string): Promise<void>;
  getLastCommit(): Promise<CommitInfo>;
  getCommitHistory(limit?: number): Promise<CommitInfo[]>;
  
  // Remote operations
  push(branch: string, remote?: string): Promise<void>;
  pull(branch?: string): Promise<void>;
  getRemote(name?: string): Promise<string>;
  
  // Status
  getStatus(): Promise<GitStatus>;
  isDirty(): Promise<boolean>;
  
  // Tags
  createTag(name: string, message?: string): Promise<void>;
  listTags(): Promise<string[]>;
}

export interface CommitInfo {
  sha: string;
  message: string;
  author: string;
  timestamp: Date;
}

export interface GitStatus {
  branch: string;
  isDirty: boolean;
  staged: string[];
  unstaged: string[];
  untracked: string[];
}
```

#### VS Code Implementation
- Uses `run_in_terminal` with `git` commands
- Parses output with regex patterns
- Caches branch list (invalidate on checkout)

#### Xcode Implementation
- Uses `Process` API with `git` commands
- Same output parsing as VS Code
- Same cache strategy

#### Shared Contract
- All operations require clean working directory (or error)
- All remote operations assume `origin` + `upstream` naming
- Commit messages follow Conventional Commits format
- Workspace must be a valid git repo

---

### 3. Markdown

**Purpose**: Unified markdown artifact generation  
**Scope**: Frontmatter (YAML), heading hierarchy, tables, code blocks  
**Platform Gap**: Same (text-based for both)  
**Priority**: P0 (Day 2)  
**Effort**: 1 day

#### Interface

```typescript
export interface Markdown {
  // Document creation
  createDocument(title: string, frontmatter?: Record<string, any>): MarkdownBuilder;
  
  // Rendering
  render(doc: MarkdownDocument): string;
  
  // Parsing
  parse(content: string): MarkdownDocument;
  
  // Utilities
  formatTable(headers: string[], rows: string[][]): string;
  formatCodeBlock(code: string, language?: string): string;
  formatLink(text: string, href: string): string;
}

export interface MarkdownBuilder {
  addFrontmatter(key: string, value: any): MarkdownBuilder;
  addHeading(level: number, text: string): MarkdownBuilder;
  addParagraph(text: string): MarkdownBuilder;
  addTable(headers: string[], rows: string[][]): MarkdownBuilder;
  addCodeBlock(code: string, language?: string): MarkdownBuilder;
  addList(items: string[], ordered?: boolean): MarkdownBuilder;
  addHorizontalRule(): MarkdownBuilder;
  build(): MarkdownDocument;
}

export interface MarkdownDocument {
  frontmatter: Record<string, any>;
  content: string;
}
```

#### VS Code Implementation
- Uses string manipulation (no special library needed)
- YAML parsing via `yaml` npm package
- Frontmatter format: `---\nkey: value\n---`

#### Xcode Implementation
- Uses string manipulation (same as VS Code)
- YAML parsing via `Yams` SPM package
- Same frontmatter format

#### Shared Contract
- Frontmatter always present (empty if not provided)
- Heading levels 1-6 only
- Tables must have consistent column counts
- Code blocks must specify language (default: `text`)

---

### 4. Diagnostics

**Purpose**: Unified error/warning/info collection and display  
**Scope**: Severity levels, source tracking, message formatting  
**Platform Gap**: vscode.languages.createDiagnosticCollection vs manual display  
**Priority**: P1 (Day 5)  
**Effort**: 1 day

#### Interface

```typescript
export interface Diagnostics {
  // Collection management
  createCollection(name: string): DiagnosticCollection;
  getCollection(name: string): DiagnosticCollection | undefined;
  clearAll(): Promise<void>;
  
  // Display
  show(collection: DiagnosticCollection): Promise<void>;
  
  // Persistence
  save(collection: DiagnosticCollection): Promise<void>;
  load(name: string): Promise<DiagnosticCollection>;
}

export interface DiagnosticCollection {
  name: string;
  add(diagnostic: Diagnostic): void;
  clear(): void;
  getDiagnostics(): Diagnostic[];
}

export interface Diagnostic {
  source: string; // File path
  severity: 'error' | 'warning' | 'info';
  message: string;
  line?: number;
  column?: number;
  code?: string;
}
```

#### VS Code Implementation
- Uses `vscode.languages.createDiagnosticCollection`
- Maps to `vscode.Diagnostic` with `Range`
- Displays in Problems panel (automatic)

#### Xcode Implementation
- Stores diagnostics in-memory collection
- Displays via console output or log file (`.git/.devops/diagnostics.json`)
- No automatic display (Xcode limitation)

#### Shared Contract
- All diagnostics persisted to JSON for audit trail
- Severity levels strictly: error > warning > info
- Line/column numbers are 1-based (for Xcode)
- Source must be relative path to workspace root

---

### 5. Testing

**Purpose**: Unified test discovery, execution, and result parsing  
**Scope**: Test frameworks (Jest/Vitest vs XCTest), result collection, coverage  
**Platform Gap**: vscode.test vs XCTest / SwiftPM test  
**Priority**: P2 (Day 10)  
**Effort**: 2 days

#### Interface

```typescript
export interface Testing {
  // Discovery
  discoverTests(pattern?: string): Promise<TestSuite[]>;
  
  // Execution
  runTests(tests: TestCase[], options?: TestOptions): Promise<TestResult>;
  runTest(test: TestCase): Promise<TestResult>;
  
  // Results
  getLastResult(): TestResult | undefined;
  clearResults(): Promise<void>;
}

export interface TestSuite {
  name: string;
  file: string;
  tests: TestCase[];
  suites?: TestSuite[];
}

export interface TestCase {
  id: string;
  name: string;
  suite: string;
  file: string;
  line: number;
}

export interface TestResult {
  total: number;
  passed: number;
  failed: number;
  skipped: number;
  duration: number;
  tests: TestCaseResult[];
}

export interface TestCaseResult {
  id: string;
  status: 'passed' | 'failed' | 'skipped';
  message?: string;
  duration: number;
}

export interface TestOptions {
  pattern?: string;
  watch?: boolean;
  coverage?: boolean;
}
```

#### VS Code Implementation
- Uses Jest/Vitest via `run_in_terminal` (`npm test`)
- Parses JSON output from `--json` flag
- Watches file changes via `FileSystem.watchFile`

#### Xcode Implementation
- Uses `xcodebuild test` via `Process` API
- Parses xctest output and `.xcresult` bundles
- SwiftPM: `swift test` for Swift Package tests

#### Shared Contract
- Test IDs must be unique and consistent
- Status never transitions (final state)
- Duration in milliseconds
- All operations support cancellation

---

### 6. UI.Interaction

**Purpose**: Unified user input/output for prompts, selections, confirmations  
**Scope**: Text input, selections, info/warning/error messages, progress  
**Platform Gap**: vscode.window vs NSAlert / NSPopUpButton  
**Priority**: P1 (Day 4)  
**Effort**: 2 days

#### Interface

```typescript
export interface UIInteraction {
  // Input
  inputText(prompt: string, options?: InputOptions): Promise<string | undefined>;
  selectOption(prompt: string, options: string[]): Promise<string | undefined>;
  selectMultiple(prompt: string, options: string[]): Promise<string[]>;
  
  // Messages
  showInfo(message: string): Promise<void>;
  showWarning(message: string): Promise<void>;
  showError(message: string): Promise<void>;
  
  // Confirmation
  confirm(message: string): Promise<boolean>;
  
  // File dialogs
  pickFolder(): Promise<string | undefined>;
  pickFile(filters?: FileFilter[]): Promise<string | undefined>;
  pickFiles(): Promise<string[]>;
  
  // Progress
  showProgress(title: string): ProgressHandle;
}

export interface InputOptions {
  value?: string;
  password?: boolean;
  validateInput?: (value: string) => string | undefined;
}

export interface FileFilter {
  name: string;
  extensions: string[];
}

export interface ProgressHandle {
  update(message: string, progress?: number): void;
  done(): void;
  cancel(): boolean;
}
```

#### VS Code Implementation
- `vscode.window.showInputBox` for text
- `vscode.window.showQuickPick` for selection
- `vscode.window.showOpenDialog` / `showSaveDialog` for files
- `vscode.window.withProgress` for progress
- `vscode_askQuestions` for multi-question forms (wrapped)

#### Xcode Implementation
- `NSAlert` + `NSTextField` for text input
- `NSPopUpButton` for single selection
- NSAlert + checkboxes for multi-select
- `NSAlert` for messages (info/warning/error)
- `NSOpenPanel` / `NSSavePanel` for files (native)
- Console or log file for progress (can't show progress UI)

#### Shared Contract
- All dialogs support cancellation
- Text input supports optional validation
- Multi-select returns empty array if cancelled
- File dialogs use workspace root as default
- Progress updates are logged for audit

---

### 7. Build

**Purpose**: Unified build system operations  
**Scope**: Build configuration, compilation, output parsing  
**Platform Gap**: vscode.tasks vs xcodebuild / Swift build  
**Priority**: P2 (Day 8)  
**Effort**: 2 days

#### Interface

```typescript
export interface Build {
  // Configuration
  getBuildConfig(): Promise<BuildConfig>;
  setBuildConfig(config: BuildConfig): Promise<void>;
  
  // Building
  build(target?: string, config?: string): Promise<BuildResult>;
  clean(target?: string): Promise<void>;
  
  // Output
  parseOutput(output: string): BuildDiagnostic[];
  
  // Validation
  validate(): Promise<ValidationResult>;
}

export interface BuildConfig {
  scheme?: string; // Xcode scheme
  project?: string; // Xcode .xcodeproj
  target?: string; // Target name
  buildType?: 'debug' | 'release';
  platform?: 'macos' | 'ios' | 'iphoneos';
}

export interface BuildResult {
  success: boolean;
  duration: number;
  diagnostics: BuildDiagnostic[];
  warnings: number;
  errors: number;
}

export interface BuildDiagnostic {
  file?: string;
  line?: number;
  column?: number;
  severity: 'error' | 'warning' | 'note';
  message: string;
  code?: string;
}

export interface ValidationResult {
  isValid: boolean;
  issues: string[];
  warnings: string[];
}
```

#### VS Code Implementation
- Uses `run_in_terminal` with custom build scripts
- `tasks.json` for build configuration
- Parses output with regex (varies by build tool)

#### Xcode Implementation
- Uses `Process` API with `xcodebuild` or `swift build`
- Parses machine-readable output: `xcodebuild -json`
- Or parses text output with regex patterns

#### Shared Contract
- Build always produces diagnostics (even on success)
- All errors must have file path
- Warnings/notes are optional (file may be nil)
- Duration in milliseconds

---

### 8. CodeAnalysis

**Purpose**: Unified code inspection and AST operations  
**Scope**: Parsing, symbol detection, complexity metrics  
**Platform Gap**: vscode.languages (real-time) vs SwiftSyntax (static)  
**Priority**: P2 (Day 9)  
**Effort**: 2 days

#### Interface

```typescript
export interface CodeAnalysis {
  // Parsing
  parseFile(path: string): Promise<SourceFile | undefined>;
  
  // Symbol lookup
  findSymbol(file: string, name: string): Promise<Symbol | undefined>;
  findReferences(file: string, symbol: string): Promise<Reference[]>;
  
  // Metrics
  getComplexity(file: string): Promise<ComplexityMetric>;
  
  // Analysis
  analyzeFile(file: string): Promise<FileAnalysis>;
}

export interface SourceFile {
  path: string;
  language: 'swift' | 'typescript' | 'javascript';
  symbols: Symbol[];
  diagnostics: CodeDiagnostic[];
}

export interface Symbol {
  name: string;
  kind: 'function' | 'class' | 'struct' | 'enum' | 'variable' | 'property';
  line: number;
  column: number;
  scope?: string; // Parent class/struct
}

export interface Reference {
  file: string;
  line: number;
  column: number;
  context: string; // Code snippet
}

export interface ComplexityMetric {
  cyclomaticComplexity: number;
  cognitiveComplexity: number;
  lineCount: number;
  functionCount: number;
}

export interface CodeDiagnostic {
  line: number;
  column: number;
  message: string;
  severity: 'error' | 'warning' | 'info';
}

export interface FileAnalysis {
  file: string;
  symbols: Symbol[];
  complexity: ComplexityMetric;
  issues: CodeDiagnostic[];
}
```

#### VS Code Implementation
- Uses TypeScript Compiler API (tsserver) for .ts/.js
- Real-time diagnostics via language server
- Symbol search via `vscode.commands.executeCommand('editor.action.goToDeclaration')`

#### Xcode Implementation
- Uses `SwiftSyntax` SPM package for parsing
- Builds AST manually (no real-time server)
- Static analysis only (no runtime info)

#### Shared Contract
- All file paths absolute or relative to workspace
- Symbols sorted by line number (ascending)
- Complexity metrics always present (may be 0)
- Only supported languages: Swift, TypeScript/JavaScript

---

### 9. Security

**Purpose**: Unified security analysis frameworks  
**Scope**: STRIDE threat modeling, OWASP checklist, dependency scanning  
**Platform Gap**: Same (both use CLI tools)  
**Priority**: P2 (Day 11)  
**Effort**: 2 days

#### Interface

```typescript
export interface Security {
  // Threat modeling
  strideAnalysis(component: string): Promise<ThreatModel>;
  
  // Checklist
  owaspChecklist(): Promise<ChecklistItem[]>;
  checkItem(id: string): Promise<void>;
  
  // Dependencies
  scanDependencies(): Promise<Vulnerability[]>;
  
  // Report
  generateReport(): Promise<SecurityReport>;
}

export interface ThreatModel {
  component: string;
  threats: Threat[];
  mitigations: string[];
}

export interface Threat {
  id: string;
  category: 'spoofing' | 'tampering' | 'repudiation' | 'informationDisclosure' | 'denialOfService' | 'elevationOfPrivilege';
  description: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  mitigation?: string;
}

export interface ChecklistItem {
  id: string;
  title: string;
  category: string;
  checked: boolean;
  notes?: string;
}

export interface Vulnerability {
  id: string;
  package: string;
  version: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  remediation?: string;
}

export interface SecurityReport {
  timestamp: Date;
  threats: ThreatModel[];
  checklist: ChecklistItem[];
  vulnerabilities: Vulnerability[];
  summary: SecuritySummary;
}

export interface SecuritySummary {
  threatCount: number;
  checkedItems: number;
  vulnerabilities: number;
  mitigationStatus: string;
}
```

#### VS Code Implementation
- Uses `npm audit` for dependency scanning
- Threat modeling via guided prompts (manual)
- Checklist stored in `.devops/security.json`

#### Xcode Implementation
- Uses `swift package update --dry-run` for SPM deps
- `swift package describe --json` for package info
- Same threat modeling approach

#### Shared Contract
- All analyses append to security report (never replace)
- Threat severity: critical > high > medium > low
- Vulnerabilities include remediation guidance
- Report always has timestamp for audit trail

---

## MCP Layer Abstractions (6)

### 10. MCP.Client

**Purpose**: Unified MCP protocol client with connection pooling and auth  
**Scope**: Server discovery, connection, tool invocation, error handling  
**Platform Gap**: Same (protocol is platform-agnostic)  
**Priority**: P0 (Day 3)  
**Effort**: 2 days

#### Interface

```typescript
export interface MCPClient {
  // Lifecycle
  connect(server: ServerConfig): Promise<void>;
  disconnect(): Promise<void>;
  isConnected(): boolean;
  
  // Tool invocation
  listTools(): Promise<Tool[]>;
  invokeTool(name: string, args: Record<string, any>): Promise<ToolResult>;
  
  // Resources
  listResources(): Promise<Resource[]>;
  readResource(uri: string): Promise<string>;
  
  // Error handling
  getLastError(): MCPError | undefined;
}

export interface ServerConfig {
  name: string;
  command: string;
  args?: string[];
  env?: Record<string, string>;
  auth?: AuthConfig;
}

export interface Tool {
  name: string;
  description: string;
  inputSchema: Record<string, any>; // JSON Schema
}

export interface ToolResult {
  success: boolean;
  data?: any;
  error?: string;
}

export interface Resource {
  uri: string;
  name: string;
  mimeType?: string;
}

export interface MCPError {
  code: string;
  message: string;
  details?: Record<string, any>;
}

export interface AuthConfig {
  type: 'token' | 'oauth' | 'apikey';
  provider: string;
  scope?: string[];
}
```

#### VS Code Implementation
- Uses `run_in_terminal` to spawn MCP server process
- JSON-RPC over stdio with automatic retry
- Connection pooling for multiple servers
- Uses vscode secret storage for credentials

#### Xcode Implementation
- Uses `Process` API to spawn MCP server
- Same JSON-RPC protocol
- File-based credential storage (`~/.devops/credentials.json`)
- Connection pooling identical to VS Code

#### Shared Contract
- All tool invocations use timeout (30s default)
- JSON-RPC version 2.0 required
- Authentication providers: token, oauth, apikey
- Error codes are standardized (MCP spec)

---

### 11. MCP.Auth

**Purpose**: Unified authentication across all MCP servers  
**Scope**: Token management, provider routing, credential storage, refresh  
**Platform Gap**: Same (credential storage differs)  
**Priority**: P1 (Day 6)  
**Effort**: 1 day

#### Interface

```typescript
export interface MCPAuth {
  // Credential management
  storeCredential(provider: string, credential: Credential): Promise<void>;
  getCredential(provider: string): Promise<Credential | undefined>;
  deleteCredential(provider: string): Promise<void>;
  
  // Token operations
  getToken(provider: string): Promise<string>;
  refreshToken(provider: string): Promise<string>;
  isTokenValid(provider: string): Promise<boolean>;
  
  // Providers
  listProviders(): Provider[];
  
  // OAuth
  initiateOAuth(provider: string, scopes: string[]): Promise<string>; // Returns token
}

export interface Credential {
  type: 'token' | 'oauth' | 'apikey';
  value: string;
  provider: string;
  expiresAt?: Date;
  metadata?: Record<string, any>;
}

export interface Provider {
  name: string;
  type: 'github' | 'azure' | 'openai' | 'other';
  scopes: string[];
  refreshable: boolean;
}
```

#### VS Code Implementation
- Uses `vscode.SecretStorage` (secure storage, encrypted by OS)
- Token refresh via provider-specific APIs
- OAuth flow via `vscode.env.openExternal`

#### Xcode Implementation
- Uses Keychain (macOS native security)
- `Security` framework for Keychain access
- Token refresh same as VS Code
- Fallback: file-based storage with warnings

#### Shared Contract
- All tokens have optional expiration
- Refresh token before expiration (5 min buffer)
- Multiple credentials per provider allowed
- Metadata allows custom provider-specific data

---

### 12. MCP.Server

**Purpose**: Unified MCP server discovery and registration  
**Scope**: Server manifest parsing, auto-discovery, lifecycle management  
**Platform Gap**: Same (manifest-based for both)  
**Priority**: P1 (Day 7)  
**Effort**: 1 day

#### Interface

```typescript
export interface MCPServer {
  // Discovery
  discoverServers(): Promise<ServerManifest[]>;
  findServer(name: string): Promise<ServerManifest | undefined>;
  
  // Registration
  registerServer(manifest: ServerManifest): Promise<void>;
  unregisterServer(name: string): Promise<void>;
  
  // Validation
  validateManifest(path: string): Promise<ValidationResult>;
  
  // Lifecycle
  getServerStatus(name: string): Promise<ServerStatus>;
}

export interface ServerManifest {
  name: string;
  command: string;
  args?: string[];
  env?: Record<string, string>;
  auth?: AuthConfig;
  tools?: ToolDefinition[];
  resources?: ResourceDefinition[];
  description?: string;
}

export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: Record<string, any>;
}

export interface ResourceDefinition {
  pattern: string;
  description: string;
  mimeType?: string;
}

export interface ServerStatus {
  name: string;
  connected: boolean;
  connectedAt?: Date;
  disconnectedAt?: Date;
  errorCount: number;
  lastError?: MCPError;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}
```

#### VS Code Implementation
- Discovers servers from `copilot-instructions.md` (YAML frontmatter)
- Also scans `.github/agents/` for agent manifests
- Stores server registry in `vscode.workspaceState`

#### Xcode Implementation
- Discovers from `copilot-instructions.md` (same format)
- Also scans `.github/agents/` for consistency
- Stores registry in `.git/.devops/mcp-servers.json`

#### Shared Contract
- Manifest format: YAML (same for both)
- Server names must be unique per workspace
- Discovery is idempotent (safe to call multiple times)
- Auto-discovery on workspace open

---

### 13. MCP.Tool

**Purpose**: Unified MCP tool validation and caching  
**Scope**: Tool schema validation, input checking, result caching  
**Platform Gap**: Same (logic-based)  
**Priority**: P2 (Day 12)  
**Effort**: 1 day

#### Interface

```typescript
export interface MCPTool {
  // Validation
  validateSchema(tool: Tool, input: Record<string, any>): ValidationResult;
  validateInput(tool: Tool, input: Record<string, any>): ValidationResult;
  
  // Caching
  getCached(tool: string, input: Record<string, any>): Promise<ToolResult | undefined>;
  cache(tool: string, input: Record<string, any>, result: ToolResult): Promise<void>;
  clearCache(): Promise<void>;
  
  // Execution
  execute(client: MCPClient, tool: string, input: Record<string, any>): Promise<ToolResult>;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}
```

#### VS Code Implementation
- Uses JSON Schema validator (npm package)
- Caching in-memory + optional persistent cache
- Result deduplication (same input → cached result)

#### Xcode Implementation
- Uses same JSON Schema validation
- File-based cache (`.git/.devops/tool-cache.json`)
- TTL-based expiration (1 hour default)

#### Shared Contract
- Cache keys: SHA256(tool_name + JSON(input))
- Cache TTL: configurable, default 3600s
- Validation errors are typed (missing field, wrong type, etc)
- Caching is optional (skip if side effects)

---

### 14. MCP.Cache

**Purpose**: Unified result caching with TTL and invalidation  
**Scope**: Cache keys, expiration, eviction, persistence  
**Platform Gap**: Same (time-based logic)  
**Priority**: P2 (Day 13)  
**Effort**: 1 day

#### Interface

```typescript
export interface MCPCache {
  // Operations
  get(key: string): Promise<any | undefined>;
  set(key: string, value: any, ttl?: number): Promise<void>;
  delete(key: string): Promise<void>;
  clear(): Promise<void>;
  
  // Queries
  has(key: string): Promise<boolean>;
  keys(): Promise<string[]>;
  
  // Invalidation
  invalidatePattern(pattern: string): Promise<number>;
  invalidateTag(tag: string): Promise<number>;
  
  // Statistics
  getStats(): CacheStats;
}

export interface CacheStats {
  hits: number;
  misses: number;
  evictions: number;
  size: number;
}
```

#### VS Code Implementation
- In-memory cache with LRU eviction
- Optional persistent layer (workspace state)
- TTL checked on access

#### Xcode Implementation
- File-based cache (`.git/.devops/cache.json`)
- LRU eviction by access time
- TTL checked on read

#### Shared Contract
- Keys are strings (no spaces)
- TTL in seconds (0 = no expiration)
- Values can be any JSON-serializable type
- Cache hits/misses tracked for metrics

---

### 15. MCP.RateLimit

**Purpose**: Unified rate limiting across MCP servers  
**Scope**: Quota tracking, backoff calculation, provider-specific limits  
**Platform Gap**: Same (logic-based)  
**Priority**: P2 (Day 14)  
**Effort**: 1 day

#### Interface

```typescript
export interface MCPRateLimit {
  // Tracking
  recordCall(provider: string, endpoint?: string): Promise<void>;
  getRemainingQuota(provider: string): Promise<number>;
  
  // Backoff
  waitIfNeeded(provider: string): Promise<number>; // Returns wait time in ms
  getBackoffTime(provider: string): Promise<number>;
  
  // Limits
  setLimit(provider: string, limit: RateLimit): Promise<void>;
  getLimit(provider: string): Promise<RateLimit>;
  
  // Reset
  reset(provider: string): Promise<void>;
}

export interface RateLimit {
  requestsPerMinute?: number;
  requestsPerHour?: number;
  requestsPerDay?: number;
  burstSize?: number; // Tokens for burst
}
```

#### VS Code Implementation
- Token bucket algorithm
- State in `vscode.globalState` (survives session)
- Exponential backoff: 1s, 2s, 4s, 8s, max 60s

#### Xcode Implementation
- Token bucket algorithm (identical)
- State in `.git/.devops/rate-limit.json`
- Same backoff strategy

#### Shared Contract
- All times in milliseconds
- Limits per provider (not endpoint)
- Burst tokens for temporary spike handling
- Backoff is exponential with jitter

---

## Cross-Cutting Abstractions (1)

### 16. Xcode.Integration

**Purpose**: Xcode-specific platform integration layer  
**Scope**: Copilot API, editor integration, workspace access  
**Platform Gap**: VS Code extension API vs Xcode Copilot sidecar  
**Priority**: P1 (Day 15)  
**Effort**: 1 day

#### Interface

```typescript
export interface XcodeIntegration {
  // Copilot API
  invokeAgent(agentName: string): Promise<AgentResult>;
  sendMessage(message: string): Promise<string>;
  
  // Editor integration
  getCurrentFile(): Promise<string | undefined>;
  getSelection(): Promise<string | undefined>;
  insertText(text: string, position?: Position): Promise<void>;
  
  // Workspace
  openFile(path: string): Promise<void>;
  getWorkspacePath(): Promise<string>;
  
  // UI
  showMessage(message: string, type?: 'info' | 'warning' | 'error'): Promise<void>;
}

export interface AgentResult {
  success: boolean;
  message: string;
  artifacts?: Artifact[];
}

export interface Artifact {
  type: 'file' | 'url' | 'code';
  content: string;
  path?: string;
}

export interface Position {
  line: number;
  column: number;
}
```

#### Xcode Implementation
- Wraps Xcode Copilot APIs (Agent protocol)
- Uses `NSTextView` for editor integration
- Accesses workspace via `.git` root

#### VS Code Implementation
- Wraps vscode Copilot APIs
- Uses `TextEditor` API
- Uses `vscode.workspace` for workspace

#### Shared Contract
- Agent names match registered agents
- Messages support markdown formatting
- Artifact paths relative to workspace
- All operations have optional callbacks

---

## Shared Interface Guidelines

### Error Handling

All abstractions use consistent error pattern:

```typescript
export class AbstractionError extends Error {
  constructor(
    public code: string,
    public message: string,
    public cause?: Error,
    public context?: Record<string, any>
  ) {
    super(message);
  }
}

// Usage
throw new AbstractionError(
  'FILE_NOT_FOUND',
  `File not found: ${path}`,
  originalError,
  { path, workspace: this.workspace }
);
```

### Logging

All abstractions log to structured logger:

```typescript
export interface Logger {
  debug(message: string, context?: Record<string, any>): void;
  info(message: string, context?: Record<string, any>): void;
  warn(message: string, context?: Record<string, any>): void;
  error(message: string, error?: Error, context?: Record<string, any>): void;
}

// Usage in abstraction
this.logger.info('File written', { path, size: content.length });
```

### Async/Await

All I/O operations support async:

```typescript
export interface FileSystem {
  readText(path: string): Promise<string>;
  // Not: readTextSync(path: string): string
}

// Usage
const content = await fileSystem.readText('/path/to/file.md');
```

### Dependency Injection

All abstractions accept dependencies in constructor:

```typescript
export class SharedFileSystem implements FileSystem {
  constructor(
    private platform: Platform,
    private logger: Logger
  ) {}
}

// Usage
const fs = new SharedFileSystem('xcode', logger);
```

---

## Implementation Strategy

### Phase 1: Foundation (Days 1-6)

**Day 1**: FileSystem + Git (2 abstractions)
- TypeScript interfaces
- VS Code implementation
- Xcode implementation
- Unit tests

**Day 2**: Markdown (1 abstraction)
- Frontmatter parsing
- Table/code formatting
- Shared builder pattern

**Day 3**: MCP.Client (1 abstraction)
- Server spawning (Process API)
- JSON-RPC protocol
- Connection pooling

**Day 4**: UI.Interaction (1 abstraction)
- Input dialogs
- Confirmations
- Progress handling

**Day 5**: Diagnostics (1 abstraction)
- Collection management
- JSON persistence
- Display strategy

**Day 6**: MCP.Auth (1 abstraction)
- Credential storage
- Token refresh
- OAuth flow

### Phase 2: Advanced (Days 7-15)

**Day 7**: MCP.Server (1 abstraction)
- Manifest parsing
- Server discovery
- Registry management

**Day 8**: Build (1 abstraction)
- xcodebuild integration
- Output parsing
- Diagnostics extraction

**Day 9**: CodeAnalysis (1 abstraction)
- SwiftSyntax parsing
- Symbol lookup
- Complexity metrics

**Day 10**: Testing (1 abstraction)
- Test discovery
- Execution pipeline
- Result aggregation

**Day 11**: Security (1 abstraction)
- STRIDE analysis
- OWASP checklist
- Dependency scanning

**Day 12-15**: MCP.Tool, MCP.Cache, MCP.RateLimit, Xcode.Integration (4 abstractions)
- Tool validation + caching
- Cache with TTL
- Rate limiting with backoff
- Xcode platform layer

### Testing Strategy

Each abstraction has:
- Unit tests for both implementations
- Integration tests with real tools
- Performance benchmarks
- Error case coverage

---

## P0-8 Conclusions

### Key Deliverables

1. **16 Shared Abstractions Defined**
   - 9 core abstractions (FileSystem, Git, Markdown, Diagnostics, Testing, UI.Interaction, Build, CodeAnalysis, Security)
   - 6 MCP layer abstractions (MCP.Client, MCP.Auth, MCP.Server, MCP.Tool, MCP.Cache, MCP.RateLimit)
   - 1 cross-cutting abstraction (Xcode.Integration)

2. **Shared Interface Pattern Established**
   - Dependency injection
   - Async/await support
   - Consistent error handling
   - Structured logging

3. **Implementation Roadmap**
   - 15-day critical path for MVP
   - Effort estimates provided
   - Priority ranking clear (P0/P1/P2)

4. **Platform Coverage**
   - VS Code implementation strategy for each
   - Xcode implementation strategy for each
   - Shared contracts ensure consistency

### Design Rationale

- **Minimal Interfaces**: Each abstraction has single responsibility
- **Separation of Concerns**: Platform-specific code isolated
- **Dependency Injection**: Enables testing and composition
- **Error Consistency**: All errors use AbstractionError
- **Async First**: No blocking operations
- **Logging Built-In**: Every operation traceable

### Acceptance Criteria Met

✅ All 16 abstractions documented  
✅ Interface definitions provided  
✅ VS Code implementation strategy  
✅ Xcode implementation strategy  
✅ Shared contracts defined  
✅ Error handling pattern established  
✅ Implementation roadmap (15 days)  
✅ No TBDs  

### Next Phase

- **P0-9**: Xcode-specific abstractions refinement
- **P0-10-12**: Test planning, implementation, infrastructure
- **P0-13**: Final report + Gate 1 go/no-go
- **Phase 1**: Begin implementing abstractions (parallel with P0-9+)

---

**P0-8 Status**: ✅ COMPLETE  
**Deliverable**: `docs/features/devsquad-xcode-compatibility/research/shared-abstractions.md` (1,000+ lines)  
**Time**: ~4 hours  
**Quality**: Comprehensive abstraction definitions with interface signatures and implementation strategies
