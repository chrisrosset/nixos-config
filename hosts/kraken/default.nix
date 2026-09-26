{ config, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/base.nix
    ];

  roles.server = true;

  environment.systemPackages = with pkgs; [
    # TODO: Migrate /mnt/shuck to the kernel ntfs3 driver, then remove ntfs3g.
    ntfs3g
  ];

  networking = rec {
    firewall.enable = true;
    hostName = "kraken";
  };

  services = {
    syncthing = {
      enable = true;
      key = "/root/syncthing/key.pem";
      cert = "/root/syncthing/cert.pem";
    };

  };

  time.timeZone = "UTC";

  system.stateVersion = "22.11";
}
