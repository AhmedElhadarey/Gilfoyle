# Gilfoyle

**Multi-agent orchestration for Claude Code.** Plan, execute, evaluate, and fix — automatically.

Conductor turns Claude Code into a structured engineering system. Instead of ad-hoc prompting, every task flows through a rigorous **Evaluate-Loop** with specialized agents, quality gates, and automatic recovery. It ships with 16+ agents, 36 skills, a 5-member Board of Directors for architectural decisions, DAG-based parallel execution, and a learning system that improves across projects.

Built on top of [obra/superpowers](https://github.com/obra/superpowers) v4.3.0.

---

## Table of Contents

- [Key Features](#key-features)
- [Quick Start](#quick-start)
- [The Evaluate-Loop](#the-evaluate-loop)
- [Commands](#commands)
- [Agent System](#agent-system)
- [Board of Directors](#board-of-directors)
- [Parallel Execution](#parallel-execution)
- [Lead Engineer System](#lead-engineer-system)
- [Bundled Superpowers](#bundled-superpowers)
- [Knowledge Layer](#knowledge-layer)
- [Project Structure](#project-structure)
- [Extending Conductor](#extending-conductor)
- [Security Considerations](#security-considerations)
- [Third-Party Licenses](#third-party-licenses)
- [License](#license)

---

## Key Features

**Evaluate-Loop Workflow** — Every task follows Plan → Evaluate Plan → Execute → Evaluate Execution → Fix. No code ships without passing quality gates.

**16+ Specialized Agents** — Orchestrator, planners, executors, evaluators, fixers, code reviewers, and executive advisors. Each agent has a focused role and clear boundaries.

**Board of Directors** — Five expert directors (Chief Architect, CPO, CSO, COO, CXO) deliberate on major decisions through a structured assess → discuss → vote → resolve protocol.

**Parallel Execution** — Plans include dependency graphs (DAGs). Independent tasks run simultaneously through ephemeral worker agents coordinated via a file-based message bus.

**Lead Engineer System** — Architecture, Product, Tech, and QA leads make autonomous decisions within defined guardrails, reducing interruptions while maintaining control over high-impact choices.

**Learning System** — A knowledge manager loads relevant patterns before planning. A retrospective agent extracts learnings after completion. The system gets better at your codebase over time.

---

## Quick Start

### 1. Install

```
claude plugin install Gilfoyle
```

### 2. Initialize Your Project

In Claude Code, run:

```
/conductor setup
```

This creates the `conductor/` directory in your project with track registry, decision log, knowledge base, and workflow documentation.

Alternatively, `/gilfoyle` auto-initializes your project on first use -- no separate setup step needed.

### 3. Start Working

```
/gilfoyle <your goal>
```

That's it. The system analyzes your goal, creates a track with a spec and execution plan, evaluates the plan, executes tasks (in parallel where possible), evaluates the results, and fixes any issues automatically.

### Examples

```
/gilfoyle Add Stripe payment integration
/gilfoyle Fix the login bug where users get logged out after 5 minutes
/gilfoyle Build an admin dashboard with user analytics
/gilfoyle Refactor the auth system from sessions to JWT
```

### What Happens Behind the Scenes

1. **Goal Analysis** — Parses intent (feature, bugfix, refactor), estimates complexity, extracts requirements
2. **Track Detection** — Checks for existing matching tracks to resume, or creates a new one
3. **Spec Generation** — Writes a `spec.md` with requirements and acceptance criteria
4. **Plan Creation** — Generates `plan.md` with phased tasks, dependencies, and a DAG for parallel execution
5. **Plan Evaluation** — Validates scope, checks for overlap with completed work, verifies dependencies. For major tracks, convenes the Board of Directors
6. **Execution** — Runs tasks through specialized workers. Updates `plan.md` after every task. Commits at logical checkpoints
7. **Evaluation** — Dispatches specialized evaluators (UI/UX, code quality, integration, business logic) to verify the work
8. **Fix Cycle** — If evaluation fails, creates targeted fix tasks and re-evaluates (max 3 cycles before escalating to you)
9. **Completion** — Syncs business docs if needed, runs retrospective, updates track registry

---

## The Evaluate-Loop

The core workflow. Every track follows this loop without exception.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   1. PLAN ──► 2. EVALUATE PLAN ──► 3. EXECUTE              │
│                                        │                    │
│                                        ▼                    │
│                                   4. EVALUATE               │
│                                    EXECUTION                │
│                                        │                    │
│                              ┌─────────┴──────────┐        │
│                              │                    │        │
│                          PASS                  FAIL        │
│                              │                    │        │
│                              ▼                    ▼        │
│                      5.5 BUSINESS          6. FIX          │
│                       DOC SYNC             (max 3x)        │
│                              │                │            │
│                              ▼                └──► 3       │
│                        5. COMPLETE          (loop back)    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Step 1: Plan

Reads the track's `spec.md`, checks `tracks.md` for completed work, and generates `plan.md` with specific tasks, acceptance criteria, dependency DAG, and parallel execution groups.

### Step 2: Evaluate Plan

Validates the plan before any code is written:
- **Scope** — Does the plan match the spec? Nothing more, nothing less?
- **Overlap** — Does any task duplicate completed work?
- **Dependencies** — Are prerequisites satisfied?
- **Feasibility** — Can each task be completed with the current codebase?
- **Clarity** — Would a new agent session understand what to do from `plan.md` alone?
- **DAG Validity** — No cycles, no conflicting file access in parallel groups

For major tracks (architecture changes, integrations, infrastructure, P0 priority, 5+ tasks), the Board of Directors convenes for a full deliberation.

If any check fails, the plan goes back to Step 1 with specific feedback.

### Step 3: Execute

Tasks run in dependency order. Independent tasks execute in parallel through worker agents. After every task completion:
- `plan.md` is updated with status markers and a description of what was done
- Tests are run to catch regressions
- Commits happen at logical checkpoints

### Step 4: Evaluate Execution

A dispatcher determines the track type and invokes the right specialized evaluator:

| Evaluator | Track Type | Checks |
|-----------|-----------|--------|
| `eval-ui-ux` | Screens, design system | Design tokens, visual consistency, responsive behavior, accessibility |
| `eval-code-quality` | Features, infrastructure | Build integrity, type safety, patterns, error handling, dead code, tests |
| `eval-integration` | APIs, third-party services | API contracts, auth flows, data persistence, error recovery, env config |
| `eval-business-logic` | Core logic, pricing | Feature correctness, edge cases, state transitions, data flow |

Multi-type tracks get multiple evaluators. All must pass.

### Step 5/5.5: Complete / Business Doc Sync

If the track made product, pricing, or model decisions, business documents are synchronized before completion. The track registry is updated, a completion report is generated, and the retrospective agent extracts learnings.

### Step 6: Fix

When evaluation fails:
1. Parse the failure report into specific fix tasks
2. Add fix tasks to `plan.md`
3. Execute the fixes
4. Re-evaluate

After 3 failed fix cycles, the system escalates to the user rather than looping forever.

---

## Commands

### Core

| Command | Description |
|---------|-------------|
| `/gilfoyle <goal>` | Main entry point. State your goal, everything else is automatic |
| `/conductor setup` | Initialize Conductor in your project |
| `/conductor status` | View progress across all tracks |
| `/conductor new-track` | Create a new development track manually |
| `/conductor run` | Run the Evaluate-Loop on the current track |
| `/conductor health` | Check system health, agent status, and message bus state |
| `/conductor help` | Show available commands and usage information |
| `/conductor pause` | Pause the current track execution |
| `/conductor logs` | View execution logs for the current or specified track |

### Evaluation & Review

| Command | Description |
|---------|-------------|
| `/phase-review` | Run post-execution quality gate |
| `/board-meeting [proposal]` | Full 4-phase board deliberation with all 5 directors |
| `/board-review [proposal]` | Quick board assessment without discussion rounds |
| `/cto-advisor` | CTO-level technical architecture review |
| `/ui-audit` | Comprehensive UI/UX design validation |

### Loop Agents (Advanced)

| Command | Description |
|---------|-------------|
| `/loop-planner` | Run the planning step directly |
| `/loop-plan-evaluator` | Evaluate an existing plan |
| `/loop-executor` | Execute tasks from a plan |
| `/loop-execution-evaluator` | Evaluate completed execution |
| `/loop-fixer` | Fix issues from a failed evaluation |
| `/parallel-dispatcher` | Dispatch parallel worker agents |

### Executive Advisors

| Command | Description |
|---------|-------------|
| `/ceo` | Strategic business advice |
| `/cmo` | Marketing strategy and brand positioning |
| `/cto` | Technology architecture guidance |
| `/ux-designer` | UX strategy and design critique |

### Superpowers (Bundled)

| Command | Description |
|---------|-------------|
| `/write-plan` | Create an implementation plan with DAG structure |
| `/execute-plan` | Execute a plan with built-in TDD and debugging |
| `/brainstorm` | Explore approaches to a problem before committing to one |

---

## Agent System

Conductor operates through specialized agents, each with a focused responsibility. The `conductor-orchestrator` acts as the master coordinator, reading track state from `metadata.json` and dispatching the appropriate agent for the current loop step.

### Agent Dispatch

| Agent | Loop Step | Responsibility |
|-------|-----------|---------------|
| `conductor-orchestrator` | All | Master coordinator. Reads state, dispatches agents, manages transitions |
| `loop-planner` | Step 1 | Generates `plan.md` with tasks, acceptance criteria, and DAG |
| `loop-plan-evaluator` | Step 2 | Validates plan against spec, checks for overlap and dependency issues |
| `loop-executor` | Step 3 | Executes tasks sequentially, updates plan markers, commits code |
| `loop-execution-evaluator` | Step 4 | Dispatches specialized evaluators based on track type |
| `loop-fixer` | Step 6 | Creates and executes fix tasks from evaluation failures |
| `parallel-dispatcher` | Step 3 | Coordinates DAG-based parallel execution with worker agents |
| `task-worker` | Step 3 | Ephemeral worker for a single task in parallel execution |
| `board-meeting` | Step 2, 4 | Coordinates 5-director deliberation with discussion rounds |
| `code-reviewer` | On demand | Code review using superpowers patterns |
| `ceo`, `cmo`, `cto`, `ux-designer` | On demand | Executive advisor consultations |
| `name-picker` | On demand | Brand name generation through iterative refinement |

### Superpower-Enhanced vs Legacy Agents

New tracks set `superpower_enhanced: true` in their metadata. The orchestrator automatically dispatches the enhanced versions:

| Step | Superpower-Enhanced | Legacy |
|------|-------------------|--------|
| Plan | `superpowers:writing-plans` | `loop-planner` |
| Execute | `superpowers:executing-plans` | `loop-executor` |
| Fix | `superpowers:systematic-debugging` | `loop-fixer` |

The enhanced versions provide production-proven patterns, built-in resumption via parameters, and checkpoint-based progress tracking. Legacy agents remain available for backward compatibility.

### State Machine

All state lives in `metadata.json`, not agent memory. This enables exact resumption after interruptions:

```json
{
  "loop_state": {
    "current_step": "EXECUTE",
    "step_status": "IN_PROGRESS",
    "fix_cycle_count": 0,
    "max_fix_cycles": 3,
    "checkpoints": {
      "PLAN": { "status": "PASSED", "agent": "superpowers:writing-plans" },
      "EVALUATE_PLAN": { "status": "PASSED", "verdict": "PASS" },
      "EXECUTE": {
        "status": "IN_PROGRESS",
        "tasks_completed": 5,
        "tasks_total": 12,
        "last_task": "Task 2.3"
      }
    }
  }
}
```

When the orchestrator starts or resumes, it reads `current_step` and `step_status`, then picks up exactly where it left off.

---

## Board of Directors

A 5-member expert deliberation system for major architectural and product decisions.

### The Directors

| Director | Domain | Evaluates |
|----------|--------|-----------|
| **CA** — Chief Architect | Technical | System design, patterns, scalability, tech debt |
| **CPO** — Chief Product Officer | Product | User value, market fit, scope, feature alignment |
| **CSO** — Chief Security Officer | Security | Vulnerabilities, compliance, data protection |
| **COO** — Chief Operations Officer | Execution | Feasibility, timeline, resources, deployment risk |
| **CXO** — Chief Experience Officer | Experience | UX/UI quality, accessibility, user journey coherence |

### When the Board Convenes

| Checkpoint | Condition | Meeting Type |
|------------|-----------|-------------|
| Plan Evaluation | Major track (architecture, integration, infrastructure, P0, 5+ tasks) | Full meeting |
| Execution Evaluation | All tracks | Quick review |
| Pre-Launch | Production deployments | Security + Ops deep dive |
| Conflict | Evaluators disagree | Tie-breaker |

### Deliberation Protocol

**Phase 1: Assess** — All 5 directors evaluate the proposal independently, in parallel.

**Phase 2: Discuss** — Directors read each other's assessments, then challenge, agree, or clarify. Up to 3 discussion rounds.

**Phase 3: Vote** — Each director votes (approve/reject) with a confidence level (0–1) and optional conditions.

**Phase 4: Resolve** — The orchestrator aggregates votes into a verdict:

| Outcome | Verdict |
|---------|---------|
| 5-0 or 4-1 approve | **Approved** |
| 3-2 approve | **Approved with review** |
| 3-2 reject | **Rejected** |
| 4-1 or 5-0 reject | **Rejected** |
| Tie | **Escalated** to user |

Board sessions are stored in `metadata.json` with full vote records, conditions, and timestamps.

---

## Parallel Execution

Plans include explicit dependency graphs. Independent tasks run simultaneously through ephemeral worker agents.

### DAG Structure

```yaml
dag:
  nodes:
    - id: "1.1"
      name: "Create data store"
      files: ["src/stores/data-store.ts"]
      depends_on: []
    - id: "1.2"
      name: "Build resolver"
      files: ["src/lib/resolver.ts"]
      depends_on: []
    - id: "1.3"
      name: "Wire together"
      files: ["src/stores/data-store.ts"]
      depends_on: ["1.1", "1.2"]

  parallel_groups:
    - id: "pg-1"
      tasks: ["1.1", "1.2"]
      conflict_free: true
    - id: "pg-2"
      tasks: ["1.3"]
      conflict_free: true
```

Tasks 1.1 and 1.2 have no dependencies on each other and touch different files, so they execute in parallel. Task 1.3 depends on both, so it waits.

### Worker Agents

Workers are ephemeral — created from templates by the `agent-factory`, dispatched via parallel Task calls, and cleaned up after completion. Specializations include code, UI, integration, and test workers.

### Message Bus

Workers coordinate through a file-based message bus at `conductor/tracks/{track}/.message-bus/`:

| File | Purpose |
|------|---------|
| `queue.jsonl` | Append-only message log |
| `locks.json` | File locks for shared resources |
| `worker-status.json` | Worker heartbeats (every 5 minutes) |
| `events/` | Signal files for polling (TASK_COMPLETE, TASK_FAILED, etc.) |

### Failure Isolation

One worker failure does not block independent tasks. Failed task dependents are paused while other parallel work continues. The orchestrator retries failed tasks (max 2 attempts) before escalating. Deadlock detection runs with a 30-minute lock timeout and automatic victim selection.

---

## Lead Engineer System

The orchestrator minimizes interruptions by consulting specialized Lead Engineer agents for decisions within their authority.

### Authority Matrix

Three tiers of decision authority:

**User Only** — Always escalated, never decided autonomously:
- Budget changes over $50/month
- Adding or removing features from the spec
- Breaking API changes
- Runtime dependencies over 50KB gzipped
- Test coverage below minimum threshold
- Security or production data changes
- Pricing and business model changes

**Lead Consult** — Lead Engineers decide within guardrails:
- **Architecture Lead** — Apply existing codebase patterns, component organization, additive schema changes
- **Product Lead** — Interpret ambiguous spec requirements, task ordering, UX copy
- **Tech Lead** — Implementation approach, runtime dependencies under 50KB, any devDependencies
- **QA Lead** — Coverage thresholds, test type selection, mock strategy

**Orchestrator** — Decided autonomously:
- File and variable naming
- Task status markers
- devDependencies (any size)
- Following established conventions

All lead consultations are logged in `metadata.json` with the decision, reasoning, authority used, and whether escalation occurred.

### Escalation Triggers

The orchestrator stops and asks the user when:
1. Fix cycle limit exceeded (3 failed evaluate → fix cycles)
2. A `USER_ONLY` decision is required
3. A Lead Engineer escalates a decision beyond their authority
4. An external blocker prevents progress
5. Safety limit of 50 loop iterations reached

---

## Bundled Superpowers

Conductor bundles [obra/superpowers](https://github.com/obra/superpowers) v4.3.0 — a set of battle-tested Claude Code skills for structured software development.

| Skill | Purpose |
|-------|---------|
| `writing-plans` | Plan creation with DAG structure and phased tasks |
| `executing-plans` | Plan execution with built-in TDD and systematic debugging |
| `systematic-debugging` | Structured root-cause analysis with hypothesis testing |
| `brainstorming` | Collaborative design exploration before implementation |
| `test-driven-development` | TDD workflow: red → green → refactor |
| `subagent-driven-development` | Multi-agent task execution in a single session |
| `dispatching-parallel-agents` | Parallel agent coordination for independent tasks |
| `verification-before-completion` | Pre-completion quality checks with evidence requirements |
| `requesting-code-review` | Structured code review requests |
| `receiving-code-review` | Technical rigor when processing review feedback |
| `using-git-worktrees` | Isolated feature work via git worktrees |
| `finishing-a-development-branch` | Branch completion with merge/PR/cleanup options |
| `writing-skills` | Creating new Claude Code skills |

New tracks use Superpowers by default. Legacy tracks automatically fall back to the built-in loop agents. Existing tracks can opt in by adding `superpower_enhanced: true` to their `metadata.json`.

---

## Knowledge Layer

Conductor learns from your project over time through two agents:

### Knowledge Manager (Pre-Planning)

Before the planner runs, the knowledge manager:
1. Extracts keywords from the spec
2. Searches `conductor/knowledge/patterns.md` for relevant patterns
3. Searches `conductor/knowledge/errors.json` for known error patterns
4. Injects relevant context into the planner's prompt

### Retrospective Agent (Post-Completion)

After a track completes, the retrospective agent:
1. Analyzes all tasks and fix cycles
2. Extracts reusable patterns into `conductor/knowledge/patterns.md`
3. Records error patterns in `conductor/knowledge/errors.json`
4. Writes a track retrospective
5. Proposes improvements to skills

### Knowledge Files

| File | Content |
|------|---------|
| `conductor/knowledge/patterns.md` | Architecture patterns, code conventions, common pitfalls |
| `conductor/knowledge/errors.json` | Known error signatures and their fixes |
| `conductor/tracks/{id}/retrospective.md` | Track-specific learnings and post-mortem |

---

## Project Structure

```
conductor-orchestrator-superpowers/
├── .claude-plugin/
│   ├── plugin.json              # Plugin metadata and version
│   └── marketplace.json         # Marketplace listing
├── agents/                      # Agent definitions (Task tool subagent_type)
│   ├── conductor-orchestrator.md
│   ├── loop-planner.md
│   ├── loop-executor.md
│   ├── loop-fixer.md
│   ├── loop-plan-evaluator.md
│   ├── loop-execution-evaluator.md
│   ├── parallel-dispatcher.md
│   ├── task-worker.md
│   ├── board-meeting.md
│   ├── code-reviewer.md
│   └── ...                      # Executive advisors (ceo, cmo, cto, ux-designer)
├── commands/                    # User-invocable slash commands
│   ├── gilfoyle.md               # /gilfoyle entry point
│   ├── conductor/               # /conductor subcommands
│   │   ├── setup.md
│   │   ├── status.md
│   │   ├── run.md
│   │   └── new-track.md
│   └── ...                      # board-meeting, write-plan, brainstorm, etc.
├── skills/                      # Skill implementations (SKILL.md with YAML frontmatter)
│   ├── conductor-orchestrator/  # Master coordinator logic
│   ├── gilfoyle/                 # Goal-driven entry point
│   ├── loop-planner/            # Plan generation
│   ├── loop-executor/           # Task execution
│   ├── loop-fixer/              # Fix cycle handler
│   ├── loop-plan-evaluator/     # Plan validation
│   ├── loop-execution-evaluator/# Execution validation dispatcher
│   ├── eval-ui-ux/              # UI/UX specialized evaluator
│   ├── eval-code-quality/       # Code quality evaluator
│   ├── eval-integration/        # Integration evaluator
│   ├── eval-business-logic/     # Business logic evaluator
│   ├── board-of-directors/      # Board deliberation protocol
│   │   └── directors/           # Individual director definitions
│   ├── leads/                   # Lead engineer agents
│   │   ├── architecture-lead/
│   │   ├── product-lead/
│   │   ├── tech-lead/
│   │   └── qa-lead/
│   ├── knowledge/               # Learning system
│   │   ├── knowledge-manager/
│   │   └── retrospective-agent/
│   ├── parallel-dispatch/       # Parallel execution engine
│   ├── message-bus/             # Inter-agent coordination
│   ├── agent-factory/           # Dynamic worker creation
│   ├── brainstorming/           # Design exploration
│   ├── writing-plans/           # Superpowers plan creation
│   ├── executing-plans/         # Superpowers execution
│   ├── systematic-debugging/    # Superpowers debugging
│   ├── test-driven-development/ # TDD patterns
│   └── ...                      # Additional skills
├── docs/
│   ├── README.md                # Internal documentation
│   ├── workflow.md              # Complete Evaluate-Loop specification
│   └── authority-matrix.md      # Lead Engineer decision boundaries
├── hooks/
│   ├── hooks.json               # SessionStart hook registration
│   └── session-start.sh         # Injects using-superpowers skill on startup
├── lib/
│   └── skills-core.js           # YAML frontmatter parsing, skill resolution
├── scripts/
│   └── setup.sh                 # Project initialization script
├── LICENSES/
│   └── superpowers-MIT          # Third-party license (obra/superpowers)
└── LICENSE                      # MIT
```

### Runtime State (Per-Project)

When Conductor is initialized in a target project, it creates:

```
your-project/
└── conductor/
    ├── tracks.md                # Track registry
    ├── decision-log.md          # Audit trail for decisions
    ├── workflow.md              # Evaluate-Loop reference (copied from plugin)
    ├── authority-matrix.md      # Authority reference (copied from plugin)
    ├── knowledge/
    │   ├── patterns.md          # Learned patterns and conventions
    │   └── errors.json          # Known error signatures
    └── tracks/
        └── {track-id}/
            ├── spec.md          # Requirements and acceptance criteria
            ├── plan.md          # Phased tasks with DAG
            ├── metadata.json    # State machine, checkpoints, board sessions
            └── .message-bus/    # Worker coordination (parallel execution)
```

---

## Extending Conductor

### Creating a Skill

1. Create a directory under `skills/`:
   ```
   skills/my-skill/SKILL.md
   ```

2. Add YAML frontmatter:
   ```markdown
   ---
   name: my-skill
   description: "Use when [condition] - [what it does]"
   ---

   # My Skill

   Implementation instructions follow.
   ```

3. Skills can invoke other skills via the Skill tool and spawn agents via the Task tool.

### Creating an Agent

Agent definitions live in `agents/` as Markdown files. They define the agent's role, tools, and behavior for the Task tool's `subagent_type` parameter.

### Creating a Command

Commands in `commands/` are user-invocable slash commands. They typically load a skill and provide a user-facing entry point.

### Skill Resolution

`lib/skills-core.js` handles skill discovery:
- Parses YAML frontmatter from `SKILL.md` files
- Resolves skill names with `superpowers:` prefix support
- Searches recursively (max depth 3)
- Strips frontmatter for runtime use

---

## Security Considerations

**Guardrails are LLM-enforced.** The authority matrix, fix cycle limits, and USER_ONLY decision boundaries are implemented as detailed instructions that the AI agent follows — they are strong conventions, not programmatic controls. The system is designed for trust-based operation.

**Autonomous file access.** Worker agents have read/write access to your project filesystem during execution. Review the authority matrix to understand what decisions require your explicit approval.

**Git commits.** By default, the system asks for confirmation before committing. Use the `--autonomous` flag with `/gilfoyle` to enable automatic commits.

**Message bus data.** The `.message-bus/` directory may contain architectural decisions and code analysis. It is gitignored by default. Review and clean up after sensitive tracks.

**Shared environments.** Exercise additional caution when using Conductor in CI/CD pipelines or shared development environments where multiple users have access.

---

## Third-Party Licenses

### Superpowers (v4.3.0)

- **Author:** Jesse Vincent (jesse@fsck.com)
- **License:** MIT
- **Repository:** [github.com/obra/superpowers](https://github.com/obra/superpowers)
- **License file:** [LICENSES/superpowers-MIT](LICENSES/superpowers-MIT)

---

## License

MIT — see [LICENSE](LICENSE) for details.
