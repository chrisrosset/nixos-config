# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot = {
    #loader.systemd-boot.enable = true;
    #loader.efi.canTouchEfiVariables = true;
    loader.grub.enable = true;
    loader.grub.devices = [ "/dev/disk/by-id/usb-General_USB_Flash_Disk_0336314100000E18-0:0" ];

    initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    vesa = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S21HNXAG451663B-part2";
      fsType = "ext4";
    };

    # TODO: mdadm monitoring (emails? home assistant? tailscale monitoring?)

    "/srv/raid" = {
      device = "/dev/disk/by-uuid/43490db9-0f6d-4f6d-b490-33184ce2c859";
      fsType = "ext4";
    };
  };

  hardware.bluetooth.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.rtl-sdr.enable = true;

  swapDevices = [ ];

  nix.settings.max-jobs = lib.mkDefault 16;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
