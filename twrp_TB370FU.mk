#
# Copyright (C) 2024-2026 The Android Open Source Project
# Copyright (C) 2024-2026 The TWRP Open Source Project
# Copyright (C) 2024-2026 OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from 64-bit core and AOSP base configurations
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

# Inherit from TWRP / OrangeFox common configuration
$(call inherit-product, vendor/twrp/config/common.mk)

# Inherit from Lenovo TB370FU device configuration
$(call inherit-product, device/lenovo/TB370FU/device.mk)

# Product Identifiers (matched to stock prop.default & build.prop)
PRODUCT_DEVICE := TB370FU
PRODUCT_NAME := twrp_TB370FU
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB370FU
PRODUCT_MANUFACTURER := LENOVO
PRODUCT_GMS_CLIENTID_BASE := android-lenovo
