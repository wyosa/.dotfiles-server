#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

echo "🚫 Starting Fail2ban setup..."
echo ""

# ── Install ────────────────────────────────────────────────
if command -v fail2ban-server &>/dev/null; then
   echo "📌 Fail2ban is already installed"
else
   echo "📦 Installing fail2ban..."
   sudo apt update -qq
   sudo apt install -y -qq fail2ban
   echo "✅ Fail2ban installed"
fi

# The systemd backend needs journal support, even on existing installs.
if ! /usr/bin/python3 -c 'from systemd import journal' &>/dev/null; then
   echo "📦 Installing Python systemd journal support..."
   sudo apt update -qq
   sudo apt install -y -qq python3-systemd
fi

echo ""

# ── Configure ──────────────────────────────────────────────
echo "🔧 Configuring jails..."

SSH_PORTS=$(ssh_ports)
[ -n "$SSH_PORTS" ] || { err "Cannot determine SSH ports"; exit 1; }
SSH_PORTS=$(printf '%s\n' "$SSH_PORTS" | paste -sd, -)
JAIL_FILE="/etc/fail2ban/jail.d/99-dotfiles-server.local"
sudo install -d -m 755 /etc/fail2ban/jail.d

sudo tee "$JAIL_FILE" >/dev/null <<EOF
[sshd]
enabled  = true
port     = $SSH_PORTS
filter   = sshd
findtime = 10m
maxretry = 3
backend  = systemd
bantime  = 24h
EOF

echo "   📄 Config written to $JAIL_FILE"
echo "   🔒 SSH: 3 attempts → 24h ban"
echo ""

# ── Enable and start ──────────────────────────────────────
echo "⚙️  Enabling and starting Fail2ban..."
sudo fail2ban-client -t
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# An active systemd service does not mean its jails have finished loading.
echo "⏳ Waiting for the sshd jail..."
JAIL_READY=false
for ((attempt = 0; attempt < 30; attempt++)); do
   if JAIL_STATUS=$(sudo fail2ban-client status sshd 2>&1); then
      JAIL_READY=true
      break
   fi
   sleep 1
done

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running verification checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

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
if [ "$JAIL_READY" = true ]; then
   pass "sshd jail is active"
else
   fail "sshd jail did not become ready"
   printf '%s\n' "$JAIL_STATUS"
   sudo journalctl -u fail2ban -n 30 --no-pager || true
   sudo tail -n 30 /var/log/fail2ban.log 2>/dev/null || true
fi

# 5. Config file exists
echo "5️⃣  Config file"
if [ -f "$JAIL_FILE" ]; then
   pass "$JAIL_FILE exists"
else
   fail "$JAIL_FILE not found"
fi

# ── Summary ────────────────────────────────────────────────
check_summary
echo ""
echo "💡 Useful commands:"
echo "   sudo fail2ban-client status sshd   — jail status"
echo "   sudo fail2ban-client get sshd banned — banned IPs"
echo "   sudo fail2ban-client set sshd unbanip <IP> — unban"
