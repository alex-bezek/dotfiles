---
name: improve
description: Audit and improve this Codex dotfiles setup — find new features, simplifications, or optimizations. Use when the user mentions improving, auditing, evolving, or reviewing the Codex config, or asks "what should I add", "what am I missing", "new Codex features", "simplify my setup". Also trigger proactively when the user asks about Codex features they don't have yet. Supports $ARGUMENTS for modes — "quick", "research", or default full audit.
---

# Improve Codex Setup

Audit the current Codex dotfiles setup, research what's new, and present actionable findings for the user to accept or reject.

## Modes

Check `$ARGUMENTS` to determine which mode to run:

- **No arguments** (`/improve`) — Full audit: research + present findings + implement approved items
- **`quick`** (`/improve quick`) — Pick one easy win from BACKLOG.md, implement it, explain how it works and how to use it
- **`research`** (`/improve research`) — Research only: find new things, update BACKLOG.md, no implementation
- **`loop`** (`/improve loop`) — Autonomous cycle: implement easy wins, prune backlog, research when empty. Commits to `improve/auto` branch without pushing.

---

## Mode: Loop

Autonomous maintenance cycle — intended to be run on a schedule (e.g., daily via `/schedule` or `/loop 24h /improve loop`). Works on a feature branch so changes can be reviewed before merging.

### Setup

1. From `~/code/dotfiles`, create or switch to the `improve/auto` branch:
   ```
   git checkout -b improve/auto master || git checkout improve/auto && git merge master
   ```
2. All commits happen on this branch. Never push automatically.

### Cycle

Repeat until the session budget is spent or 5 cycles complete (whichever comes first):

**Step 1: Quick implement**
- Read BACKLOG.md
- Find the highest-value trivial/small item
- If none exist, skip to Step 3
- Implement it
- Commit with a descriptive message (e.g., "improve: add PostToolUse gofmt hook")
- Move item to Done in BACKLOG.md, commit that too

**Step 2: Prune**
- Review BACKLOG.md for:
  - Items that are now stale (feature already exists, tool deprecated, etc.)
  - Items that duplicate each other
  - Items that sounded good but aren't worth the effort given current setup
  - Items in Explore/Research that have been there for 2+ months with no action (consider removing or downgrading)
- Remove or merge items as needed
- Commit: "improve: prune backlog — removed N stale items"
- **Cap**: BACKLOG.md should stay under ~60 unchecked items. If it's over, be more aggressive pruning low-priority items.

**Step 3: Research (only when Step 1 found no easy items)**
- Run the Research mode (3 parallel agents)
- Add findings to BACKLOG.md
- Immediately prune the new additions (Step 2 again) — this prevents unbounded growth
- Commit: "improve: research — added N new items to backlog"

**Step 4: Back to Step 1**

### After the loop ends

Print a summary:
```
Completed N improvements on branch `improve/auto`:
- [commit hash] add PostToolUse gofmt hook
- [commit hash] prune backlog — removed 3 stale items
- ...

Review with: git log master..improve/auto
Merge with: git checkout master && git merge improve/auto
```

Do NOT push. Do NOT merge to master. The user reviews and merges when ready.

---

## Mode: Quick

Fast path — grab an easy win and ship it.

1. Read `~/code/dotfiles/Codex/BACKLOG.md`
2. Find the highest-value item marked **trivial** or **small** effort that hasn't been done
3. Implement it (edit config, create files, whatever it takes)
4. Move it to the Done section in BACKLOG.md
5. Update README.md if it's a new feature
6. Explain to the user:
   - What was added/changed (1-2 sentences)
   - How it works (brief technical explanation)
   - How to use it (concrete examples or commands)
   - How to verify it's working
7. Run `/verify` to confirm nothing is broken

If the backlog is empty or everything remaining is medium/large effort, say so and suggest running `/improve` for a full audit to find new easy wins.

---

## Mode: Research

Research-only — find new things without changing anything.

1. Run Phase 1 (Snapshot) and Phase 2 (Research with 3 agents) from the full audit below
2. Run Phase 3 (Synthesize)
3. Present a summary of findings grouped by Add/Remove/Change
4. Update BACKLOG.md with any new items discovered, slotted into the right priority section
5. Do NOT implement anything — just update the backlog and inform the user

---

## Mode: Full Audit (default)

Run all phases below.

### Phase 1: Snapshot Current State

Before suggesting changes, understand what exists. Read these files (skip any that don't exist):

- `~/code/dotfiles/Codex/settings.json` — plugins, hooks, permissions, model config
- `~/code/dotfiles/Codex/AGENTS.md` — global instructions
- `~/code/dotfiles/Codex/BACKLOG.md` — known todos and ideas
- `~/code/dotfiles/Codex/README.md` — what's documented as configured
- `~/code/dotfiles/Codex/TIPS.md` — workflow reference
- `~/.Codex.json` — runtime config, MCP servers
- List `~/code/dotfiles/Codex/skills/*/SKILL.md` — custom skills
- List `~/code/dotfiles/Codex/hooks/` — hook scripts
- List `~/code/dotfiles/Codex/agents/` — custom subagents

Compile a brief inventory: what's configured, what plugins are enabled, what MCP servers are connected, how many skills/hooks/agents exist.

### Phase 2: Research (3 Parallel Agents)

Launch three agents simultaneously, each with a different lens. Give each agent the inventory from Phase 1 so they know what's already in place.

**Agent 1 — Scout (find new things)**

```
You are researching improvements for a Codex dotfiles setup. Here is what's currently configured:

<inventory from Phase 1>

Your job: find NEW things worth adding. Search the web for:

1. Codex changelog / release notes — any new features since the setup was last updated?
2. Community patterns — search GitHub for popular .Codex/ configurations, AGENTS.md examples, and Codex skills/hooks/agents that others have shared
3. New MCP servers — search for recently released or trending MCP servers that would be useful for a Go developer who works with Kubernetes, AWS, Linear, Buildkite, and Datadog
4. New plugins — check if there are new official or community plugins worth evaluating
5. Workflow patterns — search for blog posts, tweets, or discussions about Codex workflows, tips, or advanced usage patterns that aren't in the current TIPS.md
6. Skills and agents — search for community-shared skills or agent configurations

For each finding, report:
- What it is (1 sentence)
- Why it matters (1 sentence)
- Link/source
- Effort to adopt: trivial / small / medium / large
- Your confidence it's worth doing: high / medium / low

Focus on actionable, concrete findings. Skip vague "you could try..." suggestions.
```

**Agent 2 — Critic (find things to remove or fix)**

```
You are auditing a Codex dotfiles setup for bloat, redundancy, staleness, and missed opportunities. Here is what's currently configured:

<inventory from Phase 1>

Your job: find things to REMOVE, SIMPLIFY, or FIX. Look for:

1. Redundant config — plugins that overlap, settings that duplicate defaults, hooks that duplicate built-in behavior
2. Stale items — BACKLOG.md items that are no longer relevant, TIPS.md advice that's outdated, settings for features that have changed
3. Complexity that isn't paying for itself — over-engineered hooks, skills that could be simpler, abstractions nobody uses
4. Security or correctness issues — permissions that are too broad, hooks with edge cases, settings that conflict
5. Missing basics — things that should be configured but aren't (e.g., .gitignore patterns, backup strategies)
6. Performance — anything that wastes context window, slows startup, or adds latency

Read the actual file contents, not just names. Check if hooks handle edge cases. Check if skills have dead code. Check if the AGENTS.md has instructions that Codex already follows by default (wasted context).

For each finding, report:
- What to change (1 sentence)
- Why (1 sentence)
- Risk if ignored: low / medium / high
- Effort: trivial / small / medium
```

**Agent 3 — Architect (suggest structural improvements)**

```
You are reviewing the architecture of a Codex dotfiles setup for structural improvements. Here is what's currently configured:

<inventory from Phase 1>

Your job: suggest STRUCTURAL improvements — not new features, but better ways to organize or connect what exists. Consider:

1. Workflow gaps — are there common sequences of actions that should be automated? (e.g., "review then commit then push" as a single flow)
2. Hook composition — could existing hooks be combined, chained, or made more composable?
3. Skill design — are any skills doing too much? Could any be split or combined?
4. Config organization — would Codex/rules/ directory be better than a monolithic AGENTS.md? Are settings split well across base/local files?
5. Cross-cutting concerns — is there a pattern that repeats across skills/hooks that should be extracted?
6. Agent opportunities — based on the user's workflow (Go, K8s, AWS, Linear), what custom subagents would save the most time?
7. Testing and verification — could the verify skill be expanded? Are there things that should be verified but aren't?

For each suggestion, report:
- What to change (1-2 sentences)
- Expected benefit (1 sentence)
- Effort: trivial / small / medium / large
- Dependencies (if any)
```

### Phase 3: Synthesize and Deduplicate

Once all three agents return, merge their findings:

1. Remove duplicates (keep the more detailed version)
2. Group by category:
   - **Add** — new features, plugins, MCP servers, skills
   - **Remove** — bloat, redundancy, stale items
   - **Change** — structural improvements, reorganization, fixes
3. Within each category, sort by: effort (ascending) then confidence/impact (descending) — easy wins first
4. Tag each item with which agent(s) suggested it (Scout/Critic/Architect) — items flagged by multiple agents are higher signal

### Phase 4: Present Findings

Present findings to the user in a scannable format. Use AskUserQuestion with multiSelect for each category so the user can check off what they want.

For each category (Add / Remove / Change), present up to 8 items as options. Each option label should be the what (short), and the description should combine the why + effort + source agent(s).

If there are more than 8 items in a category, present the top 8 and mention how many more there are — offer to show the rest if they want.

### Phase 5: Execute Approved Changes

For each approved item:
1. Make the change (edit config, create files, install plugins)
2. Mark it briefly in the conversation as done
3. If the item was in BACKLOG.md, check it off or remove it
4. If the item is a new feature, add it to README.md's "What's Configured" section

After all changes, run `/verify` to make sure nothing is broken.

### Phase 6: Update BACKLOG.md

- Move approved-and-completed items to the Done section
- Add any deferred items (presented but not selected) to the appropriate priority section, if they aren't already there
- Remove any BACKLOG.md items that the Critic flagged as stale and the user agreed to remove

### Phase 7: Suggest Skill Improvement

After completing the audit, suggest:

> "Want me to run the skill-creator's description optimizer on `/improve` to make sure it triggers reliably? This tests 20 sample prompts and tunes the description field. Takes a few minutes in the background."

This helps the skill get better at triggering over time as the user's setup evolves. Use `/skill-creator:skill-creator` and jump to the "Description Optimization" section if the user agrees.

## Tips

- Run this skill periodically (monthly-ish) to stay current
- The Scout agent's web research is the highest-value part — Codex moves fast
- If you disagree with a finding, skip it. The skill presents options, not mandates.
- Items selected by multiple agents (Scout + Critic, etc.) tend to be the best bets
