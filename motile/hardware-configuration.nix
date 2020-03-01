# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_usb_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # https://forum.manjaro.org/t/resolution-help-needed-systemd-backlight-backlight-acpi-video0-service-loaded-failed-failed/68131
  boot.kernelParams = [ "acpi_backlight=native" ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b71e2012-58f1-4068-9651-739116ae45d1";
      fsType = "ext4";
    };

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  nix.maxJobs = lib.mkDefault 8;
}
