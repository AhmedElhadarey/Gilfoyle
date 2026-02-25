---
name: gilfoyle
description: "The single entry point to the Conductor system. Implements the 3-phase flow (Analyze, Propose, Execute) with resume mode, interactive mode, goal clarification, and escalation decision cards. v4 metadata format."
---

# /gilfoyle Skill — 3-Phase Goal-Driven Entry Point (v4)

The master entry point for all Conductor work. Parses user intent, determines mode, and drives the full lifecycle from goal to completion.

---

## Mode Selection

Parse `$ARGUMENTS` and determine which mode to enter:

```
IF $ARGUMENTS is empty OR $ARGUMENTS == "continue":
  -> MODE 2: Resume

ELSE IF $ARGUMENTS contains "-i" OR "--plan":
  -> MODE 3: Interactive

ELSE IF $ARGUMENTS contains "--track":
  -> Extract track ID from $ARGUMENTS
  -> MODE 2: Resume (specific track)

ELSE:
  -> Extract goal text (strip flags from $ARGUMENTS)
  -> Extract flags: --plan-only, --dry-run, --autonomous
  -> MODE 1: One-Shot
```

---

## Auto-Initialization

Before ANY mode, check if `conductor/` exists. If not, initialize inline:

```
IF conductor/ directory does NOT exist:
  Display:
    -- CONDUCTOR --------------------------------------------------
    This project hasn't been set up for Conductor yet.
    Setting up conductor/ directory... done.

  Create the following structure:
    conductor/
      index.md          (project overview - detect project name, stack)
      tracks.md         (empty tracks table)
      authority-matrix.md (default authority rules)
      knowledge/
        patterns.md     (empty patterns file)
        errors.json     ({"errors": []})

  Detect project context:
    - Read package.json, pyproject.toml, Cargo.toml, go.mod, etc.
    - Identify project name, language, framework
    - Store in conductor/index.md

  THEN continue to the selected mode.
```

---

## MODE 1: One-Shot (default when goal is provided)

This is the primary flow. Three phases: Analyze, Propose, Execute.

### Phase 1 -- ANALYZE (~10 seconds)

Gather context and parse the goal. Show results to user.

**Step 1.1: Read project state**
- Read git status: dirty files, current branch, recent commits
- Read `conductor/tracks.md` for active tracks
- Read `conductor/index.md` for project context (name, stack)

**Step 1.2: Parse goal**
- Classify type:
  - `Feature` -- if goal mentions: add, build, create, implement, new
  - `Bugfix` -- if goal mentions: fix, bug, error, broken, crash, issue
  - `Refactor` -- if goal mentions: refactor, clean, optimize, improve, simplify, restructure
  - `Research` -- if goal mentions: research, investigate, analyze, understand, explore
- Estimate complexity:
  - `Small` -- single file or component, < 3 tasks likely
  - `Medium` -- multiple files, 3-8 tasks likely
  - `Large` -- cross-cutting, 8+ tasks, multiple phases
- Extract key requirements from the goal text

**Step 1.3: Check for ambiguity**
If the goal is vague or could mean multiple things, trigger Goal Clarification (see section below) BEFORE proceeding.

**Step 1.4: Check for existing matching tracks**
- Search `conductor/tracks.md` for tracks with overlapping keywords
- If matches found, present them:
  ```
  Found existing tracks that may relate:
    1. [track-id] -- [status] ([step])
    2. [track-id] -- [status] ([step])

  [r] Resume track 1  [2] Resume track 2  [n] Create new track
  ```
- If user chooses resume, switch to resume flow for that track
- If no matches or user chooses new, continue to Phase 2

**Step 1.5: Display analysis**
```
-- CONDUCTOR --------------------------------------------------
Analyzing goal...
  Goal:     [parsed goal text]
  Type:     [Feature/Bugfix/Refactor/Research]
  Project:  [project name] ([detected stack])
  Existing: [N] active tracks, [conflicts or none]
```

### Phase 2 -- PROPOSE (requires confirmation unless --autonomous)

Generate the spec and plan, then present for approval.

**Step 2.1: Generate spec**
Create a specification from the goal:
- Overview: what we are building/fixing
- Requirements: specific deliverables
- Acceptance criteria: how to verify it works
- Dependencies: what this needs
- Out of scope: what we are NOT doing

Use codebase context to identify existing patterns, files to modify, tests to pass.

**Step 2.2: Generate plan overview**
Create a plan with:
- Phased task breakdown
- DAG with dependency graph and parallel groups
- Task count, phase count, parallel group count
- Board requirement assessment (required if: major feature, 8+ tasks, architecture/integration/infrastructure type, or P0 priority)

**Step 2.3: Generate track ID**
Format: `{goal-slug}_{YYYYMMDD}` where goal-slug is a lowercase kebab-case summary of the goal (max 40 chars).

**Step 2.4: Present proposal**
```
Generating spec and plan...

  Track:    [track-slug_date]
  Tasks:    [N] tasks across [M] phases
  Parallel: [P] groups identified
  Board:    [Required/Not required] ([reason])

  Proceed? [Y] yes  [n] no  [e] edit spec first  [p] preview full plan
```

**Step 2.5: Handle user response**
- `Y` or yes (default): proceed to Phase 3
- `n` or no: abort, do not create any files
- `e` or edit: show the full spec.md content, let user edit, then regenerate plan
- `p` or preview: show the full plan.md content with all tasks and DAG, then re-prompt

**Flag overrides:**
- `--plan-only`: After showing the proposal, STOP. Do not proceed to Phase 3. Display the full spec and plan, then exit.
- `--autonomous`: Skip the confirmation prompt entirely. Proceed directly to Phase 3.
- `--dry-run`: Proceed to Phase 3 but in simulation mode (see Phase 3).

### Phase 3 -- EXECUTE (dispatch orchestrator with real-time progress)

**Step 3.1: Create track artifacts**

Create the track directory and files:
```
conductor/tracks/{track-id}/
  spec.md           (from Phase 2)
  plan.md           (from Phase 2)
  metadata.json     (v4 schema, see below)
```

**v4 metadata.json schema:**
```json
{
  "version": 4,
  "track_id": "{track-id}",
  "type": "{feature|bugfix|refactor|research}",
  "status": "new",
  "created_at": "{ISO timestamp}",
  "goal": "{original user goal text}",
  "complexity": "{small|medium|large}",
  "superpower_enhanced": true,
  "loop_state": {
    "current_step": "NOT_STARTED",
    "step_status": "NOT_STARTED",
    "fix_cycle_count": 0,
    "max_fix_cycles": 3,
    "checkpoints": {}
  },
  "lead_consultations": [],
  "board_sessions": [],
  "blockers": [],
  "discovered_work": []
}
```

**Step 3.2: Register track**
Add the new track to `conductor/tracks.md` in the active tracks table.

**Step 3.3: Handle --dry-run**
If `--dry-run` flag is set:
- Show what WOULD happen: list each phase, each task, expected file modifications
- Do NOT write any code files, do NOT make commits
- DO create the track directory/spec/plan/metadata so the user can review
- Display: `[DRY RUN] Simulation complete. Track artifacts created but no code was written.`
- Exit.

**Step 3.4: Dispatch conductor-orchestrator**
Invoke the conductor-orchestrator agent to run the full Evaluate-Loop:

```
Use the conductor-orchestrator agent to run the evaluate-loop for track {track-id}.

Track directory: conductor/tracks/{track-id}/
Metadata: conductor/tracks/{track-id}/metadata.json
```

The orchestrator handles the full state machine: PLAN -> EVALUATE_PLAN -> EXECUTE -> EVALUATE_EXECUTION -> (FIX loop) -> COMPLETE. Do NOT duplicate the orchestrator's logic here.

**Step 3.5: Show real-time progress**
As the orchestrator runs, display progress updates:

```
-- EXECUTING --------------------------------------------------
Step: PLAN                                    [done]
Step: EVALUATE PLAN                           [done] PASS
Step: EXECUTE
  Phase 1: [Phase Name]                       [====------] 2/4
    [done]  Task 1.1: [name]                  (abc1234)
    [done]  Task 1.2: [name]                  (def5678)
    [run]   Task 1.3: [name]
    [wait]  Task 1.4: [name]                  (blocked by 1.3)
Workers: [N] active | Fix cycles: 0/3 | Elapsed: Nm Ns
```

Update this display as each task completes. When the track completes:
```
-- COMPLETE ---------------------------------------------------
Track:    [track-id]
Tasks:    [N]/[N] completed
Phases:   [M] completed
Commits:  [list key commit SHAs]
Elapsed:  [total time]
```

---

## MODE 2: Resume (bare /gilfoyle with no arguments, or --track <id>)

### If --track <id> is specified:
- Look up the track directly in `conductor/tracks.md`
- If found, dispatch conductor-orchestrator to resume it
- If not found, display error: `Track "{id}" not found. Use /conductor status to see all tracks.`

### If no arguments (bare /gilfoyle):

**Step R.1: Read active tracks**
Read `conductor/tracks.md` and filter for non-complete tracks.

**Step R.2: Branch on count**

**0 active tracks:**
```
-- CONDUCTOR --------------------------------------------------
No active tracks.

What would you like to work on?
```
Wait for user to provide a goal, then enter Mode 1 with that goal.

**1 active track:**
```
-- CONDUCTOR --------------------------------------------------
You have active work:

  1. [track-id]
     Step: [current_step] ([progress details])
     Last: [time since last update]

[Y] Resume  [s] Status  [n] New goal
```
- `Y` (default): dispatch conductor-orchestrator to resume the track
- `s`: show detailed status (read metadata.json, show checkpoints, task progress)
- `n`: ask for new goal, enter Mode 1

**2+ active tracks:**
Rank tracks by urgency: BLOCKED > FAILED > IN_PROGRESS > NOT_STARTED

```
-- CONDUCTOR --------------------------------------------------
You have [N] active tracks:

  1. [track-id]
     Step: [current_step] ([status])
     Last: [time since last update]

  2. [track-id]
     Step: [current_step] ([status])
     Last: [time since last update]

  ...

[1] Resume track 1  [2] Resume track 2  ...  [n] New goal
```
Let user choose which track to resume, or start new work.

---

## MODE 3: Interactive (/gilfoyle -i or /gilfoyle --plan)

Multi-goal batching with cross-goal dependency analysis.

**Step I.1: Collect goals**
```
-- CONDUCTOR: Interactive Planning ----------------------------

What do you want to accomplish? (enter goals one per line, empty line to finish)

>
```
Collect goals one at a time. Empty line signals completion.

**Step I.2: Analyze all goals**
For each goal, run the same analysis as Mode 1 Phase 1 (type, complexity, requirements). Then analyze cross-goal dependencies:
- Does goal B depend on changes from goal A?
- Do any goals conflict (modify same files in incompatible ways)?
- Are any goals "quick wins" that should go first?

**Step I.3: Propose execution order**
```
Analyzing [N] goals...

Recommended execution order:
  1. [goal-slug]                    ([type], [complexity], [reason for position])
  2. [goal-slug]                    ([type], [complexity], [reason for position])
  3. [goal-slug]                    ([type], [complexity], [reason for position])

Cross-dependencies detected:
  - [goal-slug-3] depends on [goal-slug-2] ([reason])

[Y] Accept order  [r] Reorder  [e] Edit goals
```

**Step I.4: Handle response**
- `Y` (default): create all tracks in order, begin executing the first one
- `r`: let user specify new order (e.g., "3, 1, 2")
- `e`: go back to goal collection, let user add/remove/modify goals

For execution: create all tracks up front (spec + plan + metadata for each), then dispatch the conductor-orchestrator for the first track. When it completes, automatically start the next.

---

## Goal Clarification

When the goal is ambiguous (vague verbs like "improve", "update", "work on" without specific scope, or when multiple distinct interpretations exist), present concrete interpretations:

```
"[user's goal]" could mean several things:

  [1] [Interpretation 1] -- [brief description of scope]
  [2] [Interpretation 2] -- [brief description of scope]
  [3] [Interpretation 3] -- [brief description of scope]
  [4] Something else (describe)

Which interpretation?
```

Guidelines for generating interpretations:
- Provide 3-4 concrete, actionable interpretations
- Each should be meaningfully different in scope or approach
- Always include "Something else" as the last option
- After user selects, continue Mode 1 with the clarified goal

Examples of ambiguous goals that trigger clarification:
- "Improve the auth system" (security? refactor? add OAuth?)
- "Work on the dashboard" (new? fix bugs? redesign? add features?)
- "Update the API" (versioning? new endpoints? refactor? docs?)
- "Make things faster" (frontend? backend? database? build?)

---

## Escalation Decision Cards

When the orchestrator hits a blocker (fix cycle exhausted, external dependency, unresolvable failure), present a structured decision card instead of a generic error message:

```
-- ESCALATION: [Type] ----------------------------------------
Track: [track-id]
Step:  [current step] ([context])

What keeps failing:
  1. [specific issue with details]
  2. [specific issue with details]

What was tried:
  Fix 1: [what was attempted] -- [result]
  Fix 2: [what was attempted] -- [result]
  Fix 3: [what was attempted] -- [result]

Root cause: [best assessment of why fixes are not working]

Options:
  [1] [specific actionable option]
  [2] [specific actionable option]
  [3] [specific actionable option]
  [4] Abandon track
```

### Escalation Types

| Type | Trigger | Typical Options |
|------|---------|-----------------|
| Fix Cycle Exhausted | 3 failed EVALUATE -> FIX cycles | Manual fix, revise spec, restart track, abandon |
| Board Rejected | Board voted to reject plan | Revise plan with conditions, override board, abandon |
| External Blocker | Dependency on unavailable service/data | Wait, mock it, change approach, abandon |
| Authority Escalation | USER_ONLY decision required | Present the decision with full context |
| Conflict Detected | New track conflicts with existing work | Merge tracks, sequence them, abandon one |

After user selects an option, take the corresponding action:
- If resuming with a fix: update metadata, dispatch orchestrator to continue
- If revising spec: re-enter Phase 2 with the revised spec
- If restarting: reset metadata to NOT_STARTED, re-run from Phase 1
- If abandoning: mark track as `abandoned` in metadata and tracks.md

---

## Progress Display Format

Use consistent formatting throughout all modes:

**Section headers:**
```
-- CONDUCTOR --------------------------------------------------
-- EXECUTING --------------------------------------------------
-- COMPLETE ---------------------------------------------------
-- ESCALATION: [Type] ----------------------------------------
```

**Task status markers:**
```
[done]  - Task completed successfully
[run]   - Task currently executing
[wait]  - Task waiting (blocked by dependency)
[fail]  - Task failed
[skip]  - Task skipped
```

**Progress bars:**
```
[==========] 10/10   (complete)
[====------]  4/10   (in progress)
[----------]  0/10   (not started)
```

---

## Error Handling

**Goal is empty and no active tracks:**
Ask the user what they want to work on. Do not fail silently.

**Track directory already exists for generated track-id:**
Append a numeric suffix: `{track-id}-2`, `{track-id}-3`, etc.

**metadata.json is corrupted or missing version field:**
Attempt to migrate to v4 format. If unrecoverable, create fresh metadata and warn user that previous state was lost.

**Orchestrator dispatch fails:**
Display error context and suggest: `Try /conductor health to diagnose, or /gilfoyle --track {id} to retry.`

---

## File References

| File | Purpose | This Skill's Interaction |
|------|---------|--------------------------|
| `conductor/tracks.md` | Track registry | Read to find active tracks, write to register new tracks |
| `conductor/index.md` | Project overview | Read for project name and stack detection |
| `conductor/tracks/{id}/spec.md` | Track specification | Create in Phase 2 |
| `conductor/tracks/{id}/plan.md` | Track plan with DAG | Create in Phase 2 |
| `conductor/tracks/{id}/metadata.json` | Track state (v4) | Create in Phase 3, read for resume |
| `conductor/knowledge/patterns.md` | Learned patterns | Read during analysis for context |
| `conductor/knowledge/errors.json` | Known error patterns | Read during analysis for context |

---

## Dispatch Reference

This skill dispatches the `conductor-orchestrator` for execution. It does NOT duplicate the orchestrator's state machine, agent dispatch, or evaluation logic. The boundary is:

- **`/gilfoyle` skill owns**: goal parsing, mode selection, track creation, user confirmation, progress display, escalation presentation
- **`conductor-orchestrator` owns**: state machine transitions, agent dispatch (superpowers or legacy), evaluation, fix cycles, board integration, knowledge layer, completion protocol
