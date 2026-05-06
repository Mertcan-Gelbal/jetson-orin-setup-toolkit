#!/usr/bin/env bash
# ============================================================
# 01_system_update.sh — apt update + apt upgrade.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

section "APT update"
run_cmd sudo apt update

section "APT upgrade"
# We deliberately use -y here. If a JetPack/L4T package upgrade fails (a known
# class of issues on Jetson — see TROUBLESHOOTING.md), we log it and continue
# rather than aborting the whole pipeline.
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1 | tee -a "$LOG_FILE" || \
    warn "apt upgrade reported errors. Check the log; some L4T packages may need manual handling."

ok "System update complete."
