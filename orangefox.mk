#
# Copyright (C) 2024-2026 OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#
# OrangeFox Configuration for Lenovo Tab P12 (TB370FU)
# Display: 12.7-inch LTPS LCD (2944x1840, 16:10 aspect ratio, 340 dpi)
# Architecture: MediaTek Dimensity 7050 (mt6877 / mt8791), A/B + Virtual A/B
#

# Build Identity
FOX_BUILD_TYPE := Unofficial
FOX_VARIANT := TB370FU_A12
OF_MAINTAINER := SeniorRecoveryArchitect

# A/B & Dynamic Partition Architecture (Recovery-as-Boot, Header v2, No vendor_boot)
FOX_AB_DEVICE := 1
FOX_VIRTUAL_AB_DEVICE := 1
FOX_RECOVERY_BOOT_PARTITION := /dev/block/by-name/boot
FOX_RECOVERY_SYSTEM_PARTITION := /dev/block/mapper/system
FOX_RECOVERY_VENDOR_PARTITION := /dev/block/mapper/vendor

# Device Hardware & Target Alternates (Dual Hardware Codename Support)
TARGET_DEVICE_ALT := TB370FU,spruce,spruce_row_wifi,mt6877,mt8791

# Tablet Display & UI Geometry (12.7" 1840x2944 / 2944x1840 = 16:10 ratio)
# In TWRP/OrangeFox portrait_hdpi (base width 1080), 16:10 corresponds to 1728 vertical units
OF_SCREEN_H := 1728
OF_STATUS_H := 60
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
OF_HIDE_NOTCH := 1
OF_CLOCK_POS := 1
OF_ALLOW_DISABLE_NAVBAR := 0
OF_USE_GREEN_LED := 0
OF_FLASHLIGHT_ENABLE := 0

# Encryption, AVB & DM-Verity Handling (Safe defaults for Stock ZUI 15 + Beanpod TEE)
OF_SKIP_FBE_DECRYPTION := 1
OF_PATCH_AVB20 := 0
OF_KEEP_DM_VERITY_FORCED_ENCRYPTION := 1
OF_KEEP_DM_VERITY := 1
OF_KEEP_FORCED_ENCRYPTION := 1
OF_DONT_PATCH_ENCRYPTED_DEVICE := 1
OF_DONT_PATCH_ON_FRESH_INSTALLATION := 1
OF_NO_REFLASH_CURRENT_ORANGEFOX := 1
OF_NO_SPLASH_CHANGE := 1
OF_DISABLE_MIUI_SPECIFIC_FEATURES := 1

# Boot & Ramdisk Binary Controls
OF_USE_MAGISKBOOT := 1
OF_USE_MAGISKBOOT_FOR_ALL_PATCHES := 1
OF_ENABLE_LPTOOLS := 1
FOX_USE_BASH_SHELL := 1
FOX_ASH_IS_BASH := 1
FOX_USE_TAR_BINARY := 1
FOX_USE_SED_BINARY := 1
FOX_USE_XZ_UTILS := 1
FOX_USE_GREP_BINARY := 1
FOX_EXCLUDE_NANO_EDITOR := 1

# Keep OrangeFox post-init scripts active and store transient settings in /tmp/OrangeFox
# when /data is encrypted/unmounted so foxstart.sh never blocks UI startup
OF_SKIP_ORANGEFOX_PROCESS := 0
FOX_SETTINGS_ROOT_DIRECTORY := /tmp/OrangeFox
FOX_MISCELLANEOUS_ROOT_DIRECTORY := /tmp/OrangeFox
