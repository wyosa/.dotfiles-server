#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/common.sh"

echo "📦 Installing base packages..."
echo ""

PACKAGES=(
   # essentials
   curl
   wget
   git
   unzip
   rsync
   # monitoring
   htop
   iotop
   ncdu
   # network
   net-tools
   dnsutils
   iproute2
   # editors
   vim
   # terminal
   tmux
   tree
   jq
   # build
   build-essential
   # misc
   software-properties-common
   apt-transport-https
   ca-certificates
   gnupg
   lsb-release
)

# ── Install ────────────────────────────────────────────────
echo "🔄 Updating package lists..."
sudo apt update -qq

echo ""
echo "📥 Installing ${#PACKAGES[@]} packages..."
sudo apt install -y -qq "${PACKAGES[@]}"

# Task is distributed through its official APT repository.
if ! command -v task >/dev/null; then
   TASK_SETUP=$(mktemp)
   trap 'rm -f "$TASK_SETUP"' EXIT
   curl -fsSL https://dl.cloudsmith.io/public/task/task/setup.deb.sh -o "$TASK_SETUP"
   sudo bash "$TASK_SETUP"
   sudo apt install -y -qq task
   rm -f "$TASK_SETUP"
   trap - EXIT
fi

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Verification..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for pkg in "${PACKAGES[@]}"; do
   if dpkg -s "$pkg" &>/dev/null; then
      pass "$pkg"
   else
      fail "$pkg NOT installed"
   fi
done

if task --version >/dev/null 2>&1 && task --help 2>&1 | grep -q 'Taskfile'; then
   pass "$(task --version)"
else
   fail "Go Task is missing or another program is installed as task"
fi

check_summary
