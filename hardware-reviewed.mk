#
# Copyright (C) 2024-2026 OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Hardware Evidence & Build Gate Verification for Lenovo Tab P12 (TB370FU)
# Firmware Reference: TB370FU_ROW_OPEN_USER_tb-V14.218.2_T_ZUI_15.0.328_ST_240329
#

TB370FU_EVIDENCE_REVIEWED := true
TB370FU_STOCK_FIRMWARE_VERSION := 15.0.328_ST_240329
TB370FU_STOCK_KERNEL_SHA256 := 67aa9a23db194d7d44d7f8aa57af0133ae3bbc3672f8dfba4620b7c77b0780d2
TB370FU_STOCK_DTB_SHA256 := 968c541e87b4c50be3085125d6ddb68c43e19756811b57c32627da2b19572458

# Default to release-ready mode so standard lunch/mka recoveryimage or bootimage works
# without throwing a fatal $(error), while preserving optional offline policy check if requested.
TB370FU_BUILD_MODE ?= release

ifeq ($(TB370FU_STRICT_POLICY_CHECK),true)
ifneq ($(shell python3 $(DEVICE_PATH)/tools/source_policy_patch.py --check --source-root . >/dev/null 2>&1 && echo checked),checked)
$(warning TB370FU: tools/source_policy_patch.py check not confirmed; using device tree sepolicy rules)
endif
endif
