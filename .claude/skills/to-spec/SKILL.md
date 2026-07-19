---
name: to-spec
description: Turn an accepted ADR into a sliced technical spec under specs/. Use when an ADR exists and is ready to build, or when the user asks to plan, spec, or slice a feature. Stops at a human gate. Phase 2 of the build pipeline.
---

# to-spec — Phase 2

Turn an accepted ADR into a precise, sliced spec that `implement` can derive from.

**Do not write any implementation code in this phase.** It ends at a human gate.

Delegate the actual writing to the **`spec` agent** (Opus, high effort). Planning is where
the reasoning tier earns its price — a vague spec burns every downstream attempt budget.

---

## Step 1 — locate the ADR

**If the user named one** (`to-spec 002`, or "spec out the notifications ADR"), use it.

**If not, list what's available and ask:**

```bash
grep -l 'Status:.*accepted' docs/adr/*.md
```

Show the user the accepted ADRs with no spec folder yet, and ask which to build. Don't
guess — picking the wrong one wastes the whole phase.

**Refuse to proceed if:**

- The ADR's status is `proposed` → it hasn't been accepted. Send them back to finish it.
- The ADR is `superseded` → build the superseding one instead.
- No ADR exists → stop and tell the user to run `to-adr` first. Do not invent a decision
  to fill the gap; that's the exact thing ADRs exist to prevent.

---

## Step 2 — resume or create?

Check whether `specs/{NNN}-*/` already exists.

**It exists** → this is a re-plan, not a scaffold. Read `implementation.md` first. If work
is in progress, preserve completed task state; you are refining the plan, not resetting
it. If anything is `blocked`, resolve that with the user before re-planning around it.

**It doesn't** → scaffold:

```bash
git checkout -b feat/{feature-name}
cp -r specs/_templates specs/{NNN}-{feature-name}
```

The spec number matches the ADR number. Confirm the branch before writing anything.

---

## Step 3 — explore before planning

Delegate to `explore`. You need:

- Existing patterns in every layer this touches — the spec should follow them, not
  introduce a second way of doing the same thing
- The reference implementation worth imitating, named specifically
- Relevant ADRs beyond the source one
- Domain vocabulary from `CONTEXT.md`

---

## Step 4 — fill in the four files

Nothing else goes in a spec folder. Deferred ideas go in `summary.md`, not a separate
file. Decisions go in `docs/adr/`, not here.

### `design.md`

Carry decisions over from the ADR — **do not invent beyond it.** If the ADR is silent on
something you need, that's a gap: raise it with the user or write a follow-up ADR. Don't
quietly decide.

Beyond the template's sections, two things matter most:

**Seams.** Where this gets tested, and at what level. Prefer existing seams; use the
highest one that still gives real coverage. Carry over what the ADR proposed. Confirm with
the user that the seams match their expectation before going further — a wrong seam means
every test in the slice plan tests the wrong thing.

**The test-case table.** Every behaviour gets an ID. Error paths and edge cases, not just
the happy path. If a behaviour isn't in this table, no test will exist for it, and it will
not get built.

### The slice plan (in `design.md`)

Refine the ADR's proposed slices into **vertical** slices. Each one gets:

| Field | Meaning |
|---|---|
| **Blast radius** | The files and modules this slice may touch. A hard boundary. |
| **Acceptance criteria** | What must be true to call it done. Something the user would sign off on. |
| **Test IDs** | Which cases from the table this slice satisfies. |

Rules:

- **Vertical, not horizontal.** Each slice is independently shippable and demonstrable end
  to end. "The database layer" is not a slice; "a user can save one preference" is.
- **Walking skeleton first.** The thinnest end-to-end path, then thicken it.
- **Riskiest slices early.** Front-load whatever could invalidate the plan. Discovering a
  design is wrong in slice 1 is cheap; discovering it in slice 4 is not.
- **Dependency-correct order.** Each slice merges on its own.
- **Size to the PR limit:** 5–7 files (excluding tests) and 500 lines.

### `CLAUDE.md`

Feature-specific context: patterns to follow with concrete file references, and the don'ts
an agent would otherwise get wrong here.

### `implementation.md`

Every task under the right slice, dependency-ordered, each mapped to test IDs, all
`pending`. Status `not-started`.

**Size tasks so three attempts is generous, not tight.** A task needing more than three is
scoped too large — and that is a planning error, not a coder error.

### `summary.md`

Leave as the template. It gets written when the first slice completes.

---

## Step 5 — stop at the gate

Present the slice plan and ask the user to confirm:

1. The slices are **vertical** and independently shippable
2. The **order** is dependency-correct, with the riskiest work early
3. Each **acceptance criterion** is something they'd sign off on
4. Each **blast radius** is right — nothing obviously missing, nothing suspiciously wide
5. The **seams** match how they'd test it

Do not implement until they approve. This gate is cheap; the loop is not.

Commit: `docs(spec): scaffold {NNN}-{feature-name}`

## Hand off

> Slice plan approved. Run **implement {feature-name}** to start the red-green loop on
> Slice 1. I'll stop at the slice boundary for your review before moving on.
