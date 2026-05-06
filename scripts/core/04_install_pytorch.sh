#!/usr/bin/env bash
# ============================================================
# 04_install_pytorch.sh — Installs PyTorch via the JetsonHacks
# install_pytorch_jetson.sh utility, which fetches the correct
# NVIDIA-built CUDA-accelerated wheel for the running JetPack.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

JH_REPO_URL="${JH_REPO_URL:-https://github.com/jetsonhacks/jetson-orin-setup.git}"
JH_REPO_REF="${JH_REPO_REF:-main}"
JH_CLONE_DIR="${JH_CLONE_DIR:-$HOME/.cache/jetson-orin-postinstall/jetson-orin-setup}"
JH_PYTORCH_SCRIPT="$JH_CLONE_DIR/scripts/utils/install_pytorch_jetson.sh"

section "Installing PyTorch (Jetson-optimized)"

if ! command_exists git; then
    fail "git is required but not installed."
    exit 1
fi

# Make sure we have the repo (idempotent)
if [[ ! -d "$JH_CLONE_DIR/.git" ]]; then
    log "Cloning $JH_REPO_URL into $JH_CLONE_DIR"
    mkdir -p "$(dirname "$JH_CLONE_DIR")"
    git clone --depth 1 --branch "$JH_REPO_REF" "$JH_REPO_URL" "$JH_CLONE_DIR" 2>&1 | tee -a "$LOG_FILE"
fi

if [[ ! -f "$JH_PYTORCH_SCRIPT" ]]; then
    fail "install_pytorch_jetson.sh not found at $JH_PYTORCH_SCRIPT — repository layout may have changed."
    exit 1
fi

chmod +x "$JH_PYTORCH_SCRIPT"

log "Executing install_pytorch_jetson.sh"
( cd "$JH_CLONE_DIR" && bash ./scripts/utils/install_pytorch_jetson.sh ) 2>&1 | tee -a "$LOG_FILE" || \
    warn "install_pytorch_jetson.sh reported a non-zero exit. The wheel for this JetPack/CUDA combination may not exist."

# Quick sanity check
section "PyTorch sanity check"
python3 - <<'PY' 2>&1 | tee -a "$LOG_FILE" || true
try:
    import torch
    print("torch.__version__       :", torch.__version__)
    print("torch.version.cuda      :", torch.version.cuda)
    print("torch.cuda.is_available :", torch.cuda.is_available())
    if torch.cuda.is_available():
        print("device_count            :", torch.cuda.device_count())
        print("device_name(0)          :", torch.cuda.get_device_name(0))
except Exception as e:
    print("PyTorch import/check failed:", e)
PY
