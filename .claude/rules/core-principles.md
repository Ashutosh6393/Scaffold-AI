---
name: core-principles
load_when: Always — before writing any code.
---

# Core Principles

Behavioural guidelines that reduce the most common agent coding failures. This is the one
rule file that applies to every task.

---

## 1. Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, **stop**. Name what's confusing. Ask.

Asking costs one message. Building the wrong thing costs a review cycle, a revert, and
the trust that the next thing you build is right.

---

## 2. Simplicity first

**The minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" nobody requested.
- No error handling for impossible scenarios.
- If you wrote 200 lines and it could be 50, rewrite it.

The test: *would a senior engineer call this overcomplicated?* If yes, simplify.

Speculative generality is the most expensive thing an agent produces, because it looks
like thoroughness in review and only reveals itself as cost six months later.

---

## 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style even where you'd do it differently.
- Notice unrelated dead code? **Mention it. Don't delete it.**

When your changes create orphans:

- Remove imports, variables, and functions that *your* change made unused.
- Don't remove pre-existing dead code unless asked.

**The test: every changed line traces directly to the request.** A reviewer should never
have to ask "why is this file in the diff?"

---

## 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Turn tasks into verifiable goals:

| Vague | Verifiable |
|---|---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test reproducing it, then make it pass" |
| "Refactor X" | "Tests pass before and after, behaviour unchanged" |

For multi-step work, state the plan first:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

Strong criteria let you loop independently. Weak criteria ("make it work") force you back
to the human every few minutes.

---

## 5. Write for the next reader

Assume both a human and an agent will read every important file, and that neither was
present when you wrote it.

- Optimize for clarity over cleverness.
- Make intent obvious.
- Keep responsibilities small and explicit.
- Document decisions, not implementation.
- Prefer consistency over personal preference.

---

## General rules

- Explicit beats implicit.
- Consistency beats cleverness.
- Small modules beat giant abstractions.
- Make changes easy to review.
- Optimize for long-term maintainability.
- Document *why*, not *what*.

---

## When you're stuck

Escalate rather than grind. Two failed attempts at the same thing with the same error
means the problem isn't understood, and a third attempt is a lottery ticket.

Bring the human: what you tried, the exact errors, and your best hypothesis — not
"it doesn't work". See [testing.md](testing.md) for the attempt budget.
