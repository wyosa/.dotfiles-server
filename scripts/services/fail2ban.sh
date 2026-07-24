#!/bin/bash
set -e

echo "🚫 Starting Fail2ban setup..."
echo ""

# ── Install ────────────────────────────────────────────────
if command -v fail2ban-server &>/dev/null; then
   echo "📌 Fail2ban is already installed"
else
   echo "📦 Installing fail2ban..."
   sudo apt update -qq && sudo apt install -y -qq fail2ban
   echo "✅ Fail2ban installed"
fi

echo ""

# ── Configure ──────────────────────────────────────────────
echo "🔧 Configuring jails..."

JAIL_FILE="/etc/fail2ban/jail.local"

sudo tee "$JAIL_FILE" >/dev/null <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 3
backend  = systemd

[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 24h
EOF

echo "   📄 Config written to $JAIL_FILE"
echo "   🔒 SSH: 3 attempts → 24h ban"
echo ""

# ── Enable and start ──────────────────────────────────────
echo "⚙️  Enabling and starting Fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
echo "✅ Fail2ban is running"

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

# 1. Binary exists
echo "1️⃣  Fail2ban binary"
if command -v fail2ban-server &>/dev/null; then
   pass "fail2ban-server found"
else
   fail "fail2ban-server not found"
fi

# 2. Service active
echo "2️⃣  Service status"
if systemctl is-active --quiet fail2ban; then
   pass "fail2ban.service is active"
else
   fail "fail2ban.service is NOT active"
fi

# 3. Enabled on boot
echo "3️⃣  Autostart on boot"
if systemctl is-enabled --quiet fail2ban; then
   pass "fail2ban.service is enabled"
else
   fail "fail2ban.service is NOT enabled"
fi

# 4. SSH jail active
echo "4️⃣  SSH jail"
if sudo fail2ban-client status sshd &>/dev/null; then
   BANNED=$(sudo fail2ban-client get sshd banned 2>/dev/null || echo "0")
   pass "sshd jail is active ($BANNED currently banned)"
else
   fail "sshd jail is NOT active"
fi

# 5. Config file exists
echo "5️⃣  Config file"
if [ -f "$JAIL_FILE" ]; then
   pass "$JAIL_FILE exists"
else
   fail "$JAIL_FILE not found"
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
echo "💡 Useful commands:"
echo "   sudo fail2ban-client status sshd   — jail status"
echo "   sudo fail2ban-client get sshd banned — banned IPs"
echo "   sudo fail2ban-client set sshd unbanip <IP> — unban"
