# Usage Guide

This guide goes one level deeper than the README and walks through the most common workflows.

## 1. First-time setup on a freshly flashed Jetson

```bash
# Clone the repo
git clone https://github.com/<your-user>/jetson-orin-postinstall.git
cd jetson-orin-postinstall

# (Optional) review and edit defaults
nano config.env

# Run
chmod +x install.sh
./install.sh
```

When the run finishes, reboot:

```bash
sudo reboot
```

The reboot is necessary so that:

- the user's `docker` group membership becomes active,
- new `~/.bashrc` exports (CUDA paths) load in fresh shells,
- any kernel-module updates pulled by `apt upgrade` take effect.

## 2. Verifying after a reboot

```bash
VERIFY_ONLY=yes ./install.sh
```

This re-runs every diagnostic in `scripts/verify/verify_system.sh` without re-installing anything. The output goes both to the terminal and to `setup_verify_<timestamp>.log`. Attach this log when you open issues — it contains the L4T release, package list, OpenCV build flags, GStreamer plugin probes, and Docker state.

## 3. Running individual modules

Each script under `scripts/` is self-contained and sources `scripts/lib/common.sh` on its own. You can invoke them directly:

```bash
# Just update the system
bash scripts/core/01_system_update.sh

# Install only the essential dev/multimedia stack
bash scripts/core/02_install_essentials.sh

# Just install Docker
bash scripts/core/05_install_docker.sh

# Run only the verification suite
bash scripts/verify/verify_system.sh
```

## 4. Skipping optional components

Edit `config.env`:

```bash
INSTALL_DOCKER=no
INSTALL_PYTORCH=no
RUN_JETSONHACKS_SETUP=no
INSTALL_JETSON_STATS=no
```

…or override per-run:

```bash
INSTALL_DOCKER=no INSTALL_PYTORCH=no ./install.sh
```

## 5. Unattended / fleet provisioning

Set `ASK_CONFIRM=no` to skip the y/N prompt:

```bash
ASK_CONFIRM=no ./install.sh 2>&1 | tee provisioning.log
```

You can also pin the JetsonHacks repo to a known-good commit by editing the wrapper:

```bash
JH_REPO_REF=main ./scripts/core/03_run_jetsonhacks.sh
# or pin a specific SHA:
JH_REPO_REF=<commit-sha> ./scripts/core/03_run_jetsonhacks.sh
```

## 6. Running utility scripts

The utilities under `scripts/utils/` are deliberately not invoked by the main pipeline — they make destructive or environment-changing changes (allocating 60GB of swap, switching power mode, masking sleep targets) and should be a deliberate choice.

```bash
# 60GB swap (recommended on devices that build PyTorch / large containers)
bash scripts/utils/increase_swap.sh

# Switch to MAXN / MAXN SUPER
bash scripts/utils/set_max_power_mode.sh

# Disable screen blanking (kiosk / demo mode)
bash scripts/utils/disable_screen_blank.sh

# Standalone jtop install (without the full pipeline)
bash scripts/utils/install_jetson_stats.sh
```

## 7. Logs

Each run writes `setup_verify_YYYYMMDD_HHMMSS.log` in the repo root. These logs are listed in `.gitignore`. Keep them when troubleshooting and delete them otherwise.
