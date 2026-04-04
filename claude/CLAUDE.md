# Global Preferences

## Communication
- Be concise. Sacrifice grammar for brevity in plans.
- Surface unresolved questions early — don't bury them at the end.
- When making a plan, always explain how you will verify the work.
- Lead with the answer or action, not the reasoning.
- Don't restate what I said — just do it.

## Code Style
- Don't add features, refactor, or "improve" beyond what was asked.
- Don't add abstractions for one-time operations. Three similar lines > premature abstraction.
- Don't add error handling for scenarios that can't happen.
- Don't add docstrings, comments, or type annotations to code you didn't change.
- Only add comments where logic isn't self-evident.

## Go
- I primarily work in Go.
- Use table-driven tests. Follow existing test patterns in the repo.
- Prefer `errors.New` / `fmt.Errorf` with `%w` over custom error types unless the repo already uses them.
- Use `context.Context` properly — pass it through, don't store it in structs.

## Git
- Write clear commit messages focused on "why" not "what".
- Prefer feature branches.
- Don't amend commits unless I ask.
