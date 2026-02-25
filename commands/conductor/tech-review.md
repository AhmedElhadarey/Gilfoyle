---
name: tech-review
description: "CTO-level technical architecture review (renamed from cto-advisor)"
arguments:
  - name: track_id
    description: "Optional track ID to review (defaults to active track)"
    required: false
user_invocable: true
---

# /conductor:tech-review — CTO Technical Architecture Review

Run a CTO-level technical review of the current execution plan. Evaluates architecture decisions, tech debt implications, technology choices, and engineering excellence.

> This command replaces the deprecated `/cto-advisor` command with the same functionality under the conductor namespace. It is distinct from `/cto`, which is a general advisory consultation.

## When to Use

Run this command to get technical leadership guidance on:
- **Architecture decisions** — evaluating system design patterns, component boundaries
- **Technology selection** — choosing libraries, frameworks, services
- **Technical debt** — assessing debt introduction and mitigation strategies
- **Engineering metrics** — validating against DORA metrics and quality standards
- **Integration planning** — reviewing API design, vendor dependencies
- **Infrastructure changes** — evaluating scalability, performance, monitoring
- **Security review** — checking authentication, authorization, OWASP compliance

## Usage

```bash
/conductor:tech-review
/conductor:tech-review my-track-id
```

## What It Does

The command invokes the `cto-plan-reviewer` skill, which:

1. **Loads Context**
   - Reads track's `plan.md` and `spec.md`
   - Loads `conductor/tech-stack.md` for current technology decisions
   - Loads `conductor/product.md` for product constraints
   - Scans codebase for existing architecture patterns

2. **Applies CTO Advisor Frameworks**
   - **Architecture Review** — ADR templates, system design criteria, technology standards
   - **Tech Debt Assessment** — Debt analyzer, 40/25/15 allocation strategy, red flags
   - **Technology Evaluation** — 4-week evaluation framework, vendor management, cost analysis
   - **Engineering Excellence** — DORA metrics (deployment frequency, lead time, MTTR, CFR), quality metrics (test coverage >80%)
   - **Team & Process** — Execution feasibility, knowledge distribution, documentation needs

3. **Generates Technical Review Report**
   - Architecture assessment with specific recommendations
   - Tech debt analysis with severity and mitigation plan
   - Technology evaluation with alternatives and lock-in risk
   - Engineering excellence checklist (testing, performance, security, observability)
   - Team & process fit analysis
   - Red flags from CTO advisor checklist
   - DORA metrics impact assessment
   - Actionable recommendations (must-fix, should-consider, nice-to-have)
   - Final verdict: PASS / PASS WITH CONDITIONS / FAIL

## Output Format

```markdown
## CTO Technical Review Report

**Track**: [track-id]
**Reviewer**: cto-plan-reviewer (using cto-advisor frameworks)
**Date**: YYYY-MM-DD

### Architecture Assessment

#### Design Decisions
- [x] Architecture pattern: [pattern] — [assessment]
- [ ] CONCERN: [issue description]
- Recommendation: [action]

#### System Design
- [x] Component boundaries clear and well-defined
- [x] Separation of concerns maintained
- [ ] CONCERN: [issue]
- Recommendation: [action]

### Tech Debt Analysis

#### Debt Introduction: LOW | MEDIUM | HIGH
- Debt items introduced:
  1. [item] — Severity: [level] — Justification: [reason]

#### Mitigation Plan
- [x] Debt paydown plan documented
- [x] Capacity allocated per 40/25/15 strategy

### Technology Evaluation

#### New Dependencies
| Library/Service | Necessity | Alternatives | Lock-in Risk | Cost Impact |
|----------------|-----------|--------------|--------------|-------------|
| [dep] | [level] | [alternatives] | [risk] | [cost] |

### Engineering Excellence

#### Testing Strategy: [verdict]
#### Performance Criteria: [verdict]
#### Security Review: [verdict]
#### Observability: [verdict]

### DORA Metrics Impact Assessment

| Metric | Current Target | Impact of Plan | Assessment |
|--------|---------------|----------------|------------|
| Deployment Frequency | >1/day | [impact] | [assessment] |
| Lead Time | <1 day | [impact] | [assessment] |
| MTTR | <1 hour | [impact] | [assessment] |
| Change Failure Rate | <15% | [impact] | [assessment] |

### Recommendations

#### Must Fix (Blocking Issues)
1. [blocking issue]

#### Should Consider (Improvements)
1. [improvement]

#### Nice to Have (Enhancements)
1. [enhancement]

### Verdict

**Technical Review**: PASS | PASS WITH CONDITIONS | FAIL
**Rationale**: [summary]
```

## Integration with Conductor

This command is automatically invoked by the conductor during plan evaluation for technical tracks:

```
/conductor:run
  -> detects technical track (keywords: architecture, API, database, etc.)
  -> dispatches loop-plan-evaluator
    -> invokes /conductor:tech-review automatically
  -> aggregates standard checks + CTO review
  -> PASS/FAIL verdict
```

You can also run it manually at any time to get CTO-level guidance on the current plan.

## When CTO Review is Automatic

The conductor automatically includes CTO review when the track's `spec.md` or `plan.md` contains these keywords:

**Technical Keywords:**
- architecture, system design, integration, API, database, schema, migration
- infrastructure, scalability, performance, security
- authentication, authorization, deployment, monitoring, logging
- vendor, technology selection, framework, library

**If unsure whether your track needs CTO review**, run it manually. It's better to over-review than under-review critical technical decisions.

## CTO Advisor Frameworks Used

### 1. Architecture Decision Records (ADRs)
- Template for documenting technical decisions
- Context, options, decision, consequences format

### 2. Technology Evaluation Framework
- 4-week evaluation process
- Vendor assessment criteria (SLA, cost, lock-in risk)

### 3. Tech Debt Strategy
- 40/25/15 capacity allocation (Critical/High/Medium debt)
- Red flags checklist

### 4. DORA Metrics
- Deployment Frequency: >1/day
- Lead Time for Changes: <1 day
- Mean Time to Recovery: <1 hour
- Change Failure Rate: <15%

### 5. Engineering Metrics
- Test Coverage: >80% (70% overall, 90% business logic)
- Code Review: 100% of changes
- Technical Debt: <10% of capacity

### 6. System Design Review Criteria
- Component boundaries and separation of concerns
- Scalability and performance characteristics
- Error handling and resilience patterns
- Observability and debugging support

## Related

- `/conductor:review` — Post-execution quality gate (complementary)
- `/conductor:run` — Automated loop that includes CTO review for technical tracks
- `/cto` — General CTO advisory consultation (different from tech-review)
- `.claude/skills/cto-plan-reviewer/SKILL.md` — Full CTO review agent documentation
- `.claude/skills/cto-advisor/SKILL.md` — Core CTO advisor frameworks and tools
