# Plan 001: PR-Based Workflow, Deterministic CI, and Doc Drift Auditor

**Status:** Draft
**Created:** 2026-04-11
**Goal:** Transform this repo from push-to-main into a PR-based workflow with deterministic CI gates and AI-powered scheduled workflows. The deterministic CI gate makes auto-merge safe; the AI workflows create a discovery and improvement loop that runs without manual intervention.

## Overview

Four deliverables, in dependency order:

1. **PR-first guardrails** — pre-push hook, contributor docs, agent instructions
2. **Deterministic CI** — shellcheck, syntax checks, JSON/YAML validation via GitHub Actions
3. **Doc ↔ Config Drift Auditor** — weekly scheduled AI workflow that opens an issue when docs and configs diverge
4. **AI Tool Discovery** — bi-weekly scheduled workflow that finds new AI/terminal tools on GitHub, evaluates relevance, and opens categorized issues (designed to feed into Copilot coding agent)

### What this plan does NOT do

- Does **not** touch any existing shell aliases or functions (`.zshrc` is read-only for this plan)
- Does **not** add AI to the merge gate — all AI is advisory/comment-only
- Does **not** require approvals on PRs — solo dev gates on CI status checks only
- Does **not** replace existing tools (`verify.sh`, `sync-to-dotfiles.sh`, etc.)

---

## Part 1: PR-First Guardrails

### 1a. Create `git/hooks/pre-push`

A hook that blocks direct pushes to `main`/`master`. This lives alongside the existing `pre-commit` hook and is automatically applied via the existing `core.hooksPath` setting in `install.sh` (line 273).

**File:** `git/hooks/pre-push`

**Behavior:**
- Read stdin (git provides `local_ref local_sha remote_ref remote_sha` per ref)
- Extract the remote branch name from `remote_ref`
- If it matches `main` or `master`, print a helpful message and exit 1
- Otherwise, allow the push
- Include `--no-verify` bypass note for emergencies
- Follow the same style as the existing `pre-commit` hook: `set -euo pipefail`, clear emoji-based messaging

**Important:** Make the hook executable (`chmod +x`).

### 1b. Create `CONTRIBUTING.md`

A short document describing the development workflow for this repo. This is read by both humans and AI agents (GitHub Copilot, Claude, Amp, etc.).

**File:** `CONTRIBUTING.md` (repo root)

**Content should cover:**
- **Branch workflow:** Always create a feature branch. Never push directly to main.
- **Branch naming:** `feat/`, `fix/`, `chore/`, `docs/`, `ci/` prefixes with short kebab-case descriptions
- **Commits:** Conventional commit format (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `ci:`)
- **PRs:** Use `gh pr create` to open PRs. Squash merge only. Branches auto-delete after merge.
- **Auto-merge:** After CI passes, PRs can be auto-merged with `gh pr merge --auto --squash`
- **CI:** All PRs must pass lint + install smoke tests before merging
- **AI agents:** Copilot auto-reviews all PRs (advisory, non-blocking). Agent workflows may comment with suggestions.
- **Bypass:** `git push --no-verify` for emergencies. Use sparingly.
- **Note:** This is a personal dotfiles repo. The PR workflow exists to enable AI review and CI, not for human code review bureaucracy.

Keep it concise — under 60 lines.

### 1c. Create `AGENTS.md`

Instructions for AI coding agents working in this repo. This is the cross-agent equivalent of `CLAUDE.md` — it's read by Amp, Copilot, Codex, and any other agent that respects the convention.

**File:** `AGENTS.md` (repo root)

**Content should cover:**
- **Git workflow:** Always create a feature branch first. Never commit to or push to main. Use conventional commits. Create a PR via `gh pr create` when done.
- **What this repo is:** Personal dotfiles managing zsh, Ghostty, tmux, lazygit, nvim, git hooks, themes, and AI agent configs. Primary OS is macOS ARM64.
- **Conventions:** Shell scripts use `set -euo pipefail`. Don't hardcode `/Users/alex` — use `$HOME`. Follow existing patterns in neighboring files.
- **Testing:** Run `scripts/ci/lint.sh` locally before pushing. Run `shellcheck` on any modified `.sh` files.
- **Don't touch:** `.zshrc` aliases/functions unless explicitly asked. The `ga`/`gc`/`gp` functions are muscle memory.
- **Key directories:** Brief one-liner for each top-level directory explaining what it manages.

Keep it concise — under 50 lines.

### 1d. Create `.github/copilot-instructions.md`

GitHub Copilot-specific instructions, used for both chat and code review. Limit: 4000 characters.

**File:** `.github/copilot-instructions.md`

**Content should cover:**
- Project overview (personal dotfiles, macOS ARM64 primary)
- File structure (one-liner per directory)
- Code conventions (shellcheck, `set -euo pipefail`, `$HOME` not hardcoded paths)
- When reviewing PRs: focus on portability, idempotency, secret exposure, symlink correctness, shell quoting
- Don't suggest changes to `.zshrc` aliases unless the PR explicitly modifies them

---

## Part 2: Deterministic CI

### 2a. Create `.shellcheckrc`

**File:** `.shellcheckrc` (repo root)

**Content:**
```
# Follow source directives
enable=all
# Zsh is not supported by shellcheck — exclude .zshrc and p10k.zsh
# (handled by the lint script, not this file)
```

Keep it minimal. The lint script handles file selection.

### 2b. Create `scripts/ci/lint.sh`

A single lint script that runs locally AND in CI. GitHub Actions will call this script directly.

**File:** `scripts/ci/lint.sh`

**Behavior:**
1. **ShellCheck** — Find all `.sh` files in the repo (excluding `.git/`). Run `shellcheck` on each. The `pre-commit` and `pre-push` hooks in `git/hooks/` should also be checked (they're bash despite no `.sh` extension). Exclude `.zshrc` and `p10k.zsh` (zsh, not bash — shellcheck doesn't support zsh).
2. **Bash syntax** — Run `bash -n` on all `.sh` files and hook scripts. Same exclusions.
3. **JSON validation** — Find all `.json` files (excluding `.git/`). Run `jq empty` on each.
4. **YAML validation** — Find all `.yml`/`.yaml` files (excluding `.git/`). Run `yq eval '.' > /dev/null` on each. (Use `yq` not `yamllint` — simpler dependency. If `yq` isn't available, fall back to basic syntax check or skip with warning.)

**Style:**
- `set -euo pipefail`
- Track errors with a counter, don't exit on first failure
- Print clear pass/fail per category with emoji (match existing script style)
- Exit 0 if all pass, exit 1 if any fail
- Make it work on both macOS and Linux

**File list for shellcheck/bash-n (be explicit):**
```
install.sh
themes/switch-theme.sh
claude/bootstrap.sh
claude/hooks/brain-sync.sh
claude/hooks/guard-destructive.sh
claude/hooks/guard-secrets.sh
claude/hooks/inject-context.sh
claude/hooks/notify.sh
claude/install-claude.sh
claude/refresh.sh
claude/statusline.sh
claude/sync-to-dotfiles.sh
claude/verify.sh
git/hooks/pre-commit
git/hooks/pre-push  (will exist after 1a)
scripts/ci/lint.sh  (self-check)
```

### 2c. Create `.github/workflows/ci.yml`

The GitHub Actions workflow. Calls `scripts/ci/lint.sh`.

**File:** `.github/workflows/ci.yml`

**Triggers:**
- `pull_request` (all branches)
- `push` to `main` (so checks exist for branch protection to reference)

**Jobs:**

#### Job: `lint`
- **Runner:** `ubuntu-latest`
- **Steps:**
  1. `actions/checkout@v4`
  2. Install tools: `sudo apt-get install -y shellcheck jq`
  3. Install yq (pin to mikefarah/yq — do NOT use apt, which installs an incompatible Python wrapper):
     ```bash
     YQ_VERSION="v4.44.3"
     curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
       -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
     ```
  4. Run `bash -n install.sh` (syntax check only — no execution)
  5. Run `bash scripts/ci/lint.sh`

**Notes:**
- This single `lint` job is the required status check for branch protection. Keep it fast and noise-free.
- Install smoke tests (actually running `install.sh` in CI) are deferred to a future milestone — they require significant `CI=true` guards and matrix iteration that would make the initial CI gate noisy.

---

## Part 3: Doc ↔ Config Drift Auditor

### 3a. Create `.github/workflows/doc-config-drift.yml`

A weekly scheduled workflow that uses `scripts/ask` (backed by Claude) to compare config files against their paired documentation and open an issue if drift is found.

**File:** `.github/workflows/doc-config-drift.yml`

**Triggers:**
- `schedule: cron: '0 9 * * 1'` (Monday 9am UTC)
- `workflow_dispatch` (manual trigger for testing)

**Job: `audit`**
- **Runner:** `ubuntu-latest`
- **Permissions:** `contents: read`, `issues: write`
- **Steps:**
  1. `actions/checkout@v4`
  2. Install Claude CLI: `npm install -g @anthropic-ai/claude-code` (needed for `claude -p` backend)
  3. Run `scripts/ai/collect-doc-drift-context.sh /tmp/drift-context.txt`
  4. Build prompt file combining context + instructions, then run:
     ```bash
     export ANTHROPIC_API_KEY="${{ secrets.ANTHROPIC_API_KEY }}"
     ASK_BACKEND=claude scripts/ask --raw "$(cat /tmp/drift-prompt.txt)" > drift-report.md
     ```
  5. Check if there's already an open issue with label `doc-drift` — if so, skip creating a new one
  6. If drift was found (report is non-empty / not "no drift"), create issue via `gh issue create`:
     - Title: `[doc-drift] Weekly documentation consistency report — YYYY-MM-DD`
     - Label: `doc-drift`
     - Body: the drift report content

**Auth:** Requires `ANTHROPIC_API_KEY` secret (Anthropic API key). Uses built-in `GITHUB_TOKEN` for issue creation — no PAT needed.

### 3b. Create `scripts/ai/collect-doc-drift-context.sh`

A helper script that gathers config+doc pairs into a single context file for the AI to analyze. This keeps the workflow YAML clean.

**File:** `scripts/ai/collect-doc-drift-context.sh`

**Behavior:**
- Work from an **explicit include list** — do not glob the whole repo
- For each config/doc pair, output a section like:
  ```
  === CONFIG: .zshrc ===
  <file contents>
  === PAIRED DOC: README.md (sections: "Daily development", "Shortcuts") ===
  <relevant sections>
  ```
- Before `cat`-ing any file, check its size: if >50KB, print `[SKIPPED: file exceeds 50KB size limit]` instead
- **Always skip:** `p10k.zsh` (86KB, auto-generated config — not meaningful to document), `.git/`, `node_modules/`
- Write output to a path provided as `$1` (e.g., `/tmp/drift-context.txt`)

**Explicit include list** (config → paired doc):
```
.zshrc → README.md
ghostty/config → README.md
tmux/tmux.conf → tmux/CHEATSHEET.md, README.md
lazygit/config.yml → lazygit/CHEATSHEET.md, README.md
install.sh → README.md
claude/README.md → claude/README.md (self-check)
git/hooks/pre-commit → README.md
scripts/ask → README.md
```

### 3c. Create label via setup script

**File:** `scripts/setup-github-labels.sh`

A one-time script to create the `doc-drift` label on the GitHub repo:
```bash
gh label create doc-drift --description "Automated doc/config drift report" --color "d4c5f9" --force
```

Also create labels for future workflows:
- `doc-drift` — purple
- `ci` — green
- `automation` — blue

---

## Part 4: GitHub Settings (Manual — User Action Required)

After the CI workflow has run at least once on a PR and the check names are visible:

### Repository Settings

**Settings → General → Pull Requests:**
- ✅ Allow squash merging (ONLY — disable merge commits and rebase)
- ✅ Allow auto-merge
- ✅ Automatically delete head branches

**Settings → Branches → Add branch protection rule:**
- Branch name pattern: `main`
- ✅ Require a pull request before merging
  - ❌ Require approvals (OFF — solo dev, you can't approve your own PR)
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging
  - Required checks: `lint` (add `install-smoke` later once stable)
- ✅ Do not allow bypassing the above settings (CRITICAL — this applies rules to you as admin)
- ❌ Allow force pushes (OFF)
- ❌ Allow deletions (OFF)

**Settings → Rules → Rulesets → New branch ruleset:**
- Name: "Copilot Auto Review"
- Enforcement: Active
- Target: All branches
- ✅ Automatically request Copilot code review

**Settings → Actions → General:**
- ✅ Allow all actions and reusable workflows
- Workflow permissions: Read and write
- ✅ Allow GitHub Actions to create and approve pull requests

### Secrets

**Settings → Secrets and variables → Actions:**
- `ANTHROPIC_API_KEY` — Anthropic API key, used by both the doc-drift auditor and the AI tool discovery workflow via `scripts/ask --backend claude`

---

---

## Part 4: AI Tool Discovery Workflow

A bi-weekly scheduled workflow that searches GitHub for new AI and terminal tools, evaluates them for relevance to this dotfiles repo, and opens categorized issues. Issues are designed to optionally be picked up by the Copilot coding agent (user assigns issue to `@copilot` → Copilot creates PR → CI validates → auto-merges).

### 4a. Create `scripts/ai/discover-ai-tools.sh`

**File:** `scripts/ai/discover-ai-tools.sh`

**Behavior:**
- Run several `gh search repos` queries targeting recent AI/terminal tooling
- Deduplicate results by repo full name
- Filter out: repos with <50 stars, repos not updated in the last 90 days
- For each remaining repo: output name, description, star count, URL, topics
- Output is plain text, one block per repo — this becomes the `<CANDIDATES>` section of the LLM prompt

**Queries to run** (each with `--json name,fullName,description,stargazersCount,url,repositoryTopics,updatedAt`):
```bash
gh search repos --topic mcp-server    --sort updated --limit 20
gh search repos --topic claude-mcp    --sort updated --limit 15
gh search repos --topic copilot-extension --sort updated --limit 15
gh search repos "ai terminal cli"     --sort updated --limit 15
gh search repos "llm shell agent"     --sort updated --limit 10
gh search repos "mcp client"          --sort updated --limit 10
```

### 4b. Create `scripts/prompts/discovery.md`

The system prompt used for tool evaluation. Informs the LLM of the repo context and specifies the output format.

**File:** `scripts/prompts/discovery.md`

**Content:**
```
You are evaluating new GitHub AI tools for a personal macOS dotfiles repo.

The repo manages: zsh config, Ghostty terminal, tmux, lazygit, nvim, git hooks,
and AI agent configs for Claude Code, GitHub Copilot, Codex, Amp, and opencode.
Primary: macOS ARM64 development workstation.

For each tool in <CANDIDATES>, output exactly one JSON object per line (no other text):
{"name":"...","url":"...","verdict":"integration"|"exploration"|"skip","reason":"...","suggested_action":"..."}

verdict definitions:
- "integration": directly enhances a tool already in this repo (MCP server, Ghostty/tmux/zsh plugin, new Claude/Copilot feature, git hook tool, etc.)
- "exploration": standalone tool that adds something new to the workflow (new AI CLI, new terminal tool, etc.)
- "skip": not relevant, low quality, or already well-known/installed

Keep "reason" under 20 words. Keep "suggested_action" under 30 words.
Output ONLY the JSON lines — no preamble, no summary.

<CANDIDATES>
{{CANDIDATES}}
</CANDIDATES>
```

### 4c. Create `scripts/ai/create-discovery-issues.sh`

Reads the LLM output (newline-delimited JSON) and creates GitHub issues for non-skipped tools.

**File:** `scripts/ai/create-discovery-issues.sh`

**Behavior:**
- Read input file path from `$1`
- For each JSON line where `verdict != "skip"`:
  - Search existing issues: `gh issue list --label "ai-discovery" --search "<name>" --json title` — skip if a match exists (dedup)
  - `gh issue create` with:
    - **integration** verdict: label `ai-discovery,integration`, title `[ai-discovery] Integrate: <name>`, body includes what it is, why it integrates, suggested action, URL
    - **exploration** verdict: label `ai-discovery,exploration`, title `[ai-discovery] Explore: <name>`, body includes what it is, what it adds to the workflow, URL
- Uses `jq` to parse JSON lines (already installed in CI via the lint job's apt step)

### 4d. Create `.github/workflows/ai-tool-discovery.yml`

**File:** `.github/workflows/ai-tool-discovery.yml`

**Triggers:**
- `schedule: cron: '0 9 1,15 * *'` (1st and 15th of each month, 9am UTC)
- `workflow_dispatch` (manual trigger for testing)

**Job: `discover`**
- **Runner:** `ubuntu-latest`
- **Permissions:** `contents: read`, `issues: write`
- **Steps:**
  1. `actions/checkout@v4`
  2. Install Claude CLI: `npm install -g @anthropic-ai/claude-code` (for `claude -p` backend)
  3. Install `jq`: `sudo apt-get install -y jq`
  4. Run discovery: `bash scripts/ai/discover-ai-tools.sh > /tmp/candidates.txt`
  5. Build prompt: substitute `{{CANDIDATES}}` in `scripts/prompts/discovery.md` with candidates file content → `/tmp/discovery-prompt.txt`
  6. Run LLM evaluation:
     ```bash
     export ANTHROPIC_API_KEY="${{ secrets.ANTHROPIC_API_KEY }}"
     ASK_BACKEND=claude scripts/ask --raw "$(cat /tmp/discovery-prompt.txt)" > /tmp/analysis.txt
     ```
  7. Create issues: `bash scripts/ai/create-discovery-issues.sh /tmp/analysis.txt`

### 4e. Update `scripts/setup-github-labels.sh`

Add labels for the discovery workflow:
```bash
gh label create "ai-discovery"  --description "AI tool discovery workflow" --color "0075ca" --force
gh label create "integration"   --description "Integrates with existing dotfiles tool" --color "e4e669" --force
gh label create "exploration"   --description "New tool worth adding to the workflow"  --color "d4c5f9" --force
```

---

## Implementation Order

```
1.  git/hooks/pre-push                     ← can push to main one last time after this
2.  CONTRIBUTING.md
3.  AGENTS.md
4.  .github/copilot-instructions.md
5.  .shellcheckrc
6.  scripts/ci/lint.sh
7.  .github/workflows/ci.yml
8.  scripts/setup-github-labels.sh         ← add discovery labels here
9.  scripts/ai/collect-doc-drift-context.sh
10. .github/workflows/doc-config-drift.yml
11. scripts/ai/discover-ai-tools.sh
12. scripts/prompts/discovery.md
13. scripts/ai/create-discovery-issues.sh
14. .github/workflows/ai-tool-discovery.yml
------- PUSH AS PR (first PR ever!) -------
15. Verify CI passes on the PR
16. Apply GitHub Settings (Part 4 of original plan) manually
17. Merge the PR
18. Run scripts/setup-github-labels.sh
19. Test doc-drift workflow via workflow_dispatch
20. Test ai-tool-discovery workflow via workflow_dispatch
```

## Files Created (Summary)

| File | Type | Purpose |
|------|------|---------|
| `git/hooks/pre-push` | Hook | Block pushes to main |
| `CONTRIBUTING.md` | Docs | PR workflow for humans + agents |
| `AGENTS.md` | Docs | Cross-agent instructions |
| `.github/copilot-instructions.md` | Config | Copilot chat + review context |
| `.shellcheckrc` | Config | ShellCheck settings |
| `scripts/ci/lint.sh` | Script | Shellcheck + JSON + YAML validation |
| `scripts/ai/collect-doc-drift-context.sh` | Script | Gather config/doc pairs for drift auditor |
| `scripts/ai/discover-ai-tools.sh` | Script | Search GitHub for new AI tools |
| `scripts/ai/create-discovery-issues.sh` | Script | Parse LLM output and open GitHub issues |
| `scripts/prompts/discovery.md` | Prompt | System prompt for tool evaluation LLM call |
| `scripts/setup-github-labels.sh` | Script | One-time label creation |
| `.github/workflows/ci.yml` | Workflow | Lint gate (required for auto-merge) |
| `.github/workflows/doc-config-drift.yml` | Workflow | Weekly AI doc drift auditor |
| `.github/workflows/ai-tool-discovery.yml` | Workflow | Bi-weekly AI tool discovery |
| `plans/001-pr-workflow-and-ci.md` | Plan | This file |

## Files Modified

None. `install.sh` is not modified — install smoke tests are deferred to a future milestone.

## Backlog Items Addressed

When this plan is complete, the following backlog items can be checked off or significantly progressed:

- [ ] "Evaluate Copilot agentic workflows" → Done (discovery workflow feeds the Copilot coding agent loop)
- [ ] "Define a generic agent-assisted commit flow" → Done (PR-based flow documented)
- [ ] "Define a generic task-completion verification flow" → Partially (CI lint gate is the verification step)
- [ ] "Add an agent-configuration overview" → Partially (AGENTS.md is the shared baseline)

## Future Milestones (Not In Scope)

These are documented for context but NOT part of this plan:

- **M2:** Install smoke tests — actually run `install.sh` in CI on ubuntu/macos matrix (requires CI guards in install.sh, significant iteration)
- **M3:** Copilot custom agents (`.github/agents/*.agent.md`), path-specific instructions
- **M4:** PR-triggered AI workflows (docs-impact reviewer, installer triage, theme validator)
- **M5:** More scheduled workflows (cross-agent parity auditor, meta-workflow auditor)
- **M6:** Full closed-loop pipeline (discovery issue → auto-assign to Copilot → CI → auto-merge)
