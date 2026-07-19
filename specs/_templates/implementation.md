# {Feature Name} — Implementation

Live state. The **source of truth** for where things stand. An agent resuming this feature
reads this file first and picks up from it.

Update it after every task. Never batch updates.

- **Status:** not-started | in-progress | blocked | in-review | done
- **Branch:** `feat/{feature-name}`
- **Spec:** `design.md` · **ADR:** `docs/adr/{NNN}-{feature-name}.md`
- **Current task:** {task-id, or "none"}

---

## Task states

| State | Meaning |
|---|---|
| `pending` | Not started. Dependencies may not be met yet. |
| `red` | Failing test written and confirmed failing for the right reason. |
| `green` | Code passes the test. Not yet committed. |
| `done` | **Test agent confirmed all test cases pass**, committed. |
| `blocked` | Attempt budget exhausted. Work stops here. |

A task reaches `done` only on the test agent's confirmation. The coder agent never marks
its own task complete.

---

## Tasks

In dependency order. Each task must be independently testable and map to test IDs in
`design.md`.

| # | Task | Depends on | Tests | Slice | State | Attempts | Commit |
|---|---|---|---|---|---|---|---|
| 1 | {Prisma schema + migration} | — | T-01 | 1 | `pending` | 0/3 | — |
| 2 | {Repository method} | 1 | T-01, T-02 | 1 | `pending` | 0/3 | — |
| 3 | {Service logic} | 2 | T-03 | 1 | `pending` | 0/3 | — |
| 4 | {Controller + route} | 3 | T-04 | 2 | `pending` | 0/3 | — |
| 5 | {UI component} | 4 | T-05 | 3 | `pending` | 0/3 | — |

### Attempt budget

**3 code attempts per task.** Resets each task, never carries over.

Stop early — do not spend the remaining budget — if the **same failure signature appears
twice in a row**. An identical error twice means the problem is not understood, and
further attempts distort the implementation to satisfy an assertion nobody has understood.

Environmental failures (missing dependency, bad import, config, flake) do not consume an
attempt. Fix them and retry.

On exhaustion: mark `blocked`, fill in the record below, **stop**. Do not start the next
task — tasks are dependency-ordered.

---

## PR slices

Each slice ships independently: summary → human review → PR → CI review.
Max 5–7 files (excluding tests) and 500 lines per slice.

| Slice | Contains | Files | State | PR |
|---|---|---|---|---|
| 1 | Tasks 1–3 — {data layer} | {n} | `pending` | — |
| 2 | Task 4 — {API} | {n} | `pending` | — |
| 3 | Task 5 — {UI} | {n} | `pending` | — |

---

## Blocked

Delete this section when nothing is blocked.

### Task {#} — {name}

- **Failing test:** {T-0X} in `{path}`
- **Blocked at:** {timestamp}

**Attempts**

| # | What was tried | Error |
|---|---|---|
| 1 | {change} | `{exact error}` |
| 2 | {change} | `{exact error}` |
| 3 | {change} | `{exact error}` |

**Stop reason:** budget exhausted | identical failure twice

**Hypotheses**

1. {most likely cause}
2. {alternative}

**The question for the human — is the test correct?**

> Does `{T-0X}` assert what `design.md` actually specifies, or does it encode a
> misunderstanding of it?

{The agent's read. Quote the relevant line of `design.md` against the assertion.}

---

## Test revisions

Every deliberate change to a test, with justification. Written by the **test agent only**.
A revision on a task that was failing gets extra scrutiny from the human reviewer.

| Date | Test | Change | Why |
|---|---|---|---|
| | | | |

---

## Session notes

Newest first. Keep entries short — this is a handoff, not a diary.

### {YYYY-MM-DD}

- **Done:** {tasks completed, commit SHAs}
- **State:** {where the loop stopped}
- **Next:** {exact next action}
- **Watch out for:** {anything the next session would otherwise rediscover the hard way}
