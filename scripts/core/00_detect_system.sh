#!/usr/bin/env bash
# ============================================================
# 00_detect_system.sh — Detects device, L4T release, OS, profile.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

section "Detecting system"

detect_system_info

log "Hostname       : $HOSTNAME_VALUE"
log "Architecture   : $ARCH_VALUE"
log "Kernel         : $KERNEL_VALUE"
log "OS             : $OS_NAME $OS_VERSION ($OS_CODENAME)"
log "L4T release    : $NV_TEGRA_RELEASE"
log "L4T major      : $L4T_MAJOR"
log "L4T revision   : $L4T_REVISION"
log "Target profile : $DETECTED_PROFILE"
log "Target JetPack : ${TARGET_JETPACK:-auto}"
log "OpenCV source  : ${OPENCV_SOURCE:-apt}"
log "Python mode    : ${PYTHON_PACKAGE_MODE:-apt}"

if [[ "$ARCH_VALUE" != "aarch64" ]]; then
    warn "This system is not aarch64 ($ARCH_VALUE). This toolkit is intended for Jetson devices."
fi

if [[ "$NV_TEGRA_RELEASE" == "not_found" ]]; then
    warn "/etc/nv_tegra_release was not found. This may not be a Jetson device, or L4T is not installed."
fi
