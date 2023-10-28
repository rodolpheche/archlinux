#!/bin/bash

qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -smp 2 \
  -m 2048M \
  -bios /usr/share/edk2-ovmf/x64/OVMF.fd \
  -drive file=dist/archlinux.qcow,if=virtio
