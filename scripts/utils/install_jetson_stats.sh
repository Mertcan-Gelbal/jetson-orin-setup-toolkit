#!/usr/bin/env bash
# ============================================================
# install_jetson_stats.sh — Standalone installer for jtop.
# Use this if you want jetson-stats without running the full
# pipeline.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

JETSON_STATS_VERSION="${JETSON_STATS_VERSION:-latest}"

section "Installing jetson-stats (jtop)"

if ! command_exists python3 || ! command_exists pip3; then
    log "Installing python3 / pip3 prerequisites"
    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    sudo apt install -y python3 python3-pip 2>&1 | tee -a "$LOG_FILE"
fi

if [[ "$JETSON_STATS_VERSION" == "latest" ]]; then
    sudo -H python3 -m pip install -U jetson-stats 2>&1 | tee -a "$LOG_FILE"
else
    sudo -H python3 -m pip install -U "jetson-stats==$JETSON_STATS_VERSION" 2>&1 | tee -a "$LOG_FILE"
fi

sudo systemctl enable  jetson_stats 2>&1 | tee -a "$LOG_FILE" || true
sudo systemctl restart jetson_stats 2>&1 | tee -a "$LOG_FILE" || \
    warn "Could not restart jetson_stats service. It will start on the next boot."

ok "jetson-stats installed. Run 'jtop' to launch the monitor."
