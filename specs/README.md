# Specs

Design documents for features in development. Agents read these to know what to build
and where they left off.

The full process — agent roles, the TDD loop, retry limits, review gates — is in
[`SPEC-WORKFLOW.md`](../SPEC-WORKFLOW.md). This file is the short version for humans.

---

## The flow

```
ADR  →  spec  →  [ failing test → minimal code → test ]  →  summary  →  you review  →  PR  →  CI review
```

A spec starts from an **approved ADR** in `docs/adr/`. If there is no ADR yet, write that
first — the spec is downstream of the decision, not a substitute for it.

---

## Starting a feature

```bash
cp -r specs/_templates specs/007-feature-name
git checkout -b feat/feature-name
```

Then:

```
"Build the feature from ADR-007. Review the codebase and fill in specs/007-feature-name/."
```

The agent fills in `design.md`, `CLAUDE.md`, and `implementation.md`, then **stops and
waits for you to review the spec.** Nothing gets written until you approve it. Read the
task list closely — it is cheap to fix here and expensive to fix later.

The spec folder number matches the ADR number.

---

## Resuming

```
"Continue working on 007-feature-name"
```

The agent reads `implementation.md` and picks up at the first pending task whose
dependencies are done. If anything is `blocked`, it stops and tells you instead.

---

## The four files

| File | Purpose | Who writes it |
|---|---|---|
| `CLAUDE.md` | Agent instructions for this feature | Spec agent |
| `design.md` | The plan — scope, files touched, test cases | Spec agent |
| `implementation.md` | Live task state, attempts, blockers | All agents |
| `summary.md` | Human-readable QA doc | Reviewer agent |

That is the whole folder. Nothing else goes in it.

- Architecture decisions live in `docs/adr/`.
- Deferred ideas live in the **Deferred work** section of `summary.md`.

---

## What to expect while it runs

- **One commit per task.** Not one per feature — the history should read as a sequence of
  small green steps.
- **Tests are written before code, always**, by a different agent than the one writing the
  code. The coder agent cannot touch test files.
- **Tasks are marked done only when the test agent confirms a pass.** The agent that wrote
  the code does not get to declare victory.
- **It will stop and ask you** rather than grind. Three attempts per task, or two identical
  errors in a row, and it escalates. The question it brings you is usually *"is this test
  actually right?"* — which is more often the real problem than the code is.
- **Documentation updates ship with the change**, not batched at the end.

---

## When it gets blocked

You will see a task marked `blocked` in `implementation.md` with the error, every attempt
made, and the agent's hypotheses. Work stops there — it will not skip ahead, because
tasks are dependency-ordered.

Usually one of four things:

1. The test encodes a misunderstanding of `design.md` → fix the test (or the design).
2. The task was scoped too large → split it in `implementation.md`.
3. Something environmental → fix it; that does not count against the budget.
4. The design is genuinely wrong → back to the ADR.

---

## Reviewing

You review **before** the PR is raised. Read `summary.md` — it is written for you, in QA
format, and it stands alone. Then the PR opens and the reviewer agent runs as a **CI
check** on the full diff, posting findings to the PR and publishing a summary to Notion.

Watch for a **test revision** commit on a task that was failing. Tests are only ever
changed deliberately, by the test agent, with a written justification. It is legitimate —
but it is exactly where a suite goes falsely green, so it earns a closer look.

---

## The most important rule

**Every PR must be reviewable in under 10 minutes:**

- Max 5–7 files changed (excluding tests)
- Max 500 lines changed
- One focused change

Most features are bigger than that, so `implementation.md` groups tasks into **PR slices**.
Each slice goes through summary → your review → PR → CI review on its own. One spec
produces several PRs, and that is the expected shape.
