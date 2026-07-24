#!/bin/bash
set -e

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

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Verification..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

pass() { echo "   ✅ $1"; ((CHECKS_PASSED++)); }
fail() { echo "   ❌ $1"; ((CHECKS_FAILED++)); }

for pkg in "${PACKAGES[@]}"; do
   if dpkg -s "$pkg" &>/dev/null; then
      pass "$pkg"
   else
      fail "$pkg NOT installed"
   fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CHECKS_FAILED" -eq 0 ]; then
   echo "🎉 All $CHECKS_PASSED packages installed!"
else
   echo "⚠️  $CHECKS_PASSED installed, $CHECKS_FAILED failed"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
