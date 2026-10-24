#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW_STORE="${SCRIPT_DIR}/firmwares"
TARGET_DIR="/usr/lib/firmware/updates/rtl_bt"

usage() {
    cat <<EOF
Uso: $(basename "$0") <comando>

Comandos disponíveis:
  windows-2025   Instala o firmware Windows mais novo (0xddd5c761 - Dez/2024 / Jul/2025, driver 1.9.1038.3023)
  windows-2024   Instala o firmware Windows intermediário (0xdcc6b3a8 - Set/2023 / Jan/2024, driver 1.9.1051)
  andrew-ld      Instala o firmware antigo estável (0x09a98a6b - Dez/2021, repositório andrew-ld / AUR)
  uninstall      Remove qualquer override em ${TARGET_DIR} e volta ao padrão do sistema (0xdfc6d922)
  status         Exibe o firmware atualmente instalado em ${TARGET_DIR} e a versão ativa no kernel (dmesg)
EOF
}

show_status() {
    echo "=== Status dos Arquivos em ${TARGET_DIR} ==="
    if [[ -d "${TARGET_DIR}" ]] && ls "${TARGET_DIR}"/rtl8761* >/dev/null 2>&1; then
        ls -la "${TARGET_DIR}"
        if [[ -f "${TARGET_DIR}/ACTIVE_PROFILE" ]]; then
            echo "Perfil ativo em updates/: $(cat "${TARGET_DIR}/ACTIVE_PROFILE")"
        fi
    else
        echo "Nenhum override ativo em ${TARGET_DIR} (usando padrão do pacote linux-firmware-realtek)."
    fi
    echo ""
    echo "=== Últimos Logs do Kernel (btrtl / hci0) ==="
    journalctl -b -k --no-pager | grep -i "RTL:" | tail -n 12 || true
}

ACTION="${1:-status}"

if [[ "${ACTION}" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "${ACTION}" != "windows-2025" && "${ACTION}" != "windows-2024" && "${ACTION}" != "andrew-ld" && "${ACTION}" != "uninstall" && "${ACTION}" != "default" ]]; then
    usage
    exit 1
fi

# Eleva privilégios apenas uma vez via pkexec (ou sudo se não houver sessão gráfica)
if [[ "${EUID}" -ne 0 ]]; then
    if command -v pkexec >/dev/null 2>&1 && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        echo "Solicitando permissão de administrador via Polkit (KDE)..."
        exec pkexec "$0" "$@"
    else
        echo "Solicitando permissão de administrador via sudo..."
        exec sudo "$0" "$@"
    fi
fi

if [[ "${ACTION}" == "uninstall" || "${ACTION}" == "default" ]]; then
    echo "[1/3] Removendo overrides de ${TARGET_DIR}..."
    rm -rf "${TARGET_DIR}"
else
    SRC_DIR="${FW_STORE}/${ACTION}"
    if [[ ! -f "${SRC_DIR}/rtl8761bu_fw.bin" ]]; then
        echo "Erro: firmware não encontrado em ${SRC_DIR}/rtl8761bu_fw.bin" >&2
        exit 1
    fi
    echo "[1/3] Instalando perfil '${ACTION}' em ${TARGET_DIR}..."
    mkdir -p "${TARGET_DIR}"
    install -m 644 "${SRC_DIR}/rtl8761bu_fw.bin" "${TARGET_DIR}/rtl8761bu_fw.bin"
    install -m 644 "${SRC_DIR}/rtl8761bu_config.bin" "${TARGET_DIR}/rtl8761bu_config.bin"
    install -m 644 "${SRC_DIR}/rtl8761bu_fw.bin.zst" "${TARGET_DIR}/rtl8761bu_fw.bin.zst"
    install -m 644 "${SRC_DIR}/rtl8761bu_config.bin.zst" "${TARGET_DIR}/rtl8761bu_config.bin.zst"
    echo "${ACTION}" > "${TARGET_DIR}/ACTIVE_PROFILE"
fi

echo "[2/3] Recarregando módulos btusb/btrtl para atualizar a RAM do adaptador..."
modprobe -r btusb || true
sleep 1
modprobe btusb
sleep 2
systemctl restart bluetooth.service || true
sleep 1

echo "[3/3] Verificando versão carregada pelo kernel:"
journalctl -b -k --no-pager | grep -i "RTL:" | tail -n 12 || true
