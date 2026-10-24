#!/usr/bin/env python3
"""
Downloads and extracts the official Realtek RTL8761BU Bluetooth 5.4 firmware
(fw version 0xddd5c761, Windows WHQL driver 1.9.1038.3023) from TP-Link's
official UB500 V3 Windows driver package and verifies its binary header & hashes.
"""

import hashlib
import io
import os
import struct
import urllib.request
import zipfile

DRIVER_URL = "https://static.tp-link.com/upload/driver/2025/202507/20250704/UB500(UN)_V3_20250702_Win10_Win11.zip"
DAT_MEMBER = "UB500 EAA/Driver/Windows_11_64bit/rtl8761b_mp_chip_bt40_fw_asic_rom_patch_new.dat"
EXPECTED_FW_VERSION = 0xDDD5C761
EXPECTED_SHA256 = "f48cf7124028206bb049740cd4cb0c63c5ad6315febec19f5cf248138b663a47"


def main() -> None:
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print(f"Downloading official Windows driver from:\n  {DRIVER_URL}")
    req = urllib.request.Request(DRIVER_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        zip_bytes = resp.read()

    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
        fw_bytes = zf.read(DAT_MEMBER)

    magic = fw_bytes[:8]
    fw_ver = struct.unpack("<I", fw_bytes[8:12])[0]
    num_patches = struct.unpack("<H", fw_bytes[12:14])[0]
    tail_sig = fw_bytes[-4:].hex()
    sha256 = hashlib.sha256(fw_bytes).hexdigest()

    assert magic == b"Realtech", f"Unexpected magic header: {magic!r}"
    assert tail_sig == "5104fd77", f"Unexpected tail signature: {tail_sig}"
    assert fw_ver == EXPECTED_FW_VERSION, f"Expected 0x{EXPECTED_FW_VERSION:08x}, got 0x{fw_ver:08x}"
    assert sha256 == EXPECTED_SHA256, f"SHA256 mismatch: {sha256}"

    out_fw = os.path.join(repo_root, "rtl8761bu_fw.bin")
    out_cfg = os.path.join(repo_root, "rtl8761bu_config.bin")
    with open(out_fw, "wb") as f:
        f.write(fw_bytes)
    with open(out_cfg, "wb") as f:
        f.write(bytes.fromhex("55ab23870000"))

    print(f"Successfully extracted and verified rtl8761bu_fw.bin:")
    print(f"  Size:       {len(fw_bytes)} bytes")
    print(f"  FW Version: 0x{fw_ver:08x} (Patches: {num_patches})")
    print(f"  SHA256:     {sha256}")


if __name__ == "__main__":
    main()
