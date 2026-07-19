#!/usr/bin/env bash
# PreToolUse hook (matcher: Write|Edit|Read)
#
# Hard-blocks paths that must never be read or written by an agent.
# Exit 2 = block the tool call; stderr is fed back to Claude as the reason.
#
# This exists because prose prohibitions are advisory and hooks are not. "Never read
# .env" in CLAUDE.md is a request the model may reinterpret under pressure. This is a
# wall.
#
# Requires: bun (or jq/node as fallback) — see _lib.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

input=$(cat)
path=$(json_field "$input" "tool_input.file_path")
[ -z "$path" ] && path=$(json_field "$input" "tool_input.path")
tool=$(json_field "$input" "tool_name")

[ -z "$path" ] && exit 0

base=$(basename "$path")

deny() {
  echo "BLOCKED: $1" >&2
  echo "Path: $path" >&2
  exit 2
}

# --- Secrets: never read, never write --------------------------------------
case "$base" in
  .env|.env.*)
    [ "$base" = ".env.example" ] && exit 0
    deny "Environment files hold secrets. Ask the user for the value you need, or read .env.example for key names only."
    ;;
  *.pem|*.key|*.p12|*.pfx|id_rsa|id_ed25519|*.jks)
    deny "Private key material. Never read or modify."
    ;;
  credentials|credentials.json|service-account*.json)
    deny "Credential file. Never read or modify."
    ;;
esac

# --- Everything below is write-only concern --------------------------------
[ "$tool" = "Read" ] && exit 0

# Lockfiles: regenerate, never hand-edit
case "$base" in
  bun.lock|bun.lockb)
    deny "Lockfiles are generated. Run 'bun install' instead of editing."
    ;;
  package-lock.json|yarn.lock|pnpm-lock.yaml)
    deny "Wrong package manager. This repo uses Bun — see tech-stack.yaml."
    ;;
esac

# Generated artifacts: change the generator, not the output
case "$path" in
  */node_modules/*|*/.next/*|*/dist/*|*/build/*|*/.turbo/*)
    deny "Build artifact or dependency. Not a source file."
    ;;
  */generated/*|*/__generated__/*|*.generated.*)
    deny "Generated file. Change the generator, then regenerate."
    ;;
  */prisma/migrations/*)
    deny "Applied migrations are immutable. Create a new migration with 'prisma migrate'."
    ;;
esac

exit 0
