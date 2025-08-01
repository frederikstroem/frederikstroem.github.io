---
layout: post

title: Installing NixOS on a LUKS-encrypted ext4 filesystem w/ or w/o swap
---
*I dedicate this journal post to the public domain under the [CC0 1.0 Universal (CC0 1.0) Public Domain Dedication](https://creativecommons.org/publicdomain/zero/1.0/). I waive all rights to the work worldwide under copyright law, including all related and neighboring rights, to the extent allowed by law.*

## Introduction
This post is a heavily opinionated reference for installing NixOS on a LUKS-encrypted ext4 filesystem with UEFI (GPT), optionally including an encrypted swap partition that uses a randomly generated key stored in RAM at boot time [[Encrypt swap with random key](https://web.archive.org/web/20250730104518/https://wiki.nixos.org/wiki/Swap#Encrypt_swap_with_random_key)].

Some steps vary based on whether you intend to use a swap partition. The variants are marked with the following emojis:
- 1️⃣ Without swap.
- 2️⃣ With swap.

This reference heavily relies on information from the ["Manual Installation" section](https://web.archive.org/web/20250730072851/https://nixos.org/manual/nixos/unstable/#sec-installation-manual) of the [NixOS manual](https://web.archive.org/web/20250730072851/https://nixos.org/manual/nixos/unstable/).

## Assumptions
This reference assumes that you:
- Have booted a [NixOS installation medium](https://nixos.org/download/) on the target system and are logged in as the root user.
- Have network connectivity to download packages during installation.

ℹ️ While not required, it may be preferable to perform the installation via SSH [[Networking in the installer](https://web.archive.org/web/20250730072851/https://nixos.org/manual/nixos/unstable/#sec-installation-manual-networking)].

## Identify the Target Disk
Identify the disk you're installing NixOS on, and store its identifier in a variable.

📝 After identifying the target disk, store its path in the `DISK` variable:

```bash
export DISK=/dev/disk/by-id/ata-VBOX_HARDDISK_VB230fd15b-201a3fc1
```

ℹ️ While it's possible to use the volatile `/dev/sdX` identifiers, I prefer to use the stable `/dev/disk/by-id/` identifiers.

💡 Example listing of the `/dev/disk/by-id/` directory:

```
[root@nixos:~]# ls -l /dev/disk/by-id/
total 0
lrwxrwxrwx 1 root root 9 Jul 31 17:32 ata-VBOX_CD-ROM_VB2-01700376 -> ../../sr0
lrwxrwxrwx 1 root root 9 Jul 31 17:32 ata-VBOX_HARDDISK_VB230fd15b-201a3fc1 -> ../../sda
```

💡 Example output of `lsblk`:

```
[root@nixos:~]# lsblk -o MODEL,SERIAL,SIZE,TYPE,MOUNTPOINT
MODEL         SERIAL               SIZE TYPE MOUNTPOINT
                                   1.5G loop /nix/.ro-store
VBOX HARDDISK VB230fd15b-201a3fc1  512G disk
VBOX CD-ROM   VB2-01700376         1.6G rom  /iso
```

💡 Example output of `fdisk`:

```
[root@nixos:~]# fdisk -l
Disk /dev/loop0: 1.48 GiB, 1586651136 bytes, 3098928 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sda: 512 GiB, 549755813888 bytes, 1073741824 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

## Partition the disk
Choose a partitioning scheme based on your needs.

⚠️ Make sure you're targeting the correct disk. Partitioning the wrong disk may result in permanent data loss.

ℹ️ This reference generally follows the [NixOS manual](https://web.archive.org/web/20250730072851/https://nixos.org/manual/nixos/unstable/#sec-installation-manual-partitioning-UEFI), but makes some deviations, such as using [binary units](https://en.wikipedia.org/wiki/Binary_prefix) (e.g., `GiB`) instead of [SI units](https://en.wikipedia.org/wiki/Metric_prefix) (e.g., `GB`).

📝 Pick a size for the boot partition and store it in the `BOOT_SIZE` variable:

```bash
export BOOT_SIZE=32GiB
```

ℹ️ I prefer a relatively large boot partition, especially on desktop systems. 32 GiB allows many derivations to be built and stored without the fear of running out of space.

2️⃣ If using swap, pick a swap size and store it in the `SWAP_SIZE` variable:

```bash
export SWAP_SIZE=128GiB
```

📝 Create a new GPT partition table on the disk:

```bash
parted $DISK -- mklabel gpt
```

1️⃣ Create the root partition (without space left for swap):

```bash
parted $DISK -- mkpart root ext4 $BOOT_SIZE 100%
```

2️⃣ Create the root partition (leaving space for swap):

```bash
parted $DISK -- mkpart root ext4 $BOOT_SIZE -$SWAP_SIZE
```

2️⃣ Create the swap partition:

```bash
parted $DISK -- mkpart swap linux-swap -$SWAP_SIZE 100%
```

📝 Create the boot partition:

```bash
parted $DISK -- mkpart ESP fat32 1MiB $BOOT_SIZE
```

1️⃣ Enable the ESP flag (boot partition is the 2nd):

```bash
parted $DISK -- set 2 esp on
```

2️⃣ Enable the ESP flag (boot partition is the 3rd):

```bash
parted $DISK -- set 3 esp on
```

## Initialize the root LUKS2 partition
📝 Initialize the root LUKS2 partition—this will prompt you to enter the passphrase you will be using for the NixOS installation:

```bash
cryptsetup luksFormat --type luks2 --label nixos $DISK-part1
```

ℹ️ While LUKS2 defaults should be generally acceptable, you may want to explore the many options available in `cryptsetup luksFormat` [[cryptsetup-luksFormat(8)](https://web.archive.org/web/20250731121451/https://man7.org/linux/man-pages/man8/cryptsetup-luksFormat.8.html)] or the general tooling provided by *Linux Unified Key Setup* (LUKS) [[cryptsetup(8)](https://web.archive.org/web/20250731121501/https://man7.org/linux/man-pages/man8/cryptsetup.8.html)], such as the `cryptsetup benchmark` command [[cryptsetup-benchmark(8)](https://web.archive.org/web/20250731143905/https://man7.org/linux/man-pages/man8/cryptsetup-benchmark.8.html)]. The [Arch Wiki](https://wiki.archlinux.org) also provides some useful information on LUKS and its features [[Device encryption](https://web.archive.org/web/20250731121410/https://wiki.archlinux.org/title/Dm-crypt/Device_encryption)] [[Encrypting an entire system](https://web.archive.org/web/20250731121551/https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system)].

📝 Open the encrypted root partition [[cryptsetup-open(8)](https://web.archive.org/web/20250731150250/https://man7.org/linux/man-pages/man8/cryptsetup-luksopen.8.html)]:

```bash
cryptsetup open $DISK-part1 nixos
```

## Format partitions
📝 Format the root partition [[mkfs.ext4(8)](https://web.archive.org/web/20250731151339/https://manpages.debian.org/bookworm/e2fsprogs/mkfs.ext4.8.en.html)]:

```bash
mkfs.ext4 -L nixos /dev/mapper/nixos
```

2️⃣ Format the swap partition [[mkswap(8)](https://web.archive.org/web/20250731151731/https://man7.org/linux/man-pages/man8/mkswap.8.html)]:

```bash
mkswap -L swap $DISK-part2
```

1️⃣ Format the boot partition [[mkfs.fat(8)](https://web.archive.org/web/20250731151607/https://man7.org/linux/man-pages/man8/mkfs.fat.8.html)] (boot partition is the 2nd):

```bash
mkfs.fat -F 32 -n boot $DISK-part2
```

2️⃣ Format the boot partition (boot partition is the 3rd):

```bash
mkfs.fat -F 32 -n boot $DISK-part3
```

## Mount filesystems
📝 Mount the root filesystem:

```bash
mount /dev/disk/by-label/nixos /mnt
```

📝 Create a mount point for the boot filesystem:

```bash
mkdir -p /mnt/boot
```

📝 Mount the boot filesystem:

```bash
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
```

## Generate and tweak NixOS configuration
📝 Generate a NixOS configuration:

```bash
nixos-generate-config --root /mnt
```

2️⃣ Determine the PARTUUID of the swap partition:

```bash
blkid -s PARTUUID -o value $DISK-part2
```

2️⃣ Edit `/mnt/etc/nixos/hardware-configuration.nix` to enable encrypted swap:

```nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Configuration omitted for brevity…

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/143e81c1-3491-4c7e-8b2a-9bb350189d94"; # ⚠️ Replace with your actual PARTUUID
      randomEncryption.enable = true;
    }
  ];

  # More configuration omitted…

}
```

📝 Review and tweak generated NixOS configuration files in `/mnt/etc/nixos/` as needed:

```
[root@nixos:~]# ls -1 /mnt/etc/nixos/
configuration.nix
hardware-configuration.nix
```

## Install and set passwords
📝 Start installation (you'll be prompted to set the root password):

```bash
nixos-install
```

📝 If you have configured a user account in the NixOS configuration, you might want to also set a password for that now:

```bash
nixos-enter --root /mnt -c 'passwd YOUR_USERNAME'
```

## Reboot into NixOS
📝 Reboot:

```bash
reboot
```

🏁 You should now be able to boot into your newly installed and encrypted NixOS system.
