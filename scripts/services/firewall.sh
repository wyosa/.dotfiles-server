#!/bin/bash
set -e

echo "🧱 Starting UFW firewall setup..."
echo ""

# ── Install ────────────────────────────────────────────────
if command -v ufw &>/dev/null; then
   echo "📌 UFW is already installed"
else
   echo "📦 Installing ufw..."
   sudo apt update -qq && sudo apt install -y -qq ufw
   echo "✅ UFW installed"
fi

echo ""

# ── Configure rules ────────────────────────────────────────
echo "🔧 Configuring rules..."

# default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "   🔒 Default: deny incoming, allow outgoing"

# SSH (critical — do this BEFORE enabling)
sudo ufw allow ssh
echo "   🔑 SSH (port 22) allowed"

# common services (optional, uncomment as needed)
# sudo ufw allow http
# sudo ufw allow https
# sudo ufw allow 8080

echo ""

# ── Enable ─────────────────────────────────────────────────
if sudo ufw status | grep -q "Status: active"; then
   echo "📌 UFW is already active"
else
   echo "⚡ Enabling UFW..."
   sudo ufw --force enable
   echo "✅ UFW enabled"
fi

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running verification checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

pass() { echo "   ✅ $1"; ((CHECKS_PASSED++)); }
fail() { echo "   ❌ $1"; ((CHECKS_FAILED++)); }

# 1. UFW installed
echo "1️⃣  UFW binary"
if command -v ufw &>/dev/null; then
   pass "ufw found at $(command -v ufw)"
else
   fail "ufw not found"
fi

# 2. UFW active
echo "2️⃣  Firewall status"
if sudo ufw status | grep -q "Status: active"; then
   pass "UFW is active"
else
   fail "UFW is NOT active"
fi

# 3. Default deny incoming
echo "3️⃣  Default incoming policy"
if sudo ufw status verbose | grep -qi "deny (incoming)"; then
   pass "default deny incoming"
else
   fail "default incoming policy is not deny"
fi

# 4. SSH allowed
echo "4️⃣  SSH rule"
if sudo ufw status | grep -qE "22|ssh.*ALLOW"; then
   pass "SSH is allowed"
else
   fail "SSH rule not found — you may be locked out!"
fi

# 5. Enabled on boot
echo "5️⃣  Autostart on boot"
if systemctl is-enabled --quiet ufw 2>/dev/null; then
   pass "ufw.service is enabled"
else
   fail "ufw.service is NOT enabled for autostart"
fi

# ── Summary ────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CHECKS_FAILED" -eq 0 ]; then
   echo "🎉 All $CHECKS_PASSED checks passed!"
else
   echo "⚠️  $CHECKS_PASSED passed, $CHECKS_FAILED failed"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Current rules ──────────────────────────────────────────
echo "📋 Current rules:"
sudo ufw status numbered
echo ""
echo "💡 Add more rules:"
echo "   sudo ufw allow http"
echo "   sudo ufw allow https"
echo "   sudo ufw allow from 192.168.1.0/24"
echo "   sudo ufw delete <number>"
