# Neovim / LazyVim Cheatsheet

A beginner-friendly reference for navigating LazyVim. This is your personal notebook — add to it as you learn.

## Key Concepts

- **Normal mode**: Default mode. You navigate and issue commands here. Press `Esc` to get back to it.
- **Insert mode**: For typing text. Press `i` to enter, `Esc` to leave.
- **Visual mode**: For selecting text. Press `v` to enter.
- **Command mode**: For running commands. Press `:` to enter (e.g., `:w` to save, `:q` to quit).
- **Leader key**: In LazyVim, the leader is `Space`. Many shortcuts start with `Space` + something.

## Survival Basics

| Key | What it does |
|-----|-------------|
| `Esc` | Go back to Normal mode (escape from anything) |
| `q` | **Close floating windows/popups** (like the Lazy plugin manager) |
| `i` | Enter Insert mode (start typing) |
| `:w` | Save the current file |
| `:q` | Quit (close current window) |
| `:wq` or `ZZ` | Save and quit |
| `:q!` | Quit without saving |
| `u` | Undo |
| `Ctrl+r` | Redo |

## Moving Around

| Key | What it does |
|-----|-------------|
| `h j k l` | Left, Down, Up, Right (arrow keys also work) |
| `w` / `b` | Jump forward/backward by word |
| `gg` / `G` | Go to top/bottom of file |
| `0` / `$` | Go to start/end of line |
| `Ctrl+d` / `Ctrl+u` | Scroll half-page down/up |
| `{` / `}` | Jump by paragraph |

## LazyVim Dashboard

When you open `nvim` with no file, you see the dashboard. The menu items are clickable or keyboard-accessible:

| Key | Dashboard action |
|-----|-----------------|
| `f` | Find file (fuzzy search) |
| `g` | Live grep (search file contents) |
| `r` | Recent files |
| `c` | Config (open LazyVim config files) |
| `l` | Lazy (opens the plugin manager — the screen you keep seeing) |
| `q` | Quit |

**If the Lazy plugin manager pops up**, just press `q` to close it. It's not an error.

## Leader Key Shortcuts (Space + ...)

The leader key is `Space`. Press it and wait — a popup (which-key) shows available options.

| Keys | What it does |
|------|-------------|
| `Space` | Show all available commands (wait for which-key popup) |
| `Space f` | Find/file commands |
| `Space s` | Search commands |
| `Space b` | Buffer (open file tabs) commands |
| `Space e` | Open file explorer (neo-tree) sidebar |
| `Space q` | Session/quit commands |
| `Space g` | Git commands |
| `Space l` | Lazy (plugin manager) |

## Working with Files

| Keys | What it does |
|------|-------------|
| `Space Space` | Find file by name (fuzzy search) |
| `Space f f` | Find file by name |
| `Space f r` | Recent files |
| `Space s g` | Search/grep across all files |
| `Space e` | Toggle file explorer sidebar |
| `Space b d` | Close current buffer (file tab) |
| `H` / `L` | Switch to prev/next buffer tab |

## Windows and Splits

| Keys | What it does |
|------|-------------|
| `Ctrl+h/j/k/l` | Move between split windows |
| `Space -` | Horizontal split |
| `Space \|` | Vertical split |
| `Space w d` | Close current window |

## Searching in a File

| Key | What it does |
|-----|-------------|
| `/` | Search forward (type pattern, press Enter) |
| `?` | Search backward |
| `n` / `N` | Next/previous search match |
| `*` | Search for word under cursor |

## Copy and Paste

| Key | What it does |
|-----|-------------|
| `yy` | Copy (yank) current line |
| `dd` | Cut (delete) current line |
| `p` | Paste after cursor |
| `P` | Paste before cursor |
| `v` + select + `y` | Copy a selection |

## Common "How Do I...?"

### Exit vim
`:q` to quit, `:q!` to force quit, `:wq` to save and quit, or just `ZZ`.

### Close that plugin manager popup
Press `q`. It's the Lazy plugin manager UI — you don't need it during normal editing.

### Open a file
`Space Space` or `Space f f` to fuzzy-find by name.

### Search across the project
`Space s g` to grep all files.

### Go back to the dashboard
`:` then type `Dashboard` and press Enter. Or just quit and reopen nvim.

### See what keys do what
Press `Space` and wait — the which-key popup shows all available shortcuts.

---

## Personal Notes

_Add your own discoveries and tips below as you learn:_

-
