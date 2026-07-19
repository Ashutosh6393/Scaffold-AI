# CONTEXT.md — {Project Name}

What we're building and why. Read this first in any session.

This file answers *what problem exists and for whom*. It does not describe folder
structure, file names, or APIs — those live in the code and go stale here.

---

## In one sentence

{What this product does, for whom.}

## The problem

{What is broken or missing today, for the people who will use this. Concrete, not
aspirational.}

## Who uses it

| User | What they're trying to do | What they care about |
|---|---|---|
| {role} | {job to be done} | {speed / accuracy / cost / trust} |

## What success looks like

{Observable outcomes. How we'd know this worked.}

---

## Domain language

The vocabulary of this project. Use these exact terms in code, tests, commits, and
conversation. If you find yourself inventing a synonym, use the term here instead — or
propose adding one.

| Term | Means | Does **not** mean |
|---|---|---|
| {Term} | {precise definition} | {the near-miss it gets confused with} |

Ambiguous domain terms are the most common cause of an agent building the wrong thing
correctly. Add to this table whenever a misunderstanding surfaces.

---

## Boundaries

### We are building

- {thing}

### We are explicitly not building

- {thing} — {why, or what we use instead}

Second list matters more than the first. It is what stops scope creep from looking like
initiative.

---

## Constraints

| Constraint | Detail |
|---|---|
| Users / scale | {expected load, growth} |
| Compliance / data residency | {if any} |
| Budget | {infra ceilings that rule options out} |
| Deadlines | {if real} |
| Team | {size, who reviews} |

---

## External systems

Things we depend on that we do not control.

| System | Used for | If it goes down |
|---|---|---|
| {service} | {purpose} | {degradation strategy} |

---

## Current state

- **Stage:** prototype | beta | production
- **Live:** {url or "not yet"}
- **Users:** {number or "none yet"}

---

## Decisions

Architectural decisions are **not** recorded here. They live in [`docs/adr/`](docs/adr/).
This file describes the problem; ADRs record what we chose to do about it.
