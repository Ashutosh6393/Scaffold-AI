# Spec-Driven Development

The standard workflow for feature work.

```
ADR  →  spec  →  [ failing test → minimal code → test ]  →  summary  →  human review  →  PR  →  CI review
                          ↑______________________|
```

**Use it for:** anything that adds or changes behaviour.
**Skip it for:** typo fixes, dependency bumps, one-line config changes. Judgement applies —
but if you're unsure, use it.

Detail lives in the rule files rather than being restated here:
[testing.md](.claude/rules/testing.md) (the loop, attempt budget),
[git.md](.claude/rules/git.md) (branches, commits, PR splitting),
[core-principles.md](.claude/rules/core-principles.md).

---

## Scope

**In scope:** everything from "an ADR exists" onward — creating a spec from it, resuming
an existing spec, the loop, the summary, the handoff to review.

**Out of scope:** turning a problem statement (chat, GitHub issue, Jira, Linear) into an
ADR. That happens first. This workflow assumes `docs/adr/{NNN}-{slug}.md` exists and is
accepted.

---

## Layout

```
docs/adr/
└── 007-feature-name.md        # the input — never edited by this workflow

specs/
├── _templates/                # copy to start
└── 007-feature-name/
    ├── CLAUDE.md              # agent instructions for THIS feature
    ├── design.md              # the plan: scope, files touched, test cases
    ├── implementation.md      # live task state, attempts, blockers
    └── summary.md             # human-readable QA doc
```

Exactly four files. Nothing else goes in a spec folder.

- Architecture decisions → `docs/adr/`
- Deferred ideas → the **Deferred work** section of `summary.md`

Spec number matches the ADR number.

---

## Agents and file ownership

Ownership is a hard boundary. It is what makes a green suite mean something.

| Agent | May write | May **never** write |
|---|---|---|
| **Spec** | `design.md`, `CLAUDE.md`, `implementation.md` | source, tests |
| **Test** | `*.test.ts` | source files |
| **Coder** | source, `implementation.md` | **any test file** |
| **Reviewer** | `summary.md`, PR comments | source, tests |

The coder agent never touches a test file — not to fix a failure, not on the last
attempt, not temporarily. See [testing.md](.claude/rules/testing.md#test-ownership).

---

## Entry points

### Resuming

> "Continue working on 007-feature-name"

1. Read the spec's `CLAUDE.md`.
2. Read `implementation.md` — the source of truth for current state.
3. Any task `blocked`? **Stop and report.** Don't start other tasks.
4. Otherwise take the first `pending` task whose dependencies are `done`.
5. Confirm you're on `feat/{feature-name}`.
6. Enter the loop.

### Creating from an ADR

> "Build the feature from ADR-007"

1. Read `docs/adr/007-*.md` in full.
2. Explore the codebase for existing patterns in the layers this touches.
3. `cp -r specs/_templates specs/007-feature-name`
4. `git checkout -b feat/feature-name`
5. Fill in `design.md` — scope, approach, files touched, the full test case list.
6. Fill in `CLAUDE.md` — patterns and constraints specific to this feature.
7. Fill in `implementation.md` — tasks in dependency order, each mapped to test IDs.
8. **Stop. Ask the human to review the spec before writing any code.**

Step 8 is not optional. The loop is expensive; a wrong spec wastes all of it.

---

## The loop

One task at a time, in dependency order, per
[testing.md](.claude/rules/testing.md#the-loop):

```
RED (failing test) → verify it fails correctly → GREEN (minimal code) → re-run → commit
```

**A task is `done` only when the test agent confirms every one of its test cases passes.**
The coder agent does not mark its own work complete.

Commit once per task. Update `implementation.md` and any documentation the change made
stale — same commit, never batched.

### When it stalls

Three attempts per task, or two identical failures in a row, and you stop. Mark the task
`blocked`, record every attempt, and escalate with the question **"is the test correct?"**
Do not proceed to the next task — they're dependency-ordered.

Full policy: [testing.md](.claude/rules/testing.md#attempt-budget).

---

## Shipping

### PR slices

A PR must be reviewable in under 10 minutes (5–7 files excluding tests, 500 lines). Most
features exceed that, so `implementation.md` groups tasks into **slices**, and each slice
ships independently:

```
slice complete → summary.md → human review → PR → reviewer agent in CI
```

One spec normally produces several PRs. Splitting strategy:
[git.md](.claude/rules/git.md#splitting-large-changes).

### summary.md

Regenerated when a slice completes. Written for a **human**, before any automated review
has run — so it stands alone and can't lean on a reviewer summary that doesn't exist yet.
QA format: what changed, why, how to verify by hand, what to watch.

### Human review

The human reads `summary.md` and the diff, then approves the PR being raised. **This gate
is before CI, not after.**

### CI review

Once the PR is open, the **reviewer agent runs as a CI check** against the full diff:
changes, logic, and adherence to `design.md`. Result is blocking, not advisory.

---

## Hard rules

- Never let the coder agent touch a test file.
- Never mark a task `done` without the test agent confirming a pass.
- Never continue past a `blocked` task.
- Never build anything not in `design.md` — new ideas go to Deferred work.
- Never batch documentation updates.
- Never skip the human review of the spec before the first line of code.
- One commit per task. One focused change per PR.
- Check [tech-stack.yaml](tech-stack.yaml) before adding a dependency. Not listed? Ask.
