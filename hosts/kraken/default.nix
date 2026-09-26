{ config, pkgs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/base.nix
    ];

  roles.server = true;

  environment.systemPackages = with pkgs; [
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
