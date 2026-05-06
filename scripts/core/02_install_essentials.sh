#!/usr/bin/env bash
# ============================================================
# 02_install_essentials.sh — Installs dev tools, Python, GStreamer,
# multimedia, hardware utilities, networking, and OpenCV.
# ============================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

# Re-detect so the profile is available when this script is run standalone.
detect_system_info

# ----- Package lists -----
COMMON_APT_PACKAGES=(
    git curl wget nano vim htop tree unzip zip
    ca-certificates gnupg lsb-release software-properties-common apt-transport-https
    build-essential cmake pkg-config make gcc g++ gdb
    rsync screen tmux
)

PYTHON_APT_PACKAGES=(
    python3 python3-pip python3-dev python3-venv python3-setuptools python3-wheel
)

GSTREAMER_APT_PACKAGES=(
    gstreamer1.0-tools
    gstreamer1.0-plugins-base
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    gstreamer1.0-libav
)

MULTIMEDIA_APT_PACKAGES=(
    v4l-utils ffmpeg
    libavcodec-dev libavformat-dev libswscale-dev
    libjpeg-dev libpng-dev libtiff-dev
)

HARDWARE_APT_PACKAGES=(
    i2c-tools lm-sensors usbutils pciutils can-utils
)

NETWORK_APT_PACKAGES=(
    net-tools iproute2 iputils-ping dnsutils
    openssh-server nmap ethtool
)

OPENCV_APT_PACKAGES=(
    python3-opencv libopencv-dev
)

# Profile-specific extras
case "$DETECTED_PROFILE" in
    jp6|ubuntu2204) PROFILE_EXTRA_APT_PACKAGES=(linux-tools-common) ;;
    jp5)            PROFILE_EXTRA_APT_PACKAGES=() ;;
    *)              PROFILE_EXTRA_APT_PACKAGES=() ;;
esac

PYTHON_PIP_PACKAGES=(
    numpy pandas matplotlib pillow tqdm psutil
)

if [[ "${OPENCV_SOURCE:-apt}" == "pip" ]]; then
    PYTHON_PIP_PACKAGES+=(opencv-python)
fi

# ----- Install -----
section "Installing common APT packages"
for pkg in "${COMMON_APT_PACKAGES[@]}"; do install_apt_pkg "$pkg"; done

section "Installing Python APT packages"
for pkg in "${PYTHON_APT_PACKAGES[@]}"; do install_apt_pkg "$pkg"; done

section "Installing GStreamer packages"
for pkg in "${GSTREAMER_APT_PACKAGES[@]}"; do install_apt_pkg "$pkg"; done

section "Installing multimedia packages"
for pkg in "${MULTIMEDIA_APT_PACKAGES[@]}"; do install_apt_pkg "$pkg"; done

section "Installing hardware utility packages"
for pkg in "${HARDWARE_APT_PACKAGES[@]}"; do install_apt_pkg "$pkg"; done

section "Installing network packages"
for pkg in "${NETWORK_APT_PACKAGES[@]}"; do install_apt_pkg "$pkg"; done

section "Installing profile-specific packages ($DETECTED_PROFILE)"
for pkg in "${PROFILE_EXTRA_APT_PACKAGES[@]}"; do install_apt_pkg_if_available "$pkg"; done

if [[ "${OPENCV_SOURCE:-apt}" == "apt" ]]; then
    section "Installing OpenCV from APT"
    for pkg in "${OPENCV_APT_PACKAGES[@]}"; do install_apt_pkg "$pkg"; done
else
    warn "Skipping APT OpenCV (OPENCV_SOURCE=$OPENCV_SOURCE)"
fi

section "Installing Python packages"
python3 -m pip install --upgrade pip setuptools wheel 2>&1 | tee -a "$LOG_FILE" || \
    warn "pip self-upgrade reported issues; continuing."

for pkg in "${PYTHON_PIP_PACKAGES[@]}"; do
    pip_install_or_upgrade "$pkg"
done

if [[ "${INSTALL_JETSON_STATS:-yes}" == "yes" ]]; then
    section "Installing jetson-stats"
    if [[ "${JETSON_STATS_VERSION:-latest}" == "latest" ]]; then
        python3 -m pip install -U jetson-stats 2>&1 | tee -a "$LOG_FILE"
    else
        python3 -m pip install -U "jetson-stats==$JETSON_STATS_VERSION" 2>&1 | tee -a "$LOG_FILE"
    fi
    sudo systemctl restart jetson_stats 2>&1 | tee -a "$LOG_FILE" || \
        warn "Could not restart jetson_stats service (will start on next boot)."
fi

ok "Essential packages installed."
