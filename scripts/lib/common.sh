#!/usr/bin/env bash
# ============================================================
# scripts/lib/common.sh
# Shared helpers: logging, package install, system detection.
# Sourced by every script in this repository.
# ============================================================

# ----- Colors -----
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# ----- Logging -----
# LOG_FILE is expected to be set by the caller (install.sh) or
# defaults to a per-run timestamped file when a script is run
# stand-alone.
: "${LOG_FILE:=setup_verify_$(date +%Y%m%d_%H%M%S).log}"

log()     { echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
ok()      { echo -e "${GREEN}[OK]${NC} $*"  | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
fail()    { echo -e "${RED}[FAIL]${NC} $*"  | tee -a "$LOG_FILE"; }
section() {
    echo | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
    echo "$*" | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
}

run_cmd() {
    log "Running: $*"
    "$@" 2>&1 | tee -a "$LOG_FILE"
}

# ----- Predicates -----
command_exists()    { command -v "$1" >/dev/null 2>&1; }
apt_pkg_installed() { dpkg -s "$1" >/dev/null 2>&1; }

# ----- APT helpers -----
install_apt_pkg() {
    local pkg="$1"
    if apt_pkg_installed "$pkg"; then
        ok "APT package already installed: $pkg"
    else
        log "Installing APT package: $pkg"
        sudo apt install -y "$pkg" 2>&1 | tee -a "$LOG_FILE"
    fi
}

install_apt_pkg_if_available() {
    local pkg="$1"
    if apt_pkg_installed "$pkg"; then
        ok "APT package already installed: $pkg"
        return 0
    fi
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        log "Installing optional APT package: $pkg"
        sudo apt install -y "$pkg" 2>&1 | tee -a "$LOG_FILE"
    else
        warn "Optional APT package not available in current repositories: $pkg"
    fi
}

pip_install_or_upgrade() {
    local pkg="$1"
    log "Installing/upgrading Python package: $pkg"
    python3 -m pip install -U "$pkg" 2>&1 | tee -a "$LOG_FILE"
}

# ----- User confirmation -----
confirm_or_exit() {
    if [[ "${ASK_CONFIRM:-yes}" == "yes" ]]; then
        echo
        read -r -p "Continue with installation and verification? [y/N]: " answer
        case "$answer" in
            y|Y|yes|YES) ok "Continuing..." ;;
            *)           warn "Cancelled by user."; exit 0 ;;
        esac
    fi
}

# ----- Verify helpers -----
verify_command() {
    local cmd="$1" label="$2"
    if command_exists "$cmd"; then
        ok "$label found: $(command -v "$cmd")"
        return 0
    else
        fail "$label not found"
        return 1
    fi
}

verify_apt_package() {
    local pkg="$1"
    if apt_pkg_installed "$pkg"; then
        ok "APT package installed: $pkg"
        return 0
    else
        fail "APT package missing: $pkg"
        return 1
    fi
}

# ----- System detection -----
# Populates: HOSTNAME_VALUE, ARCH_VALUE, KERNEL_VALUE,
#            OS_NAME, OS_VERSION, OS_CODENAME,
#            NV_TEGRA_RELEASE, L4T_MAJOR, L4T_REVISION,
#            DETECTED_PROFILE
detect_system_info() {
    HOSTNAME_VALUE="$(hostname || true)"
    ARCH_VALUE="$(uname -m || true)"
    KERNEL_VALUE="$(uname -r || true)"

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        OS_NAME="${NAME:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"
        OS_CODENAME="${VERSION_CODENAME:-unknown}"
    else
        OS_NAME="unknown"; OS_VERSION="unknown"; OS_CODENAME="unknown"
    fi

    if [[ -f /etc/nv_tegra_release ]]; then
        NV_TEGRA_RELEASE="$(cat /etc/nv_tegra_release)"
    else
        NV_TEGRA_RELEASE="not_found"
    fi

    if [[ "$NV_TEGRA_RELEASE" =~ R([0-9]+) ]]; then
        L4T_MAJOR="${BASH_REMATCH[1]}"
    else
        L4T_MAJOR="unknown"
    fi

    if [[ "$NV_TEGRA_RELEASE" =~ REVISION:\ ([0-9]+\.[0-9]+) ]]; then
        L4T_REVISION="${BASH_REMATCH[1]}"
    else
        L4T_REVISION="unknown"
    fi

    if [[ "${TARGET_PROFILE:-auto}" == "auto" ]]; then
        if   [[ "$L4T_MAJOR" == "36" ]];     then DETECTED_PROFILE="jp6"
        elif [[ "$L4T_MAJOR" == "35" ]];     then DETECTED_PROFILE="jp5"
        elif [[ "$OS_VERSION" == "22.04" ]]; then DETECTED_PROFILE="ubuntu2204"
        else                                       DETECTED_PROFILE="generic"
        fi
    else
        DETECTED_PROFILE="$TARGET_PROFILE"
    fi

    export HOSTNAME_VALUE ARCH_VALUE KERNEL_VALUE
    export OS_NAME OS_VERSION OS_CODENAME
    export NV_TEGRA_RELEASE L4T_MAJOR L4T_REVISION DETECTED_PROFILE
}
