#!/usr/bin/env bash
# ============================================================
# 03_run_jetsonhacks.sh — Clones and runs jetsonhacks/setup_jetson.sh
#
# Repository: https://github.com/jetsonhacks/jetson-orin-setup
# This wrapper makes the jetsonhacks baseline (Chromium, VS Code,
# jtop, etc.) part of our pipeline without copy-pasting their code.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

JH_REPO_URL="${JH_REPO_URL:-https://github.com/jetsonhacks/jetson-orin-setup.git}"
JH_REPO_REF="${JH_REPO_REF:-main}"
JH_CLONE_DIR="${JH_CLONE_DIR:-$HOME/.cache/jetson-orin-postinstall/jetson-orin-setup}"

section "Running jetsonhacks/setup_jetson.sh"

if ! command_exists git; then
    fail "git is required but not installed. Run scripts/core/02_install_essentials.sh first."
    exit 1
fi

mkdir -p "$(dirname "$JH_CLONE_DIR")"

if [[ -d "$JH_CLONE_DIR/.git" ]]; then
    log "jetsonhacks repo already cloned at $JH_CLONE_DIR — pulling latest"
    (cd "$JH_CLONE_DIR" && git fetch --all --prune 2>&1 | tee -a "$LOG_FILE" || true)
    (cd "$JH_CLONE_DIR" && git checkout "$JH_REPO_REF" 2>&1 | tee -a "$LOG_FILE" || true)
    (cd "$JH_CLONE_DIR" && git pull --ff-only 2>&1 | tee -a "$LOG_FILE" || \
        warn "git pull failed; continuing with current checkout.")
else
    log "Cloning $JH_REPO_URL ($JH_REPO_REF) into $JH_CLONE_DIR"
    git clone --depth 1 --branch "$JH_REPO_REF" "$JH_REPO_URL" "$JH_CLONE_DIR" 2>&1 | tee -a "$LOG_FILE"
fi

if [[ ! -f "$JH_CLONE_DIR/setup_jetson.sh" ]]; then
    fail "setup_jetson.sh not found in $JH_CLONE_DIR — repository layout may have changed."
    exit 1
fi

chmod +x "$JH_CLONE_DIR/setup_jetson.sh"

log "Executing setup_jetson.sh"
( cd "$JH_CLONE_DIR" && bash ./setup_jetson.sh ) 2>&1 | tee -a "$LOG_FILE" || \
    warn "setup_jetson.sh reported a non-zero exit. Review the log for details."

ok "jetsonhacks setup_jetson.sh finished."
