# Agent Prompt: Implement PR Workflow (Plan 002)

Copy everything below the line and give it to a fresh AI agent session.

---

## Your Task

Implement a PR-based workflow, deterministic CI pipeline, and install diagnostics for this personal dotfiles repo. This is a solo-dev repo managed by one human and multiple AI agents (Claude Code, Copilot, Amp, Codex).

**Read these files first, in order, before doing anything else:**
1. `plans/002-vision.md` — why we're doing this
2. `plans/002-pr-workflow-and-ci.md` — full specification for every file
3. This prompt — your execution playbook

**Ignore `plans/001-*.md` entirely.** Those are superseded drafts from an earlier iteration. Do not reference or implement anything from them. If you see contradictions between 001 and 002, **002 wins**.

## What You're Building

Two PRs that bootstrap a PR-based workflow from a repo that currently pushes directly to main.

### PR #1: Bootstrap CI + Install Diagnostics (8 deliverables)

| # | File | Action | What It Does |
|---|------|--------|-------------|
| 1 | `AGENTS.md` | Create | Cross-agent workflow rules (branch, PR, conventions). <50 lines. |
| 2 | `.github/copilot-instructions.md` | Create | Copilot context + review sensitivity calibration. <4000 chars. |
| 3 | `.shellcheckrc` | Create | Minimal shellcheck config. NO `enable=all`. |
| 4 | `scripts/ci/lint.sh` | Create | Shellcheck + `bash -n` + JSON validation. `chmod +x`. |
| 5 | `.github/workflows/ci.yml` | Create | GitHub Actions: single `lint` job on PRs and pushes to main. |
| 6 | `scripts/dotfiles-debug.sh` | Create | Portable install diagnostics (OS, tools, symlinks, disk). `chmod +x`. |
| 7 | `install.sh` | Modify | Add trap + `$HOME/.dotfiles-status` marker (~15 lines before `main "$@"`). |
| 8 | `README.md` | Modify | Add 3-line "Contributing" note pointing to AGENTS.md. |

### PR #2: Lock Down Main (1 deliverable)

| # | File | Action | What It Does |
|---|------|--------|-------------|
| 9 | `git/hooks/pre-push` | Create | Block direct pushes to main/master. `chmod +x`. |

**Why two PRs:** CI files must exist on `main` before any PR can run CI checks. PR #1 bootstraps CI. Between PRs, the owner configures GitHub branch protection. PR #2 validates the full loop end-to-end.

---

## Hard Rules

- **Read `plans/002-pr-workflow-and-ci.md` before writing any code.** Every file, behavior, and design decision is specified there.
- **Match existing code style.** Read these before writing:
  - `git/hooks/pre-commit` — hook style (`set -euo pipefail`, emoji messaging)
  - `install.sh` — script style (function-per-concern, platform detection, emoji output)
  - `claude/CLAUDE.md` — agent config style (concise, rule-oriented)
- **Do NOT modify `.zshrc`** or any shell aliases/functions.
- **Do NOT create `CONTRIBUTING.md`.** Workflow rules go in `AGENTS.md` only.
- **Do NOT use `enable=all` in `.shellcheckrc`.** Deliberate decision — defaults are fine, `enable=all` is too noisy.
- **Do NOT add YAML validation to `lint.sh`.** Only 3 YAML files in the repo, not worth the `yq` dependency.
- **Do NOT hardcode file lists in `lint.sh`.** Use dynamic `find` with shebang detection. See spec below.
- **All new scripts must be `chmod +x`.**
- **Ignore `plans/001-*.md` files.** They are superseded drafts.

---

## Detailed Specifications

These are condensed from `plans/002-pr-workflow-and-ci.md`. If anything here seems ambiguous, the plan file is authoritative.

### AGENTS.md

Under 50 lines. Content:
- What the repo is (personal dotfiles, macOS ARM64 primary, also Linux/Codespaces/devcontainers)
- Git workflow: always branch from `main`, never push to main, conventional commits (`feat:`, `fix:`, `chore:`, `docs:`, `ci:`), create PRs via `gh pr create`
- Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `ci/` + short kebab-case
- Key directories: one-liner per top-level dir explaining what it manages
- Shell conventions: `set -euo pipefail`, use `$HOME` not hardcoded paths, shellcheck clean
- Don't touch: `.zshrc` aliases/functions unless explicitly asked
- Before pushing: run `scripts/ci/lint.sh`

**No overlap with `claude/CLAUDE.md`** — AGENTS.md is workflow rules, CLAUDE.md is communication and style preferences.

### .github/copilot-instructions.md

Under 4000 characters. Two sections:

**Section 1 — General context:** Project overview, directory structure, key conventions. Condensed from AGENTS.md.

**Section 2 — Review calibration (the most important part):**
- This is a personal dotfiles repo. "Non-standard" is not a bug.
- **Only flag:** secret exposure, broken symlinks, shell quoting bugs, portability issues (macOS vs Linux), missing `set -euo pipefail` in new scripts
- **Don't flag:** style preferences on config files, missing tests, missing error handling, `.zshrc` aliases, `p10k.zsh` content (auto-generated 86KB file), theme color values, spinner verb lists, lack of documentation
- Config-only PRs (no scripts): 0-2 comments max
- Tone: terse, no praise, no "looks good overall" filler

### .shellcheckrc

Minimal:
```
# Repo-wide shellcheck defaults
# Add specific enable= directives after reviewing baseline output
```

### scripts/ci/lint.sh

Deterministic gate. Must work on both macOS (local) and Ubuntu (CI).

**Checks:**
1. **ShellCheck** — all discovered shell scripts
2. **`bash -n`** — same file set (syntax check only)
3. **JSON validation** — `jq empty` on all `.json` files excluding `.git/`

**File discovery (critical — do this right):**

```bash
# 1. All .sh files in repo (catches install.sh at root, scripts/**/*.sh, themes/*.sh)
find . -not -path './.git/*' -name '*.sh' -type f

# 2. Extensionless scripts in SPECIFIC hook directories only
find ./git/hooks ./claude/hooks -type f ! -name '.*' 2>/dev/null

# 3. Extensionless scripts elsewhere with bash shebang
#    (catches scripts/ask and future extensionless scripts)
#    Check: head -1 "$file" | grep -q '#!/.*bash'
```

**Scoping rules:**
- Hook paths: `./git/hooks/` and `./claude/hooks/` ONLY. Do NOT use `*/hooks/*` — that matches oh-my-zsh hooks.
- Extensionless scripts: detect via shebang, don't hardcode filenames.
- `install.sh` at repo root: caught by `*.sh` glob (confirm `find .` includes root-level files).
- Exclude: `.zshrc` and `p10k.zsh` (zsh, not bash — shellcheck doesn't support zsh).
- `lint.sh` checks itself — expected and fine, note it in output.

**Style:** `set -euo pipefail`, error counter (don't `set -e` exit on first failure), emoji pass/fail per category, exit 0 if all pass / exit 1 if any fail.

### .github/workflows/ci.yml

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

The `which jq ||` fallback is intentional — `jq` is pre-installed today but runner images change.

### scripts/dotfiles-debug.sh

Portable diagnostics. Runnable standalone or auto-fired by install trap on failure.

**Sections to output:**
- **OS info** — `uname -a`, `/etc/os-release` if exists
- **Shell info** — `$SHELL`, zsh version, oh-my-zsh status
- **Tool inventory** — for each tool, print version or `MISSING`: `shellcheck`, `jq`, `fzf`, `rg`, `bat`/`batcat`, `eza`/`exa`, `tmux`, `nvim`, `gh`, `lazygit`, `atuin`, `kubectl`, `brew`
- **Symlink health** — check each expected config symlink target exists and points correctly
- **Disk and memory** — `df -h /`, `free -h` (Linux) or vm_stat summary (macOS)
- **Cloud-init logs** (Linux only) — tail last 50 lines of `/var/log/cloud-init-output.log` if present
- **Dotfiles status** — print `$HOME/.dotfiles-status` if exists

Works on both macOS and Linux. `set -euo pipefail`, emoji section headers, `chmod +x`.

### install.sh modification

**Location:** After all function definitions, before `main "$@"` (around line 441).

**Add this block:**
```bash
# Status marker — written on both success and failure for remote debugging
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

# Write success marker (only reached if main completes without error)
cat > "$DOTFILES_STATUS_FILE" <<EOF
status: success
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
platform: $OS
EOF
```

This replaces the bare `main "$@"` at the end of the file. Do NOT change anything inside the `main()` function body. The existing `echo "✨ Dotfiles setup complete!"` inside main stays as-is.

### README.md modification

Find the "Normal Development Loops" section (~line 72). Add after it (or at the end of the development loops):

```markdown
### Contributing (humans and agents)

All changes go through pull requests. See [`AGENTS.md`](./AGENTS.md) for branch workflow, naming conventions, and CI requirements. Direct pushes to main are blocked by a pre-push hook.
```

### git/hooks/pre-push (PR #2 only)

Style matches existing `git/hooks/pre-commit`:
- `#!/usr/bin/env bash` + `set -euo pipefail`
- Read stdin line by line (git provides `local_ref local_sha remote_ref remote_sha`)
- Extract remote branch name from `remote_ref`
- If matches `main` or `master`: print message pointing to `gh pr create`, exit 1
- Include `--no-verify` bypass note
- `chmod +x`

---

## Execution Phases

### Phase 1: Read and Understand

Read these files in order:
1. `plans/002-vision.md`
2. `plans/002-pr-workflow-and-ci.md`
3. `git/hooks/pre-commit` — style reference for hooks and lint targets
4. `install.sh` — style reference, find the `main "$@"` insertion point
5. `claude/CLAUDE.md` — style reference for agent config files
6. `README.md` — find the "Normal Development Loops" section for insertion point
7. Skim `ls scripts/`, `ls .agents/`, `ls git/hooks/` to understand existing structure

**CHECKPOINT 1 — Tell the owner:**
> I've read the plans and style references. Here's my understanding: [1-2 sentence summary]. Ready to start implementation. [Any questions or concerns].

If anything is unclear, ask NOW — not mid-implementation.

### Phase 2: Create Branch

```bash
git checkout -b ci/pr-workflow
```

### Phase 3: Implement PR #1 Files

Create files in this order. After each file, briefly tell the owner what you created.

**Step 1: AGENTS.md**
- Write it. Under 50 lines.
- Tell owner: "Created AGENTS.md — [1-line summary]"

**Step 2: .github/copilot-instructions.md**
- Write it. Under 4000 chars. The review calibration section is the hardest part.
- **CHECKPOINT 2 — Tell the owner:**
  > Created copilot-instructions.md. Here's the review calibration section for your review:
  > [paste the full Section 2 text]
  >
  > This controls what Copilot flags on PRs. Want to adjust anything before I continue?
- **Wait for owner acknowledgment.** This is the most consequential file — the owner may want to tweak thresholds.

**Step 3: .shellcheckrc**
- Write it. Two comment lines. Move on.

**Step 4: scripts/ci/lint.sh**
- Write it following the file discovery strategy above.
- `chmod +x scripts/ci/lint.sh`
- **Run it immediately:**
  ```bash
  bash scripts/ci/lint.sh
  ```
- If shellcheck flags issues in **existing** scripts:
  - Fix the specific lines shellcheck flags
  - Do NOT refactor surrounding code
  - If fixing would change runtime behavior, add `# shellcheck disable=SCXXXX` with a reason
- If shellcheck flags issues in **your new** scripts: fix them, no disable comments.
- Re-run until clean.
- Tell owner: "lint.sh passes. [N] files checked. [Notable findings and resolutions, if any]."

**Step 5: .github/workflows/ci.yml**
- Write it matching the spec above.

**Step 6: scripts/dotfiles-debug.sh**
- Write it. `chmod +x`.
- **Run it:**
  ```bash
  bash scripts/dotfiles-debug.sh
  ```
- Tell owner: "Debug script runs cleanly. Sample output: [first 15-20 lines]"

**Step 7: Modify install.sh**
- Add the trap + status marker block before `main "$@"`.
- Do NOT change anything inside `main()`.
- **Verify syntax:**
  ```bash
  bash -n install.sh
  ```
- Tell owner: "Modified install.sh — added trap at line [N]. `bash -n` passes."

**Step 8: Modify README.md**
- Add the 3-line Contributing section.

### Phase 4: Full Local Verification

Run all checks:

```bash
# 1. Full lint pass
bash scripts/ci/lint.sh

# 2. install.sh syntax
bash -n install.sh

# 3. Debug script
bash scripts/dotfiles-debug.sh > /dev/null && echo "debug script OK"

# 4. All new scripts are executable
for f in scripts/ci/lint.sh scripts/dotfiles-debug.sh; do
  [[ -x "$f" ]] && echo "OK $f" || echo "NOT EXECUTABLE: $f"
done

# 5. All files exist
for f in AGENTS.md .github/copilot-instructions.md .shellcheckrc \
         scripts/ci/lint.sh .github/workflows/ci.yml \
         scripts/dotfiles-debug.sh; do
  [[ -f "$f" ]] && echo "OK $f" || echo "MISSING: $f"
done
```

**CHECKPOINT 3 — Tell the owner:**
> All local verification passes:
> - lint.sh: [pass/fail, N files]
> - bash -n install.sh: [pass/fail]
> - debug script: [pass/fail]
> - All files present and executable
>
> Ready to commit and create PR #1.

### Phase 5: Commit and Create PR #1

```bash
git add AGENTS.md .github/copilot-instructions.md .shellcheckrc \
       scripts/ci/lint.sh .github/workflows/ci.yml \
       scripts/dotfiles-debug.sh install.sh README.md

git commit -m "$(cat <<'EOF'
ci: add PR workflow with lint CI, agent instructions, and install diagnostics

Implements M1 of the AI-driven workflow vision (plans/002-vision.md):
- AGENTS.md: cross-agent workflow rules (branch, PR, conventions)
- .github/copilot-instructions.md: Copilot review calibration for dotfiles
- scripts/ci/lint.sh: shellcheck + bash syntax + JSON validation
- .github/workflows/ci.yml: GitHub Actions lint gate
- scripts/dotfiles-debug.sh: portable install diagnostics
- install.sh: trap writes $HOME/.dotfiles-status on success/failure
- README.md: note about PR-based workflow

Spec: plans/002-pr-workflow-and-ci.md
EOF
)"

git push -u origin ci/pr-workflow

gh pr create --title "ci: add PR workflow with lint CI, agent instructions, and install diagnostics" --body "$(cat <<'EOF'
## Summary

Implements M1 of the AI-driven workflow vision (`plans/002-vision.md`):

- **`AGENTS.md`** — cross-agent workflow rules: always branch, conventional commits, `gh pr create`
- **`.github/copilot-instructions.md`** — Copilot context + review sensitivity calibration for personal dotfiles
- **`scripts/ci/lint.sh`** — deterministic gate: shellcheck, `bash -n`, `jq empty` on all JSON
- **`.github/workflows/ci.yml`** — single `lint` job, runs on all PRs and pushes to main
- **`scripts/dotfiles-debug.sh`** — portable diagnostics (OS, tools, symlinks, disk, cloud-init)
- **`install.sh`** — trap writes `$HOME/.dotfiles-status` on success/failure, auto-runs debug on crash
- **`README.md`** — notes the repo now uses PR workflow

## What's next

After this PR merges:
1. Configure GitHub branch protection (see `plans/002-manual-steps.md` steps 6-9)
2. PR #2 adds `git/hooks/pre-push` to block direct pushes to main
3. PR #2 validates the full CI + Copilot review loop end-to-end

## Test plan

- [x] `bash scripts/ci/lint.sh` passes locally
- [x] `bash -n install.sh` passes
- [x] `bash scripts/dotfiles-debug.sh` runs cleanly
- [ ] CI `lint` job passes on this PR
- [ ] Copilot review is requested (if ruleset configured)

Full spec: `plans/002-pr-workflow-and-ci.md`
EOF
)"
```

**CHECKPOINT 4 (STOP) — Tell the owner:**

> PR #1 is created: [paste the PR URL from gh output]
>
> **I need you to do these things before I can continue with PR #2:**
>
> 1. **Check the PR on GitHub** — verify the CI `lint` job passes. Check Copilot review comments if any appeared (note their noise level for future calibration).
> 2. **Merge PR #1** manually on GitHub.
> 3. **Configure GitHub settings** (do all of these in the GitHub web UI):
>
>    **Settings → General → Pull Requests:**
>    - Enable squash merging only (disable merge commits and rebase)
>    - Enable auto-merge
>    - Enable automatically delete head branches
>
>    **Settings → Branches → Add branch protection rule for `main`:**
>    - Require pull request before merging (no required approvals)
>    - Require status checks to pass: add `lint`
>    - Require branches to be up to date
>    - Allow bypassing — leave ON for now
>    - No force pushes, no deletions
>
>    **Settings → Rules → Rulesets → New branch ruleset:**
>    - Name: "Copilot Auto Review", Enforcement: Active, Target: All branches
>    - Enable: Automatically request Copilot code review
>
>    **Settings → Actions → General:**
>    - Allow all actions and reusable workflows
>    - Workflow permissions: Read and write
>    - Allow GitHub Actions to create and approve pull requests
>
> 4. **Pull updated main locally:**
>    ```bash
>    git checkout main && git pull origin main
>    ```
>
> 5. **Tell me when done** and I'll create PR #2.

**Do not proceed until the owner confirms.**

### Phase 6: Create PR #2 (Pre-Push Hook)

```bash
git checkout main
git pull origin main
git checkout -b ci/pre-push-hook
```

Create `git/hooks/pre-push`:
- Re-read `git/hooks/pre-commit` for style reference
- Write the hook per the spec above
- `chmod +x git/hooks/pre-push`

Verify:
```bash
shellcheck git/hooks/pre-push
bash scripts/ci/lint.sh
```

Commit and push:
```bash
git add git/hooks/pre-push
git commit -m "ci: add pre-push hook to block direct pushes to main"
git push -u origin ci/pre-push-hook

gh pr create --title "ci: add pre-push hook to block direct pushes to main" --body "$(cat <<'EOF'
## Summary

Adds a pre-push hook that blocks direct pushes to `main`/`master` with a helpful message pointing to `gh pr create`. Bypass with `--no-verify` for emergencies.

Second and final PR for M1 (`plans/002-pr-workflow-and-ci.md`). Validates the full PR loop: CI gate + Copilot review + branch protection.

## Test plan

- [x] `shellcheck git/hooks/pre-push` passes
- [x] `bash scripts/ci/lint.sh` passes with new hook
- [ ] CI `lint` job passes
- [ ] Copilot review runs
- [ ] Branch protection requires `lint` before merge
EOF
)"
```

**CHECKPOINT 5 (FINAL STOP) — Tell the owner:**

> PR #2 is created: [paste PR URL]
>
> This validates the full workflow loop. Please:
> 1. Check that CI `lint` passes on the PR
> 2. Check that Copilot review is auto-requested
> 3. Check that branch protection shows `lint` as required
> 4. Merge the PR
>
> After merging, verify locally:
> ```bash
> git checkout main && git pull origin main
> git push origin main   # should be REJECTED by pre-push hook
> ```
>
> **M1 is complete.** The PR workflow is live. Future changes go through PRs.

---

## Checkpoint Summary

| # | When | What You Do | What Owner Does |
|---|------|-------------|----------------|
| 1 | After reading plans | Confirm understanding, ask questions | Answer questions |
| 2 | After copilot-instructions.md | Show review calibration section | Review and approve/adjust |
| 3 | After all local verification | Report test results | Acknowledge |
| 4 | After PR #1 created | **STOP.** Report PR URL. | Merge PR, configure GitHub settings, pull main |
| 5 | After PR #2 created | **STOP.** Report PR URL. | Merge PR, verify pre-push hook, done |

## If Things Go Wrong

| Problem | Action |
|---------|--------|
| `lint.sh` fails on existing scripts | Fix the flagged lines only. `# shellcheck disable=SCXXXX` if fix would change behavior. Don't refactor surrounding code. |
| CI fails on the PR | Read the Actions log. Fix the issue. Push a fix commit to the same branch. Don't force-push. |
| Copilot review is very noisy | Note the specific false positives. Tell the owner. They may adjust `copilot-instructions.md` before merging. |
| `install.sh` syntax breaks after edit | Quoting issue in the trap. Check with `bash -n install.sh`. The heredoc and trap quoting are tricky — test carefully. |
| `find` in lint.sh picks up unexpected files | Run `bash scripts/ci/lint.sh 2>&1 | head -50` to see what it found. Scope the find patterns narrower — don't add blanket excludes. |
| Owner doesn't respond at a checkpoint | Wait. Don't proceed past STOP checkpoints without explicit owner confirmation. |
