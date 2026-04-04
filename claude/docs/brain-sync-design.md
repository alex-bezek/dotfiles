# Brain Sync: Sharing State Across Environments

## Chosen Approach

**Private git repo** (`alex-bezek/claude-brain`) synced automatically via hooks.

- `~/code/claude-brain/` — cloned repo with journal, threads, memory
- `~/.claude/brain` — symlink to the clone
- All hooks/skills reference `~/.claude/brain/` paths
- `brain-sync.sh pull` runs at session start (Setup hook)
- `brain-sync.sh push` runs at session end (Stop hook, auto-commit+push)
- `install-claude.sh` clones the repo if missing, creates the symlink

### What's synced
```
~/.claude/brain/
├── journal/
│   ├── threads.json        # work thread index
│   ├── meta.yaml           # session counters
│   ├── handoffs/           # handoff docs per thread
│   └── YYYY-MM-DD.yaml     # daily session entries
└── memory/
    └── <project-key>/      # per-project memory files
```

### Future considerations
- If daily YAML files get large, `.gitignore` them and keep only threads.json + handoffs
- Memory files currently duplicated (also in `~/.claude/projects/*/memory/`) — could consolidate later
- Codespaces: install script clones via HTTPS if SSH unavailable

---

## Original Design Options (for reference)

## Problem

Our Claude Code setup has two categories of files:

| Category | Examples | Repo? | Sensitive? |
|----------|---------|-------|-----------|
| **Config** | CLAUDE.md, settings.json, skills/, hooks/ | Yes — dotfiles repo | No |
| **Brain** | journal/*.yaml, threads.json, memory/, handoffs/, meta.yaml | No | Yes (task descriptions, corrections, cost data) |

Config is solved — symlinked from dotfiles, synced with `/sync-to-dotfiles`.

Brain files are the problem. They're created at runtime, contain private work context, and currently live only on the machine where the session ran. Starting a Codespace means starting with zero context — no threads, no journal, no memory.

### What needs syncing

```
~/.claude/
├── journal/
│   ├── threads.json          # ~2KB, updated every session end
│   ├── meta.yaml             # ~500B, counters
│   ├── handoffs/             # ~1KB each, one per thread
│   └── 2026-04-04.yaml       # ~2KB/day, raw journal (archivable)
├── projects/
│   └── */memory/             # ~1KB per project, MEMORY.md + detail files
└── .review-due               # marker file
```

Total expected size: **< 1MB** for months of use. This is tiny.

### Current hardcoded paths in skills

These files reference `~/.claude/journal/` or `~/.claude/projects/` directly:
- `skills/focus/SKILL.md` — reads threads.json, journal/*.yaml, memory/
- `skills/threads/SKILL.md` — reads threads.json
- `skills/handoff/SKILL.md` — writes handoffs/, updates threads.json
- `hooks/session-journal.sh` — writes journal/*.yaml, threads.json, meta.yaml
- `hooks/inject-context.sh` — reads threads.json

---

## Option 1: S3 Bucket + Sync Script

The simplest approach. A private S3 bucket holds brain files. A sync script runs on session start/end.

```
s3://alex-claude-brain/
├── journal/
├── projects/
└── .review-due
```

**Sync mechanism**: Two hooks added to settings.json:
- **Setup hook**: `brain-sync.sh pull` — download from S3 before session
- **Stop hook**: `brain-sync.sh push` — upload to S3 after session (runs after session-journal.sh)

```bash
#!/usr/bin/env bash
# brain-sync.sh
BRAIN_DIR="$HOME/.claude"
BUCKET="s3://alex-claude-brain"
case "$1" in
  pull) aws s3 sync "$BUCKET" "$BRAIN_DIR" --exclude "*.json" --exclude "settings*" --include "journal/*" --include "projects/*/memory/*" ;;
  push) aws s3 sync "$BRAIN_DIR/journal" "$BUCKET/journal" && aws s3 sync "$BRAIN_DIR/projects" "$BUCKET/projects" --include "*/memory/*" ;;
esac
```

**Pros**:
- Dead simple. ~20 lines of bash.
- S3 is cheap ($0.023/GB/month), versioned, private by default.
- `aws s3 sync` only transfers changed files — fast for small deltas.
- Works from any environment with AWS credentials.

**Cons**:
- Needs AWS CLI + credentials on every machine. Codespaces needs a secret.
- No conflict resolution — last writer wins. Fine for single-user, but two concurrent sessions could clobber.
- Adds latency to session start/end (100-500ms for small syncs).
- Another cloud service dependency.

**Conflict mitigation**: Since sessions are serial (one at a time per human), conflicts are rare. Add a simple lock file in S3 if needed. Or use `--delete` only on pull, not push.

---

## Option 2: Git Repo (Private)

A separate private Git repo for brain files. Same symlink pattern as dotfiles.

```
github.com/alexbezek/claude-brain (private)
├── journal/
├── projects/
└── .gitignore
```

**Sync mechanism**: Hooks auto-commit and push/pull.

```bash
# brain-sync.sh
BRAIN_REPO="$HOME/.claude-brain"
case "$1" in
  pull) cd "$BRAIN_REPO" && git pull --rebase --quiet ;;
  push) cd "$BRAIN_REPO" && git add -A && git commit -m "session $(date +%F-%H%M)" --quiet && git push --quiet ;;
esac
```

Brain files symlinked from `~/.claude-brain/journal` → `~/.claude/journal`.

**Pros**:
- Full history — can see how threads evolved over time.
- Works great with Codespaces (just clone the repo in install script).
- No extra cloud services — just GitHub.
- Merge conflicts are possible but unlikely (and git handles them).
- Free for private repos.

**Cons**:
- Git overhead for frequent small writes (every session end = commit + push).
- History grows unbounded unless you squash/gc periodically.
- SSH key or token needed in each environment (Codespaces has this via `gh`).
- Feels heavyweight for what's essentially a key-value store.

**Optimization**: Only push every N sessions or on `/handoff`. Daily journal files change frequently; threads.json is the critical one.

---

## Option 3: Gist-Based (Simplest)

Use a single private GitHub Gist to store the critical files. Gists are git repos under the hood.

```
gist.github.com/alexbezek/<id>
├── threads.json
├── meta.yaml
└── memory-ngrok-operator.json   # flattened memory per project
```

**Sync**: `gh gist edit` or raw git operations on the gist repo.

**Pros**:
- Zero infrastructure. `gh` CLI works everywhere.
- Private by default.
- Versioned (it's git).
- Single URL to manage.

**Cons**:
- Gists don't support directories — have to flatten the structure.
- Size limits (~10MB per file, but we're way under).
- Awkward for the full journal/ tree.
- API rate limits if syncing frequently.

**Best for**: Syncing just threads.json + meta.yaml (the critical index files). Leave raw journal as local-only.

---

## Option 4: iCloud/Dropbox Symlink

Point `~/.claude/journal` at a cloud-synced folder.

```bash
ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs/claude-brain/journal ~/.claude/journal
```

**Pros**:
- Zero config on macOS. Already syncing.
- Automatic, real-time sync.
- No credentials to manage.

**Cons**:
- macOS only. Doesn't help with Codespaces or EC2.
- Sync conflicts are opaque (iCloud conflict copies).
- Can't programmatically control sync timing.

**Verdict**: Nice for Mac↔Mac but doesn't solve the full problem.

---

## Option 5: Hybrid — Tiered by Importance

Not all brain files are equally important to sync. Tier them:

| Tier | Files | Sync strategy | Why |
|------|-------|--------------|-----|
| **Critical** | threads.json, meta.yaml | Private gist, synced every session | Small, essential for `/focus` and orientation |
| **Important** | memory/MEMORY.md + detail files | Private git repo or S3, synced daily | Valuable but changes slowly |
| **Archival** | journal/*.yaml, handoffs/ | Local only, backed up weekly to S3 | Raw data, large, rarely read directly |

This means:
- A new Codespace gets threads.json + memory immediately (gist pull in install script)
- Full journal history stays local but is backed up
- Critical path is fast (one small gist, not a full repo sync)

**Implementation**:
```bash
# In install-claude.sh, after existing setup:
if [ -n "$CLAUDE_BRAIN_GIST" ]; then
  gh gist view "$CLAUDE_BRAIN_GIST" -f threads.json > ~/.claude/journal/threads.json
  gh gist view "$CLAUDE_BRAIN_GIST" -f meta.yaml > ~/.claude/journal/meta.yaml
fi

# In session-journal.sh, after writing:
if [ -n "$CLAUDE_BRAIN_GIST" ]; then
  gh gist edit "$CLAUDE_BRAIN_GIST" -f threads.json ~/.claude/journal/threads.json
fi
```

---

## Option 6: SQLite + Litestream

Use SQLite as the local brain store and [Litestream](https://litestream.io/) for continuous replication to S3.

**Pros**:
- Real database — queries, transactions, no file conflicts.
- Litestream handles sync transparently (streaming replication).
- Single file to manage.
- Can restore to any point in time.

**Cons**:
- Overkill for < 1MB of YAML/JSON.
- Adds two dependencies (sqlite3 + litestream).
- Skills and hooks would need rewriting to use sqlite instead of jq.
- Harder to inspect/debug than flat files.

**Verdict**: Cool tech but wrong scale. Revisit if brain data grows significantly.

---

## Option 7: Environment Variable Indirection

Before choosing a sync mechanism, decouple the path. All skills and hooks should reference `$CLAUDE_BRAIN_DIR` instead of hardcoded `~/.claude/journal/`:

```bash
BRAIN="${CLAUDE_BRAIN_DIR:-$HOME/.claude}"
threads="$BRAIN/journal/threads.json"
```

This lets each environment point brain files wherever makes sense:
- macOS: `~/.claude` (default, local)
- EC2: `~/.claude` (default, local)  
- Codespace: `/workspaces/.claude-brain` (mounted volume or cloned repo)

**This is orthogonal to sync** — it's just good hygiene that makes any sync option easier.

---

## Recommendation

**Do now** (10 min):
1. **Option 7** — Add `$CLAUDE_BRAIN_DIR` indirection to hooks and skills. Zero-cost, enables everything else.

**Do next** (when you actually use Codespaces):
2. **Option 5 (Hybrid)** with **Option 2 (private git repo)** for critical+important tiers:
   - Private repo `claude-brain` with threads.json, meta.yaml, memory/
   - Install script clones it, hooks push on session end
   - Raw journal stays local (it's archival)

**Why not S3?** Git repo is simpler — no AWS credentials, works with `gh` in Codespaces natively, gives you history for free. S3 is better if you want to store large archival data cheaply, but the critical data is tiny.

**Why not gist?** Gists can't do directories. A private repo is barely more work and supports the full structure.

**Skip for now**: SQLite (wrong scale), iCloud (macOS only), pure S3 (needs AWS everywhere).

---

## Path Abstraction Sketch

For the `$CLAUDE_BRAIN_DIR` change, here's what moves:

```
# Current (hardcoded)
~/.claude/journal/threads.json
~/.claude/journal/meta.yaml
~/.claude/journal/handoffs/
~/.claude/journal/*.yaml
~/.claude/projects/*/memory/

# After (indirected)
$CLAUDE_BRAIN_DIR/journal/threads.json      # default: ~/.claude/journal/
$CLAUDE_BRAIN_DIR/memory/                    # default: ~/.claude/projects/*/memory/
                                             # (flatten to $BRAIN/memory/<project>/)
```

Files that reference these paths:
- `hooks/session-journal.sh` — JOURNAL_DIR, THREADS_FILE, META_FILE
- `hooks/inject-context.sh` — THREADS_FILE
- `skills/focus/SKILL.md` — threads.json, journal/*.yaml, memory/
- `skills/threads/SKILL.md` — threads.json  
- `skills/handoff/SKILL.md` — threads.json, handoffs/
- `install-claude.sh` — creates journal/ directory

The skill files are trickier since they're markdown instructions, not scripts. Options:
1. Skills say "Read `$CLAUDE_BRAIN_DIR/journal/threads.json`" — Claude expands env vars
2. Skills say "Read the threads file (check `$CLAUDE_BRAIN_DIR` or default `~/.claude/journal/`)"
3. A setup hook sets `additionalContext` with resolved paths: "Brain dir: /home/user/.claude"

Option 3 is cleanest — skills stay readable, hook resolves the path once.
