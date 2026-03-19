#!/bin/bash

TARGET_FILE="immortalwrt/target/linux/mediatek/image/filogic.mk"
NEW_BLOCK="target/linux/mediatek/image/filogic_ax6000_ubootmod.mk"

start_line=$(grep -nF "define Device/xiaomi_redmi-router-ax6000-ubootmod" "$TARGET_FILE" | cut -d: -f1)
end_line=$(grep -nF "TARGET_DEVICES += xiaomi_redmi-router-ax6000-ubootmod" "$TARGET_FILE" | cut -d: -f1)

if [ -n "$start_line" ] && [ -n "$end_line" ]; then
    # 先删除旧代码块，然后在原起始位置读入新文件内容
    # 注意：在 Linux 上直接用 -i，在 macOS 上需用 -i ''
    sed -i "${start_line},${end_line}d" "$TARGET_FILE"
    sed -i "${start_line}r $NEW_BLOCK" "$TARGET_FILE"
    echo "替换完成！"
else
    echo "错误：未能在文件中找到指定的开始或结束标记。"
fi

cp -f target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts immortalwrt/target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts

cp defconfig/mt7986a-ax6000-ubootmod.config immortalwrt/.config