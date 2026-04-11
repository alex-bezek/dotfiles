# tmux Cheatsheet

Small personal reference for using tmux across local machines, EC2 boxes, and Codespaces.

## Mental Model

- **Terminal tab/window**: your outer container (Ghostty tab, SSH tab, etc.)
- **tmux session**: usually one project or one work context
- **tmux window**: one task inside that project (`editor`, `server`, `git`, etc.)
- **tmux pane**: a split inside one window

Good default for your workflow:

- **One terminal tab per machine/context**
- **One tmux session per project**
- **One tmux window per task**

Local and remote tmux are completely separate. If you `ssh` into EC2 or open a Codespace, start or attach tmux **there**.

## Survival Basics

Your tmux prefix is the default: `Ctrl-b`

| Key | What it does |
|-----|-------------|
| `Ctrl-b d` | Detach from tmux and leave it running |
| `Ctrl-b c` | New window in the current directory |
| `Ctrl-b ,` | Rename current window |
| `Ctrl-b n` / `p` | Next / previous window |
| `Ctrl-b 1`..`9` | Jump to window number |
| `Ctrl-b %` | Old vertical split is disabled in your config |
| `Ctrl-b |` | Vertical split (side by side) |
| `Ctrl-b -` | Horizontal split (top / bottom) |
| `Ctrl-b x` | Close current pane |
| `Ctrl-b z` | Zoom/unzoom current pane |
| `Ctrl-b [` | Enter copy mode |
| `Ctrl-b r` | Reload tmux config |
| `Ctrl-b T` | Open `sesh` session picker |

## Session Commands

Use these outside tmux or in a shell inside tmux:

```bash
tmux ls
tmux new -s myproject
tmux attach -t myproject
tmux kill-session -t myproject
```

Practical habit:

- First time in a project: `tmux new -s project-name`
- Later: `tmux attach -t project-name`
- If you forget names: `Ctrl-b T` or `tmux ls`

## Copy Mode

You enabled vi-style copy mode:

| Key | What it does |
|-----|-------------|
| `Ctrl-b [` | Enter copy mode |
| `v` | Start selection |
| `y` | Copy selection and exit |
| `q` | Exit copy mode |

## Suggested Layout

For one project session:

1. Window `editor`: Neovim
2. Window `server`: app/dev server
3. Window `shell`: git, tests, ad hoc commands
4. Optional pane split only when two things need to be visible at once

Bias toward **windows first, panes second**. Panes are useful, but too many become hard to navigate.

## Local + Remote Pattern

### Local machine

- Open Ghostty
- One tab for one broad context
- Start or attach tmux for that local project

### EC2 / remote dev box

- `ssh` into the box
- Start or attach tmux on the remote host
- Detach before disconnecting so work keeps running

### Codespaces

- Open the Codespace terminal
- Start or attach tmux inside the Codespace
- Treat it the same as any other remote Linux box

Important: a tmux session only exists on the machine where it was created.

## A Simple Default Workflow

```text
Ghostty tab
  -> ssh to machine if needed
  -> tmux attach -t project   (or create it)
  -> windows:
     1 editor
     2 server
     3 shell
```

That gives you:

- terminal tabs for machine/context
- tmux sessions for projects
- tmux windows for tasks

## Personal Notes

Add your own commands and habits here as they become real.

- 
