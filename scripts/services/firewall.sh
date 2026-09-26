#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

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

# Abort before changing policy if the SSH configuration cannot be read.
SSH_PORTS=$(ssh_ports)
[ -n "$SSH_PORTS" ] || { err "Cannot determine SSH ports"; exit 1; }

# Allow configured ports and the active session before enabling the firewall.
for port in $SSH_PORTS; do
   sudo ufw limit "$port/tcp"
done

# default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "   🔒 Default: deny incoming, allow outgoing"

echo "   🔑 SSH ports allowed with rate-limit: $(printf '%s\n' "$SSH_PORTS" | paste -sd, -)"

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

# 4. SSH allowed (ALLOW or LIMIT)
echo "4️⃣  SSH rule"
for port in $SSH_PORTS; do
   if sudo ufw status | grep -qE "^${port}/tcp[[:space:]].*(ALLOW|LIMIT)"; then
      pass "SSH port $port is allowed"
   else
      fail "SSH rule for port $port not found"
   fi
done

# 5. Enabled on boot
echo "5️⃣  Autostart on boot"
if systemctl is-enabled --quiet ufw 2>/dev/null; then
   pass "ufw.service is enabled"
else
   fail "ufw.service is NOT enabled for autostart"
fi

# ── Summary ────────────────────────────────────────────────
check_summary
echo ""

# ── Current rules ──────────────────────────────────────────
echo "📋 Current rules:"
sudo ufw status numbered
echo "Docker-published ports are controlled by Compose bindings, not UFW INPUT rules."
echo ""
echo "💡 Add more rules:"
echo "   sudo ufw allow http"
echo "   sudo ufw allow https"
echo "   sudo ufw allow from 192.168.1.0/24"
echo "   sudo ufw delete <number>"
