# Rules

Detailed instructions, split so they load **only when relevant**. Putting all of this in
`CLAUDE.md` would burn context on every session for rules most tasks never touch.

## Index

| Rule | Load when |
|---|---|
| [core-principles.md](core-principles.md) | Always — before writing any code |
| [git.md](git.md) | Branching, committing, opening or splitting a PR |
| [testing.md](testing.md) | Writing or changing any test |
| [code-style.md](code-style.md) | Naming, structuring functions, module boundaries |
| [errors-and-validation.md](errors-and-validation.md) | Error handling, schemas, external input |
| [security.md](security.md) | Auth, secrets, credentials, user data, env files |
| [documentation.md](documentation.md) | Writing docs, ADRs, or module metadata |

`.claude/hooks/route-rules.sh` nudges the right file into context based on what the
prompt mentions, but it is a hint, not a guarantee. If a rule is relevant, read it.

## Adding a rule

1. Create `{name}.md` with frontmatter:

   ```yaml
   ---
   name: {name}
   load_when: {one line — the trigger, not the topic}
   ---
   ```

2. Run `bun run docs:sync` — the index here and in `CLAUDE.md` regenerates from the
   frontmatter.
3. Add keyword triggers to `.claude/hooks/route-rules.sh` if it should auto-surface.

Keep `load_when` phrased as a **trigger** ("Writing or changing any test") not a topic
("Testing"). The agent is matching against what it's about to do.

## Keeping them small

A rule file nobody finishes reading is a rule file nobody follows. If one exceeds ~150
lines, split it. Rules describe **decisions and prohibitions** — not tutorials on the
underlying technology.
