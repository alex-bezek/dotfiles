---
name: review
description: Code review focused on Go and Kubernetes patterns. Use /review to review staged/changed files, or /review <path> for a specific file.
argument-hint: "[file-or-focus-area]"
user-invocable: true
allowed-tools: "Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(git status:*) Bash(go vet:*)"
---

# Code Review

Review the code changes for correctness, safety, and Go/Kubernetes best practices.

## What to review

- If `$ARGUMENTS` is a file path, review that file
- If `$ARGUMENTS` is a focus area (e.g., "security", "performance", "error-handling"), review changed files with that lens
- If no arguments, review all staged and unstaged changes (`git diff` + `git diff --cached`)

## Review checklist

### Correctness
- Logic errors, off-by-one, nil pointer dereference
- Missing error checks (`if err != nil`)
- Incorrect error wrapping (should use `%w` for errors that callers need to unwrap)
- Race conditions with shared state or goroutines

### Go patterns
- `context.Context` passed correctly (first param, not stored in structs)
- Deferred cleanup (`defer close`, `defer cancel`)
- Proper use of `sync` primitives
- No goroutine leaks (context cancellation, done channels)
- Slice/map initialization when size is known

### Kubernetes / controller-runtime
- Reconciler returns appropriate `Result{}` and requeue behavior
- Status updates use `StatusClient.Update`, not `Client.Update`
- Finalizer logic is correct (add on create, remove after cleanup)
- RBAC markers match actual API usage
- Watch predicates filter appropriately

### Safety
- No hardcoded secrets or credentials
- No SQL/command injection
- Validate external input at boundaries
- Check for path traversal in file operations

## Output format

For each finding:
1. **File and line** — `path/to/file.go:42`
2. **Severity** — critical / warning / nit
3. **What** — one-line description
4. **Why** — brief explanation of the risk or improvement
5. **Fix** — concrete suggestion (code snippet if helpful)

Group findings by file. Lead with critical issues. End with a one-line summary: "N findings (X critical, Y warnings, Z nits)" or "Looks good — no issues found."

Keep it concise. Don't praise code that's fine. Don't flag style preferences unless they cause bugs.
