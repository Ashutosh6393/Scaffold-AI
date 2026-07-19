# Agent Roster

Which agent does what, which model it runs on, and when to hand off.

Definitions live in `.claude/agents/*.md`. This file is the map and the rationale.

---

## Model assignment

| Agent | Model | Effort | How often it runs | Why this tier |
|---|---|---|---|---|
| `explore` | `haiku` | — | Constantly | Grep, read, summarize. Pattern matching, not reasoning. Speed and cost dominate. |
| `spec` | `opus` | `extra` | Once per feature | Decomposition, dependency ordering, scope judgement. The highest-leverage reasoning in the pipeline. |
| `test` | `sonnet` | `medium` | Every task | Turning a spec line into assertions. Careful but bounded. |
| `coder` | `sonnet` | `medium` | Every task, 1–3× | Minimal code against one named failing test. The most-run agent, so the most cost-sensitive. |
| `summary-writer` | `sonnet` | — | Per PR slice | Prose from a diff. Writing quality matters; reasoning depth doesn't. |
| `reviewer` | `opus` | `high` | Per PR | Last automated gate before merge. Its input is capped at 500 lines by the PR rule, so Opus here is nearly free. |
| `chore` | `haiku` | `low` | Constantly | Running commands, regenerating docs, dep bumps, typos. Zero judgement required. |

Rough July 2026 API rates per million tokens — **Haiku 4.5** $1/$5 · **Sonnet 5** $3/$15
· **Opus 4.8** $5/$25 · **Fable 5** $10/$50. Verify before optimizing around them.

### The reasoning

**Cost follows volume, not tier.** The loop is where tokens go: `test` and `coder` run on
every task, several times, each carrying a full context window. `spec` runs once per
feature. `reviewer` runs once per PR against a diff your own rule caps at 500 lines.

That inverts the intuition that Opus is the expensive choice. Opus on a 500-line diff
costs cents. Sonnet across forty loop iterations costs real money. **Put the expensive
model where the thinking is and the cheap model where the volume is** — which happens to
be exactly where the thinking isn't.

**Where Opus earns its price:** deciding *what* to build, and *whether it's right*. Both
are one-shot, high-consequence, small-input. A bad spec wastes every downstream loop
iteration; a missed logic error in review ships. Neither is recoverable by retrying
harder.

**Where it doesn't:** writing code against a specific failing test. That task is already
fully specified — the test *is* the spec. The Opus/Sonnet gap on SWE-bench-style
benchmarks has been a point or two, well under the price difference, and a bounded task
with a pass/fail oracle is where that gap matters least.

**Never use Opus for:** running commands, regenerating docs, bumping dependencies,
formatting. There is no judgement in `bun run docs:sync`.

**Don't reach for `fable`.** Nothing here needs a Mythos-tier model, and it's 2× Opus.

### Prefer aliases to pinned IDs

Use `model: sonnet`, not `model: claude-sonnet-5`. Aliases follow the current generation;
pinned IDs quietly become the stale choice and nobody notices for six months. Pin only
when you need reproducibility for an eval.

### Escalate deliberately, not automatically

When `coder` exhausts its 3 attempts on Sonnet, it blocks and asks the human. It does
**not** auto-retry on Opus.

Automatic model escalation is tempting and wrong here: it converts a signal into a cost.
A blocked task usually means the test encodes a misunderstanding, or the task was scoped
too large — and Opus will happily paper over both by producing something that passes.
Silent escalation buries a design problem under a bigger model.

Re-running a blocked task on Opus is a fine *human* decision. It shouldn't be an automatic
one.

---

## Routing table

| You are about to… | Use | Don't use |
|---|---|---|
| Understand an unfamiliar area of the codebase | `explore` | `coder` — it'll start editing |
| Turn an accepted ADR into a spec | `spec` | `coder` — code before a plan is how scope creeps |
| Write a failing test for the next task | `test` | `coder` — see ownership below |
| Make a failing test pass | `coder` | `test` — the test's author shouldn't also satisfy it |
| Decide whether a task is done | `test` | `coder` — it can't mark its own work complete |
| Write the human-facing summary for a slice | `summary-writer` | `coder` — it describes intent, not effect |
| Review a diff in CI | `reviewer` | — |
| Run a command, regenerate docs, bump a dep | `chore` | anything larger |
| Fix a typo | **nobody — just do it** | any subagent; overhead exceeds the task |

---

## The agents

### `explore` — read-only reconnaissance · `haiku`

Understand existing patterns before planning, when the answer would cost many file reads
in the main context. Owns nothing.

> **This name overrides the built-in.** As of Claude Code v2.1.198 the built-in Explore
> agent inherits the main conversation's model (capped at Opus) instead of always running
> on Haiku. A project subagent named `explore` keeps its own `model` field — which is the
> only way to hold exploration on the cheap tier when your main session is on Opus.
>
> Tradeoff: a subagent's context window is sized by **its own** model, so a Haiku explorer
> has less room. Fine for targeted search; not for "read this entire monorepo."

### `spec` — ADR into a buildable plan · `opus`, effort `high`

**Writes:** `specs/{NNN}-*/design.md`, `CLAUDE.md`, `implementation.md`
**Never:** source, tests

Must produce scope with an explicit out-of-scope list, files touched with slice
assignment, and a test-case table with IDs. Every task maps to test IDs — a task with no
test ID is not a task.

**Hands off to** the human. Stops for spec approval; never enters the loop on its own.

### `test` — owns correctness · `sonnet`

**Writes:** `*.test.ts` only · **Never:** source files

Two jobs: write the failing test and confirm it fails *for the right reason* (a test
failing on a missing import is not a red test), then re-run after changes and decide
whether the task is `done`.

**Sign-off authority is the point.** The agent judging completion is not the one under
pressure to declare victory.

### `coder` — makes the test pass · `sonnet`

**Writes:** source, `implementation.md` · **Never:** **any test file**

Minimal change that passes. Anything beyond the test goes to Deferred work. Budget: 3
attempts, or stop immediately on two identical failures. On exhaustion, mark `blocked` and
escalate with *"is the test correct?"*

### `summary-writer` — writes for humans · `sonnet`

**Writes:** `summary.md` only

Runs when a slice completes, **before** any automated review — so the summary stands alone
and can't lean on CI findings that don't exist yet.

### `reviewer` — the last automated gate · `opus`, effort `high`

**Writes:** nothing. Read-only; reports findings.

Runs in CI once the PR is open, against `design.md`. Blocking status check, not advisory.

**Always check:** whether a test file changed on a task that was previously failing. That
is where a suite goes falsely green, and exactly what a human skimming a diff misses.

Split from `summary-writer` for two reasons: different tier, and read-only tool access is
only enforceable if the agent never needs `Write`.

### `chore` — mechanical work · `haiku`, effort `low`

`bun run docs:sync`, dep bumps, formatting, regenerating artifacts, running a command and
reporting output. **Never** for anything requiring a decision — if it needs one, it isn't
a chore.

---

## What a subagent actually receives

Each subagent starts with a **fresh, isolated context**. It does **not** see your
conversation history, files already read, or skills already invoked.

It **does** get the `CLAUDE.md` hierarchy — project rules load into custom subagents
automatically. (The built-in `Explore` and `Plan` agents are the exception; they skip
CLAUDE.md and git status to stay fast. A *custom* agent named `explore` does not skip it.)

Two consequences that break naive multi-agent setups:

**1. State passes through files, not conversation.** `implementation.md` is the handoff
medium. If `coder` learned something `test` needs, it goes in the file — a note in the
main thread is invisible to the next subagent.

**2. Rule files still need naming.** `CLAUDE.md` loads, but it's an index; the
`.claude/rules/*.md` files it points at are not pulled in automatically. Each definition
names the rules that agent must read.

```
spec ──(design.md, implementation.md)──> human approval
                                            │
                              ┌─────────────┘
                              ▼
                   test ──(failing test)──> coder
                     ▲                        │
                     └───(code change)────────┘
                              │ done
                              ▼
          summary-writer ──(summary.md)──> human ──> PR ──> reviewer (CI)
```

---

## Tool restriction is not enforcement

`tools:` narrows what an agent *can* call, but `Write` and `Edit` are all-or-nothing —
there is no "Edit, but not test files."

Ownership is enforced in three places, and you need all three:

1. **The agent definition** says it — a request the model may reinterpret under pressure
2. **`tools:` frontmatter** removes what it never needs at all
3. **`.claude/hooks/guard-paths.sh`** is the actual wall — `PreToolUse`, exit 2, blocked

Only layer 3 holds when a model is three attempts deep and looking for the shortest path
to green.

---

## Gotchas

**`CLAUDE_CODE_SUBAGENT_MODEL` overrides everything.** If that environment variable is
set, it beats every `model:` field in this repo and the table above is silently ignored.
Resolution order: env var → per-invocation parameter → frontmatter → main conversation's
model. Check it first when an agent is running on the wrong tier.

**Subagents inherit the session's extended-thinking setting.** There is no per-agent
thinking switch; `effort` is the per-agent lever.

**Delegation is not free.** Each subagent costs a full context window plus round-trip
overhead. Don't spawn one for work that fits in a few file reads.

---

## Adding an agent

```markdown
---
name: {name}
description: {when to delegate — a trigger condition, not a topic label}
tools: Read, Grep, Glob, Bash
model: sonnet
effort: medium
color: blue
---

Read first: .claude/rules/core-principles.md, {other rules}.

{Role, what it owns, what it must never touch, output format.}
```

`description` drives auto-delegation — write it as a trigger ("Use after any code change
to review the diff"), not a label ("Code reviewer"). Overlapping descriptions cause the
wrong agent to be picked.

Then add it to the routing and model tables above, and to `.claude/hooks/route-rules.sh`
if it should auto-surface.

> Frontmatter fields and model aliases change between Claude Code versions. Check
> <https://code.claude.com/docs/en/sub-agents> before debugging a definition that stopped
> working.
