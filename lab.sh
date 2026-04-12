#!/bin/bash

VM_NAME="$1"

if [ -z "$VM_NAME" ]; then
    echo "Uso: $0 <nombre-vm>"
    exit 1
fi

if ! command -v virsh >/dev/null 2>&1; then
    echo "Error: 'virsh' no esta instalado."
    exit 1
fi

if sudo virsh list | grep -w -q "$VM_NAME"; then
    echo "[i] '$VM_NAME' ya esta en ejecucion."
    exit 0
fi

echo "[+] Iniciando '$VM_NAME'..."

if sudo virsh start "$VM_NAME" >/dev/null 2>&1; then
    echo "[ok] Maquina iniciada correctamente."
else
    echo "[error] No se pudo iniciar '$VM_NAME'."
    echo "Revisa el estado con: sudo virsh list --all"
    exit 1
fi
