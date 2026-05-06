#!/usr/bin/env bash
# ============================================================
# install.sh — Top-level orchestrator
#
# Usage:
#   ./install.sh                       # full install + verify
#   VERIFY_ONLY=yes ./install.sh       # only run verification
#   INSTALL_ONLY=yes ./install.sh      # install but skip verify
#   ASK_CONFIRM=no ./install.sh        # unattended
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ----- Load configuration (file overrides defaults; env overrides file) -----
if [[ -f "$SCRIPT_DIR/config.env" ]]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/config.env"
fi

: "${TARGET_PROFILE:=auto}"
: "${TARGET_JETPACK:=auto}"
: "${PYTHON_PACKAGE_MODE:=apt}"
: "${OPENCV_SOURCE:=apt}"
: "${INSTALL_DOCKER:=yes}"
: "${INSTALL_JETSON_STATS:=yes}"
: "${INSTALL_PYTORCH:=yes}"
: "${RUN_JETSONHACKS_SETUP:=yes}"
: "${JETSON_STATS_VERSION:=latest}"
: "${ASK_CONFIRM:=yes}"
: "${VERIFY_ONLY:=no}"
: "${INSTALL_ONLY:=no}"

if [[ -z "${LOG_FILE:-}" ]]; then
    LOG_FILE="$SCRIPT_DIR/setup_verify_$(date +%Y%m%d_%H%M%S).log"
fi
export LOG_FILE TARGET_PROFILE TARGET_JETPACK PYTHON_PACKAGE_MODE OPENCV_SOURCE
export INSTALL_DOCKER INSTALL_JETSON_STATS INSTALL_PYTORCH RUN_JETSONHACKS_SETUP
export JETSON_STATS_VERSION ASK_CONFIRM SCRIPT_DIR

touch "$LOG_FILE"

# ----- Load shared helpers -----
# shellcheck disable=SC1091
source "$SCRIPT_DIR/scripts/lib/common.sh"

trap 'fail "An error occurred at line $LINENO. See $LOG_FILE for details."' ERR

print_header() {
    section "Jetson Orin Post-Install"
    log "Working directory : $SCRIPT_DIR"
    log "Log file          : $LOG_FILE"
    log "Profile           : $TARGET_PROFILE"
    log "Python mode       : $PYTHON_PACKAGE_MODE"
    log "OpenCV source     : $OPENCV_SOURCE"
    log "Docker            : $INSTALL_DOCKER"
    log "jetson-stats      : $INSTALL_JETSON_STATS"
    log "PyTorch (Jetson)  : $INSTALL_PYTORCH"
    log "JetsonHacks setup : $RUN_JETSONHACKS_SETUP"
    log "Verify only       : $VERIFY_ONLY"
    log "Install only      : $INSTALL_ONLY"
}

print_summary() {
    section "Summary"
    log "Run completed."
    log "Log file: $LOG_FILE"
    echo
    echo "Recommended next step:"
    echo "  sudo reboot"
    echo
    echo "After reboot, re-run verification only:"
    echo "  VERIFY_ONLY=yes ./install.sh"
    echo
}

main() {
    print_header

    # 0) Always detect first
    bash "$SCRIPT_DIR/scripts/core/00_detect_system.sh"

    # Verify-only: skip every install step.
    if [[ "$VERIFY_ONLY" == "yes" ]]; then
        bash "$SCRIPT_DIR/scripts/verify/verify_system.sh"
        print_summary
        exit 0
    fi

    confirm_or_exit

    bash "$SCRIPT_DIR/scripts/core/01_system_update.sh"
    bash "$SCRIPT_DIR/scripts/core/02_install_essentials.sh"

    if [[ "$RUN_JETSONHACKS_SETUP" == "yes" ]]; then
        bash "$SCRIPT_DIR/scripts/core/03_run_jetsonhacks.sh"
    else
        warn "Skipping JetsonHacks setup_jetson.sh (RUN_JETSONHACKS_SETUP=no)"
    fi

    if [[ "$INSTALL_PYTORCH" == "yes" ]]; then
        bash "$SCRIPT_DIR/scripts/core/04_install_pytorch.sh"
    else
        warn "Skipping PyTorch install (INSTALL_PYTORCH=no)"
    fi

    if [[ "$INSTALL_DOCKER" == "yes" ]]; then
        bash "$SCRIPT_DIR/scripts/core/05_install_docker.sh"
    else
        warn "Skipping Docker install (INSTALL_DOCKER=no)"
    fi

    bash "$SCRIPT_DIR/scripts/core/06_setup_environment.sh"

    if [[ "$INSTALL_ONLY" != "yes" ]]; then
        bash "$SCRIPT_DIR/scripts/verify/verify_system.sh"
    else
        warn "Skipping verification (INSTALL_ONLY=yes)"
    fi

    bash "$SCRIPT_DIR/scripts/core/07_cleanup.sh"
    print_summary
}

main "$@"
