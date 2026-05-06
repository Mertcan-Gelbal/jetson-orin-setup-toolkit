# Jetson Orin Setup Toolkit

> A modular, idempotent post-install toolkit for NVIDIA Jetson Orin devices, designed to bring a freshly flashed system to a verified, ready-to-develop state with a single command.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Jetson%20Orin-76B900.svg)](https://developer.nvidia.com/embedded/jetson-modules)
[![JetPack](https://img.shields.io/badge/JetPack-5.x%20%7C%206.x-76B900.svg)](https://developer.nvidia.com/embedded/jetpack)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04-E95420.svg)](https://ubuntu.com/)
[![Shell](https://img.shields.io/badge/Shell-bash-4EAA25.svg)](https://www.gnu.org/software/bash/)

---

## Overview

After flashing a Jetson Orin device, the next several hours are typically spent on repetitive setup: updating APT, installing development tools, configuring GStreamer, fixing CUDA paths, installing PyTorch with the correct CUDA wheels, enabling Docker for the user, and verifying that every subsystem actually works.

This repository automates that entire pipeline. It wraps the well-tested setup scripts maintained by [jetsonhacks](https://github.com/jetsonhacks/jetson-orin-setup) (`setup_jetson.sh` and `install_pytorch_jetson.sh`) and adds a comprehensive layer of:

- automated system detection (L4T release, JetPack version, Ubuntu version, target profile)
- modular installation steps that are individually re-runnable
- a full verification suite that exercises CUDA, OpenCV (with GStreamer/CUDA build flags), GStreamer plugins (`nvarguscamerasrc`, `nvvidconv`, hardware encoders), V4L2 devices, I²C buses, Jetson services, Docker, and SSH
- timestamped logging of every step for reproducible troubleshooting
- a verify-only mode for re-running diagnostics after a reboot or system change

The scripts are **idempotent** — running them twice does no harm — and **non-interactive by default** (with an opt-in confirmation prompt), so they work well in fleet provisioning and CI.

## Supported Devices

| Device                       | JetPack 5.x | JetPack 6.x |
| ---------------------------- | :---------: | :---------: |
| Jetson AGX Orin (32 / 64 GB) |      ✅      |      ✅      |
| Jetson Orin NX (8 / 16 GB)   |      ✅      |      ✅      |
| Jetson Orin Nano             |      ✅      |      ✅      |
| Jetson Orin Nano Super       |      ✅      |      ✅      |

## Prerequisites

- A flashed Jetson Orin device booted into Ubuntu, with `oem-config` already completed.
- JetPack 5.x (Ubuntu 20.04) or JetPack 6.x (Ubuntu 22.04).
- Active internet connection.
- A user with `sudo` privileges (the scripts will prompt for the password where required).

> **Note:** This toolkit is intended to be run **on the Jetson itself**, not on a flashing host. If you still need to flash your device, see NVIDIA's [SDK Manager](https://developer.nvidia.com/sdk-manager) or the [`bootFromExternalStorage`](https://github.com/jetsonhacks/bootFromExternalStorage) workflow first.

## Quick Start

```bash
git clone https://github.com/Mertcan-Gelbal/jetson-orin-setup-toolkit.git
cd jetson-orin-setup-toolkit
chmod +x install.sh
./install.sh
```

That single command will:

1. detect your device, L4T release, and JetPack profile,
2. update and upgrade the system,
3. install essential development tools, GStreamer, multimedia libraries, V4L/I²C utilities, and OpenCV,
4. invoke `jetsonhacks/setup_jetson.sh` for the standard JetsonHacks baseline (jtop, VS Code, Chromium, etc.),
5. install PyTorch optimized for your JetPack version via `jetsonhacks/install_pytorch_jetson.sh`,
6. install and enable Docker (with the user added to the `docker` group),
7. configure CUDA paths in `~/.bashrc`,
8. run a comprehensive verification suite,
9. clean up APT caches and print a summary,
10. log everything to a timestamped `setup_verify_*.log` file.

After completion, **reboot once** so that group changes (Docker), kernel module loads, and `~/.bashrc` updates take full effect:

```bash
sudo reboot
```

## Usage

### Run only the verification suite

Useful after a reboot, after manually installing something, or for periodic health checks:

```bash
VERIFY_ONLY=yes ./install.sh
```

### Run installation but skip verification

```bash
INSTALL_ONLY=yes ./install.sh
```

### Run a single module on its own

Every script under `scripts/` is self-contained:

```bash
sudo ./scripts/core/01_system_update.sh
./scripts/utils/increase_swap.sh
./scripts/verify/verify_system.sh
```

### Non-interactive / unattended mode

```bash
ASK_CONFIRM=no ./install.sh
```

### Customize behavior

Edit `config.env` (or export the variables before running) to change defaults:

```bash
TARGET_PROFILE=auto              # auto | jp6 | jp5 | ubuntu2204
PYTHON_PACKAGE_MODE=apt          # apt | pip
OPENCV_SOURCE=apt                # apt | pip  (apt is strongly recommended on Jetson — GStreamer support)
INSTALL_DOCKER=yes
INSTALL_JETSON_STATS=yes
INSTALL_PYTORCH=yes
RUN_JETSONHACKS_SETUP=yes
JETSON_STATS_VERSION=latest
ASK_CONFIRM=yes
```

## What Gets Installed

### Core (always)

- **Build & dev tools:** `git`, `curl`, `wget`, `build-essential`, `cmake`, `pkg-config`, `gdb`, `nano`, `vim`, `tmux`, `htop`, `tree`, `rsync`
- **Python:** `python3`, `python3-pip`, `python3-venv`, `python3-dev`, plus `numpy`, `pandas`, `matplotlib`, `pillow`, `tqdm`, `psutil`
- **GStreamer:** core + `plugins-base`, `plugins-good`, `plugins-bad`, `plugins-ugly`, `libav` — required for `nvarguscamerasrc` and CSI/USB camera pipelines
- **Multimedia:** `ffmpeg`, `v4l-utils`, codec dev libraries (`libavcodec-dev`, `libavformat-dev`, `libswscale-dev`, `libjpeg-dev`, `libpng-dev`, `libtiff-dev`)
- **Hardware utilities:** `i2c-tools`, `lm-sensors`, `usbutils`, `pciutils`, `can-utils`
- **Networking:** `net-tools`, `iproute2`, `iputils-ping`, `dnsutils`, `openssh-server`, `nmap`, `ethtool`
- **OpenCV:** `python3-opencv` and `libopencv-dev` from APT (the Ubuntu/JetPack build that ships with GStreamer support, which the `pip` wheel does *not* have)

### Optional (controlled via `config.env`)

- **JetsonHacks baseline** (`scripts/core/03_run_jetsonhacks.sh`): clones [`jetsonhacks/jetson-orin-setup`](https://github.com/jetsonhacks/jetson-orin-setup) and runs `setup_jetson.sh`, which installs Chromium, VS Code, jtop, and other JetsonHacks defaults.
- **PyTorch for Jetson** (`scripts/core/04_install_pytorch.sh`): runs the JetsonHacks `install_pytorch_jetson.sh`, which fetches the correct NVIDIA-built PyTorch wheel for your JetPack version (CUDA-accelerated, not the upstream pip wheel).
- **Docker:** `docker.io` + `docker-compose-plugin`, enabled at boot, current user added to the `docker` group.
- **jetson-stats / jtop:** real-time Jetson task manager.

### Utilities (`scripts/utils/`, run manually as needed)

| Script                       | Description                                                                                                |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `increase_swap.sh`           | Configures a 60 GB swap file — recommended for memory-heavy builds (PyTorch from source, large containers). |
| `set_max_power_mode.sh`      | Switches the device to MAXN / MAXN SUPER for full performance.                                              |
| `disable_screen_blank.sh`    | Disables screen blanking and auto-suspend (useful for headless / kiosk / demo setups).                      |
| `install_jetson_stats.sh`    | Standalone install of `jetson-stats` (jtop) without running the full pipeline.                              |

## Verification Suite

The `scripts/verify/verify_system.sh` script confirms — and logs — the actual state of the system, not just what *should* be there. It reports on:

- **System:** hostname, architecture, kernel, OS release, `/etc/nv_tegra_release`, L4T major / revision
- **NVIDIA stack:** installed `nvidia-l4t-*`, `nvidia-jetpack`, `cuda*`, `cudnn*`, `tensorrt*` packages
- **CUDA:** `nvcc --version`, contents of `/usr/local/cuda*`, symlink targets
- **Python:** interpreter, version, `sys.path`, site-packages, and import checks for `numpy`, `pandas`, `matplotlib`, `PIL`, `tqdm`, `psutil`
- **OpenCV:** version, install path, and **build flags** (GStreamer, CUDA, cuDNN, FFMPEG, V4L/V4L2) — this is how you confirm the OpenCV you have actually supports CSI cameras
- **GStreamer:** `gst-launch-1.0` version, plugin probes for `nvarguscamerasrc`, `nvvidconv`, `nvv4l2h264enc`, `nvv4l2h265enc`, `videoconvert`, `appsink`
- **Video / media:** `v4l2-ctl --list-devices`, `media-ctl -p`, `/dev/video*` enumeration
- **I²C:** `/dev/i2c-*` enumeration, `i2cdetect` availability
- **Jetson services:** `nvargus-daemon`, `jetson_stats`
- **Boot config:** `/boot/extlinux/extlinux.conf` — DTB / overlays / camera entries (helps when adding `arducam`, `imx*`, etc.)
- **Docker:** version, `docker compose` plugin, daemon status, group membership
- **Network / SSH:** interfaces, routes, SSH service status, port 22 listener

All output is mirrored to a timestamped log file (`setup_verify_YYYYMMDD_HHMMSS.log`) for sharing in bug reports.

## Project Structure

```
jetson-orin-setup-toolkit/
├── install.sh                          # Top-level orchestrator
├── config.env                          # User-editable configuration
├── scripts/
│   ├── lib/
│   │   └── common.sh                   # Shared logging / helper functions
│   ├── core/
│   │   ├── 00_detect_system.sh         # L4T / JetPack / OS detection
│   │   ├── 01_system_update.sh         # apt update + upgrade
│   │   ├── 02_install_essentials.sh    # dev tools, GStreamer, OpenCV, …
│   │   ├── 03_run_jetsonhacks.sh       # wrapper for jetsonhacks/setup_jetson.sh
│   │   ├── 04_install_pytorch.sh       # wrapper for install_pytorch_jetson.sh
│   │   ├── 05_install_docker.sh        # Docker + group setup
│   │   ├── 06_setup_environment.sh     # CUDA paths in .bashrc
│   │   └── 07_cleanup.sh               # apt autoremove / clean
│   ├── utils/
│   │   ├── increase_swap.sh
│   │   ├── set_max_power_mode.sh
│   │   ├── disable_screen_blank.sh
│   │   └── install_jetson_stats.sh
│   └── verify/
│       └── verify_system.sh
├── docs/
│   ├── USAGE.md
│   └── TROUBLESHOOTING.md
├── LICENSE
└── README.md
```

## Idempotency & Safety

- Every APT install is gated by `dpkg -s` so packages already present are skipped.
- `~/.bashrc` edits are gated by `grep` so paths are never duplicated.
- Optional packages that are missing from the APT index simply emit a `[WARN]` and the script continues — the pipeline never aborts on a non-essential dependency.
- The script uses `set -Eeuo pipefail` and traps on errors, but verification commands are wrapped so a failure in one probe does not mask the rest of the report.
- No destructive operations are performed without an explicit utility script (e.g., swap changes live in `scripts/utils/increase_swap.sh` and must be invoked deliberately).

## Troubleshooting

See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) for common issues, including:

- `nvidia-l4t-*` `dpkg` errors during `apt upgrade`
- OpenCV reporting `GStreamer: NO` after install
- `nvarguscamerasrc` plugin not found after running APT OpenCV
- Docker `permission denied` until reboot
- PyTorch wheel version mismatch on JetPack 6.x

## Acknowledgements

This project stands on the work of the Jetson community:

- [`jetsonhacks/jetson-orin-setup`](https://github.com/jetsonhacks/jetson-orin-setup) — the upstream `setup_jetson.sh` and `install_pytorch_jetson.sh` are invoked directly. Many thanks to **Jim** and the JetsonHacks community.
- [NVIDIA Jetson developer documentation](https://docs.nvidia.com/jetson/) — the canonical source for L4T, JetPack, and CUDA-on-Tegra details.
- [Jetson AI Lab](https://www.jetson-ai-lab.com/) — initial-setup tutorials.

## Contributing

Pull requests are welcome. To contribute:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feat/my-improvement`).
3. Keep new functionality in its own script under `scripts/utils/` or `scripts/core/`, following the existing naming and logging conventions (`log` / `ok` / `warn` / `fail` / `section`).
4. Make sure the script is idempotent and logs to `$LOG_FILE`.
5. Update the `README.md` table and open a PR with a clear description.

## License

This project is licensed under the MIT License — see [`LICENSE`](LICENSE) for details.

The wrapped JetsonHacks scripts remain under the license of [`jetsonhacks/jetson-orin-setup`](https://github.com/jetsonhacks/jetson-orin-setup) (MIT at the time of writing).
