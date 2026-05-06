# Troubleshooting

Common issues seen on Jetson Orin during post-install, and how to recover.

---

## 1. `apt upgrade` fails with `nvidia-l4t-*` `dpkg` errors

Symptoms — output similar to:

```
Errors were encountered while processing:
 nvidia-l4t-bootloader
 nvidia-l4t-kernel
 ...
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

This usually happens when:

- the device was flashed with one JetPack version and APT is offering a newer one that ships kernel/bootloader packages incompatible with the current QSPI firmware, **or**
- the `/boot` partition is too small for new kernel images.

What to try:

```bash
# See exactly which packages are broken
dpkg -l | grep -E "nvidia-l4t" | grep -v "^ii"

# Try to fix half-installed packages
sudo apt --fix-broken install

# As a last resort, remove the offending packages and let JetPack reinstall
sudo apt purge <package>
sudo apt install nvidia-jetpack
```

If the device's UEFI firmware is older than the JetPack version you're trying to run, you may need to update the QSPI firmware first — see the [Jetson AI Lab initial setup guide](https://www.jetson-ai-lab.com/tutorials/initial-setup-jetson-orin-nano/).

---

## 2. OpenCV reports `GStreamer: NO` after install

`pip install opencv-python` ships a build that does **not** link GStreamer. If you need `cv2.VideoCapture("v4l2src ! ...")` or `nvarguscamerasrc` pipelines, you must use the APT build.

Fix:

```bash
sudo apt remove --purge python3-opencv libopencv-dev
python3 -m pip uninstall -y opencv-python opencv-contrib-python opencv-python-headless
sudo apt install -y python3-opencv libopencv-dev

# Verify
python3 -c "import cv2; print([l for l in cv2.getBuildInformation().split('\n') if 'GStreamer' in l])"
```

Set `OPENCV_SOURCE=apt` in `config.env` (the default) to make the pipeline do this for you.

If you need OpenCV with **CUDA** (in addition to GStreamer), the APT build does not include it — you have to build OpenCV from source. JetsonHacks publishes a build script for this; that path is out of scope for this repo.

---

## 3. `gst-inspect-1.0 nvarguscamerasrc` says "No such element"

The `nvarguscamerasrc` plugin is part of the NVIDIA Multimedia API, which lives in `/usr/lib/aarch64-linux-gnu/gstreamer-1.0/` and is only present if the JetPack multimedia packages are installed.

Check:

```bash
ls /usr/lib/aarch64-linux-gnu/gstreamer-1.0/ | grep -i nvargus
dpkg -l | grep -i nvidia-l4t-multimedia
```

Recover:

```bash
sudo apt install --reinstall nvidia-l4t-multimedia nvidia-l4t-camera
```

Then make sure the `nvargus-daemon` is running:

```bash
sudo systemctl restart nvargus-daemon
sudo systemctl status  nvargus-daemon
```

---

## 4. `docker: permission denied` after install

The `docker` group membership only takes effect in **new** login sessions.

Quick fix without rebooting:

```bash
newgrp docker
docker run --rm hello-world
```

Or just:

```bash
sudo reboot
```

---

## 5. PyTorch wheel mismatch on JetPack 6.x

The Jetson PyTorch wheel must match (a) JetPack version, (b) CUDA version on the device, and (c) Python version. If `import torch` reports `CUDA version mismatch` or `cuda is not available` immediately after install:

```bash
# Confirm CUDA on device
nvcc --version

# Confirm Python
python3 -V

# Re-run with verbose output
bash scripts/core/04_install_pytorch.sh
```

NVIDIA publishes the official wheel index at:
<https://developer.download.nvidia.com/compute/redist/jp/>

If JetsonHacks's `install_pytorch_jetson.sh` cannot find a wheel for your combination, you may need to:

- update to the JetPack version the wheel targets, or
- build PyTorch from source (very long; consider increasing swap with `scripts/utils/increase_swap.sh` first).

---

## 6. `jtop` says "service not running"

```bash
sudo systemctl restart jetson_stats
sudo systemctl status  jetson_stats
```

If it is masked or missing:

```bash
sudo -H python3 -m pip install -U jetson-stats
sudo systemctl daemon-reload
sudo systemctl enable  jetson_stats
sudo systemctl restart jetson_stats
```

---

## 7. CSI camera not detected (no `/dev/video0`)

CSI cameras require a matching device tree overlay. After flashing, you usually have to:

1. Run `sudo /opt/nvidia/jetson-io/jetson-io.py`
2. Choose your camera (e.g. IMX219 / IMX477 / Arducam)
3. Save and reboot

Then re-run:

```bash
ls -l /dev/video*
v4l2-ctl --list-devices
gst-launch-1.0 nvarguscamerasrc ! 'video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1' ! nvvidconv ! xvimagesink
```

---

## 8. Out of memory while installing or building

Add swap (a one-shot 60GB swap file is provided as a utility):

```bash
bash scripts/utils/increase_swap.sh
```

Then retry the failing step. After heavy builds you can free the swap with `sudo swapoff /mnt/60GB.swap` and remove the file if you want the disk space back.

---

## 9. The script aborts mid-run

`install.sh` runs with `set -Eeuo pipefail` and traps errors. The line number is reported and the partial log is preserved (`setup_verify_*.log`).

When opening an issue, please attach:

- the `setup_verify_*.log` file,
- the contents of `/etc/nv_tegra_release`,
- `uname -a`,
- `lsb_release -a`.
