# root_OS

A simple operating system build by execRooted.

## OS Commands

The following commands are available in the root_OS shell:

| Command | Description |
|---------|-------------|
| `help` | Show available commands |
| `list` | List files in the OS |
| `make <filename>` | Create a new file |
| `delete <filename>` | Delete a file |
| `clear` | Clear the screen |
| `show <filename>` | Display file contents |
| `ifconfig` | Show network interfaces |
| `connect` | Connect to the internet |
| `ping <ip>` | Ping an IP address |
| `echo <text>` | Print text or write to file |
| `shutdown` | Shutdown the system |

## Prerequisites

- NASM (Netwide Assembler)
- `dd` (part of coreutils)
- QEMU

## Usage

Run the build script:

```bash
./build.sh
```

This will build the OS and boot it in QEMU. The OS provides a simple shell where you can enter the commands above.

## Flashing to USB

To flash the image to a USB drive (replace `/dev/sdX` with your device):

```bash
sudo dd if=root_OS.img of=/dev/sdX bs=4M status=progress
sync
```

**Warning:** This will overwrite the target device. Ensure you have the correct device path.