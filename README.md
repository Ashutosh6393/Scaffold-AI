# AI-Driven Development Scaffold

Drop-in agent configuration for a **Bun + Turborepo** project.

Three ideas hold it together:

- **Docs that can't go stale** — anything derivable is generated and CI-checked
- **Rules that load only when needed** — `CLAUDE.md` is an index, not a manual
- **Boundaries enforced by hooks, not prose** — the agent writing code physically cannot edit tests

---

## The pipeline

```
 discussion / issue
        │
        ├─ to-adr ──────► docs/adr/002-name.md      ◄── gate: accept the decision
        │
        ├─ to-spec ─────► specs/002-name/           ◄── gate: approve the slice plan
        │
        └─ implement ───► code, one slice at a time ◄── gate: review the slice
                              │
                              └─► PR ─► reviewer agent in CI
```

Each phase refuses to start without its input. No spec without an accepted ADR. No code
without an approved slice plan.

---

## Quick start

```bash
cp -r scaffold/. your-project/
cd your-project

ln -s CLAUDE.md AGENTS.md          # one file, every tool finds it
chmod +x .claude/hooks/*.sh
bash .claude/hooks/install-git-hooks.sh
bun run docs:sync
```

Then:

1. Fill in `CONTEXT.md` — the only file that ships empty by design
2. Trim `tech-stack.yaml` to what this project actually uses
3. Restart Claude Code once, so `.claude/agents/` is picked up
4. Delete `README.md` and `SETUP.md`

Full install notes and customization: **[SETUP.md](SETUP.md)**

---

## Daily use

| You want to… | Say |
|---|---|
| Record a design decision | `to-adr` (after discussing, or pointing at an issue) |
| Plan a feature | `to-spec 002` |
| Build it | `implement feature-name` |
| Pick up where you left off | `implement feature-name` |

Between slices: review, merge, `/clear`, then `implement` again.

---

## Skills

`.claude/skills/` — the three pipeline phases.

| Skill | Does | Stops at |
|---|---|---|
| **to-adr** | Turns a design discussion into `docs/adr/{NNN}-{name}.md`. Synthesizes an existing conversation; runs the `grilling` skill first if you point it at a bare issue. Checks for an ADR to supersede. | You accepting the decision |
| **to-spec** | Turns an accepted ADR into `specs/{NNN}-{name}/`. Creates the branch, writes the slice plan with blast radius + acceptance criteria per slice. | You approving the slice plan |
| **implement** | Runs the red-green loop on one slice. Delegates RED to `test`, GREEN to `coder`, sign-off back to `test`. | The slice boundary |

---

## Agents

`.claude/agents/` — model tier follows the work, not the seniority of the name.

| Agent | Model | Owns | Never touches |
|---|---|---|---|
| **spec** | `opus` | `design.md`, `implementation.md` | source, tests |
| **reviewer** | `opus` | nothing — reports findings | everything (read-only) |
| **test** | `sonnet` | `*.test.ts` | source files |
| **coder** | `sonnet` | source files | **any test file** |
| **summary-writer** | `sonnet` | `summary.md` | source, tests |
| **explore** | `haiku` | nothing (read-only) | everything |
| **chore** | `haiku` | commands, doc regeneration | anything needing a decision |

**Why Opus sits on planning and review:** cost follows *volume*, not tier. `coder` and
`test` run on every task, several times. `spec` runs once per feature; `reviewer` runs once
per PR on a diff capped at 500 lines. Opus on review costs cents — Sonnet across forty loop
iterations doesn't.

Full rationale and gotchas: **[.claude/agents.md](.claude/agents.md)**

---

## Rules

`.claude/rules/` — read on demand, never all at once.

| Rule | Load when |
|---|---|
| **core-principles.md** | Always. Think before coding, simplicity, surgical changes, goal-driven execution |
| **git.md** | Branches, commit format, PR size limits, how to split large changes |
| **testing.md** | The TDD loop, attempt budget, test ownership |
| **code-style.md** | Naming, function design, layer discipline, no `as any` |
| **errors-and-validation.md** | Zod at every boundary, domain error types, one error shape |
| **security.md** | Secrets, auth vs authorization, input handling, dependency risk |
| **documentation.md** | The three-tier freshness contract, ADR format, module metadata |

---

## Hooks

`.claude/hooks/` — where the rules stop being advisory.

| Hook | Event | Does |
|---|---|---|
| **guard-paths.sh** | `PreToolUse` | **Blocks** reads/writes of `.env`, keys, lockfiles, generated files, applied migrations |
| **check-test-count.sh** | `Stop` | **Blocks** if the test count dropped during a slice — tests are append-only |
| **route-rules.sh** | `UserPromptSubmit` | Injects *pointers* to relevant rules based on prompt keywords |
| **check-freshness.sh** | `PostToolUse` | Flags docs made stale by a structural change |
| **sync-docs.sh** | `bun run docs:sync` | Regenerates `GENERATED` blocks from the filesystem |
| **install-git-hooks.sh** | `bun install` | Installs a `pre-commit` hook: refuses secrets, regenerates docs |
| **_lib.sh** | — | Shared JSON parsing (Bun → jq → node fallback) |

> **The one that matters most is `guard-paths.sh`.** "Never edit tests" in a prompt is a
> request a model can reinterpret at attempt three. A `PreToolUse` hook returning exit 2 is
> a wall.

---

## Root files

| File | Purpose |
|---|---|
| **CLAUDE.md** | Entry point. An index — stable facts, links, generated blocks |
| **AGENTS.md** | Symlink to `CLAUDE.md` for Cursor / Codex / Copilot |
| **CONTEXT.md** | What you're building, domain vocabulary, boundaries. **Fill this in** |
| **tech-stack.yaml** | The approved menu. Not listed? The agent asks instead of picking |
| **SPEC-WORKFLOW.md** | How features get built, agent ownership, PR slicing |
| **docs/adr/** | Architecture decisions. Append-only — supersede, never rewrite |
| **specs/** | Active feature specs + the four-file template |

---

## How docs stay fresh

Three tiers, decided by one question: **what makes this false, and would I notice?**

| Tier | Example | Kept true by |
|---|---|---|
| **Derived** | Workspace list, rules index | `bun run docs:sync` regenerates it |
| **Stable prose** | Principles, workflow | Fix it in the same commit that breaks it |
| **Not written down** | Folder trees, file inventories | Doesn't exist. Read the code |

Enforced at three points, because each misses different things:

- `PostToolUse` hook — during a session (misses humans in an IDE)
- `pre-commit` hook — at commit time (misses `--no-verify`)
- `bun run docs:check` in CI — catches everything, after the fact

Add to CI:

```yaml
- run: bun run docs:check
```

---

## Requirements

- **Bun** — runtime, package manager, test runner, and what the hooks use to parse JSON
- **Claude Code** — for skills, agents, and hooks
- Git

No `jq` dependency. Hooks fall back to `jq` or `node` if Bun is somehow missing.

---

## Verify it works

```bash
# Blocks, exit 2
echo '{"tool_name":"Edit","tool_input":{"file_path":".env"}}' | .claude/hooks/guard-paths.sh

# Lists git.md and testing.md
echo '{"prompt":"write a test and commit it"}' | .claude/hooks/route-rules.sh

# Exits 0 on a clean tree
bun run docs:check
```

---

## Customizing

| File | Change |
|---|---|
| `CONTEXT.md` | Everything — it's a blank template |
| `tech-stack.yaml` | Delete unused sections; promote `undecided` items as you choose them |
| `.claude/rules/*.md` | Add project rules. Keep each under ~150 lines |
| `.claude/hooks/route-rules.sh` | Add keyword triggers for new rules |
| `CLAUDE.md` | Hand-written sections only — **never** the `GENERATED` blocks |

---

## A caveat

Claude Code's hook events, subagent frontmatter, and model aliases change between versions.
If something stops firing, check the current reference before debugging the script:

- [Hooks](https://code.claude.com/docs/en/hooks)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Skills](https://code.claude.com/docs/en/skills)
