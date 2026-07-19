#!/usr/bin/env bash
# Installs the git-side half of the freshness enforcement.
#
# Two layers, deliberately:
#   - Claude Code hooks catch drift while an agent works (advisory, fast feedback)
#   - This git hook catches it at the commit boundary (blocking, tool-agnostic)
#
# The second layer matters because not every commit comes from an agent. A human
# renaming a folder in an editor bypasses every Claude Code hook in the repo.
#
# Run automatically via `bun install` (prepare script), or manually:
#   bash .claude/hooks/install-git-hooks.sh

set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Not a git repository — skipping git hook install."
  exit 0
}

hook_dir="$root/.git/hooks"
mkdir -p "$hook_dir"

cat > "$hook_dir/pre-commit" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"

# 1. Refuse staged secrets outright.
staged=$(git diff --cached --name-only --diff-filter=ACM)
for f in $staged; do
  case "$(basename "$f")" in
    .env.example) ;;
    .env|.env.*|*.pem|*.key|id_rsa|id_ed25519)
      echo "pre-commit: refusing to commit '$f' — secrets must never enter git history." >&2
      echo "Unstage it: git restore --staged '$f'" >&2
      exit 1
      ;;
  esac
done

# 2. Refuse the wrong package manager's lockfile.
for f in $staged; do
  case "$(basename "$f")" in
    package-lock.json|yarn.lock|pnpm-lock.yaml)
      echo "pre-commit: '$f' — this repo uses Bun. Delete it and run 'bun install'." >&2
      exit 1
      ;;
  esac
done

# 3. Regenerate docs and fail if they were stale.
if [ -f "$root/.claude/hooks/sync-docs.sh" ]; then
  bash "$root/.claude/hooks/sync-docs.sh" >/dev/null
  if ! git diff --quiet -- "$root/CLAUDE.md"; then
    git add "$root/CLAUDE.md"
    echo "pre-commit: CLAUDE.md was stale — regenerated and staged it."
  fi
fi
HOOK

chmod +x "$hook_dir/pre-commit"
echo "Installed pre-commit hook."
