#!/usr/bin/env bash
# ============================================================
# verify_system.sh — Full post-install verification.
#
# Reports on system info, NVIDIA/Jetson packages, CUDA, Python,
# OpenCV (incl. build flags), GStreamer (incl. nvarguscamerasrc
# and HW encoders), V4L2 / media / I2C devices, Jetson services,
# boot config, Docker, and SSH.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

# Re-detect so this script works standalone
detect_system_info

section "Verifying system information"
cat /etc/nv_tegra_release 2>&1 | tee -a "$LOG_FILE" || warn "/etc/nv_tegra_release not found"
uname -a 2>&1 | tee -a "$LOG_FILE"
lsb_release -a 2>&1 | tee -a "$LOG_FILE" || true

section "Verifying NVIDIA / Jetson packages"
dpkg -l 2>/dev/null | grep -Ei "nvidia-l4t|jetpack|cuda|cudnn|tensorrt" | sort 2>&1 | tee -a "$LOG_FILE" || \
    warn "No NVIDIA Jetson packages listed by grep."

section "Verifying CUDA"
verify_command nvcc "nvcc" || true
nvcc --version 2>&1 | tee -a "$LOG_FILE" || true
ls -ld /usr/local/cuda* 2>&1 | tee -a "$LOG_FILE" || warn "No /usr/local/cuda* directory found."
ls -l  /usr/local/cuda  2>&1 | tee -a "$LOG_FILE" || true

section "Verifying Python"
verify_command python3 "python3" || true
verify_command pip3    "pip3"    || true
python3 -V 2>&1 | tee -a "$LOG_FILE" || true
pip3 -V    2>&1 | tee -a "$LOG_FILE" || true

python3 - <<'PY' 2>&1 | tee -a "$LOG_FILE" || true
import sys, site
print("Python executable:", sys.executable)
print("Python version:", sys.version)
print("sys.path:")
for p in sys.path:
    print(" ", p)
print("site-packages:")
try:
    for p in site.getsitepackages():
        print(" ", p)
except Exception as e:
    print("site.getsitepackages error:", e)
PY

section "Verifying common Python packages"
python3 - <<'PY' 2>&1 | tee -a "$LOG_FILE" || true
packages = ["numpy", "pandas", "matplotlib", "PIL", "tqdm", "psutil"]
for pkg in packages:
    try:
        mod = __import__(pkg)
        version = getattr(mod, "__version__", "unknown")
        print(f"OK: {pkg} -> {version}")
    except Exception as e:
        print(f"MISSING: {pkg} -> {e}")
PY

section "Verifying PyTorch"
python3 - <<'PY' 2>&1 | tee -a "$LOG_FILE" || true
try:
    import torch
    print("torch.__version__       :", torch.__version__)
    print("torch.version.cuda      :", torch.version.cuda)
    print("torch.cuda.is_available :", torch.cuda.is_available())
    if torch.cuda.is_available():
        print("device_count            :", torch.cuda.device_count())
        print("device_name(0)          :", torch.cuda.get_device_name(0))
    try:
        import torchvision
        print("torchvision.__version__ :", torchvision.__version__)
    except Exception as e:
        print("torchvision not installed:", e)
except Exception as e:
    print("PyTorch import failed:", e)
PY

section "Verifying OpenCV"
python3 - <<'PY' 2>&1 | tee -a "$LOG_FILE" || true
try:
    import cv2
    print("OpenCV version:", cv2.__version__)
    print("OpenCV path:", cv2.__file__)
    print()
    print("Selected build flags:")
    for line in cv2.getBuildInformation().splitlines():
        if any(key in line for key in ["GStreamer", "CUDA", "cuDNN", "FFMPEG", "V4L/V4L2"]):
            print(line)
except Exception as e:
    print("OpenCV import failed:", e)
PY

section "Verifying GStreamer"
verify_command gst-launch-1.0 "gst-launch-1.0" || true
verify_command gst-inspect-1.0 "gst-inspect-1.0" || true
gst-launch-1.0 --version  2>&1 | tee -a "$LOG_FILE" || true
gst-inspect-1.0 --version 2>&1 | tee -a "$LOG_FILE" || true

GST_PLUGINS=(nvarguscamerasrc nvvidconv nvv4l2h264enc nvv4l2h265enc videoconvert appsink)
for plugin in "${GST_PLUGINS[@]}"; do
    if gst-inspect-1.0 "$plugin" >/dev/null 2>&1; then
        ok "GStreamer plugin found: $plugin"
    else
        warn "GStreamer plugin missing or unavailable: $plugin"
    fi
done

section "Verifying video and media utilities"
verify_command v4l2-ctl  "v4l2-ctl"  || true
verify_command media-ctl "media-ctl" || true
ls -l /dev/video* 2>&1 | tee -a "$LOG_FILE" || warn "No /dev/video* devices found."
v4l2-ctl --list-devices 2>&1 | tee -a "$LOG_FILE" || true
media-ctl -p            2>&1 | tee -a "$LOG_FILE" || true

section "Verifying I2C"
verify_command i2cdetect "i2cdetect" || true
ls -l /dev/i2c-* 2>&1 | tee -a "$LOG_FILE" || warn "No /dev/i2c-* devices found."

section "Verifying Jetson services"
if systemctl list-unit-files | grep -q "nvargus-daemon"; then
    systemctl status nvargus-daemon --no-pager 2>&1 | tee -a "$LOG_FILE" || true
else
    warn "nvargus-daemon service not found."
fi

if systemctl list-unit-files | grep -q "jetson_stats"; then
    systemctl status jetson_stats --no-pager 2>&1 | tee -a "$LOG_FILE" || true
else
    warn "jetson_stats service not found."
fi

section "Verifying Jetson-IO paths"
ls -l /opt/nvidia/jetson-io/             2>&1 | tee -a "$LOG_FILE" || warn "/opt/nvidia/jetson-io not found."
ls -l /opt/nvidia/jetson-io/jetson-io.py 2>&1 | tee -a "$LOG_FILE" || true

section "Verifying boot config"
if [[ -f /boot/extlinux/extlinux.conf ]]; then
    grep -nEi "DEFAULT|LABEL|MENU LABEL|LINUX|FDT|OVERLAYS|JetsonIO|camera|imx|arducam" \
        /boot/extlinux/extlinux.conf 2>&1 | tee -a "$LOG_FILE" || true
else
    warn "/boot/extlinux/extlinux.conf not found."
fi

section "Verifying Docker"
if command_exists docker; then
    verify_command docker "docker"
    docker --version 2>&1 | tee -a "$LOG_FILE" || true

    if command_exists docker-compose; then
        docker-compose --version 2>&1 | tee -a "$LOG_FILE" || true
    else
        warn "docker-compose (legacy v1) command not found."
    fi

    if docker compose version >/dev/null 2>&1; then
        docker compose version 2>&1 | tee -a "$LOG_FILE"
    else
        warn "docker compose plugin not available."
    fi

    systemctl status docker --no-pager 2>&1 | tee -a "$LOG_FILE" || true
    groups 2>&1 | tee -a "$LOG_FILE" || true
else
    warn "Docker not installed (skip)."
fi

section "Verifying network and SSH"
ip a     2>&1 | tee -a "$LOG_FILE" || true
ip route 2>&1 | tee -a "$LOG_FILE" || true

if systemctl list-unit-files | grep -q "ssh"; then
    systemctl status ssh --no-pager 2>&1 | tee -a "$LOG_FILE" || true
else
    warn "ssh service not found."
fi
ss -tulpn 2>&1 | grep ":22" | tee -a "$LOG_FILE" || warn "SSH port 22 not visible in ss output."

ok "Verification complete. See $LOG_FILE for the full report."
