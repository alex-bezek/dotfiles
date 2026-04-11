# tmux Cheatsheet

Personal reference for using tmux across local Mac, EC2 boxes, and Codespaces.

---

## Architecture: How Everything Fits Together

```
┌─────────────────────────────────────────────────────────────────────┐
│  YOUR MAC (Ghostty terminal)                                        │
│                                                                     │
│  Local tmux server ← your "switchboard" — always running            │
│  Prefix: Ctrl+Space (CapsLock+Space)                                │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ Session: dotfiles          ← local project, no SSH              │ │
│  │   Window 1: editor                                              │ │
│  │   Window 2: shell                                               │ │
│  ├─────────────────────────────────────────────────────────────────┤ │
│  │ Session: ngrok-local       ← local project (Kind + Nix)        │ │
│  │   Window 1: editor                                              │ │
│  │   Window 2: kind cluster                                        │ │
│  │   Window 3: lazygit                                             │ │
│  ├─────────────────────────────────────────────────────────────────┤ │
│  │ Session: monorepo-ec2      ← SSH into EC2                      │ │
│  │   Window 1: ssh session ──────────┐                             │ │
│  │                                   │                             │ │
│  ├───────────────────────────────────┼─────────────────────────────┤ │
│  │ Session: ngrok-codespace   ← SSH into Codespace                │ │
│  │   Window 1: ssh session ────────┐ │                             │ │
│  │                                 │ │                             │ │
│  └─────────────────────────────────┼─┼─────────────────────────────┘ │
└────────────────────────────────────┼─┼──────────────────────────────┘
                                     │ │
          ┌──────────────────────────┘ │
          │                            │
          ▼                            ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│  CODESPACE               │  │  EC2 INSTANCE             │
│                          │  │                           │
│  Remote tmux server      │  │  Remote tmux server       │
│  Prefix: Ctrl+b (default)│  │  Prefix: Ctrl+b (default) │
│  ┌────────────────────┐  │  │  ┌─────────────────────┐  │
│  │ Session: work      │  │  │  │ Session: work       │  │
│  │  Win 1: editor     │  │  │  │  Win 1: editor      │  │
│  │  Win 2: agent      │  │  │  │  Win 2: agent       │  │
│  │  Win 3: lazygit    │  │  │  │  Win 3: lazygit     │  │
│  │  Win 4: server     │  │  │  │  Win 4: build       │  │
│  └────────────────────┘  │  │  └─────────────────────┘  │
└──────────────────────────┘  └───────────────────────────┘
    ↑ shuts down = tmux gone      ↑ persists across SSH drops
    ↑ re-create on restart        ↑ just re-attach
```

### Why two layers?

| Layer | Purpose | Prefix |
|-------|---------|--------|
| **Local tmux** (your Mac) | Project switching — your single view of everything you're working on | `Ctrl+Space` |
| **Remote tmux** (EC2/Codespace/Linux host) | Persistence — work survives SSH disconnects, agents keep running | `Ctrl+b` |

The same tmux config is symlinked everywhere, but it switches prefixes by host OS: macOS gets `Ctrl+Space`, Linux hosts keep `Ctrl+b`. When you're looking at a remote tmux session through your local tmux, `Ctrl+Space` controls local and `Ctrl+b` controls remote.

### What happens when things disconnect?

| Scenario | What happens | What to do |
|----------|-------------|------------|
| SSH to EC2 drops | Remote tmux keeps running, local tmux shows dead pane | Re-SSH, `tmux attach` |
| Codespace shuts down | Remote tmux is gone (Codespace wiped) | Restart Codespace, start fresh tmux |
| Close Ghostty lid | Local tmux keeps running | Reopen Ghostty, `tmux attach` |
| Reboot Mac | Local tmux sessions are gone | Recreate sessions (fast with sesh) |

---

## One-Time Setup

### Caps Lock → Control (macOS)

Your tmux prefix is `Ctrl+Space`. To make Ctrl easy to hit, remap Caps Lock:

**System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys → Caps Lock key → ^ Control**

This is also automated in `install.sh` — but requires a **logout/login** to take effect.

> You can still toggle actual caps lock with `Shift + Caps Lock` if you ever need it.

### Verify tmux config is linked

```bash
ls -la ~/.config/tmux/tmux.conf
# Should point to → your dotfiles/tmux/tmux.conf
```

If not, run `./install.sh` or manually:
```bash
mkdir -p ~/.config/tmux
ln -sf ~/code/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
```

---

## Mental Model

- **Session** = a project or work context (named: `dotfiles`, `ngrok-local`, `monorepo-ec2`)
- **Window** = a task within that project (named: `editor`, `shell`, `lazygit`)
- **Pane** = a split within a window (use sparingly — prefer windows)

Rule of thumb: **sessions for projects, windows for tasks, panes only when two things must be visible at once.**

---

## Keybinding Reference

Your **local macOS** prefix is `Ctrl+Space`. With Caps Lock mapped to Control, this is: **CapsLock + Space**.

On **remote Linux** machines, the prefix stays `Ctrl+b`. The same actions apply, just swap the prefix.

### Session Management (project switching)

| Keys | Action |
|------|--------|
| `Ctrl+Space T` | **Open sesh picker** — search/switch/create sessions |
| `Ctrl+Space s` | List sessions (built-in tmux picker) |
| `Ctrl+Space (` | Previous session |
| `Ctrl+Space )` | Next session |
| `Ctrl+Space d` | Detach — leave tmux running, go back to bare terminal |
| `Ctrl+Space $` | Rename current session |

### Window Management (task switching)

| Keys | Action |
|------|--------|
| `Ctrl+Space c` | New window (in current directory) |
| `Ctrl+Space ,` | Rename current window |
| `Ctrl+Space n` | Next window |
| `Ctrl+Space p` | Previous window |
| `Ctrl+Space 1`..`9` | Jump to window by number |
| `Ctrl+Space &` | Close window (confirms) |

### Pane Management (splits)

| Keys | Action |
|------|--------|
| `Ctrl+Space \|` | Split vertical (side by side) |
| `Ctrl+Space -` | Split horizontal (top / bottom) |
| `Ctrl+Space x` | Close current pane |
| `Ctrl+Space z` | Zoom / unzoom current pane (fullscreen toggle) |
| `Ctrl+Space arrow` | Move between panes |
| `Ctrl+Space q` | Show pane numbers, then press number to jump |

### Copy Mode (scrolling & selecting)

| Keys | Action |
|------|--------|
| `Ctrl+Space [` | Enter copy mode (scroll up, search, select) |
| `v` | Start selection (in copy mode) |
| `y` | Copy selection and exit |
| `/` | Search forward (in copy mode) |
| `?` | Search backward (in copy mode) |
| `q` | Exit copy mode |

> Mouse scrolling also works (mouse mode is on).

### Utility

| Keys | Action |
|------|--------|
| `Ctrl+Space r` | Reload tmux config |
| `Ctrl+Space :` | Command prompt (for advanced tmux commands) |

---

## Shell Commands

Use these outside tmux or from any shell:

```bash
tmux ls                        # List all sessions
tmux new -s project-name       # Create a named session
tmux attach -t project-name    # Reattach to a session
tmux kill-session -t name      # Kill a specific session
```

---

## Daily Workflow

### Starting your day

```bash
# Open Ghostty (or any terminal)
# You're in a bare shell — attach to local tmux:

tmux attach
# or if no sessions exist yet:
tmux new -s dotfiles
```

Once inside tmux, use `Ctrl+Space T` (sesh picker) to switch between or create project sessions.

### Working on a local project

```
Ctrl+Space T  →  pick or create "ngrok-local"
  Window 1 (editor):  nvim
  Window 2 (shell):   build commands, tests
  Window 3 (git):     lazygit
```

Switch windows: `Ctrl+Space 1`, `Ctrl+Space 2`, `Ctrl+Space 3`

### Working on a remote project

```
Ctrl+Space T  →  pick or create "monorepo-ec2"
  Window 1:  ssh into EC2

# Now you're on the remote machine. Start remote tmux:
tmux new -s work    (first time)
tmux attach         (returning)

# Inside remote tmux (Ctrl+b prefix):
Ctrl+b c            create windows for editor, agent, lazygit, etc.
```

Your local `Ctrl+Space` still works to switch sessions. The remote `Ctrl+b` controls the inner tmux. No conflicts.

### Switching between projects

`Ctrl+Space T` — the sesh picker. This is your "what am I working on?" view. It shows all local tmux sessions. Pick one to jump to it.

Or: `Ctrl+Space s` for the built-in session list, `Ctrl+Space (` / `)` to cycle.

### Leaving for the day

Just close Ghostty. Everything stays running. Tomorrow:
```bash
# Open Ghostty
tmux attach
# You're right back where you left off
```

### Reconnecting after SSH drops

```
# Your local tmux session still exists — the SSH pane just shows "disconnected"
# Press Enter or re-run ssh:
ssh my-ec2-box
tmux attach
# Remote tmux kept everything alive
```

---

## Suggested Session Layout

Map your sessions 1:1 to what you're actively working on:

| Session name | Where | What |
|-------------|-------|------|
| `dotfiles` | local | this repo |
| `ngrok-local` | local | ngrok operator on Kind/Nix |
| `ngrok-cs-1` | SSH → Codespace | ngrok operator in Codespace |
| `monorepo-ec2` | SSH → EC2 | monorepo dev environment |
| `monorepo-cs` | SSH → Codespace | monorepo in Codespace |

Within each session, name your windows after what they do:

```
Session: ngrok-local
  1:editor    nvim
  2:agent     amp / claude
  3:git       lazygit
  4:cluster   kind cluster logs
```

Rename windows with `Ctrl+Space ,` — future you will thank present you.

---

## Quick Reference Card

```
LOCAL PREFIX: Ctrl+Space  (CapsLock + Space)
REMOTE PREFIX: Ctrl+b     (default, no setup needed)

SESSIONS        WINDOWS         PANES           UTILITY
T  sesh picker  c  new window   |  split vert   r  reload config
s  list all     ,  rename       -  split horiz  [  copy mode
(  prev         n  next         x  close        d  detach
)  next         p  prev         z  zoom toggle
$  rename       1-9  jump       ←↑↓→  navigate
```

---

## Personal Notes

Add your own commands and habits here as they become real.

- 
