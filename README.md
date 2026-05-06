# Jetson Orin Setup Toolkit

NVIDIA Jetson Orin (JetPack 5.x / 6.x) için tek komutla çalışan post-install betikleri. Sistem güncellemesi, geliştirici araçları, GStreamer + CUDA destekli OpenCV, PyTorch (Jetson wheel'i), Docker kurulumu ve doğrulama suite'i içerir.

## Desteklenen Cihazlar

Jetson AGX Orin · Orin NX · Orin Nano · Orin Nano Super  
JetPack 5.x (Ubuntu 20.04) ve JetPack 6.x (Ubuntu 22.04)

## Kullanım

```bash
git clone https://github.com/Mertcan-Gelbal/jetson-orin-setup-toolkit.git
cd jetson-orin-setup-toolkit
chmod +x install.sh
./install.sh
```

Kurulum bittikten sonra `sudo reboot` yapın (Docker grubu ve `~/.bashrc` değişiklikleri için).

### Modlar

```bash
./install.sh                    # tam kurulum + doğrulama
VERIFY_ONLY=yes ./install.sh    # sadece doğrulama
INSTALL_ONLY=yes ./install.sh   # kurulum, doğrulama yok
ASK_CONFIRM=no ./install.sh     # gözetimsiz
```

Davranışı `config.env` üzerinden değiştirebilirsiniz (Docker / PyTorch / JetsonHacks / OpenCV kaynağı vb.).

## Ne Kuruluyor

- **Geliştirici araçları:** git, cmake, build-essential, gdb, tmux, htop …
- **Python:** python3 + numpy, pandas, matplotlib, pillow, tqdm, psutil
- **GStreamer:** core + plugins-{base,good,bad,ugly} + libav (CSI/USB kamera için)
- **OpenCV:** APT'tan (GStreamer + CUDA build flag'li)
- **PyTorch:** JetPack sürümüne uygun NVIDIA wheel'i (jetsonhacks scripti)
- **Docker:** docker.io + compose plugin, kullanıcı `docker` grubuna eklenir
- **jetson-stats (jtop)** ve JetsonHacks varsayılanları (VS Code, Chromium vb.)

## Yardımcı Betikler

`scripts/utils/` altında tek başına çalıştırılabilir:

| Betik | Açıklama |
| --- | --- |
| `increase_swap.sh` | 60 GB swap oluşturur |
| `set_max_power_mode.sh` | MAXN / MAXN SUPER moduna geçer |
| `disable_screen_blank.sh` | Ekran kararmasını kapatır |
| `install_jetson_stats.sh` | Sadece jtop kurar |

## Doğrulama

`scripts/verify/verify_system.sh` çalıştırıldığında L4T sürümü, CUDA, OpenCV build flag'leri, GStreamer plugin'leri (`nvarguscamerasrc`, `nvvidconv`, NV encoder'lar), `/dev/video*`, I²C, Docker ve SSH durumunu raporlar. Çıktı `setup_verify_YYYYMMDD_HHMMSS.log` dosyasına yazılır.

## Yapı

```
jetson-orin-setup-toolkit/
├── install.sh
├── config.env
├── scripts/
│   ├── lib/common.sh
│   ├── core/         # 00_detect ... 07_cleanup
│   ├── utils/        # swap, power, screen, jtop
│   └── verify/verify_system.sh
└── docs/             # USAGE.md, TROUBLESHOOTING.md
```

Sorunlar için: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

## Teşekkür

[`jetsonhacks/jetson-orin-setup`](https://github.com/jetsonhacks/jetson-orin-setup) — `setup_jetson.sh` ve `install_pytorch_jetson.sh` doğrudan kullanılıyor.

## Lisans

MIT — bkz. [`LICENSE`](LICENSE).
