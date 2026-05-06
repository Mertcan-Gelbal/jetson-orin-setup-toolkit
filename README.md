# Jetson Orin Setup Toolkit

One-command post-install scripts for NVIDIA Jetson Orin (JetPack 5.x / 6.x).

Takes a freshly flashed Jetson and brings it to a ready-to-develop state with system updates, developer tools, GStreamer- and CUDA-enabled OpenCV, PyTorch, Docker, and a verification suite.

## Install

```bash
git clone https://github.com/Mertcan-Gelbal/jetson-orin-setup-toolkit.git
cd jetson-orin-setup-toolkit
bash install.sh
```

Reboot when finished:

```bash
sudo reboot
```

## What Gets Installed

- **Developer tools:** `git`, `curl`, `wget`, `build-essential`, `cmake`, `pkg-config`, `make`, `gcc`, `g++`, `gdb`, `nano`, `vim`, `tmux`, `screen`, `htop`, `tree`, `rsync`, `unzip`, `zip`
- **Python:** `python3`, `python3-pip`, `python3-dev`, `python3-venv`, `python3-setuptools`, `python3-wheel`
- **Python packages:** `numpy`, `pandas`, `matplotlib`, `pillow`, `tqdm`, `psutil`
- **GStreamer:** `gstreamer1.0-tools`, `plugins-base`, `plugins-good`, `plugins-bad`, `plugins-ugly`, `libav`
- **Multimedia:** `ffmpeg`, `v4l-utils`, `libavcodec-dev`, `libavformat-dev`, `libswscale-dev`, `libjpeg-dev`, `libpng-dev`, `libtiff-dev`
- **OpenCV:** `python3-opencv`, `libopencv-dev` (APT build with GStreamer + CUDA flags)
- **Hardware utilities:** `i2c-tools`, `lm-sensors`, `usbutils`, `pciutils`, `can-utils`
- **Networking:** `net-tools`, `iproute2`, `iputils-ping`, `dnsutils`, `openssh-server`, `nmap`, `ethtool`
- **PyTorch:** NVIDIA-built wheel matching your JetPack version
- **Docker:** `docker.io`, `docker-compose-plugin` (user added to `docker` group)
- **JetsonHacks baseline:** `setup_jetson.sh` — VS Code, Chromium, jtop, defaults
- **jetson-stats (jtop):** real-time Jetson task manager

For details, see [`docs/USAGE.md`](docs/USAGE.md) and [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## License

MIT
