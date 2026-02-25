---
name: gilfoyle
description: "The single entry point to the Conductor system - state your goal and everything is handled via a 3-phase flow: Analyze, Propose, Execute. Supports resume mode, interactive planning, and flags for plan-only, dry-run, and autonomous execution."
arguments:
  - name: goal
    description: "Your goal — what you want to build, fix, or change"
    required: false
  - name: flags
    description: "Optional flags: --plan-only, --dry-run, --autonomous, --track <id>, -i (interactive)"
    required: false
user_invocable: true
---

# /gilfoyle — Goal-Driven Entry Point (v4)

**The single entry point to the entire Conductor system.**

State your goal. The system analyzes it, proposes a plan, and executes — with your confirmation at every step.

## Usage

```
/gilfoyle <your goal>                     # One-shot: Analyze -> Propose -> Execute
/gilfoyle                                 # Resume: show active tracks, pick one
/gilfoyle -i                              # Interactive: batch multiple goals
/gilfoyle <goal> --plan-only              # Analyze + Propose only, no execution
/gilfoyle <goal> --dry-run                # Simulate execution without writing files
/gilfoyle <goal> --autonomous             # Skip confirmation, fully automated
/gilfoyle --track <id>                    # Resume a specific track by ID
```

## Examples

```
/gilfoyle Add Stripe payment integration
/gilfoyle Fix the login bug where users get logged out
/gilfoyle Build a dashboard with analytics
/gilfoyle Refactor the API layer to use caching
/gilfoyle -i
/gilfoyle --track stripe-payment-integration_20260225
/gilfoyle Add OAuth login --plan-only
/gilfoyle Add unit tests for auth module --autonomous
```

## Your Task

You ARE the `/gilfoyle` entry point. When invoked, follow the instructions in the `/gilfoyle` skill file at `.claude/skills/gilfoyle/SKILL.md`. That skill contains the complete 3-phase flow (Analyze, Propose, Execute), resume mode, interactive mode, goal clarification, escalation decision cards, and all flag handling.

Parse `$ARGUMENTS` to determine which mode to enter:

1. **No arguments** -> Resume Mode (show active tracks)
2. **`-i` or `--plan` flag** -> Interactive Mode (multi-goal batching)
3. **`--track <id>` flag** -> Resume specific track
4. **Goal text provided** -> One-Shot Mode (3-phase flow)

Then follow the skill instructions precisely.

## Flags Reference

| Flag | Behavior |
|------|----------|
| `--plan-only` | Run Phases 1-2 only. Show spec + plan, do not execute |
| `--dry-run` | Simulate Phase 3 without writing files or commits |
| `--autonomous` | Skip Phase 2 confirmation, run fully automated |
| `--track <id>` | Resume a specific track by ID |
| `-i`, `--plan` | Interactive mode: batch multiple goals with dependency analysis |

## Related

- `/conductor status` — Check current track progress
- `/conductor run` — Run Evaluate-Loop on existing track
- `/conductor setup` — Initialize project for Conductor
- `/brainstorm` — Think before building
