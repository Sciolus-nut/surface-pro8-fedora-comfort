# Surface Pro 8 — Linux 舒适配置集

针对微软 Surface Pro 8（x86_64，触控屏 + 触控笔）的一套 Linux 调优配置，目标是「开箱即舒适」：触控跟手、多指手势稳定、能跑安卓应用（Waydroid）。

> English version: [README.md](README.md)

## 适用环境

- 硬件：Surface Pro 8（Surface 触控屏走 IPTS 协议，设备 ID `045E:0991`）
- 系统：Fedora 44（secureblue 加固版亦可，本配置即在其上验证）
- 内核：linux-surface 定制内核（**必须有**，否则触控屏无驱动）

## 这套配置解决了什么

1. **触控不跟手 / 轻触不灵**：iptsd 默认触点检测阈值（24/20）对 SP8 偏高，轻触不易注册。这里降到 8/6，并调 PeakSuppression 让多指分离更锐利。
2. **三指手势偶发变「拖动窗口」**：GNOME/mutter 触摸先落到窗口会优先进「拖动窗口」分支。加强 PeakSuppression 让三指峰更清晰，mutter 更早判定为三指手势。
3. **Waydroid 窗口大小 / 方向**：单窗口模式 + 横竖屏一键切换脚本。
4. **游戏触控**：Waydroid `fake_touch` 让鼠标模拟触摸（coc 等触摸游戏可用鼠标玩）。

## 目录结构

```
.
├── README.md                          # English
├── README.zh-CN.md                    # 简体中文
├── setup.sh                          # 一键部署配置（需 sudo）
├── iptsd/
│   ├── 90-touch-sensitivity.conf     # 触点检测调优（核心）
│   └── iptsd-priority.conf           # 提高 iptsd 调度优先级，减少多点掉帧
└── waydroid/
    └── waydroid-rotate               # Waydroid 横竖屏一键切换脚本
```

## 快速开始

### 1. 安装 linux-surface 内核（触控屏必需）

Fedora 的默认内核**不含** Surface 触控驱动（`CONFIG_HID_IPTS` / `CONFIG_HID_ITHC`），
必须换 linux-surface 内核：

```bash
# 添加 linux-surface 源（Fedora）
sudo dnf config-manager --add-repo https://pkg.surfacelinux.com/fedora/linux-surface.repo
# 安装内核 + iptsd
sudo dnf install --allowerasing kernel-surface iptsd libwacom-surface surface-secureboot
# 重启后切默认内核
sudo grubby --set-default /boot/vmlinuz-*-surface*
sudo reboot
```

> 验证驱动：`grep -E "CONFIG_HID_IPTS|CONFIG_HID_ITHC" /boot/config-$(uname -r)` 有输出即正常。

### 2. 部署本仓库配置

```bash
git clone <本仓库>
cd surface-pro8-fedora-comfort
sudo bash setup.sh
```

### 3. Waydroid（可选）

参考 [Waydroid 官方安装](https://docs.waydro.id/)，装好后执行：

```bash
# 单窗口模式（整个安卓是一个窗口，可横竖屏切换）
waydroid prop set persist.waydroid.multi_windows false
# 竖屏 405x720（微信/QQ 等竖屏应用）
waydroid-rotate portrait
# 横屏 960x540（coc 等横屏游戏）
waydroid-rotate landscape
# 游戏触控：鼠标模拟触摸（Supercell 游戏，包名按需改）
waydroid prop set persist.waydroid.fake_touch "com.supercell.*"
```

## 调优原理（简要）

- **iptsd** 是 Surface 触摸屏的用户态处理进程，把电容热图转成标准触摸事件。它的触点检测有几个关键参数（见 `iptsd/90-touch-sensitivity.conf`）。
- **ActivationThreshold / DeactivationThreshold**：触点「出现/消失」的阈值。默认 24/20 对 SP8 偏高，轻触要用力才认。
- **PeakSuppressionRadius / Factor**：找到触点峰后，把峰周围一圈像素调暗，人为挖深「谷」，让靠得近的多指被拆成独立触点。Radius 管范围、Factor 管力度（越小越狠）。
  - 本配置 `radius=2 / factor=0.2` 是平衡点：三指手势稳定、单指单击也不丢。
  - 更激进（`radius=3 / factor=0.12`）三指更稳但**单击会偶发丢失**，别用。

## 恢复默认

```bash
sudo rm /etc/iptsd.d/90-touch-sensitivity.conf
sudo rm /etc/systemd/system/iptsd@.service.d/priority.conf
sudo systemctl daemon-reload
sudo systemctl restart iptsd@dev-hidraw0.service
```

## 免责声明

本配置在作者自己的 Surface Pro 8（Fedora 44 + secureblue）上验证。硬件批次、内核版本、
桌面环境差异可能导致效果不同，请自行判断是否适用。
