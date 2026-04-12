# Enable Powerlevel10k instant prompt. Keep this near the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Git SSH (customize per environment)
if [[ -f "$HOME/.ssh/github_key" ]]; then
  export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/github_key"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Editor: nvim (LazyVim) everywhere; VS Code as KUBE_EDITOR on macOS
export EDITOR='nvim'
if [[ -z "$CODESPACES" ]] && [[ -x "$(command -v code)" ]]; then
  export KUBE_EDITOR='code --wait'
else
  export KUBE_EDITOR='nvim'
fi

export TERM="xterm-256color"

# Company-specific
export NGROK_EMAIL="${NGROK_EMAIL:-alex@ngrok.com}"
export NGROK_LOGS_PAGER="${NGROK_LOGS_PAGER:-lnav}"
export NGROK_DISABLE_ND_AUTO_RECOMPILATION=true
export ND_AUTO_SSO_LOGIN=true
export NGROK_DISABLE_ND_INTERACTIVE_HELP=true
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"

# Linuxbrew
if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export KUBECONFIG=$HOME/.kube/config

[ -f $HOME/fubectl.source ] && source $HOME/fubectl.source

export AWS_PAGER=''
export AWS_PROFILE="${AWS_PROFILE:-ngrok}"

# Powerlevel10k theme
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  jsontools
  sudo
  kubectl
  last-working-dir
  tmux
  zsh-autosuggestions
  zsh-syntax-highlighting
)

if command -v autojump &> /dev/null; then
  plugins+=(autojump)
fi

source $ZSH/oh-my-zsh.sh

# Make filename and argument completion case-insensitive.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Powerlevel10k prompt config with transient prompt support.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Theme color overlay (managed by themes/switch-theme.sh)
_dotfiles_theme_dir="${0:A:h}"
[[ "$_dotfiles_theme_dir" == */code/dotfiles ]] || _dotfiles_theme_dir="$HOME/code/dotfiles"
if [[ -f "$_dotfiles_theme_dir/themes/current" ]]; then
  _theme="$(<"$_dotfiles_theme_dir/themes/current")"
  [[ -f "$_dotfiles_theme_dir/themes/$_theme/p10k-colors.zsh" ]] && \
    source "$_dotfiles_theme_dir/themes/$_theme/p10k-colors.zsh"
  # On non-Ghostty terminals (SSH, etc.), inject the ANSI palette via OSC escapes
  # so background/foreground/base colors match the theme.
  if [[ "$TERM_PROGRAM" != "ghostty" && -f "$_dotfiles_theme_dir/themes/$_theme/terminal-colors.sh" ]]; then
    source "$_dotfiles_theme_dir/themes/$_theme/terminal-colors.sh"
  fi
  unset _theme
fi
unset _dotfiles_theme_dir

# Kubernetes aliases - use functions to handle late PATH setup (nix/direnv)
# Unset the 'k' alias from kubectl plugin before defining our function
unalias k 2>/dev/null

k() {
  if command -v kubecolor &> /dev/null; then
    kubecolor "$@"
  elif command -v kubectl &> /dev/null; then
    kubectl "$@"
  else
    echo "kubectl not found in PATH" >&2
    return 1
  fi
}

kctx() { kubectl ctx "$@"; }
kns() { kubectl ns "$@"; }

# Setup completions if kubectl is available at shell init
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
  compdef k=kubectl
fi

# ls aliases - prefer eza > exa > ls with colors
if command -v eza &> /dev/null; then
  alias ls='eza --color=auto --icons -la'
  alias la='eza --color=auto --icons -la'
  alias ll='eza --color=auto --icons -la'
elif command -v exa &> /dev/null; then
  alias ls='exa --color=auto --icons -la'
  alias la='exa --color=auto --icons -la'
  alias ll='exa --color=auto --icons -la'
else
  alias ls='ls --color=auto -la'
  alias la='ls --color=auto -la'
  alias ll='ls --color=auto -la'
fi

alias t="tree --du -h -L"
alias gs='git status'

# bat/batcat - Ubuntu/Debian uses 'batcat' for bat
# Use --paging=never so output stays in terminal scrollback (scroll with mouse, clear with Cmd+K).
# Use \cat to bypass the alias when you need raw output.
if command -v bat &> /dev/null; then
  alias cat='bat --paging=never'
  alias gd='git diff | bat'
elif command -v batcat &> /dev/null; then
  alias cat='batcat --paging=never'
  alias gd='git diff | batcat'
else
  alias gd='git diff'
fi

# difft for git diff (optional)
if command -v difft &> /dev/null; then
  alias gdt='GIT_EXTERNAL_DIFF=difft git diff'
fi

# batgrep (only if available)
if command -v batgrep &> /dev/null; then
  alias rg='batgrep'
fi

alias watch='watch '

alias b='nd go install nd'
alias ndcf='nd config run | fx'
alias c='claude --enable-auto-mode'
alias v='nvim'

# LLM quick-ask — configurable via ASK_BACKEND (codex|claude)
export ASK_BACKEND="${ASK_BACKEND:-codex}"
_dotfiles_scripts="${0:A:h}"
[[ "$_dotfiles_scripts" == */code/dotfiles ]] || _dotfiles_scripts="$HOME/code/dotfiles"

# ? = concise (copy-paste ready), ?? = explanation mode
# noglob prevents zsh from treating ? as a glob wildcard
alias '?'='noglob _ask_concise'
alias '??'='noglob _ask_explain'
_ask_concise() { "$_dotfiles_scripts/scripts/ask" --concise "$*"; }
_ask_explain() { "$_dotfiles_scripts/scripts/ask" "$*"; }
alias ask="$_dotfiles_scripts/scripts/ask"

function lazygit() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
  local config_files="$config_dir/config.yml"
  local new_dir_file="${XDG_STATE_HOME:-$HOME/.local/state}/lazygit/newdir"

  [[ -f "$config_dir/theme.yml" ]] && config_files="$config_files,$config_dir/theme.yml"
  mkdir -p "${new_dir_file:h}"
  export LAZYGIT_NEW_DIR_FILE="$new_dir_file"

  command lazygit --use-config-file="$config_files" "$@"
  local status=$?

  if [[ -f "$LAZYGIT_NEW_DIR_FILE" ]]; then
    cd "$(cat "$LAZYGIT_NEW_DIR_FILE")"
    rm -f "$LAZYGIT_NEW_DIR_FILE" >/dev/null
  fi

  return $status
}

alias lg='lazygit'

# fzf history (only if fzf available)
if command -v fzf &> /dev/null; then
  alias h='history | fzf'
fi

# direnv
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

# ngrok shell hook (devbox)
if [[ -f "$HOME/ngrok/.cache/ngrok-host-shellhook" ]]; then
  source "$HOME/ngrok/.cache/ngrok-host-shellhook"
fi

function gp() {
  git push origin $(git symbolic-ref --short HEAD)
}
function gc() {
  git add .;
  git commit -m "$@"
}
function ga() {
  gc "$1"
  gp
}

function nds() {
  export NGROK_ENV="$1"
}

# Atuin — shell history with sync (replaces ctrl+r)
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh)"
  # Unbind Atuin AI's ? keybinding — we use ? / ?? as LLM shell functions
  bindkey -r '?' 2>/dev/null
  bindkey '?' self-insert 2>/dev/null
fi

# Carapace — multi-shell completions
if command -v carapace &> /dev/null; then
  source <(carapace _carapace zsh)
fi
