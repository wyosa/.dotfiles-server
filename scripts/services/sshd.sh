#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

info "Configuring SSH without changing password or root login policy..."
if [ ! -x /usr/sbin/sshd ]; then
   sudo apt update -qq
   sudo apt install -y -qq openssh-server
fi

MAIN_CONFIG=/etc/ssh/sshd_config
MANAGED_CONFIG=/etc/ssh/sshd_config.d/00-dotfiles-server.conf
BACKUP_DIR=$(sudo mktemp -d /etc/ssh/dotfiles-backup.XXXXXX)
TEMP_CONFIG=$(mktemp)
sudo cp -p "$MAIN_CONFIG" "$BACKUP_DIR/sshd_config"
if sudo test -f "$MANAGED_CONFIG"; then
   sudo cp -p "$MANAGED_CONFIG" "$BACKUP_DIR/managed.conf"
fi

# Restore both files if validation or reload fails.
rollback() {
   local status=$?
   rm -f "$TEMP_CONFIG"
   if [ "$status" -ne 0 ]; then
      sudo cp -p "$BACKUP_DIR/sshd_config" "$MAIN_CONFIG"
      if sudo test -f "$BACKUP_DIR/managed.conf"; then
         sudo cp -p "$BACKUP_DIR/managed.conf" "$MANAGED_CONFIG"
      else
         sudo rm -f "$MANAGED_CONFIG"
      fi
      err "SSH configuration restored from $BACKUP_DIR"
   fi
}
trap rollback EXIT

sudo install -d -m 755 /etc/ssh/sshd_config.d
sudo tee "$MANAGED_CONFIG" >/dev/null <<'CONFIG'
# Managed by dotfiles-server. Preserve existing password and root login policy.
PubkeyAuthentication yes
MaxAuthTries 3
X11Forwarding no
CONFIG
sudo chmod 644 "$MANAGED_CONFIG"

# OpenSSH uses the first value; keep this include before existing directives.
{
   printf 'Include %s\n' "$MANAGED_CONFIG"
   sudo sed '\|^Include /etc/ssh/sshd_config.d/00-dotfiles-server.conf$|d' "$MAIN_CONFIG"
} > "$TEMP_CONFIG"
sudo install -m 600 "$TEMP_CONFIG" "$MAIN_CONFIG"
sudo /usr/sbin/sshd -t
EFFECTIVE_CONFIG=$(sudo /usr/sbin/sshd -T)
if ! printf '%s\n' "$EFFECTIVE_CONFIG" | grep -qx 'pubkeyauthentication yes'; then
   err "Public key authentication is not enabled; refusing to reload SSH"
   exit 1
fi

# Allow the configured and current session ports before any service reload.
SSH_PORTS=$(ssh_ports)
if command -v ufw >/dev/null && sudo ufw status | grep -q '^Status: active'; then
   for port in $SSH_PORTS; do
      sudo ufw limit "$port/tcp"
   done
fi
sudo systemctl enable ssh
sudo systemctl reload ssh 2>/dev/null || sudo systemctl restart ssh
rm -f "$TEMP_CONFIG"
trap - EXIT

if systemctl is-active --quiet ssh && systemctl is-enabled --quiet ssh; then
   pass "SSH is active and enabled on boot"
else
   fail "SSH service is not active/enabled"
fi
pass "SSH configuration is valid; public key authentication is enabled"
check_summary
info "Backup: $BACKUP_DIR"
info "SSH ports: $(printf '%s\n' "$SSH_PORTS" | paste -sd, -)"
info "Test key login in a second session before disabling password or root login."
