define Device/xiaomi_redmi-router-ax6000-ubootmod
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Redmi Router AX6000
  DEVICE_VARIANT := (OpenWrt U-Boot layout)
  DEVICE_DTS := mt7986a-xiaomi-redmi-router-ax6000-ubootmod
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-leds-ws2812b kmod-mt7915e kmod-mt7986-firmware mt7986-wo-firmware
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.itb
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  UBOOTENV_IN_UBI := 1
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  IMAGE/sysupgrade.itb := append-kernel | \
        fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | append-metadata
  ARTIFACTS := preloader.bin bl31-uboot.fip
  ARTIFACT/preloader.bin := mt7986-bl2 spim-nand-ddr4
  ARTIFACT/bl31-uboot.fip := mt7986-bl31-uboot xiaomi_redmi-router-ax6000
ifeq ($(IB),)
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
  ARTIFACTS += initramfs-factory.ubi
  ARTIFACT/initramfs-factory.ubi := append-image-stage initramfs-recovery.itb | ubinize-kernel
endif
endif
endef
TARGET_DEVICES += xiaomi_redmi-router-ax6000-ubootmod