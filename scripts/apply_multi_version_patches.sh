#!/bin/bash

TARGET_FILE="immortalwrt/target/linux/mediatek/image/filogic.mk"
NEW_BLOCK="target/linux/mediatek/image/filogic_ax6000_ubootmod.mk"

# 1. 查找旧代码块的行号
start_line=$(grep -nF "define Device/xiaomi_redmi-router-ax6000-ubootmod" "$TARGET_FILE" | cut -d: -f1)
end_line=$(grep -nF "TARGET_DEVICES += xiaomi_redmi-router-ax6000-ubootmod" "$TARGET_FILE" | cut -d: -f1)

# 2. 如果找到了旧代码，先执行删除
if [ -n "$start_line" ] && [ -n "$end_line" ]; then
    echo "正在删除旧的 ax6000-ubootmod 定义 (第 $start_line 到 $end_line 行)..."
    # 使用 sed 删除指定范围
    sed -i "${start_line},${end_line}d" "$TARGET_FILE"
fi

# 3. 无论之前是否存在，都将新定义追加到文件末尾
# 这样可以确保不会插在其他 Device 定义的中间
echo "正在追加新的定义到文件末尾..."
cat "$NEW_BLOCK" >> "$TARGET_FILE"

echo "替换与追加完成！"

cp -f target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts immortalwrt/target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts

cp defconfig/mt7986a-ax6000-ubootmod.config immortalwrt/.config