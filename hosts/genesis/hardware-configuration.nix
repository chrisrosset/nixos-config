{ lib, ... }:
{
  imports = [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix> ];
  boot.loader.grub.device = "/dev/vda";
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
