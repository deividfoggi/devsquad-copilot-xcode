---
name: deep-clarification
description: "Ask hard clarifying questions, stress-test assumptions, and challenge a plan or design until ambiguity is resolved. Exhaustively walks each branch of a decision tree. Use when deep clarification is needed during spec creation, planning, triage, or any phase with significant uncertainty. Also use when the user says 'challenge this', 'stress-test this', 'probe this plan', or 'deep dive on requirements'. Do not use for simple yes/no confirmations, for architecture decisions (use ADRs after clarification), or when the user explicitly asks for brevity."
---

# Deep Clarification

## Principle

Premature convergence is the root cause of underspecified features. When uncertainty is high, exhaustive exploration of the decision space produces better artifacts than bounded clarification rounds.

## When to Use

| Caller | Trigger |
|--------|---------|
| `devsquad.specify` | Spec touches multiple bounded contexts, has high complexity rating, or user requests deep exploration |
| `devsquad.plan` | High-impact design decisions with 2+ viable options and no clear winner |
| `devsquad.envision` | Business context has competing objectives or unclear pain points |
| `debugging-recovery` | Bug report is incomplete or ambiguous; need to build a complete reproduction |
| Any agent | User explicitly says "challenge this", "stress-test this", or "deep dive on requirements" |

## Interview Protocol

### 1. Identify the decision tree

Before asking the first question, map the branches:
- What are the top-level decisions that need to be made?
- Which decisions depend on others? (resolve dependencies first)
- Which decisions can be answered by exploring the codebase instead of asking the user?

### 2. Walk each branch

For each decision point:

1. **State the question clearly**: one question at a time
2. **Provide a recommended answer**: based on codebase exploration, existing ADRs, or domain knowledge
3. **Wait for the user's response** before proceeding to the next question
4. **Challenge vague answers**: if the response is ambiguous, probe deeper ("What do you mean by 'flexible'? Can you give a concrete example?")
5. **Cross-reference with code**: if the user states how something works, verify against the codebase. If there is a contradiction, surface it immediately.

### 3. Codebase-first resolution

Before asking the user a question, check if the answer is already in the codebase:

```
Can the codebase answer this question?
  YES → State the finding: "I found that [X]. Is this still current?"
  NO  → Ask the user
```

This reduces unnecessary questions and grounds the conversation in reality.

### 4. Convergence criteria

The clarification session ends when ANY of the following are true:

- Every branch of the decision tree has been explored and the user confirms shared understanding
- The user explicitly asks to stop or move on ("that covers it", "let's move on")
- Three consecutive questions yield no new information (diminishing returns)
- The session exceeds 15 questions without convergence (suggest parking unresolved items and continuing later)

### 5. Document decisions inline

As decisions are made during the session, capture them immediately:

- If a term is resolved: update the glossary (via `domain-glossary` skill if available)
- If an architectural decision emerges: note it for later ADR creation (do not create during the session)
- If a requirement is clarified: note it for spec update

Present a summary at the end using the `reasoning` skill format:

```text
## Clarification Summary

### Decisions Made
| # | Decision | Justification | Confidence |
|---|----------|---------------|------------|
| 1 | [what was decided] | [why] | [High/Medium/Low] |

### Assumptions
- [assumption made during the session]

### Open Items
- [anything that could not be resolved and needs follow-up]

### Suggested Next Steps
- [ADR needed for X]
- [Spec update needed for Y]
```

## Challenging Techniques

Use these patterns to probe deeper:

| Technique | When to use | Example |
|-----------|-------------|---------|
| **Concrete scenario** | Vague requirement | "Give me a specific example of when this would happen" |
| **Edge case probe** | Happy path only discussed | "What happens if [unusual input]? What about [concurrent access]?" |
| **Contradiction surfacing** | User states conflict with code/docs | "Your code does X, but you just said Y. Which is correct?" |
| **Terminology sharpening** | Overloaded or vague terms | "You said 'account'. Do you mean the billing entity or the login identity?" |
| **Scale probe** | No volume context | "How many of these do you expect? 10? 10,000? 10 million?" |
| **Failure mode** | Only success path discussed | "What should happen when this fails? Is partial failure acceptable?" |
| **Boundary probe** | Scope unclear | "Is [X] in scope or out of scope for this feature?" |

## Auto-Clarity Exception

Temporarily pause the clarification session for:
- Security warnings that need immediate attention
- Irreversible action confirmations
- When the user explicitly asks to stop or move on

Resume after the exception is handled.

## Anti-patterns

- Do not probe trivial decisions (formatting, naming conventions already established)
- Do not ask questions that can be answered by reading the codebase
- Do not batch questions: one at a time, wait for response
- Do not skip the summary: decisions made during the session must be captured
- Do not create ADRs or update specs during the session: capture notes and create afterward
- Do not continue probing after the user signals convergence ("that covers it", "let's move on")
