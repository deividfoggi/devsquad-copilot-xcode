---
name: domain-glossary
description: "Extract and maintain a domain glossary with canonical terms, ambiguity flags, and relationship mappings. Use when defining domain terms, building a glossary, hardening terminology, or when synonym drift is detected across specs, ADRs, or work items. Also use during spec creation to validate terminology consistency. Do not use for architecture decisions (use ADRs), for code-level naming conventions (use coding-guidelines), or for one-time term definitions that do not recur across artifacts."
---

# Domain Glossary

## Principle

Enterprise systems accumulate terminology debt: the same concept called different names across teams, specs, and code. Synonym drift corrupts search, work-item labeling, and cross-spec consistency. A shared canonical glossary reduces misunderstanding and improves spec-to-code traceability.

## Operations

This skill has two modes: **extract** (build or update a glossary) and **validate** (check an artifact against the glossary).

---

## 1. Extract: Build or Update the Glossary

### When to Extract

| Trigger | Action |
|---------|--------|
| New feature spec created (`devsquad.specify`) | Extract terms from the spec |
| Envisioning completed (`devsquad.envision`) | Extract terms from the envisioning document |
| Domain discussion in conversation | Extract terms as they emerge |
| Explicit user request ("build a glossary", "define domain terms") | Full extraction from available artifacts |
| Review finding: inconsistent terminology | Update glossary with canonical choice |

### Extract Procedure

1. **Check for existing glossary**: Read `docs/domain/GLOSSARY.md` (or create from template if it does not exist)
2. **Scan sources** for domain-relevant nouns, verbs, and concepts:
   - Conversation context
   - Spec files (`docs/features/**/spec.md`)
   - Envisioning documents (`docs/envisioning/*.md`)
   - ADRs (`docs/architecture/decisions/*.md`)
   - Code (class names, module names, API endpoints) via codebase search
3. **Identify problems**:
   - Same word used for different concepts (ambiguity)
   - Different words used for the same concept (synonyms)
   - Vague or overloaded terms
   - Terms in code that differ from terms in specs
4. **Propose canonical terms**: be opinionated; pick the best term and list others as aliases to avoid
5. **Write or update** `docs/domain/GLOSSARY.md` using the format below
6. **Present summary** inline in the conversation

### Glossary Format

```markdown
# Domain Glossary

## [Domain Group]

| Term | Definition | Status | Aliases to avoid |
|------|-----------|--------|-----------------|
| **[Term]** | [One sentence: what it IS, not what it does] | [Established/Proposed/Contested] | [Synonyms to avoid] |

## Relationships

- A **[Term A]** belongs to exactly one **[Term B]**
- A **[Term C]** produces one or more **[Term D]**

## Flagged Ambiguities

- "[word]" was used to mean both **[Term X]** and **[Term Y]**. These are distinct concepts: [explanation of the difference and recommended usage].
```

### Rules for Extraction

- Be opinionated: when multiple words exist for the same concept, pick the best one and list the others as aliases to avoid
- Flag conflicts explicitly with a clear recommendation
- Only include terms relevant for domain experts; skip generic programming concepts (array, function, endpoint) unless they have domain-specific meaning
- Keep definitions tight: one sentence maximum; define what it IS, not what it does
- Show relationships with bold term names and express cardinality where obvious
- Group terms into multiple tables when natural clusters emerge (by subdomain, lifecycle, or actor)
- Create files lazily: only create `GLOSSARY.md` when the first terms are resolved; do not bloat new projects

### Confidence Levels

| Level | Criterion |
|-------|-----------|
| **Established** | Term appears consistently in accepted specs and ADRs |
| **Proposed** | Term chosen during extraction but not yet validated by the team |
| **Contested** | Multiple stakeholders use different terms for the same concept |

Mark contested terms in the Flagged Ambiguities section until resolved.

---

## 2. Validate: Check Artifact Against Glossary

### When to Validate

| Agent | Artifact | Check |
|-------|----------|-------|
| `devsquad.specify` | spec.md | Terms used in the spec exist in the glossary; no synonym drift |
| `devsquad.review.spec` | spec.md | Flag terms that contradict or diverge from the glossary |
| `devsquad.review.code` | Source code | Flag domain-language violations (code uses synonyms instead of canonical terms) |
| `quality-gate` | Any artifact | Terminology consistency as a quality dimension |

### Validate Procedure

1. Read `docs/domain/GLOSSARY.md`
   - If file does not exist, skip validation (no glossary yet)
2. Scan the artifact for domain terms
3. For each term found:
   - If it matches a canonical term: OK
   - If it matches an "alias to avoid": flag as terminology drift
   - If it is a domain-relevant term not in the glossary: suggest adding it
4. Report findings:

```text
Terminology check: [artifact]

Drift detected:
- "[alias]" used in [location] — canonical term is **[Term]**

New terms (not in glossary):
- "[new term]" — suggest adding with definition: [proposed definition]

No issues: [count] terms checked, all consistent
```

---

## 3. Code Cross-Reference

When validating code (called from `devsquad.review.code`):

1. Search for class names, module names, and API endpoints that represent domain concepts
2. Compare against the glossary:
   - Class `UserAccount` when glossary says **Customer**: flag as translation smell
   - API endpoint `/api/clients` when glossary says **Customer**: flag as inconsistency
3. Do not flag internal implementation names (private variables, utility functions) unless they represent domain concepts exposed in public interfaces
4. Exempt intentional translation boundaries: anti-corruption layers, legacy database schemas, vendor API contracts, and external system adapters may use different terms by design. If a mismatch is at a known boundary, note it but do not flag as drift.

---

## Anti-patterns

- Do not create a glossary for projects with a single bounded context and fewer than 5 domain terms (overhead exceeds value)
- Do not block delivery for terminology drift (flag it, do not enforce)
- Do not capture generic technical terms ("database", "API", "service") unless they have project-specific meaning
- Do not override terms that the team has explicitly chosen, even if another term seems "better"
- Do not duplicate definitions that already exist in accepted ADRs
