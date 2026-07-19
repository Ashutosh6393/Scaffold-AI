---
name: to-adr
description: Turn a design discussion into an Architecture Decision Record in docs/adr/. Use after a grilling session, or when the user points at a GitHub issue, Linear/Jira ticket, or describes a problem that needs a recorded decision. Phase 1 of the build pipeline.
---

# to-adr — Phase 1

Produce `docs/adr/{NNN}-{feature-name}.md`. This is the **input** to everything
downstream: `to-spec` reads it, and `implement` builds from the spec it produces.

Read `.claude/rules/documentation.md` (ADR section) and `CONTEXT.md` before writing.

---

## Step 0 — do you have enough to decide?

An ADR records a decision *and the reasoning behind it*. You cannot synthesize reasoning
that never happened.

**If the conversation already contains a substantive design discussion** — alternatives
weighed, tradeoffs named, constraints surfaced — go straight to Step 1. Do **not**
interview the user again. Synthesize what you already know.

**If the user pointed you at a bare issue, ticket, or one-line description**, you have a
problem statement, not a decision. Fetch it, read it, then run the **`grilling`** skill to
work through the design tree before writing anything.

> `grill-me` is user-invoked only (`disable-model-invocation: true`), so you cannot call
> it yourself. Use the `grilling` skill, which is the same interview. If the user would
> rather drive, tell them to run `/grill-me` and stop.

**If you are unsure which case you're in, ask.** Writing an ADR from thin material
produces a document that looks authoritative and encodes nothing — worse than no ADR,
because `to-spec` will treat it as settled.

---

## Step 1 — ground it in the codebase

Delegate to the `explore` agent rather than bulk-reading:

- Existing patterns in the area this touches
- Prior ADRs governing the same area — read `docs/adr/` for anything related
- Whether `tech-stack.yaml` already answers a tooling question raised here

Use the vocabulary from `CONTEXT.md`. If this decision introduces a new domain term,
propose adding it there.

---

## Step 2 — check for a prior decision

If an existing ADR covers this ground, you are **superseding**, not writing fresh.

ADRs are append-only. Never rewrite one. Write a new ADR, and in the same commit set the
old one's status to `superseded by ADR-{NNN}`. The superseded record is how a future
reader learns the obvious-looking alternative was already tried.

---

## Step 3 — pick the number

```bash
ls docs/adr/ | grep -oE '^[0-9]{3}' | sort -n | tail -1
```

Next integer, zero-padded to three digits. Never reuse a number, even for a deleted or
rejected ADR. Slug is kebab-case: `002-notification-preferences.md`.

---

## Step 4 — write it

Follow the template in `docs/adr/README.md`. Notes on the sections that carry weight:

**Context** — what you knew *at the time*, not what you know now. Include the constraints
that ruled options out. A future reader's first question is "why not the obvious thing?"

**Alternatives** — at least two, seriously considered. If you can't state a real
alternative, this probably isn't a decision worth recording. One-option ADRs are how a
directory of them becomes noise.

**Decision** — what was chosen and *why it beat the alternatives*.

**Tradeoffs** — what was knowingly given up. **If this section is empty, you haven't
found the cost yet.** Every real decision has one. Go back and look.

**Consequences** — what this now requires, enables, or forecloses. Migrations. New
obligations. Things that become harder.

### Also capture, when the discussion produced them

**Testing seams.** Where will this be tested, and at what level? Prefer existing seams to
new ones, and the highest seam that still gives real coverage. Fewer seams across the
codebase is better — one is ideal. If a new seam is needed, say so here so `to-spec`
doesn't have to invent it.

**Proposed slices.** A rough cut at how this ships incrementally. `to-spec` refines this
into a real slice plan; a sketch here saves it guessing.

**Out of scope.** What this decision deliberately does not cover.

### Don't include

File paths or code snippets. They go stale fast and the spec supersedes them anyway.

*Exception:* if the discussion produced a snippet that encodes a decision more precisely
than prose can — a state machine, a schema, a type shape — inline just the decision-rich
part and note where it came from. Not a working demo.

---

## Step 5 — stop at the gate

Status starts as `proposed`. Present the ADR and ask the user to confirm the decision and
the tradeoffs before it becomes `accepted`.

Add it to the index table in `docs/adr/README.md` in the same commit.

Commit: `docs(adr): {NNN} {short title}`

## Hand off

> ADR-{NNN} is written. Once you've accepted it, run **to-spec {NNN}** to turn it into a
> sliced technical spec.

Do not proceed to `to-spec` yourself. An unaccepted ADR is a draft, and building a spec on
a draft wastes both.
