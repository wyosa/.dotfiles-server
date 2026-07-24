#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

DOTFILES=(.bashrc .bash_aliases .gitconfig .tmux.conf)

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}ℹ️  $1${NC}"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }

# ── OS Detection ───────────────────────────────────────────
detect_os() {
   if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS_ID="$ID"
      OS_VERSION="$VERSION_ID"
      OS_CODENAME="${VERSION_CODENAME:-unknown}"
   else
      err "Cannot detect OS — /etc/os-release not found"
      exit 1
   fi

   case "$OS_ID" in
      ubuntu|debian) ;;
      *)
         err "Unsupported OS: $OS_ID (only Ubuntu/Debian supported)"
         exit 1
         ;;
   esac
}

# ── Dotfiles ───────────────────────────────────────────────
link_dotfiles() {
   echo ""
   echo -e "${BOLD}📁 Linking dotfiles...${NC}"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

   for dotfile in "${DOTFILES[@]}"; do
      src="$REPO_DIR/$dotfile"
      dst="$HOME/$dotfile"

      if [ ! -f "$src" ]; then
         warn "$dotfile not found in repo, skipping"
         continue
      fi

      if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
         ok "$dotfile already linked"
      elif [ -f "$dst" ] || [ -L "$dst" ]; then
         backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
         mv "$dst" "$backup"
         ln -sf "$src" "$dst"
         ok "$dotfile linked (old → $backup)"
      else
         ln -sf "$src" "$dst"
         ok "$dotfile linked"
      fi
   done

   echo ""
   info "Run 'source ~/.bashrc' or re-login to apply"
}

# ── Menu ───────────────────────────────────────────────────
show_menu() {
   echo ""
   echo -e "${BOLD}🖥  dotfiles-server — setup for Ubuntu/Debian${NC}"
   echo -e "   OS: ${GREEN}$OS_ID $OS_VERSION ($OS_CODENAME)${NC}"
   echo ""
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "  1) 📁 Link dotfiles only"
   echo "  2) 📦 Base packages"
   echo "  3) ⚙️  System config (timezone, swap, hostname)"
   echo "  4) 🐳 Docker"
   echo "  5) 🔑 SSH server"
   echo "  6) 🧱 Firewall (UFW)"
   echo "  7) 🚫 Fail2ban"
   echo "  8) 🔄 Unattended upgrades"
   echo "  9) 🛡️  Security bundle (5 + 6 + 7 + 8)"
   echo "  a) 🚀 Full install (1 + 2 + 3 + 9)"
   echo "  q) Quit"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo ""
}

run_script() {
   local script="$SCRIPT_DIR/$1"
   if [ -f "$script" ]; then
      echo ""
      bash "$script"
   else
      err "Script not found: $script"
   fi
}

# ── Main ───────────────────────────────────────────────────
detect_os

if [ "${1:-}" = "--all" ]; then
   link_dotfiles
   run_script "packages.sh"
   run_script "system.sh"
   run_script "services/sshd.sh"
   run_script "services/firewall.sh"
   run_script "services/fail2ban.sh"
   run_script "services/unattended-upgrades.sh"
   echo ""
   ok "Full install complete!"
   exit 0
fi

while true; do
   show_menu
   read -rp "Select [1-9/a/q]: " choice
   case "$choice" in
      1) link_dotfiles ;;
      2) run_script "packages.sh" ;;
      3) run_script "system.sh" ;;
      4) run_script "services/docker.sh" ;;
      5) run_script "services/sshd.sh" ;;
      6) run_script "services/firewall.sh" ;;
      7) run_script "services/fail2ban.sh" ;;
      8) run_script "services/unattended-upgrades.sh" ;;
      9)
         run_script "services/sshd.sh"
         run_script "services/firewall.sh"
         run_script "services/fail2ban.sh"
         run_script "services/unattended-upgrades.sh"
         ;;
      a|A)
         link_dotfiles
         run_script "packages.sh"
         run_script "system.sh"
         run_script "services/sshd.sh"
         run_script "services/firewall.sh"
         run_script "services/fail2ban.sh"
         run_script "services/unattended-upgrades.sh"
         echo ""
         ok "Full install complete!"
         ;;
      q|Q) echo "👋 Bye!"; exit 0 ;;
      *) warn "Invalid option" ;;
   esac
done
