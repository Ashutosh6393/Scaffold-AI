#!/usr/bin/env bash
# Regenerates every GENERATED block in the repo's docs from the filesystem.
#
#   bun run docs:sync          rewrite the blocks
#   bun run docs:check         fail if rewriting would change anything (CI)
#
# This is the mechanism that makes "docs don't go stale" true rather than aspirational.
# Prose reminders decay; a CI check does not.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

CHECK_MODE=false
[ "${1:-}" = "--check" ] && CHECK_MODE=true

# replace_block <file> <block-name> <content-file>
replace_block() {
  local file="$1" name="$2" content="$3"
  [ -f "$file" ] || return 0
  grep -q "BEGIN GENERATED: $name" "$file" || return 0

  awk -v name="$name" -v cf="$content" '
    $0 ~ "BEGIN GENERATED: " name {print; while ((getline line < cf) > 0) print line; skip=1; next}
    $0 ~ "END GENERATED: " name {skip=0}
    !skip {print}
  ' "$file" > "$file.tmp"

  mv "$file.tmp" "$file"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- workspaces -------------------------------------------------------------
{
  echo '```'
  for group in apps packages; do
    [ -d "$group" ] || continue
    echo "$group/"
    for d in "$group"/*/; do
      [ -d "$d" ] || continue
      n=$(basename "$d")
      desc=""
      if [ -f "$d/package.json" ]; then
        desc=$(json_field "$(cat "$d/package.json")" "description" || true)
      fi
      if [ -n "$desc" ]; then
        printf '  %-12s # %s\n' "$n/" "$desc"
      else
        printf '  %s\n' "$n/"
      fi
    done
  done
  echo '```'
} > "$tmp/workspaces"

# --- rules index ------------------------------------------------------------
{
  echo '| Rule | Load when |'
  echo '|---|---|'
  for f in .claude/rules/*.md; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    [ "$b" = "README.md" ] && continue
    when=$(awk -F': ' '/^load_when:/{sub(/^load_when: /,""); print; exit}' "$f")
    [ -z "$when" ] && when="—"
    echo "| [$b](.claude/rules/$b) | $when |"
  done
} > "$tmp/rules"

# --- active specs -----------------------------------------------------------
{
  if [ -d specs ] && ls -d specs/*/ >/dev/null 2>&1; then
    echo '| Spec | Status |'
    echo '|---|---|'
    for d in specs/*/; do
      n=$(basename "$d")
      [ "$n" = "_templates" ] && continue
      st="unknown"
      [ -f "$d/implementation.md" ] && st=$(awk -F': ' '/^- \*\*Status:\*\*|^## Status:/{print $2; exit}' "$d/implementation.md" | tr -d '*' | xargs || echo unknown)
      echo "| [$n](specs/$n/) | ${st:-unknown} |"
    done
  else
    echo '_No active specs._'
  fi
} > "$tmp/specs"

for target in CLAUDE.md; do
  replace_block "$target" workspaces "$tmp/workspaces"
  replace_block "$target" rules      "$tmp/rules"
  replace_block "$target" specs      "$tmp/specs"
done

if $CHECK_MODE; then
  if ! git diff --quiet -- CLAUDE.md; then
    echo "ERROR: documentation is stale." >&2
    echo "Run 'bun run docs:sync' and commit the result." >&2
    git --no-pager diff -- CLAUDE.md >&2
    exit 1
  fi
  echo "Docs are in sync."
else
  echo "Docs synced."
fi
