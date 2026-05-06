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

## Modes

```bash
VERIFY_ONLY=yes bash install.sh    # verification only
INSTALL_ONLY=yes bash install.sh   # install without verification
ASK_CONFIRM=no bash install.sh     # unattended
```

Settings can be customized via `config.env`.

## Utility Scripts

Scripts under `scripts/utils/` can be run individually: increase swap, set MAXN power mode, disable screen blanking, install jetson-stats.

For details, see [`docs/USAGE.md`](docs/USAGE.md) and [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## License

MIT
