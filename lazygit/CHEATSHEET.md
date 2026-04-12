# LazyGit Cheatsheet

Small personal reference for reviewing Git changes in the terminal across local machines, Codespaces, and SSH sessions.

## Why This Fits

- `lazygit` is the Git review UI
- `tmux` is the session layer
- `ssh` moves you between machines

That gives you the same Git UI everywhere, even when the machine changes.

## Start

```bash
lg
```

Run it inside a repo. In a remote box or Codespace, SSH in first, then run `lg` there.

## Core Review Keys

| Key | What it does |
|-----|-------------|
| `tab` | Move across panels |
| `1` `2` `3` `4` `5` | Jump to a panel |
| `enter` | Drill into the selected item |
| `esc` | Back out / close panel mode |
| `+` / `_` | Cycle screen modes for more diff space |
| `/` | Filter the current list |

## Diff Review

| Key | What it does |
|-----|-------------|
| `j` / `k` | Move through files or commits |
| `PgUp` / `PgDn` | Scroll the diff preview without switching panes |
| `space` | Stage or unstage the selected hunk/line |
| `v` | Start a range selection in a diff |
| `a` | Select the whole hunk |
| `d` | Open the diff for the selected file |
| `e` | Open the file in your editor |

## Commit History

| Key | What it does |
|-----|-------------|
| `3` | Jump to commits/log |
| `enter` | View the commit contents |
| `shift-w` | Compare against another commit or ref |
| `i` | Start interactive rebase |
| `shift-a` | Amend an older commit with staged changes |
| `shift-c` / `shift-v` | Cherry-pick copy / paste |
| `z` / `shift-z` | Undo / redo supported Git actions |

## PR / Branch Flow

| Key | What it does |
|-----|-------------|
| `5` | Jump to branches |
| `space` | Checkout the selected branch |
| `w` | Create a worktree from the selected branch |
| `shift-p` | Push |
| `shift-f` | Pull / fetch menu |
| `shift-g` | Open the GitHub PR for the branch if `gh` is authenticated |

## Local + Remote Habit

- One Ghostty tab per machine or SSH context
- One tmux session per repo
- One tmux window called `git` that stays on `lg`

That keeps the workflow identical on your Mac, in Codespaces, and on EC2.

## Notes

Add only real habits here as they stick.
