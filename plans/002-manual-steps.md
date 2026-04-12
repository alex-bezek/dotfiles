# Manual Steps: PR Workflow Setup

Steps that require human action — either before the agent starts, between PRs, or after completion. The agent prompt references this file and will tell you when each step is needed.

## Pre-Steps (Before Starting the Agent)

These must be done before giving the agent the implementation prompt.

### 1. Ensure `shellcheck` is installed locally

The agent needs to run `scripts/ci/lint.sh` locally to verify. On macOS:

```bash
brew install shellcheck
```

Verify: `shellcheck --version`

### 2. Ensure `jq` is installed locally

```bash
brew install jq
```

Verify: `jq --version`

### 3. Ensure clean working tree

The agent will create a branch. Commit or stash any uncommitted work first.

```bash
cd ~/code/dotfiles
git status        # should be clean or only have plans/ changes
git stash         # if needed
```

### 4. Ensure GitHub CLI is authenticated

The agent will use `gh pr create`. Verify:

```bash
gh auth status
```

If not authenticated: `gh auth login`

### 5. Commit the plans directory

The plans files should be on main before the agent branches, so the PR can reference them:

```bash
cd ~/code/dotfiles
git add plans/
git commit -m "docs: add PR workflow vision and implementation plans"
git push origin main
```

This is the **last direct push to main** you'll do. After PR #2, the pre-push hook blocks this.

---

## Between PR #1 and PR #2 (GitHub Settings)

The agent will pause and tell you to do these steps. They must be done in the GitHub web UI after PR #1 is merged and before PR #2 is created.

### 6. Configure Pull Request settings

**Go to:** `github.com/alex-bezek/dotfiles/settings` → General → Pull Requests

- [x] Allow squash merging (enable)
- [ ] Allow merge commits (disable)
- [ ] Allow rebase merging (disable)
- [x] Allow auto-merge (enable)
- [x] Automatically delete head branches (enable)

### 7. Configure branch protection

**Go to:** Settings → Branches → Add branch protection rule

- **Branch name pattern:** `main`
- [x] Require a pull request before merging
  - [ ] Require approvals — **leave OFF** (solo dev)
- [x] Require status checks to pass before merging
  - [x] Require branches to be up to date before merging
  - **Add required check:** `lint`
- [x] Allow bypassing the above settings — **leave ON for now**
  - Graduation: disable after 10 successful PRs or after enabling auto-merge
- [ ] Allow force pushes — OFF
- [ ] Allow deletions — OFF

### 8. Configure Copilot auto-review

**Go to:** Settings → Rules → Rulesets → New branch ruleset

- **Name:** Copilot Auto Review
- **Enforcement:** Active
- **Target:** All branches
- [x] Automatically request Copilot code review

### 9. Configure Actions permissions

**Go to:** Settings → Actions → General

- [x] Allow all actions and reusable workflows
- **Workflow permissions:** Read and write
- [x] Allow GitHub Actions to create and approve pull requests

### 10. Pull updated main locally

After PR #1 is merged, sync your local before PR #2:

```bash
git checkout main
git pull origin main
```

---

## After PR #2 Merged (Verification)

### 11. Verify pre-push hook works

```bash
git checkout main
echo "test" >> /tmp/test-push  # don't actually change files
git push origin main            # should be REJECTED by pre-push hook
```

### 12. Verify branch protection works

Create a trivial test PR to confirm the full loop:

```bash
git checkout -b test/verify-loop
echo "" >> README.md
git add README.md
git commit -m "test: verify PR loop (will close without merging)"
git push -u origin test/verify-loop
gh pr create --title "test: verify PR workflow loop" --body "Testing CI + Copilot review. Will close without merging."
```

Check:
- [ ] CI `lint` job runs and passes
- [ ] Copilot review is requested
- [ ] PR is mergeable after CI passes

Then close without merging:
```bash
gh pr close test/verify-loop --delete-branch
```

---

## Future: When Enabling Auto-Merge

When you're confident CI is reliable (after ~10 PRs):

1. Agents can add `--auto --squash` to their `gh pr merge` commands
2. PRs will auto-merge when CI passes (no human click needed)
3. Disable "Allow bypassing" in branch protection (graduation criteria met)
