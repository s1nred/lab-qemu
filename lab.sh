#!/bin/bash

VM_NAME="$1"

if [ -z "$VM_NAME" ]; then
    echo "Uso: $0 <vm-name>"
    exit 1
fi

if ! command -v virsh >/dev/null 2>&1; then
    echo "Error: 'virsh' is not installed."
    exit 1
fi

if sudo virsh list | grep -w -q "$VM_NAME"; then
    echo "[i] '$VM_NAME' is already running."
    exit 0
fi

echo "[+] Starting... '$VM_NAME'..."

if sudo virsh start "$VM_NAME" >/dev/null 2>&1; then
    echo "[ok] The machine started correctly."
else
    echo "[error] Could not start '$VM_NAME'."
    echo "Check the status using:: sudo virsh list --all"
    exit 1
fi
