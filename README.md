# rtl8761bu-firmware (Bluetooth 5.4 / `0xddd5c761`)

Updated official Realtek **RTL8761BU / RTL8761BUV** USB Bluetooth firmware (`fw version 0xddd5c761`, extracted from the 2025 Windows WHQL driver `1.9.1038.3023`) for Linux.

Fixes the notorious **Xbox Wireless Controller (Series X|S)** disconnect loop caused by the May 2023 `0xdfc6d922` regression in `linux-firmware`, while upgrading compatible adapters (such as the **TP-Link UB500**, **UB500 Plus**, **Mercusys MA530**, **ASUS USB-BT500**, and generic `0bda:8771` dongles) from **Bluetooth 5.1 (`hci_ver=0x0a`)** to **Bluetooth 5.4 (`hci_ver=0x0d`)**.

---

## Why this repository exists

In May 2023, upstream `linux-firmware` updated `rtl_bt/rtl8761bu_fw.bin` to version **`0xdfc6d922`** and has not updated it since. That version introduced a severe stability regression where **Xbox Series X|S Wireless Controllers (`045E:0B13`)** repeatedly disconnect or fail to stay connected over Bluetooth Low Energy (BLE).

Previously, the common workaround on Linux (e.g., `andrew-ld/rtl8761b-firmware`) was to downgrade the firmware back to the December 2021 build (**`0x09a98a6b`**) and overwrite files directly inside `/usr/lib/firmware/rtl_bt/` (which causes package manager conflicts on Arch Linux / CachyOS / Manjaro).

However, Realtek continued releasing newer firmware builds inside official Windows WHQL drivers (`rtl8761b_mp_chip_bt40_fw_asic_rom_patch_new.dat`), which use the **exact same `Realtech` binary format** expected by the Linux kernel's `btrtl` module:

| Firmware Source | Release Date | Windows Driver | `fw version` (`dmesg`) | BT Core Spec | Size | Xbox Series X\|S Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `andrew-ld/rtl8761b-firmware` | Dec 2021 | — | `0x09a98a6b` | BT 5.1 (`0x0a`) | 42,088 B | Stable (Old Downgrade) |
| Upstream `linux-firmware` | May 2023 | — | `0xdfc6d922` | BT 5.1 (`0x0a`) | 44,484 B | **Broken (Disconnect Loops)** |
| TP-Link / Realtek Win10/11 | Sep 2023 | `1.9.1038.3015` | `0xdcc6b3a8` | BT 5.3 (`0x0c`) | 42,620 B | Stable |
| **This Repo (TP-Link / Realtek 2025)** | **Dec 2024 / Jul 2025** | **`1.9.1038.3023` WHQL** | **`0xddd5c761`** | **BT 5.4 (`0x0d`)** | **43,340 B** | **Stable + BT 5.4 Upgrade** |

### Key Advantages
1. **Fixes Xbox Series X|S Controller Disconnects** without downgrading to a 2021 firmware.
2. **Zero Package Manager Conflicts**: Installs into `/usr/lib/firmware/updates/rtl_bt/`, which the Linux kernel `firmware_class` loader automatically prioritizes over `/usr/lib/firmware/rtl_bt/` without overwriting files owned by `linux-firmware-realtek`.
3. **100% Compatible with Secure Boot, Kernel Lockdown & Easy Anti-Cheat (EAC Linux v2)**: Does not use any unsigned out-of-tree/DKMS kernel module (`.ko`). Your kernel continues running its stock signed `btusb` and `btrtl` modules.

---

## Installation

### Arch Linux / CachyOS / Manjaro (AUR)

```bash
paru -S rtl8761bu-firmware
# or
yay -S rtl8761bu-firmware
```

The package automatically installs the firmware override into `/usr/lib/firmware/updates/rtl_bt/` and reloads `btusb` so the new firmware is active immediately without rebooting.

### Ubuntu / Kubuntu / Linux Mint / Pop!_OS 24.04+ (Launchpad PPA)

```bash
sudo add-apt-repository ppa:yurinogueira/rtl8761bu-firmware
sudo apt update
sudo apt install rtl8761bu-firmware
```

### Manual Installation (Any Linux Distribution)

```bash
git clone https://github.com/yurinogueira/rtl8761bu-firmware.git
cd rtl8761bu-firmware

sudo mkdir -p /usr/lib/firmware/updates/rtl_bt
sudo install -m 644 rtl8761bu_fw.bin /usr/lib/firmware/updates/rtl_bt/rtl8761bu_fw.bin
sudo install -m 644 rtl8761bu_config.bin /usr/lib/firmware/updates/rtl_bt/rtl8761bu_config.bin
if command -v zstd >/dev/null 2>&1; then
    sudo zstd -q -f -k /usr/lib/firmware/updates/rtl_bt/rtl8761bu_fw.bin
    sudo zstd -q -f -k /usr/lib/firmware/updates/rtl_bt/rtl8761bu_config.bin
fi

# Reload btusb to clear old firmware from adapter RAM (via 0xfc66) and load 0xddd5c761
sudo modprobe -r btusb && sudo modprobe btusb
sudo systemctl restart bluetooth.service
```

### Verification

Check `dmesg` / `journalctl` to confirm `fw version 0xddd5c761` is loaded:

```bash
journalctl -b -k | grep -i "RTL:" | tail -n 10
```

Expected output:
```text
Bluetooth: hci0: RTL: loading rtl_bt/rtl8761bu_fw.bin
Bluetooth: hci0: RTL: loading rtl_bt/rtl8761bu_config.bin
Bluetooth: hci0: RTL: cfg_sz 6, total sz 29130
Bluetooth: hci0: RTL: fw version 0xddd5c761
```

---

## Português (PT-BR)

Este repositório fornece o firmware oficial mais recente da Realtek (**`0xddd5c761`** — Bluetooth 5.4, extraído do driver WHQL de Windows `1.9.1038.3023` de 2025) para adaptadores USB Bluetooth baseados no chip **RTL8761BU / RTL8761BUV** (como o **TP-Link UB500 `2357:0604`**, **UB500 Plus**, **Mercusys MA530** e **ASUS USB-BT500**).

- **Corrige as desconexões com o Controle Xbox Series X|S** causadas pela versão `0xdfc6d922` (de maio de 2023) presente no pacote `linux-firmware-realtek`, sem precisar fazer downgrade para o firmware antigo de 2021 (`0x09a98a6b`).
- **Atualiza o adaptador para Bluetooth 5.4 (`Version: 0x0d`)**.
- **Sem conflito com o `pacman`**: utiliza o diretório prioritário `/usr/lib/firmware/updates/rtl_bt/` do kernel Linux, mantendo os arquivos originais do `linux-firmware-realtek` intactos.
- **Compatível com Secure Boot / Kernel Lockdown / EAC Linux v2**: mantém os módulos `btusb` e `btrtl` originais e assinados do kernel.
