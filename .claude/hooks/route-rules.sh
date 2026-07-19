#!/usr/bin/env bash
# UserPromptSubmit hook
#
# Progressive disclosure: instead of loading every rule into every session, this
# matches the prompt against keywords and tells Claude which rule files to read.
#
# It emits POINTERS, not content. Injecting whole rule files would recreate the
# problem it exists to solve — and the hook output cap (~10k chars) would truncate
# them anyway, which is worse than not loading them.
#
# stdout from UserPromptSubmit is added to Claude's context.
#
# Requires: bun (or jq/node as fallback) — see _lib.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

input=$(cat)
prompt=$(json_field "$input" "prompt" | tr '[:upper:]' '[:lower:]')

[ -z "$prompt" ] && exit 0

matched=()
add() { matched+=("$1"); }

match() { printf '%s' "$prompt" | grep -qE "$1"; }

match 'commit|branch|pull request| pr |rebase|merge|squash|cherry-pick'  && add ".claude/rules/git.md"
match 'test|spec|tdd|coverage|mock|assert|failing'                       && add ".claude/rules/testing.md"
match 'auth|secret|token|password|credential|\.env|permission|vulnerab|cve|injection' \
                                                                          && add ".claude/rules/security.md"
match 'error|exception|throw|catch|validat|schema|zod|parse'             && add ".claude/rules/errors-and-validation.md"
match 'refactor|rename|naming|structure|abstract|module|boundary'        && add ".claude/rules/code-style.md"
match 'doc|readme|adr|comment|explain why|architecture decision'         && add ".claude/rules/documentation.md"
match 'install|add.*(package|dep|librar)|which (library|package|tool)'   && add "tech-stack.yaml"
match 'feature|implement|build|spec|slice'                               && add "SPEC-WORKFLOW.md"
match 'adr|architecture decision|decide|tradeoff'                        && add ".claude/skills/to-adr/SKILL.md"
match 'spec|slice plan|blast radius|plan the'                            && add ".claude/skills/to-spec/SKILL.md"
match 'implement|continue working|resume|next slice|red.?green|tdd'      && add ".claude/skills/implement/SKILL.md"
match 'agent|subagent|delegate|parallel|hand off|handoff|which model|opus|sonnet|haiku' \
                                                                          && add ".claude/agents.md"

[ ${#matched[@]} -eq 0 ] && exit 0

# Deduplicate while preserving order
unique=$(printf '%s\n' "${matched[@]}" | awk '!seen[$0]++')

echo "Relevant project rules for this request — read any you have not already loaded this session:"
printf '%s\n' "$unique" | sed 's/^/  - /'
echo "(Hint only. If a rule applies and is not listed, read it anyway. core-principles.md always applies.)"

exit 0
