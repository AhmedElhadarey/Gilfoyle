---
name: help
description: "Show all available Conductor commands organized by category"
user_invocable: true
---

# /conductor:help — Command Reference

Display all available Conductor commands organized by usage tier, from essential to specialized.

## Usage

```bash
/conductor:help
```

## Your Task

Display the following command reference to the user:

```
-- CONDUCTOR COMMANDS -----------------------------------------

  Tip: Most users only need /gilfoyle. It handles everything.

PRIMARY (what 90% of users need):

  /gilfoyle [goal]        Start or resume work. The main entry point.
  /conductor:status       See where things stand — timeline, progress, next action.
  /brainstorm             Think before building — explore ideas with AI advisors.

POWER USER:

  Orchestration:
    /conductor:setup        Initialize Conductor in a new project
    /conductor:new-track    Create a new development track manually
    /conductor:run          Run the Evaluate-Loop from current state to completion
    /conductor:pause        Gracefully pause an in-flight orchestration
    /conductor:health       Validate installation and project state
    /conductor:logs [track] View human-readable message bus history
    /conductor:help         Show this command reference
    /conductor:migrate      Migrate legacy tracks to v4 format

  Reviews & Quality:
    /conductor:review       Post-execution quality gate (replaces /phase-review)
    /conductor:tech-review  CTO-level architecture review (replaces /cto-advisor)
    /board-meeting          Full Board of Directors deliberation
    /board-review           Quick board assessment
    /ui-audit               UI/UX validation

  Standalone:
    /write-plan             Create a plan outside of a track
    /execute-plan           Execute a standalone plan

ADVISORY (consult specialized AI advisors):

    /ceo                    Business strategy consultation
    /cmo                    Marketing and growth consultation
    /cto                    Technical architecture consultation
    /ux-designer            Design and usability consultation

DEPRECATED (still work, will be removed):

    /phase-review           Use /conductor:review instead
    /cto-advisor            Use /conductor:tech-review instead

---

Quick Start:
  /gilfoyle Add user authentication      # Full automated workflow
  /gilfoyle                              # Resume active work
  /gilfoyle --plan-only Fix login bug    # Plan without executing
  /conductor:status                # Check progress anytime
```

## Display Rules

1. Always show the tip about `/gilfoyle` prominently at the top
2. Group commands by tier with clear headers
3. Include the one-line description for each command
4. Show deprecated commands with their replacement
5. Include the Quick Start section with practical examples

## Related

- `/gilfoyle` — Main entry point for all work
- `/conductor:status` — Current project status
- `/conductor:health` — Validate installation
