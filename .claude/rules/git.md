---
name: git
load_when: Branching, committing, or opening/splitting a PR.
---

# Git

## Branches

- Feature work: `feat/{feature-name}` — created **before** any implementation starts.
- Fixes: `fix/{short-description}`
- Never commit directly to `main`.
- **Never force-push or rebase a shared branch.**

## Commits

One commit per completed task. Every commit explains **intent**.

```
type(scope): description
```

Types: `feat` · `fix` · `refactor` · `docs` · `test` · `chore` · `perf`

Good:

```
feat(auth): implement refresh token rotation
fix(upload): prevent duplicate uploads
refactor(cache): isolate cache adapter
docs(api): explain webhook retries
```

Avoid: `update`, `fixes`, `changes`, `misc`, `wip`.

Under spec-driven development, add the trace so a future agent can reconstruct why:

```
feat(booking): add notification preferences

Task: 3 from specs/007-notifications/implementation.md
Tests: T-04, T-05
```

Documentation touched by the change ships **in the same commit**, never batched.

---

## Pull requests

### Size limit

Every PR must be reviewable in **under 10 minutes**:

- Max **5–7 files** changed (excluding tests)
- Max **500 lines** changed
- One focused change

Bigger than that, split it. This is not a guideline.

### Every PR answers

1. **Why?** — the problem, not the diff
2. **What changed?**
3. **Risks?**
4. **Breaking changes?**
5. **Migration steps?**

---

## Splitting large changes

Four ways to cut, in rough order of preference:

1. **By dependency order** — base infrastructure first, then what depends on it. Each PR
   merges on its own.
2. **By layer** — schema/migration, then backend logic, then frontend.
3. **By feature component** — API endpoint, then UI, then integration.
4. **Refactor before feature** — preparatory refactoring lands separately, *before* the
   new functionality.

### Examples

Instead of one large **"Add booking notifications"**:

- PR 1: notification preferences schema + migration
- PR 2: notification service + API endpoints
- PR 3: notification UI components
- PR 4: integrate into the booking flow

Instead of one large **"Refactor calendar sync"**:

- PR 1: extract sync logic into a dedicated service
- PR 2: add the provider abstraction
- PR 3: migrate existing providers onto it
- PR 4: add the new provider

Note the shape: each PR is independently mergeable and independently revertible. If PR 3
has to be rolled back, PRs 1 and 2 stay.

### Why smaller

- Faster review, quicker feedback
- Easier to locate and fix issues
- Lower merge-conflict risk
- Simpler to revert
- Better history, easier bisect

---

## Never

- Commit secrets, API keys, or `.env` files
- Force-push or rebase a shared branch
- Commit generated files edited by hand
- Mix a refactor and a feature in one PR
- Open a PR with failing tests
