#!/usr/bin/env bash
# ============================================================
# 05_install_docker.sh — Installs Docker, enables the daemon,
# and adds the current user to the `docker` group.
#
# A reboot (or a logout/login) is required before the user can
# run docker commands without sudo.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

DOCKER_APT_PACKAGES=(docker.io)
DOCKER_OPTIONAL_APT_PACKAGES=(docker-compose docker-compose-plugin)

section "Installing Docker"
for pkg in "${DOCKER_APT_PACKAGES[@]}"; do
    install_apt_pkg "$pkg"
done
for pkg in "${DOCKER_OPTIONAL_APT_PACKAGES[@]}"; do
    install_apt_pkg_if_available "$pkg"
done

if command_exists docker; then
    sudo systemctl enable docker 2>&1 | tee -a "$LOG_FILE" || true
    sudo systemctl start  docker 2>&1 | tee -a "$LOG_FILE" || true

    if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        ok "User '$USER' is already in the 'docker' group."
    else
        sudo usermod -aG docker "$USER" 2>&1 | tee -a "$LOG_FILE" || \
            warn "Could not add user to docker group."
        warn "User '$USER' added to 'docker' group. Reboot or logout/login required for the change to take effect."
    fi

    ok "Docker installed."
else
    fail "Docker installation failed — 'docker' command not found."
fi
