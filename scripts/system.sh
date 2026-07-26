#!/bin/bash
set -e

echo "⚙️  System configuration..."
echo ""

# ── Timezone ───────────────────────────────────────────────
echo "🕐 Timezone setup"
CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "unknown")
echo "   Current: $CURRENT_TZ"
echo ""
echo "   Common timezones:"
echo "   1) Europe/Moscow"
echo "   2) Europe/London"
echo "   3) Europe/Berlin"
echo "   4) America/New_York"
echo "   5) America/Los_Angeles"
echo "   6) Asia/Tokyo"
echo "   7) UTC"
echo "   8) Custom"
echo ""
read -rp "Select timezone [1-8] (Enter to skip): " tz_choice

case "$tz_choice" in
   1) NEW_TZ="Europe/Moscow" ;;
   2) NEW_TZ="Europe/London" ;;
   3) NEW_TZ="Europe/Berlin" ;;
   4) NEW_TZ="America/New_York" ;;
   5) NEW_TZ="America/Los_Angeles" ;;
   6) NEW_TZ="Asia/Tokyo" ;;
   7) NEW_TZ="UTC" ;;
   8)
      read -rp "   Enter timezone (e.g. Europe/Paris): " NEW_TZ
      ;;
   *)
      NEW_TZ=""
      echo "   ⏭️  Skipped"
      ;;
esac

if [ -n "$NEW_TZ" ]; then
   sudo timedatectl set-timezone "$NEW_TZ"
   echo "   ✅ Timezone set to $NEW_TZ"
fi

echo ""

# ── Hostname ───────────────────────────────────────────────
echo "🏷️  Hostname"
CURRENT_HOST=$(hostname)
echo "   Current: $CURRENT_HOST"
read -rp "   New hostname (Enter to keep): " NEW_HOST

if [ -n "$NEW_HOST" ] && [ "$NEW_HOST" != "$CURRENT_HOST" ]; then
   sudo hostnamectl set-hostname "$NEW_HOST"
   # update /etc/hosts — replace the 127.0.1.1 entry (no regex on hostname)
   if grep -qE '^127\.0\.1\.1[[:space:]]' /etc/hosts; then
      sudo sed -i -E "s/^127\.0\.1\.1[[:space:]].*/127.0.1.1\t$NEW_HOST/" /etc/hosts
   else
      echo "127.0.1.1 $NEW_HOST" | sudo tee -a /etc/hosts >/dev/null
   fi
   echo "   ✅ Hostname set to $NEW_HOST"
else
   echo "   ⏭️  Kept $CURRENT_HOST"
fi

echo ""

# ── Swap ───────────────────────────────────────────────────
echo "💾 Swap"
CURRENT_SWAP=$(swapon --show --noheadings 2>/dev/null | wc -l)
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')

if [ "$CURRENT_SWAP" -gt 0 ]; then
   echo "   Swap already configured:"
   swapon --show
   read -rp "   Recreate swap? [y/N]: " swap_recreate
   if [[ ! "$swap_recreate" =~ ^[Yy]$ ]]; then
      echo "   ⏭️  Skipped"
      SWAP_SIZE=""
   else
      sudo swapoff -a
      # disable old swap entries in fstab so stale ones don't break boot
      sudo sed -i -E '/^[[:space:]]*[^#[:space:]]+[[:space:]]+none[[:space:]]+swap[[:space:]]/s/^/# /' /etc/fstab
      SWAP_SIZE="$((TOTAL_RAM_MB < 4096 ? TOTAL_RAM_MB : 4096))M"
   fi
else
   SUGGESTED_SWAP=$((TOTAL_RAM_MB < 4096 ? TOTAL_RAM_MB : 4096))
   echo "   No swap configured (RAM: ${TOTAL_RAM_MB}M)"
   echo "   Recommended: ${SUGGESTED_SWAP}M (min(RAM, 4G) is usually enough for servers)"
   read -rp "   Swap size in MB (Enter to skip, e.g. $SUGGESTED_SWAP): " SWAP_SIZE
fi

if [ -n "$SWAP_SIZE" ]; then
   # normalize: ensure M suffix
   [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]] && SWAP_SIZE="${SWAP_SIZE}M"

   SWAP_FILE="/swapfile"
   echo "   Creating ${SWAP_SIZE} swap..."
   sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE" 2>/dev/null || sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count="${SWAP_SIZE%M}" status=progress
   sudo chmod 600 "$SWAP_FILE"
   sudo mkswap "$SWAP_FILE"
   sudo swapon "$SWAP_FILE"

   # persist across reboots
   if ! grep -qE "^${SWAP_FILE}[[:space:]]" /etc/fstab; then
      echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
   fi

   # swappiness
   sudo sysctl vm.swappiness=10
   if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
      echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf >/dev/null
   fi

   echo "   ✅ Swap created:"
   swapon --show
fi

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Current system state"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   🕐 Timezone:  $(timedatectl show --property=Timezone --value 2>/dev/null || echo 'unknown')"
echo "   🏷️  Hostname:  $(hostname)"
echo "   💾 Swap:"
swapon --show --noheadings 2>/dev/null | while read -r line; do echo "      $line"; done
[ "$(swapon --show --noheadings 2>/dev/null | wc -l)" -eq 0 ] && echo "      (none)"
echo ""
echo "🎉 System configuration done!"
