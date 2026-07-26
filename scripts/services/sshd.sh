#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

echo "🚀 Starting SSH server setup..."
echo ""

# ── Check if already installed and running ─────────────────
if command -v sshd &>/dev/null; then
   echo "📌 openssh-server is already installed"
   if systemctl is-active --quiet ssh; then
      echo "✅ SSH service is already running"
   else
      echo "⚠️  SSH is installed but not running, starting..."
      sudo systemctl enable ssh
      sudo systemctl start ssh
      echo "✅ SSH service started"
   fi
else
   # ── Install ────────────────────────────────────────────────
   echo "📦 Installing openssh-server..."
   sudo apt update -qq && sudo apt install -y -qq openssh-server
   echo "✅ openssh-server installed"
   echo ""

   # ── Backup config ──────────────────────────────────────────
   echo "💾 Backing up sshd_config..."
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
   echo "✅ Backup saved to /etc/ssh/sshd_config.bak"
   echo ""
fi

# ── Security settings (always applied) ─────────────────────
echo "🔧 Applying security settings..."

# Ubuntu 22.04+ / Debian 12+ ship drop-in configs that override the main file
if [ -d /etc/ssh/sshd_config.d ]; then
   for conf in /etc/ssh/sshd_config.d/*.conf; do
      [ -f "$conf" ] || continue
      sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$conf"
      sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' "$conf"
      sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$conf"
   done
fi

sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
echo "   🔒 Root login disabled"
echo "   🔑 Password authentication enabled"
echo "   🔒 Public key authentication disabled"
echo "   🔒 MaxAuthTries = 3"
echo "   🔒 X11Forwarding disabled"

# ── Enable and start ──────────────────────────────────────
echo ""
echo "⚙️  Validating config and restarting SSH service..."
if ! sudo sshd -t; then
   err "sshd_config has syntax errors — NOT restarting. Fix the config first."
   exit 1
fi
sudo systemctl enable ssh
sudo systemctl reload ssh 2>/dev/null || sudo systemctl restart ssh
echo "✅ SSH service is running"

echo ""

# effective port (respects a custom Port directive)
SSH_PORT=$(sudo sshd -T 2>/dev/null | awk '/^port /{print $2; exit}')
SSH_PORT="${SSH_PORT:-22}"

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running verification checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. sshd binary exists
echo "1️⃣  sshd binary"
if command -v sshd &>/dev/null; then
   pass "sshd found at $(command -v sshd)"
else
   fail "sshd binary not found"
fi

# 2. Config syntax valid
echo "2️⃣  Config syntax"
if sudo sshd -t 2>/dev/null; then
   pass "sshd_config syntax is valid"
else
   fail "sshd_config has syntax errors — run 'sudo sshd -t' to see details"
fi

# 3. Service active
echo "3️⃣  Service status"
if systemctl is-active --quiet ssh; then
   pass "ssh.service is active"
else
   fail "ssh.service is NOT active"
fi

# 4. Service enabled on boot
echo "4️⃣  Autostart on boot"
if systemctl is-enabled --quiet ssh; then
   pass "ssh.service is enabled (will start on boot)"
else
   fail "ssh.service is NOT enabled for autostart"
fi

# 5. SSH port is listening
echo "5️⃣  Port listening"
if ss -tlnp | grep -q ":${SSH_PORT}\b"; then
   pass "sshd is listening on port $SSH_PORT"
else
   fail "nothing is listening on port $SSH_PORT"
fi

# 6. sshd process running
echo "6️⃣  Process check"
SSHD_PID=$(pgrep -x sshd | head -1 || true)
if [ -n "$SSHD_PID" ]; then
   pass "sshd process running (PID $SSHD_PID)"
else
   fail "no sshd process found"
fi

# 7. Loopback connection test
echo "7️⃣  Connection test (localhost)"
if ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no -p "$SSH_PORT" localhost exit 2>/dev/null; then
   pass "localhost SSH connection successful"
else
   if ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no -p "$SSH_PORT" localhost exit 2>&1 | grep -qi "permission denied"; then
      pass "sshd responds on localhost (auth required — expected)"
   else
      fail "could not connect to sshd on localhost"
   fi
fi

# 8. Security settings applied
echo "8️⃣  Security settings"
if sudo sshd -T 2>/dev/null | grep -qi "permitrootlogin no"; then
   pass "PermitRootLogin is disabled"
else
   fail "PermitRootLogin is NOT set to 'no'"
fi

if sudo sshd -T 2>/dev/null | grep -qi "passwordauthentication yes"; then
   pass "PasswordAuthentication is enabled"
else
   fail "PasswordAuthentication is NOT enabled"
fi

if sudo sshd -T 2>/dev/null | grep -qi "pubkeyauthentication no"; then
   pass "PubkeyAuthentication is disabled"
else
   fail "PubkeyAuthentication is NOT disabled"
fi

# 9. Host keys exist
echo "9️⃣  Host keys"
KEY_COUNT=$(ls /etc/ssh/ssh_host_*_key 2>/dev/null | wc -l)
if [ "$KEY_COUNT" -gt 0 ]; then
   pass "$KEY_COUNT host key(s) present"
else
   fail "no host keys found in /etc/ssh/"
fi

# 10. Firewall check (if ufw is installed)
echo "🔟 Firewall"
if command -v ufw &>/dev/null; then
   if sudo ufw status 2>/dev/null | grep -q "inactive"; then
      pass "ufw is inactive (port $SSH_PORT not blocked)"
   elif sudo ufw status 2>/dev/null | grep -qE "${SSH_PORT}(/tcp)?[[:space:]]+(ALLOW|LIMIT)"; then
      pass "ufw allows port $SSH_PORT"
   else
      fail "ufw is active but port $SSH_PORT may not be allowed — run 'sudo ufw limit ssh'"
   fi
else
   pass "ufw not installed (no firewall blocking)"
fi

# ── Summary ────────────────────────────────────────────────
check_summary
echo ""

# ── Connection info ────────────────────────────────────────
echo "🌐 Server IP addresses:"
hostname -I | tr ' ' '\n' | while read -r ip; do
   [ -n "$ip" ] && echo "   → $ip"
done
echo ""
PORT_FLAG=""
[ "$SSH_PORT" != "22" ] && PORT_FLAG=" -p $SSH_PORT"
echo "🎉 Connect with:"
echo "   ssh$PORT_FLAG $(whoami)@<IP>"
echo ""
echo "🔑 Password auth only (public key auth is disabled)."
