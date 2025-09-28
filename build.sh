#!/bin/bash

echo "=== Building root_OS by execRooted ==="


mkdir -p os


echo "Building bootloader..."
nasm -f bin boot/boot.asm -o os/boot.bin


echo "Building kernel..."
nasm -f bin kernel/kernel.asm -o os/kernel.bin


echo "Creating disk image..."
dd if=/dev/zero of=root_OS.img bs=512 count=2880


echo "Installing bootloader..."
dd if=os/boot.bin of=root_OS.img conv=notrunc


echo "Installing kernel..."
dd if=os/kernel.bin of=root_OS.img bs=512 seek=1 conv=notrunc


qemu-system-x86_64 -hda root_OS.img -net nic,model=rtl8139 -net user

echo ""
echo "=== Build Complete ==="
echo "OS files created in: os/"
echo "Image: root_OS.img"
echo ""
echo "Files in OS directory:"
ls -la os/
echo ""
echo "Test with: qemu-system-x86_64 -hda root_OS.img"
echo ""
echo "To flash to USB:"
echo "  sudo dd if=root_OS.img of=/dev/sdX bs=4M status=progress"
echo "  sync"
echo ""
echo "WARNING: Replace /dev/sdX with your actual USB device!"
