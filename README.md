# lab.sh
A simple script to start a virtual machine in QEMU/libvirt using `virsh`

## Requirements

- `virsh`
- permissions to run `sudo virsh`

## Use

```bash
./lab.sh <vm-name>
```

Example:

```bash
./lab.sh kali-linux
```

## Run it as a lab

If you want to use the script from anywhere on the system, create a symbolic link in a directory included in your `PATH`:
```bash
chmod +x lab.sh
sudo ln -s "$(pwd)/lab.sh" /usr/local/bin/lab
```

Then you can run it like this:
```bash
lab kali-linux
To check if it's available:
```
```bash
which lab
```

## What does it do?

- Check if the VM is already running
- If it isn't, try to start it
