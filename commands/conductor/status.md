---
name: status
description: "Show current track status with timeline view, active track progress, and next action recommendation"
user_invocable: true
---

# /conductor:status — Current Project Status

Display a comprehensive timeline-based status view across all tracks, the active evaluate-loop state, and a recommendation for the next action.

## Usage

```bash
/conductor:status
```

## Your Task

Read the following files to generate the status report:

1. **`conductor/tracks.md`** — List of all tracks and their statuses
2. **Active track's `metadata.json`** — Current loop step, state, timestamps
3. **Active track's `plan.md`** — Task completion progress
4. **`.message-bus/queue.jsonl`** — Event history for timeline (if exists)
5. **`.message-bus/worker-status.json`** — Active worker count (if exists)

## Output Format

Generate the following timeline-based status view:

```
-- CONDUCTOR STATUS -------------------------------------------
Active: [track-id]

Timeline:
  09:14  PLAN created (12 tasks, 3 phases)
  09:16  PLAN EVALUATION: PASS
  09:17  BOARD MEETING: APPROVED (4-1, 3 conditions)
  09:18  EXECUTE started (parallel, 3 workers)
  09:22  Phase 1 complete (4/4 tasks)
  09:31  Phase 2 in progress (2/5 tasks done)
  ---    NOW

Current: Task 2.3 (description)
Workers: [N] active
Fix cycles: 0/3

Next: Continue with /conductor:run

Other tracks:
  [done] auth-system (completed 2d ago)
  [wait] payment-integration (not started)
```

## Building the Timeline

### Step 1: Read metadata.json

Extract timestamps from the track's `metadata.json`:
- `created_at` — Track creation time
- `loop_state.current_step` — Current step name
- `loop_state.step_status` — Current step status
- `loop_state.fix_cycle_count` — Number of fix iterations
- `loop_state.step_history` — Array of step transitions with timestamps (if available)

### Step 2: Read plan.md

Count tasks to determine progress:
- Total tasks: count all `- [ ]` and `- [x]` items
- Completed tasks: count all `- [x]` items
- Group by phase (Phase 1, Phase 2, etc.)
- Identify current in-progress task

### Step 3: Read message bus (if available)

If `.message-bus/queue.jsonl` exists, parse events chronologically:
- `PLAN_COMPLETE_*` — Plan creation timestamp
- `PLAN_EVAL_COMPLETE_*` — Plan evaluation timestamp and result
- `BOARD_REVIEW_*` — Board meeting result
- `EXECUTE_COMPLETE_*` — Execution completion
- `EXEC_EVAL_COMPLETE_*` — Evaluation result
- `FIX_COMPLETE_*` — Fix cycle completion
- `TASK_COMPLETE_*` — Individual task completions

If message bus is not available, reconstruct timeline from metadata.json timestamps and plan.md content.

### Step 4: Read worker status (if available)

If `.message-bus/worker-status.json` exists, count active workers.

### Step 5: Determine "Next Action"

| Current State | Next Action Recommendation |
|---------------|---------------------------|
| No plan | `Run /conductor:run to generate plan` |
| Plan exists, not evaluated | `Run /conductor:run to evaluate plan` |
| Plan evaluated FAIL | `Run /conductor:run to revise plan` |
| Plan evaluated PASS, tasks pending | `Run /conductor:run to start execution` |
| Execution in progress | `Continue with /conductor:run` |
| Execution evaluated FAIL | `Run /conductor:run to start fix cycle` |
| Fix cycle exhausted (3/3) | `Manual intervention required — review failures` |
| All tasks done, not evaluated | `Run /conductor:run to evaluate execution` |
| Execution evaluated PASS | `Track complete — run /conductor:new-track for next work` |
| PAUSED | `Resume with /conductor:run or check /conductor:logs` |

### Step 6: List Other Tracks

Read `conductor/tracks.md` and list all non-active tracks with their status:

| Status | Display |
|--------|---------|
| Complete | `[done]` |
| In Progress (not active) | `[idle]` |
| Not Started | `[wait]` |
| Failed/Blocked | `[stop]` |
| Paused | `[pause]` |

## Active Track Indicator

The active track is determined by:
1. Track with `status: "active"` or `status: "in_progress"` in metadata.json
2. If multiple, the most recently modified track
3. If none, show "No active track" with suggestion to start one

## Elapsed Time

Calculate elapsed time from the track's `created_at` timestamp or from when execution started (if available in step_history). Display as:
- Under 1 hour: `Xm Ys`
- 1-24 hours: `Xh Ym`
- Over 24 hours: `Xd Yh`

## Fallback: Simple Status (when timeline data unavailable)

If message bus data is not available and metadata has no step_history, fall back to a simpler format:

```
-- CONDUCTOR STATUS -------------------------------------------
Active: [track-id]

Step: EXECUTE (Phase 2)
Tasks: 6/12 completed (50%)
  Phase 1: 4/4 [complete]
  Phase 2: 2/5 [in progress]
  Phase 3: 0/3 [waiting]

Current: Task 2.3 (description)
Fix cycles: 0/3
Superpower Enhanced: Yes

Next: Continue with /conductor:run

Other tracks:
  [done] auth-system (completed 2d ago)
  [wait] payment-integration (not started)
```

## Loop Step Reference

| Step | Name | Description |
|------|------|-------------|
| 1 | PLAN | Creating execution plan |
| 2 | EVALUATE_PLAN | Validating plan quality |
| 2a | CTO_REVIEW | Technical architecture review |
| 3 | EXECUTE | Implementing code changes |
| 4 | EVALUATE_EXECUTION | Quality checking implementation |
| 5 | FIX | Addressing evaluation failures |
| 5.5 | BUSINESS_DOC_SYNC | Syncing business documents |
| -- | PAUSED | Orchestration paused by user |
| OK | COMPLETE | Track finished |

## Related

- `/conductor:run` — Continue the evaluate-loop
- `/conductor:new-track` — Start a new track
- `/conductor:logs` — View detailed message bus history
- `/conductor:pause` — Pause an active orchestration
- `/gilfoyle` — Quick start with goal statement
