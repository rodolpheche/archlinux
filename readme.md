# Archlinux Workstation

Project to setup a minimal Archlinux OS.

Feel free to fork and custom it for your needs.

## Summary

<!-- TOC -->

- [Summary](#summary)
- [The stack](#the-stack)
- [Getting started](#getting-started)
    - [Requirements](#requirements)
    - [Test on a local qemu VM](#test-on-a-local-qemu-vm)
        - [Build qcow image](#build-qcow-image)
        - [Test qcow image](#test-qcow-image)
    - [Provision machine](#provision-machine)
        - [Burn USB live iso](#burn-usb-live-iso)
        - [Prepare machine](#prepare-machine)
        - [Provision](#provision)
    - [Totally wipe disk](#totally-wipe-disk)

<!-- /TOC -->

## The stack

- Core
  - kernel: Linux lts
  - crypted partition: LUKS
  - partition: gpt
  - filesystem: lvm / ext4
  - boot: uefi
  - boot manager: systemd-boot
  - network: systemd-networkd / systemd-resolved
  - init: systemd

## Getting started

### Requirements

- packer
- qemu
- qemu-ui-gtk
- edk2-ovmf
- ansible
- sshpass
- python-passlib

### Test on a local qemu VM

#### Build qcow image

This is based on the [qemu](https://www.packer.io/plugins/builders/qemu) Packer builder

If the file `/usr/share/edk2-ovmf/x64/OVMF.fd` doesn't exist on your system, find its right location, then adapt the `firwmare` path in the `qemu.pkr.hcl` file.

Then, build the qcow images with command:

```bash
packer build -force qemu.pkr.hcl
```

> A qcow images should be generated at `dist/archlinux.qcow`

#### Test qcow image

If the file `/usr/share/edk2-ovmf/x64/OVMF.fd` doesn't exist on your system, find its right location, then adapt the `bios` path in the command below.

```bash
./test-image.sh
```

> A qemu window should appear

Type `password` to decrypt the root partition.

Then, login:
- Username: `username`
- Password: `password`

> You're on the prompt of the base system !

### Provision machine

#### Burn USB live iso

Download Archlinux live iso at https://archlinux.org/download/:

```bash
curl https://mir.archlinux.fr/iso/latest/archlinux-x86_64.iso -o /tmp/archlinux.iso
```

Then, copy it on a USB device with `dd`:

```bash
dd if=/tmp/archlinux.iso of=/dev/sdX bs=4M status=progress # replace /dev/sdX with your USB device
```

> It may take a while

#### Prepare machine

Boot the USB key in UEFI mode on the machine you want to install Archlinux to.

> A root shell should appear after a few seconds

Execute these commands to give ssh access to ansible:

```bash
echo "root:root" | chpasswd
```

Checks:
- Internet connection
- Reachable by the machine which will run ansible

Note the machine IP address for the next:
```bash
ip addr
```

> The machine is ready to be provisionned

#### Provision

Then, from a system which has access to the machine, clone this repository:

```bash
git clone https://github.com/rodolpheche/archlinux.git
```

Now, fill informations in the `inventories/group_vars/all/all.yml` and `inventories/host_vars/archlinux-server.yml` files

Run this command to install the base system on the machine:

```bash
ansible-playbook -l archlinux-server install.yml -D
```

> Reboot the machine, it will load the base system

### Totally wipe disk

```bash
umount /mnt/boot /mnt/var/*
umount /mnt/*
umount /mnt
vgremove -f VG
cryptsetup close rootLUKS
cryptsetup luksErase rootLUKS
mkfs.ext4 /dev/sda # adapt it
```
