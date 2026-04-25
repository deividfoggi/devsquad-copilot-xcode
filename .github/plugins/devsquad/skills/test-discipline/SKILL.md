---
name: test-discipline
description: "Testing practices for behavior-focused, refactor-resistant tests. Use when implementing features or fixing bugs to ensure tests verify intent through public interfaces. Also use when adding regression tests after bug fixes. Consulted by the implement agent during coding and by the review agent when validating test quality. Do not use for test strategy decisions (use complexity-analysis), for failure triage and root-cause analysis (use debugging-recovery; after root cause is localized, use test-discipline to add the reproducing regression test and fix), or for integration test infrastructure setup."
---

# Test Discipline

## Philosophy

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests should not break unless behavior changes. A good test reads like a specification.

Use TDD **strategically, not dogmatically**. The goal is high-quality tests that verify intent — the ordering of when tests are written is a means to that end, not the end itself.

## When to Write Tests First

Test-first (red-green-refactor) works best when:

- **Fixing a bug**: Write a test that reproduces the bug before fixing it. The test **must** fail BEFORE the fix and pass AFTER. If the bug is not reproducible via automated test (race condition, environment-specific), document why and what alternative evidence proves the fix.
- **Behavior is unclear**: The test forces you to define expected behavior precisely before writing code.
- **Working on a well-defined interface**: The contract is clear and the test is straightforward to write.

## When to Write Tests After (or Interleave)

Design-first-then-test works best when:

- **Exploring a new domain**: The design is not yet clear. Sketch interfaces and responsibilities first, write code in meaningful blocks, then add tests.
- **Prototyping**: Rapid iteration where the interface is still evolving. Tests written too early against an unstable interface create waste.
- **Well-understood patterns**: When applying a known pattern (CRUD, adapter, pipeline), write the implementation, then test the behavior.

In both approaches, the quality criteria for the resulting tests are identical.

## Vertical Slices

Regardless of test-first or design-first, deliver work in **vertical slices** — thin end-to-end paths through all layers.

**Anti-pattern: horizontal slicing**

Writing all tests first (or all of one layer first), then all implementation. This produces tests that verify *imagined* behavior and delays integration feedback.

```text
AVOID (horizontal):
  All tests → All implementation
  All models → All services → All endpoints

PREFER (vertical):
  Slice 1: User can create an order (all layers, happy path)
  Slice 2: Order validates required fields (error handling)
  Slice 3: Order calculates totals (business logic)
```

The first slice should be a **tracer bullet**: a thin end-to-end path that proves the architecture works.

## Per-Task Procedure

1. **Choose the next vertical slice** (tracer bullet first)
2. **Design**: Sketch the interface and responsibilities for this slice
3. **Implement + Test**: Either test-first (RED → GREEN) or implement-then-test, based on the context guidance above
4. **Verify**: Run the full test suite — new test passes, no regressions
5. **Refactor**: Clean up while all tests are green. Never refactor with failing tests.
6. **Repeat**: Next slice

## Test Quality Criteria

Every test must satisfy these criteria regardless of when it was written:

| Criterion | Check |
|-----------|-------|
| **Behavior-focused** | Tests what the system does, not how it does it |
| **Public interface only** | Uses the same API that callers use |
| **Refactor-resistant** | Would survive internal restructuring without changes |
| **Independent** | Does not depend on other tests or test execution order |
| **Deterministic** | Same result every run, no timing dependencies |
| **Readable** | Test name describes the behavior being verified |

For unit test rules, integration test rules, and test doubles hierarchy, follow `coding-guidelines.md` (always in context). This skill focuses on what coding-guidelines does not cover: the decision framework, per-task procedure, quality criteria, and anti-patterns.

## What Makes a Good Test

**Good tests** exercise real code paths through public APIs. They describe *what* the system does, not *how*. They read like a specification: "user can checkout with valid cart" tells you exactly what capability exists.

**Bad tests** are coupled to implementation:
- Mock internal collaborators
- Test private methods or internal state
- Bypass the public interface of the component under test with side-channel assertions (unless persistence itself is the behavior being verified)
- Break when you refactor, even though behavior has not changed

**Warning sign**: a test breaks when you refactor, but behavior has not changed. That test was testing implementation, not behavior.

## Integration with SDD Lifecycle

| Agent | How test discipline is used |
|-------|----------------------------|
| `devsquad.implement.execute` | Follows per-task procedure for each task |
| `devsquad.review.tests` | Uses test quality criteria as review rubric |
| `quality-gate` (code rubric) | Verifies test coverage and behavior focus |
| `debugging-recovery` | Adds regression test (test that reproduces bug, then fix) |

## Anti-patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| All tests first, then all code | Tests verify imagined behavior | Work in vertical slices |
| Mocking what you own | Tests break on refactor | Test through public interface with real implementations |
| Testing private methods | Coupled to implementation | Test the behavior those methods enable |
| 100% coverage as a goal | Coverage without behavior focus is noise | Cover critical paths and edge cases |
| Copy-paste test setup | Fragile, hard to maintain | Extract test helpers and fixtures |
| Testing the framework | Verifying framework behavior, not yours | Trust the framework, test your logic |
| Tests without assertions | False confidence — tests pass but verify nothing | Every test must assert observable behavior |
| Dogmatic test-first in unfamiliar domains | Premature tests lock in unstable interfaces | Design first, then test when the interface stabilizes |

## Checklist Per Slice

```text
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Test doubles follow coding-guidelines hierarchy
[ ] No speculative features added
[ ] Refactoring done only while all tests pass
[ ] Suite runs green before moving to next slice
```
