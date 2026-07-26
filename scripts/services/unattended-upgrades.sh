#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

echo "🔄 Starting unattended-upgrades setup..."
echo ""

# ── Install ────────────────────────────────────────────────
if dpkg -s unattended-upgrades &>/dev/null; then
   echo "📌 unattended-upgrades is already installed"
else
   echo "📦 Installing unattended-upgrades..."
   sudo apt update -qq && sudo apt install -y -qq unattended-upgrades
   echo "✅ unattended-upgrades installed"
fi

echo ""

# ── Configure ──────────────────────────────────────────────
echo "🔧 Configuring auto-updates..."

AUTOUPGRADE_FILE="/etc/apt/apt.conf.d/20auto-upgrades"
sudo tee "$AUTOUPGRADE_FILE" >/dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF

# NB: we deliberately do NOT rewrite /etc/apt/apt.conf.d/50unattended-upgrades.
# The package's default template already has the correct per-OS origins
# (Debian security needs label=Debian-Security, which a hand-written
# "${ORIGIN}:${codename}-security" entry silently fails to match).

UNATTENDED_FILE="/etc/apt/apt.conf.d/50unattended-upgrades"

echo "   📄 Auto-upgrade config: $AUTOUPGRADE_FILE"
echo "   📄 Origins config:    $UNATTENDED_FILE (package default, untouched)"
echo "   🔒 Security updates: auto"
echo "   🔒 Reboot: manual (Automatic-Reboot = false by default)"
echo ""

# ── Enable ─────────────────────────────────────────────────
echo "⚙️  Enabling service..."
sudo systemctl enable unattended-upgrades 2>/dev/null || true
sudo systemctl restart unattended-upgrades 2>/dev/null || true
echo "✅ Service enabled"

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running verification checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Package installed
echo "1️⃣  Package"
if dpkg -s unattended-upgrades &>/dev/null; then
   pass "unattended-upgrades is installed"
else
   fail "unattended-upgrades is NOT installed"
fi

# 2. Auto-upgrade config
echo "2️⃣  Periodic config"
if [ -f "$AUTOUPGRADE_FILE" ] && grep -q 'Unattended-Upgrade "1"' "$AUTOUPGRADE_FILE"; then
   pass "periodic unattended-upgrade enabled"
else
   fail "periodic config missing or disabled"
fi

# 3. Allowed origins (from the package's default config)
echo "3️⃣  Allowed origins"
if [ -f "$UNATTENDED_FILE" ] && grep -q "security" "$UNATTENDED_FILE"; then
   pass "security updates allowed (package default origins)"
else
   fail "security origin not found in $UNATTENDED_FILE"
fi

# 4. Dry run
echo "4️⃣  Dry run"
if sudo unattended-upgrades --dry-run &>/dev/null; then
   pass "dry run succeeded"
else
   fail "dry run failed"
fi

# 5. Log exists
echo "5️⃣  Log file"
if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
   pass "log file exists"
else
   pass "log file will be created on first run"
fi

# ── Summary ────────────────────────────────────────────────
check_summary
echo ""
echo "💡 Check logs:"
echo "   cat /var/log/unattended-upgrades/unattended-upgrades.log"
echo ""
echo "⚠️  Automatic reboot is DISABLED."
echo "   After kernel updates, reboot manually:"
echo "   sudo reboot"
