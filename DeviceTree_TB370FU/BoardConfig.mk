#
# Copyright (C) 2024-2026 The Android Open Source Project
# Copyright (C) 2024-2026 OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#
# BoardConfig.mk for Lenovo Tab P12 (TB370FU / spruce_row_wifi)
# 100% Grounded in stock_boot_preserved/boot_header.json, scatter_partitions.json,
# firmware_analysis.json, and kernel.config (15.0.328_ST_240329).
#

DEVICE_PATH := device/lenovo/TB370FU

# ============================================================================
# 1. Architecture & Platform (mt6877 / mt8791 Dimensity 7050)
# ============================================================================
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_BOARD_PLATFORM := mt6877
TARGET_BOOTLOADER_BOARD_NAME := spruce_row_wifi
TARGET_NO_BOOTLOADER := true
ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# ============================================================================
# 2. Boot Image Header, Offsets, Cmdline & OS Version (100% Match to Stock)
# Reference: boot_extraction_info/stock_boot_preserved/boot_header.json
#   header_version: 2
#   header_size: 1660
#   page_size: 2048
#   kernel_address: 0x40080000
#   ramdisk_address: 0x51100000
#   tags_address: 0x47c80000
#   dtb_address: 0x47c80000
#   os_version_packed: 402653571 (OS=12.0.0, Security Patch=2024-03)
#   cmdline: "bootopt=64S3,32N2,64N2 buildvariant=user"
# ============================================================================
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_OFFSET := 0x40080000
BOARD_RAMDISK_OFFSET := 0x51100000
BOARD_KERNEL_SECOND_OFFSET := 0x00000000
BOARD_KERNEL_TAGS_OFFSET := 0x47c80000
BOARD_DTB_OFFSET := 0x47c80000

# OS Version & Security Patch Level locked to stock boot_header.json (402653571)
PLATFORM_VERSION := 12.0.0
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2024-03-05
VENDOR_SECURITY_PATCH := 2024-03-05
BOOT_SECURITY_PATCH := 2024-03-05

# Kernel Prebuilt & DTB
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel.gz
BOARD_KERNEL_IMAGE_NAME := Image.gz
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb

# Kernel Command Line
# Stock cmdline is: bootopt=64S3,32N2,64N2 buildvariant=user
# Note: AOSP build system automatically appends buildvariant=$(TARGET_BUILD_VARIANT)
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2

BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --second_offset $(BOARD_KERNEL_SECOND_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --os_version $(PLATFORM_VERSION)
BOARD_MKBOOTIMG_ARGS += --os_patch_level $(PLATFORM_SECURITY_PATCH)

# Kernel only enables CONFIG_RD_GZIP=y (LZ4/LZMA/XZ/BZIP2/LZO are NOT set in kernel.config)
BOARD_RAMDISK_USE_LZ4 := false
BOARD_RAMDISK_USE_XZ := false

# ============================================================================
# 3. Partition Sizes & Dynamic Partitions (100% Match to scatter_partitions.json)
#   boot_a / boot_b: 0x2800000 = 41943040 bytes (40 MB)
#   dtbo_a / dtbo_b: 0x800000  = 8388608 bytes (8 MB)
#   super:           0x2c0000000 = 11811160064 bytes (11264 MB)
#   metadata:        0x2000000 = 33554432 bytes (32 MB)
#   userdata:        0xc0000000 = 3221225472 bytes (3072 MB image in scatter)
# ============================================================================
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 41943040
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_METADATAIMAGE_PARTITION_SIZE := 33554432
BOARD_USERDATAIMAGE_PARTITION_SIZE := 3221225472

# A/B & Recovery-as-Boot Configuration
BOARD_USES_RECOVERY_AS_BOOT := true
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    system \
    vendor \
    product \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor

# Super / Dynamic Partitions
BOARD_SUPER_PARTITION_SIZE := 11811160064
BOARD_SUPER_PARTITION_GROUPS := lenovo_dynamic_partitions
BOARD_LENOVO_DYNAMIC_PARTITIONS_SIZE := 11806965760
BOARD_LENOVO_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    vendor \
    product

# Filesystem Types (verified from stock fstab.mt6877)
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# ============================================================================
# 4. Android Verified Boot (AVB 2.0)
# Reference: BUILD_GATES.json & scatter_partitions.json
# ============================================================================
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA2048
BOARD_AVB_BOOT_ROLLBACK_INDEX := 0
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3

BOARD_AVB_VBMETA_SYSTEM := system product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_VENDOR := vendor
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 2

# ============================================================================
# 5. Recovery FSTAB, Root Staging & First-Stage Ramdisk Preparation
# ============================================================================
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_DEVICE_DIRS += $(DEVICE_PATH)

# Ensure executable permissions on OrangeFox /sbin scripts, /FFiles/ps,
# legacy /sbin/linker64 symlink, and first_stage_ramdisk mountpoints & fstabs
BOARD_RECOVERY_IMAGE_PREPARE := \
    mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/sbin $(TARGET_RECOVERY_ROOT_OUT)/first_stage_ramdisk/system/bin $(TARGET_RECOVERY_ROOT_OUT)/metadata $(TARGET_RECOVERY_ROOT_OUT)/lenovocust $(TARGET_RECOVERY_ROOT_OUT)/lib/modules; \
    ln -sf /system/bin/linker64 $(TARGET_RECOVERY_ROOT_OUT)/sbin/linker64; \
    if [ -f $(TARGET_RECOVERY_ROOT_OUT)/system/bin/snapuserd ]; then cp -f $(TARGET_RECOVERY_ROOT_OUT)/system/bin/snapuserd $(TARGET_RECOVERY_ROOT_OUT)/first_stage_ramdisk/system/bin/snapuserd && chmod 0755 $(TARGET_RECOVERY_ROOT_OUT)/first_stage_ramdisk/system/bin/snapuserd; fi; \
    if [ -d $(TARGET_RECOVERY_ROOT_OUT)/sbin ]; then find $(TARGET_RECOVERY_ROOT_OUT)/sbin -type f -exec chmod 0755 {} +; fi; \
    if [ -f $(TARGET_RECOVERY_ROOT_OUT)/FFiles/ps ]; then chmod 0755 $(TARGET_RECOVERY_ROOT_OUT)/FFiles/ps; fi; \
    if [ -f $(TARGET_RECOVERY_ROOT_OUT)/FFiles/fox_fix_date ]; then chmod 0755 $(TARGET_RECOVERY_ROOT_OUT)/FFiles/fox_fix_date; fi; \
    if [ -f $(TARGET_RECOVERY_ROOT_OUT)/FFiles/OF_avb20/OF_avb20.sh ]; then chmod 0755 $(TARGET_RECOVERY_ROOT_OUT)/FFiles/OF_avb20/OF_avb20.sh; fi; \
    if [ -f $(TARGET_RECOVERY_ROOT_OUT)/FFiles/OF_Dynamic/dynamic-partition-functions.sh ]; then chmod 0755 $(TARGET_RECOVERY_ROOT_OUT)/FFiles/OF_Dynamic/dynamic-partition-functions.sh; fi

# ============================================================================
# 6. Display, Touch & Graphics Configuration (Lenovo Tab P12 12.7" 2944x1840)
# Reference: stock kernel.config (CONFIG_LCM_WIDTH="2944", CONFIG_LCM_HEIGHT="1840")
# and stock vendor/build.prop (ro.minui.pixel_format=RGBX_8888, ORIENTATION_270)
# ============================================================================
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TW_THEME := portrait_hdpi
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 160
TW_NO_HAPTICS := true
TW_SUPPORT_INPUT_1_2_HAPTICS := false

# ============================================================================
# 7. USB, Fastbootd, Logging, SELinux & Crypto Configuration
# ============================================================================
TW_INCLUDE_FASTBOOTD := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_SKIP_ADDITIONAL_FSTAB := false
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true

# Microtrust (Beanpod) TEE FBE v2 decryption is kept disabled in recovery by default
# to prevent hang on startup if TEE daemon is not active; FBE flags remain in fstab
# for accurate partition management and formatting.
TW_INCLUDE_CRYPTO :=
TW_INCLUDE_CRYPTO_FBE :=

# Required shared libraries for upstream recovery binary relinking
TW_RECOVERY_ADDITIONAL_RELINK_LIBRARY_FILES += \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.security.apc-ndk_platform.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.system.keystore2-V1-ndk_platform.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libkeymint_support.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/libopenaes.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.keymint-V1-ndk_platform.so \
    $(TARGET_OUT_SHARED_LIBRARIES)/android.hardware.security.secureclock-V1-ndk_platform.so

# SELinux Configuration
BOARD_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy
BOARD_SEPOLICY_M4DEFS += tb370fu_enforcing=1

# Include OrangeFox and Hardware Verification Makefiles
include $(DEVICE_PATH)/orangefox.mk
include $(DEVICE_PATH)/hardware-reviewed.mk
