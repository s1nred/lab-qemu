#!/bin/bash

set -u

VERSION="0.3.0"

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

if [[ "$COMMAND" == "snapshot" ]]; then
    SNAPSHOT_ACTION="${2:-}"
    VM_NAME="${3:-}"
    SNAPSHOT_NAME="${4:-}"
else
    VM_NAME="${2:-}"
fi

if [[ "$COMMAND" == "--version" || "$COMMAND" == "-V" ]]; then
    echo "lab.sh v${VERSION}"
    exit 0
fi

print_usage() {
    echo "Usage: lab <command> [vm-name]"
    echo ""
    echo "Virtual Machine:"
    echo "  start <vm-name>        - Start the specified VM"
    echo "  stop <vm-name>         - Send a graceful shutdown signal to the VM"
    echo "  force-stop <vm-name>   - Force stop the specified VM"
    echo "  restart <vm-name>      - Gracefully restart the specified VM"
    echo "  force-restart <vm-name> - Force restart the specified VM"
    echo "  list                   - List all VMs and their statuses"
    echo "  status <vm-name>       - Show detailed info about the specified VM"
    echo ""
    echo "Snapshots:"
    echo "  snapshot list <vm-name>           - List all snapshots"
    echo "  snapshot create <vm-name> <name>  - Create a snapshot"
    echo "  snapshot revert <vm-name> <name>  - Revert to a snapshot"
    echo "  snapshot delete <vm-name> <name>  - Delete a snapshot"
    echo ""
    echo "Other:"
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

snapshot_list() {
    if ! vm_exists; then
        warn "VM '$VM_NAME' does not exist."
        exit 1
    fi
    info "Snapshots for VM '$VM_NAME':"
    sudo virsh snapshot-list "$VM_NAME"
}

snapshot_create() {
    if ! vm_exists; then
        warn "VM '$VM_NAME' does not exist."
        exit 1
    fi
    if [ -z "$SNAPSHOT_NAME" ]; then
        error_msg "Error: Snapshot name is required for 'snapshot create'."
        exit 1
    fi
    sudo virsh snapshot-create-as "$VM_NAME" --name "$SNAPSHOT_NAME"
    if [ $? -eq 0 ]; then
        success "Snapshot '$SNAPSHOT_NAME' created for VM '$VM_NAME'."
    else
        error_msg "Failed to create snapshot '$SNAPSHOT_NAME' for VM '$VM_NAME'."
        exit 1
    fi
}

snapshot_revert() {
    if ! vm_exists; then
        warn "VM '$VM_NAME' does not exist."
        exit 1
    fi
    if [ -z "$SNAPSHOT_NAME" ]; then
        error_msg "Error: Snapshot name is required for 'snapshot revert'."
        exit 1
    fi
    # Check if the snapshot exists before attempting revert
    if ! sudo virsh snapshot-list "$VM_NAME" --name 2> /dev/null | grep -Fxq -- "$SNAPSHOT_NAME"; then
        error_msg "Snapshot '$SNAPSHOT_NAME' does not exist on VM '$VM_NAME'."
        exit 1
    fi
    sudo virsh snapshot-revert "$VM_NAME" --snapshotname "$SNAPSHOT_NAME"
    if [ $? -eq 0 ]; then
        success "Reverted VM '$VM_NAME' to snapshot '$SNAPSHOT_NAME'."
    else
        error_msg "Failed to revert VM '$VM_NAME' to snapshot '$SNAPSHOT_NAME'."
        exit 1
    fi
}

snapshot_delete() {
    if ! vm_exists; then
        warn "VM '$VM_NAME' does not exist."
        exit 1
    fi
    if [ -z "$SNAPSHOT_NAME" ]; then
        error_msg "Error: Snapshot name is required for 'snapshot delete'."
        exit 1
    fi
    if ! sudo virsh snapshot-list "$VM_NAME" --name 2> /dev/null | grep -Fxq -- "$SNAPSHOT_NAME"; then
        error_msg "Snapshot '$SNAPSHOT_NAME' does not exist on VM '$VM_NAME'."
        exit 1
    fi
    sudo virsh snapshot-delete "$VM_NAME" --snapshotname "$SNAPSHOT_NAME"
    if [ $? -eq 0 ]; then
        success "Snapshot '$SNAPSHOT_NAME' deleted from VM '$VM_NAME'."
    else
        error_msg "Failed to delete snapshot '$SNAPSHOT_NAME' from VM '$VM_NAME'."
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
        # Shutdown is asynchronous: wait until the guest has actually stopped.
        stopped=false
        for ((attempt=0; attempt<30; attempt++)); do
            state=$(sudo virsh domstate "$VM_NAME" 2>/dev/null) || {
                error_msg "Could not query VM '$VM_NAME' state."
                exit 1
            }
            if [[ "$state" == "shut off" ]]; then
                stopped=true
                break
            fi
            sleep 1
        done
        if [[ "$stopped" != true ]]; then
            error_msg "VM '$VM_NAME' did not shut down within 30 seconds; restart aborted."
            exit 1
        fi
        start_vm
        ;;
    force-restart)
        require_vm_name
        if ! vm_exists; then
            warn "VM '$VM_NAME' does not exist."
            exit 1
        fi
        if sudo virsh domstate "$VM_NAME" 2>/dev/null | grep -Fxq "running"; then
            if ! sudo virsh destroy "$VM_NAME"; then
                error_msg "Failed to stop VM '$VM_NAME'; restart aborted."
                exit 1
            fi
        fi
        start_vm
        ;;
    snapshot)
        if [ -z "$SNAPSHOT_ACTION" ]; then
            error_msg "Error: Snapshot action is required."
            info "Usage: lab snapshot <list|create|revert|delete> <vm-name> [snapshot-name]"
            exit 1
        fi
        require_vm_name
        case "$SNAPSHOT_ACTION" in
            list)
                snapshot_list
                ;;
            create)
                snapshot_create
                ;;
            revert)
                snapshot_revert
                ;;
            delete)
                snapshot_delete
                ;;
            *)
                error_msg "Error: Invalid snapshot action '$SNAPSHOT_ACTION'."
                info "Valid actions: list, create, revert, delete"
                exit 1
                ;;
        esac
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
