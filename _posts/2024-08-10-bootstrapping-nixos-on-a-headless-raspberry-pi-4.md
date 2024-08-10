---
layout: post

title: Bootstrapping NixOS on a headless Raspberry Pi 4
---
*I dedicate this journal post to the public domain under the [CC0 1.0 Universal (CC0 1.0) Public Domain Dedication](https://creativecommons.org/publicdomain/zero/1.0/). I waive all rights to the work worldwide under copyright law, including all related and neighboring rights, to the extent allowed by law.*

![Two Raspberry Pi 4's with a PoE+ HAT](https://cdn.jsdelivr.net/gh/frederikstroem/frederikstroem.github.io/assets/img/2024-08-10-bootstrapping-nixos-on-a-headless-raspberry-pi-4.jpg)

## Introduction
I have started migrating several of my homelab servers, as well as some of my more appliance-focused systems, to NixOS. I have had good results with NixOS on my x86_64 systems; however, my experiences with ARM-based Raspberry Pi (RPi) systems have been more mixed. This is, however, to be expected, as the NixOS Wiki also states, ["The support level for ARM overall varies depending on the architecture and the specific ecosystems and boards."](https://web.archive.org/web/20240808055256/https://wiki.nixos.org/wiki/NixOS_on_ARM).

I used to primarily build complete images that could be flashed to an SD card, allowing me to set up SSH keys and other configurations before booting the system. Building these images for the AArch64 architecture on an x86_64 system requires emulation, but once set up, I have generally had good success with Roberto Frenna's [NixOS Docker-based SD image builder](https://github.com/Robertof/nixos-docker-sd-image-builder) for both the RPi 3 and 4. However, I have encountered issues modifying the configuration on a running RPi 3 and then rebuilding on the device. I suspect the memory constraints of the RPi 3 might have been the issue, but I need to investigate further to be sure. This was also some time ago, so things might have changed. I have encountered no issues rebuilding RPi 4's with 8GB of RAM. Since I only own RPi 4s with 8GB of RAM, I have not tested the lower memory models.

The build times to create new images when using Frenna's tool can be a bit long, especially if new changes haven't been cached on the [cache.nixos.org](https://cache.nixos.org/) binary cache (see related [issue #33](https://github.com/Robertof/nixos-docker-sd-image-builder/issues/33)).

I am deploying some RPis for high availability (HA) homelab server purposes, which I am going to set up once and then do remote setup and continued remote management thereafter, similar to what I have done with my x86_64 servers. Given these requirements, I thought I would try to use the latest [AArch64 NixOS SD Card Hydra build image](https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image.aarch64-linux), add my SSH keys, and continue the setup remotely. This approach avoids the need to build the images myself and, most importantly, eliminates the need to connect a monitor and keyboard to the RPi.

## Downloading and flashing the Hydra build image
The process of flashing the image to the SD card is fairly straightforward. Start by downloading the latest successful build (or a specific build) from the [Hydra build page](https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image.aarch64-linux). The SHA-256 checksum for a build artifact is provided by clicking on the <i><q>Details</q></i> button. The images are compressed with [zstd](https://en.wikipedia.org/wiki/Zstd), so decompress the image first. To decompress the image, you can use your preferred archiving and compression tool, or simply run the `unzstd` command (part of the `zstd` package) on the image file:

```
$ unzstd <IMAGE FILENAME>.img.zst
```

For example:

```
$ unzstd nixos-sd-image-24.11pre663431.957d95fc8b9b-aarch64-linux.img.zst
```

Then flash the image to the SD card. This can be done using the [rpi-imager tool](https://github.com/raspberrypi/rpi-imager), or by using the `dd` command. To use the `dd` command, first identify the device name of the SD card with `sudo fdisk -l` or a similar tool. Once the device name is identified, run the `dd` command to write the image to the SD card, making sure to replace `/dev/null` with the correct device name of the SD card:

```
$ sudo dd if=<IMAGE FILENAME>.img of=/dev/null bs=4096 conv=fsync
```

For instance

```
$ sudo dd if=nixos-sd-image-24.11pre663431.957d95fc8b9b-aarch64-linux.img of=/dev/sdb bs=4096 conv=fsync
```

When the command finishes successfully, the image has been flashed to the SD card.

## Configuring initial SSH access
Once the image has been written to the SD card, insert the SD card into the RPi and power it on. This is necessary because the RPi needs to boot up and allow the NixOS system to initialize; otherwise, the SD card data will not be accessible as a standard Linux filesystem.

Wait until the RPi can be reached via SSH. Logging in is not possible just yet, as SSH keys need to be added to the system first. To check whether the RPi is reachable via SSH, attempt to SSH into the RPi with the default `nixos` user:

```
$ ssh nixos@<IP>
```

If no route to the host is found, SSH is not up yet. This will look something like this:

```
$ ssh nixos@192.168.0.42
ssh: connect to host 192.168.1.100 port 22: No route to host
```

But if SSH is up, your SSH client will begin printing SSH fingerprints and ask you to accept the host key. This will look something like this:

```
$ ssh nixos@192.168.0.42
The authenticity of host '192.168.0.42 (192.168.0.42)' can't be established.
ED25519 key fingerprint is SHA256:Q1QRtxXz3aKO9uEa2E5gKRMFBRMKagq7ulbxNvLrWNA.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

When seeing the above authentication prompt, you can power off the RPi. After powering down the RPi, take out the SD card and again plug it into your computer. The SD card should now have a standard Linux file partition that can be modified. Identify and mount the file partition, either with a file explorer or a similar tool, or manually. By running `fdisk -l`, the partition should be identifiable with an output similar to this:

```
$ sudo fdisk -l
[...]

Disk /dev/sdb: 29,12 GiB, 31266439168 bytes, 61067264 sectors
Disk model: STORAGE DEVICE
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x8699158e

Device     Boot Start      End  Sectors  Size Id Type
/dev/sdb1       16384    77823    61440   30M  b W95 FAT32
/dev/sdb2  *    77824 61067263 60989440 29,1G 83 Linux
```

`/dev/sdb2` can then be mounted to a mount point on the machine:

```
$ sudo mkdir /mnt/sd_card
$ sudo mount /dev/sdb2 /mnt/sd_card
```

The partition should now be mounted on the machine. The SSH keys that the RPi should trust can now be copied over to the default `nixos` user. First create the `.ssh` directory:

```
$ sudo mkdir /mnt/sd_card/home/nixos/.ssh
```

Then write your SSH key to the `authorized_keys` file:

```
$ sudo echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDaVxct8yXJXG6iVNQ7hUhOapHivZRW01PKOk2NKsPjp arthur@dent" | sudo tee /mnt/sd_card/home/nixos/.ssh/authorized_keys
```

You can add an additional key by appending to the `authorized_keys` file:

```
$ sudo echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7l0H36wYg3Y7X0DFapBrdQZ4u/+NrRo/0fB5gCBky6 ford@prefect" | sudo tee -a /mnt/sd_card/home/nixos/.ssh/authorized_keys
```

Lastly, before unmounting the SD card, we need to fix the ownership and file permissions of the newly created directory and file. The default `nixos` user has UID `1000` and the users' primary group is the `users` group with GID `100`. So to fix the ownership, run a recursive `chown` command:

```
$ sudo chown -R 1000:100 /mnt/sd_card/home/nixos/.ssh
```

Then fix the file permissions of the directory and file by running:

```
$ sudo chmod 700 /mnt/sd_card/home/nixos/.ssh
$ sudo chmod 600 /mnt/sd_card/home/nixos/.ssh/authorized_keys
```

Then unmount the SD card:

```
$ sudo umount /mnt/sd_card
```

Once unmounted, plug the SD card back into the RPi and power it on. The RPi should now be reachable via SSH with the `nixos` user. You can now SSH into the RPi and continue the setup remotely:

```
$ ssh nixos@192.168.0.42
```

The `nixos` user has passwordless sudo access and can also drop to a `root` shell, etc. The `nixos` user has `sudo` access as it has the `wheel` group as a supplementary group.

## Making the initial NixOS configuration
To begin configuring the remote NixOS RPi, generate a base configuration similar to setting up an x86_64 NixOS system. Generate a default configuration to the `/etc/nixos/` directory:

```
[nixos@nixos:~]$ sudo nixos-generate-config
writing /etc/nixos/hardware-configuration.nix...
writing /etc/nixos/configuration.nix...
For more hardware-specific settings, see https://github.com/NixOS/nixos-hardware.
```

The two generated files should look similar to this:

**/etc/nixos/configuration.nix:**

```nix
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;




  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}
```

**/etc/nixos/hardware-configuration.nix:**

```nix
# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.end0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
```

Rebuilding the system in its current state would lock you out, so a few modifications are needed in the `/etc/nixos/configuration.nix` file first. You can edit the configuration directly on the remote host, both `vim` and `nano` come pre-installed. Edit the `/etc/nixos/configuration.nix` file:

```
[nixos@nixos:~]$ sudo vim /etc/nixos/configuration.nix
```

I have made some modifications below, marked with the 📝 emoji for easy identification:

**/etc/nixos/configuration.nix**

```nix
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # 📝 Uncomment the default hostname.
  networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # 📝 If you are using ethernet to connect to the device, uncomment the NetworkManager option.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;




  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  # 📝 Make sure the `nixos` user stays.
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    # 📝 Re-add the trusted SSH keys.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDaVxct8yXJXG6iVNQ7hUhOapHivZRW01PKOk2NKsPjp arthur@dent"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7l0H36wYg3Y7X0DFapBrdQZ4u/+NrRo/0fB5gCBky6 ford@prefect"
    ];
    # 📝 Give user an empty password.
    # ⚠️ This is pretty risky, so use only in initial setup.
    password = "";
  };

  # 📝 Remove the need to be prompted for a password when using `sudo`.
  # ⚠️ This is pretty risky, so use only in initial setup.
  security.sudo.wheelNeedsPassword = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # 📝 Uncomment system packages to ensure that vim access stays.
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # 📝 Add SSH access, but only using SSH keys, and to the NixOS user.
  services.openssh = {
    enable = true;
    authorizedKeysInHomedir = false;  # Do not trust SSH keys in ~/.ssh/authorized_keys.
    settings = {
      PasswordAuthentication = false; # Disable password authentication.
      AllowUsers = [ "nixos" ];       # Allow only login via the "nixos" user.
      PermitRootLogin = "no";         # Disable root login via SSH.
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # 📝 Uncomment firewall option if you are okay with disabling the firewall entirely during initial setup.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}
```

The system can now be rebuilt with the new configuration:

```
[nixos@nixos:~]$ sudo nixos-rebuild switch
```

## Wrapping up
This new system state can now be further remotely configured to meet the requirements of the application being developed.

⚠️ **Remember to strengthen the security of the system!** Ensure that your configurations align with your [threat model](https://en.wikipedia.org/wiki/Threat_model), considering potential risks and implementing appropriate security measures to mitigate them.
