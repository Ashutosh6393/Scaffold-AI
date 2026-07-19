---
name: security
load_when: Touching auth, secrets, credentials, user data, or env files.
---

# Security

## Absolute prohibitions

These are not judgement calls.

- **Never commit secrets, API keys, tokens, or `.env` files.** Not temporarily, not
  commented out, not in a test fixture, not in a code sample in a doc.
- **Never expose credential or secret fields in a query.** Select explicit fields;
  never `select: *` on a table holding credentials.
- **Never log secrets, tokens, passwords, or full request bodies** that might contain
  them.
- **Never put personal or sensitive data in a URL or query string** — it lands in logs,
  browser history, and referrers.
- **Never disable an auth check to make a test pass.** Fix the test.

If a secret is committed: it is compromised. Rotate it. Removing the commit is not
sufficient — the value is in the reflog, on every clone, and in CI logs.

---

## Secrets handling

- Secrets come from environment variables, validated at boot with Zod.
- `.env` is git-ignored. `.env.example` is committed with **key names only**, no values.
- An agent must never read `.env` to "check" a value, and never echo one to output.

---

## Authentication and authorization

- The auth library owns sessions, accounts, and providers. Don't hand-roll session
  management, password hashing, or JWT signing.
- Its tables belong to it. Don't write to them directly.
- **Route protection lives in middleware**, not in scattered per-controller checks. A
  check that has to be remembered in every handler will eventually be forgotten in one.

### Authorization is not authentication

Knowing *who* someone is doesn't establish *what they may touch*. Every handler that
takes a resource ID answers: can **this** user act on **this** resource? The most common
real-world vulnerability isn't a broken login — it's an authenticated user reading
someone else's record by changing an ID.

---

## Input

- Validate every external input at the boundary. See
  [errors-and-validation.md](errors-and-validation.md).
- Use the ORM's parameterized queries. No string-concatenated SQL, ever.
- Sanitize anything rendered as HTML.
- Rate-limit anything unauthenticated, anything that sends email, and anything expensive.

---

## Dependencies

- New dependency? It's new attack surface. Check
  [tech-stack.yaml](../../tech-stack.yaml) first and ask before adding.
- Never install from an untrusted source or a typo-adjacent package name.
- Don't `curl | sh`.

---

## When you find something

Found a vulnerability in existing code while doing unrelated work? **Report it. Don't
silently fix it.** A security fix buried in an unrelated diff gets no review from anyone
looking for security problems, which is exactly the review it needs.
