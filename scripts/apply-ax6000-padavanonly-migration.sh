#!/usr/bin/env bash
#
# apply-ax6000-padavanonly-migration.sh
#
# 把 chasey-dev/immortalwrt-mt798x-rebase 里的
#   xiaomi_redmi-router-ax6000-ubootmod
# 设备代码改写为 padavanonly 分支（openwrt-24.10-6.6）的分区结构：
#   - DTS: 单 ubi(FIT-in-UBI)  ->  固定分区 crash / crash_log / ubi + NMBM 坏块管理
#   - image: sysupgrade.itb(FIT) -> sysupgrade.bin(squashfs+ubi) + 无线固件包
#
# 用法（在 OpenWrt 源码根目录执行）：
#   bash apply-ax6000-padavanonly-migration.sh
#
# 注意：本脚本只改分区/镜像结构，不动内核版本。
#       适用于内核 6.x（含 chasey-dev 的 6.12），因为只用到
#       &spi_nand_flash / &partitions 这两个标签（基础 .dtsi 已定义）。
#
set -euo pipefail

# 以脚本所在仓库的根为基准（如果你的 OpenWrt 源码在子目录，改这里）
DTS_PATH="target/linux/mediatek/dts-ext/mt7986a-xiaomi-redmi-router-ax6000-mtkuboot.dts"
MK_PATH="target/linux/mediatek/image/filogic-ext.mk"

echo "==> OpenWrt root: $(pwd)"

# ---------------------------------------------------------------------------
# 1) 写入迁移后的 DTS（采用 padavanonly 的分区结构）
# ---------------------------------------------------------------------------
if [ ! -f "$DTS_PATH" ]; then
    echo "ERROR: 找不到 $DTS_PATH" >&2
    echo "       请确认在 OpenWrt 源码根目录运行，或修改 OPENWRT_ROOT 环境变量。" >&2
    exit 1
fi

cat > "$DTS_PATH" <<'DTS_EOF'
// SPDX-License-Identifier: (GPL-2.0 OR MIT)

/dts-v1/;
#include "../dts/mt7986a-xiaomi-redmi-router-ax6000.dtsi"

/ {
	model = "Xiaomi Redmi Router AX6000 (MTK U-Boot layout)";
	compatible = "xiaomi,redmi-router-ax6000-ubootmod", "mediatek,mt7986a";
};

&spi_nand_flash {
	mediatek,nmbm;
	mediatek,bmt-max-ratio = <1>;
	mediatek,bmt-max-reserved-blocks = <64>;
};

&partitions {
	partition@580000 {
		label = "ubi";
		reg = <0x580000 0x6e80000>;
	};
};
DTS_EOF
echo "==> 已写入迁移后 DTS: $DTS_PATH"

# ---------------------------------------------------------------------------
# 2) 改写 filogic.mk 里的 xiaomi_redmi-router-ax6000-ubootmod 设备块
#    sysupgrade.itb(FIT-in-UBI) -> sysupgrade.bin(squashfs+ubi)
#    并保留 BL2/FIP 引导镜像产物，方便工厂刷机。
# ---------------------------------------------------------------------------
if [ ! -f "$MK_PATH" ]; then
    echo "ERROR: 找不到 $MK_PATH" >&2
    exit 1
fi

# 用 python 做整块替换，避免 fragile 的上下文 patch。
export MK_PATH
python3 - "$MK_PATH" <<'PY_EOF'
import re, sys

mk_path = sys.argv[1]
with open(mk_path, "r", encoding="utf-8") as f:
    content = f.read()

new_block = '''define Device/xiaomi_redmi-router-ax6000-mtkuboot
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Redmi Router AX6000
  DEVICE_VARIANT := (MTK U-Boot layout)
  DEVICE_DTS := mt7986a-xiaomi-redmi-router-ax6000-mtkuboot
  DEVICE_DTS_DIR := ../dts-ext
  DEVICE_PACKAGES := kmod-leds-ws2812b
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 113152k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  SUPPORTED_DEVICES += xiaomi,redmi-router-ax6000-ubootmod
endef'''

# 匹配从 define ... 到对应的 endef（非贪婪，DOTALL）
pattern = re.compile(
    r"define Device/xiaomi_redmi-router-ax6000-mtkuboot\n.*?\nendef",
    re.DOTALL,
)
matches = pattern.findall(content)
if not matches:
    print("ERROR: 在 filogic.mk 中未找到 xiaomi_redmi-router-ax6000-ubootmod 设备块", file=sys.stderr)
    sys.exit(2)
if len(matches) > 1:
    print("WARN: 找到多个匹配，仅替换第一个", file=sys.stderr)

content = pattern.sub(new_block, content, count=1)
with open(mk_path, "w", encoding="utf-8") as f:
    f.write(content)
print("==> 已改写 filogic.mk 设备块")
PY_EOF

echo "-------------------"
cat $DTS_PATH

cat $MK_PATH

echo "-------------------"

echo "==> 迁移完成。接下来正常 make 即可，产物为 sysupgrade.bin（squashfs+ubi）。"
