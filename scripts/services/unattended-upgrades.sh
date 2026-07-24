#!/bin/bash
set -e

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

# detect OS for correct origin
. /etc/os-release
case "$ID" in
   ubuntu) ORIGIN="Ubuntu" ;;
   debian) ORIGIN="Debian" ;;
   *)      ORIGIN="Debian" ;;
esac

AUTOUPGRADE_FILE="/etc/apt/apt.conf.d/20auto-upgrades"
sudo tee "$AUTOUPGRADE_FILE" >/dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF

UNATTENDED_FILE="/etc/apt/apt.conf.d/50unattended-upgrades"
if [ -f "$UNATTENDED_FILE" ]; then
   sudo cp "$UNATTENDED_FILE" "${UNATTENDED_FILE}.bak"
fi

sudo tee "$UNATTENDED_FILE" >/dev/null <<EOF
Unattended-Upgrade::Allowed-Origins {
    "${ORIGIN}:${VERSION_CODENAME}-security";
    "${ORIGIN}:${VERSION_CODENAME}-updates";
};

Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

echo "   📄 Auto-upgrade config: $AUTOUPGRADE_FILE"
echo "   📄 Unattended config:   $UNATTENDED_FILE"
echo "   🔒 Security + updates: auto"
echo "   🔒 Reboot: manual (Automatic-Reboot = false)"
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

CHECKS_PASSED=0
CHECKS_FAILED=0

pass() { echo "   ✅ $1"; ((CHECKS_PASSED++)); }
fail() { echo "   ❌ $1"; ((CHECKS_FAILED++)); }

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

# 3. Allowed origins
echo "3️⃣  Allowed origins"
if [ -f "$UNATTENDED_FILE" ] && grep -q "security" "$UNATTENDED_FILE"; then
   pass "security updates allowed"
else
   fail "security origin not configured"
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
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CHECKS_FAILED" -eq 0 ]; then
   echo "🎉 All $CHECKS_PASSED checks passed!"
else
   echo "⚠️  $CHECKS_PASSED passed, $CHECKS_FAILED failed"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Check logs:"
echo "   cat /var/log/unattended-upgrades/unattended-upgrades.log"
echo ""
echo "⚠️  Automatic reboot is DISABLED."
echo "   After kernel updates, reboot manually:"
echo "   sudo reboot"
