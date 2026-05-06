#!/usr/bin/env bash
# ============================================================
# 06_setup_environment.sh — Adds CUDA paths to ~/.bashrc and
# the current shell, idempotently.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

section "Configuring environment paths"

bashrc_file="$HOME/.bashrc"

if [[ -d /usr/local/cuda/bin ]]; then
    if ! grep -q "/usr/local/cuda/bin" "$bashrc_file" 2>/dev/null; then
        log "Adding CUDA bin path to $bashrc_file"
        {
            echo ""
            echo "# CUDA path - added by jetson-orin-postinstall"
            # shellcheck disable=SC2016
            echo 'export PATH=/usr/local/cuda/bin:$PATH'
        } >> "$bashrc_file"
    else
        ok "CUDA bin path already in $bashrc_file"
    fi
else
    warn "/usr/local/cuda/bin not found"
fi

if [[ -d /usr/local/cuda/lib64 ]]; then
    if ! grep -q "/usr/local/cuda/lib64" "$bashrc_file" 2>/dev/null; then
        log "Adding CUDA lib64 path to $bashrc_file"
        {
            echo ""
            echo "# CUDA library path - added by jetson-orin-postinstall"
            # shellcheck disable=SC2016
            echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH'
        } >> "$bashrc_file"
    else
        ok "CUDA lib64 path already in $bashrc_file"
    fi
else
    warn "/usr/local/cuda/lib64 not found"
fi

# Make the paths available to subsequent steps in this run
export PATH="/usr/local/cuda/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"

log "PATH=$PATH"
log "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

ok "Environment paths configured."
