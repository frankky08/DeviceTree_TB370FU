#!/usr/bin/env python3
"""
Post-Build Verification Gate for Lenovo Tab P12 (TB370FU) OrangeFox / TWRP Recovery
===================================================================================
Validates either:
  1. A built raw `boot.img` / `recovery.img` binary (Android Boot Image Header v2 + GZIP CPIO ramdisk), OR
  2. An unpacked extraction directory containing `boot_header.json` and `ramdisk_manifest.json`, OR
  3. A Device Tree directory (`device/lenovo/TB370FU`) prior to/after compilation.

Usage:
  python3 verify_recovery_image.py --image /path/to/boot.img
  python3 verify_recovery_image.py --extracted-dir /path/to/unpacked_info
  python3 verify_recovery_image.py --device-tree /path/to/device/lenovo/TB370FU
"""

import argparse
import gzip
import hashlib
import io
import json
import os
import pathlib
import struct
import sys
from typing import Dict, List, Optional, Tuple

# ============================================================================
# Ground-Truth Constants from stock_boot_preserved/boot_header.json & scatter
# ============================================================================
EXPECTED_BOOT_MAGIC = b"ANDROID!"
EXPECTED_HEADER_VERSION = 2
EXPECTED_HEADER_SIZE = 1660
EXPECTED_PAGE_SIZE = 2048
EXPECTED_KERNEL_ADDR = 0x40080000
EXPECTED_RAMDISK_ADDR = 0x51100000
EXPECTED_SECOND_ADDR = 0x00000000
EXPECTED_TAGS_ADDR = 0x47C80000
EXPECTED_DTB_ADDR = 0x47C80000
EXPECTED_OS_VERSION_PACKED = 402653571  # OS 12.0.0, Patch 2024-03 (0x18000183)
EXPECTED_CMDLINE_PREFIX = "bootopt=64S3,32N2,64N2"
EXPECTED_PARTITION_SIZE = 41943040      # 0x2800000 (40 MB)
EXPECTED_SUPER_SIZE = 11811160064       # 0x2c0000000 (11264 MB)

EXPECTED_KERNEL_SIZE = 11875675
EXPECTED_KERNEL_SHA256 = "67aa9a23db194d7d44d7f8aa57af0133ae3bbc3672f8dfba4620b7c77b0780d2"
EXPECTED_DTB_SIZE = 180143
EXPECTED_DTB_SHA256 = "968c541e87b4c50be3085125d6ddb68c43e19756811b57c32627da2b19572458"

REQUIRED_RAMDISK_FILES = [
    "init",
    "system/bin/init",
    "system/bin/recovery",
    "first_stage_ramdisk/fstab.mt6877",
    "first_stage_ramdisk/fstab.mt8791",
    "first_stage_ramdisk/fstab.emmc",
    "system/etc/recovery.fstab",
    "init.recovery.mt6877.rc",
    "init.recovery.mt8791.rc",
    "vendor/firmware/novatek_ts_boe_fw.bin",
    "vendor/firmware/novatek_ts_boe_mp.bin",
    "vendor/firmware/novatek_ts_tianma_fw.bin",
    "vendor/firmware/novatek_ts_tianma_mp.bin",
    "sepolicy",
]

CRITICAL_EXECUTABLE_PATHS = [
    "system/bin/init",
    "system/bin/recovery",
    "sbin/bash",
    "sbin/foxstart.sh",
    "sbin/magiskboot",
    "FFiles/ps",
]


def decode_os_version(packed: int) -> Tuple[str, str]:
    os_ver = packed >> 11
    a = (os_ver >> 14) & 0x7F
    b = (os_ver >> 7) & 0x7F
    c = os_ver & 0x7F
    os_patch = packed & 0x7FF
    y = (os_patch >> 4) + 2000
    m = os_patch & 0xF
    return f"{a}.{b}.{c}", f"{y:04d}-{m:02d}"


def align_up(value: int, page_size: int) -> int:
    return ((value + page_size - 1) // page_size) * page_size


def parse_boot_image_v2(data: bytes) -> Dict:
    if len(data) < 2048 or data[:8] != EXPECTED_BOOT_MAGIC:
        raise ValueError("Invalid Android boot image magic (expected 'ANDROID!')")

    # Boot Header v0/v1/v2 base fields:
    # magic(8s), kernel_size(I), kernel_addr(I), ramdisk_size(I), ramdisk_addr(I),
    # second_size(I), second_addr(I), tags_addr(I), page_size(I), header_version(I),
    # os_version(I), name(16s), cmdline(512s), id(32s), extra_cmdline(1024s)
    base_fmt = "<8s10I16s512s32s1024s"
    base_size = struct.calcsize(base_fmt)
    fields = struct.unpack_from(base_fmt, data, 0)

    magic = fields[0]
    kernel_size = fields[1]
    kernel_addr = fields[2]
    ramdisk_size = fields[3]
    ramdisk_addr = fields[4]
    second_size = fields[5]
    second_addr = fields[6]
    tags_addr = fields[7]
    page_size = fields[8]
    header_version = fields[9]
    os_version_packed = fields[10]
    board_name = fields[11].split(b"\x00", 1)[0].decode("utf-8", errors="replace")
    cmdline_part1 = fields[12].split(b"\x00", 1)[0].decode("utf-8", errors="replace")
    extra_cmdline = fields[14].split(b"\x00", 1)[0].decode("utf-8", errors="replace")
    full_cmdline = cmdline_part1 + extra_cmdline

    # v1 extension: recovery_dtbo_size(I), recovery_dtbo_offset(Q), header_size(I)
    v1_fmt = "<IQI"
    rec_dtbo_size, rec_dtbo_offset, header_size = struct.unpack_from(v1_fmt, data, base_size)

    # v2 extension: dtb_size(I), dtb_addr(Q)
    v2_fmt = "<IQ"
    dtb_size, dtb_addr = struct.unpack_from(v2_fmt, data, base_size + struct.calcsize(v1_fmt))

    kernel_offset = page_size
    ramdisk_offset = kernel_offset + align_up(kernel_size, page_size)
    second_offset = ramdisk_offset + align_up(ramdisk_size, page_size)
    rec_dtbo_calc_offset = second_offset + align_up(second_size, page_size)
    dtb_offset = rec_dtbo_calc_offset + align_up(rec_dtbo_size, page_size)

    kernel_bytes = data[kernel_offset : kernel_offset + kernel_size]
    ramdisk_bytes = data[ramdisk_offset : ramdisk_offset + ramdisk_size]
    dtb_bytes = data[dtb_offset : dtb_offset + dtb_size]

    return {
        "image_size": len(data),
        "header_version": header_version,
        "header_size": header_size,
        "page_size": page_size,
        "kernel_address": f"0x{kernel_addr:08x}",
        "ramdisk_address": f"0x{ramdisk_addr:08x}",
        "second_address": f"0x{second_addr:08x}",
        "tags_address": f"0x{tags_addr:08x}",
        "dtb_address": f"0x{dtb_addr:08x}",
        "os_version_packed": os_version_packed,
        "board_name": board_name,
        "cmdline": full_cmdline,
        "components": {
            "kernel.gz": {
                "offset": kernel_offset,
                "size": kernel_size,
                "sha256": hashlib.sha256(kernel_bytes).hexdigest(),
            },
            "ramdisk.gz": {
                "offset": ramdisk_offset,
                "size": ramdisk_size,
                "sha256": hashlib.sha256(ramdisk_bytes).hexdigest(),
                "magic": ramdisk_bytes[:4].hex(),
                "raw_bytes": ramdisk_bytes,
            },
            "dtb.img": {
                "offset": dtb_offset,
                "size": dtb_size,
                "sha256": hashlib.sha256(dtb_bytes).hexdigest(),
            },
        },
    }


def parse_cpio_newc(cpio_data: bytes) -> List[Dict]:
    entries = []
    offset = 0
    total_len = len(cpio_data)
    while offset + 110 <= total_len:
        magic = cpio_data[offset : offset + 6]
        if magic not in (b"070701", b"070702"):
            break
        hdr = cpio_data[offset : offset + 110].decode("ascii", errors="replace")
        mode = int(hdr[14:22], 16)
        filesize = int(hdr[54:62], 16)
        namesize = int(hdr[94:102], 16)

        name_start = offset + 110
        name_end = name_start + namesize
        name = cpio_data[name_start : name_end - 1].decode("utf-8", errors="replace")
        if name == "TRAILER!!!":
            break

        # Pad to 4-byte boundary after header + name
        data_start = ((name_end + 3) // 4) * 4
        data_end = data_start + filesize
        file_bytes = cpio_data[data_start:data_end]

        entry = {
            "name": name.lstrip("./"),
            "size": filesize,
            "mode": f"0o{mode:o}",
            "sha256": hashlib.sha256(file_bytes).hexdigest(),
        }
        if (mode & 0o170000) == 0o120000:
            entry["symlink_target"] = file_bytes.decode("utf-8", errors="replace")
        entries.append(entry)

        offset = ((data_end + 3) // 4) * 4
    return entries


def verify_header_and_manifest(header: Dict, manifest: List[Dict], image_size: Optional[int] = None) -> Tuple[List[str], List[str], List[str]]:
    passed = []
    warnings = []
    errors = []

    # 1. Image size check
    if image_size is not None:
        if image_size <= EXPECTED_PARTITION_SIZE:
            passed.append(f"Image size ({image_size} bytes) fits within boot partition ({EXPECTED_PARTITION_SIZE} bytes)")
        else:
            errors.append(f"Image size ({image_size} bytes) EXCEEDS boot partition ({EXPECTED_PARTITION_SIZE} bytes)")

    # 2. Header version & page size
    if header.get("header_version") == EXPECTED_HEADER_VERSION:
        passed.append(f"Header version == {EXPECTED_HEADER_VERSION}")
    else:
        errors.append(f"Header version mismatch: got {header.get('header_version')}, expected {EXPECTED_HEADER_VERSION}")

    if header.get("header_size") == EXPECTED_HEADER_SIZE:
        passed.append(f"Header size == {EXPECTED_HEADER_SIZE}")
    else:
        errors.append(f"Header size mismatch: got {header.get('header_size')}, expected {EXPECTED_HEADER_SIZE}")

    if header.get("page_size") == EXPECTED_PAGE_SIZE:
        passed.append(f"Page size == {EXPECTED_PAGE_SIZE}")
    else:
        errors.append(f"Page size mismatch: got {header.get('page_size')}, expected {EXPECTED_PAGE_SIZE}")

    # 3. Load addresses / offsets
    for key, exp_val in [
        ("kernel_address", f"0x{EXPECTED_KERNEL_ADDR:08x}"),
        ("ramdisk_address", f"0x{EXPECTED_RAMDISK_ADDR:08x}"),
        ("tags_address", f"0x{EXPECTED_TAGS_ADDR:08x}"),
        ("dtb_address", f"0x{EXPECTED_DTB_ADDR:08x}"),
    ]:
        got_val = str(header.get(key, "")).lower()
        if got_val == exp_val.lower():
            passed.append(f"{key} == {exp_val}")
        else:
            errors.append(f"{key} mismatch: got {got_val}, expected {exp_val}")

    # 4. OS Version & Security Patch Level (Anti-Rollback check)
    packed = header.get("os_version_packed", 0)
    os_ver, os_patch = decode_os_version(packed)
    exp_ver, exp_patch = decode_os_version(EXPECTED_OS_VERSION_PACKED)
    if packed == EXPECTED_OS_VERSION_PACKED:
        passed.append(f"os_version_packed == {EXPECTED_OS_VERSION_PACKED} (OS={os_ver}, Patch={os_patch})")
    elif packed > EXPECTED_OS_VERSION_PACKED:
        warnings.append(f"os_version_packed ({packed}: OS={os_ver}, Patch={os_patch}) is newer than stock ({EXPECTED_OS_VERSION_PACKED}: OS={exp_ver}, Patch={exp_patch})")
    else:
        errors.append(
            f"os_version_packed DOWNGRADE detected: got {packed} (OS={os_ver}, Patch={os_patch}), "
            f"expected >= {EXPECTED_OS_VERSION_PACKED} (OS={exp_ver}, Patch={exp_patch})"
        )

    # 5. Kernel cmdline
    cmdline = header.get("cmdline", "")
    if EXPECTED_CMDLINE_PREFIX in cmdline:
        passed.append(f"Kernel cmdline contains '{EXPECTED_CMDLINE_PREFIX}' (full: '{cmdline}')")
    else:
        errors.append(f"Kernel cmdline missing '{EXPECTED_CMDLINE_PREFIX}': got '{cmdline}'")

    # 6. Prebuilt Kernel & DTB SHA-256
    comps = header.get("components", {})
    k_info = comps.get("kernel.gz", {})
    if k_info.get("sha256") == EXPECTED_KERNEL_SHA256 and k_info.get("size") == EXPECTED_KERNEL_SIZE:
        passed.append(f"kernel.gz matches stock SHA-256 ({EXPECTED_KERNEL_SHA256[:16]}...) and size ({EXPECTED_KERNEL_SIZE})")
    else:
        errors.append(f"kernel.gz mismatch: got size={k_info.get('size')} sha256={k_info.get('sha256')}")

    d_info = comps.get("dtb.img", {})
    if d_info.get("sha256") == EXPECTED_DTB_SHA256 and d_info.get("size") == EXPECTED_DTB_SIZE:
        passed.append(f"dtb.img matches stock SHA-256 ({EXPECTED_DTB_SHA256[:16]}...) and size ({EXPECTED_DTB_SIZE})")
    else:
        errors.append(f"dtb.img mismatch: got size={d_info.get('size')} sha256={d_info.get('sha256')}")

    # 7. Ramdisk entries verification
    entry_map = {e["name"]: e for e in manifest}
    for req_file in REQUIRED_RAMDISK_FILES:
        if req_file in entry_map:
            passed.append(f"Ramdisk contains required entry: {req_file}")
        else:
            errors.append(f"Ramdisk MISSING required entry: {req_file}")

    # 8. Executable mode verification (0755/0750 check for sbin/foxstart.sh, sbin/bash, FFiles/ps, etc.)
    for exec_path in CRITICAL_EXECUTABLE_PATHS:
        if exec_path in entry_map:
            e = entry_map[exec_path]
            mode_int = int(e["mode"], 8)
            if (mode_int & 0o111) != 0:
                passed.append(f"Executable bit set on {exec_path} (mode={e['mode']})")
            else:
                errors.append(
                    f"CRITICAL: {exec_path} is NOT executable (mode={e['mode']})! "
                    f"OrangeFox post-init scripts/binaries will fail to execute!"
                )

    return passed, warnings, errors


def verify_device_tree_dir(dt_path: pathlib.Path) -> Tuple[List[str], List[str], List[str]]:
    passed = []
    warnings = []
    errors = []

    required_dt_files = [
        "Android.mk",
        "AndroidProducts.mk",
        "twrp_TB370FU.mk",
        "omni_TB370FU.mk",
        "device.mk",
        "hardware-reviewed.mk",
        "BoardConfig.mk",
        "orangefox.mk",
        "orangefox.env",
        "vendorsetup.sh",
        "recovery.fstab",
        "BUILD_GATES.json",
        "recovery/root/init.recovery.mt6877.rc",
        "recovery/root/init.recovery.mt8791.rc",
        "recovery/root/init.recovery.tb370fu.bootdiag.rc",
        "recovery/root/first_stage_ramdisk/fstab.mt6877",
        "recovery/root/first_stage_ramdisk/fstab.mt8791",
        "recovery/root/first_stage_ramdisk/fstab.mt6877dm",
        "recovery/root/first_stage_ramdisk/fstab.mt8791dm",
        "recovery/root/first_stage_ramdisk/fstab.emmc",
        "sepolicy/tb370fu_bootdiag.te",
    ]

    for rel in required_dt_files:
        p = dt_path / rel
        if p.is_file() and p.stat().st_size > 0:
            passed.append(f"Device tree file present: {rel} ({p.stat().st_size} bytes)")
        else:
            errors.append(f"Device tree file MISSING or empty: {rel}")

    bcfg_path = dt_path / "BoardConfig.mk"
    if bcfg_path.is_file():
        bcfg = bcfg_path.read_text(encoding="utf-8")
        checks = [
            ("BOARD_BOOTIMG_HEADER_VERSION := 2", "Header version 2 locked"),
            ("BOARD_KERNEL_PAGESIZE := 2048", "Page size 2048 locked"),
            ("BOARD_KERNEL_OFFSET := 0x40080000", "Kernel offset 0x40080000 locked"),
            ("BOARD_RAMDISK_OFFSET := 0x51100000", "Ramdisk offset 0x51100000 locked"),
            ("BOARD_KERNEL_TAGS_OFFSET := 0x47c80000", "Tags offset 0x47c80000 locked"),
            ("BOARD_DTB_OFFSET := 0x47c80000", "DTB offset 0x47c80000 locked"),
            ("PLATFORM_VERSION := 12.0.0", "OS version 12.0.0 locked"),
            ("PLATFORM_SECURITY_PATCH := 2024-03-05", "Security patch 2024-03-05 locked"),
            ("BOARD_BOOTIMAGE_PARTITION_SIZE := 41943040", "Boot partition size 41943040 locked"),
            ("BOARD_SUPER_PARTITION_SIZE := 11811160064", "Super partition size 11811160064 locked"),
            ("TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888", "Pixel format RGBX_8888 locked"),
        ]
        for token, desc in checks:
            if token in bcfg:
                passed.append(f"BoardConfig.mk check passed: {desc}")
            else:
                errors.append(f"BoardConfig.mk check FAILED: missing '{token}'")

    hw_path = dt_path / "hardware-reviewed.mk"
    if hw_path.is_file():
        hw_text = hw_path.read_text(encoding="utf-8")
        if "$(error TB370FU release BLOCKED" in hw_text:
            errors.append("hardware-reviewed.mk still contains hard $(error) build blocker!")
        else:
            passed.append("hardware-reviewed.mk is free of unconditional $(error) build blockers")

    rfstab_path = dt_path / "recovery.fstab"
    if rfstab_path.is_file():
        rfstab = rfstab_path.read_text(encoding="utf-8")
        for mp in ["/system_root", "/vendor", "/product", "/metadata", "/data", "/boot", "/dtbo", "/vbmeta", "/persist", "/nvdata", "/nvcfg", "/usb-otg"]:
            if mp in rfstab:
                passed.append(f"recovery.fstab includes mount point: {mp}")
            else:
                errors.append(f"recovery.fstab missing mount point: {mp}")

    return passed, warnings, errors


def main() -> int:
    parser = argparse.ArgumentParser(description="TB370FU Post-Build & Device Tree Verification Gate")
    parser.add_argument("--image", type=pathlib.Path, help="Path to built boot.img / recovery.img")
    parser.add_argument("--extracted-dir", type=pathlib.Path, help="Path to directory with boot_header.json & ramdisk_manifest.json")
    parser.add_argument("--device-tree", type=pathlib.Path, help="Path to device/lenovo/TB370FU directory")
    parser.add_argument("--json-report", type=pathlib.Path, help="Optional path to write JSON verification report")
    args = parser.parse_args()

    if not (args.image or args.extracted_dir or args.device_tree):
        parser.error("Provide at least one of --image, --extracted-dir, or --device-tree")

    all_passed, all_warnings, all_errors = [], [], []

    if args.device_tree:
        p, w, e = verify_device_tree_dir(args.device_tree)
        all_passed.extend(p)
        all_warnings.extend(w)
        all_errors.extend(e)

    if args.image:
        raw = args.image.read_bytes()
        header = parse_boot_image_v2(raw)
        ramdisk_gz = header["components"]["ramdisk.gz"]["raw_bytes"]
        if ramdisk_gz[:2] != b"\x1f\x8b":
            all_errors.append(f"Ramdisk is NOT gzip-compressed (magic={ramdisk_gz[:4].hex()})! Kernel only supports CONFIG_RD_GZIP=y.")
            manifest = []
        else:
            all_passed.append("Ramdisk compression verified as GZIP (magic=1f8b)")
            cpio_bytes = gzip.decompress(ramdisk_gz)
            manifest = parse_cpio_newc(cpio_bytes)
        p, w, e = verify_header_and_manifest(header, manifest, image_size=len(raw))
        all_passed.extend(p)
        all_warnings.extend(w)
        all_errors.extend(e)

    if args.extracted_dir:
        bh_path = args.extracted_dir / "boot_header.json"
        rm_path = args.extracted_dir / "ramdisk_manifest.json"
        header = json.loads(bh_path.read_text(encoding="utf-8"))
        manifest = json.loads(rm_path.read_text(encoding="utf-8"))
        p, w, e = verify_header_and_manifest(header, manifest)
        all_passed.extend(p)
        all_warnings.extend(w)
        all_errors.extend(e)

    print("=" * 76)
    print("TB370FU POST-BUILD VERIFICATION GATE REPORT")
    print("=" * 76)
    print(f"PASSED CHECKS ({len(all_passed)}):")
    for msg in all_passed:
        print(f"  [PASS] {msg}")
    if all_warnings:
        print(f"\nWARNINGS ({len(all_warnings)}):")
        for msg in all_warnings:
            print(f"  [WARN] {msg}")
    if all_errors:
        print(f"\nFAILED CHECKS ({len(all_errors)}):")
        for msg in all_errors:
            print(f"  [FAIL] {msg}")
    print("=" * 76)
    verdict = "PASS" if not all_errors else "FAIL"
    print(f"FINAL VERDICT: {verdict}")
    print("=" * 76)

    if args.json_report:
        report = {
            "verdict": verdict,
            "passed_count": len(all_passed),
            "warning_count": len(all_warnings),
            "error_count": len(all_errors),
            "passed": all_passed,
            "warnings": all_warnings,
            "errors": all_errors,
        }
        args.json_report.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    return 0 if not all_errors else 1


if __name__ == "__main__":
    sys.exit(main())