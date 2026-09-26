# shellcheck shell=bash
# This file is sourced by other scripts — variables are used there.
# shellcheck disable=SC2034

# Shared helpers for dotfiles-server scripts.
# Source from other scripts: . "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}ℹ️  $1${NC}"; }
ok()    { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }

# ── Verification counters ──────────────────────────────────
# NB: use pre-increment — ((var++)) returns exit 1 when var=0
# and would kill the script under `set -e`.
CHECKS_PASSED=0
CHECKS_FAILED=0

pass() { echo "   ✅ $1"; ((++CHECKS_PASSED)); }
fail() { echo "   ❌ $1"; ((++CHECKS_FAILED)); }

check_summary() {
   echo ""
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   if [ "$CHECKS_FAILED" -eq 0 ]; then
      echo "🎉 All $CHECKS_PASSED checks passed!"
   else
      echo "⚠️  $CHECKS_PASSED passed, $CHECKS_FAILED failed"
   fi
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   [ "$CHECKS_FAILED" -eq 0 ]
}

# Include the port of the active session (also covers SSH socket activation).
ssh_ports() {
   local config session_port
   config=$(sudo /usr/sbin/sshd -T) || return 1
   session_port=$(printf '%s\n' "${SSH_CONNECTION:-}" | awk '{print $4}')
   { printf '%s\n' "$config" | awk '$1 == "port" {print $2}'; printf '%s\n' "$session_port"; } |
      awk '/^[0-9]+$/ && $1 > 0 && $1 < 65536 && !seen[$1]++ {print $1}'
}

# ── OS Detection ───────────────────────────────────────────
# Sets OS_ID, OS_VERSION, OS_CODENAME
detect_os() {
   if [ -f /etc/os-release ]; then
      . /etc/os-release
      OS_ID="$ID"
      OS_VERSION="$VERSION_ID"
      OS_CODENAME="${VERSION_CODENAME:-unknown}"
   else
      err "Cannot detect OS — /etc/os-release not found"
      exit 1
   fi
}
