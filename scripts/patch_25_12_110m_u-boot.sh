#!/bin/bash

# 定义文件路径
DTS_FILE="target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts"
MAKEFILE="target/linux/mediatek/image/filogic.mk"

echo "开始修补 OpenWrt 25.12 源码以适配 hanwckf 110M 大分区布局..."

# ==========================================
# 修改 DTS 文件
# ==========================================
if [ -f "$DTS_FILE" ]; then
    echo "正在修改 DTS: $DTS_FILE"
    
    # 使用 awk 精确替换 &partitions { ... }; 块内部的内容
    # 将原本的 partition@580000, 5c0000, 600000 统一替换为 hanwckf 的 0x280000 独占大分区
    awk '
    BEGIN { inside_partitions = 0 }
    /&partitions \{/ { 
        print $0; 
        print "\t/delete-node/ partition@580000;";
        print "\t/delete-node/ partition@5c0000;";
        print "\t/delete-node/ partition@600000;";
        print "\tpartition@280000 {";
        print "\t\tlabel = \"ubi\";";
        print "\t\treg = <0x280000 0x7d00000>;";
        print "\t};";
        inside_partitions = 1; 
        next 
    }
    inside_partitions == 1 { 
        if ($0 ~ /\};/) { 
            inside_partitions = 0; 
            print $0; 
            next 
        } 
        next 
    }
    { print }
    ' "$DTS_FILE" > "${DTS_FILE}.tmp" && mv "${DTS_FILE}.tmp" "$DTS_FILE"

    echo "DTS 修改完成。"
else
    echo "错误: 未找到 DTS 文件 $DTS_FILE ，请检查源码分支是否正确！"
    exit 1
fi

echo "--- $PATCH_110M"

pwd
ls
ls target/linux/mediatek/image

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
sed -n '/&partitions {/,/};/p' "$DTS_FILE"
echo "----------------------------------------------------------"

echo ""
echo "👉 [Makefile 文件] 编译限制与打包配置 (Device Block):"
echo "----------------------------------------------------------"
# 打印 Makefile 尾部的设备定义块
sed -n '/define Device\/xiaomi_redmi-router-ax6000-ubootmod/,/endef/p' "$MAKEFILE"
echo "----------------------------------------------------------"
echo ""