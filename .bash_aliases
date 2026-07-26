# ── Listing ────────────────────────────────────────────────
alias ll='ls -lah'
alias la='ls -A'
alias lf='ls -alF'
alias lt='ls -ltah'
alias ld='ls -d */'

# ── Navigation ─────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── System ─────────────────────────────────────────────────
alias reboot='sudo reboot'
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'

install() { sudo apt install "$@"; }
uninstall() { sudo apt remove "$@"; }
search() { apt search "$@"; }

# ── Docker ─────────────────────────────────────────────────
# no sudo here — docker.sh adds your user to the docker group
alias dc='docker compose'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='docker images'
alias dlog='docker logs -f --tail 100'

# ── systemd ────────────────────────────────────────────────
alias sctl='sudo systemctl'
alias jctl='sudo journalctl'

# ── Find / Search ──────────────────────────────────────────
fh() { find . -name "*$1*"; }

# ── Misc ───────────────────────────────────────────────────
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='sudo ss -tlnp'
alias myip='hostname -I'
alias myipext='curl -s ifconfig.me && echo'
alias aliases='echo "── Aliases ──" && alias'
alias path='echo -e ${PATH//:/\\n}'
