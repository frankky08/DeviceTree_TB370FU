#!/bin/bash
#
# Copyright (C) 2024-2026 OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

FDEVICE="TB370FU"

fox_get_target_device() {
    local chkdev=$(echo "$BASH_SOURCE" | grep -w "$FDEVICE")
    if [ -n "$chkdev" ]; then
        FOX_BUILD_DEVICE="$FDEVICE"
    else
        chkdev=$(set | grep BASH_ARGV | grep -w "$FDEVICE")
        [ -n "$chkdev" ] && FOX_BUILD_DEVICE="$FDEVICE"
    fi
}

if [ -z "$1" -a -z "$FOX_BUILD_DEVICE" ]; then
    fox_get_target_device
fi

if [ "$1" = "$FDEVICE" -o "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
    export FOX_BUILD_DEVICE="TB370FU"
    export FOX_BUILD_TYPE="Unofficial"
    export FOX_VARIANT="TB370FU_A12"
    export OF_MAINTAINER="SeniorRecoveryArchitect"

    # A/B & Virtual A/B Dynamic Partitions
    export FOX_AB_DEVICE=1
    export FOX_VIRTUAL_AB_DEVICE=1
    export FOX_RECOVERY_BOOT_PARTITION="/dev/block/by-name/boot"
    export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
    export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"
    export TARGET_DEVICE_ALT="TB370FU,spruce,spruce_row_wifi,mt6877,mt8791"

    # Tablet Display Geometry (12.7-inch 2944x1840 16:10 aspect ratio)
    export OF_SCREEN_H=1728
    export OF_STATUS_H=60
    export OF_STATUS_INDENT_LEFT=48
    export OF_STATUS_INDENT_RIGHT=48
    export OF_HIDE_NOTCH=1
    export OF_CLOCK_POS=1
    export OF_ALLOW_DISABLE_NAVBAR=0
    export OF_USE_GREEN_LED=0
    export OF_FLASHLIGHT_ENABLE=0

    # AVB 2.0, DM-Verity & FBE Safety Settings
    export OF_DISABLE_MIUI_SPECIFIC_FEATURES=1
    export OF_SKIP_FBE_DECRYPTION=1
    export OF_PATCH_AVB20=0
    export OF_KEEP_DM_VERITY_FORCED_ENCRYPTION=1
    export OF_KEEP_DM_VERITY=1
    export OF_KEEP_FORCED_ENCRYPTION=1
    export OF_DONT_PATCH_ENCRYPTED_DEVICE=1
    export OF_DONT_PATCH_ON_FRESH_INSTALLATION=1
    export OF_NO_REFLASH_CURRENT_ORANGEFOX=1
    export OF_NO_SPLASH_CHANGE=1

    # OrangeFox Tools & Environment
    export OF_USE_MAGISKBOOT=1
    export OF_USE_MAGISKBOOT_FOR_ALL_PATCHES=1
    export OF_ENABLE_LPTOOLS=1
    export FOX_USE_BASH_SHELL=1
    export FOX_ASH_IS_BASH=1
    export FOX_USE_TAR_BINARY=1
    export FOX_USE_SED_BINARY=1
    export FOX_USE_XZ_UTILS=1
    export FOX_USE_GREP_BINARY=1
    export FOX_EXCLUDE_NANO_EDITOR=1
    export OF_SKIP_ORANGEFOX_PROCESS=0
    export FOX_SETTINGS_ROOT_DIRECTORY="/tmp/OrangeFox"
    export FOX_MISCELLANEOUS_ROOT_DIRECTORY="/tmp/OrangeFox"
fi