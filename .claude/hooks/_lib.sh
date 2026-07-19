#!/usr/bin/env bash
# Shared helpers for hooks. Sourced, not executed.
#
# Parses JSON with whatever is available, preferring Bun — which is guaranteed in this
# stack — over jq, which is not. Hooks that hard-depend on jq fail silently on a fresh
# machine, and a security hook that fails open is worse than no hook.

# json_field <json-string> <dot.path> -> value on stdout, empty if absent
json_field() {
  local json="$1" path="$2"

  if command -v bun >/dev/null 2>&1; then
    printf '%s' "$json" | bun -e '
      const path = process.argv[2].split(".");
      let v;
      try { v = JSON.parse(await Bun.stdin.text()); } catch { process.exit(0); }
      for (const k of path) { v = v?.[k]; if (v == null) { process.exit(0); } }
      process.stdout.write(String(v));
    ' -- "$path" 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg p "$path" 'getpath($p | split(".")) // empty' 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$json" | node -e '
      let s=""; process.stdin.on("data",d=>s+=d).on("end",()=>{
        let v; try { v = JSON.parse(s); } catch { return; }
        for (const k of process.argv[1].split(".")) { v = v?.[k]; if (v == null) return; }
        process.stdout.write(String(v));
      });
    ' "$path" 2>/dev/null
  fi
}

# json_emit_context <text> -> PostToolUse additionalContext payload
json_emit_context() {
  local event="$1" text="$2"
  if command -v bun >/dev/null 2>&1; then
    bun -e '
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: process.argv[2],
          additionalContext: process.argv[3],
        },
      }));
    ' -- "$event" "$text"
  else
    # Minimal hand-rolled fallback; escape the characters that matter.
    local esc=${text//\\/\\\\}
    esc=${esc//\"/\\\"}
    esc=${esc//$'\n'/\\n}
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}' "$event" "$esc"
  fi
}
