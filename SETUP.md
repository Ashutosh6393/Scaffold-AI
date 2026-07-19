# Scaffold Setup

Detailed install and customization notes. For the overview, file-by-file reference, and
quick start, see [README.md](README.md).

Delete both files once the project is running — they're scaffold docs, not project docs.

## Install

```bash
# 1. Copy everything into the repo root
cp -r scaffold/. your-project/

# 2. AGENTS.md as a symlink to CLAUDE.md — one source of truth, every tool finds it
cd your-project
ln -s CLAUDE.md AGENTS.md
git add AGENTS.md

# 3. Make hooks executable and install the git hook
chmod +x .claude/hooks/*.sh
bash .claude/hooks/install-git-hooks.sh

# 4. Generate the derived blocks
bun run docs:sync
```

The symlink matters more than it looks: Cursor, Codex, Copilot, and Claude Code each look
for a different filename. A symlink means one file, no drift. Copies drift within a week.

Then fill in `CONTEXT.md` (the only file that's empty by design) and trim `tech-stack.yaml`
to what this project actually uses.

## Layout

```
CLAUDE.md            entry point — index + generated blocks
AGENTS.md            symlink → CLAUDE.md
CONTEXT.md           what we're building (fill this in)
tech-stack.yaml      approved menu; ask before adding anything not listed
SPEC-WORKFLOW.md     how features get built
.claude/
  settings.json      hook wiring
  agents.md          roster: which agent, which model, when
  agents/            subagent definitions (7)
  skills/            build pipeline: to-adr -> to-spec -> implement
  rules/             loaded on demand, not upfront
  hooks/             the enforcement layer
docs/adr/            architecture decisions
specs/               active feature specs + templates
```

## How staleness is actually prevented

Three layers, because prose alone never works:

**1. Don't write down what goes stale.** Detailed folder structures, file inventories, and
API surfaces are not documented anywhere. `documentation.md` calls this Tier 3. The rule
is: *if code changes would make it false and nothing would catch that, don't write it.*

**2. Generate what can be derived.** Workspace lists, the rules index, and the spec index
live between `<!-- BEGIN GENERATED: x -->` markers and are rewritten by `bun run docs:sync`.

**3. Enforce at three points.** A Claude Code `PostToolUse` hook nudges during a session;
the git `pre-commit` hook regenerates and stages at commit time; CI runs `bun run docs:check`
and fails on drift.

Layer 3 needs all three because they catch different misses. The Claude hook misses humans
editing in an IDE. The git hook misses anyone using `--no-verify`. CI catches everything
but only after a push.

Add to CI:

```yaml
- run: bun run docs:check
```

## How rules stay out of context until needed

`CLAUDE.md` lists rule files with a one-line trigger and does **not** inline them. The
`UserPromptSubmit` hook matches prompt keywords and injects *pointers* — filenames, not
contents. Injecting the files themselves would recreate the problem and hit the ~10k char
hook output cap anyway.

Net effect: a session that never touches auth never loads `security.md`.

## The build pipeline

Three skills, three human gates:

```
discussion / issue  --to-adr-->  docs/adr/NNN-name.md   [gate: accept the decision]
                    --to-spec--> specs/NNN-name/        [gate: approve the slice plan]
                    --implement-> code, one slice       [gate: review the slice]
                                                        --> PR --> reviewer agent in CI
```

`to-adr` synthesizes an existing design discussion. If you point it at a bare issue with
no discussion behind it, it runs the `grilling` skill first rather than inventing a
rationale.

Each phase refuses to start without its input: no spec without an accepted ADR, no
implementation without an approved slice plan.

## Model tiering

Agents are pinned per tier in `.claude/agents/*.md` — `haiku` for mechanical work,
`sonnet` for the TDD loop, `opus` for planning and review. The reasoning is in
`.claude/agents.md`; the short version is that the loop is where token volume lives, so
the expensive model goes on the one-shot, high-consequence steps instead.

Two things that will bite you:

- **`CLAUDE_CODE_SUBAGENT_MODEL` beats every `model:` field.** If it's exported, the whole
  tiering scheme is silently ignored. Check it first when an agent runs on the wrong tier.
- **Restart after first install.** Claude Code's file watcher only covers directories that
  existed when the session started, so the first time `.claude/agents/` appears you need a
  restart before the definitions load.

## Requirements

Hooks need **Bun** (already required by the stack). They fall back to `jq` or `node` if
Bun is somehow absent — see `.claude/hooks/_lib.sh`. Nothing depends on `jq` being
installed.

## Verify it works

```bash
# Should print a BLOCKED message and exit 2
echo '{"tool_name":"Edit","tool_input":{"file_path":".env"}}' | .claude/hooks/guard-paths.sh

# Should list git.md and testing.md
echo '{"prompt":"write a test and commit it"}' | .claude/hooks/route-rules.sh

# Should exit 0 on a clean tree
bun run docs:check
```

## Per-project customization

| File | What to change |
|---|---|
| `CONTEXT.md` | Everything — it's a blank template |
| `tech-stack.yaml` | Delete unused sections; move `undecided` items up as you choose them |
| `.claude/rules/*.md` | Add project-specific rules; keep each under ~150 lines |
| `.claude/hooks/route-rules.sh` | Add keyword triggers for new rules |
| `CLAUDE.md` | Only the hand-written sections — never the GENERATED blocks |

## One caveat

Claude Code's hook event names and JSON schema evolve. If a hook stops firing, check the
current reference at <https://code.claude.com/docs/en/hooks> before debugging the script —
the event set has been expanding, and `.claude/settings.json` is the first place a rename
would break.