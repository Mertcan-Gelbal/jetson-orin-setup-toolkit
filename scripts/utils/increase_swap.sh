#!/usr/bin/env bash
# ============================================================
# increase_swap.sh — Configures a 60GB swap file.
# Useful for memory-heavy builds (PyTorch from source, large
# containers, jetson-containers builds).
#
# WARNING: Allocates ~60GB on the root filesystem. Make sure you
# have the disk space (an NVMe SSD is strongly recommended).
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

SWAP_SIZE_GB="${SWAP_SIZE_GB:-60}"
SWAPFILE="${SWAPFILE:-/mnt/${SWAP_SIZE_GB}GB.swap}"

section "Increasing swap to ${SWAP_SIZE_GB} GB"

# Check available disk space (kB)
AVAIL_KB="$(df --output=avail / | tail -n1 | tr -d ' ')"
NEED_KB=$(( SWAP_SIZE_GB * 1024 * 1024 + 1024 * 1024 ))   # + 1GB headroom
if (( AVAIL_KB < NEED_KB )); then
    fail "Not enough free space on / (have $((AVAIL_KB/1024/1024)) GB, need >= $((NEED_KB/1024/1024)) GB)."
    exit 1
fi

# Disable any existing swap on the same path
if swapon --show=NAME --noheadings | grep -qx "$SWAPFILE"; then
    log "Existing swap on $SWAPFILE — disabling"
    sudo swapoff "$SWAPFILE" 2>&1 | tee -a "$LOG_FILE" || true
fi

if [[ -f "$SWAPFILE" ]]; then
    log "Removing old swap file $SWAPFILE"
    sudo rm -f "$SWAPFILE"
fi

log "Allocating ${SWAP_SIZE_GB}GB swap file at $SWAPFILE"
sudo mkdir -p "$(dirname "$SWAPFILE")"
sudo fallocate -l "${SWAP_SIZE_GB}G" "$SWAPFILE" 2>&1 | tee -a "$LOG_FILE" || \
    sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((SWAP_SIZE_GB*1024)) status=progress 2>&1 | tee -a "$LOG_FILE"

sudo chmod 600  "$SWAPFILE"
sudo mkswap     "$SWAPFILE" 2>&1 | tee -a "$LOG_FILE"
sudo swapon     "$SWAPFILE" 2>&1 | tee -a "$LOG_FILE"

# Persist in /etc/fstab
if ! grep -qF "$SWAPFILE" /etc/fstab; then
    log "Adding $SWAPFILE to /etc/fstab"
    echo "$SWAPFILE  none  swap  sw  0  0" | sudo tee -a /etc/fstab >/dev/null
else
    ok "$SWAPFILE already present in /etc/fstab"
fi

# Disable zram if present (it competes with on-disk swap)
if systemctl list-unit-files | grep -q "nvzramconfig"; then
    log "Disabling nvzramconfig (zram swap competes with disk swap)"
    sudo systemctl disable nvzramconfig 2>&1 | tee -a "$LOG_FILE" || true
fi

log "Current swap layout:"
swapon --show 2>&1 | tee -a "$LOG_FILE" || true

ok "Swap configured (${SWAP_SIZE_GB} GB)."
warn "Reboot recommended to make sure all swap settings (incl. fstab) take effect."
