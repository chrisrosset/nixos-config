{ config, pkgs, ... }:
{
  ## You probably do NOT want to change these settings.
  boot.kernelParams = ["boot.shell_on_fail"];
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.storePath = "/nixos/nix/store";
  boot.initrd.supportedFilesystems = [ "ext4" ];
  boot.initrd.postDeviceCommands = ''
    mkdir -p /mnt-root/old-root ;
    mount -t ext4 /dev/vda1 /mnt-root/old-root ;
  '';
  fileSystems = {
    "/" = {
      device = "/old-root/nixos";
      fsType = "none";
      options = [ "bind" ];
    };
    "/old-root" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
  };
}
