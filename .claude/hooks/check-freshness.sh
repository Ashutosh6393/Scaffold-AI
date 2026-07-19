#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit)
#
# The anti-staleness enforcer. Fires after a file is written and asks: did this change
# invalidate something a document claims?
#
# Non-blocking by design — it injects a reminder rather than rejecting the edit, because
# an edit mid-task is usually correct and the doc update belongs in the same commit, not
# the same keystroke.
#
# Requires: bun (or jq/node as fallback) — see _lib.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

input=$(cat)
path=$(json_field "$input" "tool_input.file_path")
[ -z "$path" ] && path=$(json_field "$input" "tool_input.path")
[ -z "$path" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
rel="${path#"$root"/}"

notes=()

# 1. Structural change -> generated blocks are now stale
case "$rel" in
  apps/*/package.json|packages/*/package.json|turbo.json|package.json)
    notes+=("Workspace layout changed. Run 'bun run docs:sync' to regenerate the GENERATED blocks in CLAUDE.md, and commit the result with this change.")
    ;;
esac

# 2. New or removed top-level app/package directory
if [ -d "$root/apps" ] && [ -d "$root/packages" ]; then
  case "$rel" in
    apps/*|packages/*)
      dir=$(printf '%s' "$rel" | cut -d/ -f1-2)
      if ! grep -q "$dir" "$root/CLAUDE.md" 2>/dev/null; then
        notes+=("'$dir' is not reflected in CLAUDE.md. If this is a new workspace, run 'bun run docs:sync'.")
      fi
      ;;
  esac
fi

# 3. Rules changed -> index is stale
case "$rel" in
  .claude/rules/*.md)
    notes+=("A rule file changed. Run 'bun run docs:sync' to refresh the rules index in CLAUDE.md.")
    ;;
esac

# 4. Tech stack changed -> needs an ADR
case "$rel" in
  tech-stack.yaml)
    notes+=("tech-stack.yaml changed. Adding or swapping a tool requires an ADR in docs/adr/ in the same PR.")
    ;;
esac

# 5. Editing a doc that hand-states structure — Tier 3 violation
case "$rel" in
  *.md)
    if grep -qE '^\s*(├──|└──|│)' "$path" 2>/dev/null; then
      if ! grep -q "BEGIN GENERATED" "$path" 2>/dev/null; then
        notes+=("This doc contains a hand-written folder tree outside a GENERATED block. Folder trees in prose go stale — see .claude/rules/documentation.md (Tier 3).")
      fi
    fi
    ;;
esac

[ ${#notes[@]} -eq 0 ] && exit 0

msg=$(printf '%s ' "${notes[@]}")
json_emit_context "PostToolUse" "Documentation freshness: $msg"

exit 0
