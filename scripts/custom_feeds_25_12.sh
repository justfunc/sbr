#!/bin/bash


# Add a feed source
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
rm -rf package/luci-theme-argon
git clone --depth 1 --single-branch https://github.com/sbwml/luci-theme-argon package/luci-theme-argon
rm -rf package/luci-theme-aurora
git clone --depth 1 --single-branch https://github.com/eamonxg/luci-theme-aurora package/luci-theme-aurora
rm -rf package/luci-app-aurora-config
git clone --depth 1 --single-branch https://github.com/eamonxg/luci-app-aurora-config package/luci-app-aurora-config
rm -rf package/luci-theme-orion
git clone --depth 1 --single-branch https://github.com/CoolLoong/luci-theme-orion package/luci-theme-orion

# 常用工具与应用
rm -rf package/netspeedtest
git clone --depth=1 https://github.com/sirpdboy/netspeedtest package/netspeedtest  #homebox speedtest测速
rm -rf package/luci-app-poweroffdevice
git clone --depth=1 https://github.com/sirpdboy/luci-app-poweroffdevice package/luci-app-poweroffdevice   #关机
rm -rf package/luci-app-taskplan
git clone --depth=1 https://github.com/sirpdboy/luci-app-taskplan package/luci-app-taskplan    #计划任务
rm -rf package/luci-app-advancedplus
git clone --depth=1 https://github.com/sirpdboy/luci-app-advancedplus package/luci-app-advancedplus  #高级设置
rm -rf package/luci-app-authshield 
git clone --depth=1 https://github.com/iv7777/luci-app-authshield package/luci-app-authshield  #防止异常登录保护
rm -rf package/luci-app-timewol
git clone --depth=1 https://github.com/VIKINGYFY/packages package/luci-app-timewol
rm -rf package/luci-app-wolplus
git clone --depth=1 https://github.com/VIKINGYFY/packages package/luci-app-wolplus
rm -rf package/luci-app-owq-wol
git clone --depth=1 https://github.com/isalikai/luci-app-owq-wol package/luci-app-owq-wol  # wol加强版