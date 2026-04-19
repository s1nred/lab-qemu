#!/bin/bash

set -u

COMMAND="${1:-help}"
VM_NAME="${2:-}"

print_usage() {
    echo "Usage: lab <command> [vm-name]"
    echo ""
    echo "Commands:"
    echo "  start <vm-name>   - Start the specified VM"
    echo "  stop <vm-name>    - Send a graceful shutdown signal to the VM"
    echo "  force-stop <vm-name> - Force stop the specified VM"
    echo "  list             - List all VMs and their statuses"
    echo "  status <vm-name>   - Show the status of the specified VM"
    echo "  help, -h, --help - Show this help message"

}
if [[ "$COMMAND" == "help" || "$COMMAND" == "-h" || "$COMMAND" == "--help" ]]; then
    print_usage
    exit 0
fi

check_deps() {
    if ! command -v virsh &> /dev/null; then
        echo "Error: 'virsh' command not found. Please install libvirt to manage VMs."
        exit 1
    fi
}

vm_exists() {
    sudo virsh dominfo "$VM_NAME" > /dev/null 2>&1
}

start_vm() {
    if ! vm_exists; then
        echo "VM '$VM_NAME' does not exist."
    elif sudo virsh domstate "$VM_NAME" 2> /dev/null | grep -q '^running$'; then
        echo "VM '$VM_NAME' is already running."
    else
        sudo virsh start "$VM_NAME"
        if [ $? -eq 0 ]; then
            echo "VM '$VM_NAME' started successfully."
        else
            echo "Failed to start VM '$VM_NAME'."
        fi
    fi
}
stop_vm() {
    if vm_exists; then
        sudo virsh shutdown "$VM_NAME"
        if [ $? -eq 0 ]; then
            echo "Shutdown signal sent to VM '$VM_NAME'."
        else
            echo "Failed to send shutdown signal to VM '$VM_NAME'."
        fi
    else
        echo "VM '$VM_NAME' does not exist."
    fi
}
check_deps

case "$COMMAND" in
    start)
        if [ -z "$VM_NAME" ]; then
            echo "Error: VM name is required for the 'start' command."
            print_usage
            exit 1
        fi
        start_vm
        ;;
    stop)
        if [ -z "$VM_NAME" ]; then
            echo "Error: VM name is required for the 'stop' command."
            print_usage
            exit 1
        fi
        stop_vm
        ;;
    force-stop)
        if [ -z "$VM_NAME" ]; then
            echo "Error: VM name is required for the 'force-stop' command."
            print_usage
            exit 1
        fi
        if ! vm_exists; then
            echo "VM '$VM_NAME' does not exist."
            exit 1
        fi
        sudo virsh destroy "$VM_NAME"
        if [ $? -eq 0 ]; then
            echo "VM '$VM_NAME' was force-stopped."
        else
            echo "Failed to force-stop VM '$VM_NAME'."
            exit 1
        fi
        ;;
    list)
        sudo virsh list --all
        ;;
    status)
        if [ -z "$VM_NAME" ]; then
            echo "Error: VM name is required for the 'status' command."
            print_usage
            exit 1
        fi
        sudo virsh dominfo "$VM_NAME"
        ;;
    *)
        echo "Error: Invalid command '$COMMAND'."
        print_usage
        exit 1
        ;;
esac
