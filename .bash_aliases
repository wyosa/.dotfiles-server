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
alias docker='sudo docker'
alias dc='sudo docker compose'
alias dps='sudo docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dimg='sudo docker images'
alias dlog='sudo docker logs -f --tail 100'

# ── Find / Search ──────────────────────────────────────────
fh() { find . -name "*$1*"; }

# ── Misc ───────────────────────────────────────────────────
alias ports='sudo ss -tlnp'
alias myip='hostname -I'
alias aliases='echo "── Aliases ──" && alias'
alias path='echo -e ${PATH//:/\\n}'
