# lab.sh KVM Virtual Machine Manager

A lightweight Bash CLI tool for managing KVM/QEMU virtual machines via `virsh`. Designed to simplify day-to-day VM operations in a local lab environment.

---

## Requirements

- Linux with [libvirt](https://libvirt.org/) installed
- `virsh` available in your `$PATH`
- Sufficient `sudo` privileges to manage VMs

Install libvirt on Arch Linux:

```bash
sudo pacman -S libvirt virt-client-tools
sudo systemctl enable --now libvirtd
```

Install libvirt on Debian/Ubuntu:

```bash
sudo apt install libvirt-clients libvirt-daemon-system
```

Install libvirt on Fedora/RHEL:

```bash
sudo dnf install libvirt
```

---

## Installation

1. Clone the script:

```bash
git clone https://github.com/s1nred/lab-qemu.git
cd lab-qemu
```

2. Make it executable:

```bash
chmod +x lab.sh
```

3. Optionally move it to your PATH for global access:

```bash
sudo mv lab.sh /usr/local/bin/lab
```

---

## Usage

```
lab <command> [vm-name]
```

### Commands

| Command | Arguments | Description |
|---|---|---|
| `start` | `<vm-name>` | Start the specified VM |
| `stop` | `<vm-name>` | Send a graceful shutdown signal to the specified VM |
| `force-stop` | `<vm-name>` | Forcefully terminate the specified VM (equivalent to pulling the power) |
| `list` | — | List all VMs and their current statuses |
| `status` | `<vm-name>` | Display detailed information about the specified VM |
| `help` | — | Show the help message |
| `-h`, `--help` | — | Show the help message |

---

## Examples

```bash
# Start a VM named "ubuntu-server"
lab start ubuntu-server

# Gracefully stop a VM
lab stop ubuntu-server

# Force stop a VM (use when graceful shutdown fails)
lab force-stop ubuntu-server

# List all VMs (running and stopped)
lab list

# Show detailed status of a VM
lab status ubuntu-server

# Display help
lab help
```

---

## Notes

- **`stop`** sends an ACPI shutdown signal (graceful). The guest OS handles the shutdown, so it may take a few seconds.
- **`force-stop`** calls `virsh destroy`, which immediately kills the VM process. Use this only when the VM is unresponsive, as it may cause data loss or filesystem corruption.
- **`start`** checks if the VM is already running before attempting to start it, preventing duplicate start errors.
- VM-specific commands now validate that the domain exists before attempting to operate on it.
- The script validates that `virsh` is installed before executing any command.
- Running `lab` without arguments shows the help output by default.

---

## Project Structure

```
lab
├── lab.sh       # Main script
└── README.md    # This file
```

---

## License

MIT License. Feel free to use, modify, and distribute.
