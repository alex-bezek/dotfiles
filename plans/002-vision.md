# Vision: AI-Driven Dotfiles Workflow

**Created:** 2026-04-11
**Status:** Active — M1 in progress

## The Problem

This dotfiles repo is managed by one person but increasingly modified by multiple AI agents (Claude Code, Copilot, Amp, Codex). Today, everything is pushed directly to main. This means:

1. **No review layer.** AI-generated changes land immediately with no feedback loop.
2. **No CI.** A broken shell script isn't caught until someone SSHs into a new box and finds nothing works.
3. **No install diagnostics.** When `install.sh` fails on a fresh Codespace or devcontainer, there's no programmatic way to know what broke or where.
4. **No path to automation.** Without a PR-based workflow, there's no place to attach CI checks, AI reviews, or auto-merge logic.

## The Goal

A fully automated, AI-driven workflow where:

- AI agents create PRs instead of pushing to main
- Deterministic CI validates every change before merge
- AI code review (Copilot) provides advisory feedback on every PR
- Install failures are caught and debuggable without manual SSH investigation
- Over time, the loop tightens toward zero-click: agent opens PR → CI passes → auto-merge

## What We Learned

Before planning implementation, we researched what's actually possible with GitHub's current tooling (April 2026):

| Capability | Status | Implication |
|-----------|--------|-------------|
| Copilot code review | Comment-only, cannot approve | Advisory feedback only, never gates merge |
| Auto-merge without human approval | Works if branch protection has no required approvals | The zero-click loop is achievable for CI-gated PRs |
| Copilot coding agent PRs | Always require human review | Full autonomy not possible for Copilot-generated PRs |
| Copilot review gating auto-merge | Not supported | Copilot findings can't block or allow merge |

**Bottom line:** The achievable automated loop is: agent creates PR → CI passes → auto-merge (if enabled). Copilot review runs in parallel but is purely advisory. Human approval is needed only for Copilot coding agent PRs (by GitHub's design).

## Milestones

### [M1: PR Workflow + CI + Install Diagnostics](./002-pr-workflow-and-ci.md)

The foundation. Gets the PR loop working with deterministic CI and makes install failures debuggable.

**Delivers:**
- [Agent instructions](./002-pr-workflow-and-ci.md#1-agentsmd-repo-root-50-lines) so all AI agents know to branch and PR (`AGENTS.md`)
- [Copilot review calibration](./002-pr-workflow-and-ci.md#2-githubcopilot-instructionsmd-4000-chars) to reduce noise on a personal dotfiles repo
- [Lint CI](./002-pr-workflow-and-ci.md#4-scriptscilintsh) — shellcheck, bash syntax, JSON validation on every PR
- [Install trap + debug script](./002-pr-workflow-and-ci.md#installsh--add-trap--status-marker) — `$HOME/.dotfiles-status` written on success/failure, auto-diagnostics on crash
- [Pre-push hook](./002-pr-workflow-and-ci.md#7-githookspre-push) blocking direct pushes to main
- [Branch protection](./002-pr-workflow-and-ci.md#configure-github-settings-manual-between-prs) requiring CI to pass before merge

**Key design decisions:**
- Two PRs to bootstrap (CI files must reach main before PRs can use CI)
- No required approvals — solo dev, CI is the gate
- Branch protection bypass left ON during initial iteration (graduation criteria: 10 PRs or auto-merge enabled)
- Copilot review sensitivity tuned for dotfiles context (the hardest part — needs iteration after 5-10 PRs)

### M2: Scheduled AI Workflows (Future)

Once M1 is stable and Copilot review noise is manageable, add scheduled AI-powered workflows:

- **Doc-drift auditor** — weekly cron that uses `claude -p` to compare config files against documentation, opens issues when they diverge
- **AI tool discovery** — bi-weekly scan of GitHub for new MCP servers, AI CLI tools, terminal utilities; LLM evaluates relevance and opens categorized issues

Technical approach: use `claude -p` directly in workflow YAML (not `scripts/ask`), pipe prompts via stdin to avoid ARG_MAX limits. Requires `ANTHROPIC_API_KEY` as an Actions secret — validate headless auth before trusting on cron.

### M3: Copilot Coding Agent Loop (Future)

Once M2 proves the AI-in-CI pattern works:

- Copilot coding agent picks up issues (assign `@copilot` to discovery issues)
- Copilot creates PRs → CI validates → human reviews and merges
- Iterate toward: discovery finds tool → creates issue → Copilot integrates it → CI validates → merge

This is the "closed loop" aspiration. It will always require human review for Copilot coding agent PRs (GitHub enforces this), but the human review step should be lightweight if CI and advisory review are doing their job.

### M4+: Advanced Automation (Aspirational)

- Install smoke tests in CI (actually run `install.sh` on ubuntu/macos matrix)
- PR-triggered AI workflows (docs-impact reviewer, installer triage)
- Cross-agent parity auditor (are CLAUDE.md, AGENTS.md, copilot-instructions all consistent?)
- Meta-workflow auditor (are the AI workflows themselves working correctly?)

## What This Is NOT

- Not a "best practices" or compliance exercise. No security policies, contributor guidelines, or governance docs.
- Not trying to replicate a team engineering workflow. This is one person with AI agents.
- Not replacing existing tools (`verify.sh`, `sync-to-dotfiles.sh`, etc.) — layering automation on top.
- Not adding AI to the merge gate. All AI feedback is advisory. Deterministic CI is the only hard gate.
