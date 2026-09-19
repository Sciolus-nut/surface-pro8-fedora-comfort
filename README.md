# Surface Pro 8 — Comfortable Linux Config

A set of Linux tuning configs for the Microsoft Surface Pro 8 (x86_64, touchscreen + stylus), aiming for "comfortable out of the box": responsive touch, stable multi-finger gestures, and Android apps via Waydroid.

## Target environment

- Hardware: Surface Pro 8 (touchscreen uses the IPTS protocol, device ID `045E:0991`)
- OS: Fedora 44 (secureblue hardened edition also works — this config was verified on it)
- Kernel: linux-surface custom kernel (**required**, otherwise no touchscreen driver)

## What this config fixes

1. **Unresponsive touch / light taps not registering**: iptsd's default contact detection thresholds (24/20) are too high for the SP8, so light taps need excessive pressure. Lowered to 8/6 here, plus PeakSuppression tuning for sharper multi-finger separation.
2. **Three-finger gestures occasionally become "window drag"**: GNOME/mutter prioritizes window dragging when touch lands on a window. Stronger PeakSuppression makes the three peaks clearer, so mutter recognizes the gesture sooner.
3. **Waydroid window size / orientation**: single-window mode + a one-command portrait/landscape switcher.
4. **Game touch input**: Waydroid `fake_touch` maps mouse to touch (play touch-only games like Clash of Clans with a mouse).

## Directory layout

```
.
├── README.md
├── README.zh-CN.md                   # 简体中文
├── setup.sh                          # One-shot config deployment (needs sudo)
├── iptsd/
│   ├── 90-touch-sensitivity.conf     # Contact detection tuning (core)
│   └── iptsd-priority.conf           # Higher iptsd scheduling priority, fewer multi-touch dropouts
└── waydroid/
    └── waydroid-rotate               # One-command Waydroid portrait/landscape switch
```

## Quick start

### 1. Install the linux-surface kernel (required for touchscreen)

Fedora's stock kernel does **not** include Surface touch drivers (`CONFIG_HID_IPTS` / `CONFIG_HID_ITHC`), so you must switch to the linux-surface kernel:

```bash
# Add the linux-surface repo (Fedora)
sudo dnf config-manager --add-repo https://pkg.surfacelinux.com/fedora/linux-surface.repo
# Install kernel + iptsd
sudo dnf install --allowerasing kernel-surface iptsd libwacom-surface surface-secureboot
# Reboot, then set the default kernel
sudo grubby --set-default /boot/vmlinuz-*-surface*
sudo reboot
```

> Verify the driver: `grep -E "CONFIG_HID_IPTS|CONFIG_HID_ITHC" /boot/config-$(uname -r)` should print output.

### 2. Deploy this repo's configs

```bash
git clone <this-repo>
cd surface-pro8-fedora-comfort
sudo bash setup.sh
```

### 3. Waydroid (optional)

Follow the [official Waydroid install](https://docs.waydro.id/), then:

```bash
# Single-window mode (whole Android is one window, switchable orientation)
waydroid prop set persist.waydroid.multi_windows false
# Portrait 405x720 (WeChat/QQ and other portrait apps)
waydroid-rotate portrait
# Landscape 960x540 (Clash of Clans and other landscape games)
waydroid-rotate landscape
# Mouse-as-touch for games (Supercell; adjust package names as needed)
waydroid prop set persist.waydroid.fake_touch "com.supercell.*"
```

## How the tuning works (brief)

- **iptsd** is the userspace process that turns Surface's capacitive heatmap into standard touch events. Its contact detection has a few key parameters (see `iptsd/90-touch-sensitivity.conf`).
- **ActivationThreshold / DeactivationThreshold**: the "appear / disappear" thresholds for contacts. The defaults (24/20) are too high for the SP8.
- **PeakSuppressionRadius / Factor**: after finding a contact peak, darken the pixels around it to artificially deepen the "valley" between neighboring fingers, so close fingers split into separate contacts. Radius controls range, Factor controls strength (smaller = stronger).
  - This repo's `radius=2 / factor=0.2` is the sweet spot: stable three-finger gestures without dropping single taps.
  - Going more aggressive (`radius=3 / factor=0.12`) stabilizes three-finger gestures but **single taps drop occasionally** — don't use it.

## Restore defaults

```bash
sudo rm /etc/iptsd.d/90-touch-sensitivity.conf
sudo rm /etc/systemd/system/iptsd@.service.d/priority.conf
sudo systemctl daemon-reload
sudo systemctl restart iptsd@dev-hidraw0.service
```

## Upstream projects

This config builds on:

- [linux-surface](https://github.com/linux-surface/linux-surface) — the custom kernel that adds Surface touchscreen support
- [iptsd](https://github.com/linux-surface/iptsd) — the userspace daemon that turns Surface's touch heatmap into touch events
- [Waydroid](https://github.com/waydroid/waydroid) — Android in a Linux container
- [Fedora](https://fedoraproject.org/) — the base OS

## Disclaimer

Verified on the author's own Surface Pro 8 (Fedora 44 + secureblue). Hardware batches, kernel versions, and desktop environments vary — your mileage may vary.
