# ZSH Configuration for ThinkPad X1 Carbon
# Source this from ~/.zshrc or symlink to ~/.config/zsh/.zshrc

# ============================================================
# Plugins (loaded from ~/.config/zsh/)
# ============================================================
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.config/zsh/spaceship/spaceship.zsh"

# ============================================================
# Shell History
# ============================================================
HISTFILE="$ZDOTDIR/.zhistory"
setopt EXTENDED_HISTORY
SAVEHIST=5000
HISTSIZE=2000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# ============================================================
# Completion
# ============================================================
autoload -U colors && colors
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# ============================================================
# Spaceship Prompt
# ============================================================
SPACESHIP_PROMPT_ORDER=(
  dir           # Current directory section
  git           # Git section (git_branch + git_status)
  venv          # virtualenv section
  line_sep      # Line break
  char          # Prompt character
)

# ============================================================
# Options
# ============================================================
setopt AUTO_CD
setopt COMPLETE_ALIASES

# Vi mode
bindkey -v

# ============================================================
# Autosuggestion
# ============================================================
bindkey '^f' autosuggest-accept
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true

# ============================================================
# FZF Integration (env vars set via environment.d)
# ============================================================
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh

# ============================================================
# Aliases
# ============================================================
alias ls='lsd'
alias ll='ls -alh'
alias tmux='tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf'
alias wget="wget --hsts-file $XDG_CACHE_HOME/wget/wget-hsts"

# ============================================================
# Terminal Integration (foot/ghostty compatible)
# ============================================================
function osc7-pwd() {
    emulate -L zsh
    setopt extendedglob
    local LC_ALL=C
    printf '\e]7;file://%s%s\e\' $HOST ${PWD//(#m)([^@-Za-z&-;_~])/%${(l:2::0:)$(([##16]#MATCH))}}
}

function chpwd-osc7-pwd() {
    (( ZSH_SUBSHELL )) || osc7-pwd
}
add-zsh-hook -Uz chpwd chpwd-osc7-pwd

# Shell integration for prompt marking
function precmd {
    if ! builtin zle; then
        print -n "\e]133;D\e\\"
    else
        print -Pn "\e]133;A\e\\"
    fi
}

function preexec {
    print -n "\e]133;C\e\\"
}

# ============================================================
# Syntax Highlighting & History Search (load last)
# ============================================================
source "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
