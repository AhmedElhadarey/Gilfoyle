# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Conductor Orchestrator Superpowers (v4.0) — a Claude Code plugin providing multi-agent orchestration for software development. It automates work through a structured **Evaluate-Loop**: Plan → Evaluate Plan → Execute → Evaluate Execution → Fix → Complete. Bundles [obra/superpowers](https://github.com/obra/superpowers) v4.3.0 (MIT).

## Project Structure

- `.claude-plugin/` — Plugin metadata (`plugin.json`, `marketplace.json`)
- `agents/` — Agent definitions (15 agents: orchestrator, loop agents, board members, executives, workers)
- `commands/` — Slash commands: 11 `/conductor` subcommands + `/gilfoyle` + advisory + board commands. Internal loop agents are `user_invocable: false`
- `skills/` — Skill implementations as `SKILL.md` files with YAML frontmatter (36+ skills)
- `skills/worker-templates/` — 4 worker templates for parallel execution (code, ui, integration, test)
- `docs/` — `README.md`, `workflow.md` (full Evaluate-Loop docs), `authority-matrix.md`
- `docs/plans/` — Design documents and board review reports
- `hooks/` — `hooks.json` + `session-start.sh` (injects `using-superpowers` skill on session start, detects first-time use)
- `lib/skills-core.js` — Core utilities: YAML frontmatter parsing (supports arrays, hyphenated keys), skill resolution, update checking
- `scripts/setup.sh` — Initializes `conductor/` directory in target projects (with git check, double-init prevention, errors.json bootstrap)

## Architecture

### Three-Layer System

1. **Commands** (`commands/*.md`) — User-facing slash commands that trigger skills/agents
2. **Skills** (`skills/*/SKILL.md`) — Implementation logic with YAML frontmatter (`name`, `description`). Skills invoke other skills via the Skill tool
3. **Agents** (`agents/*.md`) — Agent definitions used by the Task tool's `subagent_type` parameter

### Evaluate-Loop (Core Workflow)

Every track follows: `PLAN → EVALUATE_PLAN → EXECUTE → EVALUATE_EXECUTION → (PASS → BUSINESS_SYNC → COMPLETE | FAIL → FIX → loop back to EXECUTE, max 3 cycles)`

State is tracked in each track's `metadata.json` (v4 schema) with `loop_state.current_step` for exact resumption. Step name is `EXECUTE` (parallelism is an implementation detail within this step).

### Key Agent Dispatch (v4)

Superpowers are the PRIMARY dispatch path. Legacy loop agents are FALLBACK (for tracks without `superpower_enhanced: true`):

| Step | Primary | Fallback |
|------|---------|----------|
| Plan | `superpowers:writing-plans` | `loop-planner` |
| Execute | `superpowers:executing-plans` | `loop-executor` |
| Fix | `superpowers:systematic-debugging` | `loop-fixer` |
| Evaluate Plan | `loop-plan-evaluator` | (same) |
| Evaluate Execution | `loop-execution-evaluator` → specialized evaluators | (same) |

### Command Taxonomy (v4)

Primary: `/gilfoyle`, `/conductor:status`, `/brainstorm`
Power User: `/conductor:run` (was `implement`), `/conductor:health`, `/conductor:help`, `/conductor:pause`, `/conductor:logs`, `/conductor:migrate`, `/conductor:review` (was `phase-review`), `/conductor:tech-review` (was `cto-advisor`)
Internal (hidden): `/loop-executor`, `/loop-planner`, `/loop-fixer`, `/loop-plan-evaluator`, `/loop-execution-evaluator`, `/parallel-dispatcher`, `/task-worker`
Deprecated: `/phase-review` → `/conductor:review`, `/cto-advisor` → `/conductor:tech-review`

### `/gilfoyle` 3-Phase Flow (v4)

1. **Analyze** — Context detection, goal parsing, track matching
2. **Propose** — Spec summary + plan overview + confirmation (`[Y] yes [n] no [e] edit [p] preview`)
3. **Execute** — Real-time progress display with task status

Supports: `--plan-only`, `--dry-run`, `--autonomous`, `--track <id>`, `-i` (interactive multi-goal)

### Parallel Execution

Plans include DAG definitions with `parallel_groups`. Workers are spawned from templates in `skills/worker-templates/` (code, ui, integration, test) via `agent-factory`, dispatched in parallel, and coordinate through a file-based message bus. Atomic writes use `.tmp` + rename pattern.

### Authority Matrix

Three decision levels: **USER_ONLY** (budget >$50, scope changes, breaking API, deps >50KB), **LEAD_CONSULT** (Architecture/Product/Tech/QA leads decide within guardrails), **ORCHESTRATOR** (naming, conventions, devDeps). See `docs/authority-matrix.md`.

## Skill File Format

```markdown
---
name: skill-name
description: "Use when [condition] - [what it does]"
---
# Skill content here
```

`lib/skills-core.js` parses frontmatter (supports arrays like `depends_on: [a, b]` and hyphenated keys), resolves skill names (supports `superpowers:` prefix), and finds `SKILL.md` files recursively (max depth 3).

## Metadata Schema (v4)

All metadata uses `"version": 4`. Key fields: `loop_state.current_step` (PLAN, EVALUATE_PLAN, EXECUTE, EVALUATE_EXECUTION, FIX, BUSINESS_SYNC, COMPLETE), `superpower_enhanced: true` (default for new tracks), `checkpoints` for exact resumption. Atomic writes required (write to `.tmp`, rename).

## Runtime State (Per-Project, Not In This Repo)

When used in a target project, Conductor creates:
- `conductor/tracks/{track-id}/` — spec.md, plan.md, metadata.json per track
- `conductor/tracks/{track-id}/.message-bus/` — Worker coordination (gitignored)
- `conductor/knowledge/` — patterns.md, errors.json (learning system, gitignored)
- `conductor/tracks.md` — Track registry
- `conductor/decision-log.md` — Audit trail

## Security Note

All guardrails (authority matrix, fix cycle limits, USER_ONLY decisions) are LLM-enforced — strong conventions, not programmatic controls. Git commits default to confirmation; `--autonomous` flag enables automatic commits. Message bus data is gitignored.

## Task Status Markers in plan.md

```markdown
- [ ] Not started
- [~] In progress
- [x] Completed <!-- commit: abc1234 -->
- [!] Blocked
```

## Track Naming Convention

`{slug}_{YYYYMMDD}` (e.g., `add-stripe-payment_20260213`)
