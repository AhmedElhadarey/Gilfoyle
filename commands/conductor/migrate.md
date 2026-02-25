---
name: migrate
description: "Migrate legacy tracks to v4 format"
user_invocable: true
---

# /conductor:migrate — Legacy Track Migration

Migrate tracks from v2/v3 format to v4. Updates metadata structure, enables superpower enhancements, and ensures compatibility with the current Conductor system.

## Usage

```bash
/conductor:migrate                    # Migrate all legacy tracks
/conductor:migrate my-track-id        # Migrate a specific track
```

## Your Task

### Step 1: Scan for Legacy Tracks

Read all track directories under `conductor/tracks/`:
1. Read each track's `metadata.json`
2. Check the `version` field
3. Identify tracks with `version` < 4

Report findings:
```
Scanning tracks...
  stripe-integration_20260225 — v4 (current, skip)
  auth-refactor_20260220 — v3 (needs migration)
  api-redesign_20260218 — v2 (needs migration)

Found 2 tracks to migrate.
```

### Step 2: Migrate Each Track

For each legacy track, apply the following transformations:

#### v2 to v4 Migration

v2 metadata is minimal:
```json
{
  "version": 2,
  "track_id": "api-redesign_20260218",
  "name": "API Redesign",
  "status": "active"
}
```

Transform to v4:
```json
{
  "version": 4,
  "track_id": "api-redesign_20260218",
  "name": "API Redesign",
  "type": "refactor",
  "status": "active",
  "superpower_enhanced": true,
  "created_at": "2026-02-18",
  "migrated_from": 2,
  "migrated_at": "2026-02-25T09:00:00Z",
  "loop_state": {
    "current_step": "NOT_STARTED",
    "step_status": "NOT_STARTED",
    "fix_cycle_count": 0,
    "step_history": []
  }
}
```

#### v3 to v4 Migration

v3 metadata already has most fields:
```json
{
  "version": 3,
  "track_id": "auth-refactor_20260220",
  "name": "Auth Refactor",
  "type": "refactor",
  "status": "active",
  "superpower_enhanced": true,
  "created_at": "2026-02-20",
  "loop_state": {
    "current_step": "EXECUTE",
    "step_status": "IN_PROGRESS",
    "fix_cycle_count": 0
  }
}
```

Transform to v4:
```json
{
  "version": 4,
  "track_id": "auth-refactor_20260220",
  "name": "Auth Refactor",
  "type": "refactor",
  "status": "active",
  "superpower_enhanced": true,
  "created_at": "2026-02-20",
  "migrated_from": 3,
  "migrated_at": "2026-02-25T09:00:00Z",
  "loop_state": {
    "current_step": "EXECUTE",
    "step_status": "IN_PROGRESS",
    "fix_cycle_count": 0,
    "step_history": []
  }
}
```

### Step 3: Infer Missing Fields

When migrating from v2, some fields need to be inferred:

| Field | Inference Rule |
|-------|---------------|
| `type` | Scan `spec.md` for keywords: "fix" = bugfix, "refactor" = refactor, "deploy/CI" = infrastructure, default = feature |
| `superpower_enhanced` | Always set to `true` (v4 default) |
| `created_at` | Extract date from track ID suffix (e.g., `_20260218` = 2026-02-18) or use file creation date |
| `loop_state.current_step` | Infer from plan.md: no plan = NOT_STARTED, has plan with `[ ]` = EXECUTE, all `[x]` = EVALUATE_EXECUTION |
| `loop_state.step_status` | Set to NOT_STARTED if step changed, preserve if only version bumped |

### Step 4: Normalize Step Names

Standardize any legacy step names:
- `PARALLEL_EXECUTE` -> `EXECUTE`
- `EVAL_PLAN` -> `EVALUATE_PLAN`
- `EVAL_EXECUTION` -> `EVALUATE_EXECUTION`
- `DONE` -> `COMPLETE`

### Step 5: Update tracks.md

Ensure `conductor/tracks.md` entries match the migrated metadata.

### Step 6: Create Backup

Before modifying any file, create a backup:
```
conductor/tracks/{track_id}/metadata.json.v{old_version}.bak
```

## Output Format

```
-- CONDUCTOR MIGRATION ----------------------------------------

Migrated 2 tracks to v4:

  auth-refactor_20260220 (v3 -> v4)
    [ok] Version updated
    [ok] step_history array added
    [ok] migrated_from/migrated_at recorded
    [ok] Backup: metadata.json.v3.bak

  api-redesign_20260218 (v2 -> v4)
    [ok] Version updated
    [ok] Type inferred: refactor (from spec.md keywords)
    [ok] superpower_enhanced: true
    [ok] loop_state reconstructed from plan.md
    [ok] Step name normalized: PARALLEL_EXECUTE -> EXECUTE
    [ok] Backup: metadata.json.v2.bak

All tracks are now v4 compatible.
Run /conductor:health to verify.
```

## Safety

- **Non-destructive**: Original metadata is backed up before modification
- **Idempotent**: Running migrate on already-v4 tracks is a no-op
- **Preserves state**: Current step and progress are maintained through migration
- **Reversible**: Backup files allow manual rollback if needed

## Related

- `/conductor:health` — Verify tracks after migration
- `/conductor:status` — Check migrated track status
- `/conductor:setup` — Initialize a fresh Conductor environment
- `/conductor:run` — Run migrated tracks through the evaluate-loop
