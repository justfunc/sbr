#!/bin/bash

# 定义文件路径
DTS_FILE="target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts"
MAKEFILE="target/linux/mediatek/image/filogic.mk"

echo "开始修补 OpenWrt 25.12 源码以适配 hanwckf 110M 大分区布局..."

# ==========================================
# 修改 DTS 文件
# ==========================================
if [ -f "$DTS_FILE" ]; then
    echo "[-] 正在重写 DTS: $DTS_FILE"
    
    # 2. 【核心改变】绝对不碰原文件的一行代码，不删任何括号！
    # 直接在文件末尾追加一个强力的重写块：先命令编译器删除官方的3个旧分区，再注入我们的 UBI 大分区。
    cat << 'EOF' > "$DTS_FILE"
// SPDX-License-Identifier: (GPL-2.0 OR MIT)

/dts-v1/;
#include "mt7986a-xiaomi-redmi-router-ax6000.dtsi"

/ {
	model = "Xiaomi Redmi Router AX6000 (OpenWrt U-Boot layout)";
	compatible = "xiaomi,redmi-router-ax6000-ubootmod", "mediatek,mt7986a";
};

&chosen {
	rootdisk = <&ubi_rootdisk>;
	bootargs-append = " root=/dev/fit0 rootwait";
};

/* 彻底擦除原厂 NMBM 定义，防止 25.12 内核报错 */

&partitions {
	/* 彻底擦除原厂 crash、crash_log，腾出空间 */

	/* 最优解核心：将 UBI 起点顶到 2.5MB 物理位置 (0x280000) */
	partition@280000 {
		label = "ubi";
		reg = <0x280000 0x7d00000>;
	};
};
EOF

    echo "[✓] DTS 物理覆盖修改完成。"
else
    echo "[x] 错误: 未找到 DTS 文件 $DTS_FILE"
    exit 1
fi

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
  DEVICE_PACKAGES := kmod-leds-ws2812b kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  UBINI_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 128000k
  ARTIFACTS := initramfs-factory.ubi
  ARTIFACT/initramfs-factory.ubi := append-image-stage initramfs-recovery.itb | ubinize-kernel
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
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
echo "=========================================================="
echo "                   修改结果核对日志                        "
echo "=========================================================="
echo ""
echo "👉 [DTS 文件] 当前的分区表配置 (&partitions):"
echo "----------------------------------------------------------"
# 打印 DTS 中 &partitions 开始到结束的代码块
cat "$DTS_FILE"
echo "----------------------------------------------------------"

echo ""
echo "👉 [Makefile 文件] 编译限制与打包配置 (Device Block):"
echo "----------------------------------------------------------"
# 打印 Makefile 尾部的设备定义块
sed -n '/define Device\/xiaomi_redmi-router-ax6000-ubootmod/,/endef/p' "$MAKEFILE"
echo "----------------------------------------------------------"
echo ""