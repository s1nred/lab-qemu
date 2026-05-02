#!/bin/bash

set -u

VERSION="0.2.0"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

success() { echo -e "${GREEN}${1}${NC}"; }
error_msg() { echo -e "${RED}${1}${NC}"; }
warn() { echo -e "${YELLOW}${1}${NC}"; }
info() { echo -e "${BLUE}${1}${NC}"; }

COMMAND="${1:-help}"
VM_NAME="${2:-}"

if [[ "$COMMAND" == "--version" || "$COMMAND" == "-V" ]]; then
    echo "lab.sh v${VERSION}"
    exit 0
fi

print_usage() {
    echo "Usage: lab <command> [vm-name]"
    echo ""
    echo "Commands:"
    echo "  start <vm-name>        - Start the specified VM"
    echo "  stop <vm-name>         - Send a graceful shutdown signal to the VM"
    echo "  force-stop <vm-name>   - Force stop the specified VM"
    echo "  restart <vm-name>      - Gracefully restart the specified VM"
    echo "  force-restart <vm-name> - Force restart the specified VM"
    echo "  list                   - List all VMs and their statuses"
    echo "  status <vm-name>       - Show the status of the specified VM"
    echo "  help, -h, --help       - Show this help message"
    echo "  --version, -V          - Show version"
    echo ""
}

if [[ "$COMMAND" == "help" || "$COMMAND" == "-h" || "$COMMAND" == "--help" ]]; then
    print_usage
    exit 0
fi

check_deps() {
    if ! command -v virsh &> /dev/null; then
        error_msg "Error: 'virsh' command not found. Please install libvirt to manage VMs."
        exit 1
    fi
}

require_vm_name() {
    if [ -z "$VM_NAME" ]; then
        error_msg "Error: VM name is required for the '$COMMAND' command."
        exit 1
    fi
}

vm_exists() {
    sudo virsh dominfo "$VM_NAME" > /dev/null 2>&1
}

start_vm() {
    if ! vm_exists; then
        warn "VM '$VM_NAME' does not exist."
        exit 1
    elif sudo virsh domstate "$VM_NAME" 2> /dev/null | grep -q '^running$'; then
        warn "VM '$VM_NAME' is already running."
    else
        sudo virsh start "$VM_NAME"
        if [ $? -eq 0 ]; then
            success "VM '$VM_NAME' started successfully."
        else
            error_msg "Failed to start VM '$VM_NAME'."
            exit 1
        fi
    fi
}

stop_vm() {
    if vm_exists; then
        sudo virsh shutdown "$VM_NAME"
        if [ $? -eq 0 ]; then
            success "Shutdown signal sent to VM '$VM_NAME'."
        else
            error_msg "Failed to send shutdown signal to VM '$VM_NAME'."
            exit 1
        fi
    else
        warn "VM '$VM_NAME' does not exist."
        exit 1
    fi
}

check_deps

case "$COMMAND" in
    start)
        require_vm_name
        start_vm
        ;;
    stop)
        require_vm_name
        stop_vm
        ;;
    force-stop)
        require_vm_name
        if ! vm_exists; then
            warn "VM '$VM_NAME' does not exist."
            exit 1
        fi
        sudo virsh destroy "$VM_NAME"
        if [ $? -eq 0 ]; then
            success "VM '$VM_NAME' was force-stopped."
        else
            error_msg "Failed to force-stop VM '$VM_NAME'."
            exit 1
        fi
        ;;
    restart)
        require_vm_name
        if ! vm_exists; then
            warn "VM '$VM_NAME' does not exist."
            exit 1
        fi
        sudo virsh shutdown "$VM_NAME"
        if [ $? -ne 0 ]; then
            error_msg "Failed to send shutdown signal to VM '$VM_NAME'."
            exit 1
        fi
        info "Waiting for VM '$VM_NAME' to shut down..."
        sleep 5
        start_vm
        ;;
    force-restart)
        require_vm_name
        if ! vm_exists; then
            warn "VM '$VM_NAME' does not exist."
            exit 1
        fi
        sudo virsh destroy "$VM_NAME" 2> /dev/null
        start_vm
        ;;
    list)
        sudo virsh list --all
        ;;
    status)
        require_vm_name
        sudo virsh dominfo "$VM_NAME"
        ;;
    *)
        error_msg "Error: Invalid command '$COMMAND'."
        print_usage
        exit 1
        ;;
esac
