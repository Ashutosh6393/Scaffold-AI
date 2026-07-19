---
name: errors-and-validation
load_when: Handling errors, defining schemas, or accepting external input.
---

# Errors and Validation

## Validation

**Schemas are the source of truth.** Zod defines the shape; TypeScript types are derived
with `z.infer`. Never maintain a type and a schema separately — they will drift, and the
drift shows up as a runtime error in production rather than a type error in CI.

Validate at **every boundary**:

| Boundary | Validate |
|---|---|
| HTTP request | body, params, query, headers you rely on |
| Environment | at boot — fail fast, not on first use |
| Queue payload | on enqueue **and** on process |
| Third-party response | always — their contract is not your contract |
| Database → domain | when the DB shape and domain shape differ |

Shared schemas live in a package both apps consume. A schema defined twice is a bug
waiting for a deploy.

Parse, don't validate: turn unknown input into a typed value once, at the edge, and let
everything downstream trust the type.

---

## Errors

### Never

- Throw strings. Throw error types.
- Silently swallow a failure. If you catch it, handle it or rethrow it.
- Return multiple error styles from one module — pick one and hold it.
- Log and rethrow at every level. Log once, where you handle it.

### Prefer domain-specific error types

```ts
class BookingSlotTakenError extends Error { ... }
```

A caller can branch on `BookingSlotTakenError`. It cannot branch on
`new Error("slot taken")` without string-matching, and string-matching breaks the first
time someone rewords the message.

### Error responses

All HTTP errors flow through **one** handler with **one** shape. A client that has to
handle three error formats from one API will handle two of them wrong.

Include: a stable machine-readable code, a human-readable message, and — in development
only — detail. Never leak internals, stack traces, or query text to a client.

### What the user sees

Every failure path answers: what does the user see, what gets logged, what gets retried?
"It throws" is not an answer.

---

## Never

- Expose credentials, tokens, or secret fields in any query result or response
- Swallow an error to make a test pass
- `catch {}` with an empty body
