{ config, pkgs, ... }:
let
  syncthingCfg = import ../../modules/syncthing.nix;
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/cli.nix
      ../../modules/nix.nix
      ../../modules/roles.nix
      ../../modules/ssh.nix
      ../../modules/tailscale.nix
      ../../modules/users.nix
    ];

  roles.server = true;

  environment.systemPackages = with pkgs; [
      cron
      fish
      samba
      zsh
  ];

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "lat9w-16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  networking = rec {
    firewall.enable = false;
    hostName = "kraken";
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
        domain = true;
      };
    };

    cron.enable = true;

    ntp.enable = true;

    syncthing = {
      enable = true;
      systemService = true;
      openDefaultPorts = true;
      user = "ctr";
      group = "users";
      dataDir = "/home/ctr/syncthing";
      configDir = "/home/ctr/.config/syncthing";
      key = "/root/syncthing/key.pem";
      cert = "/root/syncthing/cert.pem";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = syncthingCfg.devices;
        folders = {
          "/home/ctr/syncthing/default" = {
            id = "sync-default";
            label = "Default";
            devices = syncthingCfg.groups.standard;
          };

          "/home/ctr/syncthing/Calibre" = {
            id = "sync-calibre";
            label = "Calibre";
            devices = syncthingCfg.groups.pcs;
          };
        };
      };
    };

  };

  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

  time.timeZone = "UTC";

  system.stateVersion = "22.11";
}
