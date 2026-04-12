#!/bin/bash

COMMAND="$1"
VM_NAME="$2"

print_usage() {
    echo "Usage: lab <command> [vm-name]"
    echo ""
    echo "Commands:"
    echo "  start <vm-name>   - Start the specified VM"
    echo "  stop <vm-name>    - Stop the specified VM"
    echo "  force-stop <vm-name> - Force stop the specified VM"
    echo "  list             - List all VMs and their statuses"
    echo "  status <vm-name>   - Show the status of the specified VM"
    echo "  help             - Show this help message"

}
if [[ "$COMMAND" == "help" ]]; then
    print_usage
    exit 0
fi

check_dps(){
    if ! command -v virsh &> /dev/null; then
        echo "Error: 'virsh' command not found. Please install libvirt to manage VMs."
        exit 1
    fi
}
start_vm() {
    if sudo virsh list | grep -q "$VM_NAME"; then
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
    if sudo virsh list --all | grep -q "$VM_NAME"; then
        sudo virsh shutdown "$VM_NAME"
        if [ $? -eq 0 ]; then
            echo "VM '$VM_NAME' stopped successfully."
        else
            echo "Failed to stop VM '$VM_NAME'."
        fi
    else
        echo "VM '$VM_NAME' does not exist."
    fi
}
check_dps

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
        [[ -z "$VM_NAME" ]] && { echo "Error: Missing VM name."; exit 1; }
        sudo virsh destroy "$VM_NAME"
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
