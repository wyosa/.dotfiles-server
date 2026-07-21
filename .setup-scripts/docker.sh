#!/bin/bash
set -e

echo "🚀 Starting Docker & Docker Compose installation..."
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
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   echo "✅ GPG key added"
   echo ""

   # ── Add Docker repository ─────────────────────────────────
   echo "📋 Adding Docker apt repository..."
   sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
   sudo apt update -qq
   echo "✅ Repository added"
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

# 1. Docker binary
echo "1️⃣  Docker binary"
if command -v docker &>/dev/null; then
   pass "docker found at $(command -v docker)"
else
   fail "docker binary not found"
fi

# 2. Docker version
echo "2️⃣  Docker version"
DOCKER_VER=$(docker --version 2>/dev/null || true)
if [ -n "$DOCKER_VER" ]; then
   pass "$DOCKER_VER"
else
   fail "could not determine Docker version"
fi

# 3. Docker Compose plugin
echo "3️⃣  Docker Compose plugin"
COMPOSE_VER=$(docker compose version --short 2>/dev/null || true)
if [ -n "$COMPOSE_VER" ]; then
   pass "Docker Compose v$COMPOSE_VER"
else
   fail "Docker Compose plugin not found"
fi

# 4. Docker Buildx plugin
echo "4️⃣  Docker Buildx plugin"
if docker buildx version &>/dev/null; then
   pass "$(docker buildx version 2>/dev/null)"
else
   fail "Docker Buildx plugin not found"
fi

# 5. Docker daemon active
echo "5️⃣  Docker service"
if systemctl is-active --quiet docker; then
   pass "docker.service is active"
else
   fail "docker.service is NOT active"
fi

# 6. Docker enabled on boot
echo "6️⃣  Autostart on boot"
if systemctl is-enabled --quiet docker; then
   pass "docker.service is enabled (will start on boot)"
else
   fail "docker.service is NOT enabled for autostart"
fi

# 7. containerd running
echo "7️⃣  containerd"
if systemctl is-active --quiet containerd; then
   pass "containerd.service is active"
else
   fail "containerd.service is NOT active"
fi

# 8. Docker socket
echo "8️⃣  Docker socket"
if [ -S /var/run/docker.sock ]; then
   pass "/var/run/docker.sock exists"
else
   fail "/var/run/docker.sock not found"
fi

# 9. Docker info (daemon responds)
echo "9️⃣  Daemon responsiveness"
if sudo docker info &>/dev/null; then
   CONTAINERS=$(sudo docker info --format '{{.Containers}}' 2>/dev/null || echo "?")
   IMAGES=$(sudo docker info --format '{{.Images}}' 2>/dev/null || echo "?")
   pass "daemon responds ($CONTAINERS containers, $IMAGES images)"
else
   fail "daemon not responding to 'docker info'"
fi

# 10. hello-world test
echo "🔟 Container run test"
if sudo docker run --rm hello-world &>/dev/null; then
   pass "hello-world container ran successfully"
   sudo docker rmi hello-world &>/dev/null || true
else
   fail "hello-world container failed to run"
fi

# 11. User in docker group
echo "1️⃣1️⃣ Docker group membership"
CURRENT_USER=$(whoami)
if id -nG "$CURRENT_USER" | grep -qw docker; then
   pass "'$CURRENT_USER' is in the docker group"
else
   fail "'$CURRENT_USER' is NOT in the docker group yet (re-login required)"
fi

# 12. Network drivers
echo "1️⃣2️⃣ Network drivers"
NET_DRIVERS=$(sudo docker network ls --format '{{.Driver}}' 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/,$//')
if [ -n "$NET_DRIVERS" ]; then
   pass "available drivers: $NET_DRIVERS"
else
   fail "no network drivers found"
fi

# 13. Storage driver
echo "1️⃣3️⃣ Storage driver"
STORAGE=$(sudo docker info --format '{{.Driver}}' 2>/dev/null || true)
if [ -n "$STORAGE" ]; then
   pass "storage driver: $STORAGE"
else
   fail "could not determine storage driver"
fi

# 14. Disk space for /var/lib/docker
echo "1️⃣4️⃣ Disk space"
AVAIL=$(df -h /var/lib/docker 2>/dev/null | awk 'NR==2 {print $4}' || true)
if [ -n "$AVAIL" ]; then
   pass "$AVAIL available on /var/lib/docker partition"
else
   fail "could not check disk space"
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

# ── Post-install notes ─────────────────────────────────────
if ! id -nG "$(whoami)" | grep -qw docker; then
   echo "⚠️  Log out and log back in for docker group to take effect,"
   echo "   or run: newgrp docker"
   echo ""
fi

echo "🐳 Docker is ready!"
