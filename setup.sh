#!/usr/bin/env bash
# Surface Pro 8 舒适配置 — 一键部署脚本
# 用法：sudo bash setup.sh
# 作用：部署 iptsd 触控调优 + iptsd 优先级 + waydroid-rotate 脚本（幂等，可重复运行）

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "错误：请用 root 运行：sudo bash setup.sh"
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Surface Pro 8 舒适配置部署 ==="

# 1. iptsd 触控调优配置
echo "[1/4] 部署 iptsd 触控调优配置"
mkdir -p /etc/iptsd.d
install -m 644 "$REPO_DIR/iptsd/90-touch-sensitivity.conf" /etc/iptsd.d/90-touch-sensitivity.conf

# 2. iptsd 调度优先级（减少多点处理掉帧）
echo "[2/4] 部署 iptsd 调度优先级"
mkdir -p /etc/systemd/system/iptsd@.service.d
install -m 644 "$REPO_DIR/iptsd/iptsd-priority.conf" /etc/systemd/system/iptsd@.service.d/priority.conf

# 3. waydroid-rotate 脚本
echo "[3/4] 部署 waydroid-rotate 脚本"
install -m 755 "$REPO_DIR/waydroid/waydroid-rotate" /usr/local/bin/waydroid-rotate

# 4. 重启 iptsd 生效
echo "[4/4] 重启 iptsd 生效"
systemctl daemon-reload
IPTSD_SVC=$(systemctl list-units --type=service --all --no-legend 2>/dev/null | awk '{print $1}' | grep -E '^iptsd@' | head -1)
if [[ -n "$IPTSD_SVC" ]]; then
    systemctl restart "$IPTSD_SVC"
    echo "已重启 $IPTSD_SVC"
else
    echo "未找到 iptsd 服务（iptsd 可能未安装），跳过"
fi

echo
echo "=== 配置已部署完成 ==="
echo
echo "后续手动步骤（见 README）："
echo "  1. 安装 linux-surface 内核源 + kernel-surface 内核（触控屏必需）"
echo "  2. 切换默认内核：sudo grubby --set-default /boot/vmlinuz-*-surface*"
echo "  3. 重启"
echo "  4. Waydroid 属性设置（如已装 Waydroid，见 README）"
