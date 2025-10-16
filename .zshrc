# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Git SSH (customize per environment)
if [[ -f "$HOME/.ssh/github_key" ]]; then
  export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/github_key"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Editor: Use 'vi' in Codespaces/EC2, 'code' on macOS
if [[ -n "$CODESPACES" ]] || [[ ! -x "$(command -v code)" ]]; then
  export EDITOR='nvim'
  export KUBE_EDITOR='nvim'
else
  export EDITOR='code'
  export KUBE_EDITOR='code --wait'
fi

export TERM="xterm-256color"

# Company-specific (customize as needed)
export NGROK_EMAIL="${NGROK_EMAIL:-alex@ngrok.com}"
export NGROK_LOGS_PAGER="${NGROK_LOGS_PAGER:-lnav}"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export KUBECONFIG=$HOME/.kube/config

[ -f $HOME/fubectl.source ] && source $HOME/fubectl.source

export AWS_PAGER=''
export AWS_PROFILE="${AWS_PROFILE:-default}"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  jsontools
  sudo
  autojump
  kubectl
  last-working-dir
  tmux
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

ngrok_environment() {
  echo -n "NGROK $NGROK_ENV"
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

POWERLEVEL9K_INSTANT_PROMPT=quiet

# http://nerdfonts.com/#cheat-lssheet
POWERLEVEL9K_CUSTOM_FIRE="echo -n '\ue780'"
# POWERLEVEL9K_CUSTOM_FIRE_BACKGROUND="blue"
POWERLEVEL9K_CUSTOM_FIRE_FOREGROUND="red"

# Sets new icons on the power bar (triangle by default)
# Need to see if i can find a way to only apply this on the newline
# POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=$'\uE0B1'
# POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=$'\uE0B3'
POWERLEVEL9K_VCS_BRANCH_ICON=$'\ue727 '
POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=''

POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD='0'
# POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='black'
# POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='blue'

# POWERLEVEL9K_KUBECONTEXT_BACKGROUND='005'
# POWERLEVEL9K_KUBECONTEXT_FOREGROUND='000'


# POWERLEVEL9K_STATUS_ERROR_BACKGROUND='blue'
# POWERLEVEL9K_STATUS_OK_BACKGROUND='blue'
# POWERLEVEL9K_STATUS_ERROR_FOREGROUND='red'
# POWERLEVEL9K_STATUS_OK_FOREGROUND='green3'


POWERLEVEL9K_CUSTOM_NGROK="ngrok_environment"
# POWERLEVEL9K_CUSTOM_NGROK_BACKGROUND='blue'
# POWERLEVEL9K_CUSTOM_NGROK_FOREGROUND='darkgreen'


POWERLEVEL9K_GO_VERSION_BACKGROUND='021'
# POWERLEVEL9K_GO_VERSION_FOREGROUND='white'

# POWERLEVEL9K_VCS_CLEAN_FOREGROUND='green'
# POWERLEVEL9K_VCS_CLEAN_BACKGROUND='blue'
# POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='green3'
# POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='blue'
# POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='orangered1'
# POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='blue'

# POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='blue'
# POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='white'

# POWERLEVEL9K_BATTERY_CHARGING_BACKGROUND='lightgreen'
# POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND='black'
# POWERLEVEL9K_BATTERY_CHARGED_BACKGROUND='green'
# POWERLEVEL9K_BATTERY_CHARGED_FOREGROUND='black'
# POWERLEVEL9K_BATTERY_DISCONNECTED_BACKGROUND='orangered1'
# POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND='green3'
# POWERLEVEL9K_BATTERY_LOW_BACKGROUND='lightred'
# POWERLEVEL9K_BATTERY_LOW_FOREGROUND='green3'

# POWERLEVEL9K_TIME_BACKGROUND='orangered1'



unset POWERLEVEL9K_TERRAFORM_VERSION_SHOW_ON_COMMAND
unset POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND

# # Customise the Powerlevel9k prompts
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  custom_fire
  status
  dir
  vcs
  kubecontext
  custom_ngrok
  go_version
  newline

  terraform
  ssh
  newline
)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  command_execution_time
  time
  battery
)

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

compdef kubecolor=kubectl
complete -F __start_kubectl k

alias k="kubecolor"
alias kctx="kubectl ctx"
alias kns="kubectl ns"

alias ls='exa --color=auto --icons -la'
alias la='exa --color=auto --icons -la'
alias ll='exa --color=auto --icons -la'
alias t="tree --du -h -L"

alias gs='git status'
alias gd='git diff | bat'
alias gdt='GIT_EXTERNAL_DIFF=difft git diff'

alias cat='bat'
alias rg='batgrep'
alias watch='watch '
alias vi='nvim'

alias f='fuck'

alias b='nd go install nd'
alias ndcf='nd config run | fx'
alias h='history | fzf'

# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# neofetch

source <(kubectl completion zsh)
# source "/ngrok-host-shellhook"
# source "/Users/alex/code/ngrok/.cache/ngrok-host-shellhook"

eval $(thefuck --alias)

