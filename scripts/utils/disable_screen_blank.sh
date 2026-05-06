#!/usr/bin/env bash
# ============================================================
# disable_screen_blank.sh — Disables screen blanking, dimming,
# and idle-suspend. Useful for headless / kiosk / demo setups
# where you don't want the monitor to go dark mid-recording.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

section "Disabling screen blanking and auto-suspend"

if command_exists gsettings; then
    log "Configuring GNOME power settings via gsettings"
    gsettings set org.gnome.desktop.session                  idle-delay        0     2>&1 | tee -a "$LOG_FILE" || true
    gsettings set org.gnome.desktop.screensaver              lock-enabled      false 2>&1 | tee -a "$LOG_FILE" || true
    gsettings set org.gnome.desktop.screensaver              idle-activation-enabled false 2>&1 | tee -a "$LOG_FILE" || true
    gsettings set org.gnome.settings-daemon.plugins.power    sleep-inactive-ac-type    'nothing' 2>&1 | tee -a "$LOG_FILE" || true
    gsettings set org.gnome.settings-daemon.plugins.power    sleep-inactive-battery-type 'nothing' 2>&1 | tee -a "$LOG_FILE" || true
    ok "GNOME power settings updated."
else
    warn "gsettings not found — skipping GNOME power settings."
fi

# Disable suspend / hibernate at the systemd level (best-effort)
if command_exists systemctl; then
    log "Masking suspend / hibernate / hybrid-sleep targets"
    sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>&1 | tee -a "$LOG_FILE" || \
        warn "Could not mask sleep/suspend targets."
fi

ok "Screen blanking and auto-suspend disabled."
