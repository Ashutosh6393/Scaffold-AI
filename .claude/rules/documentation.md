---
name: documentation
load_when: Writing docs, recording an ADR, or adding module metadata.
---

# Documentation

## The freshness contract

Stale documentation is worse than missing documentation. Missing docs make an agent ask.
Wrong docs make it confidently wrong — and the confidence is the expensive part.

Three tiers, and the tier decides how a fact is kept true:

### Tier 1 — Derived (never hand-written)

Anything a script can read off the filesystem: workspace lists, folder trees, the rules
index, active specs.

These live between sentinel markers and are rewritten by `bun run docs:sync`:

```markdown
<!-- BEGIN GENERATED: workspaces -->
...regenerated content...
<!-- END GENERATED: workspaces -->
```

**Never hand-edit inside a generated block.** CI runs `docs:sync` and fails on drift, so
hand edits get reverted anyway.

### Tier 2 — Stable prose (hand-written, changes rarely)

Principles, workflow, domain language, links. Written once, revisited deliberately.

**Rule: if a change makes a line here false, fix it in the same commit.** Not in a
follow-up, not in a cleanup PR. The same commit, or it never happens.

### Tier 3 — Not documented at all

Detailed file structure, function inventories, API surfaces, anything with a one-to-one
correspondence to code. **Don't write it down.** It cannot be kept true by discipline, and
a folder tree pasted into prose is stale the day someone adds a folder.

Point at the code instead. The code is the only description of itself that can't drift.

### The test

Before writing any sentence into a doc, ask: **what makes this false, and would I notice?**

- Nothing makes it false → Tier 2, write it.
- Code changes make it false and a script can detect that → Tier 1, generate it.
- Code changes make it false and nothing would catch it → **Tier 3. Don't write it.**

---

## Module documentation

Important modules explain:

- **Purpose** — what it's for
- **Responsibilities** — what it owns
- **Non-responsibilities** — what it deliberately doesn't do
- **Dependencies** — what it needs
- **Constraints** — limits and assumptions
- **Tradeoffs** — what was knowingly given up

The non-responsibilities line is the one people skip and the one that saves the most
time. It's what stops the next contributor from adding a feature to the wrong module.

**Document *why*, not *what*.** The code says what. Only a human knew why.

```ts
// Bad — restates the code
// Increment the retry counter
retries++

// Good — explains a decision
// Retry 3x: the provider returns 502 on cold start, which resolves within ~2s.
// More than 3 and we exceed the webhook timeout.
```

---

## Metadata for complex modules

Where a module carries real business rules, state them in a header comment:

- Purpose
- Owner (optional)
- External dependencies
- Business rules
- Failure modes

---

## Architecture Decision Records

Significant decisions go in [`docs/adr/`](../../docs/adr/) as `{NNN}-{slug}.md`.

**Significant** means: hard to reverse, affects more than one module, or a future reader
would otherwise ask "why on earth is it like this?"

Template:

```markdown
# ADR-{NNN}: {Title}

- **Date:** {YYYY-MM-DD}
- **Status:** proposed | accepted | superseded by ADR-{NNN}

## Context
{What situation forced a decision. Constraints in play.}

## Alternatives
1. {Option} — {pros/cons}
2. {Option} — {pros/cons}

## Decision
{What we chose and why.}

## Tradeoffs
{What we knowingly gave up.}

## Consequences
{What this now requires or forecloses.}
```

ADRs are **append-only**. A decision that changes gets a *new* ADR that supersedes the
old one. Never rewrite history — the superseded record is how a future reader learns the
obvious-looking alternative was already tried.

Adding a tool to `tech-stack.yaml` requires an ADR.

---

## Structured over prose

For anything a machine reads — architecture, dependencies, services, integrations,
conventions — prefer YAML or JSON over prose. It's parseable, diffable, and can be
validated in CI. Prose can only be re-read and hoped about.

---

## Never

- Hand-edit inside a `GENERATED` block
- Document the folder structure in prose
- Batch doc updates into a separate commit or PR
- Leave a doc contradicting the code you just changed
- Rewrite an existing ADR — supersede it instead
