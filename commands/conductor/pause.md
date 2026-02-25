---
name: pause
description: "Gracefully pause an in-flight orchestration"
user_invocable: true
---

# /conductor:pause — Pause Orchestration

Gracefully pause an active orchestration. Writes a PAUSED state to the track's metadata so that no further agents are dispatched until the user explicitly resumes.

## Usage

```bash
/conductor:pause
/conductor:pause my-track-id
```

## Your Task

### Step 1: Identify Active Track

If a track ID is provided, use it. Otherwise:
1. Read `conductor/tracks.md` for active tracks
2. Read each active track's `metadata.json`
3. Find the track with `status: "active"` or `status: "in_progress"`
4. If no active track, report: "No active orchestration to pause."

### Step 2: Record Current State

Before pausing, capture the current state for later resumption:
- Current step (`loop_state.current_step`)
- Step status (`loop_state.step_status`)
- Task progress (count of completed vs total tasks)
- Active workers (from `.message-bus/worker-status.json` if available)

### Step 3: Update metadata.json

Write the paused state to the track's `metadata.json`:

```json
{
  "status": "paused",
  "loop_state": {
    "current_step": "PAUSED",
    "step_status": "PAUSED",
    "previous_step": "<the step that was running>",
    "previous_step_status": "<the status of that step>",
    "fix_cycle_count": "<preserved>",
    "paused_at": "YYYY-MM-DDTHH:mm:ssZ",
    "paused_reason": "user_requested"
  }
}
```

### Step 4: Signal Workers to Stop (if parallel execution)

If `.message-bus/worker-status.json` shows active workers:
1. Write a `PAUSE_REQUESTED` event to the message bus
2. Workers should complete their current task but not pick up new ones
3. Report how many workers were signaled

### Step 5: Update tracks.md

Update the track's status in `conductor/tracks.md` to `paused`.

### Step 6: Report to User

```
-- ORCHESTRATION PAUSED ---------------------------------------

Track:    [track-id]
Paused at: EXECUTE (Phase 2, task 2.3)
Progress: 6/12 tasks complete

What was preserved:
  - Current step: EXECUTE
  - Task progress: All completed work saved
  - Fix cycles: 0/3

To resume:
  /conductor:run          Resume from where you left off
  /conductor:status       See full status before resuming

To abandon:
  Edit metadata.json and set status to "abandoned"
```

## Pause Reasons

The pause can be triggered for different reasons:

| Reason | Source | Description |
|--------|--------|-------------|
| `user_requested` | User runs `/conductor:pause` | Manual pause |
| `fix_cycle_exhausted` | Automatic | 3 fix cycles without passing |
| `blocker_detected` | Automatic | External dependency blocking progress |
| `escalation_required` | Automatic | Decision requires user input |

## Resumption Protocol

When `/conductor:run` is invoked on a paused track:
1. Read `previous_step` and `previous_step_status` from metadata
2. Restore `current_step` to `previous_step`
3. Set `status` back to `active`
4. Continue the evaluate-loop from the restored state
5. Clear the `paused_at` and `paused_reason` fields

## Related

- `/conductor:run` — Resume a paused orchestration
- `/conductor:status` — Check status of paused tracks
- `/conductor:logs` — See what happened before the pause
- `/gilfoyle` — Will detect paused tracks and offer to resume
