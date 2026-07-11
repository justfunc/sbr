#!/bin/bash

echo "=========================================="
echo "执行自定义优化脚本 (cust_init_settings.sh)"
echo "=========================================="


# Modify default IP
sed -i 's/192.168.6.1/192.168.1.254/g' package/base-files/files/bin/config_generate

# Modify hostname
sed -i 's/ImmortalWrt/Gwrt/g' package/base-files/files/bin/config_generate

# Modify default theme
# sed -i 's/luci-theme-bootstrap/luci-theme-aurora/g' feeds/luci/collections/luci/Makefile

# add date in output file name
# sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d%H%M%S)' \
#        -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-24-10-$(BUILD_DATE)/' include/image.mk

# banner中加入构建时间
echo -e "\n Build By Justfunc At $WRT_DATE" >> package/base-files/files/etc/banner
echo " -----------------------------------------------------" >> package/base-files/files/etc/banner
echo "export LANG=en_US.UTF-8" >> package/base-files/files/etc/profile
echo "export LC_CTYPE=en_US.UTF-8" >> package/base-files/files/etc/profile

#添加编译日期标识
sed -i "s/\(_('Kernel Version'), *boardinfo.kernel\)/\1 + ' (Build By Justfunc At $WRT_DATE)'/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ gwrt-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
