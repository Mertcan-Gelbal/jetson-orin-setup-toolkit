# Jetson Orin Setup Toolkit

NVIDIA Jetson Orin (JetPack 5.x / 6.x) için tek komutla çalışan post-install betikleri.

Yeni flash'lanmış bir Jetson'u; sistem güncellemesi, geliştirici araçları, GStreamer + CUDA destekli OpenCV, PyTorch, Docker ve doğrulama suite'i ile kullanıma hazır hale getirir.

## Kurulum

```bash
git clone https://github.com/Mertcan-Gelbal/jetson-orin-setup-toolkit.git
cd jetson-orin-setup-toolkit
bash install.sh
```

Bittikten sonra `sudo reboot` yapın.

## Modlar

```bash
VERIFY_ONLY=yes bash install.sh    # sadece doğrulama
INSTALL_ONLY=yes bash install.sh   # doğrulama olmadan kurulum
ASK_CONFIRM=no bash install.sh     # gözetimsiz
```

Ayarlar `config.env` dosyasından değiştirilebilir.

## Yardımcı Betikler

`scripts/utils/` altındaki betikler tek başına çalıştırılabilir: swap arttırma, MAXN güç modu, ekran kararmasını kapatma, jetson-stats kurulumu.

Detaylar için [`docs/USAGE.md`](docs/USAGE.md) ve [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## Lisans

MIT
