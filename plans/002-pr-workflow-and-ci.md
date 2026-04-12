# Plan 002: PR Workflow + CI + Install Diagnostics

**Status:** Ready to implement
**Created:** 2026-04-11
**Supersedes:** `001-pr-workflow-and-ci.md` (over-scoped)
**Vision:** [`002-vision.md`](./002-vision.md)

## Overview

7 files created, 2 files modified, delivered as 2 PRs. Gets the PR loop working with deterministic CI and makes install failures debuggable remotely.

### What this plan does NOT do

- Does not touch `.zshrc`, aliases, or shell functions
- Does not add AI to the merge gate — all AI is advisory/comment-only
- Does not require approvals on PRs — solo dev, CI status checks only
- Does not add YAML validation (3 YAML files don't justify a `yq` dependency)
- Does not use `scripts/ask` in CI (fragile auth, ARG_MAX risk)
- Does not add `CONTRIBUTING.md` (agents read `AGENTS.md`)

---

## Files to Create

### 1. `AGENTS.md` (repo root, <50 lines)

Cross-agent workflow instructions. Read by Copilot, Claude Code, Amp, Codex, and any agent that respects the convention.

Content:
- What the repo is (personal dotfiles, macOS ARM64 primary)
- Git workflow: always branch from main, never push to main, conventional commits, `gh pr create`
- Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `ci/` + kebab-case
- Key directories (one-liner each)
- Shell conventions: `set -euo pipefail`, `$HOME` not hardcoded, shellcheck clean
- Don't touch `.zshrc` aliases unless explicitly asked
- Run `scripts/ci/lint.sh` before pushing

No overlap with `claude/CLAUDE.md` — AGENTS.md covers workflow rules, CLAUDE.md covers communication and code style preferences.

### 2. `.github/copilot-instructions.md` (<4000 chars)

Two sections:

**Section 1 — General context** (for Copilot chat and coding agent):
- Project overview, directory structure, key conventions
- Condensed from AGENTS.md for Copilot's format

**Section 2 — Review calibration:**

This is the most valuable and hardest-to-get-right part of the whole plan. Copilot reviews on personal dotfiles repos are extremely noisy by default.

- This is a personal dotfiles repo. "Non-standard" is not a bug. Don't enforce external conventions.
- **Only flag:** secret exposure, broken symlinks, shell quoting bugs, portability issues (macOS/Linux), missing `set -euo pipefail` in new scripts
- **Don't flag:** style preferences on config files, missing tests, missing error handling, `.zshrc` aliases, `p10k.zsh` content (auto-generated), theme color values, spinner verb lists
- If a PR only touches config values (not scripts), the review should produce 0-2 comments max
- Terse tone. No praise, no "looks good overall" filler, no suggestions to add documentation.

**Tuning plan:** Review Copilot's actual comment output after 5-10 PRs. Adjust calibration section based on recurring false positives. This is an iterative process — the initial version is a best guess.

### 3. `.shellcheckrc` (repo root)

Minimal — shellcheck defaults are already good:

```shellcheckrc
# Repo-wide shellcheck defaults
# Add specific enable= directives after reviewing baseline output
```

**Why not `enable=all`:** It enables every optional check including very noisy ones (SC2250 for `$var` vs `${var}`, SC2312 for subshell masking in pipes). Existing scripts won't pass these. Start with defaults, add selectively later.

### 4. `scripts/ci/lint.sh`

Deterministic gate. Works locally on macOS and in CI on Ubuntu.

**Checks:**
1. **ShellCheck** — all discovered shell scripts
2. **bash -n** — same file set (syntax check only)
3. **JSON validation** — `jq empty` on all `.json` files excluding `.git/`

**No YAML validation.** Only 3 YAML files in the repo (lazygit themes). Not worth the `yq` dependency.

**File discovery strategy:**

Use `find` dynamically. The original plan's hardcoded file list was already stale (missed files, would break when new scripts are added).

```bash
# All .sh files (catches install.sh at root, scripts/**/*.sh, themes/*.sh, etc.)
find . -not -path './.git/*' -name '*.sh' -type f

# Extensionless scripts in known hook directories
find ./git/hooks ./claude/hooks -type f ! -name '.*' 2>/dev/null

# Extensionless scripts elsewhere: check shebang for bash
# (catches scripts/ask and any future extensionless scripts)
```

**Scoping rules:**
- Hook directories scoped to `./git/hooks/` and `./claude/hooks/` only — NOT `*/hooks/*` which would match oh-my-zsh hooks
- Extensionless scripts discovered by shebang check (`head -1 | grep -q bash`), not by hardcoding names
- `install.sh` at repo root caught by the `*.sh` glob
- `.zshrc` and `p10k.zsh` excluded (zsh, not bash)
- `lint.sh` self-checks itself — expected, note it in output

**Style:** `set -euo pipefail`, error counter (don't exit on first failure), emoji pass/fail per category, exit 0/1. Match `git/hooks/pre-commit` style.

### 5. `.github/workflows/ci.yml`

Single workflow, single job.

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install tools
        run: |
          sudo apt-get install -y shellcheck
          which jq || sudo apt-get install -y jq
      - name: Lint
        run: bash scripts/ci/lint.sh
```

- `jq` is pre-installed on `ubuntu-latest` today, but the `which jq ||` fallback is cheap insurance against runner image changes and self-documents the dependency
- The job name `lint` becomes the required status check for branch protection
- No other dependencies needed

### 6. `scripts/dotfiles-debug.sh`

Portable diagnostics script. Runnable standalone (`bash scripts/dotfiles-debug.sh`) or auto-fired by the install trap on failure.

**Outputs:**
- **OS info** — `uname -a`, `/etc/os-release` if it exists
- **Shell info** — `$SHELL`, zsh version, oh-my-zsh presence
- **Tool inventory** — for each expected tool, print installed version or `MISSING`:
  `shellcheck`, `jq`, `fzf`, `rg`, `bat`/`batcat`, `eza`/`exa`, `tmux`, `nvim`, `gh`, `lazygit`, `atuin`, `kubectl`, `brew`
- **Symlink health** — check each expected config symlink exists and points correctly
- **Disk and memory** — `df -h /`, `free -h` (Linux) or `vm_stat` summary (macOS)
- **Cloud-init logs** (Linux only) — tail last 50 lines of `/var/log/cloud-init-output.log` if present
- **Dotfiles status** — print `$HOME/.dotfiles-status` if it exists

**Style:** `set -euo pipefail`, clear section headers with emoji, works on both macOS and Linux. `chmod +x`.

### 7. `git/hooks/pre-push`

Block pushes to `main`/`master`. Style matches existing `git/hooks/pre-commit`.

- Read stdin for ref info (git provides `local_ref local_sha remote_ref remote_sha` per line)
- Extract remote branch name from `remote_ref`
- If it matches `main` or `master`, print helpful message pointing to `gh pr create` and exit 1
- Include `--no-verify` bypass note for emergencies
- `set -euo pipefail`, `chmod +x`

**Goes in PR #2** — must not exist until after the bootstrap PR is merged.

---

## Files to Modify

### `install.sh` — Add trap + status marker

**Location:** After all function definitions, before `main "$@"` (~line 441)

**What to add:** A trap that writes `$HOME/.dotfiles-status` on both success and failure, and auto-fires `dotfiles-debug.sh` on failure.

```bash
# --- Status marker (add before main "$@") ---
DOTFILES_STATUS_FILE="$HOME/.dotfiles-status"
trap '_exit_code=$?; if [[ $_exit_code -ne 0 ]]; then
  echo "status: failed" > "$DOTFILES_STATUS_FILE"
  echo "exit_code: $_exit_code" >> "$DOTFILES_STATUS_FILE"
  echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$DOTFILES_STATUS_FILE"
  echo "platform: $OS" >> "$DOTFILES_STATUS_FILE"
  echo ""
  echo "❌ Install failed (exit code $_exit_code). Debug info:"
  bash "$DOTFILES_DIR/scripts/dotfiles-debug.sh" 2>/dev/null || true
fi' EXIT

main "$@"

# Write success marker (only reached if main completes without set -e exit)
cat > "$DOTFILES_STATUS_FILE" <<EOF
status: success
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
platform: $OS
EOF
```

~15 lines added. The `main()` function body is not changed.

### `README.md` — Mention PR workflow

**Location:** After "Normal Development Loops" section (~line 72), or at the end of the development loops.

**Add:**

```markdown
### Contributing (humans and agents)

All changes go through pull requests. See [`AGENTS.md`](./AGENTS.md) for branch workflow, naming conventions, and CI requirements. Direct pushes to main are blocked by a pre-push hook.
```

3 lines. Ensures any agent or human reading the README knows this is now a PR-based repo.

---

## Implementation Order

### PR #1: Bootstrap CI + install diagnostics

The bootstrap PR. Must be merged before branch protection can reference the `lint` check.

```
 1. git checkout -b ci/pr-workflow
 2. Create: AGENTS.md
 3. Create: .github/copilot-instructions.md
 4. Create: .shellcheckrc
 5. Create: scripts/ci/lint.sh          (chmod +x)
 6. Create: .github/workflows/ci.yml
 7. Create: scripts/dotfiles-debug.sh   (chmod +x)
 8. Modify: install.sh                  (add trap + status marker)
 9. Modify: README.md                   (add PR workflow note)
10. Run:    bash scripts/ci/lint.sh     (verify locally — fix any findings)
11. Run:    bash -n install.sh          (verify syntax after edit)
12. Run:    bash scripts/dotfiles-debug.sh (verify readable output)
13. Commit — message body should reference plans/002-pr-workflow-and-ci.md
14. Push branch, gh pr create
15. Verify: CI runs and passes on the PR
16. Verify: Copilot review runs (if ruleset already configured)
17. Merge PR manually (no branch protection yet)
```

### Configure GitHub Settings (manual, between PRs)

**Settings -> General -> Pull Requests:**
- Squash merging only (disable merge commits and rebase)
- Enable auto-merge
- Automatically delete head branches

**Settings -> Branches -> Add rule for `main`:**
- Require pull request before merging — **no required approvals**
- Require status checks to pass: `lint`
- Require branches to be up to date before merging
- **Allow bypassing** (keep ON while iterating)
- No force pushes, no deletions

**Settings -> Rules -> Rulesets:**
- Create ruleset: auto-request Copilot code review on all PRs

**Settings -> Actions -> General:**
- Allow all actions and reusable workflows
- Workflow permissions: read and write
- Allow GitHub Actions to create and approve pull requests

**No secrets needed for M1.** CI is fully deterministic.

**Graduation criteria for disabling bypass:** After 10 successful PRs through the loop OR after auto-merge is enabled, whichever comes first.

### PR #2: Add pre-push hook

Validates the full loop end-to-end with branch protection active.

```
1. git checkout -b ci/pre-push-hook
2. Create: git/hooks/pre-push          (chmod +x)
3. Commit + push branch
4. gh pr create
5. Verify: CI passes, Copilot review requested, merge works
6. Merge
```

---

## Verification

**After PR #1 merged:**
- [ ] `lint` check appears green on the merged PR
- [ ] Copilot review ran (check for comments — note their noise level)
- [ ] Branch auto-deleted after merge
- [ ] `bash scripts/ci/lint.sh` passes locally
- [ ] `bash -n install.sh` passes
- [ ] `bash scripts/dotfiles-debug.sh` runs cleanly on macOS
- [ ] Simulate install failure: confirm `$HOME/.dotfiles-status` written with failure info and debug output printed

**After PR #2 merged + branch protection configured:**
- [ ] `git push origin main` rejected by pre-push hook locally
- [ ] Creating a new PR triggers CI automatically
- [ ] `lint` status check shows as required in PR checks
- [ ] Copilot review is auto-requested
- [ ] Merge succeeds after CI passes

**After 5-10 PRs (tuning phase):**
- [ ] Review Copilot comment patterns — identify recurring false positives
- [ ] Update `.github/copilot-instructions.md` review calibration
- [ ] Decide whether to enable auto-merge
- [ ] Disable "allow bypassing" per graduation criteria

---

## Files Summary

| File | Action | PR | Purpose |
|------|--------|-----|---------|
| `AGENTS.md` | Create | #1 | Cross-agent workflow rules |
| `.github/copilot-instructions.md` | Create | #1 | Copilot context + review calibration |
| `.shellcheckrc` | Create | #1 | Shellcheck config (minimal defaults) |
| `scripts/ci/lint.sh` | Create | #1 | Shellcheck + bash -n + JSON validation |
| `.github/workflows/ci.yml` | Create | #1 | GitHub Actions lint gate |
| `scripts/dotfiles-debug.sh` | Create | #1 | Portable install diagnostics |
| `install.sh` | Modify | #1 | Trap + status marker on success/failure |
| `README.md` | Modify | #1 | Note that repo uses PR workflow |
| `git/hooks/pre-push` | Create | #2 | Block direct pushes to main |

## Style References

- **Hook style:** `git/hooks/pre-commit` — `set -euo pipefail`, clear emoji messaging, pattern matching
- **Script style:** `install.sh` — function-per-concern, emoji status output, platform detection
- **Agent config style:** `claude/CLAUDE.md` — concise, rule-oriented, no fluff
