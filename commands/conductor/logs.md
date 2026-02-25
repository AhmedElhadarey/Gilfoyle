---
name: logs
description: "Show human-readable message bus history for a track"
arguments:
  - name: track_id
    description: "Track ID to show logs for (defaults to active track)"
    required: false
user_invocable: true
---

# /conductor:logs — Message Bus History

Display a human-readable, chronological view of all message bus events for a track. Useful for debugging, understanding what happened, and auditing the orchestration flow.

## Usage

```bash
/conductor:logs
/conductor:logs my-track-id
/conductor:logs --last 20
```

## Your Task

### Step 1: Identify Track

If a track ID is provided, use it. Otherwise:
1. Find the active track from `conductor/tracks.md` and metadata files
2. If no active track, prompt the user for a track ID

### Step 2: Read Message Bus Data

Read `.message-bus/queue.jsonl` and filter events for the target track.

Each line in `queue.jsonl` is a JSON object with:
```json
{
  "timestamp": "2026-02-25T09:14:32Z",
  "event_type": "PLAN_COMPLETE",
  "track_id": "stripe-integration_20260225",
  "source": "loop-planner",
  "data": { ... },
  "result": "PASS"
}
```

### Step 3: Read Event Files

Also scan `.message-bus/events/` for event files matching the track:
- `PLAN_COMPLETE_{track_id}.event`
- `PLAN_EVAL_COMPLETE_{track_id}.event`
- `EXECUTE_COMPLETE_{track_id}.event`
- `EXEC_EVAL_COMPLETE_{track_id}.event`
- `FIX_COMPLETE_{track_id}.event`
- `TASK_COMPLETE_*.event`
- `TASK_FAILED_*.event`
- `PARALLEL_COMPLETE_{track_id}.event`
- `PAUSE_REQUESTED.event`

### Step 4: Build Chronological Timeline

Sort all events by timestamp and format as a readable log.

## Output Format

```
-- CONDUCTOR LOGS: stripe-integration_20260225 ----------------

2026-02-25 09:14:32  PLAN_COMPLETE
  Source: loop-planner
  Result: PASS
  Details: 12 tasks in 3 phases

2026-02-25 09:16:01  PLAN_EVAL_COMPLETE
  Source: loop-plan-evaluator
  Result: PASS
  Details: All 6 checks passed

2026-02-25 09:17:15  BOARD_REVIEW
  Source: board-meeting
  Result: APPROVED (4-1)
  Details: 3 conditions attached

2026-02-25 09:18:02  EXECUTE_START
  Source: parallel-dispatcher
  Details: 3 workers spawned for Phase 1

2026-02-25 09:19:44  TASK_COMPLETE (1.1)
  Source: task-worker-1.1
  Result: PASS
  Commit: abc1234
  Files: src/lib/stripe-client.ts

2026-02-25 09:20:12  TASK_COMPLETE (1.2)
  Source: task-worker-1.2
  Result: PASS
  Commit: def5678
  Files: src/config/stripe.ts

2026-02-25 09:21:30  TASK_FAILED (1.3)
  Source: task-worker-1.3
  Result: FAIL
  Error: Type error in webhook handler — missing Request type import

2026-02-25 09:22:00  TASK_COMPLETE (1.3) [retry]
  Source: task-worker-1.3
  Result: PASS
  Commit: ghi9012
  Files: src/api/webhooks/stripe.ts

--- 12 events shown ---
```

## Fallback: No Message Bus

If `.message-bus/` does not exist or has no events for this track:

```
-- CONDUCTOR LOGS: stripe-integration_20260225 ----------------

No message bus history found for this track.

Available information from metadata:
  Created: 2026-02-25
  Current step: EXECUTE
  Status: active
  Fix cycles: 0

Tip: Message bus events are recorded during orchestration.
     Run /conductor:run to generate events.
```

## Filtering Options

When `--last N` is provided, show only the most recent N events.

## Event Type Reference

| Event Type | Description |
|------------|-------------|
| `PLAN_COMPLETE` | Plan was created by planner agent |
| `PLAN_EVAL_COMPLETE` | Plan evaluation finished (PASS/FAIL) |
| `BOARD_REVIEW` | Board of Directors reviewed the plan |
| `CTO_REVIEW` | CTO advisor technical review |
| `EXECUTE_START` | Execution phase began |
| `TASK_COMPLETE` | Individual task completed |
| `TASK_FAILED` | Individual task failed |
| `EXECUTE_COMPLETE` | All execution tasks finished |
| `EXEC_EVAL_COMPLETE` | Execution evaluation finished (PASS/FAIL) |
| `FIX_COMPLETE` | Fix cycle completed |
| `PARALLEL_COMPLETE` | Parallel dispatch batch finished |
| `PAUSE_REQUESTED` | Orchestration pause was requested |
| `BUSINESS_DOC_SYNC` | Business document sync completed |

## Related

- `/conductor:status` — High-level status with timeline summary
- `/conductor:run` — Continue orchestration (generates events)
- `/conductor:health` — Check message bus integrity
- `/conductor:pause` — Pause and review logs before continuing
