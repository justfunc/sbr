#!/bin/bash

echo "=========================================="
echo "执行自定义优化脚本 (cust_init_settings.sh)"
echo "=========================================="


# Modify default IP
sed -i 's/192.168.6.1/192.168.1.254/g' package/base-files/files/bin/config_generate

# Modify hostname
sed -i 's/ImmortalWrt/gwrt/g' package/base-files/files/bin/config_generate

# Modify default theme
# sed -i 's/luci-theme-bootstrap/luci-theme-aurora/g' feeds/luci/collections/luci/Makefile

# add date in output file name
sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d%H%M%S)' \
       -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-24-10-$(BUILD_DATE)/' include/image.mk

# 获取当前北京时间 (UTC+8)
BUILD_DATE=$(date -u -d "+8 hours" "+%Y-%m-%d %H:%M:%S")
# banner中加入构建时间
echo "" >> package/base-files/files/etc/banner
echo "  Build By Justfunc At $BUILD_DATE" >> package/base-files/files/etc/banner
echo " -----------------------------------------------------" >> package/base-files/files/etc/banner

#添加编译日期标识
sed -i "s/\(_('Kernel Version'), *boardinfo.kernel\)/\1 + ' (Build By Justfunc At $BUILD_DATE)'/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ gwrt-$BUILD_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

# ---------------------------------------------------------
# libxcrypt 专项救治 (极致精简版)
# ---------------------------------------------------------
XCRYPT_MK="feeds/packages/libs/libxcrypt/Makefile"
if [ -f "$XCRYPT_MK" ]; then
    echo ">>> 正在硬化 libxcrypt 编译参数..."
    
    # 1. 强制禁用 werror (兼容多种等号写法)
    # 作用：防止编译器因为一些琐碎的警告而罢工
    sed -i 's/CONFIGURE_ARGS[ \t]*+=[ \t]*/&--disable-werror /' "$XCRYPT_MK"

    # 2. 注入 -fcommon (核心修复)
    # 作用：解决 gen-des-tables.o 报错的真凶（允许多重定义变量）
    # 使用 TARGET_CFLAGS 注入，如果还报 host 错，我们会同时注入给 HOST_CFLAGS
    sed -i 's/TARGET_CFLAGS[ \t]*+=[ \t]*/&-fcommon /' "$XCRYPT_MK"
    
    # 3. 额外保险：针对宿主机编译工具的补丁
    # 因为 gen-des-tables 是在你的电脑上跑的，有时候需要这一行
    # sed -i 's/HOST_CFLAGS[ \t]*+=[ \t]*/&-fcommon /' "$XCRYPT_MK" 2>/dev/null || true

    echo "✅ libxcrypt 参数注入完成。"
fi

#修复Rust编译失败
RUST_FILE=$(find feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
echo "pwd- $(pwd)"
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi