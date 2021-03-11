{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/99e2afdb-eb84-4897-8bb9-f23620485f5c";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8C09-3F95";
      fsType = "vfat";
    };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.system76.enableAll = true;

  swapDevices = [{ device = "/dev/disk/by-uuid/6a5e0c75-0b2f-4f2b-a31b-910ed2857782"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
