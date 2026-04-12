# Agent Prompt: Implement Plan 001

Copy everything below the line and give it to an agent (Claude Code, Amp, Copilot, etc.).

---

## Task

Implement the plan in `plans/001-pr-workflow-and-ci.md`. Read that file completely before starting — it contains exact specifications for every file to create.

## Summary

You are implementing 4 things for this dotfiles repo:

1. **PR-first guardrails** — a pre-push hook, CONTRIBUTING.md, AGENTS.md, and Copilot instructions
2. **Deterministic CI** — a lint script + GitHub Actions workflow with shellcheck, JSON/YAML validation, and `bash -n` syntax check
3. **Doc ↔ Config drift auditor** — a weekly scheduled GitHub Actions workflow using `scripts/ask` (Claude backend) to detect documentation/config mismatches
4. **AI tool discovery** — a bi-weekly scheduled workflow that searches GitHub for new AI/terminal tools, evaluates them with LLM, and opens categorized issues

## Critical Rules

- **Read `plans/001-pr-workflow-and-ci.md` first.** Every file, every behavior, every edge case is specified there.
- **Do NOT modify `.zshrc`.** Do not touch aliases, functions (`ga`, `gc`, `gp`), or any shell config.
- **Do NOT modify `install.sh`** — install smoke tests are deferred to a future milestone. No CI guards needed now.
- **Match existing code style.** Look at `git/hooks/pre-commit` for hook style. Look at `install.sh` for script style. Use `set -euo pipefail`, emoji prefixes, clear error messages.
- **Make `scripts/ci/lint.sh` runnable locally.** It must work on both macOS and Linux without GitHub Actions.
- **All new scripts must be executable** (`chmod +x`).
- **Note the `.agents/` directory** in the repo root — it contains skills for Amp/Codex. AGENTS.md should be consistent with whatever conventions exist there.

## Implementation Order

Follow this exact sequence:

1.  `git/hooks/pre-push` — model after existing `git/hooks/pre-commit` style
2.  `CONTRIBUTING.md` — concise, under 60 lines
3.  `AGENTS.md` — concise, under 50 lines
4.  `.github/copilot-instructions.md` — under 4000 characters
5.  `.shellcheckrc` — minimal
6.  `scripts/ci/lint.sh` — shellcheck + bash -n + jq + yq
7.  `.github/workflows/ci.yml` — calls lint.sh, includes `bash -n install.sh` step, pins mikefarah/yq
8.  `scripts/setup-github-labels.sh` — create doc-drift + ai-discovery labels
9.  `scripts/ai/collect-doc-drift-context.sh` — explicit include list, 50KB size guard
10. `.github/workflows/doc-config-drift.yml` — uses `scripts/ask --backend claude`
11. `scripts/ai/discover-ai-tools.sh` — gh search queries, dedup, filter
12. `scripts/prompts/discovery.md` — LLM prompt for tool evaluation
13. `scripts/ai/create-discovery-issues.sh` — parse JSON lines, create gh issues
14. `.github/workflows/ai-tool-discovery.yml` — bi-weekly cron, calls discovery scripts

## Verification

After implementing, verify:

```bash
# Lint script works locally
bash scripts/ci/lint.sh

# Pre-push hook is executable
ls -la git/hooks/pre-push

# install.sh syntax is valid (no execution)
bash -n install.sh

# All new scripts are executable
find scripts/ -name "*.sh" -not -perm -u+x

# JSON files are valid
find . -name "*.json" -not -path "./.git/*" -exec jq empty {} \;

# All new files exist
for f in git/hooks/pre-push CONTRIBUTING.md AGENTS.md .github/copilot-instructions.md \
         .shellcheckrc scripts/ci/lint.sh .github/workflows/ci.yml \
         scripts/setup-github-labels.sh scripts/ai/collect-doc-drift-context.sh \
         .github/workflows/doc-config-drift.yml \
         scripts/ai/discover-ai-tools.sh scripts/prompts/discovery.md \
         scripts/ai/create-discovery-issues.sh \
         .github/workflows/ai-tool-discovery.yml; do
  [ -f "$f" ] && echo "✅ $f" || echo "❌ MISSING: $f"
done
```

## After Implementation

Tell the user:
1. Files are ready. Create a feature branch and PR — this will be the first PR ever on this repo.
2. Configure GitHub settings as described in Part 4 of the plan (branch protection, squash merge, auto-merge, auto-delete).
3. Add `ANTHROPIC_API_KEY` as an Actions secret — used by both doc-drift and discovery workflows.
4. Run `scripts/setup-github-labels.sh` after the PR is merged to create issue labels.
5. Test both AI workflows via `workflow_dispatch` before relying on the cron schedule.
6. Install smoke tests are intentionally NOT in this plan — the `lint` job is the only required CI gate for now.
