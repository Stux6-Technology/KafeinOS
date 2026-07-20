#!/bin/sh

# This script starts the QEMU PC emulator, booting from the
# KafeinOS floppy disk image

qemu-system-i386 -soundhw pcspk -drive format=raw,file=disk_images/kafeinos.flp,index=0,if=floppy
