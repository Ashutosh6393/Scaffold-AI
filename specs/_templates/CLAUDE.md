# CLAUDE.md — {Feature Name}

Feature-specific instructions. Read this **first**, before `design.md`.

- **Spec:** `specs/{NNN}-{feature-name}/`
- **Source ADR:** `docs/adr/{NNN}-{feature-name}.md`
- **Branch:** `feat/{feature-name}`
- **Workflow:** [`SPEC-WORKFLOW.md`](../../SPEC-WORKFLOW.md) — the loop, retry limits, and
  file ownership rules apply here in full.

---

## Context

{One paragraph: what this feature does and who it is for. Not the decision rationale —
that is in the ADR.}

---

## Before writing anything

1. Read `design.md` — scope, files touched, test cases.
2. Read `implementation.md` — this is the source of truth for current state.
3. If any task is `blocked`, **stop and report it.** Do not start other tasks.
4. Confirm you are on `feat/{feature-name}`.
5. Read the reference implementations listed below.

---

## Which agent am I?

| If you are the… | You may write | You may **never** write |
|---|---|---|
| Test agent | `*.test.ts` | source files |
| Coder agent | source files, `implementation.md` | **any test file** |

If you are the coder agent and you believe a test is wrong: **stop and escalate.**
Do not edit it, skip it, or weaken the assertion. That path produces a green suite that
proves nothing, and it is the single failure mode this workflow exists to prevent.

---

## Reference implementations

Follow these rather than inventing a new shape.

| Concern | Follow the pattern in |
|---|---|
| {Controller} | `{path}` |
| {Service} | `{path}` |
| {Repository} | `{path}` |
| {Component} | `{path}` |
| {Test} | `{path}` |

---

## Patterns for this feature

{Anything an agent would otherwise get wrong. Naming, error shapes, edge cases, an
existing helper it should reuse instead of rewriting, a gotcha in this part of the
codebase.}

- Layer order is `routes → controllers → services → repository`. Only the repository
  layer imports the Prisma client.
- Validate every boundary with Zod. Derive types with `z.infer` — do not hand-write them.
- Check `tech-stack.yaml` before adding a dependency.

---

## Don't

- Don't build anything not in `design.md`. New ideas go to **Deferred work** in `summary.md`.
- Don't skip tests, and don't write code before the failing test exists.
- Don't mark a task `done` yourself — the test agent confirms the pass.
- Don't continue past a `blocked` task.
- Don't batch documentation updates; they ship in the same commit as the change.
- {Feature-specific don'ts — e.g. "don't touch the auth tables directly, Better Auth owns them"}
