#
# Copyright (C) 2024-2026 The Android Open Source Project
# Copyright (C) 2024-2026 OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/lenovo/TB370FU

# Dynamic Partitions & Virtual A/B (verified from stock prop.default & vendor/build.prop)
PRODUCT_USE_DYNAMIC_PARTITIONS := true
 $(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# Recovery-only product: do not build full system/vendor/product filesystem images
PRODUCT_BUILD_SUPER_PARTITION := false
PRODUCT_BUILD_SYSTEM_IMAGE := false
PRODUCT_BUILD_SYSTEM_EXT_IMAGE := false
PRODUCT_BUILD_VENDOR_IMAGE := false
PRODUCT_BUILD_PRODUCT_IMAGE := false
PRODUCT_BUILD_ODM_IMAGE := false
PRODUCT_BUILD_VENDOR_DLKM_IMAGE := false
PRODUCT_BUILD_ODM_DLKM_IMAGE := false

# Shipping API Level (verified from stock ro.product.first_api_level=31 / ro.board.api_level=30)
PRODUCT_SHIPPING_API_LEVEL := 31
PRODUCT_TARGET_VNDK_VERSION := 31

# A/B OTA & Boot Control HALs + Fastbootd + Snapuserd
PRODUCT_PACKAGES += \
    fastbootd \
    snapuserd \
    bootctrl.mt6877 \
    bootctrl.mt6877.recovery \
    bootctrl.mt8791 \
    bootctrl.mt8791.recovery \
    android.hardware.boot@1.0-impl-1.2-mtkimpl \
    android.hardware.boot@1.0-impl-1.2-mtkimpl.recovery \
    android.hardware.boot@1.0-service \
    android.hardware.boot@1.1-service \
    android.hardware.boot@1.2-service \
    android.hardware.fastboot@1.0-impl-mtk \
    android.hardware.fastboot@1.1-impl-mtk \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service \
    mtk_plpath_utils \
    mtk_plpath_utils.recovery

# Recovery UI & Platform Properties (matched to stock prop.default & vendor/build.prop)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.minui.pixel_format=RGBX_8888 \
    ro.sf.lcd_density=340 \
    ro.surface_flinger.primary_display_orientation=ORIENTATION_270 \
    ro.boot.dynamic_partitions=true \
    ro.build.ab_update=true \
    ro.virtual_ab.enabled=true \
    ro.virtual_ab.compression.enabled=true \
    ro.virtual_ab.userspace.snapshots.enabled=true \
    ro.vendor.mediatek.platform=MT6877 \
    ro.board.platform=mt6877 \
    ro.product.board=spruce_row_wifi \
    ro.hardware.kmsetkey=beanpod \
    ro.hardware.gatekeeper=beanpod \
    ro.vendor.mtk_microtrust_tee_support=1 \
    ro.vendor.mtk_ufs_support=1 \
    ro.vendor.mtk_emmc_support=1 \
    ro.vendor.mtk_f2fs_enable=1 \
    ro.crypto.volume.filenames_mode=aes-256-cts

PRODUCT_VENDOR_PROPERTIES += \
    ro.minui.pixel_format=RGBX_8888 \
    ro.sf.lcd_density=340 \
    ro.surface_flinger.primary_display_orientation=ORIENTATION_270

# First-Stage Ramdisk fstab & Multi-Hardware Architecture Support (mt6877 / mt8791 / mt8791dm / emmc)
# Copies exact stock first_stage_ramdisk fstabs into both /first_stage_ramdisk and /system/etc
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt6877:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt6877 \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt8791:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt8791 \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt6877dm:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt6877dm \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt8791dm:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt8791dm \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.emmc:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.emmc \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt6877:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/fstab.mt6877 \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt8791:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/fstab.mt8791 \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt6877dm:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/fstab.mt6877dm \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt8791dm:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/fstab.mt8791dm \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.emmc:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/fstab.emmc

# Novatek NT36532 Host-Download SPI Touchscreen Firmware (CONFIG_TOUCHSCREEN_NT36xxx_HOSTDL_SPI=y)
# Staged to both /vendor/firmware and /lib/firmware so kernel firmware_class resolves immediately
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_boe_fw.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/novatek_ts_boe_fw.bin \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_boe_mp.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/novatek_ts_boe_mp.bin \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_tianma_fw.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/novatek_ts_tianma_fw.bin \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_tianma_mp.bin:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/firmware/novatek_ts_tianma_mp.bin \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_boe_fw.bin:$(TARGET_COPY_OUT_RECOVERY)/root/lib/firmware/novatek_ts_boe_fw.bin \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_boe_mp.bin:$(TARGET_COPY_OUT_RECOVERY)/root/lib/firmware/novatek_ts_boe_mp.bin \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_tianma_fw.bin:$(TARGET_COPY_OUT_RECOVERY)/root/lib/firmware/novatek_ts_tianma_fw.bin \
    $(LOCAL_PATH)/prebuilt/firmware/novatek_ts_tianma_mp.bin:$(TARGET_COPY_OUT_RECOVERY)/root/lib/firmware/novatek_ts_tianma_mp.bin
