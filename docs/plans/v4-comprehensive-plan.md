# Conductor v4 — Comprehensive Improvement Plan

**Generated**: 2026-02-25
**Sources**: Board of Directors (5 directors), CTO Advisor, UX Designer, Code Reviewer
**Verdict**: APPROVED WITH CONDITIONS (5-0)
**Timeline**: 6-8 week sprint to v4.0, then open-source

---

## Executive Summary

Four independent review teams analyzed the entire plugin. The consensus: **the core architecture is strong and genuinely differentiated** — no competing system (LangGraph, CrewAI, AutoGen) has the Evaluate-Loop, Board of Directors deliberation, track-type-aware evaluators, or the authority matrix. But the plugin is **not ready for open-source in its current state**. There are 4 critical bugs, 8 important issues, 7 feature gaps, and a significant UX overhaul needed — particularly around the `/go` entry point.

---

## Part 1: Critical Bugs (Must Fix Immediately)

### C1. Conflicting Agent Dispatch Strategies

**The problem**: The skill `conductor-orchestrator/SKILL.md` defines a state machine that dispatches `loop-planner`, `loop-executor`, `loop-fixer` with `PARALLEL_EXECUTE` as a step. The agent `agents/conductor-orchestrator.md` defines a "SUPERPOWER-ENHANCED" dispatch table using `superpowers:writing-plans`, `superpowers:executing-plans`, `superpowers:systematic-debugging` with `EXECUTE` as the step. The `/go` skill adds a third interpretation via the `superpower_enhanced` flag.

**Impact**: An LLM agent reading these conflicting instructions will either pick one arbitrarily or get confused, leading to failed orchestration loops.

**Fix**: Unify the dispatch strategy. Commit fully to superpower-enhanced agents. Update the skill, agent, and `/go` skill to use identical step names and dispatch targets.

**Files**:
- `skills/conductor-orchestrator/SKILL.md` (line 248-269)
- `agents/conductor-orchestrator.md` (line 301-320)
- `skills/go/SKILL.md` (line 76-79)

### C2. State Machine Step Name Mismatch: PARALLEL_EXECUTE vs EXECUTE

**The problem**: The skill uses `PARALLEL_EXECUTE`, the agent uses `EXECUTE`, the plan evaluator agent sets `PARALLEL_EXECUTE` on pass, the plan evaluator skill sets `EXECUTE` on pass. If anything sets `PARALLEL_EXECUTE`, the main loop will not recognize it and stall.

**Fix**: Standardize on one name everywhere. If parallel execution is the default, use `EXECUTE` and treat parallelism as an implementation detail.

**Files**:
- `skills/conductor-orchestrator/SKILL.md` (line 253-258)
- `agents/conductor-orchestrator.md` (line 312)
- `agents/loop-plan-evaluator.md` (line 97-98)
- `skills/loop-plan-evaluator/SKILL.md` (line 354)

### C3. Missing `break` in Resumption Protocol Switch Statement

**The problem**: In `conductor-orchestrator/SKILL.md`, the `FAILED` case falls through to `BLOCKED` because there is no `break`. Any `FAILED` state that isn't `EVALUATE_PLAN` or `EVALUATE_EXECUTION` silently falls into the wrong handler.

**Fix**: Add `break` after the `FAILED` case. Add a default handler for unrecognized failed steps.

**File**: `skills/conductor-orchestrator/SKILL.md` (line 763-764)

### C4. File Lock Race Condition in Message Bus

**The problem**: `acquire_lock` in message-bus reads `locks.json`, checks it, writes back — classic TOCTOU race. Two workers reading simultaneously will both see it as unlocked. Same issue with `queue.jsonl` appends.

**Fix**: Add explicit warnings in the skill that file operations must be atomic. Use `.lock` sentinel file or `flock`-style advisory locking. Long-term: migrate to SQLite for the message bus.

**File**: `skills/message-bus/SKILL.md` (line 124-152, 68-84)

---

## Part 2: The `/go` Entry Point Redesign

All four review teams converged on the same conclusion: **do not replace `/go`, enhance it with a 3-phase flow and three interaction modes**.

### Current (v3.2): Fire-and-Forget
```
User: /go Add Stripe payment integration
→ [runs silently for 30+ minutes]
→ Complete or escalate
```

### New (v4): Analyze → Propose → Execute

#### Mode 1: One-Shot (Default)

```
/go Add Stripe payment integration
```

**Phase 1 — Analyze** (~10s, shown to user):
```
-- CONDUCTOR --------------------------------------------------

Analyzing goal...

  Goal:     Add Stripe payment integration
  Type:     Feature
  Project:  my-saas-app (Next.js + Prisma)
  Existing: 2 active tracks, 0 conflicts detected

Generating spec and plan...

  Track:    stripe-payment-integration_20260225
  Tasks:    12 tasks across 4 phases
  Parallel: 2 groups identified
  Board:    Required (major feature, 12 tasks)

Proceed? [Y] yes  [n] no  [e] edit spec first  [p] preview plan
```

**Phase 2 — Propose**: User confirms, edits, or previews before committing.

**Phase 3 — Execute** (real-time progress):
```
-- EXECUTING --------------------------------------------------

Phase 1: Foundation                          [====------] 2/4
  [done]  Task 1.1: Create Stripe client     (abc1234)
  [done]  Task 1.2: Add config schema        (def5678)
  [run]   Task 1.3: Create checkout API route
  [wait]  Task 1.4: Add webhook handler      (blocked by 1.3)

Workers: 2 active | Fix cycles: 0/3
Elapsed: 8m 22s
```

#### Mode 2: Resume (Bare `/go`)

When invoked without arguments, shows active tracks and lets user choose:

```
-- CONDUCTOR --------------------------------------------------

You have active work:

  1. stripe-payment-integration_20260225
     Step: EXECUTE (6/12 tasks done)
     Last: 3 hours ago

  2. refactor-auth-system_20260220
     Step: EVALUATE_PLAN (awaiting board)
     Last: 2 days ago

[1] Resume track 1  [2] Resume track 2  [n] New goal
```

#### Mode 3: Interactive (`/go -i` or `/go --plan`)

Multi-goal batching with dependency analysis:
```
-- CONDUCTOR: Interactive Planning ----------------------------

What do you want to accomplish?

> Add Stripe payment integration
> Fix the login timeout bug
> Refactor the API layer to use proper error codes
>

Analyzing 3 goals...

Recommended execution order:
  1. fix-login-timeout           (quick win, independent)
  2. api-error-codes-refactor    (foundation for Stripe)
  3. stripe-payment-integration  (depends on error codes)

[Y] Accept order  [r] Reorder  [e] Edit goals
```

#### Goal Clarification Flow

When the system detects ambiguity:
```
/go Improve the auth system

"Improve the auth system" could mean several things:

  [1] Security hardening — rate limiting, CSRF, session rotation
  [2] Refactor to JWT — replace sessions with tokens
  [3] Add OAuth — Google, GitHub login alongside email/password
  [4] Something else (describe)

Which interpretation?
```

#### New Flags

| Flag | Behavior |
|------|----------|
| `--plan-only` | Run Phases 1-2 only. Show spec + plan, do not execute |
| `--dry-run` | Simulate Phase 3 without writing files or commits |
| `--autonomous` | Skip Phase 2 confirmation, run fully automated |
| `--track [id]` | Resume a specific track by ID |

---

## Part 3: Command System Overhaul

### Problem

25 commands with no hierarchy, no discoverability, internal agents exposed as user commands.

### Solution: Three-Tier Architecture

**Tier 1 — Primary (what 90% of users need):**

| Command | Purpose |
|---------|---------|
| `/go` | Start or resume work |
| `/conductor status` | See where things stand |
| `/brainstorm` | Think before building |

**Tier 2 — Power User:**

| Command | Purpose |
|---------|---------|
| `/conductor setup` | Initialize project |
| `/conductor new-track` | Manual track creation |
| `/conductor run` | Run Evaluate-Loop (renamed from `implement`) |
| `/conductor health` | Validate installation (NEW) |
| `/conductor pause` | Gracefully halt orchestration (NEW) |
| `/conductor logs [track]` | Human-readable message bus history (NEW) |
| `/conductor knowledge show` | Display learned patterns (NEW) |
| `/conductor help` | Show all commands with descriptions (NEW) |
| `/conductor migrate` | Migrate legacy tracks to v4 (NEW) |
| `/board-meeting` | Full board deliberation |
| `/board-review` | Quick board assessment |
| `/cto-advisor` → rename to `/conductor tech-review` | Technical architecture review |
| `/phase-review` → rename to `/conductor review` | Quality gate |
| `/ui-audit` | UI/UX validation |
| `/write-plan` | Manual plan creation (standalone, outside tracks) |
| `/execute-plan` | Manual plan execution (standalone, outside tracks) |

**Tier 3 — Advisory:**

| Command | Purpose |
|---------|---------|
| `/ceo` | Business strategy consultation |
| `/cmo` | Marketing consultation |
| `/cto` | Technical consultation |
| `/ux-designer` | Design consultation |

**Remove from user-invocable list** (internal agents only):

| Command | Reason |
|---------|--------|
| `/loop-executor` | Internal agent, exposed through `/conductor run` |
| `/loop-planner` | Internal agent |
| `/loop-fixer` | Internal agent |
| `/loop-plan-evaluator` | Internal agent |
| `/loop-execution-evaluator` | Internal agent |
| `/parallel-dispatcher` | Internal agent |
| `/task-worker` | Internal agent |

### Key Renames

| Current | New | Reason |
|---------|-----|--------|
| `/conductor implement` | `/conductor run` | "Run" is clearer than "implement" for orchestration |
| `/cto-advisor` | `/conductor tech-review` | Distinguishes from `/cto` consultation |
| `/phase-review` | `/conductor review` | Keeps it in the conductor namespace |

---

## Part 4: Architecture Fixes

### A1. Decompose the Conductor Orchestrator God Object

**Problem**: `conductor-orchestrator/SKILL.md` is 1000+ lines containing goal analysis, track management, state machine, lead consultation, parallel execution, board integration, knowledge layer, resumption, and escalation — all in one skill that one agent must internalize.

**Fix**: Decompose into a thin dispatcher that reads state, makes one routing decision, and delegates. Each state transition should be its own atomic skill invocation.

**Priority**: P0

### A2. Unify Metadata Version

**Problem**: `track-manager/SKILL.md` creates metadata with `"version": 2`, `go/SKILL.md` creates with `"version": 3`, orchestrator references "v3". No JSON schema exists.

**Fix**: Standardize on `"version": 4` for v4.0. Create a JSON schema at `conductor/schemas/metadata.v4.json`. Add auto-migration from v2/v3 on read.

**Priority**: P1

### A3. Add Lightweight Invariant Enforcement

**Problem**: All guardrails (fix cycle limits, authority matrix, USER_ONLY decisions, state machine transitions) are prose instructions — not programmatic controls. The LLM IS the runtime.

**Fix**: Add a ~200-line Node.js runner that reads `metadata.json`, validates current state against JSON schema, determines the correct next agent, and validates the state was updated correctly after dispatch. This is a wrapper, not a rewrite.

**Priority**: P1

### A4. Deprecate Legacy Track Path

**Problem**: Legacy (loop-planner/executor/fixer) and superpowers paths coexist with no sunset. Two code paths doubles maintenance.

**Fix**: Mark legacy as deprecated in v4. Add `/conductor migrate [track-id]`. Announce 90-day sunset. Remove in v4.2.

**Priority**: P1

### A5. Create Shared Path/Schema Registry

**Problem**: Skills reference `conductor/tracks/{trackId}/metadata.json` as string literals. No contract definition. Renaming a directory requires auditing every skill.

**Fix**: Create `conductor-paths.md` reference that all skills point to. Add a manifest schema declaring inputs/outputs per skill.

**Priority**: P1

---

## Part 5: Missing Features

### F1. Missing Worker Templates (BLOCKING)

**Problem**: The four worker templates referenced in `agent-factory/SKILL.md` and `parallel-dispatch/SKILL.md` do not exist in the repository:
- `code-worker.template.md`
- `ui-worker.template.md`
- `integration-worker.template.md`
- `test-worker.template.md`

Parallel execution is documented but partially unimplemented.

**Fix**: Implement all four templates with the worker protocol (check deps → lock files → execute → post TASK_COMPLETE/FAILED → release locks).

**Priority**: P0 (blocking for open-source)

### F2. Missing `errors.json` Bootstrap

**Problem**: `setup.sh` does not create `conductor/knowledge/errors.json`, but multiple skills reference it. First access will crash.

**Fix**: Add to setup.sh: `{ "errors": [] }`

**Priority**: P0

### F3. Missing `business-docs-sync` Frontmatter

**Problem**: `skills/business-docs-sync/SKILL.md` lacks YAML frontmatter. `skills-core.js` returns empty name/description.

**Fix**: Add standard frontmatter.

**Priority**: P1

### F4. No Rollback Capability

**Problem**: No way to undo work. If the executor writes bad code and fix cycles exhaust, there's no `git revert` integration.

**Fix**: Before each execution phase, record the git SHA. If evaluation fails and cycles exhaust, offer rollback to pre-execution checkpoint.

**Priority**: P1

### F5. No Health Check / Diagnostics

**Problem**: No way to verify the plugin is correctly installed or that conductor/ is in a valid state.

**Fix**: `/conductor health` command that validates: all skills present with valid frontmatter, conductor directory structure exists, metadata files parse correctly, knowledge base files exist, hooks registered.

**Priority**: P1

### F6. No Track Archival

**Problem**: Completed tracks accumulate indefinitely with no cleanup.

**Fix**: Add archival protocol to track completion. Move completed tracks to `conductor/archive/`.

**Priority**: P2

### F7. No Starter Knowledge Base

**Problem**: The learning layer provides zero value on day one. Requires weeks of usage to become useful.

**Fix**: Ship 20+ common patterns organized by stack (Next.js, React, TypeScript, FastAPI, auth patterns, etc.). Community can contribute immediately.

**Priority**: P1

---

## Part 6: Code Quality Fixes

### Q1. `skills-core.js` — Silent Error Swallowing

`extractFrontmatter` returns `{ name: '', description: '' }` on any error with no logging.

**Fix**: Log to stderr before returning fallback. Add an `error` field to the return object.

### Q2. `skills-core.js` — Synchronous Network I/O

`checkForUpdates` uses `execSync('git fetch')` blocking for up to 3 seconds.

**Fix**: Make async with `execFile`/`spawn`, or document the blocking behavior.

### Q3. `skills-core.js` — YAML Parser Too Simplistic

The regex `line.match(/^(\w+):\s*(.*)$/)` fails on multi-line values, arrays, nested objects.

**Fix**: Use a proper YAML parser (js-yaml) for frontmatter extraction. Required before adding `depends_on` arrays.

### Q4. Deadlock Detection Bug in Message Bus

`wait_for` map uses event names instead of worker IDs. The cycle detection will never find cycles.

**Fix**: Resolve `waiting_for` to the worker holding the lock, then build the wait-for graph.

**File**: `skills/message-bus/SKILL.md` (line 326-356)

### Q5. Incorrect Path References in Skills

`conductor-orchestrator/SKILL.md` references `.claude/skills/leads/` and `agent-factory/SKILL.md` references `.claude/skills/worker-templates/`. These should be plugin-relative paths.

**Fix**: Document path resolution or use relative paths.

### Q6. Inconsistent Pseudocode Languages

Skills mix TypeScript, Python, and JavaScript inconsistently.

**Fix**: Standardize on TypeScript for all pseudocode.

---

## Part 7: Security (Before Open-Source)

### S1. Autonomous Git Commits — Change to Opt-In

**Current**: Workers commit to git without user confirmation by default.
**Fix**: Default to confirmation. Add `--autonomous` flag for fire-and-forget.

### S2. Add .gitignore Entries

Add to setup script's generated `.gitignore`:
```
conductor/.message-bus/
conductor/knowledge/
```

### S3. Add README Disclaimer

Document clearly that:
- Guardrails (authority matrix, fix cycle limits, USER_ONLY decisions) are LLM-enforced — strong conventions, not programmatic controls
- The plugin dispatches autonomous agents with write access to the filesystem
- Review security considerations before using in shared/CI environments

### S4. Message Bus Cleanup (P1)

Implement message bus rotation after track completion. Prevent indefinite accumulation of sensitive data.

### S5. Secrets Scanner (P2)

Add a scanner that redacts sensitive strings from message bus logs and knowledge base entries.

---

## Part 8: Onboarding Improvements

### O1. Auto-Initialize from `/go`

When `/go` is invoked and no `conductor/` directory exists, initialize inline instead of failing:

```
/go Add user authentication

This project hasn't been set up for Conductor yet.
Setting up conductor/ directory... done.

Now processing your goal...
```

### O2. First-Session Welcome Message

Session-start hook should detect whether `conductor/` exists. If not:
```
Conductor Superpowers is available. Type /go <your goal> to get started,
or /conductor help to see all commands.
```

### O3. `/conductor quickstart`

A demo mode that runs a complete track end-to-end in under 10 minutes, showing the user every step.

### O4. Setup Validation

`setup.sh` should check:
- Is this a git repository? (warn if not)
- Does package.json exist? (helps determine project type)
- Are there existing `.claude/` configurations?

---

## Part 9: Escalation UX Redesign

### Current (v3.2)
```
## Orchestrator Paused — User Input Required
**Track**: [track-id]
**Reason**: [reason]
**Options**: 1. [option] 2. [option]
```

### New (v4): Structured Decision Cards

```
-- ESCALATION: Fix Cycle Exhausted ----------------------------

Track: stripe-payment-integration_20260225
Step:  EVALUATE_EXECUTION (failed 3 times)

What keeps failing:
  1. Webhook handler throws 500 on duplicate events
  2. Test coverage at 68% (target: 70%)

What was tried:
  Fix 1: Added deduplication logic — still fails (DB allows duplicates)
  Fix 2: Added try/catch — masks error, tests still fail
  Fix 3: Added unique index — migration fails (existing duplicates)

Root cause:
  Events table has ~40 duplicate rows from testing.
  Migration cannot add unique constraint until cleaned up.

Options:
  [1] Clean up duplicates manually, then resume
  [2] Modify spec to allow duplicate events
  [3] Restart track with revised approach
  [4] Abandon track
```

---

## Sprint Plan

### Week 1-2: Foundation (Critical Bugs + Missing Pieces)

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 1 | Fix C1: Unify dispatch strategies (skill vs agent) | P0 | Medium |
| 2 | Fix C2: Standardize step names (EXECUTE everywhere) | P0 | Small |
| 3 | Fix C3: Add break in switch statement | P0 | Tiny |
| 4 | Fix C4: Document atomic file ops in message bus | P0 | Small |
| 5 | Implement F1: Four worker templates | P0 | Large |
| 6 | Fix F2: Add errors.json to setup.sh | P0 | Tiny |
| 7 | Fix F3: Add frontmatter to business-docs-sync | P1 | Tiny |
| 8 | Fix A2: Standardize metadata version to v4 | P1 | Medium |

### Week 3-4: `/go` Redesign + Command Overhaul

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 9 | Implement `/go` 3-phase flow (analyze → propose → execute) | P0 | Large |
| 10 | Add `/go` flags: `--plan-only`, `--dry-run`, `--autonomous`, `--track` | P1 | Medium |
| 11 | Add resume mode (bare `/go` shows active tracks) | P1 | Medium |
| 12 | Add goal clarification flow (ambiguity detection) | P1 | Medium |
| 13 | Unify command namespace under `/conductor` | P0 | Medium |
| 14 | Hide internal agents from user-invocable commands | P0 | Small |
| 15 | Rename: `implement` → `run`, `phase-review` → `review`, `cto-advisor` → `tech-review` | P1 | Small |

### Week 5-6: Observability + Onboarding

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 16 | Implement `/conductor status` with timeline view | P1 | Medium |
| 17 | Implement `/conductor logs [track-id]` | P1 | Medium |
| 18 | Implement `/conductor health` | P1 | Medium |
| 19 | Implement `/conductor help` | P1 | Small |
| 20 | Add live progress output during Evaluate-Loop | P1 | Medium |
| 21 | Auto-initialize conductor/ from `/go` on first use | P1 | Small |
| 22 | Add first-session welcome message to hook | P1 | Small |
| 23 | Create `/conductor quickstart` demo | P1 | Large |
| 24 | Ship starter knowledge base (20+ patterns) | P1 | Medium |

### Week 7: Safety + Documentation

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 25 | Change autonomous commits to opt-in | P0 | Small |
| 26 | Add .gitignore entries for message-bus and knowledge | P0 | Tiny |
| 27 | Add security/guardrail disclaimer to README | P0 | Small |
| 28 | Implement escalation decision cards | P1 | Medium |
| 29 | Implement `/conductor migrate` for legacy deprecation | P1 | Medium |
| 30 | Implement `/conductor pause` | P1 | Medium |

### Week 8: Hardening + Release

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 31 | Add Node.js metadata state validator | P1 | Medium |
| 32 | Create JSON schema for metadata.json | P1 | Medium |
| 33 | Fix Q1-Q6 code quality issues | P1 | Medium |
| 34 | Implement checkpoint-based rollback (F4) | P1 | Medium |
| 35 | Fix deadlock detection bug (Q4) | P1 | Small |
| 36 | Decompose orchestrator god object (A1) | P0 | Large |
| 37 | Write v3 → v4 migration guide | P1 | Small |

### Post-Release (v4.1+)

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 38 | CONTRIBUTING.md for open-source contributors | P1 | Medium |
| 39 | Secrets scanner for message bus | P2 | Medium |
| 40 | Message bus rotation/cleanup after track completion | P2 | Small |
| 41 | Migrate message bus to SQLite | P2 | Large |
| 42 | Semantic similarity for track matching | P2 | Medium |
| 43 | Cross-track dependency management | P2 | Large |
| 44 | Track archival protocol | P2 | Small |
| 45 | Skill dependency declaration system | P2 | Medium |
| 46 | Skill versioning in frontmatter | P2 | Small |
| 47 | Skill smoke-test harness | P2 | Large |
| 48 | GitHub Issues / Linear import | P2 | Large |
| 49 | Track template system (pre-built specs) | P2 | Medium |
| 50 | Cross-session preference memory | P2 | Medium |

---

## Competitive Differentiation

What Conductor has that LangGraph, CrewAI, and AutoGen do not:

| Feature | Competitors | Conductor |
|---------|------------|-----------|
| Multi-perspective expert review | None | Board of Directors (5 directors) |
| Track-type-aware evaluation | None | 4 specialized evaluators (UI, code, integration, logic) |
| Authority matrix with lead consultation | None | 3-tier decision system (user / lead / autonomous) |
| Evaluate-Loop as first-class workflow | None | Plan → Eval → Execute → Eval → Fix with state machine |
| Plan-preview before execution | None | v4: `/go` Phase 2 confirmation |
| Learning across projects | None | Knowledge manager + retrospective agent |

---

## Summary

**Total items**: 50 tasks across 8 weeks + post-release backlog
**Critical (P0)**: 14 items (weeks 1-4)
**Important (P1)**: 23 items (weeks 3-8)
**Nice-to-have (P2)**: 13 items (post-release)

The core message from all four review teams: **the architecture is worth shipping — it needs completion, not redesign.** Fix the critical bugs, enhance `/go` with the 3-phase flow, unify the command namespace, add observability, and ship.
