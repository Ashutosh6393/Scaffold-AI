# {Feature Name} — Design

The plan. Source of truth for **what** gets built. Nothing gets implemented that is not
described here.

> **This is not an ADR.** The decision and its rationale live in
> `docs/adr/{NNN}-{feature-name}.md`. This document assumes that decision is made and
> describes how it lands in the codebase.

- **Source ADR:** `docs/adr/{NNN}-{feature-name}.md`
- **Status:** draft | approved
- **Approved by:** {human} on {date}

> Implementation does not start until Status is `approved`.

---

## What we're building

{2–4 sentences. Concrete and observable — what will be true after this ships that is not
true now.}

## Why now

{One or two lines linking back to the ADR. Do not re-argue the decision.}

---

## Scope

### In scope

- {Thing 1}
- {Thing 2}

### Out of scope

- {Thing} — {why, or where it went instead}

Anything discovered mid-build that is not in the in-scope list goes to **Deferred work**
in `summary.md`. It does not get built.

---

## Approach

{How it works. Data flow, the shape of the solution, how it fits existing architecture.}

### Data model

{Prisma schema changes. New models, new fields, indexes, migration notes. "No change" is
a valid answer.}

### API surface

| Method | Route | Purpose | Auth |
|---|---|---|---|
| `GET` | `/{path}` | {what} | {public / session / role} |

### Validation

{Zod schemas, where they live, which boundaries they guard.}

### UI

{Routes/pages, server vs client components, state ownership — TanStack Query for server
state, Zustand for UI state only.}

### Existing code to reuse

{The buy-vs-build check. What already exists — in this repo or as a maintained library —
that this feature should use instead of reimplementing.}

---

## Files touched

Keep this current. It is how PR slices get sized.

| Path | Change | Layer | Slice |
|---|---|---|---|
| `apps/server/src/repository/{x}.ts` | new | repository | 1 |
| `apps/server/src/services/{x}.ts` | new | service | 1 |
| `apps/server/src/controllers/{x}.ts` | new | controller | 2 |
| `apps/web/app/{x}/page.tsx` | modify | web | 3 |

Excluding tests, each slice must stay within **5–7 files / 500 lines**.

---

## Test cases

Every task in `implementation.md` maps to one or more of these IDs. If a behaviour is not
listed here, there is no test for it, and it does not get built.

| ID | Verifies | Type | Given → When → Then |
|---|---|---|---|
| T-01 | {behaviour} | unit | {given} → {when} → {then} |
| T-02 | {error path} | unit | {given} → {when} → {then} |
| T-03 | {edge case} | integration | {given} → {when} → {then} |

### Edge cases and failure modes

- {Empty / null / boundary input}
- {Concurrent access, duplicate submission}
- {Third-party or DB failure — what should the user see?}
- {Authorization: what happens for the wrong user?}

---

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| {what could go wrong} | {who it hurts} | {what we do about it} |

---

## Open questions

Resolve before Status becomes `approved`. Unanswered questions here are the most common
cause of a blocked task later.

- [ ] {question} — **owner:** {who}
