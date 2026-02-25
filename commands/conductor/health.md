---
name: health
description: "Validate Conductor installation and project state"
user_invocable: true
---

# /conductor:health — Installation & State Validator

Validates the Conductor plugin installation, project directory structure, configuration files, and overall system health. Use this to diagnose issues or verify a fresh setup.

## Usage

```bash
/conductor:health
```

## Your Task

Run through all health checks below and generate a comprehensive health report.

### Check 1: Directory Structure

Verify the `conductor/` directory exists and contains the expected structure:

```
conductor/
  tracks.md          [required]
  index.md           [required]
  workflow.md         [required]
  decision-log.md    [optional]
  knowledge/
    patterns.md      [required]
    errors.json      [required]
  tracks/            [required - directory]
```

For each item, report: FOUND / MISSING / EMPTY

### Check 2: Metadata Integrity

For each track in `conductor/tracks/`:
- Verify `metadata.json` exists and parses as valid JSON
- Check required fields: `version`, `track_id`, `name`, `type`, `status`, `loop_state`
- Check `loop_state` has: `current_step`, `step_status`, `fix_cycle_count`
- Validate `version` field (warn if < 4, suggest migration)
- Validate `status` is a known value: `new`, `active`, `in_progress`, `paused`, `complete`, `failed`, `blocked`

### Check 3: Plan File Integrity

For each track with a `plan.md`:
- Verify file is non-empty
- Check for task checkboxes (`- [ ]` or `- [x]`)
- Verify task count matches metadata expectations (if available)
- Check for orphaned evaluation reports (report exists but track is in wrong state)

### Check 4: Knowledge Base

- `conductor/knowledge/errors.json` — Parses as valid JSON, has `errors` array
- `conductor/knowledge/patterns.md` — File exists and is non-empty

### Check 5: Message Bus (if exists)

If `.message-bus/` directory exists:
- `queue.jsonl` — Each line parses as valid JSON
- `locks.json` — Parses as valid JSON, check for stale locks (older than 30 minutes)
- `worker-status.json` — Parses as valid JSON, check for stale workers
- `events/` — Directory exists

### Check 6: Skill & Command Frontmatter

Scan all `.md` files in the plugin's `commands/` and `skills/` directories:
- Verify each has valid YAML frontmatter (between `---` delimiters)
- Verify `name` field is present and non-empty
- Verify `description` field is present and non-empty
- Report any files with missing or broken frontmatter

### Check 7: Tracks Registry Consistency

Cross-reference `conductor/tracks.md` with actual track directories:
- Tracks listed in registry but missing from filesystem
- Track directories that exist but are not listed in registry
- Status mismatches between registry and metadata.json

### Check 8: Hook Registration

Check if the plugin's hooks are properly configured:
- Session start hook registered
- Post-commit hook registered (if applicable)
- Report any hook configuration issues

## Output Format

```
-- CONDUCTOR HEALTH -------------------------------------------

Installation: OK
  [pass] conductor/ directory structure
  [pass] knowledge base files
  [pass] workflow documentation
  [warn] errors.json is empty (no learned errors yet)

Tracks: 3 found (2 active, 1 complete)
  [pass] stripe-integration_20260225 — metadata valid, plan valid
  [pass] auth-refactor_20260220 — metadata valid, plan valid, complete
  [warn] api-redesign_20260218 — metadata version 2 (run /conductor:migrate)

Message Bus: OK
  [pass] queue.jsonl — 47 events, all valid
  [pass] No stale locks
  [warn] 1 stale worker entry (older than 30m)

Skills: OK
  [pass] 24/24 commands have valid frontmatter
  [pass] 12/12 skills have valid frontmatter

Registry: OK
  [pass] All tracks in registry match filesystem
  [pass] All track directories listed in registry

Overall: HEALTHY (2 warnings)

Recommendations:
  1. Run /conductor:migrate to update api-redesign track to v4
  2. Clear stale worker entry in .message-bus/worker-status.json
```

## Status Levels

| Level | Meaning |
|-------|---------|
| `[pass]` | Check passed, no issues |
| `[warn]` | Non-blocking issue, system works but should be addressed |
| `[fail]` | Blocking issue, system may not function correctly |
| `[skip]` | Check skipped (component not present or not applicable) |

## Overall Verdicts

| Verdict | Meaning |
|---------|---------|
| HEALTHY | All checks pass or only warnings |
| DEGRADED | Some failures but core functionality works |
| BROKEN | Critical failures, system will not function correctly |
| NOT INITIALIZED | No conductor/ directory found — suggest running /conductor:setup |

## Related

- `/conductor:setup` — Initialize Conductor environment
- `/conductor:migrate` — Migrate legacy tracks to v4 format
- `/conductor:status` — Show current track status
- `/conductor:help` — Show all available commands
