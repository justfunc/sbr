#!/bin/bash

# 定义文件路径
MAKEFILE="target/linux/mediatek/image/filogic.mk"

# ==========================================
# 修改 Makefile (filogic.mk)
# ==========================================
if [ -f "$MAKEFILE" ]; then
    echo "正在修改 Makefile: $MAKEFILE"
    
    # 1. 先用 awk 把原有的 define Device/xiaomi_redmi-router-ax6000-ubootmod 块完全剔除
    # 防止多次运行脚本时重复追加导致编译报错
    awk '
    BEGIN { skip = 0 }
    /define Device\/xiaomi_redmi-router-ax6000-ubootmod/ { skip = 1; next }
    /TARGET_DEVICES \+= xiaomi_redmi-router-ax6000-ubootmod/ { if (skip == 1) { skip = 0; next } }
    skip == 1 { next }
    { print }
    ' "$MAKEFILE" > "${MAKEFILE}.tmp" && mv "${MAKEFILE}.tmp" "$MAKEFILE"

    # 2. 将我们精简优化过的 hanwckf 专用打包定义追加到 Makefile 末尾
    cat << 'EOF' >> "$MAKEFILE"

define Device/xiaomi_redmi-router-ax6000-ubootmod
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Redmi Router AX6000
  DEVICE_VARIANT := (OpenWrt U-Boot layout)
  DEVICE_DTS := mt7986a-xiaomi-redmi-router-ax6000-ubootmod
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-leds-ws2812b kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware kmod-mt7986-wed iwinfo
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
  ARTIFACTS += initramfs-factory.ubi
  ARTIFACT/initramfs-factory.ubi := append-image-stage initramfs-recovery.itb | ubinize-kernel
endif
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  SUPPORTED_DEVICES += xiaomi,redmi-router-ax6000-mtkuboot
endef
TARGET_DEVICES += xiaomi_redmi-router-ax6000-ubootmod
EOF

    echo "Makefile 修改完成。"
else
    echo "错误: 未找到 Makefile 文件 $MAKEFILE"
    exit 1
fi

# ==========================================
# 打印修改结果日志
# ==========================================
echo ""
echo "👉 [Makefile 文件] 编译限制与打包配置 (Device Block):"
echo "----------------------------------------------------------"
# 打印 Makefile 尾部的设备定义块
sed -n '/define Device\/xiaomi_redmi-router-ax6000-ubootmod/,/endef/p' "$MAKEFILE"
echo "----------------------------------------------------------"
echo ""