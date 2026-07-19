---
name: implement
description: Run the red-green TDD loop on the current slice of a feature spec. Use to start or resume building a spec, or when the user says continue working on a feature. Stops at the slice boundary for human review. Phase 3 of the build pipeline.
---

# implement — Phase 3

Build the **current in-progress slice** of a spec, and nothing else.

This is the only phase that runs without a human in the inner loop, so the discipline is
strict and partly machine-enforced (`guard-paths.sh`, `check-test-count.sh`).

---

## Step 1 — locate the spec

**Named** (`implement notifications`) → use it.

**Not named** → list the state and ask:

```bash
for d in specs/*/; do
  [ "$(basename "$d")" = "_templates" ] && continue
  printf '%-32s %s\n' "$(basename "$d")" "$(grep -m1 'Status:' "$d/implementation.md")"
done
```

Show in-progress specs first, then not-started, and ask which to work on. Don't guess.

**If no spec exists** → stop. Tell the user to run `to-spec`. Do not start implementing
from an ADR directly; the slice plan is what makes the loop bounded.

---

## Step 2 — orient

1. Read `specs/{feature}/CLAUDE.md`, then `design.md` (slice plan), then
   `implementation.md`.
2. Identify the **current slice**, its **blast radius**, and its **acceptance criteria**.
3. Confirm you are on `feat/{feature-name}`.
4. **If any task is `blocked`, stop and report it.** Do not start other tasks — they are
   dependency-ordered, and working around a block means building on something known to be
   broken.

Record the starting test count so the append-only rule is checkable:

```bash
bash .claude/hooks/check-test-count.sh --baseline
```

---

## Step 3 — the loop

One task at a time, in dependency order. One cycle at a time.

### RED — delegate to the `test` agent

Write **one** failing test for the next smallest behaviour, at the highest seam named in
`design.md`. Run it.

**Confirm it fails for the right reason.** Read the error. A test failing on a missing
import is not a red test — it's a broken one.

If it passes immediately, stop and investigate: either the behaviour already exists or the
test asserts nothing. A free pass is not progress.

### GREEN — delegate to the `coder` agent

The minimum code that passes. Every line traces to the failing test.

**Stay inside the blast radius.** Need to touch something outside it? Stop, record it, and
ask the user. Do not quietly widen the boundary — the blast radius is what keeps the PR
reviewable and the slice revertible.

### VERIFY — back to the `test` agent

Re-run the task's tests, then the full suite. The test agent decides whether the task is
`done`. The coder never marks its own work complete.

### REFACTOR — optional, suite green

Tidy with no behaviour change. Skip it if there's nothing to tidy; refactoring for its own
sake is not a step.

### COMMIT

One small atomic commit per task:

```
{type}({scope}): {what changed}

Task: {id} from specs/{feature}/implementation.md
Tests: {test-ids}
```

Update `implementation.md` — task `done`, commit SHA, what's next. Update any
documentation the change made stale, **same commit**.

### DECIDE

Acceptance criteria met → stop, go to Step 4. Otherwise → next cycle.

---

## Hard rules

**Tests are append-only.** Never edit, weaken, skip, or delete a test to reach green. The
test count must not drop across a slice. A test that won't pass means the *code* is wrong —
or the test is, and that's a conversation, not a repair.

A deliberate test revision is legitimate but is a separate act: only the `test` agent does
it, it needs a written justification in the **Test revisions** table, and it lands as its
own commit. `check-test-count.sh` will catch a silent drop.

**Minimal code only.** No speculative abstraction, no configurability nobody asked for.

**Stay in the blast radius.**

**Nothing outside `design.md`.** New ideas go to Deferred work in `summary.md`.

---

## Stop conditions — halt and report, never grind

| Condition | Action |
|---|---|
| Acceptance criteria met | Report success, go to Step 4 |
| Same failure signature twice in a row | **Stop immediately.** Don't spend the remaining budget |
| 3 attempts on one task | Stop. Mark `blocked` |
| Required change falls outside the blast radius | Stop and ask |
| A test would have to change to reach green | Stop and ask |

### On a block

1. Mark the task `blocked` in `implementation.md`.
2. Record each attempt: what changed, and the exact error.
3. Ask the real question — **"is the test correct?"** Quote the relevant line of
   `design.md` against the assertion and give your read.
4. **Stop.** Do not start the next task.

Do not request a bigger model. A block usually means the test encodes a misunderstanding
or the task was scoped too large — and a stronger model will paper over both rather than
surface them. Re-running on Opus is the human's call.

---

## Step 4 — the slice boundary

The human gate. Delegate to `summary-writer` (never `coder` — it describes intent, not
effect) to write `summary.md` for this slice.

Then verify and report:

```bash
bash .claude/hooks/check-test-count.sh   # must not have dropped
bun run docs:check                        # generated blocks in sync
```

Report:

- Which acceptance criteria are now satisfied
- Test count before and after
- Files changed and total lines — against the 5–7 file / 500-line limit
- Any deferred work surfaced
- **Any test revisions**, conspicuously. "None" is the expected answer

Then:

> Slice {n} complete and green. Please review `summary.md` and the diff. Once you approve
> and the PR is merged, run `/clear`, then **implement {feature}** again for the next
> slice.

`/clear` matters. The next slice starts from `implementation.md`, not from a context
window full of the last one.

---

## After the PR opens

The `reviewer` agent runs as a **CI check** against the full diff — blocking, not
advisory. That is a separate gate from the human review above, and it runs after it, not
before.
