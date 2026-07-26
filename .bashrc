# ── Non-interactive guard ─────────────────────────────────
case $- in
   *i*) ;;
   *) return ;;
esac

# ── History ────────────────────────────────────────────────
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT='%F %T  '
shopt -s histappend
shopt -s cmdhist
# write history immediately — survives killed sessions and
# merges history across multiple SSH sessions
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ── Shell options ──────────────────────────────────────────
shopt -s checkwinsize
shopt -s cdspell
shopt -s dirspell

# ── Prompt ─────────────────────────────────────────────────
parse_git_branch() {
   local branch
   branch=$(git symbolic-ref --short HEAD 2>/dev/null) && echo " ($branch)"
}
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '

# ── Environment ────────────────────────────────────────────
export EDITOR=vim
export LANG=en_US.UTF-8

# ── Aliases ────────────────────────────────────────────────
if [ -f "$HOME/.bash_aliases" ]; then
   . "$HOME/.bash_aliases"
fi

# ── Completion ─────────────────────────────────────────────
if [ -f /etc/bash_completion ]; then
   . /etc/bash_completion
fi
