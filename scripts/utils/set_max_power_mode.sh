#!/usr/bin/env bash
# ============================================================
# set_max_power_mode.sh — Switches the device to its maximum
# power mode (MAXN / MAXN SUPER) and runs jetson_clocks.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

section "Setting maximum power mode"

if ! command_exists nvpmodel; then
    fail "nvpmodel is not available — is this a Jetson device with L4T installed?"
    exit 1
fi

log "Current power mode:"
sudo nvpmodel -q 2>&1 | tee -a "$LOG_FILE" || true

# Mode 0 is MAXN / MAXN SUPER on every Jetson Orin SKU.
log "Switching to mode 0 (MAXN / MAXN SUPER)"
sudo nvpmodel -m 0 2>&1 | tee -a "$LOG_FILE" || \
    warn "Could not set power mode 0 — check 'sudo nvpmodel -p --verbose' for available modes."

if command_exists jetson_clocks; then
    log "Running jetson_clocks"
    sudo jetson_clocks 2>&1 | tee -a "$LOG_FILE" || \
        warn "jetson_clocks reported errors."
else
    warn "jetson_clocks not found."
fi

log "Active power mode:"
sudo nvpmodel -q 2>&1 | tee -a "$LOG_FILE" || true

ok "Power mode configured."
