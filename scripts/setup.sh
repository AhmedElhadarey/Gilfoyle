#!/bin/bash
# Conductor Superpowers — Project Initialization Script
# Usage: bash ~/.claude/plugins/conductor-orchestrator-superpowers/scripts/setup.sh [project-dir]
#
# Creates the conductor/ directory structure in your project.

set -euo pipefail

PROJECT_DIR="${1:-.}"

# Prevent double-init: check if we're already inside a conductor/ directory
if [ -d "$PROJECT_DIR/conductor/tracks" ] && [ -f "$PROJECT_DIR/conductor/tracks.md" ]; then
  echo "⚠  Conductor is already initialized in: $PROJECT_DIR/conductor"
  echo "   To reinitialize, remove the conductor/ directory first."
  exit 0
fi

# Check if git is initialized (warn but don't block)
if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "⚠  Warning: No git repository detected in $PROJECT_DIR"
  echo "   Conductor works best with git. Run 'git init' when ready."
  echo ""
fi

echo "Initializing Conductor in: $PROJECT_DIR"

# Create directory structure
mkdir -p "$PROJECT_DIR/conductor/tracks"
mkdir -p "$PROJECT_DIR/conductor/knowledge"

# Create tracks.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/conductor/tracks.md" ]; then
  cat > "$PROJECT_DIR/conductor/tracks.md" << 'TRACKS_EOF'
# Track Registry

## Active Tracks

| Track ID | Name | Status | Priority | Started |
|----------|------|--------|----------|---------|
| — | — | — | — | — |

## Completed Tracks

| Track ID | Name | Completed | Summary |
|----------|------|-----------|---------|
| — | — | — | — |

---

*Updated by Conductor orchestrator. Do not edit manually.*
TRACKS_EOF
  echo "  Created conductor/tracks.md"
fi

# Create decision-log.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/conductor/decision-log.md" ]; then
  cat > "$PROJECT_DIR/conductor/decision-log.md" << 'DECISION_EOF'
# Decision Log

All product, pricing, architecture, and model decisions are logged here for audit trail and business document synchronization.

## Decisions

| Date | Track | Decision | Category | Impact | Logged By |
|------|-------|----------|----------|--------|-----------|
| — | — | — | — | — | — |

---

*Entries added automatically by business-docs-sync and lead consultations.*
DECISION_EOF
  echo "  Created conductor/decision-log.md"
fi

# Create knowledge/patterns.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/conductor/knowledge/patterns.md" ]; then
  cat > "$PROJECT_DIR/conductor/knowledge/patterns.md" << 'PATTERNS_EOF'
# Project Knowledge — Patterns & Conventions

This file captures learned patterns, conventions, and best practices discovered during development. Updated by the Knowledge Manager and Retrospective Agent.

## Architecture Patterns

*No patterns recorded yet.*

## Code Conventions

*No conventions recorded yet.*

## Common Pitfalls

*No pitfalls recorded yet.*

---

*Updated automatically by Conductor knowledge agents.*
PATTERNS_EOF
  echo "  Created conductor/knowledge/patterns.md"
fi

# Create knowledge/errors.json if it doesn't exist
if [ ! -f "$PROJECT_DIR/conductor/knowledge/errors.json" ]; then
  cat > "$PROJECT_DIR/conductor/knowledge/errors.json" << 'ERRORS_EOF'
{ "errors": [] }
ERRORS_EOF
  echo "  Created conductor/knowledge/errors.json"
fi

# Copy workflow docs if they don't exist
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$PROJECT_DIR/conductor/workflow.md" ]; then
  if [ -f "$PLUGIN_DIR/docs/workflow.md" ]; then
    cp "$PLUGIN_DIR/docs/workflow.md" "$PROJECT_DIR/conductor/workflow.md"
    echo "  Copied conductor/workflow.md"
  fi
fi

if [ ! -f "$PROJECT_DIR/conductor/authority-matrix.md" ]; then
  if [ -f "$PLUGIN_DIR/docs/authority-matrix.md" ]; then
    cp "$PLUGIN_DIR/docs/authority-matrix.md" "$PROJECT_DIR/conductor/authority-matrix.md"
    echo "  Copied conductor/authority-matrix.md"
  fi
fi

echo ""
echo "================================================"
echo "  Conductor initialized successfully!"
echo "================================================"
echo ""
echo "Your project now has the conductor/ directory structure."
echo ""
echo "Command Reference (3-tier system):"
echo ""
echo "  Tier 1 — Quick Actions:"
echo "    /gilfoyle <goal>              Start working toward a goal"
echo "    /conductor status       See current state"
echo ""
echo "  Tier 2 — Track Management:"
echo "    /conductor new-track    Create a track manually"
echo "    /conductor sync-docs    Sync business documents"
echo ""
echo "  Tier 3 — Advanced:"
echo "    /conductor evaluate     Run evaluation loop"
echo "    /conductor retrospective Run retrospective"
echo ""
echo "Get started: /gilfoyle <your goal>"
