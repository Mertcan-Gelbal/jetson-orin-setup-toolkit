#!/usr/bin/env bash
# ============================================================
# 07_cleanup.sh — apt autoremove + apt clean.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

section "Cleaning up"

sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE" || true
sudo apt clean        2>&1 | tee -a "$LOG_FILE" || true

ok "Cleanup complete."
