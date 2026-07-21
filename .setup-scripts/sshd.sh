#!/bin/bash
set -e

echo "🚀 Starting SSH server setup..."
echo ""

# ── Check if already installed and running ─────────────────
if command -v sshd &>/dev/null; then
   echo "📌 openssh-server is already installed"
   if systemctl is-active --quiet ssh; then
      echo "✅ SSH service is already running"
   else
      echo "⚠️  SSH is installed but not running, starting..."
      systemctl enable ssh
      systemctl start ssh
      echo "✅ SSH service started"
   fi
else
   # ── Install ────────────────────────────────────────────────
   echo "📦 Installing openssh-server..."
   apt update -qq && apt install -y -qq openssh-server
   echo "✅ openssh-server installed"
   echo ""

   # ── Backup config ──────────────────────────────────────────
   echo "💾 Backing up sshd_config..."
   cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
   echo "✅ Backup saved to /etc/ssh/sshd_config.bak"
   echo ""

   # ── Security settings ─────────────────────────────────────
   echo "🔧 Applying security settings..."
   sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
   sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
   sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
   echo "   🔒 Root login disabled"
   echo "   🔑 Password authentication enabled"
   echo "   🔑 Public key authentication enabled"
   echo "✅ Security settings applied"
   echo ""

   # ── Enable and start ──────────────────────────────────────
   echo "⚙️  Enabling and starting SSH service..."
   systemctl enable ssh
   systemctl restart ssh
   echo "✅ SSH service is running"
fi

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running verification checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

pass() {
   echo "   ✅ $1"
   ((CHECKS_PASSED++))
}
fail() {
   echo "   ❌ $1"
   ((CHECKS_FAILED++))
}

# 1. sshd binary exists
echo "1️⃣  sshd binary"
if command -v sshd &>/dev/null; then
   pass "sshd found at $(command -v sshd)"
else
   fail "sshd binary not found"
fi

# 2. Config syntax valid
echo "2️⃣  Config syntax"
if sshd -t 2>/dev/null; then
   pass "sshd_config syntax is valid"
else
   fail "sshd_config has syntax errors — run 'sshd -t' to see details"
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

# 5. Port 22 is listening
echo "5️⃣  Port listening"
if ss -tlnp | grep -q ':22\b'; then
   pass "sshd is listening on port 22"
else
   fail "nothing is listening on port 22"
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
if ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no localhost exit 2>/dev/null; then
   pass "localhost SSH connection successful"
else
   # BatchMode will fail if no key is set up — check if we at least got a response
   if ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no localhost exit 2>&1 | grep -qi "permission denied"; then
      pass "sshd responds on localhost (auth required — expected)"
   else
      fail "could not connect to sshd on localhost"
   fi
fi

# 8. Security settings applied
echo "8️⃣  Security settings"
if sshd -T 2>/dev/null | grep -qi "permitrootlogin no"; then
   pass "PermitRootLogin is disabled"
else
   fail "PermitRootLogin is NOT set to 'no'"
fi

if sshd -T 2>/dev/null | grep -qi "pubkeyauthentication yes"; then
   pass "PubkeyAuthentication is enabled"
else
   fail "PubkeyAuthentication is NOT enabled"
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
   if ufw status 2>/dev/null | grep -q "inactive"; then
      pass "ufw is inactive (port 22 not blocked)"
   elif ufw status 2>/dev/null | grep -q "22.*ALLOW"; then
      pass "ufw allows port 22"
   else
      fail "ufw is active but port 22 may not be allowed — run 'ufw allow ssh'"
   fi
else
   pass "ufw not installed (no firewall blocking)"
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

# ── Connection info ────────────────────────────────────────
echo "🌐 Server IP addresses:"
hostname -I | tr ' ' '\n' | while read ip; do
   [ -n "$ip" ] && echo "   → $ip"
done
echo ""
echo "🎉 Connect with:"
echo "   ssh $(whoami)@<IP>"
echo ""
echo "💡 Tip: After copying your SSH key (ssh-copy-id user@IP),"
echo "   disable password auth for better security."
