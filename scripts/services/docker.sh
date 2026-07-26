#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../lib/common.sh"

echo "🚀 Starting Docker & Docker Compose installation..."
echo ""

# ── OS Detection ───────────────────────────────────────────
detect_os

case "$OS_ID" in
   ubuntu) DOCKER_REPO="https://download.docker.com/linux/ubuntu" ;;
   debian) DOCKER_REPO="https://download.docker.com/linux/debian" ;;
   *)
      echo "❌ Unsupported OS: $OS_ID (only Ubuntu/Debian)"
      exit 1
      ;;
esac

echo "   OS: $OS_ID $VERSION_ID ($OS_CODENAME)"
echo ""

# ── Check if already installed and running ─────────────────
if command -v docker &>/dev/null; then
   echo "📌 Docker is already installed"
   echo "   🐳 $(docker --version)"
   if docker compose version &>/dev/null; then
      echo "   📦 Docker Compose $(docker compose version --short)"
   else
      echo "   ⚠️  Docker Compose plugin not found"
   fi
   if systemctl is-active --quiet docker; then
      echo "✅ Docker service is already running"
   else
      echo "⚠️  Docker is installed but not running, starting..."
      sudo systemctl enable docker
      sudo systemctl start docker
      echo "✅ Docker service started"
   fi
else
   # ── Uninstall old versions ─────────────────────────────────
   echo "🧹 Removing old/conflicting packages..."
   sudo apt remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null || true
   echo "✅ Old packages removed"
   echo ""

   # ── Install prerequisites ──────────────────────────────────
   echo "📦 Installing prerequisites..."
   sudo apt update -qq
   sudo apt install -y -qq ca-certificates curl
   echo "✅ Prerequisites installed"
   echo ""

   # ── Add Docker GPG key ─────────────────────────────────────
   echo "🔑 Adding Docker's official GPG key..."
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL "$DOCKER_REPO/gpg" -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   echo "✅ GPG key added"
   echo ""

   # ── Add Docker repository ─────────────────────────────────
   echo "📋 Adding Docker apt repository..."
   sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: $DOCKER_REPO
Suites: $OS_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
   sudo apt update -qq
   echo "✅ Repository added ($DOCKER_REPO)"
   echo ""

   # ── Install Docker Engine ──────────────────────────────────
   echo "🐳 Installing Docker Engine & Docker Compose..."
   sudo apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   echo "✅ Docker installed"
   echo ""

   # ── Enable & start Docker ─────────────────────────────────
   echo "⚙️  Enabling Docker service..."
   sudo systemctl enable docker
   sudo systemctl start docker
   echo "✅ Docker service is running"
   echo ""

   # ── Add current user to docker group ──────────────────────
   echo "👤 Adding user '$(whoami)' to docker group..."
   sudo usermod -aG docker "$(whoami)"
   echo "✅ User added to docker group"
fi

echo ""

# ── Verification ───────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running verification checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Docker binary + version
echo "1️⃣  Docker binary"
if command -v docker &>/dev/null; then
   pass "$(docker --version)"
else
   fail "docker binary not found"
fi

# 2. Docker daemon active and enabled
echo "2️⃣  Docker service"
if systemctl is-active --quiet docker && systemctl is-enabled --quiet docker; then
   pass "docker.service is active and enabled on boot"
else
   fail "docker.service is NOT active/enabled"
fi

# 3. Docker Compose plugin
echo "3️⃣  Docker Compose plugin"
COMPOSE_VER=$(docker compose version --short 2>/dev/null || true)
if [ -n "$COMPOSE_VER" ]; then
   pass "Docker Compose v$COMPOSE_VER"
else
   fail "Docker Compose plugin not found"
fi

# 4. Container run test
echo "4️⃣  Container run test"
if sudo docker run --rm hello-world &>/dev/null; then
   pass "hello-world container ran successfully"
   sudo docker rmi hello-world &>/dev/null || true
else
   fail "hello-world container failed to run"
fi

# ── Summary ────────────────────────────────────────────────
check_summary
echo ""

# ── Post-install notes ─────────────────────────────────────
if ! id -nG "$(whoami)" | grep -qw docker; then
   echo "⚠️  Log out and log back in for docker group to take effect,"
   echo "   or run: newgrp docker"
   echo ""
fi

echo "🐳 Docker is ready!"
